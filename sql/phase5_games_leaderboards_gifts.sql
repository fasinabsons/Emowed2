-- ============================================
-- EMOWED DATABASE MIGRATION - PHASE 5
-- ============================================
-- Purpose: Games, Leaderboards & Digital Gifting
-- Tables: game_types, wedding_games, game_questions, game_participants,
--         game_responses, leaderboard_categories, singles_leaderboard,
--         singles_activities, couples_leaderboard, couples_milestones,
--         wedding_side_competition, gift_categories, gift_products,
--         guest_gifts, gift_wishlists, photo_challenge_submissions,
--         photo_challenge_votes
-- Execute in Supabase SQL Editor after Phase 4
-- ============================================

-- Prerequisites check
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'weddings') THEN
    RAISE EXCEPTION 'Phase 1-4 must be completed before running Phase 5 migration';
  END IF;
END $$;

-- ============================================
-- GAME SYSTEM TABLES
-- ============================================

-- Game Templates/Types
CREATE TABLE IF NOT EXISTS game_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  game_code TEXT UNIQUE NOT NULL,
  game_name TEXT NOT NULL,
  game_category TEXT CHECK (game_category IN ('quiz', 'prediction', 'photo_challenge', 'trivia', 'voting', 'custom')),
  description TEXT,
  rules TEXT,
  min_players INTEGER DEFAULT 1,
  max_players INTEGER,
  duration_minutes INTEGER,
  is_team_based BOOLEAN DEFAULT FALSE,
  scoring_method TEXT CHECK (scoring_method IN ('points', 'time', 'accuracy', 'votes')),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_game_types_category ON game_types(game_category);
CREATE INDEX idx_game_types_active ON game_types(is_active);

-- Wedding-specific game instances
CREATE TABLE IF NOT EXISTS wedding_games (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  game_type_id UUID REFERENCES game_types(id),
  game_title TEXT NOT NULL,
  game_description TEXT,
  is_enabled BOOLEAN DEFAULT TRUE,
  is_team_based BOOLEAN DEFAULT FALSE,
  groom_side_only BOOLEAN DEFAULT FALSE,
  bride_side_only BOOLEAN DEFAULT FALSE,
  both_sides_compete BOOLEAN DEFAULT TRUE,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'active', 'completed', 'cancelled')),
  total_participants INTEGER DEFAULT 0,
  total_plays INTEGER DEFAULT 0,
  winner_announced BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_wedding_games_wedding ON wedding_games(wedding_id);
CREATE INDEX idx_wedding_games_status ON wedding_games(status);
CREATE INDEX idx_wedding_games_type ON wedding_games(game_type_id);

-- Game questions (quiz/trivia)
CREATE TABLE IF NOT EXISTS game_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_game_id UUID REFERENCES wedding_games(id) ON DELETE CASCADE,
  question_order INTEGER NOT NULL,
  question_text TEXT NOT NULL CHECK (LENGTH(question_text) >= 10),
  question_type TEXT CHECK (question_type IN ('multiple_choice', 'true_false', 'open_ended', 'number', 'date')),
  options JSONB,
  correct_answer TEXT,
  points INTEGER DEFAULT 10 CHECK (points BETWEEN 1 AND 100),
  time_limit_seconds INTEGER CHECK (time_limit_seconds BETWEEN 10 AND 300),
  hint TEXT,
  explanation TEXT,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_game_questions_game ON game_questions(wedding_game_id);
CREATE INDEX idx_game_questions_order ON game_questions(question_order);

-- Game participants
CREATE TABLE IF NOT EXISTS game_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_game_id UUID REFERENCES wedding_games(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  guest_id UUID REFERENCES guests(id),
  participant_name TEXT NOT NULL,
  side TEXT CHECK (side IN ('groom', 'bride', 'neutral')),
  team_name TEXT,
  total_score INTEGER DEFAULT 0,
  games_played INTEGER DEFAULT 0,
  games_won INTEGER DEFAULT 0,
  rank INTEGER,
  joined_at TIMESTAMP DEFAULT NOW(),
  last_played_at TIMESTAMP,
  UNIQUE(wedding_game_id, user_id)
);

CREATE INDEX idx_game_participants_game ON game_participants(wedding_game_id);
CREATE INDEX idx_game_participants_user ON game_participants(user_id);
CREATE INDEX idx_game_participants_score ON game_participants(total_score DESC);

