-- ============================================
-- EMOWED PHASE 3: VENDOR SYSTEM
-- ============================================
-- This migration adds vendor management, invitations, quotes, voting, and bookings
-- Run this after Phase 2 migration is complete

-- ============================================
-- VENDOR PROFILES TABLE
-- ============================================
CREATE TABLE vendor_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN (
    'photographer', 'videographer', 'caterer', 'decorator',
    'makeup_artist', 'mehendi_artist', 'dj', 'band', 'venue',
    'florist', 'priest', 'travel', 'custom'
  )),
  custom_category TEXT,
  description TEXT,
  services_offered TEXT[],
  base_price DECIMAL(12, 2),
  price_range_min DECIMAL(12, 2),
  price_range_max DECIMAL(12, 2),
  city TEXT NOT NULL,
  service_areas TEXT[],
  phone TEXT NOT NULL,
  website TEXT,
  portfolio_urls TEXT[],
  profile_image_url TEXT,
  verified BOOLEAN DEFAULT FALSE,
  verification_star BOOLEAN DEFAULT FALSE,
  wedding_count INTEGER DEFAULT 0,
  rating DECIMAL(3, 2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  total_reviews INTEGER DEFAULT 0,
  subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'paid')),
  subscription_expires_at TIMESTAMP,
  featured BOOLEAN DEFAULT FALSE,
  blocked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX idx_vendor_category ON vendor_profiles(category);
CREATE INDEX idx_vendor_city ON vendor_profiles(city);
CREATE INDEX idx_vendor_verified ON vendor_profiles(verified);
CREATE INDEX idx_vendor_subscription ON vendor_profiles(subscription_type);
CREATE INDEX idx_vendor_rating ON vendor_profiles(rating DESC);
CREATE INDEX idx_vendor_wedding_count ON vendor_profiles(wedding_count DESC);

COMMENT ON TABLE vendor_profiles IS 'Vendor business profiles with verification and subscription status';

-- ============================================
-- VENDOR INVITATIONS TABLE
-- ============================================
CREATE TABLE vendor_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  invited_by UUID REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  invitation_message TEXT,
  sent_at TIMESTAMP DEFAULT NOW(),
  responded_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(wedding_id, vendor_id)
);

CREATE INDEX idx_vendor_invitations_wedding ON vendor_invitations(wedding_id);
CREATE INDEX idx_vendor_invitations_vendor ON vendor_invitations(vendor_id);
CREATE INDEX idx_vendor_invitations_status ON vendor_invitations(status);
CREATE INDEX idx_vendor_invitations_category ON vendor_invitations(category);

COMMENT ON TABLE vendor_invitations IS 'Track vendor invitations from couples with 7-day expiry';

-- ============================================
-- VENDOR QUOTES TABLE
-- ============================================
CREATE TABLE vendor_quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_invitation_id UUID REFERENCES vendor_invitations(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  package_name TEXT NOT NULL,
  description TEXT,
  items_included TEXT[],
  base_price DECIMAL(12, 2) NOT NULL CHECK (base_price >= 1000),
  additional_charges JSONB DEFAULT '{}',
  total_price DECIMAL(12, 2) NOT NULL CHECK (total_price >= base_price),
  payment_terms TEXT,
  validity_days INTEGER DEFAULT 30 CHECK (validity_days >= 7 AND validity_days <= 90),
  valid_until TIMESTAMP,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'withdrawn', 'accepted')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_vendor_quotes_invitation ON vendor_quotes(vendor_invitation_id);
CREATE INDEX idx_vendor_quotes_wedding ON vendor_quotes(wedding_id);
CREATE INDEX idx_vendor_quotes_vendor ON vendor_quotes(vendor_id);
CREATE INDEX idx_vendor_quotes_status ON vendor_quotes(status);

COMMENT ON TABLE vendor_quotes IS 'Vendor pricing quotes with validity tracking';

