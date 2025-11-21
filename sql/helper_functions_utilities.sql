-- ============================================
-- EMOWED HELPER FUNCTIONS & UTILITIES
-- ============================================
-- Purpose: Utility functions for common operations
-- Execute after all phase migrations are complete
-- ============================================

-- ============================================
-- STRING UTILITIES
-- ============================================

-- Generate random alphanumeric code
CREATE OR REPLACE FUNCTION generate_random_code(length INTEGER)
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..length LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_random_code IS 'Generate random alphanumeric code of specified length';

-- Slugify text (convert to URL-friendly format)
CREATE OR REPLACE FUNCTION slugify(text TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN lower(trim(regexp_replace(text, '[^a-zA-Z0-9]+', '-', 'g'), '-'));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION slugify IS 'Convert text to URL-friendly slug';

-- ============================================
-- DATE UTILITIES
-- ============================================

-- Check if date is in future
CREATE OR REPLACE FUNCTION is_future_date(check_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN check_date > CURRENT_DATE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION is_future_date IS 'Check if a date is in the future';

-- Calculate age from date of birth
CREATE OR REPLACE FUNCTION calculate_age(dob DATE)
RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(YEAR FROM age(dob))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_age IS 'Calculate age from date of birth';

-- Get days until date
CREATE OR REPLACE FUNCTION days_until(target_date DATE)
RETURNS INTEGER AS $$
BEGIN
  RETURN (target_date - CURRENT_DATE)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION days_until IS 'Get number of days until a future date';

-- ============================================
-- WEDDING UTILITIES
-- ============================================

-- Get wedding progress percentage
CREATE OR REPLACE FUNCTION get_wedding_progress(p_wedding_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_total_tasks INTEGER := 10; -- Total checklist items
  v_completed_tasks INTEGER := 0;
BEGIN
  -- Count completed items (customize based on your requirements)
  SELECT COUNT(*) INTO v_completed_tasks
  FROM (
    SELECT 1 WHERE EXISTS (SELECT 1 FROM events WHERE wedding_id = p_wedding_id)
    UNION ALL
    SELECT 1 WHERE EXISTS (SELECT 1 FROM guests WHERE wedding_id = p_wedding_id)
    UNION ALL
    SELECT 1 WHERE EXISTS (SELECT 1 FROM vendor_bookings WHERE wedding_id = p_wedding_id AND booking_status = 'confirmed')
    UNION ALL
    SELECT 1 WHERE EXISTS (SELECT 1 FROM media_albums WHERE wedding_id = p_wedding_id)
  ) AS tasks;

  RETURN ROUND((v_completed_tasks::DECIMAL / v_total_tasks) * 100, 2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_wedding_progress IS 'Calculate wedding planning progress percentage';

-- Get recommended vendors for wedding
CREATE OR REPLACE FUNCTION get_recommended_vendors(
  p_wedding_id UUID,
  p_category TEXT,
  p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
  vendor_id UUID,
  business_name TEXT,
  rating DECIMAL,
  base_price DECIMAL,
  total_bookings INTEGER,
  is_sponsored BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    vp.id,
    vp.business_name,
    vp.rating,
    vp.base_price,
    vp.total_bookings,
    vp.is_sponsored
  FROM vendor_profiles vp
  JOIN weddings w ON vp.city = w.city
  WHERE w.id = p_wedding_id
  AND vp.category = p_category
  AND vp.is_active = true
  ORDER BY
    vp.is_sponsored DESC,
    vp.rating DESC,
    vp.total_bookings DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_recommended_vendors IS 'Get recommended vendors for a wedding by category';

-- ============================================
-- GUEST MANAGEMENT UTILITIES
-- ============================================

-- Calculate total expected headcount for wedding
CREATE OR REPLACE FUNCTION calculate_total_headcount(p_wedding_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_headcount INTEGER;
BEGIN
  SELECT COALESCE(SUM(r.headcount), 0)
  INTO v_headcount
  FROM guests g
  JOIN rsvps r ON g.id = r.guest_id
  WHERE g.wedding_id = p_wedding_id
  AND r.attendance_status = 'attending';

  RETURN v_headcount;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_total_headcount IS 'Calculate total expected headcount for a wedding';

-- Get guest RSVP completion rate
CREATE OR REPLACE FUNCTION get_rsvp_completion_rate(p_wedding_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_total_guests INTEGER;
  v_responded_guests INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total_guests
  FROM guests
  WHERE wedding_id = p_wedding_id;

  SELECT COUNT(*) INTO v_responded_guests
  FROM guests g
  JOIN rsvps r ON g.id = r.guest_id
  WHERE g.wedding_id = p_wedding_id
  AND r.attendance_status IS NOT NULL;

  IF v_total_guests = 0 THEN
    RETURN 0;
  END IF;

  RETURN ROUND((v_responded_guests::DECIMAL / v_total_guests) * 100, 2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_rsvp_completion_rate IS 'Get RSVP completion rate as percentage';

-- ============================================
-- NOTIFICATION UTILITIES
-- ============================================

-- Create notification for user
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_action_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, action_url)
  VALUES (p_user_id, p_type, p_title, p_message, p_action_url)
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_notification IS 'Create a notification for a user';

-- Mark all notifications as read for user
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  UPDATE notifications
  SET read = true
  WHERE user_id = p_user_id
  AND read = false;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mark_all_notifications_read IS 'Mark all notifications as read for a user';

-- ============================================
-- SEARCH UTILITIES
-- ============================================

-- Search guests by name or email
CREATE OR REPLACE FUNCTION search_guests(
  p_wedding_id UUID,
  p_search_term TEXT
)
RETURNS TABLE (
  guest_id UUID,
  guest_name TEXT,
  guest_email TEXT,
  relationship_side TEXT,
  role TEXT,
  attendance_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    g.id,
    g.guest_name,
    g.guest_email,
    g.relationship_side,
    g.role,
    r.attendance_status
  FROM guests g
  LEFT JOIN rsvps r ON g.id = r.guest_id
  WHERE g.wedding_id = p_wedding_id
  AND (
    g.guest_name ILIKE '%' || p_search_term || '%'
    OR g.guest_email ILIKE '%' || p_search_term || '%'
  )
  ORDER BY g.guest_name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION search_guests IS 'Search guests by name or email';

-- ============================================
-- VALIDATION UTILITIES
-- ============================================

-- Check if user can create wedding
CREATE OR REPLACE FUNCTION can_create_wedding(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_relationship_status TEXT;
  v_has_wedding BOOLEAN;
BEGIN
  -- Check relationship status
  SELECT relationship_status INTO v_relationship_status
  FROM users
  WHERE id = p_user_id;

  IF v_relationship_status NOT IN ('engaged', 'married') THEN
    RETURN FALSE;
  END IF;

  -- Check if already has wedding
  SELECT EXISTS (
    SELECT 1
    FROM couples c
    JOIN weddings w ON c.id = w.couple_id
    WHERE c.user1_id = p_user_id OR c.user2_id = p_user_id
  ) INTO v_has_wedding;

  RETURN NOT v_has_wedding;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION can_create_wedding IS 'Check if user can create a wedding';

-- Check if user can invite partner
CREATE OR REPLACE FUNCTION can_invite_partner(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_can_invite BOOLEAN;
  v_in_cooldown BOOLEAN;
BEGIN
  -- Check can_invite flag
  SELECT can_invite INTO v_can_invite
  FROM users
  WHERE id = p_user_id;

  IF NOT v_can_invite THEN
    RETURN FALSE;
  END IF;

  -- Check cooldown
  SELECT is_in_cooldown(p_user_id, 'invitation') INTO v_in_cooldown;

  RETURN NOT v_in_cooldown;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION can_invite_partner IS 'Check if user can send partner invitation';

-- ============================================
-- STATISTICS UTILITIES
-- ============================================

-- Get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE (
  total_weddings INTEGER,
  total_guests_invited INTEGER,
  total_vendors_booked INTEGER,
  total_gifts_received INTEGER,
  total_activities INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(DISTINCT w.id)::INTEGER as total_weddings,
    COUNT(DISTINCT g.id)::INTEGER as total_guests_invited,
    COUNT(DISTINCT vb.id)::INTEGER as total_vendors_booked,
    COUNT(DISTINCT gg.id)::INTEGER as total_gifts_received,
    COUNT(DISTINCT sa.id)::INTEGER as total_activities
  FROM users u
  LEFT JOIN couples c ON u.id IN (c.user1_id, c.user2_id)
  LEFT JOIN weddings w ON c.id = w.couple_id
  LEFT JOIN guests g ON w.id = g.wedding_id
  LEFT JOIN vendor_bookings vb ON w.id = vb.wedding_id AND vb.booking_status = 'confirmed'
  LEFT JOIN guest_gifts gg ON w.id = gg.wedding_id
  LEFT JOIN singles_activities sa ON u.id = sa.user_id
  WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_stats IS 'Get comprehensive user statistics';

-- ============================================
-- CLEANUP UTILITIES
-- ============================================

-- Delete expired invitations
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM partner_invitations
  WHERE status = 'pending'
  AND expires_at < NOW();

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_expired_invitations IS 'Delete expired partner invitations';

-- Archive old notifications
CREATE OR REPLACE FUNCTION archive_old_notifications(days_old INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
  v_archived_count INTEGER;
BEGIN
  DELETE FROM notifications
  WHERE read = true
  AND created_at < NOW() - (days_old || ' days')::INTERVAL;

  GET DIAGNOSTICS v_archived_count = ROW_COUNT;
  RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION archive_old_notifications IS 'Archive read notifications older than specified days';

-- ============================================
-- LEADERBOARD UTILITIES
-- ============================================

-- Recalculate all leaderboard ranks
CREATE OR REPLACE FUNCTION recalculate_all_leaderboard_ranks()
RETURNS VOID AS $$
BEGIN
  -- Singles leaderboard
  PERFORM calculate_singles_ranks();

  -- Couples leaderboard
  WITH ranked_couples AS (
    SELECT
      id,
      ROW_NUMBER() OVER (ORDER BY overall_score DESC) as new_rank
    FROM couples_leaderboard
  )
  UPDATE couples_leaderboard cl
  SET rank_overall = rc.new_rank,
      last_updated = NOW()
  FROM ranked_couples rc
  WHERE cl.id = rc.id;

  RAISE NOTICE 'All leaderboard ranks recalculated successfully';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION recalculate_all_leaderboard_ranks IS 'Recalculate all leaderboard rankings';

-- ============================================
-- REPORTING UTILITIES
-- ============================================

-- Get wedding budget summary
CREATE OR REPLACE FUNCTION get_wedding_budget_summary(p_wedding_id UUID)
RETURNS TABLE (
  budget_limit DECIMAL,
  vendor_costs DECIMAL,
  gift_commissions DECIMAL,
  total_spent DECIMAL,
  remaining_budget DECIMAL,
  budget_used_percentage DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.budget_limit,
    COALESCE(SUM(vb.final_price), 0) as vendor_costs,
    COALESCE(SUM(gg.commission_amount), 0) as gift_commissions,
    COALESCE(SUM(vb.final_price), 0) + COALESCE(SUM(gg.commission_amount), 0) as total_spent,
    w.budget_limit - (COALESCE(SUM(vb.final_price), 0) + COALESCE(SUM(gg.commission_amount), 0)) as remaining_budget,
    ROUND(((COALESCE(SUM(vb.final_price), 0) + COALESCE(SUM(gg.commission_amount), 0)) / NULLIF(w.budget_limit, 0)) * 100, 2) as budget_used_percentage
  FROM weddings w
  LEFT JOIN vendor_bookings vb ON w.id = vb.wedding_id AND vb.payment_status = 'paid'
  LEFT JOIN guest_gifts gg ON w.id = gg.wedding_id AND gg.payment_status = 'completed'
  WHERE w.id = p_wedding_id
  GROUP BY w.id, w.budget_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_wedding_budget_summary IS 'Get comprehensive budget summary for a wedding';

-- ============================================
-- AUDIT UTILITIES
-- ============================================

-- Get recent activity log for user
CREATE OR REPLACE FUNCTION get_user_activity_log(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  activity_type TEXT,
  activity_description TEXT,
  created_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    'notification' as activity_type,
    n.title as activity_description,
    n.created_at
  FROM notifications n
  WHERE n.user_id = p_user_id
  ORDER BY n.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_user_activity_log IS 'Get recent activity log for a user';

-- ============================================
-- USAGE EXAMPLES
-- ============================================

/*
-- Generate random code
SELECT generate_random_code(6);

-- Slugify text
SELECT slugify('My Awesome Wedding 2025!');
-- Result: 'my-awesome-wedding-2025'

-- Calculate age
SELECT calculate_age('1995-05-15');

-- Get wedding progress
SELECT get_wedding_progress('wedding-uuid');

-- Get recommended vendors
SELECT * FROM get_recommended_vendors('wedding-uuid', 'photographer', 5);

-- Calculate headcount
SELECT calculate_total_headcount('wedding-uuid');

-- Get RSVP completion rate
SELECT get_rsvp_completion_rate('wedding-uuid');

-- Create notification
SELECT create_notification(
  'user-uuid',
  'invitation',
  'New Partner Request',
  'You have received a partner invitation',
  '/invitations'
);

-- Search guests
SELECT * FROM search_guests('wedding-uuid', 'john');

-- Check if user can create wedding
SELECT can_create_wedding('user-uuid');

-- Get user stats
SELECT * FROM get_user_stats('user-uuid');

-- Cleanup expired invitations
SELECT cleanup_expired_invitations();

-- Get budget summary
SELECT * FROM get_wedding_budget_summary('wedding-uuid');
*/

-- ============================================
-- VERIFICATION
-- ============================================

-- List all custom functions
SELECT
  n.nspname as schema,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname NOT LIKE 'pg_%'
AND p.proname NOT LIKE 'uuid_%'
ORDER BY p.proname;

-- ============================================
-- SUCCESS
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'HELPER FUNCTIONS CREATED SUCCESSFULLY';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'Functions available for use in your application';
  RAISE NOTICE 'See USAGE EXAMPLES section for details';
  RAISE NOTICE '==========================================';
END $$;
