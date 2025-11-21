import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { supabase, Guest, Wedding, User } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import { Input } from '../components/Input'
import { InviteGuestModal } from '../components/InviteGuestModal'
import { GuestListTable } from '../components/GuestListTable'
import toast from 'react-hot-toast'

const GuestsPage = () => {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [guests, setGuests] = useState<Guest[]>([])
  const [filteredGuests, setFilteredGuests] = useState<Guest[]>([])
  const [wedding, setWedding] = useState<Wedding | null>(null)
  const [loading, setLoading] = useState(true)
  const [showInviteModal, setShowInviteModal] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [filterSide, setFilterSide] = useState<'all' | 'groom' | 'bride'>('all')
  const [filterRole, setFilterRole] = useState<string>('all')
  const [filterStatus, setFilterStatus] = useState<string>('all')

  useEffect(() => {
    fetchWeddingAndGuests()
  }, [user])

  useEffect(() => {
    filterGuestList()
  }, [guests, searchQuery, filterSide, filterRole, filterStatus])

  const fetchWeddingAndGuests = async () => {
    if (!user) return

    try {
      // Get couple and wedding
      const { data: coupleData } = await supabase
        .from('couples')
        .select('*')
        .or(`user1_id.eq.${user.id},user2_id.eq.${user.id}`)
        .single()

      if (!coupleData) {
        toast.error('You need to be in a couple to view guests')
        navigate('/dashboard')
        return
      }

      const { data: weddingData } = await supabase
        .from('weddings')
        .select('*')
        .eq('couple_id', coupleData.id)
        .single()

      if (!weddingData) {
        toast.error('Please create a wedding first')
        navigate('/wedding/create')
        return
      }

      setWedding(weddingData)

      // Fetch guests
      const { data: guestsData, error } = await supabase
        .from('guests')
        .select('*')
        .eq('wedding_id', weddingData.id)
        .order('created_at', { ascending: false })

      if (error) throw error
      setGuests(guestsData || [])
    } catch (error: any) {
      toast.error(error.message || 'Failed to load guests')
    } finally {
      setLoading(false)
    }
  }

  const filterGuestList = () => {
    let filtered = guests

    // Search filter
    if (searchQuery) {
      filtered = filtered.filter(
        (guest) =>
          guest.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          guest.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          guest.phone?.includes(searchQuery)
      )
    }

    // Side filter
    if (filterSide !== 'all') {
      filtered = filtered.filter((guest) => guest.side === filterSide)
    }

    // Role filter
    if (filterRole !== 'all') {
      filtered = filtered.filter((guest) => guest.role === filterRole)
    }

    // Status filter
    if (filterStatus !== 'all') {
      filtered = filtered.filter((guest) => guest.status === filterStatus)
    }

    setFilteredGuests(filtered)
  }

  const handleGuestInvited = () => {
    setShowInviteModal(false)
    fetchWeddingAndGuests()
    toast.success('Guest invitation sent successfully!')
  }

  const handleDeleteGuest = async (guestId: string) => {
    if (!confirm('Are you sure you want to remove this guest?')) return

    try {
      const { error } = await supabase.from('guests').delete().eq('id', guestId)
      if (error) throw error

      toast.success('Guest removed successfully')
      fetchWeddingAndGuests()
    } catch (error: any) {
      toast.error(error.message || 'Failed to remove guest')
    }
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-400"></div>
        </div>
      </Layout>
    )
  }

  const groomGuests = guests.filter((g) => g.side === 'groom')
  const brideGuests = guests.filter((g) => g.side === 'bride')
  const acceptedCount = guests.filter((g) => g.status === 'accepted').length
  const pendingCount = guests.filter((g) => g.status === 'pending' || g.status === 'invited').length

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Guest Management</h1>
            <p className="text-gray-600 mt-1">
              Invite and manage your wedding guests
            </p>
          </div>
          <Button onClick={() => setShowInviteModal(true)}>
            + Invite Guest
          </Button>
        </div>

        {/* Stats */}
        <div className="grid md:grid-cols-5 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-primary-400">{guests.length}</p>
                <p className="text-sm text-gray-600 mt-1">Total Guests</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-blue-500">{groomGuests.length}</p>
                <p className="text-sm text-gray-600 mt-1">Groom's Side</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-pink-500">{brideGuests.length}</p>
                <p className="text-sm text-gray-600 mt-1">Bride's Side</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-green-500">{acceptedCount}</p>
                <p className="text-sm text-gray-600 mt-1">Accepted</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-yellow-500">{pendingCount}</p>
                <p className="text-sm text-gray-600 mt-1">Pending</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <Card>
          <CardHeader>
            <CardTitle>Filter Guests</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid md:grid-cols-4 gap-4">
              <Input
                type="text"
                placeholder="Search by name, email, or phone..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />

              <select
                className="input"
                value={filterSide}
                onChange={(e) => setFilterSide(e.target.value as any)}
              >
                <option value="all">All Sides</option>
                <option value="groom">Groom's Side</option>
                <option value="bride">Bride's Side</option>
              </select>

              <select
                className="input"
                value={filterRole}
                onChange={(e) => setFilterRole(e.target.value)}
              >
                <option value="all">All Roles</option>
                <option value="parent">Parent</option>
                <option value="sibling">Sibling</option>
                <option value="uncle">Uncle</option>
                <option value="aunt">Aunt</option>
                <option value="cousin">Cousin</option>
                <option value="grandparent">Grandparent</option>
                <option value="friend">Friend</option>
                <option value="colleague">Colleague</option>
                <option value="other">Other</option>
              </select>

              <select
                className="input"
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <option value="all">All Statuses</option>
                <option value="invited">Invited</option>
                <option value="accepted">Accepted</option>
                <option value="declined">Declined</option>
                <option value="pending">Pending</option>
              </select>
            </div>
          </CardContent>
        </Card>

        {/* Guest List */}
        {filteredGuests.length > 0 ? (
          <GuestListTable
            guests={filteredGuests}
            onDelete={handleDeleteGuest}
            onRefresh={fetchWeddingAndGuests}
          />
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <div className="text-6xl mb-4">👥</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                {guests.length === 0 ? 'No Guests Yet' : 'No Guests Match Your Filters'}
              </h3>
              <p className="text-gray-600 mb-6">
                {guests.length === 0
                  ? 'Start inviting your family and friends to the wedding'
                  : 'Try adjusting your filters to see more guests'}
              </p>
              {guests.length === 0 && (
                <Button onClick={() => setShowInviteModal(true)}>Invite Your First Guest</Button>
              )}
            </CardContent>
          </Card>
        )}

        {/* Invite Modal */}
        {wedding && (
          <InviteGuestModal
            isOpen={showInviteModal}
            onClose={() => setShowInviteModal(false)}
            weddingId={wedding.id}
            onGuestInvited={handleGuestInvited}
          />
        )}
      </div>
    </Layout>
  )
}

export default GuestsPage
