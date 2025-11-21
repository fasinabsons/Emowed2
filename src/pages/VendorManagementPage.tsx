import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase, VendorInvitation, VendorQuote, VendorProfile } from '../lib/supabase'
import { toast } from 'react-hot-toast'
import Card from '../components/Card'
import Button from '../components/Button'
import Input from '../components/Input'
import Modal from '../components/Modal'
import { useAuth } from '../contexts/AuthContext'

const vendorCategories = [
  'photographer', 'videographer', 'caterer', 'decorator',
  'makeup_artist', 'mehendi_artist', 'dj', 'band', 'venue',
  'florist', 'priest', 'travel'
]

export default function VendorManagementPage() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [wedding, setWedding] = useState<any>(null)
  const [invitations, setInvitations] = useState<VendorInvitation[]>([])
  const [quotes, setQuotes] = useState<VendorQuote[]>([])
  const [vendors, setVendors] = useState<Record<string, VendorProfile>>({})
  const [loading, setLoading] = useState(true)
  const [selectedCategory, setSelectedCategory] = useState<string>('all')
  const [showInviteModal, setShowInviteModal] = useState(false)
  const [inviteEmail, setInviteEmail] = useState('')
  const [inviteCategory, setInviteCategory] = useState('')
  const [inviteMessage, setInviteMessage] = useState('')

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)

      // Fetch wedding
      const { data: coupleData } = await supabase
        .from('couples')
        .select('id')
        .or(`user1_id.eq.${user?.id},user2_id.eq.${user?.id}`)
        .single()

      if (coupleData) {
        const { data: weddingData } = await supabase
          .from('weddings')
          .select('*')
          .eq('couple_id', coupleData.id)
          .single()

        setWedding(weddingData)

        if (weddingData) {
          // Fetch invitations
          const { data: invitationsData } = await supabase
            .from('vendor_invitations')
            .select('*')
            .eq('wedding_id', weddingData.id)

          setInvitations(invitationsData || [])

          // Fetch quotes
          const { data: quotesData } = await supabase
            .from('vendor_quotes')
            .select('*')
            .eq('wedding_id', weddingData.id)

          setQuotes(quotesData || [])

          // Fetch vendor details
          const vendorIds = [...new Set(invitationsData?.map(i => i.vendor_id) || [])]
          if (vendorIds.length > 0) {
            const { data: vendorsData } = await supabase
              .from('vendor_profiles')
              .select('*')
              .in('id', vendorIds)

            const vendorsMap: Record<string, VendorProfile> = {}
            vendorsData?.forEach(v => {
              vendorsMap[v.id] = v
            })
            setVendors(vendorsMap)
          }
        }
      }
    } catch (error: any) {
      console.error('Error fetching data:', error)
      toast.error('Failed to load vendor data')
    } finally {
      setLoading(false)
    }
  }

  const handleInviteVendor = async () => {
    if (!inviteEmail || !inviteCategory || !wedding) {
      toast.error('Please fill in all required fields')
      return
    }

    try {
      // Step 1: Find vendor by email
      const { data: vendorUser, error: userError } = await supabase
        .from('users')
        .select('id')
        .eq('email', inviteEmail)
        .single()

      if (userError || !vendorUser) {
        toast.error('Vendor not found. They need to create an account first.')
        return
      }

      // Step 2: Check if they have a vendor profile
      const { data: vendorProfile, error: profileError } = await supabase
        .from('vendor_profiles')
        .select('id')
        .eq('user_id', vendorUser.id)
        .single()

      if (profileError || !vendorProfile) {
        toast.error('This user is not registered as a vendor.')
        return
      }

      // Step 3: Check if already invited
      const { data: existingInvitation } = await supabase
        .from('vendor_invitations')
        .select('id')
        .eq('wedding_id', wedding.id)
        .eq('vendor_id', vendorProfile.id)
        .eq('category', inviteCategory)
        .single()

      if (existingInvitation) {
        toast.error('This vendor has already been invited for this category.')
        return
      }

      // Step 4: Create vendor invitation
      const expiresAt = new Date()
      expiresAt.setDate(expiresAt.getDate() + 30) // 30 days expiry

      const { error: inviteError } = await supabase
        .from('vendor_invitations')
        .insert({
          wedding_id: wedding.id,
          vendor_id: vendorProfile.id,
          invited_by: user?.id,
          category: inviteCategory,
          status: 'pending',
          invitation_message: inviteMessage || null,
          sent_at: new Date().toISOString(),
          expires_at: expiresAt.toISOString(),
        })

      if (inviteError) throw inviteError

      // Step 5: Create notification for vendor
      await supabase.from('notifications').insert({
        user_id: vendorUser.id,
        type: 'wedding_created',
        title: 'Wedding Vendor Invitation',
        message: `You've been invited to provide ${inviteCategory.replace('_', ' ')} services for ${wedding.name}`,
        read: false,
        action_url: `/vendor/dashboard`,
      })

      toast.success('Vendor invitation sent successfully!')
      setShowInviteModal(false)
      setInviteEmail('')
      setInviteCategory('')
      setInviteMessage('')

      // Refresh data
      fetchData()
    } catch (error: any) {
      console.error('Error inviting vendor:', error)
      toast.error(error.message || 'Failed to send invitation')
    }
  }

  const filteredInvitations = selectedCategory === 'all'
    ? invitations
    : invitations.filter(inv => inv.category === selectedCategory)

  const getQuotesForVendor = (vendorId: string) => {
    return quotes.filter(q => q.vendor_id === vendorId)
  }

  const groupedByCategory = vendorCategories.reduce((acc, category) => {
    acc[category] = invitations.filter(inv => inv.category === category)
    return acc
  }, {} as Record<string, VendorInvitation[]>)

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-pink-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading vendors...</p>
        </div>
      </div>
    )
  }

  if (!wedding) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50">
        <div className="max-w-4xl mx-auto px-4 py-16">
          <Card>
            <Card.Content className="p-12 text-center">
              <div className="text-6xl mb-4">💒</div>
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                Create Your Wedding First
              </h2>
              <p className="text-gray-600 mb-6">
                You need to create a wedding before you can manage vendors
              </p>
              <Button variant="primary" onClick={() => navigate('/wedding/create')}>
                Create Wedding
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
              Vendor Management
            </h1>
            <p className="text-gray-600">
              {wedding.name} • {new Date(wedding.date).toLocaleDateString('en-IN', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}
            </p>
          </div>
          <div className="flex gap-3">
            <Button variant="outline" onClick={() => navigate('/vendors')}>
              Browse Vendors
            </Button>
            <Button variant="primary" onClick={() => setShowInviteModal(true)}>
              + Invite Vendor
            </Button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-pink-600 mb-1">
                {invitations.length}
              </div>
              <div className="text-sm text-gray-600">Total Invitations</div>
            </Card.Content>
          </Card>
          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-green-600 mb-1">
                {invitations.filter(i => i.status === 'accepted').length}
              </div>
              <div className="text-sm text-gray-600">Accepted</div>
            </Card.Content>
          </Card>
          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-blue-600 mb-1">
                {quotes.length}
              </div>
              <div className="text-sm text-gray-600">Quotes Received</div>
            </Card.Content>
          </Card>
          <Card>
            <Card.Content className="p-6">
              <div className="text-3xl font-bold text-purple-600 mb-1">
                {invitations.filter(i => i.status === 'pending').length}
              </div>
              <div className="text-sm text-gray-600">Pending</div>
            </Card.Content>
          </Card>
        </div>

        {/* Category Tabs */}
        <div className="mb-6 flex gap-2 overflow-x-auto pb-2">
          <button
            onClick={() => setSelectedCategory('all')}
            className={`px-4 py-2 rounded-lg font-medium whitespace-nowrap transition-colors ${
              selectedCategory === 'all'
                ? 'bg-pink-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            All ({invitations.length})
          </button>
          {vendorCategories.map(category => {
            const count = groupedByCategory[category]?.length || 0
            return (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-lg font-medium whitespace-nowrap transition-colors capitalize ${
                  selectedCategory === category
                    ? 'bg-pink-600 text-white'
                    : 'bg-white text-gray-700 hover:bg-gray-100'
                }`}
              >
                {category.replace('_', ' ')} ({count})
              </button>
            )
          })}
        </div>

        {/* Vendor Invitations List */}
        {filteredInvitations.length === 0 ? (
          <Card>
            <Card.Content className="p-12 text-center">
              <div className="text-6xl mb-4">🎯</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                No vendors invited yet
              </h3>
              <p className="text-gray-600 mb-4">
                Start by browsing vendors or inviting them directly
              </p>
              <div className="flex gap-3 justify-center">
                <Button variant="outline" onClick={() => navigate('/vendors')}>
                  Browse Vendors
                </Button>
                <Button variant="primary" onClick={() => setShowInviteModal(true)}>
                  Invite Vendor
                </Button>
              </div>
            </Card.Content>
          </Card>
        ) : (
          <div className="space-y-4">
            {filteredInvitations.map(invitation => {
              const vendor = vendors[invitation.vendor_id]
              const vendorQuotes = getQuotesForVendor(invitation.vendor_id)

              return (
                <Card key={invitation.id} className="hover:shadow-lg transition-shadow">
                  <Card.Content className="p-6">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="text-xl font-bold text-gray-900">
                            {vendor?.business_name || 'Loading...'}
                          </h3>
                          <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                            invitation.status === 'accepted' ? 'bg-green-100 text-green-700' :
                            invitation.status === 'rejected' ? 'bg-red-100 text-red-700' :
                            invitation.status === 'expired' ? 'bg-gray-100 text-gray-700' :
                            'bg-yellow-100 text-yellow-700'
                          }`}>
                            {invitation.status.charAt(0).toUpperCase() + invitation.status.slice(1)}
                          </span>
                          {vendor?.verification_star && (
                            <span className="text-yellow-400">⭐</span>
                          )}
                        </div>
                        <p className="text-gray-600 mb-3 capitalize">
                          {invitation.category.replace('_', ' ')} • {vendor?.city || '-'}
                        </p>

                        {vendor && (
                          <div className="flex items-center gap-4 mb-3">
                            <div className="flex items-center">
                              {[1, 2, 3, 4, 5].map((star) => (
                                <span key={star} className={star <= vendor.rating ? 'text-yellow-400' : 'text-gray-300'}>
                                  ★
                                </span>
                              ))}
                            </div>
                            <span className="text-sm text-gray-600">
                              {vendor.rating.toFixed(1)} ({vendor.total_reviews} reviews)
                            </span>
                          </div>
                        )}

                        {vendorQuotes.length > 0 && (
                          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
                            <h4 className="font-semibold text-blue-900 mb-2">
                              {vendorQuotes.length} Quote{vendorQuotes.length > 1 ? 's' : ''} Received
                            </h4>
                            <div className="space-y-2">
                              {vendorQuotes.map(quote => (
                                <div key={quote.id} className="flex items-center justify-between">
                                  <span className="text-sm text-gray-700">{quote.package_name}</span>
                                  <span className="font-semibold text-blue-600">
                                    ₹{quote.total_price.toLocaleString('en-IN')}
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>

                      <div className="flex flex-col gap-2">
                        {vendor && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => navigate(`/vendors/${vendor.id}`)}
                          >
                            View Profile
                          </Button>
                        )}
                        {invitation.status === 'accepted' && vendorQuotes.length > 0 && (
                          <Button variant="primary" size="sm">
                            Start Voting
                          </Button>
                        )}
                      </div>
                    </div>
                  </Card.Content>
                </Card>
              )
            })}
          </div>
        )}
      </div>

      {/* Invite Modal */}
      <Modal
        isOpen={showInviteModal}
        onClose={() => setShowInviteModal(false)}
        title="Invite Vendor to Wedding"
      >
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Vendor Email *
            </label>
            <Input
              type="email"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
              placeholder="vendor@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Category *
            </label>
            <select
              value={inviteCategory}
              onChange={(e) => setInviteCategory(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
            >
              <option value="">Select category</option>
              {vendorCategories.map(cat => (
                <option key={cat} value={cat} className="capitalize">
                  {cat.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Personal Message (Optional)
            </label>
            <textarea
              value={inviteMessage}
              onChange={(e) => setInviteMessage(e.target.value)}
              placeholder="Add a personal note to the vendor..."
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
            />
          </div>

          <div className="flex gap-3">
            <Button
              variant="outline"
              onClick={() => setShowInviteModal(false)}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={handleInviteVendor}
              className="flex-1"
            >
              Send Invitation
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
