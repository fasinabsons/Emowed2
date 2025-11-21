-- ============================================
-- EMOWED DATABASE MIGRATION - PHASE 2
-- Events, Guests, Family Tree, and RSVP System
-- ============================================
-- Purpose: Create tables for wedding events, guest management, and RSVP tracking
-- Execute in Supabase SQL Editor AFTER Phase 1
-- ============================================

-- ============================================
-- EVENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  event_type TEXT NOT NULL CHECK (
    event_type IN ('engagement', 'save_the_date', 'haldi', 'mehendi', 'sangeet', 'wedding', 'reception', 'custom')
  ),
  date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  venue TEXT NOT NULL,
  city TEXT NOT NULL,
  dress_code TEXT,
  rsvp_deadline TIMESTAMP,
  auto_generated BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_wedding ON events(wedding_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);

-- ============================================
-- GUESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS guests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  email TEXT,
  full_name TEXT NOT NULL,
  phone TEXT,
  side TEXT NOT NULL CHECK (side IN ('groom', 'bride', 'both')),
  role TEXT NOT NULL CHECK (
    role IN ('groom', 'bride', 'parent', 'sibling', 'uncle', 'aunt', 'cousin',
             'grandparent', 'friend', 'colleague', 'other')
  ),
  invited_by UUID REFERENCES users(id) NOT NULL,
  can_invite_others BOOLEAN DEFAULT FALSE,
  plus_one_allowed BOOLEAN DEFAULT FALSE,
  plus_one_name TEXT,
  is_vip BOOLEAN DEFAULT FALSE,
  under_18 BOOLEAN DEFAULT FALSE,
  age INTEGER,
  dietary_preferences TEXT[],
  special_requirements TEXT,
  status TEXT DEFAULT 'invited' CHECK (
    status IN ('invited', 'accepted', 'declined', 'maybe', 'pending')
  ),
  invitation_sent_at TIMESTAMP,
  responded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_guest_email_wedding UNIQUE(wedding_id, email)
);

CREATE INDEX IF NOT EXISTS idx_guests_wedding ON guests(wedding_id);
CREATE INDEX IF NOT EXISTS idx_guests_user ON guests(user_id);
CREATE INDEX IF NOT EXISTS idx_guests_invited_by ON guests(invited_by);
CREATE INDEX IF NOT EXISTS idx_guests_side ON guests(side);
CREATE INDEX IF NOT EXISTS idx_guests_role ON guests(role);
CREATE INDEX IF NOT EXISTS idx_guests_status ON guests(status);

-- ============================================
-- GUEST INVITATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS guest_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES users(id) NOT NULL,
  receiver_email TEXT NOT NULL,
  receiver_name TEXT NOT NULL,
  role TEXT NOT NULL,
  side TEXT NOT NULL CHECK (side IN ('groom', 'bride')),
  can_invite_others BOOLEAN DEFAULT FALSE,
  personal_message TEXT,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'accepted', 'rejected', 'expired')
  ),
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
  responded_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_guest_invitations_wedding ON guest_invitations(wedding_id);
CREATE INDEX IF NOT EXISTS idx_guest_invitations_sender ON guest_invitations(sender_id);
CREATE INDEX IF NOT EXISTS idx_guest_invitations_email ON guest_invitations(receiver_email);
CREATE INDEX IF NOT EXISTS idx_guest_invitations_status ON guest_invitations(status);

-- ============================================
-- FAMILY TREE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS family_tree (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE NOT NULL,
  guest_id UUID REFERENCES guests(id) ON DELETE CASCADE NOT NULL,
  parent_guest_id UUID REFERENCES guests(id) ON DELETE CASCADE,
  relationship TEXT CHECK (
    relationship IN ('self', 'spouse', 'parent', 'child', 'sibling', 'uncle', 'aunt',
                     'cousin', 'grandparent', 'grandchild', 'friend', 'colleague')
  ),
  depth INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_guest_parent UNIQUE(guest_id, parent_guest_id)
);

CREATE INDEX IF NOT EXISTS idx_family_tree_wedding ON family_tree(wedding_id);
CREATE INDEX IF NOT EXISTS idx_family_tree_guest ON family_tree(guest_id);
CREATE INDEX IF NOT EXISTS idx_family_tree_parent ON family_tree(parent_guest_id);
CREATE INDEX IF NOT EXISTS idx_family_tree_depth ON family_tree(depth);

