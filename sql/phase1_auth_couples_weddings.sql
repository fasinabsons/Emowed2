-- ============================================
-- EMOWED DATABASE MIGRATION - PHASE 1
-- ============================================
-- Purpose: Create core tables for MVP
-- Tables: users, partner_invitations, couples, weddings, notifications, cooldown_periods
-- Execute in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  full_name TEXT NOT NULL,
  age INTEGER CHECK (age >= 18),
  relationship_status TEXT DEFAULT 'single' CHECK (
    relationship_status IN ('single', 'committed', 'engaged', 'married', 'divorced', 'widowed')
  ),
  age_verified BOOLEAN DEFAULT FALSE,
  can_invite BOOLEAN DEFAULT TRUE,
  last_invite_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(relationship_status);

-- ============================================
-- PARTNER INVITATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS partner_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  receiver_email TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'rejected', 'expired')
  ),
  rejection_count INTEGER DEFAULT 0 CHECK (rejection_count <= 3),
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '48 hours'),
  responded_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_invitations_code ON partner_invitations(code);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON partner_invitations(status);

-- ============================================
-- COUPLES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS couples (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id UUID REFERENCES users(id) ON DELETE CASCADE,
  user2_id UUID REFERENCES users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'engaged' CHECK (
    status IN ('engaged', 'married', 'separated', 'divorced')
  ),
  engaged_date DATE DEFAULT CURRENT_DATE,
  married_date DATE,
  separated_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_couple UNIQUE (user1_id, user2_id)
);

CREATE INDEX IF NOT EXISTS idx_couples_users ON couples(user1_id, user2_id);
CREATE INDEX IF NOT EXISTS idx_couples_status ON couples(status);

-- ============================================
-- WEDDINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS weddings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  date DATE NOT NULL CHECK (date > CURRENT_DATE),
  venue TEXT NOT NULL,
  city TEXT NOT NULL,
  mode TEXT DEFAULT 'combined' CHECK (mode IN ('combined', 'separate')),
  budget_limit DECIMAL(12, 2),
  guest_limit INTEGER DEFAULT 500 CHECK (guest_limit > 0),
  status TEXT DEFAULT 'planning' CHECK (
    status IN ('planning', 'confirmed', 'completed', 'cancelled')
  ),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weddings_couple ON weddings(couple_id);
CREATE INDEX IF NOT EXISTS idx_weddings_date ON weddings(date);
CREATE INDEX IF NOT EXISTS idx_weddings_status ON weddings(status);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (
    type IN ('invitation', 'rejection', 'acceptance', 'wedding_created', 'wedding_cancelled')
  ),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, read);

-- ============================================
-- COOLDOWN PERIODS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS cooldown_periods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('invitation', 'wedding_cancellation')),
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cooldown_user ON cooldown_periods(user_id, type, expires_at);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Generate unique 6-char code
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Check if user is in cooldown
CREATE OR REPLACE FUNCTION is_in_cooldown(p_user_id UUID, p_type TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM cooldown_periods
    WHERE user_id = p_user_id
    AND type = p_type
    AND expires_at > NOW()
  );
END;
$$ LANGUAGE plpgsql;

-- Function to check invitation expiry
CREATE OR REPLACE FUNCTION check_invitation_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'pending' AND NOW() > NEW.expires_at THEN
    NEW.status = 'expired';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for invitation expiry
DROP TRIGGER IF EXISTS update_invitation_expiry ON partner_invitations;
CREATE TRIGGER update_invitation_expiry
BEFORE INSERT OR UPDATE ON partner_invitations
FOR EACH ROW
EXECUTE FUNCTION check_invitation_expiry();

-- Update user status on couple creation
CREATE OR REPLACE FUNCTION update_users_on_couple()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET relationship_status = 'engaged'
  WHERE id IN (NEW.user1_id, NEW.user2_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_couple_insert ON couples;
CREATE TRIGGER after_couple_insert
AFTER INSERT ON couples
FOR EACH ROW
EXECUTE FUNCTION update_users_on_couple();

-- Clean up on wedding cancellation
CREATE OR REPLACE FUNCTION cleanup_on_wedding_cancel()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
    -- Update couple status
    UPDATE couples SET status = 'separated'
    WHERE id = NEW.couple_id;

    -- Update user statuses
    UPDATE users SET relationship_status = 'single'
    WHERE id IN (
      SELECT user1_id FROM couples WHERE id = NEW.couple_id
      UNION
      SELECT user2_id FROM couples WHERE id = NEW.couple_id
    );

    -- Create cooldown periods
    INSERT INTO cooldown_periods (user_id, type, expires_at)
    SELECT user1_id, 'invitation', NOW() + INTERVAL '30 days'
    FROM couples WHERE id = NEW.couple_id
    UNION
    SELECT user2_id, 'invitation', NOW() + INTERVAL '30 days'
    FROM couples WHERE id = NEW.couple_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS wedding_cancelled ON weddings;
CREATE TRIGGER wedding_cancelled
AFTER UPDATE ON weddings
FOR EACH ROW
EXECUTE FUNCTION cleanup_on_wedding_cancel();

-- ============================================
-- ROW LEVEL SECURITY (RLS) - DISABLED FOR TESTING
-- ============================================
-- RLS policies have been moved to sql/rls_policies.sql
-- Execute rls_policies.sql separately after testing to enable security

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Run these to verify migration success:
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Phase 1 tables created successfully!
-- Next: Run Phase 2 migration for events, guests, vendors
-- ============================================
