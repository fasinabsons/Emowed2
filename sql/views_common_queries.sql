-- ============================================
-- EMOWED DATABASE VIEWS
-- ============================================
-- Purpose: Create reusable views for common queries
-- Benefits: Simplify frontend queries, improve performance
-- Execute after all phase migrations are complete
-- ============================================

-- ============================================
-- WEDDING OVERVIEW VIEWS
-- ============================================

-- Complete wedding details with couple information
CREATE OR REPLACE VIEW vw_wedding_details AS
SELECT
  w.id as wedding_id,
  w.name as wedding_name,
  w.date as wedding_date,
  w.venue,
  w.city,
  w.mode,
  w.budget_limit,
  w.guest_limit,
  w.status as wedding_status,
  c.id as couple_id,
  c.engaged_date,
  c.married_date,
  u1.id as user1_id,
  u1.full_name as user1_name,
  u1.email as user1_email,
  u2.id as user2_id,
  u2.full_name as user2_name,
  u2.email as user2_email,
  -- Calculate days until wedding
  (w.date - CURRENT_DATE) as days_until_wedding,
  w.created_at,
  w.updated_at
FROM weddings w
JOIN couples c ON w.couple_id = c.id
JOIN users u1 ON c.user1_id = u1.id
JOIN users u2 ON c.user2_id = u2.id;

COMMENT ON VIEW vw_wedding_details IS 'Complete wedding information with couple details';

-- ============================================
-- GUEST STATISTICS VIEWS
-- ============================================

-- Guest count and RSVP summary per wedding
CREATE OR REPLACE VIEW vw_wedding_guest_stats AS
SELECT
  w.id as wedding_id,
  w.name as wedding_name,
  COUNT(DISTINCT g.id) as total_guests_invited,
  COUNT(DISTINCT CASE WHEN r.attendance_status = 'attending' THEN g.id END) as guests_attending,
  COUNT(DISTINCT CASE WHEN r.attendance_status = 'not_attending' THEN g.id END) as guests_not_attending,
  COUNT(DISTINCT CASE WHEN r.attendance_status = 'maybe' THEN g.id END) as guests_maybe,
  COUNT(DISTINCT CASE WHEN r.attendance_status IS NULL THEN g.id END) as guests_pending,
  COALESCE(SUM(CASE WHEN r.attendance_status = 'attending' THEN r.headcount ELSE 0 END), 0) as total_headcount,
  w.guest_limit,
  ROUND((COUNT(DISTINCT CASE WHEN r.attendance_status = 'attending' THEN g.id END)::DECIMAL / NULLIF(COUNT(DISTINCT g.id), 0) * 100), 2) as attendance_percentage
FROM weddings w
LEFT JOIN guests g ON w.id = g.wedding_id
LEFT JOIN rsvps r ON g.id = r.guest_id
GROUP BY w.id, w.name, w.guest_limit;

COMMENT ON VIEW vw_wedding_guest_stats IS 'Wedding guest count and RSVP statistics';

-- Guest list with RSVP status
CREATE OR REPLACE VIEW vw_guest_list_with_rsvp AS
SELECT
  g.id as guest_id,
  g.wedding_id,
  g.guest_name,
  g.guest_email,
  g.guest_phone,
  g.relationship_side,
  g.role,
  g.under_18,
  g.invitation_sent_at,
  r.attendance_status,
  r.headcount,
  r.dietary_preferences,
  r.special_requirements,
  r.responded_at,
  CASE
    WHEN r.attendance_status IS NULL THEN 'Pending'
    WHEN r.attendance_status = 'attending' THEN 'Attending'
    WHEN r.attendance_status = 'not_attending' THEN 'Not Attending'
    WHEN r.attendance_status = 'maybe' THEN 'Maybe'
  END as status_label,
  u.full_name as invited_by_name
FROM guests g
LEFT JOIN rsvps r ON g.id = r.guest_id
LEFT JOIN users u ON g.invited_by = u.id;

COMMENT ON VIEW vw_guest_list_with_rsvp IS 'Complete guest list with RSVP details';

-- ============================================
-- VENDOR STATISTICS VIEWS
-- ============================================

-- Vendor summary with ratings and bookings
CREATE OR REPLACE VIEW vw_vendor_summary AS
SELECT
  vp.id as vendor_id,
  vp.user_id,
  u.full_name as vendor_contact_name,
  u.email as vendor_email,
  vp.business_name,
  vp.category,
  vp.city,
  vp.base_price,
  vp.is_sponsored,
  vp.rating,
  vp.total_bookings,
  vp.total_revenue,
  COUNT(DISTINCT vb.id) as active_bookings,
  COUNT(DISTINCT vr.id) as total_reviews,
  ROUND(AVG(vr.rating), 2) as average_review_rating,
  vp.created_at
