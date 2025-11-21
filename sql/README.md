# Emowed Database Migrations

Complete SQL migrations for the Emowed wedding platform.

## 📁 Files Overview

### Core Migration Files
| File | Size | Tables | Description |
|------|------|--------|-------------|
| `00_MASTER_MIGRATION.sql` | 13 KB | 0 | Master migration guide and instructions |
| `phase1_auth_couples_weddings.sql` | 12 KB | 6 | Core authentication, couples, and weddings |
| `phase2_events_guests_rsvp.sql` | 24 KB | 7 | Events, guest management, and RSVP system |
| `phase3_vendor_system.sql` | 28 KB | 8 | Vendor management and booking system |
| `phase4_media_program.sql` | 22 KB | 10 | Media galleries and wedding program builder |
| `phase5_games_leaderboards_gifts.sql` | 28 KB | 17 | Interactive games, leaderboards, and digital gifting |
| `phase6_matchmaking_postmarriage.sql` | 30 KB | 19 | Matchmaking and post-marriage support |
| **MIGRATION TOTAL** | **157 KB** | **67** | **Complete database schema** |

### Utility & Enhancement Files
| File | Size | Description |
|------|------|-------------|
| `views_common_queries.sql` | 16 KB | Pre-built views for common data queries |
| `helper_functions_utilities.sql` | 16 KB | Utility functions for data operations |
| `advanced_stored_procedures.sql` | 38 KB | Complete workflow procedures for frontend |
| `performance_optimization.sql` | 33 KB | Performance tuning and indexes |
| `monitoring_health_checks.sql` | 18 KB | Database monitoring and health checks |
| `backup_restore_procedures.sql` | 30 KB | Backup and restore procedures |
| `rollback_migrations.sql` | 18 KB | Rollback procedures for migrations |
| `admin_utilities.sql` | 29 KB | Administrative utilities and tools |
| `seed_data_test.sql` | 16 KB | Sample test data for development |
| `integration_testing_complete.sql` | 34 KB | Complete end-to-end testing scenarios |
| **UTILITIES TOTAL** | **248 KB** | **Comprehensive utilities & testing** |

### Documentation Files
| File | Description |
|------|-------------|
| `README.md` | This file - complete setup guide |
| `QUICK_REFERENCE.md` | Quick reference for common queries |

## 🚀 Quick Start

### Prerequisites
- Supabase account (free tier works)
- PostgreSQL 12+ (provided by Supabase)
- Basic SQL knowledge

### Step 1: Create Supabase Project
```bash
1. Go to https://supabase.com
2. Sign up or log in
3. Click "New Project"
4. Enter project details:
   - Name: Emowed
   - Database Password: [create strong password]
   - Region: ap-south-1 (Mumbai) or nearest
5. Wait 2-3 minutes for provisioning
```

### Step 2: Run Migrations

**Option A: Individual Phase Files (Recommended)**
```sql
-- In Supabase SQL Editor, run each file in order:

1. phase1_auth_couples_weddings.sql      -- ✅ Core tables
2. phase2_events_guests_rsvp.sql         -- ✅ Events & guests
3. phase3_vendor_system.sql              -- ✅ Vendors
4. phase4_media_program.sql              -- ✅ Media & program
5. phase5_games_leaderboards_gifts.sql   -- ✅ Games & gifts
6. phase6_matchmaking_postmarriage.sql   -- ✅ Matchmaking & support
```

**Option B: Copy-Paste Each Phase**
```bash
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Create new query
4. Copy contents of phase1_auth_couples_weddings.sql
5. Click "Run"
6. Repeat for each phase file
```

### Step 3: Install Utility Functions (Recommended)
```sql
-- In Supabase SQL Editor, run these for enhanced functionality:

7. views_common_queries.sql              -- ✅ Pre-built views
8. helper_functions_utilities.sql         -- ✅ Utility functions
9. advanced_stored_procedures.sql         -- ✅ Workflow procedures
10. performance_optimization.sql          -- ✅ Performance tuning
```

### Step 4: Verify Installation
```sql
-- Run this query to verify all tables are created:

SELECT COUNT(*) as total_tables
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

-- Expected result: ~67 tables
```

### Step 5: Run Integration Tests (Optional but Recommended)
```sql
-- Load sample data and test all workflows:
-- Run: integration_testing_complete.sql

-- This will:
-- ✅ Create test users
-- ✅ Test partner invitations
-- ✅ Test wedding creation
-- ✅ Test guest invitations
-- ✅ Test RSVP submissions
-- ✅ Test all stored procedures
-- ✅ Verify all features work end-to-end
```

## 📊 Phase Details

### Phase 1: Authentication, Couples & Weddings (Required)
**File:** `phase1_auth_couples_weddings.sql`
**Tables:** 6
**Duration:** ~30 seconds

