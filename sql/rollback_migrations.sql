-- ============================================
-- EMOWED DATABASE ROLLBACK SCRIPTS
-- ============================================
-- Purpose: Safely rollback migrations if needed
-- WARNING: This will DELETE DATA! Use with caution!
-- Execute these ONLY if you need to undo migrations
-- ============================================

-- ============================================
-- SAFETY WARNINGS
-- ============================================
/*
⚠️ CRITICAL WARNINGS:

1. BACKUP FIRST!
   - Always backup your database before rollback
   - Use: pg_dump or Supabase Dashboard backup

2. DATA LOSS!
   - Rollback will DELETE all data in affected tables
   - This is IRREVERSIBLE
   - Make sure you have backups

3. CASCADE DELETES!
   - Dropping tables will cascade delete dependent objects
   - Views, triggers, and functions will be removed

4. PRODUCTION WARNING!
   - NEVER run rollback in production without backup
   - Test rollback in development first
   - Have recovery plan ready

5. ORDER MATTERS!
   - Rollback in REVERSE order (Phase 6 → Phase 1)
   - Foreign key constraints require specific order
*/

-- ============================================
-- VERIFY ENVIRONMENT
-- ============================================
DO $$
BEGIN
  IF current_database() = 'production' THEN
    RAISE EXCEPTION 'CANNOT ROLLBACK IN PRODUCTION! Create backup first!';
  END IF;

  RAISE NOTICE 'Database: %', current_database();
  RAISE NOTICE 'Make sure this is correct before proceeding!';
END $$;

-- ============================================
-- ROLLBACK PHASE 6: MATCHMAKING & POST-MARRIAGE
-- ============================================
-- Execute this section to rollback Phase 6 only

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back Phase 6...';
END $$;

-- Drop tables in reverse order of creation
DROP TABLE IF EXISTS counseling_sessions CASCADE;
DROP TABLE IF EXISTS counselor_profiles CASCADE;
DROP TABLE IF EXISTS spam_prevention CASCADE;
DROP TABLE IF EXISTS community_forum_votes CASCADE;
DROP TABLE IF EXISTS community_forum_comments CASCADE;
DROP TABLE IF EXISTS community_forum_posts CASCADE;
DROP TABLE IF EXISTS community_forum_categories CASCADE;
DROP TABLE IF EXISTS gift_tracking CASCADE;
DROP TABLE IF EXISTS trip_plans CASCADE;
DROP TABLE IF EXISTS date_night_plans CASCADE;
DROP TABLE IF EXISTS couple_shared_goals CASCADE;
DROP TABLE IF EXISTS couple_diary_entries CASCADE;
DROP TABLE IF EXISTS match_probability_cache CASCADE;
DROP TABLE IF EXISTS parent_invitations CASCADE;
DROP TABLE IF EXISTS match_conversations CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS match_swipes CASCADE;
DROP TABLE IF EXISTS match_preferences CASCADE;
DROP TABLE IF EXISTS matchmaking_profiles CASCADE;

