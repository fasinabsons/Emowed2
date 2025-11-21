-- ============================================
-- EMOWED SEED DATA - TEST ENVIRONMENT
-- ============================================
-- Purpose: Populate database with realistic test data
-- Use Case: Development, testing, and demos
-- WARNING: Only run in development/staging environments!
-- ============================================

-- ============================================
-- SAFETY CHECK
-- ============================================
DO $$
BEGIN
  IF current_database() = 'production' THEN
    RAISE EXCEPTION 'CANNOT RUN SEED DATA IN PRODUCTION!';
  END IF;
  RAISE NOTICE 'Running seed data in database: %', current_database();
END $$;

-- ============================================
-- CLEAR EXISTING DATA (Optional)
-- ============================================
-- Uncomment to clear all data before seeding

-- TRUNCATE TABLE counseling_sessions CASCADE;
-- TRUNCATE TABLE counselor_profiles CASCADE;
-- TRUNCATE TABLE spam_prevention CASCADE;
-- TRUNCATE TABLE community_forum_votes CASCADE;
-- TRUNCATE TABLE community_forum_comments CASCADE;
-- TRUNCATE TABLE community_forum_posts CASCADE;
-- TRUNCATE TABLE community_forum_categories CASCADE;
-- TRUNCATE TABLE gift_tracking CASCADE;
-- TRUNCATE TABLE trip_plans CASCADE;
-- TRUNCATE TABLE date_night_plans CASCADE;
-- TRUNCATE TABLE couple_shared_goals CASCADE;
-- TRUNCATE TABLE couple_diary_entries CASCADE;
-- TRUNCATE TABLE match_probability_cache CASCADE;
-- TRUNCATE TABLE parent_invitations CASCADE;
-- TRUNCATE TABLE match_conversations CASCADE;
-- TRUNCATE TABLE matches CASCADE;
-- TRUNCATE TABLE match_swipes CASCADE;
-- TRUNCATE TABLE match_preferences CASCADE;
-- TRUNCATE TABLE matchmaking_profiles CASCADE;
-- TRUNCATE TABLE photo_challenge_votes CASCADE;
-- TRUNCATE TABLE photo_challenge_submissions CASCADE;
-- TRUNCATE TABLE gift_wishlists CASCADE;
-- TRUNCATE TABLE guest_gifts CASCADE;
-- TRUNCATE TABLE gift_products CASCADE;
-- TRUNCATE TABLE gift_categories CASCADE;
-- TRUNCATE TABLE couples_milestones CASCADE;
-- TRUNCATE TABLE couples_leaderboard CASCADE;
-- TRUNCATE TABLE singles_activities CASCADE;
-- TRUNCATE TABLE singles_leaderboard CASCADE;
-- TRUNCATE TABLE leaderboard_categories CASCADE;
-- TRUNCATE TABLE wedding_side_competition CASCADE;
-- TRUNCATE TABLE game_responses CASCADE;
-- TRUNCATE TABLE game_participants CASCADE;
-- TRUNCATE TABLE game_questions CASCADE;
-- TRUNCATE TABLE wedding_games CASCADE;
-- TRUNCATE TABLE game_types CASCADE;
-- TRUNCATE TABLE media_shares CASCADE;
-- TRUNCATE TABLE wedding_timeline CASCADE;
-- TRUNCATE TABLE playlist_songs CASCADE;
-- TRUNCATE TABLE music_playlists CASCADE;
-- TRUNCATE TABLE ceremony_details CASCADE;
-- TRUNCATE TABLE program_sections CASCADE;
-- TRUNCATE TABLE media_comments CASCADE;
-- TRUNCATE TABLE media_likes CASCADE;
-- TRUNCATE TABLE media_items CASCADE;
-- TRUNCATE TABLE media_albums CASCADE;
-- TRUNCATE TABLE vendor_reviews CASCADE;
-- TRUNCATE TABLE vendor_verifications CASCADE;
-- TRUNCATE TABLE vendor_availability CASCADE;
-- TRUNCATE TABLE vendor_bookings CASCADE;
-- TRUNCATE TABLE vendor_votes CASCADE;
-- TRUNCATE TABLE vendor_quotes CASCADE;
-- TRUNCATE TABLE vendor_invitations CASCADE;
-- TRUNCATE TABLE vendor_profiles CASCADE;
-- TRUNCATE TABLE event_attendees CASCADE;
-- TRUNCATE TABLE headcount_snapshots CASCADE;
-- TRUNCATE TABLE rsvps CASCADE;
-- TRUNCATE TABLE family_tree CASCADE;
-- TRUNCATE TABLE guest_invitations CASCADE;
-- TRUNCATE TABLE guests CASCADE;
-- TRUNCATE TABLE events CASCADE;
-- TRUNCATE TABLE notifications CASCADE;
-- TRUNCATE TABLE cooldown_periods CASCADE;
-- TRUNCATE TABLE weddings CASCADE;
-- TRUNCATE TABLE couples CASCADE;
-- TRUNCATE TABLE partner_invitations CASCADE;
-- TRUNCATE TABLE users CASCADE;

