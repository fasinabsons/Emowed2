import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase, VendorProfile, VendorInvitation, VendorQuote, VendorBooking } from '../lib/supabase'
import { toast } from 'react-hot-toast'
import Card from '../components/Card'
import Button from '../components/Button'
import { useAuth } from '../contexts/AuthContext'

export default function VendorDashboardPage() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [vendorProfile, setVendorProfile] = useState<VendorProfile | null>(null)
  const [invitations, setInvitations] = useState<VendorInvitation[]>([])
  const [quotes, setQuotes] = useState<VendorQuote[]>([])
  const [bookings, setBookings] = useState<VendorBooking[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchVendorData()
  }, [])

  const fetchVendorData = async () => {
    try {
      setLoading(true)

      // Fetch vendor profile
      const { data: profileData, error: profileError } = await supabase
        .from('vendor_profiles')
        .select('*')
        .eq('user_id', user?.id)
        .single()

      if (profileError && profileError.code !== 'PGRST116') {
        throw profileError
      }

      setVendorProfile(profileData)

      if (profileData) {
        // Fetch invitations
        const { data: invitationsData } = await supabase
          .from('vendor_invitations')
          .select('*')
          .eq('vendor_id', profileData.id)
          .order('created_at', { ascending: false })

        setInvitations(invitationsData || [])

        // Fetch quotes
        const { data: quotesData } = await supabase
          .from('vendor_quotes')
          .select('*')
          .eq('vendor_id', profileData.id)
          .order('created_at', { ascending: false })

        setQuotes(quotesData || [])

        // Fetch bookings
        const { data: bookingsData } = await supabase
          .from('vendor_bookings')
          .select('*')
          .eq('vendor_id', profileData.id)
          .order('booking_date', { ascending: false })

        setBookings(bookingsData || [])
      }
    } catch (error: any) {
      console.error('Error fetching vendor data:', error)
      toast.error('Failed to load vendor data')
    } finally {
      setLoading(false)
    }
  }

  const handleAcceptInvitation = async (invitationId: string) => {
    try {
      const { error } = await supabase
        .from('vendor_invitations')
        .update({
          status: 'accepted',
          responded_at: new Date().toISOString(),
        })
        .eq('id', invitationId)

      if (error) throw error

      toast.success('Invitation accepted! You can now submit a quote.')
      fetchVendorData()
    } catch (error: any) {
      console.error('Error accepting invitation:', error)
      toast.error('Failed to accept invitation')
    }
  }

  const handleDeclineInvitation = async (invitationId: string) => {
    if (!confirm('Are you sure you want to decline this invitation?')) return

    try {
      const { error } = await supabase
        .from('vendor_invitations')
        .update({
          status: 'rejected',
          responded_at: new Date().toISOString(),
        })
        .eq('id', invitationId)

      if (error) throw error

      toast.success('Invitation declined.')
      fetchVendorData()
    } catch (error: any) {
      console.error('Error declining invitation:', error)
      toast.error('Failed to decline invitation')
    }
  }

  const handleMarkComplete = async (bookingId: string) => {
    if (!confirm('Mark this booking as complete? This will contribute to your verification count.')) return

    try {
      const { error } = await supabase
        .from('vendor_bookings')
        .update({
          booking_status: 'completed',
        })
        .eq('id', bookingId)

      if (error) throw error

      // Increment wedding count for vendor
      if (vendorProfile) {
        await supabase
          .from('vendor_profiles')
          .update({
            wedding_count: vendorProfile.wedding_count + 1,
          })
          .eq('id', vendorProfile.id)
      }

      toast.success('Booking marked as complete!')
      fetchVendorData()
    } catch (error: any) {
      console.error('Error marking booking complete:', error)
      toast.error('Failed to mark booking complete')
    }
  }

  const pendingInvitations = invitations.filter(i => i.status === 'pending')
  const activeQuotes = quotes.filter(q => q.status === 'active')
  const upcomingBookings = bookings.filter(b => b.booking_status === 'confirmed')
  const completedBookings = bookings.filter(b => b.booking_status === 'completed')

  const totalRevenue = bookings
    .filter(b => b.payment_status === 'completed')
    .reduce((sum, b) => sum + b.total_amount, 0)

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-pink-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  if (!vendorProfile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50">
        <div className="max-w-4xl mx-auto px-4 py-16">
          <Card>
            <Card.Content className="p-12 text-center">
              <div className="text-6xl mb-4">🎯</div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                Create Your Vendor Profile
              </h2>
              <p className="text-gray-600 mb-6">
                Set up your vendor profile to start receiving wedding invitations
              </p>
              <Button variant="primary" onClick={() => navigate('/vendor/profile/create')}>
                Create Profile
              </Button>
            </Card.Content>
          </Card>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-4xl font-bold text-gray-900 mb-2">
              Vendor Dashboard
            </h1>
            <p className="text-gray-600">
              {vendorProfile.business_name}
            </p>
          </div>
          <Button variant="outline" onClick={() => navigate(`/vendors/${vendorProfile.id}`)}>
            View Public Profile
          </Button>
        </div>

        {/* Verification Progress */}
        {!vendorProfile.verification_star && (
          <Card className="mb-8 border-2 border-yellow-400">
            <Card.Content className="p-6">
              <div className="flex items-start gap-4">
                <div className="text-4xl">⭐</div>
                <div className="flex-1">
                  <h3 className="text-lg font-bold text-gray-900 mb-2">
                    Get Your Verification Star
                  </h3>
                  <p className="text-gray-600 mb-3">
                    Complete {5 - vendorProfile.wedding_count} more weddings to earn your verification badge
                  </p>
                  <div className="flex items-center gap-2">
                    {[1, 2, 3, 4, 5].map((num) => (
                      <div
                        key={num}
                        className={`w-12 h-12 rounded-full flex items-center justify-center text-lg font-bold ${
                          num <= vendorProfile.wedding_count
                            ? 'bg-yellow-400 text-white'
                            : 'bg-gray-200 text-gray-400'
                        }`}
                      >
                        {num}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </Card.Content>
          </Card>
        )}

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-yellow-600 mb-1">
                {pendingInvitations.length}
              </div>
              <div className="text-sm text-gray-600">Pending Invitations</div>
            </Card.Content>
          </Card>

          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-blue-600 mb-1">
                {activeQuotes.length}
              </div>
              <div className="text-sm text-gray-600">Active Quotes</div>
            </Card.Content>
          </Card>

          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-green-600 mb-1">
                {upcomingBookings.length}
              </div>
              <div className="text-sm text-gray-600">Upcoming Bookings</div>
            </Card.Content>
          </Card>

          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-pink-600 mb-1">
                ₹{(totalRevenue / 1000).toFixed(0)}K
              </div>
              <div className="text-sm text-gray-600">Total Revenue</div>
            </Card.Content>
          </Card>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-6">
            {/* Pending Invitations */}
            <Card>
              <Card.Header>
                <Card.Title>Pending Invitations ({pendingInvitations.length})</Card.Title>
              </Card.Header>
              <Card.Content>
                {pendingInvitations.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">
                    No pending invitations
                  </p>
                ) : (
                  <div className="space-y-4">
                    {pendingInvitations.map(invitation => (
                      <div key={invitation.id} className="p-4 border rounded-lg hover:shadow-md transition-shadow">
                        <div className="flex items-start justify-between">
                          <div>
                            <h4 className="font-semibold text-gray-900 mb-1">
                              Wedding Invitation
                            </h4>
                            <p className="text-sm text-gray-600 mb-2 capitalize">
                              {invitation.category.replace('_', ' ')}
                            </p>
                            {invitation.invitation_message && (
                              <p className="text-sm text-gray-700 mb-3 italic">
                                "{invitation.invitation_message}"
                              </p>
                            )}
                            <p className="text-xs text-gray-500">
                              Sent: {new Date(invitation.sent_at).toLocaleDateString('en-IN')}
                            </p>
                          </div>
                          <div className="flex flex-col gap-2">
                            <Button
                              variant="primary"
                              size="sm"
                              onClick={() => handleAcceptInvitation(invitation.id)}
                            >
                              Accept
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleDeclineInvitation(invitation.id)}
                            >
                              Decline
                            </Button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </Card.Content>
            </Card>

            {/* Active Quotes */}
            <Card>
              <Card.Header>
                <Card.Title>Active Quotes ({activeQuotes.length})</Card.Title>
              </Card.Header>
              <Card.Content>
                {activeQuotes.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">
                    No active quotes
                  </p>
                ) : (
                  <div className="space-y-4">
                    {activeQuotes.map(quote => (
                      <div key={quote.id} className="p-4 border rounded-lg">
                        <div className="flex items-start justify-between mb-2">
                          <div>
                            <h4 className="font-semibold text-gray-900">{quote.package_name}</h4>
                            <p className="text-sm text-gray-600">{quote.description}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-xl font-bold text-pink-600">
                              ₹{quote.total_price.toLocaleString('en-IN')}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center justify-between text-xs text-gray-500">
                          <span>
                            Valid until: {new Date(quote.valid_until || quote.created_at).toLocaleDateString('en-IN')}
                          </span>
                          <Button variant="outline" size="sm">
                            View Details
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </Card.Content>
            </Card>

            {/* Upcoming Bookings */}
            <Card>
              <Card.Header>
                <Card.Title>Upcoming Bookings ({upcomingBookings.length})</Card.Title>
              </Card.Header>
              <Card.Content>
                {upcomingBookings.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">
                    No upcoming bookings
                  </p>
                ) : (
                  <div className="space-y-4">
                    {upcomingBookings.map(booking => (
                      <div key={booking.id} className="p-4 border rounded-lg">
                        <div className="flex items-start justify-between mb-2">
                          <div>
                            <h4 className="font-semibold text-gray-900 capitalize">
                              {booking.category.replace('_', ' ')}
                            </h4>
                            <p className="text-sm text-gray-600">
                              {new Date(booking.booking_date).toLocaleDateString('en-IN', {
                                year: 'numeric',
                                month: 'long',
                                day: 'numeric'
                              })}
                            </p>
                            {booking.start_time && (
                              <p className="text-sm text-gray-600">
                                {booking.start_time} - {booking.end_time}
                              </p>
                            )}
                          </div>
                          <div className="text-right">
                            <p className="text-lg font-bold text-green-600">
                              ₹{booking.total_amount.toLocaleString('en-IN')}
                            </p>
                            <p className="text-xs text-gray-600">
                              Paid: ₹{booking.advance_paid.toLocaleString('en-IN')}
                            </p>
                          </div>
                        </div>
                        <div className="flex gap-2 mt-3">
                          <Button
                            variant="outline"
                            size="sm"
                            className="flex-1"
                            onClick={() => navigate(`/vendors/bookings/${booking.id}`)}
                          >
                            View Details
                          </Button>
                          <Button
                            variant="primary"
                            size="sm"
                            className="flex-1"
                            onClick={() => handleMarkComplete(booking.id)}
                          >
                            Mark Complete
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </Card.Content>
            </Card>
          </div>

          {/* Right Sidebar */}
          <div className="space-y-6">
            {/* Profile Summary */}
            <Card>
              <Card.Header>
                <Card.Title>Profile Summary</Card.Title>
              </Card.Header>
              <Card.Content className="space-y-3">
                <div>
                  <p className="text-sm text-gray-600 mb-1">Category</p>
                  <p className="font-semibold capitalize">{vendorProfile.category.replace('_', ' ')}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 mb-1">Rating</p>
                  <div className="flex items-center gap-2">
                    <span className="text-yellow-400">★</span>
                    <span className="font-semibold">{vendorProfile.rating.toFixed(1)}</span>
                    <span className="text-gray-600 text-sm">({vendorProfile.total_reviews} reviews)</span>
                  </div>
                </div>
                <div>
                  <p className="text-sm text-gray-600 mb-1">Weddings Completed</p>
                  <p className="font-semibold">{vendorProfile.wedding_count}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 mb-1">Subscription</p>
                  <p className="font-semibold capitalize">{vendorProfile.subscription_type}</p>
                </div>
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => navigate('/vendor/profile/edit')}
                >
                  Edit Profile
                </Button>
              </Card.Content>
            </Card>

            {/* Quick Stats */}
            <Card>
              <Card.Header>
                <Card.Title>This Month</Card.Title>
              </Card.Header>
              <Card.Content className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">New Invitations</span>
                  <span className="font-bold text-pink-600">{pendingInvitations.length}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Quotes Sent</span>
                  <span className="font-bold text-blue-600">{activeQuotes.length}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Bookings</span>
                  <span className="font-bold text-green-600">{upcomingBookings.length}</span>
                </div>
                <div className="flex items-center justify-between border-t pt-3">
                  <span className="text-gray-600 font-semibold">Revenue</span>
                  <span className="font-bold text-pink-600">
                    ₹{(totalRevenue / 1000).toFixed(0)}K
                  </span>
                </div>
              </Card.Content>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
}