FROM vendor_profiles vp
JOIN users u ON vp.user_id = u.id
LEFT JOIN vendor_bookings vb ON vp.id = vb.vendor_id AND vb.status = 'confirmed'
LEFT JOIN vendor_reviews vr ON vp.id = vr.vendor_id
GROUP BY vp.id, vp.user_id, u.full_name, u.email, vp.business_name,
         vp.category, vp.city, vp.base_price, vp.is_sponsored,
         vp.rating, vp.total_bookings, vp.total_revenue, vp.created_at;

COMMENT ON VIEW vw_vendor_summary IS 'Vendor profiles with booking and review statistics';

-- Vendor bookings with wedding details
CREATE OR REPLACE VIEW vw_vendor_bookings_detail AS
SELECT
  vb.id as booking_id,
  vb.vendor_id,
  vp.business_name as vendor_name,
  vp.category as vendor_category,
  vb.wedding_id,
  w.name as wedding_name,
  w.date as wedding_date,
  vb.event_id,
  e.event_name,
  e.event_date,
  vb.quoted_price,
  vb.final_price,
  vb.advance_paid,
  vb.balance_due,
  vb.payment_status,
  vb.booking_status as status,
  vb.created_at as booked_at
FROM vendor_bookings vb
JOIN vendor_profiles vp ON vb.vendor_id = vp.id
JOIN weddings w ON vb.wedding_id = w.id
LEFT JOIN events e ON vb.event_id = e.id;

COMMENT ON VIEW vw_vendor_bookings_detail IS 'Vendor bookings with complete details';

-- ============================================
-- EVENT ATTENDANCE VIEWS
-- ============================================

-- Event attendance summary
CREATE OR REPLACE VIEW vw_event_attendance_summary AS
SELECT
  e.id as event_id,
  e.wedding_id,
  w.name as wedding_name,
  e.event_name,
  e.event_date,
  e.event_time,
  e.venue,
  COUNT(DISTINCT ea.guest_id) as guests_attending,
  COUNT(DISTINCT g.id) as total_guests_invited,
  ROUND((COUNT(DISTINCT ea.guest_id)::DECIMAL / NULLIF(COUNT(DISTINCT g.id), 0) * 100), 2) as attendance_percentage
FROM events e
JOIN weddings w ON e.wedding_id = w.id
LEFT JOIN guests g ON w.id = g.wedding_id
LEFT JOIN event_attendees ea ON e.id = ea.event_id AND ea.will_attend = true
GROUP BY e.id, e.wedding_id, w.name, e.event_name, e.event_date, e.event_time, e.venue;

COMMENT ON VIEW vw_event_attendance_summary IS 'Event-wise attendance statistics';

-- ============================================
-- GAME LEADERBOARDS VIEWS
-- ============================================

-- Wedding game leaderboard
CREATE OR REPLACE VIEW vw_game_leaderboard AS
SELECT
  wg.id as game_id,
  wg.wedding_id,
  wg.game_title,
  gp.id as participant_id,
  gp.participant_name,
  gp.side,
  gp.total_score,
  gp.games_played,
  ROW_NUMBER() OVER (PARTITION BY wg.id ORDER BY gp.total_score DESC) as rank
FROM wedding_games wg
JOIN game_participants gp ON wg.id = gp.wedding_game_id
WHERE wg.status IN ('active', 'completed')
ORDER BY wg.id, gp.total_score DESC;

COMMENT ON VIEW vw_game_leaderboard IS 'Game leaderboard with rankings';

-- Wedding side competition summary
CREATE OR REPLACE VIEW vw_wedding_side_competition_summary AS
SELECT
  wsc.wedding_id,
  w.name as wedding_name,
  wsc.groom_side_score,
  wsc.bride_side_score,
  wsc.groom_side_participants,
  wsc.bride_side_participants,
  wsc.total_games,
  CASE
    WHEN wsc.groom_side_score > wsc.bride_side_score THEN 'Groom Side'
    WHEN wsc.bride_side_score > wsc.groom_side_score THEN 'Bride Side'
    ELSE 'Tie'
  END as current_leader,
  ABS(wsc.groom_side_score - wsc.bride_side_score) as point_difference
FROM wedding_side_competition wsc
JOIN weddings w ON wsc.wedding_id = w.id
WHERE wsc.is_active = true;

COMMENT ON VIEW vw_wedding_side_competition_summary IS 'Groom vs Bride competition summary';

-- ============================================
-- GIFT TRACKING VIEWS
-- ============================================