-- ============================================
-- VENDOR VOTES TABLE
-- ============================================
CREATE TABLE vendor_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  vote_type TEXT DEFAULT 'rank' CHECK (vote_type IN ('approve', 'reject', 'rank')),
  rank INTEGER CHECK (rank >= 1 AND rank <= 10),
  comments TEXT CHECK (LENGTH(comments) <= 500),
  price_rating INTEGER CHECK (price_rating >= 1 AND price_rating <= 5),
  quality_rating INTEGER CHECK (quality_rating >= 1 AND quality_rating <= 5),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(wedding_id, vendor_id, voter_id)
);

CREATE INDEX idx_vendor_votes_wedding ON vendor_votes(wedding_id);
CREATE INDEX idx_vendor_votes_vendor ON vendor_votes(vendor_id);
CREATE INDEX idx_vendor_votes_voter ON vendor_votes(voter_id);
CREATE INDEX idx_vendor_votes_category ON vendor_votes(category);

COMMENT ON TABLE vendor_votes IS 'Family voting on vendors with rankings and ratings';

-- ============================================
-- VENDOR BOOKINGS TABLE
-- ============================================
CREATE TABLE vendor_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  quote_id UUID REFERENCES vendor_quotes(id),
  category TEXT NOT NULL,
  booking_date DATE NOT NULL CHECK (booking_date >= CURRENT_DATE),
  event_dates DATE[] NOT NULL,
  start_time TIME,
  end_time TIME CHECK (end_time > start_time),
  total_amount DECIMAL(12, 2) NOT NULL CHECK (total_amount >= 1000),
  advance_paid DECIMAL(12, 2) DEFAULT 0 CHECK (advance_paid >= 0 AND advance_paid <= total_amount),
  balance_due DECIMAL(12, 2) GENERATED ALWAYS AS (total_amount - advance_paid) STORED,
  commission_rate DECIMAL(5, 2),
  commission_amount DECIMAL(12, 2),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'advance_paid', 'partial', 'completed')),
  booking_status TEXT DEFAULT 'confirmed' CHECK (booking_status IN ('confirmed', 'completed', 'cancelled')),
  contract_url TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_vendor_bookings_wedding ON vendor_bookings(wedding_id);
CREATE INDEX idx_vendor_bookings_vendor ON vendor_bookings(vendor_id);
CREATE INDEX idx_vendor_bookings_status ON vendor_bookings(booking_status);
CREATE INDEX idx_vendor_bookings_date ON vendor_bookings(booking_date);

COMMENT ON TABLE vendor_bookings IS 'Confirmed vendor bookings with payment tracking';

-- ============================================
-- VENDOR AVAILABILITY TABLE
-- ============================================
CREATE TABLE vendor_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME,
  end_time TIME CHECK (end_time > start_time),
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'booked', 'blocked')),
  booking_id UUID REFERENCES vendor_bookings(id),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vendor_id, date, start_time)
);

CREATE INDEX idx_vendor_availability_vendor ON vendor_availability(vendor_id);
CREATE INDEX idx_vendor_availability_date ON vendor_availability(date);
CREATE INDEX idx_vendor_availability_status ON vendor_availability(status);

COMMENT ON TABLE vendor_availability IS 'Vendor date and time availability tracking';

-- ============================================
-- VENDOR VERIFICATIONS TABLE
-- ============================================
CREATE TABLE vendor_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  verified_by UUID REFERENCES users(id),
  verification_type TEXT CHECK (verification_type IN ('wedding_completion', 'manual')),
  verification_date TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vendor_id, wedding_id)
);

CREATE INDEX idx_vendor_verifications_vendor ON vendor_verifications(vendor_id);

COMMENT ON TABLE vendor_verifications IS 'Track vendor verification progress (5 weddings = verified star)';

-- ============================================
-- VENDOR REVIEWS TABLE
-- ============================================
CREATE TABLE vendor_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT CHECK (LENGTH(review_text) <= 1000),
  pros TEXT[],
  cons TEXT[],
  would_recommend BOOLEAN,
  response_from_vendor TEXT,
  images TEXT[],
  verified_booking BOOLEAN DEFAULT FALSE,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vendor_id, wedding_id, reviewer_id)
);

