import { useEffect, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import toast from 'react-hot-toast'
import { useAuth } from '../contexts/AuthContext'
import { supabase, PartnerInvitation, User } from '../lib/supabase'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'

const AcceptInvitePage = () => {
  const { code } = useParams<{ code: string }>()
  const navigate = useNavigate()
  const { user, supabaseUser } = useAuth()
  const [invitation, setInvitation] = useState<PartnerInvitation | null>(null)
  const [sender, setSender] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [accepting, setAccepting] = useState(false)

  useEffect(() => {
    const fetchInvitation = async () => {
      if (!code) return

      try {
        // Fetch invitation
        const { data: inviteData, error: inviteError } = await supabase
          .from('partner_invitations')
          .select('*')
          .eq('code', code.toUpperCase())
          .single()

        if (inviteError || !inviteData) {
          toast.error('Invalid invitation code')
          navigate('/')
          return
        }

        setInvitation(inviteData)

        // Fetch sender info
        const { data: senderData } = await supabase
          .from('users')
          .select('*')
          .eq('id', inviteData.sender_id)
          .single()

        setSender(senderData)
        setLoading(false)

        // Check if expired
        if (new Date(inviteData.expires_at) < new Date()) {
          toast.error('This invitation has expired')
        }

        // Check if already accepted/rejected
        if (inviteData.status !== 'pending') {
          toast.error(`This invitation has already been ${inviteData.status}`)
        }
      } catch (error) {
        toast.error('Error loading invitation')
        navigate('/')
      }
    }

    fetchInvitation()
  }, [code, navigate])

  const handleAccept = async () => {
    if (!invitation || !user || !supabaseUser) {
      toast.error('Please login to accept this invitation')
      navigate(`/login?redirect=/invite/accept/${code}`)
      return
    }

    if (user.email !== invitation.receiver_email) {
      toast.error('This invitation is not for your email address')
      return
    }

    setAccepting(true)
    try {
      // Update invitation status
      const { error: updateError } = await supabase
        .from('partner_invitations')
        .update({
          status: 'accepted',
          responded_at: new Date().toISOString(),
        })
        .eq('id', invitation.id)

      if (updateError) throw updateError

      // Create couple
      const { error: coupleError } = await supabase.from('couples').insert({
        user1_id: invitation.sender_id,
        user2_id: user.id,
        status: 'engaged',
        engaged_date: new Date().toISOString().split('T')[0],
      })

      if (coupleError) throw coupleError

      // Create notification for sender
      await supabase.from('notifications').insert({
        user_id: invitation.sender_id,
        type: 'acceptance',
        title: 'Partner Invitation Accepted!',
        message: `${user.full_name} has accepted your invitation. You can now start planning together!`,
        action_url: '/dashboard',
      })

      toast.success('Invitation accepted! Welcome to your journey together!')
      navigate('/dashboard')
    } catch (error: any) {
      toast.error(error.message || 'Failed to accept invitation')
    } finally {
      setAccepting(false)
    }
  }

  const handleReject = async () => {
    if (!invitation || !user) {
      toast.error('Please login to reject this invitation')
      return
    }

    try {
      // Update invitation status
      const { error } = await supabase
        .from('partner_invitations')
        .update({
          status: 'rejected',
          responded_at: new Date().toISOString(),
          rejection_count: invitation.rejection_count + 1,
        })
        .eq('id', invitation.id)

      if (error) throw error

      // Create notification for sender
      await supabase.from('notifications').insert({
        user_id: invitation.sender_id,
        type: 'rejection',
        title: 'Invitation Declined',
        message: `Your invitation was declined.`,
        action_url: '/dashboard',
      })

      toast.success('Invitation rejected')
      navigate('/dashboard')
    } catch (error: any) {
      toast.error(error.message || 'Failed to reject invitation')
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-400"></div>
      </div>
    )
  }

  const isExpired = invitation && new Date(invitation.expires_at) < new Date()
  const isProcessed = invitation && invitation.status !== 'pending'

  return (
    <div className="min-h-screen bg-gradient-to-b from-pink-50 to-white flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link to="/" className="text-3xl font-bold text-gradient">
            Emowed
          </Link>
        </div>

        <Card>
          <CardHeader>
            <div className="text-center mb-4">
              <div className="w-20 h-20 mx-auto rounded-full bg-gradient-to-br from-primary-400 to-secondary-400 flex items-center justify-center text-white font-bold text-3xl mb-4">
                {sender?.full_name.charAt(0)}
              </div>
              <CardTitle>Partner Invitation</CardTitle>
              <CardDescription>
                {sender?.full_name} has invited you to start your journey together
              </CardDescription>
            </div>
          </CardHeader>

          <CardContent className="space-y-6">
            {invitation?.message && (
              <div className="bg-gray-50 rounded-lg p-4">
                <p className="text-sm text-gray-600 italic">"{invitation.message}"</p>
              </div>
            )}

            <div className="space-y-2 text-sm text-gray-600">
              <div className="flex justify-between">
                <span>Invitation Code:</span>
                <code className="font-bold text-primary-400">{code}</code>
              </div>
              <div className="flex justify-between">
                <span>From:</span>
                <span className="font-medium">{sender?.full_name}</span>
              </div>
              <div className="flex justify-between">
                <span>Expires:</span>
                <span className="font-medium">
                  {invitation && new Date(invitation.expires_at).toLocaleDateString()}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Status:</span>
                <span
                  className={`font-medium capitalize ${
                    isExpired ? 'text-red-600' : isProcessed ? 'text-gray-600' : 'text-green-600'
                  }`}
                >
                  {isExpired ? 'Expired' : invitation?.status}
                </span>
              </div>
            </div>

            {!supabaseUser ? (
              <div className="space-y-3">
                <p className="text-center text-sm text-gray-600">
                  Please login or create an account to respond to this invitation
                </p>
                <Link to="/login" className="block">
                  <Button className="w-full">Login</Button>
                </Link>
                <Link to="/signup" className="block">
                  <Button variant="outline" className="w-full">
                    Sign Up
                  </Button>
                </Link>
              </div>
            ) : isExpired || isProcessed ? (
              <div className="text-center py-4">
                <p className="text-gray-600 mb-4">
                  {isExpired
                    ? 'This invitation has expired'
                    : `This invitation has already been ${invitation?.status}`}
                </p>
                <Link to="/dashboard">
                  <Button variant="secondary">Go to Dashboard</Button>
                </Link>
              </div>
            ) : (
              <div className="flex gap-3">
                <Button onClick={handleAccept} loading={accepting} className="flex-1">
                  Accept
                </Button>
                <Button variant="secondary" onClick={handleReject} className="flex-1">
                  Decline
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default AcceptInvitePage
