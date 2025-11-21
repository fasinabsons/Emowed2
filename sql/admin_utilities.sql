-- ============================================
-- EMOWED ADMIN UTILITY SCRIPTS
-- ============================================
-- Purpose: Administrative tools for common management tasks
-- WARNING: These scripts modify data - use with caution!
-- ============================================

-- ============================================
-- TABLE OF CONTENTS
-- ============================================
/*
1. USER MANAGEMENT
   - Find users by criteria
   - Bulk user updates
   - Account status management
   - User statistics

2. DATA CLEANUP
   - Remove orphaned records
   - Delete test data
   - Archive old data
   - Clean up expired items

3. BULK OPERATIONS
   - Bulk delete
   - Bulk update
   - Mass notifications
   - Batch processing

4. REPORT GENERATION
   - User activity reports
   - Wedding statistics
   - Revenue reports
   - Vendor performance

5. SYSTEM MAINTENANCE
   - Reset sequences
   - Fix data inconsistencies
   - Update computed fields
   - Reindex operations

6. EMERGENCY PROCEDURES
   - Ban spam users
   - Lock accounts
   - Emergency rollback
   - Data recovery

7. DEVELOPMENT UTILITIES
   - Reset development data
   - Generate test data
   - Clone production structure
*/

-- ============================================
-- SECTION 1: USER MANAGEMENT
-- ============================================

-- ============================================
-- 1.1: FIND USERS BY CRITERIA
-- ============================================

-- Find users by email pattern
CREATE OR REPLACE FUNCTION find_users_by_email(p_pattern TEXT)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  relationship_status TEXT,
  created_at TIMESTAMP,
  last_active TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    u.full_name,
    u.relationship_status,
    u.created_at,
    u.updated_at
  FROM users u
  WHERE u.email ILIKE '%' || p_pattern || '%'
  ORDER BY u.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Find inactive users
CREATE OR REPLACE FUNCTION find_inactive_users(p_days INTEGER DEFAULT 90)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  days_inactive INTEGER,
  last_active TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    u.full_name,
    (EXTRACT(DAYS FROM NOW() - u.updated_at))::INTEGER,
    u.updated_at
  FROM users u
  WHERE u.updated_at < NOW() - (p_days || ' days')::INTERVAL
  ORDER BY u.updated_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Find users without couples/weddings
CREATE OR REPLACE FUNCTION find_solo_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  relationship_status TEXT,
  created_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    u.full_name,
    u.relationship_status,
    u.created_at
  FROM users u
  WHERE NOT EXISTS (
    SELECT 1 FROM couples c
    WHERE c.user1_id = u.id OR c.user2_id = u.id
  )
  ORDER BY u.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM find_users_by_email('test');
-- SELECT * FROM find_inactive_users(90);
-- SELECT * FROM find_solo_users();

-- ============================================
-- 1.2: BULK USER UPDATES
-- ============================================

-- Reset invitation permissions for all users
CREATE OR REPLACE FUNCTION reset_invitation_permissions()
RETURNS INTEGER AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  UPDATE users
  SET can_invite = true,
      last_invite_at = NULL
  WHERE can_invite = false;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  RAISE NOTICE 'Reset invitation permissions for % users', v_updated_count;
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- Verify all user ages
CREATE OR REPLACE FUNCTION verify_user_ages()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  stated_age INTEGER,
  calculated_age INTEGER,
  needs_verification BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.email,
    u.age,
    calculate_age(u.date_of_birth),
    ABS(u.age - calculate_age(u.date_of_birth)) > 1
  FROM users u
  WHERE u.date_of_birth IS NOT NULL
  AND ABS(u.age - calculate_age(u.date_of_birth)) > 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 1.3: USER STATISTICS
-- ============================================