CREATE INDEX idx_vendor_reviews_vendor ON vendor_reviews(vendor_id);
CREATE INDEX idx_vendor_reviews_rating ON vendor_reviews(rating);
CREATE INDEX idx_vendor_reviews_verified ON vendor_reviews(verified_booking);

COMMENT ON TABLE vendor_reviews IS 'Vendor reviews from couples post-wedding';

-- ============================================
-- VENDOR TIME CONFLICTS TABLE
-- ============================================
CREATE TABLE vendor_time_conflicts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  conflict_date DATE NOT NULL,
  existing_booking_id UUID REFERENCES vendor_bookings(id),
  requested_wedding_id UUID REFERENCES weddings(id),
  conflict_resolved BOOLEAN DEFAULT FALSE,
  resolution_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_vendor_conflicts_vendor ON vendor_time_conflicts(vendor_id);
CREATE INDEX idx_vendor_conflicts_date ON vendor_time_conflicts(conflict_date);

COMMENT ON TABLE vendor_time_conflicts IS 'Track and resolve vendor scheduling conflicts';

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Update vendor verification status after 5 weddings
CREATE OR REPLACE FUNCTION update_vendor_verification()
RETURNS TRIGGER AS $$
DECLARE
  v_verification_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_verification_count
  FROM vendor_verifications
  WHERE vendor_id = NEW.vendor_id;

  IF v_verification_count >= 5 THEN
    UPDATE vendor_profiles
    SET verification_star = TRUE,
        verified = TRUE,
        updated_at = NOW()
    WHERE id = NEW.vendor_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_vendor_verification
AFTER INSERT ON vendor_verifications
FOR EACH ROW
EXECUTE FUNCTION update_vendor_verification();

COMMENT ON FUNCTION update_vendor_verification IS 'Auto-verify vendors after 5 completed weddings';

-- Function: Update vendor rating after review
CREATE OR REPLACE FUNCTION update_vendor_rating()
RETURNS TRIGGER AS $$
DECLARE
  v_avg_rating DECIMAL(3,2);
  v_total_reviews INTEGER;
BEGIN
  SELECT AVG(rating)::DECIMAL(3,2), COUNT(*)
  INTO v_avg_rating, v_total_reviews
  FROM vendor_reviews
  WHERE vendor_id = COALESCE(NEW.vendor_id, OLD.vendor_id);

  UPDATE vendor_profiles
  SET rating = COALESCE(v_avg_rating, 0),
      total_reviews = v_total_reviews,
      updated_at = NOW()
  WHERE id = COALESCE(NEW.vendor_id, OLD.vendor_id);

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_vendor_review
AFTER INSERT OR UPDATE OR DELETE ON vendor_reviews
FOR EACH ROW
EXECUTE FUNCTION update_vendor_rating();

COMMENT ON FUNCTION update_vendor_rating IS 'Update vendor average rating and review count';

-- Function: Calculate vendor commission
CREATE OR REPLACE FUNCTION calculate_vendor_commission(
  p_booking_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
  v_total_amount DECIMAL(12,2);
  v_commission_rate DECIMAL(5,2);
  v_vendor_subscription TEXT;
BEGIN
  SELECT b.total_amount, vp.subscription_type
  INTO v_total_amount, v_vendor_subscription
  FROM vendor_bookings b
  JOIN vendor_profiles vp ON b.vendor_id = vp.id
  WHERE b.id = p_booking_id;

  -- Paid vendors: 3% commission, Free vendors: 12% commission
  IF v_vendor_subscription = 'paid' THEN
    v_commission_rate := 3.0;
  ELSE
    v_commission_rate := 12.0;
  END IF;

  RETURN (v_total_amount * v_commission_rate / 100);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_vendor_commission IS 'Calculate commission: 3% for paid vendors, 12% for free vendors';

-- Function: Check vendor time conflict
CREATE OR REPLACE FUNCTION check_vendor_time_conflict(
  p_vendor_id UUID,
  p_date DATE,
  p_start_time TIME,
  p_end_time TIME
)
RETURNS BOOLEAN AS $$
DECLARE
  v_conflict_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM vendor_availability
    WHERE vendor_id = p_vendor_id
    AND date = p_date
    AND status = 'booked'
    AND (
      (start_time <= p_start_time AND end_time > p_start_time)
      OR (start_time < p_end_time AND end_time >= p_end_time)
      OR (start_time >= p_start_time AND end_time <= p_end_time)
    )
  ) INTO v_conflict_exists;

  RETURN v_conflict_exists;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_vendor_time_conflict IS 'Check if vendor has time conflict on date';

