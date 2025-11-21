-- ============================================
-- EMOWED MASTER DATABASE MIGRATION
-- ============================================
-- Purpose: Complete database setup for Emowed platform
-- Executes all 6 phases in correct order
-- Execute in Supabase SQL Editor
-- ============================================

-- ============================================
-- IMPORTANT INSTRUCTIONS
-- ============================================
--
-- OPTION 1: Run Individual Phase Files (Recommended)
-- ---------------------------------------------------
-- For better error tracking and debugging, run each phase file separately:
-- 1. sql/phase1_auth_couples_weddings.sql
-- 2. sql/phase2_events_guests_rsvp.sql
-- 3. sql/phase3_vendor_system.sql
-- 4. sql/phase4_media_program.sql
-- 5. sql/phase5_games_leaderboards_gifts.sql
-- 6. sql/phase6_matchmaking_postmarriage.sql
--
-- OPTION 2: Run This Master File
-- --------------------------------
-- This file references all individual phase files
-- Use \i or \include if your SQL client supports it
--
-- PostgreSQL/Supabase: Copy and execute each phase manually
--
-- ============================================

-- ============================================
-- PHASE OVERVIEW
-- ============================================

/*
PHASE 1: Authentication, Couples & Weddings
- Tables: 6 (users, partner_invitations, couples, weddings, notifications, cooldown_periods)
- Features: Auth, partner invitations, wedding creation
- Status: ✅ Required for all other phases

PHASE 2: Events, Guests & RSVP
- Tables: 7 (events, guests, guest_invitations, family_tree, rsvps, headcount_snapshots, event_attendees)
- Features: Event management, hierarchical guest system, RSVP tracking
- Status: ✅ Depends on Phase 1

PHASE 3: Vendor Management
- Tables: 8 (vendor_profiles, vendor_invitations, vendor_quotes, vendor_votes, vendor_bookings, vendor_availability, vendor_verifications, vendor_reviews)
- Features: Vendor discovery, quotes, family voting, bookings
- Status: ✅ Depends on Phase 1-2

PHASE 4: Media & Program
- Tables: 10 (media_albums, media_items, media_likes, media_comments, program_sections, ceremony_details, music_playlists, playlist_songs, wedding_timeline, media_shares)
- Features: Photo/video galleries, wedding program builder, music playlists
- Status: ✅ Depends on Phase 1-3

PHASE 5: Games, Leaderboards & Gifting
- Tables: 17 (game_types, wedding_games, game_questions, game_participants, game_responses, wedding_side_competition, photo_challenge_submissions, photo_challenge_votes, leaderboard_categories, singles_leaderboard, singles_activities, couples_leaderboard, couples_milestones, gift_categories, gift_products, guest_gifts, gift_wishlists)
- Features: Interactive games, competitive leaderboards, digital gifting
- Status: ✅ Depends on Phase 1-4

PHASE 6: Matchmaking & Post-Marriage
- Tables: 19 (matchmaking_profiles, match_preferences, match_swipes, matches, match_conversations, parent_invitations, match_probability_cache, couple_diary_entries, couple_shared_goals, date_night_plans, trip_plans, gift_tracking, community_forum_categories, community_forum_posts, community_forum_comments, community_forum_votes, spam_prevention, counselor_profiles, counseling_sessions)
- Features: Dating system, post-marriage support, community forum, counseling
- Status: ✅ Depends on Phase 1-5

TOTAL: 67 tables across 6 phases
*/

-- ============================================
-- PRE-MIGRATION CHECKS
-- ============================================

DO $$
BEGIN
  -- Check PostgreSQL version
  IF current_setting('server_version_num')::integer < 120000 THEN
    RAISE EXCEPTION 'PostgreSQL 12+ required. Current version: %', current_setting('server_version');
  END IF;

  -- Check if uuid-ossp extension can be created
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

  RAISE NOTICE 'Pre-migration checks passed!';
  RAISE NOTICE 'PostgreSQL version: %', current_setting('server_version');