CREATE OR REPLACE FUNCTION get_user_statistics()
RETURNS TABLE (
  metric TEXT,
  count BIGINT,
  percentage NUMERIC
) AS $$
DECLARE
  v_total_users BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total_users FROM users;

  -- Total users
  RETURN QUERY SELECT
    'Total Users'::TEXT,
    v_total_users,
    100.00;

  -- By relationship status
  RETURN QUERY
  SELECT
    'Status: ' || relationship_status,
    COUNT(*),
    ROUND(100.0 * COUNT(*) / v_total_users, 2)
  FROM users
  GROUP BY relationship_status;

  -- By gender
  RETURN QUERY
  SELECT
    'Gender: ' || gender,
    COUNT(*),
    ROUND(100.0 * COUNT(*) / v_total_users, 2)
  FROM users
  WHERE gender IS NOT NULL
  GROUP BY gender;

  -- Age verified
  RETURN QUERY SELECT
    'Age Verified'::TEXT,
    COUNT(*),
    ROUND(100.0 * COUNT(*) / v_total_users, 2)
  FROM users WHERE age_verified = true;

  -- Has couple
  RETURN QUERY SELECT
    'Has Partner/Couple'::TEXT,
    COUNT(DISTINCT u.id),
    ROUND(100.0 * COUNT(DISTINCT u.id) / v_total_users, 2)
  FROM users u
  JOIN couples c ON u.id IN (c.user1_id, c.user2_id);

  -- Has wedding
  RETURN QUERY SELECT
    'Has Wedding'::TEXT,
    COUNT(DISTINCT u.id),
    ROUND(100.0 * COUNT(DISTINCT u.id) / v_total_users, 2)
  FROM users u
  JOIN couples c ON u.id IN (c.user1_id, c.user2_id)
  JOIN weddings w ON c.id = w.couple_id;

END;
$$ LANGUAGE plpgsql;

-- Run: SELECT * FROM get_user_statistics();

-- ============================================
-- SECTION 2: DATA CLEANUP
-- ============================================

-- ============================================
-- 2.1: REMOVE ORPHANED RECORDS
-- ============================================

-- Find and remove orphaned records
CREATE OR REPLACE FUNCTION cleanup_orphaned_records(
  p_dry_run BOOLEAN DEFAULT true
)
RETURNS TABLE (
  table_name TEXT,
  orphaned_count BIGINT,
  action_taken TEXT
) AS $$
DECLARE
  v_count BIGINT;
BEGIN
  -- Orphaned rsvps (guest deleted)
  SELECT COUNT(*) INTO v_count
  FROM rsvps r
  LEFT JOIN guests g ON r.guest_id = g.id
  WHERE g.id IS NULL;

  IF v_count > 0 THEN
    IF NOT p_dry_run THEN
      DELETE FROM rsvps r
      USING rsvps r2
      LEFT JOIN guests g ON r2.guest_id = g.id
      WHERE r.id = r2.id AND g.id IS NULL;
    END IF;

    RETURN QUERY SELECT
      'rsvps'::TEXT,
      v_count,
      CASE WHEN p_dry_run THEN 'Would delete' ELSE 'Deleted' END;
  END IF;

  -- Orphaned vendor_bookings (wedding deleted)
  SELECT COUNT(*) INTO v_count
  FROM vendor_bookings vb
  LEFT JOIN weddings w ON vb.wedding_id = w.id
  WHERE w.id IS NULL;

  IF v_count > 0 THEN
    IF NOT p_dry_run THEN
      DELETE FROM vendor_bookings vb
      USING vendor_bookings vb2
      LEFT JOIN weddings w ON vb2.wedding_id = w.id
      WHERE vb.id = vb2.id AND w.id IS NULL;
    END IF;

    RETURN QUERY SELECT
      'vendor_bookings'::TEXT,
      v_count,
      CASE WHEN p_dry_run THEN 'Would delete' ELSE 'Deleted' END;
  END IF;

  -- Orphaned media_items (album deleted)
  SELECT COUNT(*) INTO v_count
  FROM media_items mi
  LEFT JOIN media_albums ma ON mi.album_id = ma.id
  WHERE ma.id IS NULL;

  IF v_count > 0 THEN
    IF NOT p_dry_run THEN
      DELETE FROM media_items mi
      USING media_items mi2
      LEFT JOIN media_albums ma ON mi2.album_id = ma.id
      WHERE mi.id = mi2.id AND ma.id IS NULL;
    END IF;

    RETURN QUERY SELECT
      'media_items'::TEXT,
      v_count,
      CASE WHEN p_dry_run THEN 'Would delete' ELSE 'Deleted' END;
  END IF;

  IF p_dry_run THEN
    RAISE NOTICE 'DRY RUN - No data was deleted. Run with p_dry_run = false to execute.';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Check what would be deleted:
