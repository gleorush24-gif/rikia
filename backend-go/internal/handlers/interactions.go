package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type InteractionHandler struct {
	db *sql.DB
}

func NewInteractionHandler(db *sql.DB) *InteractionHandler {
	return &InteractionHandler{db: db}
}

// LikePost — likes or unlikes a post (toggle)
func (h *InteractionHandler) LikePost(c *gin.Context) {
	userID := c.GetString("user_id")
	postID := c.Param("id")

	// Check if already liked
	var existingID string
	err := h.db.QueryRow(`
		SELECT user_id FROM likes 
		WHERE user_id::text=$1 AND post_id::text=$2`,
		userID, postID).Scan(&existingID)

	if err == sql.ErrNoRows {
		// Not liked yet — add like
		h.db.Exec(`
			INSERT INTO likes (user_id, post_id) 
			VALUES ($1::uuid, $2::uuid)`,
			userID, postID)

		// Increment likes count on post
		h.db.Exec(`
			UPDATE posts SET likes_count = likes_count + 1 
			WHERE id::text=$1`, postID)

		// Notify post owner
		var postOwnerID string
		h.db.QueryRow(`SELECT user_id FROM posts WHERE id::text=$1`, postID).Scan(&postOwnerID)
		if postOwnerID != userID {
			CreateNotification(h.db, postOwnerID, userID, "like", "liked your post")
		}
		c.JSON(http.StatusOK, gin.H{"liked": true, "message": "Post liked!"})
	} else {
		// Already liked — remove like (unlike)
		h.db.Exec(`
			DELETE FROM likes 
			WHERE user_id::text=$1 AND post_id::text=$2`,
			userID, postID)

		// Decrement likes count
		h.db.Exec(`
			UPDATE posts SET likes_count = likes_count - 1 
			WHERE id::text=$1`, postID)

		c.JSON(http.StatusOK, gin.H{"liked": false, "message": "Post unliked!"})
	}
}

// AddComment — adds a comment to a post
func (h *InteractionHandler) AddComment(c *gin.Context) {
	userID := c.GetString("user_id")
	postID := c.Param("id")

	var req struct {
		Text string `json:"text" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Comment text is required"})
		return
	}

	id := uuid.New().String()

	_, err := h.db.Exec(`
		INSERT INTO comments (id, user_id, post_id, text)
		VALUES ($1, $2::uuid, $3::uuid, $4)`,
		id, userID, postID, req.Text)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add comment"})
		return
	}

	// Increment comments count on post
	h.db.Exec(`
		UPDATE posts SET comments_count = comments_count + 1 
		WHERE id::text=$1`, postID)

	c.JSON(http.StatusCreated, gin.H{
		"id":      id,
		"message": "Comment added!",
	})
}

// GetComments — gets all comments for a post
func (h *InteractionHandler) GetComments(c *gin.Context) {
	postID := c.Param("id")

	rows, err := h.db.Query(`
		SELECT c.id, c.text, c.created_at,
		       u.id, u.username, u.avatar_url
		FROM comments c
		JOIN users u ON u.id = c.user_id
		WHERE c.post_id::text=$1
		ORDER BY c.created_at ASC`, postID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get comments"})
		return
	}
	defer rows.Close()

	type Comment struct {
		ID        string    `json:"id"`
		Text      string    `json:"text"`
		CreatedAt time.Time `json:"created_at"`
		UserID    string    `json:"user_id"`
		Username  string    `json:"username"`
		AvatarURL string    `json:"avatar_url"`
	}

	comments := []Comment{}
	for rows.Next() {
		var cm Comment
		rows.Scan(&cm.ID, &cm.Text, &cm.CreatedAt,
			&cm.UserID, &cm.Username, &cm.AvatarURL)
		comments = append(comments, cm)
	}

	c.JSON(http.StatusOK, gin.H{"comments": comments})
}

// DeleteComment — deletes a comment (only owner can delete)
func (h *InteractionHandler) DeleteComment(c *gin.Context) {
	userID := c.GetString("user_id")
	commentID := c.Param("id")

	var ownerID string
	err := h.db.QueryRow(`SELECT user_id FROM comments WHERE id::text=$1`, commentID).Scan(&ownerID)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Comment not found"})
		return
	}

	if ownerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own comments"})
		return
	}

	h.db.Exec(`DELETE FROM comments WHERE id::text=$1`, commentID)
	c.JSON(http.StatusOK, gin.H{"message": "Comment deleted"})
}