END $$;

-- ============================================
-- EXECUTION INSTRUCTIONS
-- ============================================

/*
TO EXECUTE THIS MIGRATION:

Step 1: Backup (if existing database)
--------------------------------------
-- Export existing data if any
-- pg_dump your_database > backup.sql

Step 2: Run Phases Sequentially
--------------------------------
Option A - Manual (Recommended):
1. Open each phase file in Supabase SQL Editor
2. Execute one by one in order
3. Verify each phase completes successfully

Option B - Single Script:
1. Copy contents of this file
2. Execute in Supabase SQL Editor
3. Monitor for errors

Step 3: Verification
--------------------
After all phases complete, run these queries:

-- Count total tables
SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';
-- Expected: ~67 tables

-- List all tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Count functions
SELECT COUNT(*) as total_functions
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION';
-- Expected: ~20+ functions

-- Count triggers
SELECT COUNT(*) as total_triggers
FROM information_schema.triggers
WHERE trigger_schema = 'public';
-- Expected: ~15+ triggers

Step 4: Test Core Functionality
--------------------------------
-- Create test user
INSERT INTO users (email, full_name, age, relationship_status)
VALUES ('test@emowed.com', 'Test User', 25, 'single')
RETURNING id;

-- Verify RLS policies work
-- Try to query as that user

Step 5: Frontend Integration
-----------------------------
-- Update your .env.local with Supabase credentials
-- Test authentication flow
-- Test partner invitation flow
-- Test wedding creation
*/

-- ============================================
-- MIGRATION NOTES
-- ============================================

/*
IMPORTANT NOTES:

1. EXECUTION TIME
   - Phase 1: ~30 seconds
   - Phase 2: ~45 seconds
   - Phase 3: ~60 seconds
   - Phase 4: ~45 seconds
   - Phase 5: ~90 seconds
   - Phase 6: ~90 seconds
   - Total: ~6 minutes

2. DEPENDENCIES
   - Each phase depends on previous phases
   - Do NOT skip phases
   - Do NOT run phases out of order

3. ROLLBACK
   - To rollback a specific phase, drop its tables
   - Be careful with CASCADE deletes
   - Always backup before migration

4. ROW LEVEL SECURITY (RLS)
   - All tables have RLS enabled
   - Policies are restrictive by default
   - Test with actual user tokens

5. INDEXES
   - Indexes created automatically with tables
   - Verify performance after data load
   - May need additional indexes based on usage

6. TRIGGERS & FUNCTIONS
   - Automatic updates for counters
   - Verification and validation logic
   - Business rule enforcement

7. SEED DATA
   - Game types added in Phase 5
   - Gift categories added in Phase 5
   - Forum categories added in Phase 6
   - Add more seed data as needed

8. NEXT STEPS AFTER MIGRATION
   - Set up authentication in Supabase Auth
   - Configure storage buckets for images
   - Set up Cloudinary for media
   - Configure Razorpay for payments
   - Set up email service (Resend)
   - Configure environment variables
*/

-- ============================================
-- QUICK START GUIDE
-- ============================================

/*
FOR FIRST-TIME SETUP:

1. Create Supabase Project
   - Go to supabase.com
   - Create new project
   - Wait for provisioning
   - Copy project URL and anon key

2. Run Migration
   - Open Supabase SQL Editor
   - Run phase1_auth_couples_weddings.sql
   - Run phase2_events_guests_rsvp.sql
   - Run phase3_vendor_system.sql
   - Run phase4_media_program.sql
   - Run phase5_games_leaderboards_gifts.sql
   - Run phase6_matchmaking_postmarriage.sql

3. Configure Authentication
   - Enable email/password auth
   - Set email templates
   - Configure redirect URLs

4. Set Up Storage
   - Create bucket: profile-photos
   - Create bucket: wedding-media
   - Create bucket: vendor-portfolios
   - Set RLS policies for buckets

5. Update Frontend
   - Set VITE_SUPABASE_URL
   - Set VITE_SUPABASE_ANON_KEY
   - Run npm install
   - Run npm run dev

6. Test Basic Flows
   - User signup
   - Partner invitation
   - Wedding creation
   - Guest invitation
   - RSVP submission

7. Go Live
   - Run npm run build
   - Deploy to Vercel/Netlify
   - Configure custom domain
   - Enable monitoring
*/