-- SELECT * FROM cleanup_orphaned_records(true);

-- Actually delete:
-- SELECT * FROM cleanup_orphaned_records(false);

-- ============================================
-- 2.2: DELETE TEST DATA
-- ============================================

-- Remove all test accounts and related data
CREATE OR REPLACE FUNCTION delete_test_data(
  p_confirm TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
  v_deleted_users INTEGER;
  v_deleted_weddings INTEGER;
BEGIN
  IF p_confirm != 'DELETE_TEST_DATA' THEN
    RETURN 'ERROR: Must confirm with DELETE_TEST_DATA parameter';
  END IF;

  -- Delete test weddings and cascade
  DELETE FROM weddings
  WHERE name ILIKE '%test%'
  OR name ILIKE '%demo%';

  GET DIAGNOSTICS v_deleted_weddings = ROW_COUNT;

  -- Delete test users and cascade
  DELETE FROM users
  WHERE email ILIKE '%test%'
  OR email ILIKE '%example.com'
  OR email LIKE '%+test@%';

  GET DIAGNOSTICS v_deleted_users = ROW_COUNT;

  RETURN format('Deleted %s test users and %s test weddings',
    v_deleted_users, v_deleted_weddings);
END;
$$ LANGUAGE plpgsql;

-- WARNING: This deletes data permanently!
-- SELECT delete_test_data('DELETE_TEST_DATA');

-- ============================================
-- 2.3: ARCHIVE OLD DATA
-- ============================================

-- Archive weddings older than specified date
CREATE OR REPLACE FUNCTION archive_old_weddings(
  p_before_date DATE,
  p_dry_run BOOLEAN DEFAULT true
)
RETURNS TABLE (
  wedding_id UUID,
  wedding_name TEXT,
  wedding_date DATE,
  total_guests INTEGER,
  action TEXT
) AS $$
BEGIN
  IF p_dry_run THEN
    -- Just show what would be archived
    RETURN QUERY
    SELECT
      w.id,
      w.name,
      w.date,
      COUNT(g.id)::INTEGER,
      'Would archive'::TEXT
    FROM weddings w
    LEFT JOIN guests g ON w.id = g.wedding_id
    WHERE w.date < p_before_date
    AND w.status != 'archived'
    GROUP BY w.id, w.name, w.date
    ORDER BY w.date;
  ELSE
    -- Actually archive
    UPDATE weddings
    SET status = 'archived'
    WHERE date < p_before_date
    AND status != 'archived';

    RETURN QUERY
    SELECT
      w.id,
      w.name,
      w.date,
      COUNT(g.id)::INTEGER,
      'Archived'::TEXT
    FROM weddings w
    LEFT JOIN guests g ON w.id = g.wedding_id
    WHERE w.date < p_before_date
    GROUP BY w.id, w.name, w.date
    ORDER BY w.date;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Check what would be archived:
-- SELECT * FROM archive_old_weddings('2024-01-01', true);

-- Actually archive:
-- SELECT * FROM archive_old_weddings('2024-01-01', false);

-- ============================================
-- 2.4: CLEAN UP EXPIRED ITEMS
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_expired_items()
RETURNS TABLE (
  item_type TEXT,
  deleted_count INTEGER
) AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Expired invitations
  DELETE FROM partner_invitations
  WHERE status = 'pending'
  AND expires_at < NOW();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Expired Partner Invitations'::TEXT, v_count;

  -- Expired vendor invitations
  DELETE FROM vendor_invitations
  WHERE status = 'pending'
  AND expires_at < NOW();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Expired Vendor Invitations'::TEXT, v_count;

  -- Expired parent invitations
  DELETE FROM parent_invitations
  WHERE status = 'pending'
  AND expires_at < NOW();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Expired Parent Invitations'::TEXT, v_count;

  -- Old read notifications (90+ days)
  DELETE FROM notifications
  WHERE read = true
  AND created_at < NOW() - INTERVAL '90 days';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Old Read Notifications'::TEXT, v_count;

  -- Expired cooldown periods
  DELETE FROM cooldown_periods
  WHERE expires_at < NOW();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Expired Cooldown Periods'::TEXT, v_count;

END;
$$ LANGUAGE plpgsql;

-- Run cleanup:
-- SELECT * FROM cleanup_expired_items();

-- ============================================
-- SECTION 3: BULK OPERATIONS
-- ============================================

-- ============================================
-- 3.1: BULK NOTIFICATION SENDER
-- ============================================

-- Send notification to all users matching criteria
CREATE OR REPLACE FUNCTION send_bulk_notification(
  p_title TEXT,
  p_message TEXT,
  p_type TEXT DEFAULT 'announcement',
  p_filter_relationship_status TEXT DEFAULT NULL,
  p_filter_has_wedding BOOLEAN DEFAULT NULL,
  p_dry_run BOOLEAN DEFAULT true
)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  notification_sent BOOLEAN
) AS $$
DECLARE
  v_user RECORD;
  v_notification_id UUID;
  v_count INTEGER := 0;