-- Game responses/answers
CREATE TABLE IF NOT EXISTS game_responses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_game_id UUID REFERENCES wedding_games(id) ON DELETE CASCADE,
  game_question_id UUID REFERENCES game_questions(id) ON DELETE CASCADE,
  participant_id UUID REFERENCES game_participants(id) ON DELETE CASCADE,
  response_text TEXT,
  is_correct BOOLEAN,
  points_earned INTEGER DEFAULT 0,
  time_taken_seconds INTEGER,
  response_time TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_game_responses_game ON game_responses(wedding_game_id);
CREATE INDEX idx_game_responses_question ON game_responses(game_question_id);
CREATE INDEX idx_game_responses_participant ON game_responses(participant_id);

-- Wedding side competition tracker
CREATE TABLE IF NOT EXISTS wedding_side_competition (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  competition_name TEXT NOT NULL,
  groom_side_score INTEGER DEFAULT 0,
  bride_side_score INTEGER DEFAULT 0,
  groom_side_participants INTEGER DEFAULT 0,
  bride_side_participants INTEGER DEFAULT 0,
  total_games INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  winner_side TEXT CHECK (winner_side IN ('groom', 'bride', 'tie', NULL)),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(wedding_id)
);

CREATE INDEX idx_wedding_competition_wedding ON wedding_side_competition(wedding_id);