Creates core tables:
- ✅ `users` - User profiles and authentication
- ✅ `partner_invitations` - Partner invitation codes
- ✅ `couples` - Coupled users
- ✅ `weddings` - Wedding details
- ✅ `notifications` - User notifications
- ✅ `cooldown_periods` - Invitation cooldown tracking

**Features:**
- User signup and login
- Partner invitation system
- Couple formation
- Wedding creation
- Notification system

---

### Phase 2: Events, Guests & RSVP
**File:** `phase2_events_guests_rsvp.sql`
**Tables:** 7
**Duration:** ~45 seconds
**Depends on:** Phase 1

Creates event and guest management tables:
- ✅ `events` - Wedding event management
- ✅ `guests` - Guest management with hierarchy
- ✅ `guest_invitations` - Guest invitation tracking
- ✅ `family_tree` - Relationship hierarchy
- ✅ `rsvps` - RSVP responses
- ✅ `headcount_snapshots` - Real-time attendance tracking
- ✅ `event_attendees` - Event-Guest relationships

**Features:**
- Auto-generate 7 traditional wedding events
- Hierarchical guest invitation system
- Role-based permissions
- RSVP with headcount tracking
- Real-time headcount dashboard

---

### Phase 3: Vendor Management
**File:** `phase3_vendor_system.sql`
**Tables:** 8
**Duration:** ~60 seconds
**Depends on:** Phase 1, 2

Creates vendor system tables:
- ✅ `vendor_profiles` - Vendor business profiles
- ✅ `vendor_invitations` - Vendor invitation tracking
- ✅ `vendor_quotes` - Vendor pricing quotes
- ✅ `vendor_votes` - Family voting system
- ✅ `vendor_bookings` - Confirmed bookings
- ✅ `vendor_availability` - Date/time availability
- ✅ `vendor_verifications` - 5-wedding verification
- ✅ `vendor_reviews` - Post-wedding reviews

**Features:**
- Vendor discovery and invitations
- Quote management
- Family voting on vendors
- Booking and payment tracking
- 5-wedding verification system
- Review and rating system

---

### Phase 4: Media & Program
**File:** `phase4_media_program.sql`
**Tables:** 10
**Duration:** ~45 seconds
**Depends on:** Phase 1, 2, 3

Creates media and program tables:
- ✅ `media_albums` - Photo and video album organization
- ✅ `media_items` - Individual photos and videos
- ✅ `media_likes` - User likes on media
- ✅ `media_comments` - Comments on media
- ✅ `program_sections` - Wedding program/timeline builder
- ✅ `ceremony_details` - Detailed ceremony information
- ✅ `music_playlists` - Wedding music playlists
- ✅ `playlist_songs` - Individual songs in playlists
- ✅ `wedding_timeline` - Pre-wedding planning milestones
- ✅ `media_shares` - Shareable media links

**Features:**
- Photo and video galleries
- Social engagement (likes, comments)
- Wedding program builder
- Ceremony details management
- Music playlist creation
- Planning timeline tracker
- Secure media sharing

---

### Phase 5: Games, Leaderboards & Gifting
**File:** `phase5_games_leaderboards_gifts.sql`
**Tables:** 17
**Duration:** ~90 seconds
**Depends on:** Phase 1, 2, 3, 4

Creates interactive features:
- ✅ `game_types` - Game templates
- ✅ `wedding_games` - Wedding-specific game instances
- ✅ `game_questions` - Quiz/trivia questions
- ✅ `game_participants` - Game participants
- ✅ `game_responses` - Game answers/responses
- ✅ `wedding_side_competition` - Groom vs Bride competition
- ✅ `photo_challenge_submissions` - Photo challenge entries
- ✅ `photo_challenge_votes` - Photo challenge votes
- ✅ `leaderboard_categories` - Leaderboard categories
- ✅ `singles_leaderboard` - Singles ranking
- ✅ `singles_activities` - Singles activity log
- ✅ `couples_leaderboard` - Couples ranking
- ✅ `couples_milestones` - Couple milestones
- ✅ `gift_categories` - Gift categories
- ✅ `gift_products` - Gift product catalog
- ✅ `guest_gifts` - Guest gift purchases
- ✅ `gift_wishlists` - Couple's wishlist

**Features:**
- Interactive wedding games
- Quiz and photo challenges
- Groom vs Bride side competition
- Singles personal growth leaderboard
- Couples milestones leaderboard
- Digital gift marketplace
- Gift wishlist management

---

### Phase 6: Matchmaking & Post-Marriage
**File:** `phase6_matchmaking_postmarriage.sql`
**Tables:** 19
**Duration:** ~90 seconds
**Depends on:** Phase 1, 2, 3, 4, 5