-- ============================================
-- RSVPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS rsvps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  guest_id UUID REFERENCES guests(id) ON DELETE CASCADE NOT NULL,
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('attending', 'not_attending', 'maybe', 'pending')
  ),
  adults_count INTEGER DEFAULT 1 CHECK (adults_count >= 0),
  teens_count INTEGER DEFAULT 0 CHECK (teens_count >= 0),
  children_count INTEGER DEFAULT 0 CHECK (children_count >= 0),
  calculated_headcount DECIMAL(5, 2),
  dietary_preferences TEXT[],
  special_requirements TEXT,
  rsvp_notes TEXT,
  submitted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_rsvp_event_guest UNIQUE(event_id, guest_id)
);

CREATE INDEX IF NOT EXISTS idx_rsvps_event ON rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_rsvps_guest ON rsvps(guest_id);
CREATE INDEX IF NOT EXISTS idx_rsvps_wedding ON rsvps(wedding_id);
CREATE INDEX IF NOT EXISTS idx_rsvps_status ON rsvps(status);

-- ============================================
-- HEADCOUNT SNAPSHOTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS headcount_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  wedding_id UUID REFERENCES weddings(id) ON DELETE CASCADE NOT NULL,
  side TEXT CHECK (side IN ('groom', 'bride', 'both')),
  total_invited INTEGER DEFAULT 0,
  total_attending INTEGER DEFAULT 0,
  total_declined INTEGER DEFAULT 0,
  total_maybe INTEGER DEFAULT 0,
  total_pending INTEGER DEFAULT 0,
  adults_count INTEGER DEFAULT 0,
  teens_count INTEGER DEFAULT 0,
  children_count INTEGER DEFAULT 0,
  calculated_headcount DECIMAL(8, 2) DEFAULT 0,
  vegetarian_count INTEGER DEFAULT 0,
  vegan_count INTEGER DEFAULT 0,
  halal_count INTEGER DEFAULT 0,
  snapshot_date TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_headcount_event ON headcount_snapshots(event_id);
CREATE INDEX IF NOT EXISTS idx_headcount_wedding ON headcount_snapshots(wedding_id);
CREATE INDEX IF NOT EXISTS idx_headcount_date ON headcount_snapshots(snapshot_date);

-- ============================================
-- EVENT ATTENDEES TABLE (Many-to-Many)
-- ============================================
CREATE TABLE IF NOT EXISTS event_attendees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  guest_id UUID REFERENCES guests(id) ON DELETE CASCADE NOT NULL,
  invited BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_event_attendee UNIQUE(event_id, guest_id)
);