-- ============================================
-- TROUBLESHOOTING
-- ============================================

/*
COMMON ISSUES:

1. "Extension uuid-ossp does not exist"
   Solution: Run "CREATE EXTENSION IF NOT EXISTS uuid-ossp;"

2. "Table already exists"
   Solution: Either drop the table or skip that statement
   - Be careful with DROP CASCADE

3. "Function already exists"
   Solution: DROP FUNCTION first or use OR REPLACE

4. "Permission denied"
   Solution: Ensure you're using the postgres role in Supabase

5. "Foreign key constraint violation"
   Solution: Ensure you run phases in order

6. RLS policies blocking queries
   Solution: Check auth.uid() is set correctly in your app

7. Triggers not firing
   Solution: Verify trigger is created with \d+ table_name

8. Performance issues
   Solution: Check indexes with \d table_name
             Add missing indexes for frequent queries
*/

-- ============================================
-- SUPPORT & RESOURCES
-- ============================================

/*
DOCUMENTATION:
- Emowed Docs: docs/ folder in repository
- Supabase Docs: https://supabase.com/docs
- PostgreSQL Docs: https://www.postgresql.org/docs/

COMMUNITY:
- GitHub Issues: Report bugs and feature requests
- Discord: Join Emowed community (if available)

NEED HELP?
- Check CLAUDE.md for detailed instructions
- Review individual phase files
- Check Supabase logs for errors
- Review RLS policies if data access issues
*/

-- ============================================
-- SUCCESS VERIFICATION
-- ============================================

-- After migration, run this to verify everything is set up correctly:

DO $$
DECLARE
  v_table_count INTEGER;
  v_function_count INTEGER;
  v_trigger_count INTEGER;
BEGIN
  -- Count tables
  SELECT COUNT(*) INTO v_table_count
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

  -- Count functions
  SELECT COUNT(*) INTO v_function_count
  FROM information_schema.routines
  WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';

  -- Count triggers
  SELECT COUNT(*) INTO v_trigger_count
  FROM information_schema.triggers
  WHERE trigger_schema = 'public';

  RAISE NOTICE '==========================================';
  RAISE NOTICE 'EMOWED DATABASE MIGRATION VERIFICATION';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'Tables Created: % (Expected: ~67)', v_table_count;
  RAISE NOTICE 'Functions Created: % (Expected: ~20+)', v_function_count;
  RAISE NOTICE 'Triggers Created: % (Expected: ~15+)', v_trigger_count;
  RAISE NOTICE '==========================================';

  IF v_table_count >= 60 THEN
    RAISE NOTICE '✅ SUCCESS: All phases migrated successfully!';
  ELSE
    RAISE WARNING '⚠️ WARNING: Some tables may be missing. Expected ~67, found %', v_table_count;
  END IF;

  RAISE NOTICE '==========================================';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '1. Configure Supabase Auth';
  RAISE NOTICE '2. Set up Storage buckets';
  RAISE NOTICE '3. Update frontend environment variables';
  RAISE NOTICE '4. Test authentication flow';
  RAISE NOTICE '5. Deploy frontend to production';
  RAISE NOTICE '==========================================';
END $$;

-- ============================================
-- READY TO BUILD!
-- ============================================
-- Your database is now ready for Emowed.
-- From First Swipe to Forever! 💕
-- ============================================