-- Wedding gifts summary
CREATE OR REPLACE VIEW vw_wedding_gifts_summary AS
SELECT
  gg.wedding_id,
  w.name as wedding_name,
  COUNT(gg.id) as total_gifts,
  COUNT(CASE WHEN gg.gift_type = 'cash' THEN 1 END) as cash_gifts_count,
  COUNT(CASE WHEN gg.gift_type != 'cash' THEN 1 END) as physical_gifts_count,
  SUM(gg.gift_amount) as total_gift_value,
  SUM(CASE WHEN gg.gift_type = 'cash' THEN gg.gift_amount ELSE 0 END) as total_cash_received,
  SUM(CASE WHEN gg.payment_status = 'completed' THEN gg.gift_amount ELSE 0 END) as total_paid,
  SUM(CASE WHEN gg.payment_status = 'pending' THEN gg.gift_amount ELSE 0 END) as total_pending,
  SUM(gg.commission_amount) as total_commission
FROM guest_gifts gg
JOIN weddings w ON gg.wedding_id = w.id
GROUP BY gg.wedding_id, w.name;

COMMENT ON VIEW vw_wedding_gifts_summary IS 'Wedding gift statistics and totals';

-- Wishlist with fulfillment status
CREATE OR REPLACE VIEW vw_wishlist_with_status AS
SELECT
  gw.id as wishlist_item_id,
  gw.wedding_id,
  w.name as wedding_name,
  gp.product_name,
  gp.brand,
  gp.base_price,
  gw.priority,
  gw.quantity_desired,
  gw.quantity_received,
  CASE
    WHEN gw.quantity_received >= gw.quantity_desired THEN 'Fulfilled'
    WHEN gw.quantity_received > 0 THEN 'Partially Fulfilled'
    ELSE 'Not Fulfilled'
  END as fulfillment_status,
  gw.notes,
  gw.is_public
FROM gift_wishlists gw
JOIN weddings w ON gw.wedding_id = w.id
JOIN gift_products gp ON gw.product_id = gp.id
WHERE gw.is_public = true;

COMMENT ON VIEW vw_wishlist_with_status IS 'Gift wishlist with fulfillment status';

-- ============================================
-- MATCHMAKING VIEWS
-- ============================================

-- Active matchmaking profiles with compatibility
CREATE OR REPLACE VIEW vw_matchmaking_profiles_active AS
SELECT
  mp.id as profile_id,
  mp.user_id,
  mp.full_name,
  mp.age,
  mp.gender,
  mp.current_city,
  mp.profession,
  mp.religion,
  mp.caste,
  mp.diet,
  mp.height_cm,
  mp.profile_status,
  mp.verification_level,
  mp.profile_photo_url,
  mp.bio,
  mp.profile_views,
  mp.likes_received,
  mp.matches_count,
  mp.created_at
FROM matchmaking_profiles mp
WHERE mp.profile_status = 'active';

COMMENT ON VIEW vw_matchmaking_profiles_active IS 'Active matchmaking profiles for discovery';

-- Match details with profiles
CREATE OR REPLACE VIEW vw_matches_with_profiles AS
SELECT
  m.id as match_id,
  m.match_score,
  m.match_status,
  m.matched_at,
  mp1.user_id as user1_id,
  mp1.full_name as user1_name,
  mp1.age as user1_age,
  mp1.city as user1_city,
  mp1.profile_photo_url as user1_photo,
  mp2.user_id as user2_id,
  mp2.full_name as user2_name,
  mp2.age as user2_age,
  mp2.city as user2_city,
  mp2.profile_photo_url as user2_photo,
  m.first_message_sent,
  m.last_interaction
FROM matches m
JOIN matchmaking_profiles mp1 ON m.profile1_id = mp1.id
JOIN matchmaking_profiles mp2 ON m.profile2_id = mp2.id;

COMMENT ON VIEW vw_matches_with_profiles IS 'Matches with complete profile information';

-- ============================================
-- LEADERBOARD VIEWS
-- ============================================

-- Singles leaderboard with rankings
CREATE OR REPLACE VIEW vw_singles_leaderboard_ranked AS
SELECT
  sl.user_id,
  u.full_name,
  u.email,
  sl.overall_score,
  sl.personal_growth_score,
  sl.career_achievement_score,
  sl.rank_overall,
  sl.rank_personal,
  sl.rank_career,
  sl.badges,
  sl.last_updated
FROM singles_leaderboard sl
JOIN users u ON sl.user_id = u.id
ORDER BY sl.rank_overall;

COMMENT ON VIEW vw_singles_leaderboard_ranked IS 'Singles leaderboard with complete rankings';

-- Couples leaderboard with rankings
CREATE OR REPLACE VIEW vw_couples_leaderboard_ranked AS
SELECT
  cl.couple_id,
  u1.full_name as partner1_name,
  u2.full_name as partner2_name,
  cl.overall_score,
  cl.milestones_achieved,
  cl.date_nights_count,
  cl.diary_entries_count,
  cl.rank_overall,
  cl.badges,
  c.engaged_date,
  c.married_date,
  cl.last_updated