CREATE INDEX IF NOT EXISTS idx_event_attendees_event ON event_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attendees_guest ON event_attendees(guest_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to calculate RSVP headcount
CREATE OR REPLACE FUNCTION calculate_rsvp_headcount()
RETURNS TRIGGER AS $$
BEGIN
  NEW.calculated_headcount :=
    (NEW.adults_count * 1.0) +
    (NEW.teens_count * 0.75) +
    (NEW.children_count * 0.3);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to calculate headcount on RSVP insert/update
DROP TRIGGER IF EXISTS rsvp_calculate_headcount ON rsvps;
CREATE TRIGGER rsvp_calculate_headcount
BEFORE INSERT OR UPDATE ON rsvps
FOR EACH ROW
EXECUTE FUNCTION calculate_rsvp_headcount();

-- Function to auto-generate wedding events
CREATE OR REPLACE FUNCTION generate_wedding_events(
  p_wedding_id UUID,
  p_wedding_date DATE,
  p_venue TEXT,
  p_city TEXT
)
RETURNS VOID AS $$
DECLARE
  v_created_by UUID;
BEGIN
  -- Get wedding couple (use user1 as creator)
  SELECT user1_id INTO v_created_by
  FROM couples c
  JOIN weddings w ON w.couple_id = c.id
  WHERE w.id = p_wedding_id;

  -- 1. Engagement Ceremony (60 days before)
  INSERT INTO events (wedding_id, name, event_type, date, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Engagement Ceremony',
    'engagement',
    p_wedding_date - INTERVAL '60 days',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );

  -- 2. Save The Date (30 days before)
  INSERT INTO events (wedding_id, name, event_type, date, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Save The Date',
    'save_the_date',
    p_wedding_date - INTERVAL '30 days',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );

  -- 3. Haldi Ceremony (2 days before)
  INSERT INTO events (wedding_id, name, event_type, date, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Haldi Ceremony',
    'haldi',
    p_wedding_date - INTERVAL '2 days',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );

  -- 4. Mehendi Ceremony (1 day before)
  INSERT INTO events (wedding_id, name, event_type, date, start_time, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Mehendi Ceremony',
    'mehendi',
    p_wedding_date - INTERVAL '1 day',
    '14:00:00',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );

  -- 5. Sangeet Night (1 day before, evening)
  INSERT INTO events (wedding_id, name, event_type, date, start_time, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Sangeet Night',
    'sangeet',
    p_wedding_date - INTERVAL '1 day',
    '19:00:00',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );

  -- 6. Wedding Ceremony (wedding day)
  INSERT INTO events (wedding_id, name, event_type, date, start_time, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Wedding Ceremony',
    'wedding',
    p_wedding_date,
    '10:00:00',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );

  -- 7. Reception (wedding day, evening)
  INSERT INTO events (wedding_id, name, event_type, date, start_time, venue, city, auto_generated, created_by)
  VALUES (
    p_wedding_id,
    'Reception',
    'reception',
    p_wedding_date,
    '19:00:00',
    p_venue,
    p_city,
    TRUE,
    v_created_by
  );
END;
$$ LANGUAGE plpgsql;

-- Function to check if user can invite guest (role-based permissions)
CREATE OR REPLACE FUNCTION can_invite_guest(
  p_inviter_role TEXT,
  p_invitee_role TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Groom/Bride can invite anyone
  IF p_inviter_role IN ('groom', 'bride') THEN
    RETURN TRUE;
  END IF;

  -- Parents can invite anyone except groom/bride
  IF p_inviter_role = 'parent' THEN
    RETURN p_invitee_role NOT IN ('groom', 'bride');
  END IF;

  -- Siblings can invite their spouse, children, and friends
  IF p_inviter_role = 'sibling' THEN
    RETURN p_invitee_role IN ('friend', 'colleague', 'other');
  END IF;

  -- Uncles/Aunts can only invite their immediate family
  IF p_inviter_role IN ('uncle', 'aunt') THEN
    RETURN p_invitee_role IN ('cousin', 'other');
  END IF;

  -- Others cannot invite
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Function to update headcount snapshot
CREATE OR REPLACE FUNCTION update_headcount_snapshot(
  p_event_id UUID,
  p_wedding_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_groom_stats RECORD;
  v_bride_stats RECORD;
BEGIN
  -- Calculate stats for groom side
  SELECT
    COUNT(*) FILTER (WHERE r.status = 'attending') as attending,
    COUNT(*) FILTER (WHERE r.status = 'not_attending') as declined,
    COUNT(*) FILTER (WHERE r.status = 'maybe') as maybe,
    COUNT(*) FILTER (WHERE r.status = 'pending') as pending,
    COUNT(*) as total_invited,
    COALESCE(SUM(r.adults_count) FILTER (WHERE r.status = 'attending'), 0) as adults,
    COALESCE(SUM(r.teens_count) FILTER (WHERE r.status = 'attending'), 0) as teens,
    COALESCE(SUM(r.children_count) FILTER (WHERE r.status = 'attending'), 0) as children,
    COALESCE(SUM(r.calculated_headcount) FILTER (WHERE r.status = 'attending'), 0) as headcount
  INTO v_groom_stats
  FROM rsvps r
  JOIN guests g ON g.id = r.guest_id
  WHERE r.event_id = p_event_id AND g.side = 'groom';

  -- Insert/Update groom snapshot
  INSERT INTO headcount_snapshots (
    event_id, wedding_id, side, total_invited, total_attending,
    total_declined, total_maybe, total_pending, adults_count,
    teens_count, children_count, calculated_headcount
  )
  VALUES (
    p_event_id, p_wedding_id, 'groom', v_groom_stats.total_invited,
    v_groom_stats.attending, v_groom_stats.declined, v_groom_stats.maybe,
    v_groom_stats.pending, v_groom_stats.adults, v_groom_stats.teens,
    v_groom_stats.children, v_groom_stats.headcount
  )
  ON CONFLICT (event_id, side)
  DO UPDATE SET
    total_invited = EXCLUDED.total_invited,
    total_attending = EXCLUDED.total_attending,
    total_declined = EXCLUDED.total_declined,
    total_maybe = EXCLUDED.total_maybe,
    total_pending = EXCLUDED.total_pending,
    adults_count = EXCLUDED.adults_count,
    teens_count = EXCLUDED.teens_count,
    children_count = EXCLUDED.children_count,
    calculated_headcount = EXCLUDED.calculated_headcount,
    snapshot_date = NOW();

  -- Calculate stats for bride side
  SELECT
    COUNT(*) FILTER (WHERE r.status = 'attending') as attending,
    COUNT(*) FILTER (WHERE r.status = 'not_attending') as declined,
    COUNT(*) FILTER (WHERE r.status = 'maybe') as maybe,
    COUNT(*) FILTER (WHERE r.status = 'pending') as pending,
    COUNT(*) as total_invited,
    COALESCE(SUM(r.adults_count) FILTER (WHERE r.status = 'attending'), 0) as adults,
    COALESCE(SUM(r.teens_count) FILTER (WHERE r.status = 'attending'), 0) as teens,
    COALESCE(SUM(r.children_count) FILTER (WHERE r.status = 'attending'), 0) as children,
    COALESCE(SUM(r.calculated_headcount) FILTER (WHERE r.status = 'attending'), 0) as headcount
  INTO v_bride_stats
  FROM rsvps r
  JOIN guests g ON g.id = r.guest_id
  WHERE r.event_id = p_event_id AND g.side = 'bride';

  -- Insert/Update bride snapshot
  INSERT INTO headcount_snapshots (
    event_id, wedding_id, side, total_invited, total_attending,
    total_declined, total_maybe, total_pending, adults_count,
    teens_count, children_count, calculated_headcount
  )
  VALUES (
    p_event_id, p_wedding_id, 'bride', v_bride_stats.total_invited,
    v_bride_stats.attending, v_bride_stats.declined, v_bride_stats.maybe,
    v_bride_stats.pending, v_bride_stats.adults, v_bride_stats.teens,
    v_bride_stats.children, v_bride_stats.headcount
  )
  ON CONFLICT (event_id, side)
  DO UPDATE SET
    total_invited = EXCLUDED.total_invited,
    total_attending = EXCLUDED.total_attending,
    total_declined = EXCLUDED.total_declined,
    total_maybe = EXCLUDED.total_maybe,
    total_pending = EXCLUDED.total_pending,
    adults_count = EXCLUDED.adults_count,
    teens_count = EXCLUDED.teens_count,
    children_count = EXCLUDED.children_count,
    calculated_headcount = EXCLUDED.calculated_headcount,
    snapshot_date = NOW();
END;
$$ LANGUAGE plpgsql;

-- Trigger to update headcount on RSVP change
CREATE OR REPLACE FUNCTION trigger_update_headcount()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_headcount_snapshot(NEW.event_id, NEW.wedding_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS rsvp_update_headcount ON rsvps;
CREATE TRIGGER rsvp_update_headcount
AFTER INSERT OR UPDATE ON rsvps
FOR EACH ROW
EXECUTE FUNCTION trigger_update_headcount();

-- Function to auto-generate events when wedding is created
CREATE OR REPLACE FUNCTION auto_generate_events_on_wedding()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM generate_wedding_events(NEW.id, NEW.date, NEW.venue, NEW.city);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS wedding_create_events ON weddings;
CREATE TRIGGER wedding_create_events
AFTER INSERT ON weddings
FOR EACH ROW
EXECUTE FUNCTION auto_generate_events_on_wedding();

-- ============================================
-- ROW LEVEL SECURITY (RLS) - DISABLED FOR TESTING
-- ============================================
-- RLS policies have been moved to sql/rls_policies.sql
-- Execute rls_policies.sql separately after testing to enable security

-- ============================================
-- HELPER VIEWS
-- ============================================

-- View for guest statistics
CREATE OR REPLACE VIEW guest_statistics AS
SELECT
  g.wedding_id,
  g.side,
  g.role,
  COUNT(*) as total_guests,
  COUNT(*) FILTER (WHERE g.status = 'accepted') as accepted_count,
  COUNT(*) FILTER (WHERE g.status = 'declined') as declined_count,
  COUNT(*) FILTER (WHERE g.status = 'pending') as pending_count,
  COUNT(*) FILTER (WHERE g.is_vip = TRUE) as vip_count,
  COUNT(*) FILTER (WHERE g.under_18 = TRUE) as under_18_count
FROM guests g
GROUP BY g.wedding_id, g.side, g.role;

-- View for event attendance
CREATE OR REPLACE VIEW event_attendance AS
SELECT
  e.id as event_id,
  e.wedding_id,
  e.name as event_name,
  e.date as event_date,
  COUNT(r.id) as total_rsvps,
  COUNT(*) FILTER (WHERE r.status = 'attending') as attending_count,
  COUNT(*) FILTER (WHERE r.status = 'not_attending') as not_attending_count,
  COUNT(*) FILTER (WHERE r.status = 'maybe') as maybe_count,
  COALESCE(SUM(r.calculated_headcount) FILTER (WHERE r.status = 'attending'), 0) as total_headcount
FROM events e
LEFT JOIN rsvps r ON r.event_id = e.id
GROUP BY e.id, e.wedding_id, e.name, e.date;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Run these to verify migration success:
-- SELECT COUNT(*) FROM events;
-- SELECT COUNT(*) FROM guests;
-- SELECT COUNT(*) FROM rsvps;
-- SELECT * FROM guest_statistics LIMIT 10;
-- SELECT * FROM event_attendance LIMIT 10;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- Phase 2 tables created successfully!
-- Features enabled:
-- - Event management (7 auto-generated events per wedding)
-- - Guest management with hierarchical invitations
-- - Family tree tracking
-- - RSVP system with headcount calculation
-- - Real-time headcount snapshots
-- Next: Implement frontend components for these features
-- ============================================
