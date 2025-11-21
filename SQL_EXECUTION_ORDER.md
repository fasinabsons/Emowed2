# SQL Migration Execution Order

**Important: Execute these files in the exact order specified below**

---

## ⚠️ Critical Instructions

1. **Execute in Supabase SQL Editor** (not your local terminal)
2. **Run one file at a time** to catch errors easily
3. **Wait for success** before proceeding to next file
4. **Do NOT enable RLS** until after testing
5. **Verify each phase** before moving to next

---

## Minimum Required Setup (Core Functionality)

For the app to work, you **MUST** execute these files:

### 1️⃣ Phase 1: Core Authentication & Couples (Required)

**File:** `sql/phase1_auth_couples_weddings.sql`

**What it creates:**
- `users` - User profiles and authentication
- `partner_invitations` - Partner invitation codes
- `couples` - Coupled users
- `weddings` - Wedding details
- `notifications` - User notifications
- `cooldown_periods` - Invitation cooldown tracking

**Time:** ~30 seconds

```sql
-- Copy and paste entire content of phase1_auth_couples_weddings.sql
-- into Supabase SQL Editor and click "Run"
```

---

### 2️⃣ Phase 2: Events, Guests & RSVP (Required)

**File:** `sql/phase2_events_guests_rsvp.sql`

**What it creates:**
- `events` - Wedding events (7 auto-generated + custom)
- `guests` - Guest management with hierarchy
- `guest_invitations` - Guest invitation tracking
- `family_tree` - Relationship hierarchy
- `rsvps` - RSVP responses
- `headcount_snapshots` - Real-time attendance tracking
- `event_attendees` - Event-Guest relationship

**Time:** ~30 seconds

```sql
-- Copy and paste entire content of phase2_events_guests_rsvp.sql
-- into Supabase SQL Editor and click "Run"
```

---

### 3️⃣ Helper Functions & Utilities (Required)

**File:** `sql/helper_functions_utilities.sql`

**What it creates:**
- `create_notification()` - Create user notifications
- `calculate_food_headcount()` - RSVP headcount calculation
- `get_user_wedding_id()` - Get wedding for user
- Various utility functions

**Time:** ~10 seconds

```sql
-- Copy and paste entire content of helper_functions_utilities.sql
-- into Supabase SQL Editor and click "Run"
```

---

### 4️⃣ Advanced Stored Procedures (Required)

**File:** `sql/advanced_stored_procedures.sql`

**What it creates:**
- `create_partner_invitation()` - Complete partner invitation workflow
- `accept_partner_invitation()` - Accept invitation workflow
- `create_wedding_with_events()` - Create wedding + auto-generate 7 events
- `invite_guest()` - Guest invitation workflow
- `submit_rsvp()` - RSVP submission workflow
- `calculate_headcount_for_event()` - Headcount calculation

**Time:** ~30 seconds

```sql
-- Copy and paste entire content of advanced_stored_procedures.sql
-- into Supabase SQL Editor and click "Run"
```

---

## ✅ Minimum Setup Complete!

At this point, you can:
- Sign up and log in
- Create partner invitations
- Accept invitations
- Create weddings
- Manage events
- Invite guests
- Track RSVPs
- View headcount

**Test the app before continuing to optional phases!**

---

## Optional Phases (Additional Features)

### 5️⃣ Phase 3: Vendor Management (Optional)

**File:** `sql/phase3_vendor_system.sql`

**What it creates:**
- `vendor_profiles` - Vendor business profiles
- `vendor_invitations` - Invite vendors to quote
- `vendor_quotes` - Vendor pricing quotes
- `vendor_votes` - Family voting on vendors
- `vendor_bookings` - Confirmed vendor bookings
- `vendor_availability` - Vendor calendar
- `vendor_verifications` - 5-wedding verification system
- `vendor_reviews` - Vendor ratings and reviews

**Time:** ~45 seconds

---

### 6️⃣ Phase 4: Media & Program Management (Optional)

**File:** `sql/phase4_media_program.sql`

**What it creates:**
- `media_albums` - Photo/video albums
- `media_items` - Photos and videos
- `media_likes` - Like system for media
- `media_comments` - Comments on media
- `program_sections` - Wedding program builder
- `ceremony_details` - Ceremony information
- `music_playlists` - Music playlists
- `wedding_timeline` - Timeline/schedule
- `media_shares` - Share media with guests

**Time:** ~45 seconds

---

### 7️⃣ Phase 5: Games, Leaderboards & Gifting (Optional)

**File:** `sql/phase5_games_leaderboards_gifts.sql`

**What it creates:**
- `game_types` - Available game types
- `wedding_games` - Active games for wedding
- `game_participants` - Game players
- `game_responses` - Game answers
- `singles_leaderboard` - Singles competition
- `couples_leaderboard` - Couples competition
- `gift_categories` - Gift categories
- `gift_products` - Digital gift catalog
- `guest_gifts` - Gifts sent to couple
- `gift_wishlists` - Couple's gift wishlist

**Time:** ~60 seconds

