# Frontend SQL Integration Guide - Emowed

## 🎯 Purpose

This guide shows you how to use the advanced stored procedures in your React/TypeScript frontend. These procedures encapsulate complex business logic, making your frontend code cleaner and more efficient.

---

## 📋 Table of Contents

1. [Setup](#setup)
2. [Partner Invitation Workflows](#partner-invitation-workflows)
3. [Wedding Creation](#wedding-creation)
4. [Dashboard Data](#dashboard-data)
5. [Guest Management](#guest-management)
6. [RSVP System](#rsvp-system)
7. [Analytics](#analytics)
8. [Error Handling](#error-handling)
9. [Real-world Examples](#real-world-examples)

---

## Setup

### Install Supabase Client

```bash
npm install @supabase/supabase-js
```

### Initialize Supabase

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

---

## Partner Invitation Workflows

### 1. Create Partner Invitation

**Stored Procedure:** `create_partner_invitation`

**What it does:**
- Validates user can invite (checks cooldown, relationship status)
- Generates unique 6-character code
- Sets 48-hour expiry
- Creates invitation record
- Sends notification
- Returns code or error

**Frontend Implementation:**

```typescript
// src/components/SingleDashboard.tsx
import { supabase } from '../lib/supabase'
import toast from 'react-hot-toast'

const createInvitation = async (receiverEmail: string, message?: string) => {
  const { user } = useAuth() // Your auth hook

  try {
    const { data: result, error } = await supabase.rpc('create_partner_invitation', {
      p_sender_id: user.id,
      p_receiver_email: receiverEmail,
      p_message: message || null,
    })

    if (error) throw error

    const invitationResult = result[0]

    if (invitationResult.success) {
      toast.success('Invitation created successfully!')
      return {
        code: invitationResult.code,
        expiresAt: invitationResult.expires_at,
      }
    } else {
      toast.error(invitationResult.error_message)
      return null
    }
  } catch (error: any) {
    toast.error(error.message || 'Failed to create invitation')
    return null
  }
}
```

**Response Format:**

```typescript
{
  success: boolean
  code: string | null           // "ABC123"
  error_message: string | null  // "User is already in a relationship"
  expires_at: timestamp | null  // "2025-11-19T10:30:00Z"
}
```

**Error Messages:**
- "User is already in a relationship"
- "User is not allowed to send invitations"
- "User is in cooldown period"
- "User already has a pending invitation"
- "Cannot invite yourself"

---

### 2. Accept Partner Invitation

**Stored Procedure:** `accept_partner_invitation`

**What it does:**
- Validates invitation code
- Checks receiver email matches
- Creates couple record
- Updates both users to 'engaged'
- Sends notifications to both
- Returns couple_id or error

**Frontend Implementation:**

```typescript
// src/pages/AcceptInvitePage.tsx
const acceptInvitation = async (code: string) => {
  const { user } = useAuth()

  try {
    const { data: result, error } = await supabase.rpc('accept_partner_invitation', {
      p_receiver_id: user.id,
      p_code: code,
    })

    if (error) throw error

    const acceptResult = result[0]

    if (acceptResult.success) {
      toast.success('Invitation accepted! You are now engaged! 💍')
      navigate('/dashboard')
      return true
    } else {
      toast.error(acceptResult.error_message)
      return false
    }
  } catch (error: any) {
    toast.error(error.message || 'Failed to accept invitation')
    return false
  }
}
```

**Response Format:**

```typescript
{
  success: boolean
  couple_id: string | null      // UUID of created couple
  error_message: string | null  // "Invalid or expired invitation code"
}
```

---

### 3. Reject Partner Invitation

**Stored Procedure:** `reject_partner_invitation`

**What it does:**
- Updates invitation status to 'rejected'
- Increments rejection count
- Applies cooldown if rejection limit (3) reached
- Notifies sender
- Returns success or error

**Frontend Implementation:**

```typescript
const rejectInvitation = async (code: string) => {
  const { user } = useAuth()

  try {
    const { data: result, error } = await supabase.rpc('reject_partner_invitation', {
      p_receiver_id: user.id,
      p_code: code,
    })

    if (error) throw error

    const rejectResult = result[0]

    if (rejectResult.success) {
      toast.success('Invitation rejected')
      return true
    } else {
      toast.error(rejectResult.error_message)
      return false
    }
  } catch (error: any) {
    toast.error(error.message || 'Failed to reject invitation')
    return false
  }
}
```

---

## Wedding Creation

### Create Wedding with Auto-Generated Events

**Stored Procedure:** `create_wedding_with_events`

**What it does:**
- Validates user is engaged
- Checks wedding date is in future
- Creates wedding record
- AUTO-GENERATES 7 traditional events:
  - Engagement Ceremony (60 days before)
  - Save The Date (30 days before)
  - Haldi Ceremony (2 days before)
  - Mehendi Ceremony (1 day before, 2 PM)
  - Sangeet Night (1 day before, 7 PM)
  - Wedding Ceremony (wedding day, 10 AM)
  - Reception (wedding day, 7 PM)
- Notifies both partners
- Returns wedding_id and events_created

**Frontend Implementation:**

```typescript
// src/pages/WeddingCreatePage.tsx
const createWedding = async (weddingData: WeddingFormData) => {
  const { user } = useAuth()

  try {
    const { data: result, error } = await supabase.rpc('create_wedding_with_events', {
      p_user_id: user.id,
      p_name: weddingData.name,
      p_date: weddingData.date,
      p_venue: weddingData.venue,
      p_city: weddingData.city,
      p_mode: weddingData.mode, // 'combined' or 'separate'
      p_budget_limit: weddingData.budgetLimit || null,
      p_guest_limit: weddingData.guestLimit || 500,
    })

    if (error) throw error

    const weddingResult = result[0]

    if (weddingResult.success) {
      toast.success(
        `Wedding created with ${weddingResult.events_created} events!`,
        { duration: 4000 }
      )
      return weddingResult.wedding_id
    } else {
      toast.error(weddingResult.error_message)
      return null
    }
  } catch (error: any) {
    toast.error(error.message || 'Failed to create wedding')
    return null
  }
}
```

**Response Format:**

```typescript
{
  success: boolean
  wedding_id: string | null         // UUID
  events_created: number            // Should be 7
  error_message: string | null
}
```

**Error Messages:**
- "User must be engaged or married to create a wedding"
- "Wedding date must be in the future"
- "Mode must be either combined or separate"
- "User is not part of a couple"
- "Couple already has an active wedding"

---

## Dashboard Data

### Get Single User Dashboard Data

**Stored Procedure:** `get_single_dashboard_data`

**What it does:**
- Fetches ALL single user dashboard data in ONE query:
  - User profile
  - Pending invitations sent
  - Received invitations
  - Unread notifications
  - Cooldown status
- Returns complete JSON

**Frontend Implementation:**

```typescript
// src/components/SingleDashboard.tsx
const [dashboardData, setDashboardData] = useState<any>(null)

useEffect(() => {
  const fetchDashboardData = async () => {
    const { user } = useAuth()

    const { data, error } = await supabase.rpc('get_single_dashboard_data', {
      p_user_id: user.id,
    })

    if (error) {
      console.error('Error:', error)
      return
    }

    setDashboardData(data)
  }

  fetchDashboardData()
}, [])

// Use the data
const user = dashboardData?.user
const pendingInvitations = dashboardData?.pending_invitations || []
const receivedInvitations = dashboardData?.received_invitations || []
const notifications = dashboardData?.notifications || []
const isInCooldown = dashboardData?.in_cooldown
```

**Response Format:**

```typescript
{
  user: {
    id: string
    email: string
    full_name: string
    age: number
    relationship_status: string
    can_invite: boolean
  },
  pending_invitations: [
    {
      id: string
      code: string
      receiver_email: string
      created_at: timestamp
      expires_at: timestamp
      status: string
    }
  ],
  received_invitations: [
    {
      id: string
      code: string
      sender_id: string
      sender_name: string
      created_at: timestamp
      expires_at: timestamp
      message: string
    }
  ],
  notifications: [
    {
      id: string
      type: string
      title: string
      message: string
      read: boolean
      created_at: timestamp
    }
  ],
  in_cooldown: boolean
}
```

---

### Get Engaged User Dashboard Data

**Stored Procedure:** `get_engaged_dashboard_data`

**What it does:**
- Fetches ALL engaged couple dashboard data in ONE query:
  - Couple information (both partners)
  - Wedding details
  - Wedding statistics (events, guests, vendors)
  - Upcoming events
  - Unread notifications
- Returns complete JSON

**Frontend Implementation:**

```typescript
// src/components/EngagedDashboard.tsx
const [dashboardData, setDashboardData] = useState<any>(null)

useEffect(() => {
  const fetchDashboardData = async () => {
    const { user } = useAuth()

    const { data, error } = await supabase.rpc('get_engaged_dashboard_data', {
      p_user_id: user.id,
    })

    if (error) {
      console.error('Error:', error)
      return
    }

    setDashboardData(data)
  }

  fetchDashboardData()
}, [])

// Use the data
const couple = dashboardData?.couple
const wedding = dashboardData?.wedding
const weddingStats = dashboardData?.wedding_stats
const upcomingEvents = dashboardData?.upcoming_events || []
const notifications = dashboardData?.notifications || []
```

**Response Format:**

```typescript
{
  couple: {
    id: string
    status: string
    engaged_date: date
    married_date: date | null
    user1: {
      id: string
      full_name: string
      email: string
    }
    user2: {
      id: string
      full_name: string
      email: string
    }
  },
  wedding: {
    id: string
    name: string
    date: date
    venue: string
    city: string
    mode: string
    budget_limit: number
    guest_limit: number
    status: string
    days_until: number
  } | null,
  wedding_stats: {
    total_events: number
    total_guests: number
    guests_responded: number
    total_vendors: number
    confirmed_vendors: number
  } | null,
  upcoming_events: [
    {
      id: string
      name: string
      event_type: string
      date: date
      start_time: time
      venue: string
    }
  ],
  notifications: [...]
}
```

---

## Guest Management

### Invite Wedding Guest

**Stored Procedure:** `invite_wedding_guest`

**What it does:**
- Validates inviter has permission
- Checks role-based invitation rules:
  - Groom/Bride: Can invite anyone
  - Parents: Can invite anyone except groom/bride
  - Siblings: Can invite friends, colleagues
  - Uncles/Aunts: Can only invite immediate family
  - Friends/Colleagues: Cannot invite anyone
- Creates guest record
- Creates invitation record
- Returns guest_id or error

**Frontend Implementation:**

```typescript
// src/pages/GuestsPage.tsx
const inviteGuest = async (guestData: GuestFormData) => {
  try {
    const { data: result, error } = await supabase.rpc('invite_wedding_guest', {
      p_wedding_id: weddingId,
      p_inviter_id: user.id,
      p_guest_email: guestData.email,
      p_guest_name: guestData.name,
      p_guest_phone: guestData.phone || null,
      p_side: guestData.side, // 'groom' | 'bride' | 'both'
      p_role: guestData.role, // 'parent' | 'sibling' | 'friend' | etc
      p_can_invite_others: guestData.canInviteOthers || false,
      p_plus_one_allowed: guestData.plusOneAllowed || false,
    })

    if (error) throw error

    const inviteResult = result[0]

    if (inviteResult.success) {
      toast.success(`Invited ${guestData.name}!`)
      return inviteResult.guest_id
    } else {
      toast.error(inviteResult.error_message)
      return null
    }
  } catch (error: any) {
    toast.error(error.message || 'Failed to invite guest')
    return null
  }
}
```

**Response Format:**

```typescript
{
  success: boolean
  guest_id: string | null
  error_message: string | null
}
```

**Error Messages:**
- "User does not have permission to invite guests"
- "Guest with this email already invited"
- "Not authorized to invite guests with this role"
- "Invalid side specified"

---

## RSVP System

### Submit RSVP

**Stored Procedure:** `submit_rsvp`

**What it does:**
- Validates RSVP deadline (24 hours before event)
- Validates headcount (at least 1 adult if attending)
- Calculates smart headcount:
  - Adults × 1.0
  - Teens (13-17) × 0.75
  - Children (0-12) × 0.3
- Creates/updates RSVP record
- Updates headcount snapshots
- Updates guest status
- Notifies couple
- Returns calculated headcount

**Frontend Implementation:**

```typescript
// src/pages/RSVPPage.tsx
const submitRSVP = async (rsvpData: RSVPFormData) => {
  try {
    const { data: result, error } = await supabase.rpc('submit_rsvp', {
      p_guest_id: guestId,
      p_event_id: eventId,
      p_status: rsvpData.status, // 'attending' | 'not_attending' | 'maybe'
      p_adults_count: rsvpData.adults || 1,
      p_teens_count: rsvpData.teens || 0,
      p_children_count: rsvpData.children || 0,
      p_dietary_preferences: rsvpData.dietaryPreferences || null, // Array
      p_special_requirements: rsvpData.specialRequirements || null,
      p_rsvp_notes: rsvpData.notes || null,
    })

    if (error) throw error

    const rsvpResult = result[0]

    if (rsvpResult.success) {
      toast.success(
        `RSVP submitted! Headcount: ${rsvpResult.calculated_headcount.toFixed(2)} meals`
      )
      return true
    } else {
      toast.error(rsvpResult.error_message)
      return false
    }
  } catch (error: any) {
    toast.error(error.message || 'Failed to submit RSVP')
    return false
  }
}
```

**Response Format:**

```typescript
{
  success: boolean
  rsvp_id: string | null
  calculated_headcount: number      // e.g., 3.05
  error_message: string | null
}
```

**Headcount Calculation Example:**

```
2 adults + 1 teen + 1 child
= (2 × 1.0) + (1 × 0.75) + (1 × 0.3)
= 2.0 + 0.75 + 0.3
= 3.05 meal portions
```

**Error Messages:**
- "Guest not found"
- "Event not found"
- "RSVP deadline has passed"
- "Invalid RSVP status"
- "At least 1 adult required when attending"

---

## Analytics

### Get Wedding Analytics

**Stored Procedure:** `get_wedding_analytics`

**What it does:**
- Fetches comprehensive wedding analytics in ONE query:
  - Event statistics
  - Guest statistics (by side, status, role)
  - RSVP statistics
  - Budget summary
  - Progress percentage
- Returns complete JSON

**Frontend Implementation:**

```typescript
// src/components/WeddingAnalytics.tsx
const [analytics, setAnalytics] = useState<any>(null)

useEffect(() => {
  const fetchAnalytics = async () => {
    const { data, error } = await supabase.rpc('get_wedding_analytics', {
      p_wedding_id: weddingId,
    })

    if (error) {
      console.error('Error:', error)
      return
    }

    setAnalytics(data)
  }

  fetchAnalytics()
}, [weddingId])

// Use the data
const eventStats = analytics?.events
const guestStats = analytics?.guests
const rsvpStats = analytics?.rsvps
const budget = analytics?.budget
const progress = analytics?.progress_percentage
```

**Response Format:**

```typescript
{
  wedding_id: string,
  events: {
    total: number
    auto_generated: number
    custom: number
    upcoming: number
  },
  guests: {
    total_invited: number
    by_side: {
      groom: number
      bride: number
      both: number
    }
    by_status: {
      invited: number
      accepted: number
      declined: number
      maybe: number
    }
    vip_count: number
  },
  rsvps: {
    total_responses: number
    completion_rate: number       // Percentage
    total_headcount: number
    by_status: {
      attending: number
      not_attending: number
      maybe: number
    }
  },
  budget: {
    budget_limit: number
    vendor_costs: number
    gift_commissions: number
    total_spent: number
    remaining_budget: number
    budget_used_percentage: number
  },
  progress_percentage: number    // 0-100
}
```

---

## Error Handling

### Standard Error Pattern

```typescript
try {
  const { data: result, error } = await supabase.rpc('procedure_name', {
    // parameters
  })

  // Supabase connection errors
  if (error) {
    console.error('Supabase error:', error)
    toast.error(error.message || 'Database error')
    return null
  }

  // Business logic errors from stored procedure
  const procedureResult = result[0]

  if (!procedureResult.success) {
    toast.error(procedureResult.error_message)
    return null
  }

  // Success
  return procedureResult
} catch (error: any) {
  // Unexpected errors
  console.error('Unexpected error:', error)
  toast.error('An unexpected error occurred')
  return null
}
```

---

## Real-world Examples

### Example 1: Complete Partner Invitation Flow

```typescript
// SingleDashboard.tsx
const InvitePartnerForm = () => {
  const { user } = useAuth()
  const [code, setCode] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (data: { email: string; message?: string }) => {
    setLoading(true)

    try {
      const { data: result, error } = await supabase.rpc('create_partner_invitation', {
        p_sender_id: user.id,
        p_receiver_email: data.email,
        p_message: data.message || null,
      })

      if (error) throw error

      const inviteResult = result[0]

      if (inviteResult.success) {
        setCode(inviteResult.code)
        toast.success('Invitation created!')

        // Show code with share options
        const shareMessage = `Join me on Emowed! Code: ${inviteResult.code}`
        // WhatsApp, email, copy, etc.
      } else {
        toast.error(inviteResult.error_message)
      }
    } catch (error: any) {
      toast.error(error.message || 'Failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    // Form UI
  )
}
```

### Example 2: Accept Invitation Page

```typescript
// AcceptInvitePage.tsx
const AcceptInvitePage = () => {
  const { code } = useParams()
  const { user } = useAuth()
  const navigate = useNavigate()

  const handleAccept = async () => {
    try {
      const { data: result, error } = await supabase.rpc('accept_partner_invitation', {
        p_receiver_id: user.id,
        p_code: code,
      })

      if (error) throw error

      if (result[0].success) {
        toast.success('You are now engaged! 💍')
        navigate('/dashboard')
      } else {
        toast.error(result[0].error_message)
      }
    } catch (error: any) {
      toast.error(error.message)
    }
  }

  return (
    <div>
      <h1>You've been invited!</h1>
      <Button onClick={handleAccept}>Accept Invitation</Button>
    </div>
  )
}
```

### Example 3: Dashboard with Real-time Data

```typescript
// EngagedDashboard.tsx
const EngagedDashboard = () => {
  const { user } = useAuth()
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboardData()

    // Set up real-time subscription for updates
    const subscription = supabase
      .channel('wedding_updates')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'rsvps',
        },
        () => {
          // Refresh dashboard data when RSVPs change
          fetchDashboardData()
        }
      )
      .subscribe()

    return () => {
      subscription.unsubscribe()
    }
  }, [])

  const fetchDashboardData = async () => {
    const { data: result } = await supabase.rpc('get_engaged_dashboard_data', {
      p_user_id: user.id,
    })
    setData(result)
    setLoading(false)
  }

  if (loading) return <Spinner />

  return (
    <div>
      <h1>{data.couple.user1.full_name} & {data.couple.user2.full_name}</h1>

      {data.wedding && (
        <>
          <h2>{data.wedding.name}</h2>
          <p>{data.wedding.days_until} days to go!</p>

          <Stats>
            <Stat label="Events" value={data.wedding_stats.total_events} />
            <Stat label="Guests" value={data.wedding_stats.total_guests} />
            <Stat label="RSVPs" value={data.wedding_stats.guests_responded} />
          </Stats>
        </>
      )}
    </div>
  )
}
```

---

## Benefits of Using Stored Procedures

✅ **Less Frontend Code** - Complex logic in database
✅ **Better Performance** - Single round-trip for multiple operations
✅ **Consistent Validation** - Business rules enforced at DB level
✅ **Automatic Notifications** - Triggers handle notifications
✅ **Transaction Safety** - All-or-nothing operations
✅ **Easier Testing** - Test business logic without frontend
✅ **Reduced Bugs** - Less code = fewer bugs
✅ **Better Security** - RLS policies apply automatically

---

## Need Help?

- Check `SQL_IMPLEMENTATION_COMPLETE.md` for SQL details
- Check `sql/advanced_stored_procedures.sql` for procedure source code
- Check `sql/integration_testing_complete.sql` for test examples

---

**From First Swipe to Forever! 💕**

*Last Updated: November 17, 2025*