-- ============================================
-- TEST USERS
-- ============================================
-- Note: In production, users are created via Supabase Auth
-- These are for testing database relationships only

INSERT INTO users (id, email, full_name, age, relationship_status, age_verified, can_invite) VALUES
-- Singles
('11111111-1111-1111-1111-111111111111', 'ahmed@test.com', 'Ahmed Khan', 28, 'single', true, true),
('22222222-2222-2222-2222-222222222222', 'priya@test.com', 'Priya Sharma', 26, 'single', true, true),
('33333333-3333-3333-3333-333333333333', 'rahul@test.com', 'Rahul Verma', 30, 'single', true, true),

-- Engaged Couples
('44444444-4444-4444-4444-444444444444', 'faseen@test.com', 'Faseen Ali', 29, 'engaged', true, false),
('55555555-5555-5555-5555-555555555555', 'hanan@test.com', 'Hanan Sheikh', 27, 'engaged', true, false),

('66666666-6666-6666-6666-666666666666', 'rohan@test.com', 'Rohan Kapoor', 31, 'engaged', true, false),
('77777777-7777-7777-7777-777777777777', 'sneha@test.com', 'Sneha Patel', 28, 'engaged', true, false),

-- Married Couple
('88888888-8888-8888-8888-888888888888', 'arjun@test.com', 'Arjun Singh', 32, 'married', true, false),
('99999999-9999-9999-9999-999999999999', 'meera@test.com', 'Meera Singh', 29, 'married', true, false)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- COUPLES
-- ============================================

INSERT INTO couples (id, user1_id, user2_id, status, engaged_date, married_date) VALUES
-- Engaged couples
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'engaged', '2024-11-01', NULL),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '66666666-6666-6666-6666-666666666666', '77777777-7777-7777-7777-777777777777', 'engaged', '2024-10-15', NULL),

-- Married couple
('cccccccc-cccc-cccc-cccc-cccccccccccc', '88888888-8888-8888-8888-888888888888', '99999999-9999-9999-9999-999999999999', 'married', '2023-12-01', '2024-06-15')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- WEDDINGS
-- ============================================

INSERT INTO weddings (id, couple_id, name, date, venue, city, mode, budget_limit, guest_limit, status) VALUES
-- Upcoming wedding
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Faseen & Hanan Wedding', '2025-12-15', 'Grand Palace Hotel', 'Mumbai', 'combined', 500000, 500, 'planning'),

-- Another upcoming wedding
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Rohan & Sneha Wedding', '2025-11-25', 'Royal Gardens', 'Delhi', 'combined', 750000, 600, 'confirmed'),

