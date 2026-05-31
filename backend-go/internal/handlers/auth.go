package handlers

import (
	"database/sql"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	db *sql.DB
}

func NewAuthHandler(db *sql.DB) *AuthHandler {
	return &AuthHandler{db: db}
}

// Register — creates a new user account
func (h *AuthHandler) Register(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Email    string `json:"email"`
		Phone    string `json:"phone"`
		Password string `json:"password" binding:"required"`
		Province string `json:"province"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Hash the password — never store plain text!
	// bcrypt turns "mypassword" into "$2a$10$xyz..." 
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Generate a unique ID for the user
	id := uuid.New().String()

	// Insert user into database
	_, err = h.db.Exec(`
		INSERT INTO users (id, username, email, phone, password_hash, province)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		id, req.Username, req.Email, req.Phone, string(hash), req.Province)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username or email already exists"})
		return
	}

	// Generate JWT token
	token, err := generateToken(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"token":    token,
		"user_id":  id,
		"username": req.Username,
		"message":  "Welcome to Rikia!",
	})
}

// Login — authenticates existing user
func (h *AuthHandler) Login(c *gin.Context) {
	var req struct {
		Email    string `json:"email"`
		Phone    string `json:"phone"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find user by email or phone
	var id, username, passwordHash string
	var isAdmin bool
	err := h.db.QueryRow(`
		SELECT id, username, password_hash, is_admin 
		FROM users 
		WHERE email=$1 OR phone=$2`,
		req.Email, req.Phone).Scan(&id, &username, &passwordHash, &isAdmin)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Compare password with hash
	// bcrypt.CompareHashAndPassword returns nil if they match
	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Generate JWT token
	token, err := generateToken(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":    token,
		"user_id":  id,
		"username": username,
		"is_admin": isAdmin,
	})
}

// generateToken creates a JWT token that expires in 30 days
func generateToken(userID string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "rikia-default-secret"
	}

	// Claims are the data stored inside the token
	claims := jwt.MapClaims{
		"sub": userID,                                // subject (user ID)
		"iat": time.Now().Unix(),                     // issued at
		"exp": time.Now().Add(30 * 24 * time.Hour).Unix(), // expires in 30 days
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}