Creates premium features:
- ✅ `matchmaking_profiles` - Dating profiles
- ✅ `match_preferences` - Match filters and preferences
- ✅ `match_swipes` - Likes and passes
- ✅ `matches` - Mutual likes and matches
- ✅ `match_conversations` - In-app messaging
- ✅ `parent_invitations` - Parent mode invitations
- ✅ `match_probability_cache` - Match success rate calculation
- ✅ `couple_diary_entries` - Couple's private diary
- ✅ `couple_shared_goals` - Shared goals tracker
- ✅ `date_night_plans` - Date night planner
- ✅ `trip_plans` - Trip planning
- ✅ `gift_tracking` - Gift tracker
- ✅ `community_forum_categories` - Forum categories
- ✅ `community_forum_posts` - Forum posts
- ✅ `community_forum_comments` - Forum comments
- ✅ `community_forum_votes` - Forum voting
- ✅ `spam_prevention` - Anti-spam system
- ✅ `counselor_profiles` - Counselor profiles
- ✅ `counseling_sessions` - Counseling bookings

**Features:**
- Matchmaking/dating system (Premium)
- Advanced filters and preferences
- Parent mode
- Match probability calculation
- Couple's diary
- Shared goals tracker
- Date night planner
- Trip planning
- Community forum
- Counseling integration

---

## 🚀 Advanced Stored Procedures

The `advanced_stored_procedures.sql` file provides complete workflow procedures that encapsulate business logic, making frontend development much easier.

### Partner Invitation Workflows

**1. Create Partner Invitation**
```sql
SELECT * FROM create_partner_invitation(
  'sender-user-id',
  'receiver@example.com',
  'Will you be my partner?'
);

-- Returns: success, code, error_message, expires_at
```

**2. Accept Partner Invitation**
```sql
SELECT * FROM accept_partner_invitation(
  'receiver-user-id',
  'ABC123'  -- invitation code
);

-- Returns: success, couple_id, error_message
-- Automatically creates couple and updates user statuses
```

**3. Reject Partner Invitation**
```sql
SELECT * FROM reject_partner_invitation(
  'receiver-user-id',
  'ABC123'
);

-- Handles rejection count and cooldown periods automatically
```

### Wedding Creation Workflows

**Create Wedding with Auto-Generated Events**
```sql
SELECT * FROM create_wedding_with_events(
  'user-id',
  'Our Amazing Wedding',
  '2025-12-25',
  'Grand Hotel Ballroom',
  'Mumbai',
  'combined',
  500000.00,
  500
);

-- Returns: success, wedding_id, events_created, error_message
-- Automatically generates 7 traditional wedding events
```

### Dashboard Data Aggregation

**Get Single User Dashboard** (one query for all data)
```sql
SELECT get_single_dashboard_data('user-id');

-- Returns JSON with:
-- - User profile
-- - Pending invitations
-- - Received invitations
-- - Recent notifications
-- - Cooldown status
```

**Get Engaged User Dashboard** (one query for all data)
```sql
SELECT get_engaged_dashboard_data('user-id');

-- Returns JSON with:
-- - Couple information
-- - Wedding details
-- - Wedding stats (events, guests, vendors)
-- - Upcoming events
-- - Recent notifications
```

### Guest Invitation Workflows

**Invite Guest with Validation**
```sql
SELECT * FROM invite_wedding_guest(
  'wedding-id',
  'inviter-user-id',
  'guest@example.com',
  'Guest Name',
  '+91 98765 43210',
  'groom',  -- side
  'friend',  -- role
  FALSE,  -- can_invite_others
  TRUE  -- plus_one_allowed
);

-- Returns: success, guest_id, error_message
-- Automatically validates role-based permissions
```

### RSVP Submission Workflows

**Submit RSVP with Automatic Headcount Calculation**
```sql
SELECT * FROM submit_rsvp(
  'guest-id',
  'event-id',
  'attending',
  2,  -- adults
  1,  -- teens
  1,  -- children
  ARRAY['vegetarian', 'vegan'],
  'No peanuts please',
  'Looking forward to it!'
);

-- Returns: success, rsvp_id, calculated_headcount, error_message
-- Automatically:
-- - Calculates headcount (adults * 1.0 + teens * 0.75 + children * 0.3)
-- - Updates headcount snapshots
-- - Sends notifications to couple
```

### Analytics Workflows

**Get Complete Wedding Analytics**
```sql
SELECT get_wedding_analytics('wedding-id');

-- Returns JSON with comprehensive analytics:
-- - Event statistics
-- - Guest statistics (by side, status, role)
-- - RSVP completion rate
-- - Total headcount
-- - Budget summary
-- - Progress percentage
```

### Why Use Stored Procedures?

