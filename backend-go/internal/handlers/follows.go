package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type FollowHandler struct {
	db *sql.DB
}

func NewFollowHandler(db *sql.DB) *FollowHandler {
	return &FollowHandler{db: db}
}

// Follow — follow a user
func (h *FollowHandler) Follow(c *gin.Context) {
	followerID := c.GetString("user_id")
	followingID := c.Param("id")

	// Can't follow yourself
	if followerID == followingID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You can't follow yourself"})
		return
	}

	// Check if user exists
	var exists bool
	h.db.QueryRow(`SELECT EXISTS(SELECT 1 FROM users WHERE id::text=$1)`, followingID).Scan(&exists)
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if already following
	var alreadyFollowing bool
	h.db.QueryRow(`
		SELECT EXISTS(SELECT 1 FROM follows 
		WHERE follower_id::text=$1 AND following_id::text=$2)`,
		followerID, followingID).Scan(&alreadyFollowing)

	if alreadyFollowing {
		// Unfollow
		h.db.Exec(`
			DELETE FROM follows 
			WHERE follower_id::text=$1 AND following_id::text=$2`,
			followerID, followingID)

		// Update counts
		h.db.Exec(`UPDATE users SET following_count = following_count - 1 WHERE id::text=$1`, followerID)
		h.db.Exec(`UPDATE users SET followers_count = followers_count - 1 WHERE id::text=$1`, followingID)

		c.JSON(http.StatusOK, gin.H{"following": false, "message": "Unfollowed!"})
	} else {
		// Follow
		h.db.Exec(`
			INSERT INTO follows (follower_id, following_id)
			VALUES ($1::uuid, $2::uuid)`,
			followerID, followingID)

		// Update counts
		h.db.Exec(`UPDATE users SET following_count = following_count + 1 WHERE id::text=$1`, followerID)
		h.db.Exec(`UPDATE users SET followers_count = followers_count + 1 WHERE id::text=$1`, followingID)

		c.JSON(http.StatusOK, gin.H{"following": true, "message": "Following!"})
	}
}

// GetFollowers — get list of followers for a user
func (h *FollowHandler) GetFollowers(c *gin.Context) {
	userID := c.Param("id")

	rows, err := h.db.Query(`
		SELECT u.id, u.username, u.avatar_url, u.bio
		FROM follows f
		JOIN users u ON u.id = f.follower_id
		WHERE f.following_id::text=$1
		ORDER BY f.created_at DESC`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get followers"})
		return
	}
	defer rows.Close()

	type User struct {
		ID        string `json:"id"`
		Username  string `json:"username"`
		AvatarURL string `json:"avatar_url"`
		Bio       string `json:"bio"`
	}

	followers := []User{}
	for rows.Next() {
		var u User
		rows.Scan(&u.ID, &u.Username, &u.AvatarURL, &u.Bio)
		followers = append(followers, u)
	}

	c.JSON(http.StatusOK, gin.H{"followers": followers})
}

// GetFollowing — get list of users a user is following
func (h *FollowHandler) GetFollowing(c *gin.Context) {
	userID := c.Param("id")

	rows, err := h.db.Query(`
		SELECT u.id, u.username, u.avatar_url, u.bio
		FROM follows f
		JOIN users u ON u.id = f.following_id
		WHERE f.follower_id::text=$1
		ORDER BY f.created_at DESC`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get following"})
		return
	}
	defer rows.Close()

	type User struct {
		ID        string `json:"id"`
		Username  string `json:"username"`
		AvatarURL string `json:"avatar_url"`
		Bio       string `json:"bio"`
	}

	following := []User{}
	for rows.Next() {
		var u User
		rows.Scan(&u.ID, &u.Username, &u.AvatarURL, &u.Bio)
		following = append(following, u)
	}

	c.JSON(http.StatusOK, gin.H{"following": following})
}

// GetProfile — get a user's public profile
func (h *FollowHandler) GetProfile(c *gin.Context) {
	userID := c.Param("id")

	var profile struct {
		ID             string    `json:"id"`
		Username       string    `json:"username"`
		Bio            string    `json:"bio"`
		AvatarURL      string    `json:"avatar_url"`
		Province       string    `json:"province"`
		IsVerified     bool      `json:"is_verified"`
		FollowersCount int       `json:"followers_count"`
		FollowingCount int       `json:"following_count"`
		PostsCount     int       `json:"posts_count"`
		CreatedAt      time.Time `json:"created_at"`
	}

	err := h.db.QueryRow(`
		SELECT id, username, bio, avatar_url, province, is_verified,
		       followers_count, following_count, posts_count, created_at
		FROM users WHERE id::text=$1`, userID).Scan(
		&profile.ID, &profile.Username, &profile.Bio, &profile.AvatarURL,
		&profile.Province, &profile.IsVerified, &profile.FollowersCount,
		&profile.FollowingCount, &profile.PostsCount, &profile.CreatedAt)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Get user's posts
	rows, _ := h.db.Query(`
		SELECT id, caption, image_url, likes_count, comments_count, created_at
		FROM posts WHERE user_id::text=$1
		ORDER BY created_at DESC LIMIT 20`, userID)
	defer rows.Close()

	type Post struct {
		ID            string    `json:"id"`
		Caption       string    `json:"caption"`
		ImageURL      string    `json:"image_url"`
		LikesCount    int       `json:"likes_count"`
		CommentsCount int       `json:"comments_count"`
		CreatedAt     time.Time `json:"created_at"`
	}

	posts := []Post{}
	for rows.Next() {
		var p Post
		rows.Scan(&p.ID, &p.Caption, &p.ImageURL, &p.LikesCount, &p.CommentsCount, &p.CreatedAt)
		posts = append(posts, p)
	}

	c.JSON(http.StatusOK, gin.H{
		"profile": profile,
		"posts":   posts,
	})
}