BEGIN
  FOR v_user IN
    SELECT u.id, u.email
    FROM users u
    LEFT JOIN couples c ON u.id IN (c.user1_id, c.user2_id)
    LEFT JOIN weddings w ON c.id = w.couple_id
    WHERE
      (p_filter_relationship_status IS NULL OR u.relationship_status = p_filter_relationship_status)
      AND (p_filter_has_wedding IS NULL OR (w.id IS NOT NULL) = p_filter_has_wedding)
    GROUP BY u.id, u.email
  LOOP
    IF NOT p_dry_run THEN
      INSERT INTO notifications (user_id, type, title, message)
      VALUES (v_user.id, p_type, p_title, p_message)
      RETURNING id INTO v_notification_id;
    END IF;

    v_count := v_count + 1;

    RETURN QUERY SELECT
      v_user.id,
      v_user.email,
      NOT p_dry_run;
  END LOOP;

  RAISE NOTICE '% notifications %', v_count,
    CASE WHEN p_dry_run THEN 'would be sent' ELSE 'sent' END;
END;
$$ LANGUAGE plpgsql;

-- Dry run to see who would receive notification:
/*
SELECT * FROM send_bulk_notification(
  'Welcome to Emowed!',
  'Thank you for joining our platform',
  'announcement',
  NULL,  -- all relationship statuses
  NULL,  -- wedding status doesn't matter
  true   -- dry run
);
*/

-- Actually send:
/*
SELECT * FROM send_bulk_notification(
  'Welcome to Emowed!',
  'Thank you for joining our platform',
  'announcement',
  NULL,
  NULL,
  false  -- send for real
);
*/

-- ============================================
-- 3.2: BULK STATUS UPDATES
-- ============================================

-- Update wedding statuses based on dates
CREATE OR REPLACE FUNCTION update_wedding_statuses()
RETURNS TABLE (
  wedding_id UUID,
  wedding_name TEXT,
  old_status TEXT,
  new_status TEXT
) AS $$
BEGIN
  -- Mark past weddings as completed
  RETURN QUERY
  UPDATE weddings
  SET status = 'completed'
  WHERE date < CURRENT_DATE
  AND status = 'upcoming'
  RETURNING id, name, 'upcoming'::TEXT, status;

  -- Mark upcoming weddings (within 30 days)
  RETURN QUERY
  UPDATE weddings
  SET status = 'upcoming'
  WHERE date >= CURRENT_DATE
  AND date <= CURRENT_DATE + INTERVAL '30 days'
  AND status = 'planning'
  RETURNING id, name, 'planning'::TEXT, status;
