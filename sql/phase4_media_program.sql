-- ============================================
-- EMOWED PHASE 4: MEDIA & PROGRAM MANAGEMENT
-- ============================================
-- This migration adds photo/video galleries, wedding program, ceremony details
-- Run this after Phase 3 migration is complete

-- ============================================
-- MEDIA ALBUMS TABLE
-- ============================================
CREATE TABLE media_albums (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  title TEXT NOT NULL CHECK (LENGTH(title) >= 3),
  description TEXT,
  album_type TEXT CHECK (album_type IN ('pre_wedding', 'engagement', 'haldi', 'mehendi', 'sangeet', 'wedding', 'reception', 'honeymoon', 'other')),
  cover_image_url TEXT,
  visibility TEXT DEFAULT 'private' CHECK (visibility IN ('private', 'family', 'public')),
  created_by UUID REFERENCES users(id),
  media_count INTEGER DEFAULT 0,
  total_likes INTEGER DEFAULT 0,
  total_comments INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_media_albums_wedding ON media_albums(wedding_id);
CREATE INDEX idx_media_albums_event ON media_albums(event_id);
CREATE INDEX idx_media_albums_type ON media_albums(album_type);

COMMENT ON TABLE media_albums IS 'Photo and video albums organized by event or category';

-- ============================================
-- MEDIA ITEMS TABLE
-- ============================================
CREATE TABLE media_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  album_id UUID REFERENCES media_albums(id) ON DELETE CASCADE,
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL CHECK (media_type IN ('photo', 'video')),
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  title TEXT,
  description TEXT,
  file_size INTEGER, -- in bytes
  width INTEGER,
  height INTEGER,
  duration INTEGER, -- for videos, in seconds
  uploaded_by UUID REFERENCES users(id),
  captured_at TIMESTAMP,
  location TEXT,
  tags TEXT[],
  is_featured BOOLEAN DEFAULT FALSE,
  is_cover BOOLEAN DEFAULT FALSE,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  processing_status TEXT DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_media_items_album ON media_items(album_id);
CREATE INDEX idx_media_items_wedding ON media_items(wedding_id);
CREATE INDEX idx_media_items_type ON media_items(media_type);
CREATE INDEX idx_media_items_featured ON media_items(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_media_items_tags ON media_items USING GIN(tags);

COMMENT ON TABLE media_items IS 'Individual photos and videos in albums';

-- ============================================
-- MEDIA LIKES TABLE
-- ============================================
CREATE TABLE media_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  media_item_id UUID REFERENCES media_items(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(media_item_id, user_id)
);

CREATE INDEX idx_media_likes_item ON media_likes(media_item_id);
CREATE INDEX idx_media_likes_user ON media_likes(user_id);

COMMENT ON TABLE media_likes IS 'User likes on media items';

-- ============================================
-- MEDIA COMMENTS TABLE
-- ============================================
CREATE TABLE media_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  media_item_id UUID REFERENCES media_items(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL CHECK (LENGTH(comment_text) >= 1 AND LENGTH(comment_text) <= 500),
  parent_comment_id UUID REFERENCES media_comments(id) ON DELETE CASCADE,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_media_comments_item ON media_comments(media_item_id);
CREATE INDEX idx_media_comments_user ON media_comments(user_id);
CREATE INDEX idx_media_comments_parent ON media_comments(parent_comment_id);

COMMENT ON TABLE media_comments IS 'Comments on media items with nested replies support';

-- ============================================
-- PROGRAM SECTIONS TABLE
-- ============================================
CREATE TABLE program_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  section_type TEXT CHECK (section_type IN ('ceremony', 'ritual', 'performance', 'speech', 'meal', 'activity', 'other')),
  title TEXT NOT NULL CHECK (LENGTH(title) >= 3),
  description TEXT,
  start_time TIME NOT NULL,
  end_time TIME CHECK (end_time > start_time),
  duration_minutes INTEGER GENERATED ALWAYS AS (
    EXTRACT(EPOCH FROM (end_time - start_time)) / 60
  ) STORED,
  location TEXT,
  participants TEXT[],
  hosts TEXT[],
  notes TEXT,
  is_public BOOLEAN DEFAULT TRUE,
  sort_order INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_program_sections_wedding ON program_sections(wedding_id);
CREATE INDEX idx_program_sections_event ON program_sections(event_id);
CREATE INDEX idx_program_sections_time ON program_sections(start_time);

COMMENT ON TABLE program_sections IS 'Wedding program sections/timeline for events';

-- ============================================
-- CEREMONY DETAILS TABLE
-- ============================================
CREATE TABLE ceremony_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  ceremony_type TEXT CHECK (ceremony_type IN ('hindu', 'muslim', 'christian', 'sikh', 'buddhist', 'jain', 'interfaith', 'civil', 'other')),
  custom_type TEXT,
  tradition TEXT,
  officiant_name TEXT,
  officiant_contact TEXT,
  vow_exchange BOOLEAN DEFAULT FALSE,
  ring_exchange BOOLEAN DEFAULT FALSE,
  special_rituals TEXT[],
  ritual_descriptions JSONB,
  dress_code TEXT,
  seating_arrangement TEXT,
  ceremony_duration_minutes INTEGER,
  rehearsal_date DATE,
  rehearsal_time TIME,
  special_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(wedding_id, event_id)
);

CREATE INDEX idx_ceremony_details_wedding ON ceremony_details(wedding_id);
CREATE INDEX idx_ceremony_details_event ON ceremony_details(event_id);

COMMENT ON TABLE ceremony_details IS 'Detailed ceremony information for wedding events';

-- ============================================
-- MUSIC PLAYLIST TABLE
-- ============================================
CREATE TABLE music_playlists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE SET NULL,
  playlist_name TEXT NOT NULL,
  description TEXT,
  playlist_type TEXT CHECK (playlist_type IN ('ceremony', 'cocktail', 'dinner', 'dancing', 'pre_ceremony', 'processional', 'recessional', 'first_dance', 'other')),
  song_count INTEGER DEFAULT 0,
  total_duration_seconds INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_music_playlists_wedding ON music_playlists(wedding_id);
CREATE INDEX idx_music_playlists_event ON music_playlists(event_id);

COMMENT ON TABLE music_playlists IS 'Music playlists for different parts of wedding events';

-- ============================================
-- PLAYLIST SONGS TABLE
-- ============================================
CREATE TABLE playlist_songs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  playlist_id UUID REFERENCES music_playlists(id) ON DELETE CASCADE,
  song_title TEXT NOT NULL,
  artist TEXT,
  duration_seconds INTEGER,
  spotify_uri TEXT,
  youtube_url TEXT,
  notes TEXT,
  sort_order INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_playlist_songs_playlist ON playlist_songs(playlist_id);

COMMENT ON TABLE playlist_songs IS 'Individual songs in wedding playlists';

-- ============================================
-- WEDDING TIMELINE TABLE
-- ============================================
CREATE TABLE wedding_timeline (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  milestone_type TEXT CHECK (milestone_type IN ('engagement', 'venue_booked', 'invitations_sent', 'dress_purchased', 'cake_tasting', 'rehearsal', 'wedding_day', 'honeymoon', 'custom')),
  title TEXT NOT NULL,
  description TEXT,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP,
  reminder_days_before INTEGER DEFAULT 7,
  assigned_to UUID[],
  notes TEXT,
  sort_order INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_wedding_timeline_wedding ON wedding_timeline(wedding_id);
CREATE INDEX idx_wedding_timeline_date ON wedding_timeline(scheduled_date);
CREATE INDEX idx_wedding_timeline_completed ON wedding_timeline(completed);

COMMENT ON TABLE wedding_timeline IS 'Pre-wedding planning timeline and milestones';

-- ============================================
-- MEDIA SHARES TABLE
-- ============================================
CREATE TABLE media_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  album_id UUID REFERENCES media_albums(id) ON DELETE CASCADE,
  share_link TEXT UNIQUE NOT NULL,
  share_type TEXT CHECK (share_type IN ('view_only', 'download', 'upload')),
  password_hash TEXT,
  expires_at TIMESTAMP,
  max_downloads INTEGER,
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_media_shares_album ON media_shares(album_id);
CREATE INDEX idx_media_shares_link ON media_shares(share_link);

COMMENT ON TABLE media_shares IS 'Shareable links for media albums';

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Update media counts in album
CREATE OR REPLACE FUNCTION update_album_media_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE media_albums
    SET media_count = media_count + 1,
        updated_at = NOW()
    WHERE id = NEW.album_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE media_albums
    SET media_count = GREATEST(0, media_count - 1),
        updated_at = NOW()
    WHERE id = OLD.album_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_media_item_change
AFTER INSERT OR DELETE ON media_items
FOR EACH ROW
EXECUTE FUNCTION update_album_media_count();

COMMENT ON FUNCTION update_album_media_count IS 'Update media count when items added/removed from album';

-- Function: Update likes count on media item
CREATE OR REPLACE FUNCTION update_media_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE media_items
    SET likes_count = likes_count + 1
    WHERE id = NEW.media_item_id;

    UPDATE media_albums
    SET total_likes = total_likes + 1
    WHERE id = (SELECT album_id FROM media_items WHERE id = NEW.media_item_id);
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE media_items
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.media_item_id;

    UPDATE media_albums
    SET total_likes = GREATEST(0, total_likes - 1)
    WHERE id = (SELECT album_id FROM media_items WHERE id = OLD.media_item_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_media_like_change
AFTER INSERT OR DELETE ON media_likes
FOR EACH ROW
EXECUTE FUNCTION update_media_likes_count();

COMMENT ON FUNCTION update_media_likes_count IS 'Update likes count on media items and albums';

-- Function: Update comments count
CREATE OR REPLACE FUNCTION update_media_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE media_items
    SET comments_count = comments_count + 1
    WHERE id = NEW.media_item_id;

    UPDATE media_albums
    SET total_comments = total_comments + 1
    WHERE id = (SELECT album_id FROM media_items WHERE id = NEW.media_item_id);
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE media_items
    SET comments_count = GREATEST(0, comments_count - 1)
    WHERE id = OLD.media_item_id;

    UPDATE media_albums
    SET total_comments = GREATEST(0, total_comments - 1)
    WHERE id = (SELECT album_id FROM media_items WHERE id = OLD.media_item_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_media_comment_change
AFTER INSERT OR DELETE ON media_comments
FOR EACH ROW
EXECUTE FUNCTION update_media_comments_count();

COMMENT ON FUNCTION update_media_comments_count IS 'Update comments count on media items and albums';

-- Function: Update playlist song count
CREATE OR REPLACE FUNCTION update_playlist_song_count()
RETURNS TRIGGER AS $$
DECLARE
  v_total_duration INTEGER;
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE music_playlists
    SET song_count = song_count + 1,
        total_duration_seconds = total_duration_seconds + COALESCE(NEW.duration_seconds, 0),
        updated_at = NOW()
    WHERE id = NEW.playlist_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE music_playlists
    SET song_count = GREATEST(0, song_count - 1),
        total_duration_seconds = GREATEST(0, total_duration_seconds - COALESCE(OLD.duration_seconds, 0)),
        updated_at = NOW()
    WHERE id = OLD.playlist_id;
  ELSIF TG_OP = 'UPDATE' THEN
    SELECT SUM(duration_seconds) INTO v_total_duration
    FROM playlist_songs
    WHERE playlist_id = NEW.playlist_id;

    UPDATE music_playlists
    SET total_duration_seconds = COALESCE(v_total_duration, 0),
        updated_at = NOW()
    WHERE id = NEW.playlist_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_playlist_song_change
AFTER INSERT OR UPDATE OR DELETE ON playlist_songs
FOR EACH ROW
EXECUTE FUNCTION update_playlist_song_count();

COMMENT ON FUNCTION update_playlist_song_count IS 'Update song count and duration in playlists';

-- Function: Generate share link
CREATE OR REPLACE FUNCTION generate_share_link()
RETURNS TEXT AS $$
DECLARE
  v_link TEXT;
  v_exists BOOLEAN;
BEGIN
  LOOP
    v_link := encode(gen_random_bytes(16), 'base64');
    v_link := replace(replace(replace(v_link, '+', ''), '/', ''), '=', '');
    v_link := substring(v_link, 1, 12);

    SELECT EXISTS(SELECT 1 FROM media_shares WHERE share_link = v_link) INTO v_exists;
    EXIT WHEN NOT v_exists;
  END LOOP;

  RETURN v_link;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_share_link IS 'Generate unique share link for media albums';

-- ============================================
-- ROW LEVEL SECURITY (RLS) - DISABLED FOR TESTING
-- ============================================
-- RLS policies have been moved to sql/rls_policies.sql
-- Execute rls_policies.sql separately after testing to enable security

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

INSERT INTO schema_migrations (version) VALUES ('phase4_media_program_v1');

DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE 'PHASE 4: MEDIA & PROGRAM MIGRATION COMPLETE';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Tables created: 10';
  RAISE NOTICE 'Functions created: 5';
  RAISE NOTICE 'Triggers created: 4';
  RAISE NOTICE 'RLS Policies: 20+';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Features:';
  RAISE NOTICE '- Photo/Video Albums';
  RAISE NOTICE '- Media Likes & Comments';
  RAISE NOTICE '- Wedding Program Builder';
  RAISE NOTICE '- Ceremony Details';
  RAISE NOTICE '- Music Playlists';
  RAISE NOTICE '- Planning Timeline';
  RAISE NOTICE '- Media Sharing';
  RAISE NOTICE '============================================';
END $$;
