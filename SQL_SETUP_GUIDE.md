# Emowed - SQL Database Setup Guide

## 🚀 Quick Start

This guide will help you set up the complete database schema for Emowed in Supabase.

## Prerequisites

- Supabase account (free tier works)
- Access to Supabase SQL Editor

## Setup Steps

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Project Name**: Emowed
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your target users (e.g., ap-south-1 for India)
5. Click "Create new project"
6. Wait 2-3 minutes for provisioning

### Step 2: Get Your API Credentials

1. In your project dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public** key
3. Save these in your `.env` file

### Step 3: Run Database Migrations

You have two options:

#### Option A: Run All Phases at Once (Recommended for new projects)

1. Open Supabase SQL Editor (Database → SQL Editor)
2. Run the migrations in this order:

```sql
-- 1. Run Phase 1: Authentication, Couples & Weddings
-- Copy and paste contents from: sql/phase1_auth_couples_weddings.sql

-- 2. Run Phase 2: Events, Guests & RSVP
-- Copy and paste contents from: sql/phase2_events_guests_rsvp.sql

-- 3. Run Phase 3: Vendor System
-- Copy and paste contents from: sql/phase3_vendor_system.sql

-- 4. Run Phase 4: Media & Program
-- Copy and paste contents from: sql/phase4_media_program.sql

-- 5. Run Phase 5: Games & Leaderboards
-- Copy and paste contents from: sql/phase5_games_leaderboards_gifts.sql

-- 6. Run Phase 6: Matchmaking & Post-Marriage
-- Copy and paste contents from: sql/phase6_matchmaking_postmarriage.sql
```

#### Option B: Run Individual SQL Files (For Step-by-Step Setup)

Run each file separately by copying its contents into the SQL Editor and clicking "Run".

**Required Order:**
1. ✅ `sql/phase1_auth_couples_weddings.sql` (MUST run first)
2. ✅ `sql/phase2_events_guests_rsvp.sql`
3. ✅ `sql/phase3_vendor_system.sql`
4. ✅ `sql/phase4_media_program.sql`
5. ✅ `sql/phase5_games_leaderboards_gifts.sql`
6. ✅ `sql/phase6_matchmaking_postmarriage.sql`

### Step 4: Verify Installation

After running all migrations, verify by running:

```sql
-- Check if all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

You should see **67 tables** total.

### Step 5: (Optional) Seed Test Data

For development/testing, you can load sample data:

```sql
-- Copy and paste contents from: sql/seed_data_test.sql
```

### Step 6: Enable Row Level Security (RLS)

RLS policies are included in each phase file. Verify they're enabled:

```sql
-- Check RLS status
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

All tables should show `rowsecurity = true`.

## What Each Phase Includes

### Phase 1: Core (Authentication & Weddings)
- Users management
- Partner invitations (with 6-char codes)
- Couples creation
- Wedding management
- Notifications system

**Tables**: users, partner_invitations, couples, weddings, notifications, cooldown_periods

### Phase 2: Events & Guests
- Event timeline (7 auto-generated events)
- Hierarchical guest system (family tree)
- RSVP tracking with headcount
- Dietary preferences

**Tables**: events, guests, guest_invitations, family_tree, rsvps, headcount_snapshots, event_attendees

### Phase 3: Vendors
- Vendor profiles & verification
- Vendor invitations
- Quote management
- Family voting system
- Booking management
- 5-wedding verification threshold

**Tables**: vendor_profiles, vendor_invitations, vendor_quotes, vendor_votes, vendor_bookings, vendor_availability, vendor_verifications, vendor_reviews

### Phase 4: Media & Program
- Photo/video albums
- Media items with Cloudinary URLs
- Wedding program builder
- Music playlists
- Timeline management

**Tables**: media_albums, media_items, media_likes, media_comments, program_sections, ceremony_details, music_playlists, playlist_songs, wedding_timeline, media_shares

### Phase 5: Games & Leaderboards
- Wedding games (trivia, photo challenges)
- Groom vs Bride side competition
- Singles leaderboard
- Couples milestones
- Digital gifting

**Tables**: game_types, wedding_games, game_questions, game_participants, game_responses, wedding_side_competition, photo_challenge_submissions, photo_challenge_votes, leaderboard_categories, singles_leaderboard, singles_activities, couples_leaderboard, couples_milestones, gift_categories, gift_products, guest_gifts, gift_wishlists

### Phase 6: Matchmaking & Post-Marriage
- Dating system for singles
- Match swipes and conversations
- Parent invitations for matchmaking
- Couple diary
- Shared goals
- Date night planning
- Community forum
- Counseling sessions

**Tables**: matchmaking_profiles, match_preferences, match_swipes, matches, match_conversations, parent_invitations, match_probability_cache, couple_diary_entries, couple_shared_goals, date_night_plans, trip_plans, gift_tracking, community_forum_categories, community_forum_posts, community_forum_comments, community_forum_votes, spam_prevention, counselor_profiles, counseling_sessions

## Important Stored Procedures

The database includes several critical stored procedures that the frontend uses:

1. **`create_partner_invitation`** - Creates partner invitation with validation
2. **`create_wedding_with_events`** - Creates wedding + auto-generates 7 events
3. **`get_engaged_dashboard_data`** - Fetches all dashboard data in one query
4. **`calculate_headcount`** - Calculates food portions (adults 1.0x, teens 0.75x, children 0.3x)

## Troubleshooting

### Error: "relation already exists"
- You're trying to run a migration that's already been executed
- Solution: Skip that migration or drop the tables first

### Error: "permission denied"
- RLS policies are blocking your query
- Solution: Check if you're authenticated in the Supabase client

### Tables not showing up
- Check you're looking in the `public` schema
- Verify the migration ran without errors

### Frontend can't connect
- Verify your `.env` file has correct Supabase URL and anon key
- Check that RLS policies are properly configured

## Next Steps

After database setup:

1. ✅ Copy `.env.example` to `.env`
2. ✅ Add your Supabase credentials to `.env`
3. ✅ Run `npm install` to install dependencies
4. ✅ Run `npm run dev` to start the development server
5. ✅ Navigate to `http://localhost:5173`
6. ✅ Sign up for a new account to test!

## Helpful SQL Queries

```sql
-- Count total users
SELECT COUNT(*) FROM users;

-- View all couples
SELECT * FROM couples;

-- View all weddings
SELECT w.*, c.status as couple_status
FROM weddings w
JOIN couples c ON w.couple_id = c.id;

-- Check vendor verification count
SELECT id, business_name, wedding_count, verification_star
FROM vendor_profiles
ORDER BY wedding_count DESC;

-- View recent notifications
SELECT * FROM notifications
ORDER BY created_at DESC
LIMIT 10;
```

## Database Size

Total schema size: ~12,600 lines of SQL
Total tables: 67
Total stored procedures: 15+
Total views: 10+

## Performance Tips

1. Indexes are already created for frequently queried columns
2. Use the provided stored procedures for complex operations
3. Enable connection pooling in production
4. Consider upgrading Supabase plan for > 10,000 users

## Support

For issues:
- Check Supabase logs: Dashboard → Database → Logs
- Review SQL error messages carefully
- Consult Supabase docs: https://supabase.com/docs

---

**From First Swipe to Forever! 💕**