END;
$$ LANGUAGE plpgsql;

-- Run: SELECT * FROM update_wedding_statuses();

-- ============================================
-- 3.3: BATCH PROCESSING HELPER
-- ============================================

-- Process records in batches to avoid memory issues
CREATE OR REPLACE FUNCTION process_in_batches(
  p_table_name TEXT,
  p_batch_size INTEGER DEFAULT 1000,
  p_process_function TEXT DEFAULT 'SELECT 1'
)
RETURNS TABLE (
  batch_number INTEGER,
  records_processed INTEGER,
  status TEXT
) AS $$
DECLARE
  v_offset INTEGER := 0;
  v_batch_num INTEGER := 0;
  v_total_count INTEGER;
BEGIN
  EXECUTE format('SELECT COUNT(*) FROM %I', p_table_name) INTO v_total_count;

  WHILE v_offset < v_total_count LOOP
    v_batch_num := v_batch_num + 1;

    -- Process batch (customize as needed)
    EXECUTE format(
      'SELECT COUNT(*) FROM %I LIMIT %s OFFSET %s',
      p_table_name, p_batch_size, v_offset
    );

    v_offset := v_offset + p_batch_size;

    RETURN QUERY SELECT
      v_batch_num,
      LEAST(p_batch_size, v_total_count - (v_offset - p_batch_size))::INTEGER,
      'Processed'::TEXT;

    -- Small delay to avoid overwhelming database
    PERFORM pg_sleep(0.1);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SECTION 4: REPORT GENERATION
-- ============================================

-- ============================================
-- 4.1: WEDDING STATISTICS REPORT
-- ============================================

CREATE OR REPLACE FUNCTION generate_wedding_report(
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
  metric TEXT,
  value TEXT
) AS $$
DECLARE
  v_start DATE := COALESCE(p_start_date, '2000-01-01');
  v_end DATE := COALESCE(p_end_date, '2099-12-31');
BEGIN
  -- Total weddings
  RETURN QUERY SELECT
    'Total Weddings'::TEXT,
    COUNT(*)::TEXT
  FROM weddings
  WHERE date BETWEEN v_start AND v_end;

  -- By status
  RETURN QUERY
  SELECT
    'Status: ' || status,
    COUNT(*)::TEXT
  FROM weddings
  WHERE date BETWEEN v_start AND v_end
  GROUP BY status;

  -- Average guest count
  RETURN QUERY SELECT
    'Average Guests per Wedding'::TEXT,
    ROUND(AVG(guest_count))::TEXT
  FROM (
    SELECT w.id, COUNT(g.id) as guest_count
    FROM weddings w
    LEFT JOIN guests g ON w.id = g.wedding_id
    WHERE w.date BETWEEN v_start AND v_end
    GROUP BY w.id
  ) sub;

  -- Total RSVP rate
  RETURN QUERY SELECT
    'Overall RSVP Response Rate'::TEXT,
    ROUND(AVG(rsvp_rate))::TEXT || '%'
  FROM (
    SELECT
      w.id,
      100.0 * COUNT(r.id)::DECIMAL / NULLIF(COUNT(g.id), 0) as rsvp_rate
    FROM weddings w
    LEFT JOIN guests g ON w.id = g.wedding_id
    LEFT JOIN rsvps r ON g.id = r.guest_id
    WHERE w.date BETWEEN v_start AND v_end
    GROUP BY w.id
  ) sub;

  -- Average vendor bookings
  RETURN QUERY SELECT
    'Average Vendors per Wedding'::TEXT,
    ROUND(AVG(vendor_count))::TEXT
  FROM (
    SELECT w.id, COUNT(vb.id) as vendor_count
    FROM weddings w
    LEFT JOIN vendor_bookings vb ON w.id = vb.wedding_id
    WHERE w.date BETWEEN v_start AND v_end
    GROUP BY w.id
  ) sub;