-- Drop functions specific to Phase 6
DROP FUNCTION IF EXISTS calculate_match_probability(UUID, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS check_mutual_like() CASCADE;
DROP FUNCTION IF EXISTS update_forum_post_stats() CASCADE;
DROP FUNCTION IF EXISTS update_couples_leaderboard_date_night() CASCADE;
DROP FUNCTION IF EXISTS update_couples_leaderboard_diary() CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Phase 6 rollback complete!';
END $$;
*/

-- ============================================
-- ROLLBACK PHASE 5: GAMES, LEADERBOARDS & GIFTS
-- ============================================
-- Execute this section to rollback Phase 5 only

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back Phase 5...';
END $$;

-- Drop tables in reverse order
DROP TABLE IF EXISTS photo_challenge_votes CASCADE;
DROP TABLE IF EXISTS photo_challenge_submissions CASCADE;
DROP TABLE IF EXISTS gift_wishlists CASCADE;
DROP TABLE IF EXISTS guest_gifts CASCADE;
DROP TABLE IF EXISTS gift_products CASCADE;
DROP TABLE IF EXISTS gift_categories CASCADE;
DROP TABLE IF EXISTS couples_milestones CASCADE;
DROP TABLE IF EXISTS couples_leaderboard CASCADE;
DROP TABLE IF EXISTS singles_activities CASCADE;
DROP TABLE IF EXISTS singles_leaderboard CASCADE;
DROP TABLE IF EXISTS leaderboard_categories CASCADE;
DROP TABLE IF EXISTS wedding_side_competition CASCADE;
DROP TABLE IF EXISTS game_responses CASCADE;
DROP TABLE IF EXISTS game_participants CASCADE;
DROP TABLE IF EXISTS game_questions CASCADE;
DROP TABLE IF EXISTS wedding_games CASCADE;
DROP TABLE IF EXISTS game_types CASCADE;

-- Drop functions specific to Phase 5
DROP FUNCTION IF EXISTS update_participant_score() CASCADE;
DROP FUNCTION IF EXISTS update_side_competition() CASCADE;
DROP FUNCTION IF EXISTS calculate_singles_ranks() CASCADE;
DROP FUNCTION IF EXISTS update_singles_score_on_activity() CASCADE;
DROP FUNCTION IF EXISTS update_couples_score_on_milestone() CASCADE;
DROP FUNCTION IF EXISTS calculate_gift_commission() CASCADE;
DROP FUNCTION IF EXISTS update_photo_challenge_votes() CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Phase 5 rollback complete!';
END $$;
*/

-- ============================================
-- ROLLBACK PHASE 4: MEDIA & PROGRAM
-- ============================================
-- Execute this section to rollback Phase 4 only

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back Phase 4...';
END $$;

-- Drop tables in reverse order
DROP TABLE IF EXISTS media_shares CASCADE;
DROP TABLE IF EXISTS wedding_timeline CASCADE;
DROP TABLE IF EXISTS playlist_songs CASCADE;
DROP TABLE IF EXISTS music_playlists CASCADE;
DROP TABLE IF EXISTS ceremony_details CASCADE;
DROP TABLE IF EXISTS program_sections CASCADE;
DROP TABLE IF EXISTS media_comments CASCADE;
DROP TABLE IF EXISTS media_likes CASCADE;
DROP TABLE IF EXISTS media_items CASCADE;
DROP TABLE IF EXISTS media_albums CASCADE;

-- Drop functions specific to Phase 4
DROP FUNCTION IF EXISTS update_album_media_count() CASCADE;
DROP FUNCTION IF EXISTS update_media_likes_count() CASCADE;
DROP FUNCTION IF EXISTS update_media_comments_count() CASCADE;
DROP FUNCTION IF EXISTS update_playlist_song_count() CASCADE;
DROP FUNCTION IF EXISTS generate_share_link() CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Phase 4 rollback complete!';
END $$;
*/

-- ============================================
-- ROLLBACK PHASE 3: VENDOR SYSTEM
-- ============================================
-- Execute this section to rollback Phase 3 only

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back Phase 3...';
END $$;

-- Drop tables in reverse order
DROP TABLE IF EXISTS vendor_reviews CASCADE;
DROP TABLE IF EXISTS vendor_verifications CASCADE;
DROP TABLE IF EXISTS vendor_availability CASCADE;
DROP TABLE IF EXISTS vendor_bookings CASCADE;
DROP TABLE IF EXISTS vendor_votes CASCADE;
DROP TABLE IF EXISTS vendor_quotes CASCADE;
DROP TABLE IF EXISTS vendor_invitations CASCADE;
DROP TABLE IF EXISTS vendor_profiles CASCADE;

-- Drop functions specific to Phase 3
DROP FUNCTION IF EXISTS calculate_vendor_commission() CASCADE;
DROP FUNCTION IF EXISTS update_vendor_stats() CASCADE;
DROP FUNCTION IF EXISTS check_vendor_verification() CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Phase 3 rollback complete!';
END $$;
*/

-- ============================================
-- ROLLBACK PHASE 2: EVENTS, GUESTS & RSVP
-- ============================================
-- Execute this section to rollback Phase 2 only

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back Phase 2...';
END $$;

-- Drop tables in reverse order
DROP TABLE IF EXISTS event_attendees CASCADE;
DROP TABLE IF EXISTS headcount_snapshots CASCADE;
DROP TABLE IF EXISTS rsvps CASCADE;
DROP TABLE IF EXISTS family_tree CASCADE;
DROP TABLE IF EXISTS guest_invitations CASCADE;
DROP TABLE IF EXISTS guests CASCADE;
DROP TABLE IF EXISTS events CASCADE;

-- Drop functions specific to Phase 2
DROP FUNCTION IF EXISTS calculate_headcount() CASCADE;
DROP FUNCTION IF EXISTS update_headcount_snapshot() CASCADE;
DROP FUNCTION IF EXISTS generate_wedding_events() CASCADE;
DROP FUNCTION IF EXISTS update_event_attendees() CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Phase 2 rollback complete!';
END $$;
*/

-- ============================================
-- ROLLBACK PHASE 1: AUTH, COUPLES & WEDDINGS
-- ============================================
-- Execute this section to rollback Phase 1
-- WARNING: This will remove EVERYTHING!

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back Phase 1...';
  RAISE NOTICE 'This will remove ALL tables!';
END $$;

-- Drop tables in reverse order
DROP TABLE IF EXISTS cooldown_periods CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS weddings CASCADE;
DROP TABLE IF EXISTS couples CASCADE;
DROP TABLE IF EXISTS partner_invitations CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop functions specific to Phase 1
DROP FUNCTION IF EXISTS generate_invite_code() CASCADE;
DROP FUNCTION IF EXISTS is_in_cooldown(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS check_invitation_expiry() CASCADE;
DROP FUNCTION IF EXISTS update_users_on_couple() CASCADE;
DROP FUNCTION IF EXISTS cleanup_on_wedding_cancel() CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Phase 1 rollback complete!';
  RAISE NOTICE 'All core tables removed!';
END $$;
*/

-- ============================================
-- ROLLBACK HELPER FUNCTIONS & VIEWS
-- ============================================
-- Execute to remove helper functions and views

/*
DO $$
BEGIN
  RAISE NOTICE 'Rolling back helper functions and views...';
END $$;

-- Drop all custom views
DROP VIEW IF EXISTS vw_user_dashboard_summary CASCADE;
DROP VIEW IF EXISTS vw_forum_posts_with_stats CASCADE;
DROP VIEW IF EXISTS vw_media_items_with_stats CASCADE;
DROP VIEW IF EXISTS vw_couples_leaderboard_ranked CASCADE;
DROP VIEW IF EXISTS vw_singles_leaderboard_ranked CASCADE;
DROP VIEW IF EXISTS vw_matches_with_profiles CASCADE;
DROP VIEW IF EXISTS vw_matchmaking_profiles_active CASCADE;
DROP VIEW IF EXISTS vw_wishlist_with_status CASCADE;
DROP VIEW IF EXISTS vw_wedding_gifts_summary CASCADE;
DROP VIEW IF EXISTS vw_wedding_side_competition_summary CASCADE;
DROP VIEW IF EXISTS vw_game_leaderboard CASCADE;
DROP VIEW IF EXISTS vw_event_attendance_summary CASCADE;
DROP VIEW IF EXISTS vw_vendor_bookings_detail CASCADE;
DROP VIEW IF EXISTS vw_vendor_summary CASCADE;
DROP VIEW IF EXISTS vw_guest_list_with_rsvp CASCADE;
DROP VIEW IF EXISTS vw_wedding_guest_stats CASCADE;
DROP VIEW IF EXISTS vw_wedding_details CASCADE;

-- Drop all helper functions
DROP FUNCTION IF EXISTS get_wedding_budget_summary(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_user_activity_log(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS recalculate_all_leaderboard_ranks() CASCADE;
DROP FUNCTION IF EXISTS archive_old_notifications(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS cleanup_expired_invitations() CASCADE;
DROP FUNCTION IF EXISTS get_user_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS can_invite_partner(UUID) CASCADE;
DROP FUNCTION IF EXISTS can_create_wedding(UUID) CASCADE;
DROP FUNCTION IF EXISTS search_guests(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS mark_all_notifications_read(UUID) CASCADE;
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_rsvp_completion_rate(UUID) CASCADE;
DROP FUNCTION IF EXISTS calculate_total_headcount(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_recommended_vendors(UUID, TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_wedding_progress(UUID) CASCADE;
DROP FUNCTION IF EXISTS days_until(DATE) CASCADE;
DROP FUNCTION IF EXISTS calculate_age(DATE) CASCADE;
DROP FUNCTION IF EXISTS is_future_date(DATE) CASCADE;
DROP FUNCTION IF EXISTS slugify(TEXT) CASCADE;
DROP FUNCTION IF EXISTS generate_random_code(INTEGER) CASCADE;

DO $$
BEGIN
  RAISE NOTICE 'Helper functions and views rollback complete!';
END $$;
*/

-- ============================================
-- COMPLETE ROLLBACK (ALL PHASES)
-- ============================================
-- DANGER: This removes EVERYTHING!
-- Uncomment and execute to completely reset database

/*
DO $$
BEGIN
  RAISE EXCEPTION 'COMPLETE ROLLBACK - Are you ABSOLUTELY sure?';
  RAISE NOTICE 'Removing ALL Emowed tables, functions, and views...';
END $$;

-- Execute all rollback sections in order
-- (Uncomment each section above, starting from Phase 6 down to Phase 1)

DO $$
BEGIN
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'COMPLETE ROLLBACK FINISHED';
  RAISE NOTICE 'All Emowed database objects removed';
  RAISE NOTICE '==========================================';
END $$;
*/

-- ============================================
-- PARTIAL ROLLBACK HELPER
-- ============================================
-- Generate list of tables to review before rollback

-- List all Emowed tables
SELECT
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- List all Emowed functions
SELECT
  n.nspname as schema,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname NOT LIKE 'pg_%'
ORDER BY p.proname;

-- List all Emowed views
SELECT
  schemaname,
  viewname,
  viewowner
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;

-- ============================================
-- ROLLBACK VERIFICATION
-- ============================================
-- After rollback, verify objects are removed

-- Count remaining tables
SELECT COUNT(*) as remaining_tables
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

-- Count remaining functions
SELECT COUNT(*) as remaining_functions
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION';

-- Count remaining views
SELECT COUNT(*) as remaining_views
FROM pg_views
WHERE schemaname = 'public';

-- ============================================
-- RECOVERY FROM ROLLBACK
-- ============================================
/*
If you need to restore after rollback:

1. Restore from backup:
   - Supabase Dashboard → Database → Backups
   - Select backup and restore

2. Or re-run migrations:
   - Execute phase SQL files in order (1 → 6)
   - Execute views and helper functions

3. Or use pg_restore (if you have dump file):
   psql -U postgres -d database_name -f backup.sql
*/

-- ============================================
-- USAGE EXAMPLES
-- ============================================
/*
EXAMPLE 1: Rollback only Phase 6
-------------------------------
1. Backup database first
2. Uncomment Phase 6 rollback section
3. Execute the uncommented section
4. Verify with verification queries
5. Re-run Phase 6 if needed

EXAMPLE 2: Rollback Phases 5 & 6
---------------------------------
1. Backup database first
2. Uncomment Phase 6 section
3. Execute Phase 6 section
4. Uncomment Phase 5 section
5. Execute Phase 5 section
6. Verify with verification queries

EXAMPLE 3: Complete reset
-------------------------
1. BACKUP DATABASE FIRST! (Critical!)
2. Uncomment all sections from bottom to top
3. Execute complete rollback section
4. Database is now empty
5. Re-run all migrations if needed
*/

-- ============================================
-- BEST PRACTICES
-- ============================================
/*
1. ALWAYS BACKUP FIRST
   - Use Supabase dashboard backup
   - Or: pg_dump database_name > backup.sql
   - Store backup securely

2. TEST IN DEVELOPMENT FIRST
   - Never rollback in production without testing
   - Use development database to verify rollback works

3. COMMUNICATE WITH TEAM
   - Inform team before rollback
   - Schedule downtime if needed
   - Have rollback plan reviewed

4. MONITOR AFTER ROLLBACK
   - Check application still works
   - Verify no broken references
   - Test critical user flows

5. DOCUMENT CHANGES
   - Log why rollback was needed
   - Document what was rolled back
   - Update migration tracking
*/

-- ============================================
-- ALTERNATIVE: SOFT ROLLBACK
-- ============================================
/*
Instead of dropping tables, you can:

1. Disable RLS temporarily
2. Truncate tables (keeps structure)
3. Recreate seed data
4. Re-enable RLS

This is safer than complete DROP:

-- Example soft rollback
TRUNCATE TABLE wedding_games CASCADE;
TRUNCATE TABLE game_participants CASCADE;
-- etc.

Then re-insert seed data if needed.
*/

-- ============================================
-- NOTES
-- ============================================
/*
- All rollback sections are commented by default for safety
- Uncomment only what you need to rollback
- Execute in reverse order (Phase 6 → 1)
- Always verify after rollback
- Have recovery plan ready

Remember: Prevention is better than cure!
- Test migrations in development first
- Use transactions where possible
- Keep good backups
- Document all changes
*/

-- ============================================
-- FINAL WARNING
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'ROLLBACK SCRIPTS LOADED';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'These scripts are DESTRUCTIVE!';
  RAISE NOTICE 'Read comments carefully before executing';
  RAISE NOTICE 'ALWAYS backup before rollback';
  RAISE NOTICE '==========================================';
END $$;
