// barack
// ssdkospadkpassdsdas jdwdoiwj

package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// Database models
type License struct {
	ID           int       `json:"id" gorm:"primaryKey;autoIncrement;column:id"`
	Email        string    `json:"email" gorm:"size:120;column:email"`
	LicenseKey   string    `json:"licensekey" gorm:"size:120;not null;column:licensekey"`
	Remaining    int       `json:"remaining" gorm:"default:5;column:remaining"`
	PurchaseInfo string    `json:"purchaseinfo" gorm:"type:text;column:purchaseinfo"`
	PurchaseDate time.Time `json:"purchasedate" gorm:"column:purchasedate;default:CURRENT_TIMESTAMP"`
}

func (License) TableName() string {
	return "licenses"
}

type User struct {
	UID       int       `json:"uid" gorm:"primaryKey;autoIncrement;column:uid"`
	KeyID     int       `json:"key_id" gorm:"not null;column:key_id"`
	MachineID string    `json:"machine_id" gorm:"size:120;not null;column:machine_id"`
	Created   time.Time `json:"created" gorm:"default:CURRENT_TIMESTAMP;column:created"`
	License   License   `json:"license" gorm:"foreignKey:KeyID"`
}

func (User) TableName() string {
	return "users"
}

// Request/Response structures
type ValidateLicenseRequest struct {
	LicenseKey string `json:"licensekey" binding:"required"`
	MachineID  string `json:"machine_id" binding:"required"`
}

type ValidateLicenseResponse struct {
	Valid   bool   `json:"valid"`
	Message string `json:"message"`
}

type RegisterLicenseRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type RegisterLicenseResponse struct {
	Success    bool   `json:"success"`
	LicenseKey string `json:"licensekey,omitempty"`
	Message    string `json:"message"`
}

var db *gorm.DB

func main() {
	// Initialize database with retry mechanism
	initDBWithRetry()

	// Setup Gin router
	r := gin.Default()

	// Add CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// API routes
	api := r.Group("/api/v1")
	{
		api.POST("/validate", validateLicense)
		api.POST("/register", registerLicense)
	}

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "super healthy with docker hot reload!"})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
	log.Printf("Server started on port %s", port)
}

func initDBWithRetry() {
	maxRetries := 30
	retryDelay := 2 * time.Second

	for i := 0; i < maxRetries; i++ {
		err := initDB()
		if err == nil {
			return
		}

		log.Printf("Database connection attempt %d/%d failed: %v", i+1, maxRetries, err)
		if i < maxRetries-1 {
			log.Printf("Retrying in %v...", retryDelay)
			time.Sleep(retryDelay)
		}
	}

	log.Fatal("Failed to connect to database after maximum retries")
}

func initDB() error {
	// Get database configuration from environment variables
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "3306")
	dbUser := getEnv("DB_USER", "launchpad_user")
	dbPassword := getEnv("DB_PASSWORD", "launchpad_password")
	dbName := getEnv("DB_NAME", "launchpad_db")

	// Create DSN
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		dbUser, dbPassword, dbHost, dbPort, dbName)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// Test the connection by checking if tables exist
	var count int64
	db.Raw("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ? AND table_name IN ('licenses', 'users')", dbName).Scan(&count)
	if count < 2 {
		return fmt.Errorf("required tables not found in database")
	}

	log.Println("Database connected successfully")
	return nil
}

func validateLicense(c *gin.Context) {
	var req ValidateLicenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if license exists and has remaining uses
	var license License
	result := db.Where("licensekey = ?", req.LicenseKey).First(&license)
	if result.Error != nil {
		c.JSON(http.StatusOK, ValidateLicenseResponse{
			Valid:   false,
			Message: "Invalid license key",
		})
		return
	}

	// Check if license has remaining uses
	if license.Remaining <= 0 {
		c.JSON(http.StatusOK, ValidateLicenseResponse{
			Valid:   false,
			Message: "License has no remaining uses",
		})
		return
	}

	// Check if this machine is already registered with this license
	var existingUser User
	result = db.Where("key_id = ? AND machine_id = ?", license.ID, req.MachineID).First(&existingUser)
	if result.Error == nil {
		// Machine is already registered, license is valid
		c.JSON(http.StatusOK, ValidateLicenseResponse{
			Valid:   true,
			Message: "License is valid for this machine",
		})
		return
	}

	// Check if we can register a new machine
	var userCount int64
	db.Model(&User{}).Where("key_id = ?", license.ID).Count(&userCount)
	if int(userCount) >= license.Remaining {
		c.JSON(http.StatusOK, ValidateLicenseResponse{
			Valid:   false,
			Message: "License has reached maximum number of machines",
		})
		return
	}

	// Register new machine
	newUser := User{
		KeyID:     license.ID,
		MachineID: req.MachineID,
	}

	if err := db.Create(&newUser).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register machine"})
		return
	}

	// Decrease remaining count
	db.Model(&license).Update("remaining", license.Remaining-1)

	c.JSON(http.StatusOK, ValidateLicenseResponse{
		Valid:   true,
		Message: "License is valid and machine registered",
	})
}

func registerLicense(c *gin.Context) {
	var req RegisterLicenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Generate a unique license key (simple implementation)
	licenseKey := generateLicenseKey()

	// Create new license
	license := License{
		Email:      req.Email,
		LicenseKey: licenseKey,
		Remaining:  5, // Default value
	}

	if err := db.Create(&license).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create license"})
		return
	}

	c.JSON(http.StatusOK, RegisterLicenseResponse{
		Success:    true,
		LicenseKey: licenseKey,
		Message:    "License created successfully",
	})
}

func generateLicenseKey() string {
	// Simple license key generation - in production, use a more secure method
	timestamp := time.Now().Unix()
	return fmt.Sprintf("LP-%d-%d", timestamp, time.Now().UnixNano()%10000)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