END;
$$ LANGUAGE plpgsql;

-- Run: SELECT * FROM generate_wedding_report('2025-01-01', '2025-12-31');

-- ============================================
-- 4.2: VENDOR PERFORMANCE REPORT
-- ============================================

CREATE OR REPLACE FUNCTION vendor_performance_report()
RETURNS TABLE (
  vendor_name TEXT,
  category TEXT,
  total_bookings BIGINT,
  confirmed_bookings BIGINT,
  average_rating NUMERIC,
  total_revenue NUMERIC,
  response_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    vp.business_name,
    vp.category,
    COUNT(vb.id),
    COUNT(vb.id) FILTER (WHERE vb.booking_status = 'confirmed'),
    ROUND(vp.rating, 2),
    COALESCE(SUM(vb.final_price) FILTER (WHERE vb.payment_status = 'paid'), 0),
    ROUND(100.0 * COUNT(vb.id) FILTER (WHERE vb.booking_status != 'pending') / NULLIF(COUNT(vb.id), 0), 2)
  FROM vendor_profiles vp
  LEFT JOIN vendor_bookings vb ON vp.id = vb.vendor_id
  GROUP BY vp.id, vp.business_name, vp.category, vp.rating
  ORDER BY COUNT(vb.id) DESC;
END;
$$ LANGUAGE plpgsql;

-- Run: SELECT * FROM vendor_performance_report();

-- ============================================
-- 4.3: USER ACTIVITY REPORT
-- ============================================

CREATE OR REPLACE FUNCTION user_activity_report(p_days INTEGER DEFAULT 30)
RETURNS TABLE (
  metric TEXT,
  count BIGINT
) AS $$
BEGIN
  RETURN QUERY SELECT
    'New Users (Last ' || p_days || ' days)'::TEXT,
    COUNT(*)
  FROM users
  WHERE created_at > NOW() - (p_days || ' days')::INTERVAL;

  RETURN QUERY SELECT
    'Active Users (Last ' || p_days || ' days)'::TEXT,
    COUNT(*)
  FROM users
  WHERE updated_at > NOW() - (p_days || ' days')::INTERVAL;

  RETURN QUERY SELECT
    'New Weddings Created'::TEXT,
    COUNT(*)
  FROM weddings
  WHERE created_at > NOW() - (p_days || ' days')::INTERVAL;

  RETURN QUERY SELECT
    'New Matchmaking Profiles'::TEXT,
    COUNT(*)
  FROM matchmaking_profiles
  WHERE created_at > NOW() - (p_days || ' days')::INTERVAL;

  RETURN QUERY SELECT
    'Total Matches Made'::TEXT,
    COUNT(*)
  FROM matches
  WHERE created_at > NOW() - (p_days || ' days')::INTERVAL;

  RETURN QUERY SELECT
    'New Vendor Bookings'::TEXT,
    COUNT(*)
  FROM vendor_bookings
  WHERE created_at > NOW() - (p_days || ' days')::INTERVAL;

END;
$$ LANGUAGE plpgsql;

-- Run: SELECT * FROM user_activity_report(30);

-- ============================================
-- SECTION 5: SYSTEM MAINTENANCE
-- ============================================

-- ============================================
-- 5.1: FIX DATA INCONSISTENCIES
-- ============================================

CREATE OR REPLACE FUNCTION fix_data_inconsistencies()
RETURNS TABLE (
  fix_type TEXT,
  affected_records INTEGER,
  status TEXT
) AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Fix null relationship statuses
  UPDATE users SET relationship_status = 'single'
  WHERE relationship_status IS NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Null relationship status'::TEXT, v_count, 'Fixed'::TEXT;

  -- Fix negative ages
  UPDATE users SET age = EXTRACT(YEAR FROM age(date_of_birth))
  WHERE age < 18 AND date_of_birth IS NOT NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Invalid ages'::TEXT, v_count, 'Fixed'::TEXT;

  -- Fix orphaned couple records (missing users)
  DELETE FROM couples c
  WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = c.user1_id)
  OR NOT EXISTS (SELECT 1 FROM users WHERE id = c.user2_id);
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Orphaned couples'::TEXT, v_count, 'Removed'::TEXT;

  -- Fix wedding dates in past with 'upcoming' status
  UPDATE weddings SET status = 'completed'
  WHERE date < CURRENT_DATE AND status = 'upcoming';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT 'Past weddings marked upcoming'::TEXT, v_count, 'Fixed'::TEXT;

