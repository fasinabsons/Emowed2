# Emowed - Complete Setup Guide

**From First Swipe to Forever! 💕**

A comprehensive wedding planning platform for Indian couples with family integration, vendor management, and post-marriage support.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Detailed Setup](#detailed-setup)
6. [Features Overview](#features-overview)
7. [Project Structure](#project-structure)
8. [Development](#development)
9. [Deployment](#deployment)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

Emowed is a full-lifecycle relationship platform designed specifically for Indian couples. It supports users from dating through marriage and beyond with features like:

- Partner invitations with unique codes
- Wedding planning with automatic event generation
- Hierarchical guest management (family tree)
- Vendor verification system
- Photo/video galleries
- Interactive wedding games
- Matchmaking for singles
- Post-marriage support (diary, goals, counseling)

### Key Metrics
- **67 database tables** across 6 phases
- **15+ pages** fully implemented
- **12,600+ lines** of SQL
- **Complete wedding lifecycle** coverage

---

## 🛠️ Tech Stack

### Frontend
- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool & dev server
- **TailwindCSS** - Styling
- **React Router v6** - Routing
- **React Hook Form + Zod** - Form validation
- **React Hot Toast** - Notifications
- **TanStack Query** - Server state management

### Backend
- **Supabase** - Backend-as-a-Service
  - PostgreSQL database
  - Authentication
  - Row Level Security (RLS)
  - Real-time subscriptions
  - Storage for media files

### Media & Payments (Optional)
- **Cloudinary** - Photo/video hosting
- **Razorpay** - Payment processing

---

## ✅ Prerequisites

### Required
- **Node.js** 18+ ([Download](https://nodejs.org/))
- **npm** 8+ (comes with Node.js)
- **Supabase account** (free tier works) - [Sign up](https://supabase.com/)
- **Git** ([Download](https://git-scm.com/))

### Optional
- **Cloudinary account** for media uploads
- **Razorpay account** for payments
- **VS Code** (recommended editor)

---

## 🚀 Quick Start

Get up and running in 10 minutes:

```bash
# 1. Clone the repository
cd Emowed2

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env
# Edit .env and add your Supabase credentials

# 4. Set up database (see SQL_SETUP_GUIDE.md)
# - Create Supabase project
# - Run all 6 phase migrations

# 5. Start development server
npm run dev

# 6. Open browser
# Navigate to http://localhost:5173
```

---

## 📝 Detailed Setup

### Step 1: Environment Configuration

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Get Supabase credentials:
   - Go to [Supabase Dashboard](https://supabase.com/dashboard)
   - Create new project
   - Go to Settings → API
   - Copy **Project URL** and **anon public key**

3. Update `.env`:
   ```env
   VITE_SUPABASE_URL=https://xxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=your_anon_key_here
   ```

### Step 2: Database Setup

Follow the complete database setup in **[SQL_SETUP_GUIDE.md](./SQL_SETUP_GUIDE.md)**

**Summary:**
1. Create Supabase project
2. Run migrations in order:
   - Phase 1: Auth & Weddings
   - Phase 2: Events & Guests
   - Phase 3: Vendors
   - Phase 4: Media
   - Phase 5: Games
   - Phase 6: Matchmaking & Post-Marriage
3. Verify 67 tables created
4. (Optional) Load seed data

### Step 3: Install Dependencies

```bash
npm install
```

This installs:
- React & React DOM
- React Router
- Supabase client
- TanStack Query
- Tailwind CSS
- Form libraries (React Hook Form, Zod)
- TypeScript

### Step 4: Start Development Server

```bash
npm run dev
```

Visit `http://localhost:5173` in your browser.

---

## 🌟 Features Overview

### Phase 1: Authentication & Couples ✅
- **User Registration** with age verification (18+)
- **Login/Logout** with session management
- **Partner Invitations** with 6-character codes
- **48-hour expiry** and rejection limits
- **Couple Creation** when invitation accepted
- **Wedding Creation** with automatic event generation

### Phase 2: Events & Guests ✅
- **7 Auto-Generated Events**:
  - Engagement (60 days before wedding)
  - Save the Date (30 days before)
  - Haldi (2 days before)
  - Mehendi (1 day before)
  - Sangeet (1 day before evening)
  - Wedding Ceremony (wedding day)
  - Reception (wedding day evening)
- **Custom Events** creation
- **Hierarchical Guest System**:
  - Groom/Bride (unlimited invites)
  - Parents (unlimited invites)
  - Siblings (can invite spouse/kids)
  - Uncles/Aunts (limited invites)
  - Cousins (cannot invite)
- **RSVP Tracking** with weighted headcount:
  - Adults: 1.0x
  - Teens: 0.75x
  - Children: 0.3x
- **Dietary Preferences** (vegetarian, vegan, halal, etc.)

### Phase 3: Vendor System ✅
- **Vendor Directory** with filtering
- **Vendor Invitations** to weddings
- **Quote Management** from multiple vendors
- **Family Voting** on vendor selection
- **Vendor Verification** (⭐ star after 5 weddings)
- **Vendor Reviews** from verified bookings
- **Booking Management** with payment tracking

### Phase 4: Media & Galleries ✅
- **Photo/Video Albums**
- **Media Upload** (Cloudinary integration ready)
- **Album Organization** by event
- **Image Viewer** with captions
- **7-Day Deletion** for free tier users

### Phase 5: Wedding Games ✅
- **Couple Trivia**
- **Photo Challenges**
- **Dance Battles** (Groom vs Bride)
- **Wishes & Predictions**
- **Scavenger Hunts**
- **Leaderboards** (Groom's side vs Bride's side)

### Phase 6: Matchmaking & Post-Marriage ✅
- **Dating System** for singles
- **Swipe Interface** (like/dislike)
- **Match Notifications** on mutual likes
- **Couple Diary** with mood tracking
- **Shared Goals** (financial, health, career, etc.)
- **Date Night Planner**
- **Gift Tracking**
- **Counseling** connections

---

## 📁 Project Structure

```
Emowed2/
├── public/               # Static assets
├── src/
│   ├── components/       # Reusable components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Modal.tsx
│   │   ├── Layout.tsx
│   │   ├── ProtectedRoute.tsx
│   │   ├── SingleDashboard.tsx
│   │   ├── EngagedDashboard.tsx
│   │   └── ...
│   ├── contexts/         # React contexts
│   │   └── AuthContext.tsx
│   ├── lib/              # Utilities
│   │   └── supabase.ts   # Supabase client & types
│   ├── pages/            # Page components
│   │   ├── HomePage.tsx
│   │   ├── SignupPage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── DashboardPage.tsx
│   │   ├── ProfilePage.tsx
│   │   ├── WeddingCreatePage.tsx
│   │   ├── EventsPage.tsx
│   │   ├── GuestsPage.tsx
│   │   ├── RSVPPage.tsx
│   │   ├── HeadcountPage.tsx
│   │   ├── VendorDirectoryPage.tsx
│   │   ├── VendorProfilePage.tsx
│   │   ├── VendorManagementPage.tsx
│   │   ├── VendorDashboardPage.tsx
│   │   ├── GalleryPage.tsx
│   │   ├── GamesPage.tsx
│   │   ├── MatchmakingPage.tsx
│   │   └── PostMarriagePage.tsx
│   ├── App.tsx           # Main app component
│   ├── main.tsx          # Entry point
│   └── index.css         # Global styles
├── sql/                  # Database migrations
│   ├── phase1_auth_couples_weddings.sql
│   ├── phase2_events_guests_rsvp.sql
│   ├── phase3_vendor_system.sql
│   ├── phase4_media_program.sql
│   ├── phase5_games_leaderboards_gifts.sql
│   ├── phase6_matchmaking_postmarriage.sql
│   └── ...
├── .env.example          # Environment template
├── .env                  # Your environment variables (git ignored)
├── package.json          # Dependencies
├── tailwind.config.js    # Tailwind configuration
├── tsconfig.json         # TypeScript configuration
├── vite.config.ts        # Vite configuration
├── SQL_SETUP_GUIDE.md    # Database setup guide
└── SETUP.md              # This file
```

---

## 💻 Development

### Available Scripts

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

### Development Workflow

1. **Start dev server**: `npm run dev`
2. **Make changes** to source files
3. **Hot reload** automatically updates browser
4. **Check console** for errors
5. **Test features** in browser
6. **Commit changes** when ready

### Adding New Features

1. **Create database tables** (if needed) in appropriate phase SQL file
2. **Add types** to `src/lib/supabase.ts`
3. **Create page component** in `src/pages/`
4. **Add route** in `src/App.tsx`
5. **Add navigation link** in `src/components/Layout.tsx`
6. **Test thoroughly**

### Database Changes

1. Write migration SQL
2. Test in Supabase SQL editor
3. Add to appropriate phase file
4. Update type definitions
5. Document in SQL_SETUP_GUIDE.md

---

## 🚢 Deployment

### Option 1: Vercel (Recommended)

1. Push code to GitHub
2. Import project in Vercel
3. Add environment variables
4. Deploy

```bash
# Build command
npm run build

# Output directory
dist
```

### Option 2: Netlify

1. Push code to GitHub
2. Import project in Netlify
3. Configure:
   - Build command: `npm run build`
   - Publish directory: `dist`
4. Add environment variables
5. Deploy

### Environment Variables (Production)

Make sure to add these in your deployment platform:

```env
VITE_SUPABASE_URL=your_production_url
VITE_SUPABASE_ANON_KEY=your_production_key
```

---

## 🐛 Troubleshooting

### Database Issues

**Tables not found**
- Verify all 6 phases ran successfully
- Check you're looking in `public` schema
- Run: `SELECT * FROM information_schema.tables WHERE table_schema = 'public';`

**RLS blocking queries**
- Ensure user is authenticated
- Check RLS policies are correct
- Temporarily disable RLS for testing (NOT in production)

### Frontend Issues

**Supabase connection error**
- Verify `.env` file exists and has correct values
- Check Supabase project is running
- Confirm API URL and key are correct

**TypeScript errors**
- Run `npm install` to ensure all types are installed
- Check `tsconfig.json` is correct
- Restart VS Code TypeScript server

**Build errors**
- Clear node_modules: `rm -rf node_modules && npm install`
- Clear build cache: `rm -rf dist`
- Update dependencies: `npm update`

### Common Errors

```
Error: Missing Supabase environment variables
Solution: Create .env file with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
```

```
Error: relation "users" does not exist
Solution: Run Phase 1 migration in Supabase
```

```
Error: Failed to fetch
Solution: Check Supabase project is running and URL is correct
```

---

## 📚 Additional Resources

- **Supabase Docs**: https://supabase.com/docs
- **React Docs**: https://react.dev/
- **Vite Docs**: https://vitejs.dev/
- **Tailwind Docs**: https://tailwindcss.com/docs

---

## 🎉 You're Ready!

Start the development server and begin building:

```bash
npm run dev
```

Navigate to `http://localhost:5173` and create your first account!

### Next Steps

1. ✅ Sign up for a new account
2. ✅ Invite your partner with a code
3. ✅ Create your wedding
4. ✅ Add events and guests
5. ✅ Explore all features!

---

**Questions?** Check the documentation files:
- `SQL_SETUP_GUIDE.md` - Database setup
- `README.md` - Project overview
- `docs/tasks.txt` - Development tasks
- `docs/` - Additional documentation

**From First Swipe to Forever! 💕**

---

*Last Updated: November 2025*
