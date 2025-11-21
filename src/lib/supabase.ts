import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
})

// Database types
export interface User {
  id: string
  email: string
  phone?: string
  full_name: string
  age: number
  relationship_status: 'single' | 'committed' | 'engaged' | 'married' | 'divorced' | 'widowed'
  age_verified: boolean
  can_invite: boolean
  last_invite_at?: string
  created_at: string
  updated_at: string
}

export interface PartnerInvitation {
  id: string
  code: string
  sender_id: string
  receiver_email: string
  status: 'pending' | 'accepted' | 'rejected' | 'expired'
  rejection_count: number
  message?: string
  created_at: string
  expires_at: string
  responded_at?: string
}

export interface Couple {
  id: string
  user1_id: string
  user2_id: string
  status: 'engaged' | 'married' | 'separated' | 'divorced'
  engaged_date: string
  married_date?: string
  separated_date?: string
  created_at: string
  updated_at: string
}

export interface Wedding {
  id: string
  couple_id: string
  name: string
  date: string
  venue: string
  city: string
  mode: 'combined' | 'separate'
  budget_limit?: number
  guest_limit: number
  status: 'planning' | 'confirmed' | 'completed' | 'cancelled'
  created_at: string
  updated_at: string
}

export interface Notification {
  id: string
  user_id: string
  type: 'invitation' | 'rejection' | 'acceptance' | 'wedding_created' | 'wedding_cancelled'
  title: string
  message: string
  read: boolean
  action_url?: string
  created_at: string
}

export interface Event {
  id: string
  wedding_id: string
  name: string
  description?: string
  event_type: 'engagement' | 'save_the_date' | 'haldi' | 'mehendi' | 'sangeet' | 'wedding' | 'reception' | 'custom'
  date: string
  start_time?: string
  end_time?: string
  venue: string
  city: string
  dress_code?: string
  rsvp_deadline?: string
  auto_generated: boolean
  created_by?: string
  created_at: string
  updated_at: string
}

export interface Guest {
  id: string
  wedding_id: string
  user_id?: string
  email?: string
  full_name: string
  phone?: string
  side: 'groom' | 'bride' | 'both'
  role: 'groom' | 'bride' | 'parent' | 'sibling' | 'uncle' | 'aunt' | 'cousin' | 'grandparent' | 'friend' | 'colleague' | 'other'
  invited_by: string
  can_invite_others: boolean
  plus_one_allowed: boolean
  plus_one_name?: string
  is_vip: boolean
  under_18: boolean
  age?: number
  dietary_preferences?: string[]
  special_requirements?: string
  status: 'invited' | 'accepted' | 'declined' | 'maybe' | 'pending'
  invitation_sent_at?: string
  responded_at?: string
  created_at: string
  updated_at: string
}

export interface GuestInvitation {
  id: string
  wedding_id: string
  sender_id: string
  receiver_email: string
  receiver_name: string
  role: string
  side: 'groom' | 'bride'
  can_invite_others: boolean
  personal_message?: string
  status: 'pending' | 'accepted' | 'rejected' | 'expired'
  created_at: string
  expires_at: string
  responded_at?: string
}

export interface RSVP {
  id: string
  event_id: string
  guest_id: string
  wedding_id: string
  status: 'attending' | 'not_attending' | 'maybe' | 'pending'
  adults_count: number
  teens_count: number
  children_count: number
  calculated_headcount: number
  dietary_preferences?: string[]
  special_requirements?: string
  rsvp_notes?: string
  submitted_at?: string
  created_at: string
  updated_at: string
}

export interface HeadcountSnapshot {
  id: string
  event_id: string
  wedding_id: string
  side?: 'groom' | 'bride' | 'both'
  total_invited: number
  total_attending: number
  total_declined: number
  total_maybe: number
  total_pending: number
  adults_count: number
  teens_count: number
  children_count: number
  calculated_headcount: number
  vegetarian_count: number
  vegan_count: number
  halal_count: number
  snapshot_date: string
  created_at: string
}

export interface FamilyTree {
  id: string
  wedding_id: string
  guest_id: string
  parent_guest_id?: string
  relationship?: string
  depth: number
  created_at: string
}

