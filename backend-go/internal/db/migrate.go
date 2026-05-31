package db

import "log"

func Migrate() {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			username VARCHAR(50) UNIQUE NOT NULL,
			email VARCHAR(255) UNIQUE,
			phone VARCHAR(20) UNIQUE,
			password_hash VARCHAR(255) NOT NULL,
			bio TEXT DEFAULT '',
			avatar_url TEXT DEFAULT '',
			province VARCHAR(100) DEFAULT '',
			is_admin BOOLEAN DEFAULT FALSE,
			is_verified BOOLEAN DEFAULT FALSE,
			followers_count INT DEFAULT 0,
			following_count INT DEFAULT 0,
			posts_count INT DEFAULT 0,
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS posts (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			user_id UUID REFERENCES users(id) ON DELETE CASCADE,
			caption TEXT DEFAULT '',
			image_url TEXT DEFAULT '',
			video_url TEXT DEFAULT '',
			location VARCHAR(255) DEFAULT '',
			likes_count INT DEFAULT 0,
			comments_count INT DEFAULT 0,
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS stories (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			user_id UUID REFERENCES users(id) ON DELETE CASCADE,
			media_url TEXT NOT NULL,
			caption TEXT DEFAULT '',
			expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '24 hours',
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS follows (
			follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
			following_id UUID REFERENCES users(id) ON DELETE CASCADE,
			created_at TIMESTAMP DEFAULT NOW(),
			PRIMARY KEY (follower_id, following_id)
		)`,
		`CREATE TABLE IF NOT EXISTS likes (
			user_id UUID REFERENCES users(id) ON DELETE CASCADE,
			post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
			created_at TIMESTAMP DEFAULT NOW(),
			PRIMARY KEY (user_id, post_id)
		)`,
		`CREATE TABLE IF NOT EXISTS comments (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			user_id UUID REFERENCES users(id) ON DELETE CASCADE,
			post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
			text TEXT NOT NULL,
			created_at TIMESTAMP DEFAULT NOW()
		)`,
	}

	for _, q := range queries {
		if _, err := DB.Exec(q); err != nil {
			log.Fatalf("Migration failed: %v", err)
		}
	}

	log.Println("✅ Database migrations complete")
}