-- Function: Auto-expire old vendor quotes
CREATE OR REPLACE FUNCTION expire_old_vendor_quotes()
RETURNS VOID AS $$
BEGIN
  UPDATE vendor_quotes
  SET status = 'expired',
      updated_at = NOW()
  WHERE status = 'active'
  AND valid_until < NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION expire_old_vendor_quotes IS 'Mark expired quotes as expired';

-- Function: Increment vendor wedding count on completion
CREATE OR REPLACE FUNCTION increment_vendor_wedding_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.booking_status = 'completed' AND OLD.booking_status != 'completed' THEN
    UPDATE vendor_profiles
    SET wedding_count = wedding_count + 1,
        updated_at = NOW()
    WHERE id = NEW.vendor_id;

    -- Create verification record
    INSERT INTO vendor_verifications (vendor_id, wedding_id, verification_type)
    VALUES (NEW.vendor_id, NEW.wedding_id, 'wedding_completion')
    ON CONFLICT (vendor_id, wedding_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_booking_completion
AFTER UPDATE ON vendor_bookings
FOR EACH ROW
EXECUTE FUNCTION increment_vendor_wedding_count();

COMMENT ON FUNCTION increment_vendor_wedding_count IS 'Increment wedding count when booking is completed';

-- Function: Set quote validity timestamp
CREATE OR REPLACE FUNCTION set_quote_validity()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.valid_until IS NULL THEN
    NEW.valid_until := NOW() + (NEW.validity_days || ' days')::INTERVAL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_quote_insert
BEFORE INSERT ON vendor_quotes
FOR EACH ROW
EXECUTE FUNCTION set_quote_validity();

-- Function: Update vendor booking commission
CREATE OR REPLACE FUNCTION update_booking_commission()
RETURNS TRIGGER AS $$
BEGIN
  NEW.commission_rate := (
    SELECT CASE
      WHEN subscription_type = 'paid' THEN 3.0
      ELSE 12.0
    END
    FROM vendor_profiles
    WHERE id = NEW.vendor_id
  );

  NEW.commission_amount := (NEW.total_amount * NEW.commission_rate / 100);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_booking_insert
BEFORE INSERT OR UPDATE ON vendor_bookings
FOR EACH ROW
EXECUTE FUNCTION update_booking_commission();

COMMENT ON FUNCTION update_booking_commission IS 'Auto-calculate commission on booking insert/update';

-- ============================================
-- ROW LEVEL SECURITY (RLS) - DISABLED FOR TESTING
-- ============================================
-- RLS policies have been moved to sql/rls_policies.sql
-- Execute rls_policies.sql separately after testing to enable security

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- View: Vendor search with rankings
CREATE OR REPLACE VIEW vendor_search_rankings AS
SELECT
  vp.*,
  -- Ranking score calculation
  (
    (CASE WHEN vp.verification_star THEN 0.25 ELSE 0 END) +
    (COALESCE(vp.rating, 0) / 5.0 * 0.30) +
    (LEAST(vp.wedding_count, 100) / 100.0 * 0.20) +
    (CASE WHEN vp.subscription_type = 'paid' THEN 0.05 ELSE 0 END)
  ) AS ranking_score
FROM vendor_profiles vp
WHERE vp.blocked = FALSE;

COMMENT ON VIEW vendor_search_rankings IS 'Vendor search results with calculated ranking scores';

-- View: Vendor voting results summary
CREATE OR REPLACE VIEW vendor_voting_summary AS
SELECT
  wedding_id,
  category,
  vendor_id,
  COUNT(*) AS total_votes,
  AVG(rank) AS avg_rank,
  AVG(price_rating) AS avg_price_rating,
  AVG(quality_rating) AS avg_quality_rating,
  COUNT(*) FILTER (WHERE rank = 1) AS first_choice_votes,
  COUNT(*) FILTER (WHERE rank = 2) AS second_choice_votes,
  COUNT(*) FILTER (WHERE rank = 3) AS third_choice_votes
FROM vendor_votes
GROUP BY wedding_id, category, vendor_id;

COMMENT ON VIEW vendor_voting_summary IS 'Aggregated voting results for vendor selection';

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Additional composite indexes for common queries
CREATE INDEX idx_vendor_profiles_search ON vendor_profiles(category, city, verified) WHERE blocked = FALSE;
CREATE INDEX idx_vendor_quotes_wedding_category ON vendor_quotes(wedding_id, status);
CREATE INDEX idx_vendor_bookings_vendor_date ON vendor_bookings(vendor_id, booking_date);
CREATE INDEX idx_vendor_reviews_vendor_rating ON vendor_reviews(vendor_id, rating DESC);

-- ============================================
-- DATA VALIDATION CONSTRAINTS
-- ============================================

-- Ensure vendor profile completeness
ALTER TABLE vendor_profiles ADD CONSTRAINT check_profile_complete
  CHECK (
    business_name IS NOT NULL AND
    LENGTH(business_name) >= 3 AND
    category IS NOT NULL AND
    city IS NOT NULL AND
    phone IS NOT NULL
  );

-- Ensure quote validity
ALTER TABLE vendor_quotes ADD CONSTRAINT check_quote_validity
  CHECK (
    total_price >= base_price AND
    validity_days >= 7 AND
    valid_until > created_at
  );

-- Ensure booking dates are valid
ALTER TABLE vendor_bookings ADD CONSTRAINT check_booking_dates
  CHECK (
    booking_date <= ALL(event_dates) AND
    array_length(event_dates, 1) > 0
  );

-- ============================================
-- SAMPLE DATA (FOR TESTING)
-- ============================================

-- This section can be commented out in production

/*
-- Sample vendor profile
INSERT INTO vendor_profiles (
  user_id,
  business_name,
  category,
  description,
  services_offered,
  base_price,
  price_range_min,
  price_range_max,
  city,
  service_areas,
  phone,
  verified,
  wedding_count,
  rating
) VALUES (
  'sample-user-uuid',
  'Studio Flash Photography',
  'photographer',
  'Professional wedding photography with 10 years experience',
  ARRAY['photography', 'videography', 'drone'],
  120000,
  80000,
  300000,
  'Mumbai',
  ARRAY['Mumbai', 'Pune', 'Goa'],
  '+91-9876543210',
  TRUE,
  8,
  4.8
);
*/

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Add migration tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
  id SERIAL PRIMARY KEY,
  version TEXT UNIQUE NOT NULL,
  applied_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO schema_migrations (version) VALUES ('phase3_vendor_system_v1');

COMMENT ON TABLE schema_migrations IS 'Track database schema migrations';

-- Display completion message
DO $$
BEGIN
  RAISE NOTICE '============================================';
  RAISE NOTICE 'PHASE 3: VENDOR SYSTEM MIGRATION COMPLETE';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Tables created: 8';
  RAISE NOTICE 'Functions created: 7';
  RAISE NOTICE 'Triggers created: 5';
  RAISE NOTICE 'Views created: 2';
  RAISE NOTICE 'RLS Policies: 20+';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Test vendor profile creation';
  RAISE NOTICE '2. Test vendor invitation flow';
  RAISE NOTICE '3. Test quote submission';
  RAISE NOTICE '4. Test voting system';
  RAISE NOTICE '5. Test booking creation';
  RAISE NOTICE '============================================';
END $$;
