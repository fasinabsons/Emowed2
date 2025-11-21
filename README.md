# Emowed - From First Swipe to Forever

A complete relationship platform for Indian couples, supporting them through every stage from dating to marriage and beyond.

## 🎉 Current Status

- ✅ **Phase 1: Complete** - Auth, Partner Invitation, Wedding Creation
- ✅ **Phase 2: Complete** - Events, Guests, RSVP, Headcount Tracking
- 🚧 **Phase 3: Planned** - Vendor Management
- 📋 **Phase 4-6: Planned** - Media, Payments, Post-Marriage

## Features

### Phase 1 Features ✅
- **Partner Connect**: Invite your partner with a simple code and start planning together
- **Wedding Creation**: Multi-step wizard with combined/separate mode selection
- **Authentication**: Secure signup, login, and protected routes
- **Profile Management**: Edit personal information and settings

### Phase 2 Features ✅
- **Event Management**: 7 auto-generated traditional events + custom events
- **Guest Management**: Hierarchical invitation system with role-based permissions
- **RSVP System**: Complete RSVP tracking with intelligent headcount calculation
- **Headcount Dashboard**: Real-time attendance tracking and food planning
- **Dietary Tracking**: Full support for dietary preferences and special requirements
- **Family Hierarchy**: Parent-child relationships with invitation limits

### Coming Soon 🚧
- **Vendor Management**: Book verified vendors based on actual performance
- **Digital Invitations**: Beautiful wedding cards with QR codes
- **Post-Marriage Support**: Access to counseling and couple resources

## Tech Stack

- **Frontend**: React 18 + TypeScript + Tailwind CSS
- **Build Tool**: Vite
- **Backend**: Supabase (PostgreSQL + Auth + RLS)
- **State Management**: React Query
- **Forms**: React Hook Form + Zod
- **Routing**: React Router v6
- **Notifications**: React Hot Toast

## Getting Started

### Prerequisites

- Node.js 18+ installed
- Supabase account (free tier works)

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/emowed.git
cd emowed
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
```bash
cp .env.example .env.local
```

Edit `.env.local` and add your Supabase credentials:
```
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Set up the database

**Run migrations in order:**

a. Phase 1 Migration:
- Go to your Supabase project dashboard
- Navigate to SQL Editor
- Run `docs/database_migration_phase1.sql`

b. Phase 2 Migration:
- In SQL Editor
- Run `sql/phase2_events_guests_rsvp.sql`

5. Start the development server
```bash
npm run dev
```

Visit http://localhost:3000 to see the app!

## Project Structure

```
emowed/
├── sql/
│   └── phase2_events_guests_rsvp.sql    # Phase 2 database migration
├── src/
│   ├── components/                       # Reusable UI components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Modal.tsx
│   │   ├── Layout.tsx
│   │   ├── ProtectedRoute.tsx
│   │   ├── SingleDashboard.tsx
│   │   ├── EngagedDashboard.tsx
│   │   ├── EventCard.tsx
│   │   ├── CreateEventModal.tsx
│   │   ├── EditEventModal.tsx
│   │   ├── InviteGuestModal.tsx
│   │   └── GuestListTable.tsx
│   ├── contexts/                        # React contexts
│   │   └── AuthContext.tsx
│   ├── lib/                             # Utilities and configurations
│   │   └── supabase.ts
│   ├── pages/                           # Page components
│   │   ├── HomePage.tsx
│   │   ├── SignupPage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── DashboardPage.tsx
│   │   ├── ProfilePage.tsx
│   │   ├── WeddingCreatePage.tsx
│   │   ├── AcceptInvitePage.tsx
│   │   ├── EventsPage.tsx
│   │   ├── GuestsPage.tsx
│   │   ├── RSVPPage.tsx
│   │   └── HeadcountPage.tsx
│   ├── App.tsx                          # Main app component
│   ├── main.tsx                         # Entry point
│   └── index.css                        # Global styles
├── docs/                                # Documentation
│   └── database_migration_phase1.sql
├── public/                              # Static assets
└── package.json                         # Dependencies
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## Database Schema

