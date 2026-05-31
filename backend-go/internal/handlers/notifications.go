package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	db *sql.DB
}

func NewNotificationHandler(db *sql.DB) *NotificationHandler {
	return &NotificationHandler{db: db}
}

// GetNotifications — get all notifications for the current user
func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userID := c.GetString("user_id")

	rows, err := h.db.Query(`
		SELECT n.id, n.type, n.message, n.is_read, n.created_at,
		       u.id, u.username, u.avatar_url
		FROM notifications n
		JOIN users u ON u.id = n.actor_id
		WHERE n.user_id::text=$1
		ORDER BY n.created_at DESC
		LIMIT 50`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get notifications"})
		return
	}
	defer rows.Close()

	type Notification struct {
		ID        string    `json:"id"`
		Type      string    `json:"type"`
		Message   string    `json:"message"`
		IsRead    bool      `json:"is_read"`
		CreatedAt time.Time `json:"created_at"`
		ActorID   string    `json:"actor_id"`
		Username  string    `json:"username"`
		AvatarURL string    `json:"avatar_url"`
	}

	notifications := []Notification{}
	for rows.Next() {
		var n Notification
		rows.Scan(&n.ID, &n.Type, &n.Message, &n.IsRead, &n.CreatedAt,
			&n.ActorID, &n.Username, &n.AvatarURL)
		notifications = append(notifications, n)
	}

	c.JSON(http.StatusOK, gin.H{"notifications": notifications})
}

// MarkAsRead — mark all notifications as read
func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	userID := c.GetString("user_id")

	h.db.Exec(`UPDATE notifications SET is_read=true WHERE user_id::text=$1`, userID)
	c.JSON(http.StatusOK, gin.H{"message": "All notifications marked as read"})
}

// CreateNotification — internal helper to create a notification
func CreateNotification(db *sql.DB, userID, actorID, notifType, message string) {
	id := uuid.New().String()
	db.Exec(`
		INSERT INTO notifications (id, user_id, actor_id, type, message)
		VALUES ($1, $2::uuid, $3::uuid, $4, $5)`,
		id, userID, actorID, notifType, message)
}