END;
$$ LANGUAGE plpgsql;

-- Run: SELECT * FROM fix_data_inconsistencies();

-- ============================================
-- 5.2: RECALCULATE COMPUTED FIELDS
-- ============================================

CREATE OR REPLACE FUNCTION recalculate_all_stats()
RETURNS TEXT AS $$
BEGIN
  -- Recalculate vendor ratings
  UPDATE vendor_profiles vp
  SET rating = (
    SELECT COALESCE(AVG(rating), 0)
    FROM vendor_reviews vr
    WHERE vr.vendor_id = vp.id
  );

  -- Recalculate total bookings
  UPDATE vendor_profiles vp
  SET total_bookings = (
    SELECT COUNT(*)
    FROM vendor_bookings vb
    WHERE vb.vendor_id = vp.id
    AND vb.booking_status = 'confirmed'
  );

  -- Recalculate leaderboard ranks
  PERFORM recalculate_all_leaderboard_ranks();

  RETURN 'All stats recalculated successfully';
END;
$$ LANGUAGE plpgsql;

-- Run: SELECT recalculate_all_stats();

-- ============================================
-- SECTION 6: EMERGENCY PROCEDURES
-- ============================================

-- ============================================
-- 6.1: BAN SPAM USERS
-- ============================================

CREATE OR REPLACE FUNCTION ban_spam_users(
  p_email_pattern TEXT,
  p_reason TEXT DEFAULT 'Spam detected',
  p_dry_run BOOLEAN DEFAULT true
)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  action TEXT
) AS $$
BEGIN
  IF p_dry_run THEN
    RETURN QUERY
    SELECT u.id, u.email, 'Would ban'::TEXT
    FROM users u
    WHERE u.email ILIKE '%' || p_email_pattern || '%';
  ELSE
    -- Mark users as banned (implement ban logic as needed)
    -- For now, we'll just return the list
    RETURN QUERY
    SELECT u.id, u.email, 'BANNED: ' || p_reason
    FROM users u
    WHERE u.email ILIKE '%' || p_email_pattern || '%';

    -- TODO: Implement actual ban logic
    -- - Add 'banned' field to users table
    -- - Create banned_users audit table
    -- - Revoke all sessions
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6.2: EMERGENCY DATA SNAPSHOT
-- ============================================

CREATE OR REPLACE FUNCTION create_emergency_snapshot()
RETURNS TEXT AS $$
DECLARE
  v_snapshot_time TIMESTAMP := NOW();
BEGIN
  -- Create snapshot tables with timestamp
  EXECUTE format('CREATE TABLE users_snapshot_%s AS SELECT * FROM users',
    to_char(v_snapshot_time, 'YYYYMMDD_HH24MISS'));

  EXECUTE format('CREATE TABLE weddings_snapshot_%s AS SELECT * FROM weddings',
    to_char(v_snapshot_time, 'YYYYMMDD_HH24MISS'));

  EXECUTE format('CREATE TABLE couples_snapshot_%s AS SELECT * FROM couples',
    to_char(v_snapshot_time, 'YYYYMMDD_HH24MISS'));

  RETURN 'Emergency snapshot created at ' || v_snapshot_time;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SECTION 7: DEVELOPMENT UTILITIES