✅ **Less Frontend Code** - Complex logic handled in database
✅ **Better Performance** - Single database round-trip
✅ **Consistent Validation** - Business rules enforced at DB level
✅ **Automatic Notifications** - Triggers handle notifications
✅ **Transaction Safety** - All-or-nothing operations
✅ **Easier Testing** - Test business logic without frontend

---

## 🔒 Security Features

All tables include:
- ✅ Row Level Security (RLS) enabled
- ✅ Secure policies for data access
- ✅ User isolation
- ✅ Couple-specific data separation
- ✅ Guest permissions
- ✅ Vendor data protection

## ⚙️ Functions & Triggers

**Automated Business Logic:**
- Auto-calculate headcount for RSVPs
- Auto-generate wedding events on wedding creation
- Auto-update leaderboard rankings
- Auto-calculate vendor commissions
- Auto-create matches on mutual likes
- Auto-update forum post stats
- Spam prevention
- And more...

## 📝 Post-Migration Steps

### 1. Configure Authentication
```bash
# In Supabase Dashboard:
1. Go to Authentication > Settings
2. Enable Email provider
3. Set email templates
4. Configure redirect URLs
5. Set JWT expiry (recommended: 1 week)
```

### 2. Set Up Storage
```sql
-- Create storage buckets:
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('profile-photos', 'profile-photos', true),
  ('wedding-media', 'wedding-media', false),
  ('vendor-portfolios', 'vendor-portfolios', true);

-- Set RLS policies for buckets
-- See Supabase storage documentation
```

### 3. Update Frontend Environment
```bash
# .env.local
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Test Core Flows
- [ ] User signup
- [ ] User login
- [ ] Partner invitation (send and accept)
- [ ] Couple formation
- [ ] Wedding creation
- [ ] Event auto-generation
- [ ] Guest invitation
- [ ] RSVP submission
- [ ] Vendor invitation
- [ ] Quote submission

## 🐛 Troubleshooting

### Common Issues

**1. "Extension uuid-ossp does not exist"**
```sql
-- Solution:
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

**2. "Table already exists"**
```sql
-- Solution: Drop and recreate (⚠️ This will delete data!)
DROP TABLE table_name CASCADE;
-- Then re-run the migration
```

**3. "Foreign key constraint violation"**
```
Solution: Run phases in correct order (1 → 2 → 3 → 4 → 5 → 6)
```

**4. RLS blocking queries**
```
Solution: Ensure auth.uid() is set correctly in your frontend
Check: SELECT auth.uid(); should return your user ID
```

**5. Performance issues**
```sql
-- Solution: Check if indexes exist
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

## 📊 Database Statistics

After successful migration:

```sql
-- Total tables
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
-- Expected: ~67

-- Total functions
SELECT COUNT(*) FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
-- Expected: ~20+

-- Total triggers
SELECT COUNT(*) FROM information_schema.triggers
WHERE trigger_schema = 'public';
-- Expected: ~15+

-- Total RLS policies
SELECT COUNT(*) FROM pg_policies
WHERE schemaname = 'public';
-- Expected: ~70+
```

## 🎯 Next Steps

1. ✅ Complete database migration
2. ⬜ Set up authentication
3. ⬜ Configure storage buckets
4. ⬜ Install frontend dependencies
5. ⬜ Update environment variables
6. ⬜ Test authentication flow
7. ⬜ Test partner invitation flow
8. ⬜ Test wedding creation flow
9. ⬜ Deploy frontend to Vercel/Netlify
10. ⬜ Configure custom domain
11. ⬜ Set up monitoring (optional)
12. ⬜ Launch! 🚀

## 📚 Documentation

- **Main Documentation:** `docs/` folder
- **Architecture:** `docs/architecture.txt`
- **Frontend Guide:** `docs/frontend.txt`
- **Implementation Guide:** `docs/IMPLEMENTATION_GUIDE.txt`
- **Tasks:** `docs/tasks.txt`

## 💡 Tips

- Always run migrations in a test environment first
- Backup your database before major changes
- Use transactions for critical operations
- Monitor Supabase logs for errors
- Test RLS policies thoroughly
- Keep track of applied migrations

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Supabase logs
3. Check individual phase file comments
4. Refer to main documentation
5. Open an issue on GitHub

## ✅ Migration Checklist

- [ ] Supabase project created
- [ ] Phase 1 migration completed
- [ ] Phase 2 migration completed
- [ ] Phase 3 migration completed
- [ ] Phase 4 migration completed
- [ ] Phase 5 migration completed
- [ ] Phase 6 migration completed
- [ ] All 67 tables created
- [ ] All functions created
- [ ] All triggers created
- [ ] RLS policies enabled
- [ ] Authentication configured
- [ ] Storage buckets created
- [ ] Frontend environment updated
- [ ] Core flows tested
- [ ] Ready for deployment

---

**From First Swipe to Forever! 💕**

*Last Updated: November 17, 2025*
