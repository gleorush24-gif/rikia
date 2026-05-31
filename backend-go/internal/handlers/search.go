package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

type SearchHandler struct {
	db *sql.DB
}

func NewSearchHandler(db *sql.DB) *SearchHandler {
	return &SearchHandler{db: db}
}

// SearchUsers — search users by username
func (h *SearchHandler) SearchUsers(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query is required"})
		return
	}

	// Use ILIKE for case-insensitive search
	// % means "anything" — so %query% means "contains query"
	rows, err := h.db.Query(`
		SELECT id, username, bio, avatar_url, province, 
		       is_verified, followers_count, posts_count
		FROM users
		WHERE username ILIKE $1
		ORDER BY followers_count DESC
		LIMIT 20`, "%"+query+"%")

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Search failed"})
		return
	}
	defer rows.Close()

	type User struct {
		ID             string `json:"id"`
		Username       string `json:"username"`
		Bio            string `json:"bio"`
		AvatarURL      string `json:"avatar_url"`
		Province       string `json:"province"`
		IsVerified     bool   `json:"is_verified"`
		FollowersCount int    `json:"followers_count"`
		PostsCount     int    `json:"posts_count"`
	}

	users := []User{}
	for rows.Next() {
		var u User
		rows.Scan(&u.ID, &u.Username, &u.Bio, &u.AvatarURL,
			&u.Province, &u.IsVerified, &u.FollowersCount, &u.PostsCount)
		users = append(users, u)
	}

	c.JSON(http.StatusOK, gin.H{
		"users": users,
		"count": len(users),
	})
}

// SearchPosts — search posts by caption
func (h *SearchHandler) SearchPosts(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query is required"})
		return
	}

	rows, err := h.db.Query(`
		SELECT p.id, p.caption, p.image_url, p.likes_count, 
		       p.comments_count, p.created_at,
		       u.id, u.username, u.avatar_url
		FROM posts p
		JOIN users u ON u.id = p.user_id
		WHERE p.caption ILIKE $1
		ORDER BY p.likes_count DESC
		LIMIT 20`, "%"+query+"%")

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Search failed"})
		return
	}
	defer rows.Close()

	type Post struct {
		ID            string `json:"id"`
		Caption       string `json:"caption"`
		ImageURL      string `json:"image_url"`
		LikesCount    int    `json:"likes_count"`
		CommentsCount int    `json:"comments_count"`
		UserID        string `json:"user_id"`
		Username      string `json:"username"`
		AvatarURL     string `json:"avatar_url"`
	}

	posts := []Post{}
	for rows.Next() {
		var p Post
		rows.Scan(&p.ID, &p.Caption, &p.ImageURL, &p.LikesCount,
			&p.CommentsCount, &p.UserID, &p.Username, &p.AvatarURL)
		posts = append(posts, p)
	}

	c.JSON(http.StatusOK, gin.H{
		"posts": posts,
		"count": len(posts),
	})
}