-- ============================================

-- ============================================
-- 7.1: RESET DEVELOPMENT DATA
-- ============================================

CREATE OR REPLACE FUNCTION reset_development_environment(
  p_confirm TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
BEGIN
  IF current_database() = 'production' THEN
    RAISE EXCEPTION 'CANNOT RESET PRODUCTION DATABASE!';
  END IF;

  IF p_confirm != 'RESET_DEV' THEN
    RETURN 'ERROR: Must confirm with RESET_DEV parameter';
  END IF;

  -- Truncate all tables (preserves structure)
  TRUNCATE TABLE match_conversations CASCADE;
  TRUNCATE TABLE matches CASCADE;
  TRUNCATE TABLE match_swipes CASCADE;
  TRUNCATE TABLE matchmaking_profiles CASCADE;
  TRUNCATE TABLE vendor_bookings CASCADE;
  TRUNCATE TABLE vendor_profiles CASCADE;
  TRUNCATE TABLE rsvps CASCADE;
  TRUNCATE TABLE guests CASCADE;
  TRUNCATE TABLE events CASCADE;
  TRUNCATE TABLE media_items CASCADE;
  TRUNCATE TABLE media_albums CASCADE;
  TRUNCATE TABLE game_participants CASCADE;
  TRUNCATE TABLE wedding_games CASCADE;
  TRUNCATE TABLE weddings CASCADE;
  TRUNCATE TABLE couples CASCADE;
  TRUNCATE TABLE notifications CASCADE;
  TRUNCATE TABLE partner_invitations CASCADE;
  TRUNCATE TABLE users CASCADE;

  RETURN 'Development environment reset successfully';
END;
$$ LANGUAGE plpgsql;

-- WARNING: This deletes ALL data in development
-- SELECT reset_development_environment('RESET_DEV');

-- ============================================
-- 7.2: GENERATE RANDOM TEST DATA
-- ============================================

CREATE OR REPLACE FUNCTION generate_random_test_users(p_count INTEGER DEFAULT 10)
RETURNS TEXT AS $$
DECLARE
  v_i INTEGER;
  v_user_id UUID;
  v_gender TEXT;
  v_status TEXT;
BEGIN
  FOR v_i IN 1..p_count LOOP
    v_gender := CASE WHEN random() < 0.5 THEN 'male' ELSE 'female' END;
    v_status := (ARRAY['single', 'committed', 'engaged'])[floor(random() * 3 + 1)];

    INSERT INTO users (
      email,
      full_name,
      age,
      gender,
      relationship_status,
      age_verified
    ) VALUES (
      'test_' || generate_random_code(8) || '@example.com',
      'Test User ' || v_i,
      floor(random() * 30 + 18),
      v_gender,
      v_status,
      true
    ) RETURNING id INTO v_user_id;
  END LOOP;

  RETURN format('%s random test users created', p_count);
END;
$$ LANGUAGE plpgsql;

-- Run: SELECT generate_random_test_users(10);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'ADMIN UTILITY SCRIPTS LOADED';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Available utilities:';
  RAISE NOTICE '1. User Management: find_users_by_email, find_inactive_users';
  RAISE NOTICE '2. Data Cleanup: cleanup_orphaned_records, cleanup_expired_items';
  RAISE NOTICE '3. Bulk Operations: send_bulk_notification, update_wedding_statuses';
  RAISE NOTICE '4. Reports: generate_wedding_report, vendor_performance_report';
  RAISE NOTICE '5. Maintenance: fix_data_inconsistencies, recalculate_all_stats';
  RAISE NOTICE '6. Emergency: ban_spam_users, create_emergency_snapshot';
  RAISE NOTICE '7. Development: reset_development_environment, generate_random_test_users';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'IMPORTANT: Many functions have dry_run mode';
  RAISE NOTICE 'Always test with dry_run=true first!';
  RAISE NOTICE '==============================================';
END $$;