-- Completed wedding
('ffffffff-ffff-ffff-ffff-ffffffffffff', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Arjun & Meera Wedding', '2024-06-15', 'Beach Resort', 'Goa', 'combined', 1000000, 400, 'completed')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- EVENTS (Auto-generated for weddings)
-- ============================================

INSERT INTO events (wedding_id, event_name, event_date, event_time, venue, city, event_type, description) VALUES
-- Faseen & Hanan Wedding Events
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Engagement Ceremony', '2025-10-16', '18:00:00', 'Grand Palace Hotel', 'Mumbai', 'engagement', 'Ring exchange ceremony'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Haldi Ceremony', '2025-12-13', '10:00:00', 'Grand Palace Hotel', 'Mumbai', 'haldi', 'Traditional turmeric ceremony'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Mehendi Ceremony', '2025-12-14', '15:00:00', 'Grand Palace Hotel', 'Mumbai', 'mehendi', 'Henna art ceremony'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Sangeet Night', '2025-12-14', '19:00:00', 'Grand Palace Hotel', 'Mumbai', 'sangeet', 'Musical night with performances'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Wedding Ceremony', '2025-12-15', '11:00:00', 'Grand Palace Hotel', 'Mumbai', 'wedding', 'Main wedding ceremony'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Reception', '2025-12-15', '19:00:00', 'Grand Palace Hotel', 'Mumbai', 'reception', 'Evening reception and dinner'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Honeymoon Departure', '2025-12-17', '08:00:00', 'Mumbai Airport', 'Mumbai', 'custom', 'Departure for Maldives')
ON CONFLICT DO NOTHING;

-- ============================================
-- GUESTS
-- ============================================

INSERT INTO guests (wedding_id, guest_name, guest_email, guest_phone, relationship_side, role, under_18, invited_by) VALUES
-- Faseen & Hanan Wedding Guests
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Uncle Ahmed', 'uncle.ahmed@test.com', '+919876543210', 'groom', 'uncle', false, '44444444-4444-4444-4444-444444444444'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Aunt Fatima', 'aunt.fatima@test.com', '+919876543211', 'bride', 'aunt', false, '55555555-5555-5555-5555-555555555555'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Cousin Ali', 'cousin.ali@test.com', '+919876543212', 'groom', 'cousin', false, '44444444-4444-4444-4444-444444444444'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Friend Zara', 'zara@test.com', '+919876543213', 'bride', 'friend', false, '55555555-5555-5555-5555-555555555555'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Little Sara', NULL, NULL, 'bride', 'cousin', true, '55555555-5555-5555-5555-555555555555')
ON CONFLICT DO NOTHING;

-- ============================================
-- VENDOR PROFILES
-- ============================================

INSERT INTO vendor_profiles (user_id, business_name, category, city, base_price, description, portfolio_url, is_sponsored, rating) VALUES
('11111111-1111-1111-1111-111111111111', 'Royal Caterers', 'caterer', 'Mumbai', 50000, 'Premium catering services for weddings', 'https://example.com/royal-caterers', true, 4.8),
('22222222-2222-2222-2222-222222222222', 'Priya Photography', 'photographer', 'Delhi', 75000, 'Professional wedding photography and videography', 'https://example.com/priya-photo', true, 4.9),
('33333333-3333-3333-3333-333333333333', 'Verma Decorators', 'decorator', 'Mumbai', 100000, 'Complete wedding decoration and setup', 'https://example.com/verma-decor', false, 4.6)
ON CONFLICT DO NOTHING;

-- ============================================
-- GAME TYPES (Already seeded in phase5, adding more)
-- ============================================

INSERT INTO game_types (game_code, game_name, game_category, description, scoring_method) VALUES
('quiz_bride_groom', 'Bride vs Groom Quiz', 'quiz', 'Test who knows the couple better', 'points'),
('photo_funny', 'Funniest Wedding Moment', 'photo_challenge', 'Submit the funniest photo from the wedding', 'votes')
ON CONFLICT (game_code) DO NOTHING;

-- ============================================
-- GIFT PRODUCTS (Sample products)
-- ============================================

INSERT INTO gift_products (category_id, product_name, product_code, brand, product_type, base_price, description, is_active, featured) VALUES
((SELECT id FROM gift_categories WHERE category_code = 'home_kitchen' LIMIT 1), 'Philips Air Fryer', 'PROD-AF-001', 'Philips', 'physical', 12499, 'Digital air fryer with rapid air technology', true, true),
((SELECT id FROM gift_categories WHERE category_code = 'electronics' LIMIT 1), 'Sony Bluetooth Speaker', 'PROD-SPEAKER-001', 'Sony', 'physical', 8999, 'Portable wireless speaker with bass boost', true, true),
((SELECT id FROM gift_categories WHERE category_code = 'gift_cards' LIMIT 1), 'Amazon Gift Card', 'PROD-GC-AMAZON', 'Amazon', 'gift_card', 1000, 'Digital gift card - any amount', true, true),
((SELECT id FROM gift_categories WHERE category_code = 'home_kitchen' LIMIT 1), 'Borosil Dinner Set', 'PROD-DINNER-001', 'Borosil', 'physical', 3999, '32-piece dinner set', true, false)
ON CONFLICT (product_code) DO NOTHING;

-- ============================================
-- COUPLES LEADERBOARD (Initialize)
-- ============================================

INSERT INTO couples_leaderboard (couple_id, overall_score, milestones_achieved) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 500, 3),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 750, 5),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 2500, 15)
ON CONFLICT (couple_id) DO NOTHING;