---

### 8️⃣ Phase 6: Matchmaking & Post-Marriage (Optional)

**File:** `sql/phase6_matchmaking_postmarriage.sql`

**What it creates:**
- `matchmaking_profiles` - Dating profiles
- `match_preferences` - User preferences
- `match_swipes` - Swipe history
- `matches` - Matched couples
- `match_conversations` - Chat messages
- `couple_diary_entries` - Private couple diary
- `couple_shared_goals` - Shared goal tracking
- `date_night_plans` - Date planning
- `trip_plans` - Trip planning
- `community_forum_posts` - Community forum
- `counselor_profiles` - Marriage counselors
- `counseling_sessions` - Counseling bookings

**Time:** ~60 seconds

---

## Additional Utility Scripts (Optional)

### 9️⃣ Views & Common Queries (Optional)

**File:** `sql/views_common_queries.sql`

**What it creates:**
- Materialized views for common queries
- Performance-optimized views
- Reporting views

**Time:** ~20 seconds

---

### 🔟 Performance Optimization (Optional)

**File:** `sql/performance_optimization.sql`

**What it creates:**
- Additional indexes
- Query optimization
- Performance monitoring

**Time:** ~15 seconds

---

## 🔒 Row Level Security (RLS) - Enable LAST

**File:** `sql/rls_policies.sql`

**⚠️ CRITICAL: Only run this AFTER testing the app!**

**What it does:**
- Enables RLS on all tables
- Creates security policies
- Restricts data access per user
- Protects data at database level

**When to run:**
- ✅ After all testing is complete
- ✅ Before deploying to production
- ✅ When you want database-level security

**Time:** ~60 seconds

```sql
-- Copy and paste entire content of rls_policies.sql
-- into Supabase SQL Editor and click "Run"
```

---

## Verification Scripts (Optional but Recommended)

### Verify Installation

**File:** `sql/verification_consistency_check.sql`

Run this to verify all tables and functions are created correctly:

```sql
-- Copy and paste entire content
-- Returns a detailed report of your database setup
```

### Integration Testing

**File:** `sql/integration_testing_complete.sql`

Run this to test all workflows:

```sql
-- Creates test users and validates all major workflows
-- Use in development environment only!
```

---

## Quick Execution Checklist

Copy this checklist and check off as you complete each step:

### Core Setup (Required)
- [ ] Phase 1: Auth & Couples (`phase1_auth_couples_weddings.sql`)
- [ ] Phase 2: Events & Guests (`phase2_events_guests_rsvp.sql`)
- [ ] Helper Functions (`helper_functions_utilities.sql`)
- [ ] Stored Procedures (`advanced_stored_procedures.sql`)

### Optional Features (Pick what you need)
- [ ] Phase 3: Vendors (`phase3_vendor_system.sql`)
- [ ] Phase 4: Media (`phase4_media_program.sql`)
- [ ] Phase 5: Games (`phase5_games_leaderboards_gifts.sql`)
- [ ] Phase 6: Matchmaking (`phase6_matchmaking_postmarriage.sql`)

### Optimization (Optional)
- [ ] Views (`views_common_queries.sql`)
- [ ] Performance (`performance_optimization.sql`)

### Security (Do Last)
- [ ] RLS Policies (`rls_policies.sql`) - **AFTER TESTING ONLY**

### Verification (Optional)
- [ ] Run verification script (`verification_consistency_check.sql`)
- [ ] Run integration tests (`integration_testing_complete.sql`)

---

## Troubleshooting

### Error: "relation already exists"

**Solution:** The table is already created. This is safe to ignore.

### Error: "function does not exist"

**Solution:** Execute `helper_functions_utilities.sql` first, then retry.

### Error: "permission denied"

**Solution:** Ensure you're logged in as the database owner in Supabase.

### Error: "syntax error"

**Solution:** Copy the ENTIRE file content, including comments.

---

## What Each File Type Does

| File Type | Purpose | Required? |
|-----------|---------|-----------|
| `phase*.sql` | Create database tables and schemas | Yes (1-2) / Optional (3-6) |
| `helper_functions_utilities.sql` | Utility functions | Yes |
| `advanced_stored_procedures.sql` | Complex business logic | Yes |
| `rls_policies.sql` | Security policies | Yes (production) |
| `views_common_queries.sql` | Performance views | No |
| `verification_*.sql` | Testing and validation | No |

---

## Total Execution Time

- **Minimum (Core):** ~2 minutes
- **Full (All Phases):** ~5-6 minutes
- **With RLS:** ~6-7 minutes

---

## After Execution

1. ✅ Verify tables exist in Supabase dashboard
2. ✅ Start your development server: `npm run dev`
3. ✅ Test signup, login, partner invitation
4. ✅ Test wedding creation
5. ✅ Only enable RLS when ready for production

---

**Questions?** Check the QUICK_START.md guide for full setup instructions.

---

**Last Updated:** 2025-11-21
**Database Version:** 2.0.0
**Total Tables:** 67
**Total Functions:** 50+