-- Photo challenge submissions
CREATE TABLE IF NOT EXISTS photo_challenge_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_game_id UUID REFERENCES wedding_games(id) ON DELETE CASCADE,
  participant_id UUID REFERENCES game_participants(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  caption TEXT CHECK (LENGTH(caption) <= 500),
  votes_count INTEGER DEFAULT 0,
  rank INTEGER,
  is_winner BOOLEAN DEFAULT FALSE,
  submitted_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_photo_submissions_game ON photo_challenge_submissions(wedding_game_id);
CREATE INDEX idx_photo_submissions_votes ON photo_challenge_submissions(votes_count DESC);

-- Photo challenge votes
CREATE TABLE IF NOT EXISTS photo_challenge_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID REFERENCES photo_challenge_submissions(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(submission_id, voter_id)
);

CREATE INDEX idx_photo_votes_submission ON photo_challenge_votes(submission_id);
CREATE INDEX idx_photo_votes_voter ON photo_challenge_votes(voter_id);

-- ============================================
-- LEADERBOARD SYSTEM TABLES
-- ============================================

-- Leaderboard categories
CREATE TABLE IF NOT EXISTS leaderboard_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_code TEXT UNIQUE NOT NULL,
  category_name TEXT NOT NULL,
  category_type TEXT CHECK (category_type IN ('singles_personal', 'singles_career', 'couples', 'game', 'wedding_specific')),
  description TEXT,
  icon TEXT,
  scoring_criteria JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  display_order INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_leaderboard_categories_type ON leaderboard_categories(category_type);

-- Singles leaderboard
CREATE TABLE IF NOT EXISTS singles_leaderboard (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES leaderboard_categories(id),
  category_type TEXT CHECK (category_type IN ('personal', 'career')),
  overall_score INTEGER DEFAULT 0,
  personal_growth_score INTEGER DEFAULT 0,
  career_achievement_score INTEGER DEFAULT 0,
  fitness_score INTEGER DEFAULT 0,
  social_engagement_score INTEGER DEFAULT 0,
  skills_score INTEGER DEFAULT 0,
  achievements JSONB DEFAULT '[]'::jsonb,
  badges TEXT[] DEFAULT ARRAY[]::TEXT[],
  rank_overall INTEGER,
  rank_personal INTEGER,
  rank_career INTEGER,
  last_updated TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX idx_singles_leaderboard_user ON singles_leaderboard(user_id);
CREATE INDEX idx_singles_leaderboard_overall ON singles_leaderboard(overall_score DESC);
CREATE INDEX idx_singles_leaderboard_personal ON singles_leaderboard(personal_growth_score DESC);
CREATE INDEX idx_singles_leaderboard_career ON singles_leaderboard(career_achievement_score DESC);

-- Singles activities
CREATE TABLE IF NOT EXISTS singles_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  activity_type TEXT CHECK (activity_type IN (
    'fitness_goal', 'skill_learned', 'book_read', 'course_completed',
    'certification', 'project_completed', 'volunteer_work', 'travel'
  )),
  activity_title TEXT NOT NULL CHECK (LENGTH(activity_title) BETWEEN 5 AND 100),
  activity_description TEXT CHECK (LENGTH(activity_description) BETWEEN 20 AND 1000),
  proof_url TEXT,
  points_earned INTEGER DEFAULT 0,
  category TEXT CHECK (category IN ('personal', 'career', 'both')),
  verified BOOLEAN DEFAULT FALSE,
  verified_by UUID REFERENCES users(id),
  activity_date DATE CHECK (activity_date <= CURRENT_DATE),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_singles_activities_user ON singles_activities(user_id);
CREATE INDEX idx_singles_activities_type ON singles_activities(activity_type);
CREATE INDEX idx_singles_activities_date ON singles_activities(activity_date);
CREATE INDEX idx_singles_activities_verified ON singles_activities(verified);

-- Couples leaderboard
CREATE TABLE IF NOT EXISTS couples_leaderboard (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE,
  overall_score INTEGER DEFAULT 0,
  relationship_health_score INTEGER DEFAULT 0,
  communication_score INTEGER DEFAULT 0,
  shared_goals_score INTEGER DEFAULT 0,
  quality_time_score INTEGER DEFAULT 0,
  milestones_achieved INTEGER DEFAULT 0,
  challenges_completed INTEGER DEFAULT 0,
  diary_entries_count INTEGER DEFAULT 0,
  date_nights_count INTEGER DEFAULT 0,
  achievements JSONB DEFAULT '[]'::jsonb,
  badges TEXT[] DEFAULT ARRAY[]::TEXT[],
  rank_overall INTEGER,
  last_updated TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(couple_id)
);

CREATE INDEX idx_couples_leaderboard_couple ON couples_leaderboard(couple_id);
CREATE INDEX idx_couples_leaderboard_overall ON couples_leaderboard(overall_score DESC);

-- Couples milestones
CREATE TABLE IF NOT EXISTS couples_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE,
  milestone_type TEXT CHECK (milestone_type IN (
    'first_date', 'engagement', 'wedding', 'first_anniversary',
    'home_purchase', 'first_child', 'career_goal', 'travel_goal', 'custom'
  )),
  milestone_title TEXT NOT NULL CHECK (LENGTH(milestone_title) BETWEEN 5 AND 100),
  milestone_description TEXT,
  milestone_date DATE CHECK (milestone_date <= CURRENT_DATE),
  points_earned INTEGER DEFAULT 0,
  photos TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_couples_milestones_couple ON couples_milestones(couple_id);
CREATE INDEX idx_couples_milestones_date ON couples_milestones(milestone_date);

-- ============================================
-- DIGITAL GIFTING SYSTEM TABLES
-- ============================================

-- Gift categories
CREATE TABLE IF NOT EXISTS gift_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_name TEXT NOT NULL,
  category_code TEXT UNIQUE NOT NULL,
  description TEXT,
  icon TEXT,
  is_physical BOOLEAN DEFAULT FALSE,
  is_digital BOOLEAN DEFAULT FALSE,
  display_order INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gift_categories_active ON gift_categories(is_active);

-- Gift products/catalog
CREATE TABLE IF NOT EXISTS gift_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES gift_categories(id),
  product_name TEXT NOT NULL,
  product_code TEXT UNIQUE NOT NULL,
  description TEXT,
  brand TEXT,
  product_type TEXT CHECK (product_type IN ('physical', 'digital', 'gift_card', 'experience')),
  base_price DECIMAL(10, 2) NOT NULL CHECK (base_price >= 100),
  discounted_price DECIMAL(10, 2),
  currency TEXT DEFAULT 'INR',
  stock_quantity INTEGER,
  is_unlimited BOOLEAN DEFAULT FALSE,
  images TEXT[] DEFAULT ARRAY[]::TEXT[],
  product_url TEXT,
  vendor_name TEXT,
  commission_rate DECIMAL(5, 2) DEFAULT 5.0,
  delivery_days INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  featured BOOLEAN DEFAULT FALSE,
  rating DECIMAL(3, 2) DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
  total_sales INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gift_products_category ON gift_products(category_id);
CREATE INDEX idx_gift_products_type ON gift_products(product_type);
CREATE INDEX idx_gift_products_price ON gift_products(base_price);
CREATE INDEX idx_gift_products_active ON gift_products(is_active);
CREATE INDEX idx_gift_products_featured ON gift_products(featured);

-- Guest gifts (purchases)
CREATE TABLE IF NOT EXISTS guest_gifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_email TEXT NOT NULL,
  sender_phone TEXT,
  gift_type TEXT CHECK (gift_type IN ('physical_product', 'digital_product', 'gift_card', 'cash', 'custom')),
  product_id UUID REFERENCES gift_products(id),
  gift_amount DECIMAL(10, 2) CHECK (gift_amount >= 100 AND gift_amount <= 50000),
  currency TEXT DEFAULT 'INR',
  gift_message TEXT CHECK (LENGTH(gift_message) <= 500),
  delivery_address JSONB,
  delivery_status TEXT DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'processing', 'shipped', 'delivered', 'failed')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT,
  transaction_id TEXT,
  commission_amount DECIMAL(10, 2),
  gift_card_code TEXT,
  gift_card_pin TEXT,
  redeemed BOOLEAN DEFAULT FALSE,
  redeemed_at TIMESTAMP,
  thank_you_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_guest_gifts_wedding ON guest_gifts(wedding_id);
CREATE INDEX idx_guest_gifts_sender ON guest_gifts(sender_id);
CREATE INDEX idx_guest_gifts_payment ON guest_gifts(payment_status);
CREATE INDEX idx_guest_gifts_delivery ON guest_gifts(delivery_status);

-- Gift wishlists (couple's desired gifts)
CREATE TABLE IF NOT EXISTS gift_wishlists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  couple_id UUID REFERENCES couples(id) ON DELETE CASCADE,
  product_id UUID REFERENCES gift_products(id),
  priority TEXT CHECK (priority IN ('high', 'medium', 'low')),
  quantity_desired INTEGER DEFAULT 1 CHECK (quantity_desired > 0),
  quantity_received INTEGER DEFAULT 0,
  notes TEXT,
  is_public BOOLEAN DEFAULT TRUE,
  added_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gift_wishlists_wedding ON gift_wishlists(wedding_id);
CREATE INDEX idx_gift_wishlists_couple ON gift_wishlists(couple_id);
CREATE INDEX idx_gift_wishlists_priority ON gift_wishlists(priority);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Update participant score after game response
CREATE OR REPLACE FUNCTION update_participant_score()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE game_participants
  SET total_score = total_score + NEW.points_earned,
      games_played = games_played + 1,
      last_played_at = NOW()
  WHERE id = NEW.participant_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_game_response ON game_responses;
CREATE TRIGGER after_game_response
AFTER INSERT ON game_responses
FOR EACH ROW
EXECUTE FUNCTION update_participant_score();

-- Update side competition scores
CREATE OR REPLACE FUNCTION update_side_competition()
RETURNS TRIGGER AS $$
DECLARE
  v_wedding_id UUID;
  v_side TEXT;
BEGIN
  SELECT wg.wedding_id, gp.side
  INTO v_wedding_id, v_side
  FROM game_participants gp
  JOIN wedding_games wg ON gp.wedding_game_id = wg.id
  WHERE gp.id = NEW.participant_id;

  IF v_side = 'groom' THEN
    UPDATE wedding_side_competition
    SET groom_side_score = groom_side_score + NEW.points_earned,
        updated_at = NOW()
    WHERE wedding_id = v_wedding_id;
  ELSIF v_side = 'bride' THEN
    UPDATE wedding_side_competition
    SET bride_side_score = bride_side_score + NEW.points_earned,
        updated_at = NOW()
    WHERE wedding_id = v_wedding_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_game_score_update ON game_responses;
CREATE TRIGGER after_game_score_update
AFTER INSERT ON game_responses
FOR EACH ROW
EXECUTE FUNCTION update_side_competition();

-- Calculate leaderboard ranks
CREATE OR REPLACE FUNCTION calculate_singles_ranks()
RETURNS VOID AS $$
BEGIN
  WITH ranked_users AS (
    SELECT
      id,
      ROW_NUMBER() OVER (ORDER BY overall_score DESC) as overall_rank,
      ROW_NUMBER() OVER (ORDER BY personal_growth_score DESC) as personal_rank,
      ROW_NUMBER() OVER (ORDER BY career_achievement_score DESC) as career_rank
    FROM singles_leaderboard
  )
  UPDATE singles_leaderboard sl
  SET
    rank_overall = ru.overall_rank,
    rank_personal = ru.personal_rank,
    rank_career = ru.career_rank,
    last_updated = NOW()
  FROM ranked_users ru
  WHERE sl.id = ru.id;
END;
$$ LANGUAGE plpgsql;

-- Update singles score on activity verification
CREATE OR REPLACE FUNCTION update_singles_score_on_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.verified = TRUE AND OLD.verified = FALSE THEN
    -- Update personal growth score
    IF NEW.category = 'personal' OR NEW.category = 'both' THEN
      UPDATE singles_leaderboard
      SET personal_growth_score = personal_growth_score + NEW.points_earned,
          overall_score = overall_score + NEW.points_earned,
          last_updated = NOW()
      WHERE user_id = NEW.user_id;
    END IF;

    -- Update career score
    IF NEW.category = 'career' OR NEW.category = 'both' THEN
      UPDATE singles_leaderboard
      SET career_achievement_score = career_achievement_score + NEW.points_earned,
          overall_score = overall_score + NEW.points_earned,
          last_updated = NOW()
      WHERE user_id = NEW.user_id;
    END IF;

    -- Recalculate ranks
    PERFORM calculate_singles_ranks();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_activity_verification ON singles_activities;
CREATE TRIGGER after_activity_verification
AFTER UPDATE ON singles_activities
FOR EACH ROW
WHEN (NEW.verified = TRUE AND OLD.verified = FALSE)
EXECUTE FUNCTION update_singles_score_on_activity();

-- Update couples score on milestone
CREATE OR REPLACE FUNCTION update_couples_score_on_milestone()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE couples_leaderboard
  SET milestones_achieved = milestones_achieved + 1,
      overall_score = overall_score + NEW.points_earned,
      last_updated = NOW()
  WHERE couple_id = NEW.couple_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_milestone_creation ON couples_milestones;
CREATE TRIGGER after_milestone_creation
AFTER INSERT ON couples_milestones
FOR EACH ROW
EXECUTE FUNCTION update_couples_score_on_milestone();

-- Calculate gift commission
CREATE OR REPLACE FUNCTION calculate_gift_commission()
RETURNS TRIGGER AS $$
DECLARE
  v_commission_rate DECIMAL(5,2);
  v_commission_amount DECIMAL(10,2);
BEGIN
  IF NEW.product_id IS NOT NULL AND NEW.gift_type != 'cash' THEN
    SELECT commission_rate INTO v_commission_rate
    FROM gift_products
    WHERE id = NEW.product_id;

    v_commission_amount := NEW.gift_amount * v_commission_rate / 100;
    NEW.commission_amount := v_commission_amount;
  ELSE
    NEW.commission_amount := 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS before_gift_insert ON guest_gifts;
CREATE TRIGGER before_gift_insert
BEFORE INSERT ON guest_gifts
FOR EACH ROW
EXECUTE FUNCTION calculate_gift_commission();

-- Update photo challenge votes
CREATE OR REPLACE FUNCTION update_photo_challenge_votes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE photo_challenge_submissions
    SET votes_count = votes_count + 1
    WHERE id = NEW.submission_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE photo_challenge_submissions
    SET votes_count = votes_count - 1
    WHERE id = OLD.submission_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_photo_vote ON photo_challenge_votes;
CREATE TRIGGER after_photo_vote
AFTER INSERT OR DELETE ON photo_challenge_votes
FOR EACH ROW
EXECUTE FUNCTION update_photo_challenge_votes();

-- ============================================
-- ROW LEVEL SECURITY (RLS) - DISABLED FOR TESTING
-- ============================================
-- RLS policies have been moved to sql/rls_policies.sql
-- Execute rls_policies.sql separately after testing to enable security

-- ============================================
-- SEED DATA - DEFAULT GAME TYPES
-- ============================================

INSERT INTO game_types (game_code, game_name, game_category, description, scoring_method) VALUES
('quiz_couple', 'How Well Do You Know the Couple?', 'quiz', 'Test your knowledge about the couple''s love story', 'points'),
('quiz_traditions', 'Wedding Traditions Quiz', 'trivia', 'Test your knowledge of global wedding traditions', 'points'),
('prediction_future', 'Predict the Couple''s Future', 'prediction', 'Make fun predictions about the couple''s life together', 'points'),
('photo_best_moment', 'Best Wedding Moment', 'photo_challenge', 'Submit and vote for the best wedding photo', 'votes'),
('trivia_general', 'General Trivia', 'trivia', 'Fun general knowledge quiz', 'points')
ON CONFLICT (game_code) DO NOTHING;

-- ============================================
-- SEED DATA - GIFT CATEGORIES
-- ============================================

INSERT INTO gift_categories (category_name, category_code, is_physical, is_digital, display_order) VALUES
('Home & Kitchen', 'home_kitchen', TRUE, FALSE, 1),
('Electronics', 'electronics', TRUE, FALSE, 2),
('Gift Cards', 'gift_cards', FALSE, TRUE, 3),
('Cash Gift', 'cash', FALSE, TRUE, 4),
('Experiences', 'experiences', FALSE, FALSE, 5)
ON CONFLICT (category_code) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Run these to verify migration success:
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE '%game%' OR table_name LIKE '%gift%' OR table_name LIKE '%leaderboard%';
-- Expected: 17 new tables

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Phase 5 tables created successfully!
-- Next: Run Phase 6 migration for Post-Marriage & Premium features
-- ============================================