-- ============================================
-- SINGLES LEADERBOARD (Initialize)
-- ============================================

INSERT INTO singles_leaderboard (user_id, overall_score, personal_growth_score, career_achievement_score) VALUES
('11111111-1111-1111-1111-111111111111', 450, 250, 200),
('22222222-2222-2222-2222-222222222222', 680, 400, 280),
('33333333-3333-3333-3333-333333333333', 320, 180, 140)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================
-- FORUM CATEGORIES (Already seeded in phase6)
-- ============================================
-- Verify forum categories exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM community_forum_categories WHERE category_slug = 'wedding-planning') THEN
    INSERT INTO community_forum_categories (category_name, category_slug, description, display_order) VALUES
    ('Wedding Planning', 'wedding-planning', 'Tips and advice for planning your wedding', 1);
  END IF;
END $$;

-- ============================================
-- SAMPLE FORUM POSTS
-- ============================================

INSERT INTO community_forum_posts (category_id, author_id, author_name, post_title, post_content, tags) VALUES
((SELECT id FROM community_forum_categories WHERE category_slug = 'wedding-planning' LIMIT 1),
 '44444444-4444-4444-4444-444444444444',
 'Faseen Ali',
 'How to choose the perfect wedding venue?',
 'We are planning our wedding for December 2025 and struggling to choose between indoor and outdoor venues. Any advice on what factors to consider?',
 ARRAY['venue', 'planning', 'advice']),

((SELECT id FROM community_forum_categories WHERE category_slug = 'wedding-planning' LIMIT 1),
 '66666666-6666-6666-6666-666666666666',
 'Rohan Kapoor',
 'Budget-friendly decoration ideas',
 'Looking for creative decoration ideas that won''t break the bank. What worked for you?',
 ARRAY['decoration', 'budget', 'diy'])
ON CONFLICT DO NOTHING;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
  v_users_count INTEGER;
  v_couples_count INTEGER;
  v_weddings_count INTEGER;
  v_events_count INTEGER;
  v_guests_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_users_count FROM users;
  SELECT COUNT(*) INTO v_couples_count FROM couples;
  SELECT COUNT(*) INTO v_weddings_count FROM weddings;
  SELECT COUNT(*) INTO v_events_count FROM events;
  SELECT COUNT(*) INTO v_guests_count FROM guests;

  RAISE NOTICE '==========================================';
  RAISE NOTICE 'SEED DATA INSERTED SUCCESSFULLY';
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'Test Users: %', v_users_count;
  RAISE NOTICE 'Test Couples: %', v_couples_count;
  RAISE NOTICE 'Test Weddings: %', v_weddings_count;
  RAISE NOTICE 'Test Events: %', v_events_count;
  RAISE NOTICE 'Test Guests: %', v_guests_count;
  RAISE NOTICE '==========================================';
  RAISE NOTICE 'You can now test the application with:';
  RAISE NOTICE '- Email: faseen@test.com (Engaged user)';
  RAISE NOTICE '- Email: ahmed@test.com (Single user)';
  RAISE NOTICE '- Email: arjun@test.com (Married user)';
  RAISE NOTICE '==========================================';
END $$;

-- ============================================
-- NOTES
-- ============================================
/*
This seed data provides:
- 9 test users (3 singles, 4 engaged, 2 married)
- 3 couples (2 engaged, 1 married)
- 3 weddings (2 upcoming, 1 completed)
- 7 events for first wedding
- 5 sample guests
- 3 vendor profiles
- Sample gift products
- Forum posts
- Leaderboard entries

To use this data:
1. Create users in Supabase Auth with these emails
2. Use the UUIDs provided here as user IDs
3. Set test passwords for all users
4. Test all features with realistic data

To reset:
1. Uncomment TRUNCATE statements at top
2. Re-run this file
*/