FROM couples_leaderboard cl
JOIN couples c ON cl.couple_id = c.id
JOIN users u1 ON c.user1_id = u1.id
JOIN users u2 ON c.user2_id = u2.id
ORDER BY cl.rank_overall;

COMMENT ON VIEW vw_couples_leaderboard_ranked IS 'Couples leaderboard with complete rankings';

-- ============================================
-- MEDIA VIEWS
-- ============================================

-- Media items with album and engagement stats
CREATE OR REPLACE VIEW vw_media_items_with_stats AS
SELECT
  mi.id as media_id,
  mi.album_id,
  ma.album_name,
  ma.album_type,
  mi.media_type,
  mi.media_url,
  mi.thumbnail_url,
  mi.caption,
  mi.uploaded_by,
  u.full_name as uploader_name,
  mi.likes_count,
  mi.comments_count,
  mi.views_count,
  mi.is_featured,
  mi.created_at
FROM media_items mi
JOIN media_albums ma ON mi.album_id = ma.id
LEFT JOIN users u ON mi.uploaded_by = u.id
ORDER BY mi.created_at DESC;

COMMENT ON VIEW vw_media_items_with_stats IS 'Media items with engagement statistics';

-- ============================================
-- FORUM VIEWS
-- ============================================

-- Forum posts with author and stats
CREATE OR REPLACE VIEW vw_forum_posts_with_stats AS
SELECT
  fp.id as post_id,
  fp.category_id,
  fc.category_name,
  fp.author_id,
  fp.author_name,
  fp.post_title,
  fp.post_content,
  fp.tags,
  fp.upvotes_count,
  fp.comments_count,
  fp.views_count,
  fp.is_pinned,
  fp.status,
  fp.created_at,
  fp.updated_at
FROM community_forum_posts fp
JOIN community_forum_categories fc ON fp.category_id = fc.id
WHERE fp.status = 'active'
ORDER BY
  fp.is_pinned DESC,
  fp.created_at DESC;

COMMENT ON VIEW vw_forum_posts_with_stats IS 'Forum posts with complete statistics';

-- ============================================
-- DASHBOARD SUMMARY VIEWS
-- ============================================

-- User dashboard summary
CREATE OR REPLACE VIEW vw_user_dashboard_summary AS
SELECT
  u.id as user_id,
  u.email,
  u.full_name,
  u.relationship_status,
  c.id as couple_id,
  w.id as wedding_id,
  w.name as wedding_name,
  w.date as wedding_date,
  (w.date - CURRENT_DATE) as days_until_wedding,
  COUNT(DISTINCT n.id) as unread_notifications
FROM users u
LEFT JOIN couples c ON u.id IN (c.user1_id, c.user2_id)
LEFT JOIN weddings w ON c.id = w.couple_id
LEFT JOIN notifications n ON u.id = n.user_id AND n.read = false
GROUP BY u.id, u.email, u.full_name, u.relationship_status,
         c.id, w.id, w.name, w.date;

COMMENT ON VIEW vw_user_dashboard_summary IS 'User dashboard summary with key information';

-- ============================================
-- VERIFICATION
-- ============================================

-- List all views created
SELECT
  schemaname,
  viewname,
  viewowner
FROM pg_views
WHERE schemaname = 'public'
AND viewname LIKE 'vw_%'
ORDER BY viewname;

-- ============================================
-- USAGE EXAMPLES
-- ============================================

/*
-- Get wedding details
SELECT * FROM vw_wedding_details WHERE wedding_id = 'your-wedding-id';

-- Get guest statistics
SELECT * FROM vw_wedding_guest_stats WHERE wedding_id = 'your-wedding-id';

-- Get vendor summary
SELECT * FROM vw_vendor_summary WHERE category = 'photographer';

-- Get game leaderboard
SELECT * FROM vw_game_leaderboard WHERE game_id = 'your-game-id';

-- Get gift summary
SELECT * FROM vw_wedding_gifts_summary WHERE wedding_id = 'your-wedding-id';

-- Get active matchmaking profiles
SELECT * FROM vw_matchmaking_profiles_active
WHERE current_city = 'Mumbai'
AND age BETWEEN 25 AND 30;

-- Get user dashboard
SELECT * FROM vw_user_dashboard_summary WHERE user_id = auth.uid();
*/

-- ============================================
-- NOTES
-- ============================================
/*
These views provide:
1. Simplified queries for frontend
2. Pre-calculated statistics
3. Joined data from multiple tables
4. Common filters applied

Benefits:
- Reduce frontend query complexity
- Improve performance with materialized views (optional)
- Centralize business logic
- Consistent data access patterns

To make a view materialized (for better performance):
CREATE MATERIALIZED VIEW vw_name AS ...;
REFRESH MATERIALIZED VIEW vw_name;

Note: Materialized views need manual refresh or scheduled refresh
*/