### Phase 1 Tables
- `users` - User profiles and authentication
- `partner_invitations` - Partner invitation codes
- `couples` - Coupled users
- `weddings` - Wedding details
- `notifications` - User notifications
- `cooldown_periods` - Invitation cooldown tracking

### Phase 2 Tables
- `events` - Wedding events (auto-generated + custom)
- `guests` - Guest management with hierarchy
- `guest_invitations` - Guest invitation tracking
- `family_tree` - Relationship hierarchy
- `rsvps` - RSVP responses
- `headcount_snapshots` - Real-time attendance tracking
- `event_attendees` - Event-Guest relationship

## Key Features Implementation

### Authentication
- Email/password signup with validation
- Secure login with Supabase Auth
- Protected routes with auth guards

### Partner Invitation System
- Generate unique 6-character codes
- 48-hour expiry period
- Email notifications
- Acceptance/rejection tracking

### Event Management
- 7 auto-generated traditional events per wedding
- Custom event creation
- Event editing and deletion
- Event countdown and details

### Guest Management
- Hierarchical invitation system
- Role-based permissions (parents can invite, cousins cannot)
- Plus-one support
- VIP guests
- Under-18 handling
- Dietary preferences
- Advanced filtering and search

### RSVP System
- Attendance status tracking
- Headcount calculation with multipliers:
  - Adults: 1.0x
  - Teens (13-17): 0.75x
  - Children (0-12): 0.3x
- Dietary preferences
- Special requirements

### Headcount Dashboard
- Real-time statistics across all events
- Side-by-side comparison (groom vs bride)
- Detailed breakdown by event
- Food planning numbers

### Wedding Creation
- Multi-step wizard
- Combined vs Separate mode selection
- Budget and guest limit tracking

## Environment Variables

Required environment variables:

```
VITE_SUPABASE_URL=       # Your Supabase project URL
VITE_SUPABASE_ANON_KEY=  # Your Supabase anon/public key
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For support, email support@emowed.com or create an issue in the GitHub repository.

## Roadmap

- [x] Phase 1: Core Features (Authentication, Partner Invitation, Wedding Creation)
- [x] Phase 2: Events, Guests, RSVP System
- [ ] Phase 3: Vendor Management
- [ ] Phase 4: Media & Program
- [ ] Phase 5: Payments & Monetization
- [ ] Phase 6: Post-Marriage Features

## Auto-Generated Events

When you create a wedding, 7 traditional events are automatically generated:

1. **Engagement Ceremony** - 60 days before wedding
2. **Save The Date** - 30 days before wedding
3. **Haldi Ceremony** - 2 days before wedding
4. **Mehendi Ceremony** - 1 day before wedding (2:00 PM)
5. **Sangeet Night** - 1 day before wedding (7:00 PM)
6. **Wedding Ceremony** - Wedding day (10:00 AM)
7. **Reception** - Wedding day (7:00 PM)

## Guest Invitation Hierarchy

**Permission Levels:**
- **Groom/Bride:** Can invite anyone
- **Parents:** Can invite anyone except groom/bride
- **Siblings:** Can invite friends, colleagues, others
- **Uncles/Aunts:** Can only invite their immediate family
- **Friends/Colleagues:** Cannot invite anyone

## RSVP Headcount Calculation

The system uses intelligent multipliers for accurate food planning:

```
Headcount = (Adults × 1.0) + (Teens × 0.75) + (Children × 0.3)

Example:
- 2 adults + 1 teen + 1 child
- = (2 × 1.0) + (1 × 0.75) + (1 × 0.3)
- = 2.0 + 0.75 + 0.3
- = 3.05 meal portions
```

## Screenshots & Demo

Coming soon!

---

**Made with ❤️ for Indian couples**

**Current Version:** 2.0.0
**Last Updated:** November 9, 2025
**Status:** Production Ready (Phase 1 + Phase 2)