// ============================================
// PHASE 3: VENDOR SYSTEM TYPES
// ============================================

export interface VendorProfile {
  id: string
  user_id: string
  business_name: string
  category: 'photographer' | 'videographer' | 'caterer' | 'decorator' | 'makeup_artist' | 'mehendi_artist' | 'dj' | 'band' | 'venue' | 'florist' | 'priest' | 'travel' | 'custom'
  custom_category?: string
  description?: string
  services_offered?: string[]
  base_price?: number
  price_range_min?: number
  price_range_max?: number
  city: string
  service_areas?: string[]
  phone: string
  website?: string
  portfolio_urls?: string[]
  profile_image_url?: string
  verified: boolean
  verification_star: boolean
  wedding_count: number
  rating: number
  total_reviews: number
  subscription_type: 'free' | 'paid'
  subscription_expires_at?: string
  featured: boolean
  blocked: boolean
  created_at: string
  updated_at: string
}

export interface VendorInvitation {
  id: string
  wedding_id: string
  vendor_id: string
  invited_by: string
  category: string
  status: 'pending' | 'accepted' | 'rejected' | 'expired'
  invitation_message?: string
  sent_at: string
  responded_at?: string
  expires_at: string
  created_at: string
}

export interface VendorQuote {
  id: string
  vendor_invitation_id: string
  vendor_id: string
  wedding_id: string
  package_name: string
  description?: string
  items_included?: string[]
  base_price: number
  additional_charges?: Record<string, number>
  total_price: number
  payment_terms?: string
  validity_days: number
  valid_until?: string
  status: 'active' | 'expired' | 'withdrawn' | 'accepted'
  created_at: string
  updated_at: string
}

export interface VendorVote {
  id: string
  wedding_id: string
  vendor_id: string
  voter_id: string
  category: string
  vote_type: 'approve' | 'reject' | 'rank'
  rank?: number
  comments?: string
  price_rating?: number
  quality_rating?: number
  created_at: string
  updated_at: string
}

export interface VendorBooking {
  id: string
  wedding_id: string
  vendor_id: string
  quote_id?: string
  category: string
  booking_date: string
  event_dates: string[]
  start_time?: string
  end_time?: string
  total_amount: number
  advance_paid: number
  balance_due: number
  commission_rate?: number
  commission_amount?: number
  payment_status: 'pending' | 'advance_paid' | 'partial' | 'completed'
  booking_status: 'confirmed' | 'completed' | 'cancelled'
  contract_url?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface VendorAvailability {
  id: string
  vendor_id: string
  date: string
  start_time?: string
  end_time?: string
  status: 'available' | 'booked' | 'blocked'
  booking_id?: string
  notes?: string
  created_at: string
}

export interface VendorVerification {
  id: string
  vendor_id: string
  wedding_id: string
  verified_by?: string
  verification_type: 'wedding_completion' | 'manual'
  verification_date: string
  created_at: string
}

export interface VendorReview {
  id: string
  vendor_id: string
  wedding_id: string
  reviewer_id: string
  rating: number
  review_text?: string
  pros?: string[]
  cons?: string[]
  would_recommend?: boolean
  response_from_vendor?: string
  images?: string[]
  verified_booking: boolean
  helpful_count: number
  created_at: string
  updated_at: string
}

export interface VendorTimeConflict {
  id: string
  vendor_id: string
  conflict_date: string
  existing_booking_id?: string
  requested_wedding_id?: string
  conflict_resolved: boolean
  resolution_notes?: string
  created_at: string
}

export interface VendorSearchRanking {
  id: string
  user_id: string
  business_name: string
  category: string
  city: string
  verified: boolean
  verification_star: boolean
  rating: number
  wedding_count: number
  ranking_score: number
}

export interface VendorVotingSummary {
  wedding_id: string
  category: string
  vendor_id: string
  total_votes: number
  avg_rank: number
  avg_price_rating: number
  avg_quality_rating: number
  first_choice_votes: number
  second_choice_votes: number
  third_choice_votes: number
}
