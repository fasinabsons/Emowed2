# Emowed - Quick Start Guide

## 🚀 Get Your Wedding App Running in 15 Minutes!

This guide will help you get Emowed up and running quickly.

## Prerequisites

- Node.js 18 or higher
- A Supabase account (free tier is fine)
- A code editor (VS Code recommended)

## Step-by-Step Setup

### 1. Install Dependencies (2 minutes)

```bash
cd Emowed2
npm install
```

This will install all required packages (~50MB).

### 2. Set Up Supabase (5 minutes)

#### a. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up/Login
4. Click "New Project"
5. Fill in:
   - **Name:** Emowed
   - **Database Password:** Create a strong password (save it!)
   - **Region:** Choose closest to you (for India: ap-south-1)
6. Click "Create new project"
7. Wait 2-3 minutes for provisioning

#### b. Get Your API Keys
1. In your Supabase project, click "Settings" (gear icon)
2. Click "API" in the sidebar
3. Copy:
   - **Project URL** (looks like: https://xxxxx.supabase.co)
   - **anon/public key** (long string)

#### c. Configure Environment
1. Open `.env.local` in your project
2. Replace with your actual values:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-actual-anon-key-here
```
3. Save the file

### 3. Set Up Database (5 minutes)

#### a. Run Phase 1 Migration
1. In Supabase dashboard, click "SQL Editor" in left sidebar
2. Click "New query"
3. Copy entire contents of `docs/database_migration_phase1.sql`
4. Paste into SQL Editor
5. Click "Run" (or press Ctrl+Enter)
6. Wait for "Success. No rows returned"

#### b. Run Phase 2 Migration
1. Still in SQL Editor, click "New query"
2. Copy entire contents of `sql/phase2_events_guests_rsvp.sql`
3. Paste into SQL Editor
4. Click "Run" (or press Ctrl+Enter)
5. Wait for "Success. No rows returned"

#### c. Verify Tables
1. Click "Table Editor" in left sidebar
2. You should see 13 tables:
   - users
   - partner_invitations
   - couples
   - weddings
   - notifications
   - cooldown_periods
   - events
   - guests
   - guest_invitations
   - family_tree
   - rsvps
   - headcount_snapshots
   - event_attendees

If you see all 13 tables, you're good! ✅

### 4. Start the App (1 minute)

```bash
npm run dev
```

You should see:
```
  VITE v5.0.10  ready in 500 ms

  ➜  Local:   http://localhost:3000/
  ➜  Network: use --host to expose
```

### 5. Test It Out! (2 minutes)

#### a. Visit the App
Open http://localhost:3000 in your browser

#### b. Create an Account
1. Click "Sign Up"
2. Fill in the form:
   - Full Name: Your Name
   - Email: your@email.com
   - Password: Test@1234 (or any strong password)
   - Age: 25
   - Phone: Optional
3. Click "Sign Up"
4. You'll see "Account created! Please check your email to verify"

#### c. Login
1. Click "Login"
2. Enter your email and password
3. Click "Login"
4. You'll be redirected to your dashboard!

## 🎉 You're Done!

You now have a fully functional wedding planning app with:
- ✅ User authentication
- ✅ Partner invitation system
- ✅ Wedding creation
- ✅ Event management (7 auto-generated events!)
- ✅ Guest management with hierarchy
- ✅ RSVP system
- ✅ Headcount tracking

## Next Steps

### Test the Full Flow

1. **Invite Your Partner**
   - Go to Dashboard
   - Click "Generate Invitation Code"
   - Copy the code
   - Share via WhatsApp or email

2. **Create a Wedding**
   - After partner accepts, you'll both be "engaged"
   - Click "Create Our Wedding"
   - Fill in wedding details
   - 7 events are auto-generated!

3. **Manage Events**
   - Click "Events" in navigation
   - See all 7 traditional events
   - Add custom events

4. **Invite Guests**
   - Click "Guests" in navigation
   - Click "Invite Guest"
   - Fill in guest details
   - Assign roles and permissions

5. **Track RSVPs**
   - Click "Headcount" in navigation
   - See real-time statistics
   - Track food planning numbers

## Troubleshooting

### Issue: "Missing Supabase environment variables"
**Fix:** Make sure `.env.local` has correct URL and key

### Issue: Tables not showing in Supabase
**Fix:** Run the SQL migrations again in order (Phase 1, then Phase 2)

### Issue: Can't login after signup
**Fix:** Check if email verification is required in Supabase Auth settings

### Issue: Events not auto-generating
**Fix:** Make sure Phase 2 migration ran successfully (check for trigger)

### Issue: npm install fails
**Fix:** Make sure you have Node.js 18+ installed: `node --version`

## File Structure

```
Emowed2/
├── sql/
│   └── phase2_events_guests_rsvp.sql
├── src/
│   ├── components/         # 15+ components
│   ├── contexts/           # Auth context
│   ├── lib/               # Supabase client
│   ├── pages/             # 11 pages
│   ├── App.tsx
│   └── main.tsx
├── docs/
│   └── database_migration_phase1.sql
├── .env.local             # ⚠️ Add your keys here
├── package.json
├── README.md
└── QUICK_START.md (this file)
```

## Available Pages

Once logged in, you can access:

- `/dashboard` - Main dashboard
- `/events` - Event management
- `/guests` - Guest management
- `/headcount` - RSVP tracking
- `/profile` - Your profile
- `/wedding/create` - Wedding creation wizard

## What You Get

### Phase 1 ✅
- Authentication (Signup, Login, Logout)
- Partner invitation with codes
- Wedding creation wizard
- Profile management

### Phase 2 ✅
- 7 auto-generated wedding events
- Custom event creation
- Guest invitation with hierarchy
- Role-based permissions
- RSVP system with headcount
- Real-time headcount dashboard
- Dietary preferences tracking

### Phase 3-6 (Coming Later)
- Vendor management
- Media galleries
- Digital invitations
- Payment integration
- Post-marriage features

## Support

Having issues? Check:
1. QUICK_START.md (this file)
2. README.md (detailed docs)
3. PHASE2_COMPLETE.md (Phase 2 features)
4. IMPLEMENTATION_COMPLETE.md (Phase 1 features)

## Development Commands

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linter
npm run lint
```

## Database Backups

Your Supabase project has automatic backups. You can also export:
1. Go to Supabase Dashboard
2. Click "Database"
3. Click "Backups"
4. Download if needed

## Production Deployment

Ready to deploy? Check README.md for deployment instructions to:
- Vercel (recommended)
- Netlify
- Custom server

---

**Enjoy building amazing weddings with Emowed! 💕**

**Questions?** Check the docs or create an issue on GitHub.

**Made with ❤️ for Indian couples**
