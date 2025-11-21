import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from './Card'
import { Button } from './Button'
import { Input } from './Input'
import { Modal } from './Modal'

const inviteSchema = z.object({
  receiverEmail: z.string().email('Invalid email address'),
  message: z.string().optional(),
})

type InviteFormData = z.infer<typeof inviteSchema>

export const SingleDashboard = () => {
  const { user } = useAuth()
  const [showInviteModal, setShowInviteModal] = useState(false)
  const [generatedCode, setGeneratedCode] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<InviteFormData>({
    resolver: zodResolver(inviteSchema),
  })

  const generateInviteCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    let code = ''
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return code
  }

  const onSubmit = async (data: InviteFormData) => {
    if (!user) return

    setLoading(true)
    try {
      // Use the stored procedure for complete invitation workflow
      const { data: result, error } = await supabase.rpc('create_partner_invitation', {
        p_sender_id: user.id,
        p_receiver_email: data.receiverEmail,
        p_message: data.message || null,
      })

      if (error) throw error

      // Check if successful
      if (result && result.length > 0) {
        const invitationResult = result[0]

        if (invitationResult.success) {
          setGeneratedCode(invitationResult.code)
          toast.success('Invitation created successfully!')
          reset()
        } else {
          toast.error(invitationResult.error_message || 'Failed to create invitation')
        }
      }
    } catch (error: any) {
      toast.error(error.message || 'Failed to create invitation')
    } finally {
      setLoading(false)
    }
  }

  const copyCode = () => {
    if (generatedCode) {
      navigator.clipboard.writeText(generatedCode)
      toast.success('Code copied to clipboard!')
    }
  }

  const shareViaWhatsApp = () => {
    if (generatedCode) {
      const message = `Hey! I'd like to connect with you on Emowed to plan our journey together. Use code: ${generatedCode}\n\nAccept here: ${window.location.origin}/invite/accept/${generatedCode}`
      window.open(`https://wa.me/?text=${encodeURIComponent(message)}`, '_blank')
    }
  }

  return (
    <div className="space-y-6">
      {/* Welcome Card */}
      <Card>
        <CardHeader>
          <CardTitle>Welcome back, {user?.full_name}!</CardTitle>
          <CardDescription>
            You're currently single. Start your journey by inviting your partner to join you on Emowed.
          </CardDescription>
        </CardHeader>
      </Card>

      {/* Partner Invitation Card */}
      <Card>
        <CardHeader>
          <CardTitle>Connect with Your Partner</CardTitle>
          <CardDescription>
            Invite your partner to start planning together. They'll receive a unique code to accept your invitation.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={() => setShowInviteModal(true)}>
            Generate Invitation Code
          </Button>

          {generatedCode && (
            <div className="mt-6 p-4 bg-primary-50 rounded-lg border border-primary-200">
              <p className="text-sm text-gray-700 mb-2">Your invitation code:</p>
              <div className="flex items-center gap-3">
                <code className="text-2xl font-bold text-primary-400 flex-1">
                  {generatedCode}
                </code>
                <Button size="sm" variant="outline" onClick={copyCode}>
                  Copy
                </Button>
                <Button size="sm" onClick={shareViaWhatsApp}>
                  Share via WhatsApp
                </Button>
              </div>
              <p className="text-xs text-gray-600 mt-3">
                Code expires in 48 hours
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Matchmaking Preview (Locked) */}
      <Card className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent to-white z-10 flex items-center justify-center">
          <div className="text-center">
            <div className="text-4xl mb-2">🔒</div>
            <p className="text-lg font-semibold text-gray-900">Premium Feature</p>
            <p className="text-sm text-gray-600 mt-1">Upgrade to unlock matchmaking</p>
            <Button className="mt-4" size="sm">
              Upgrade Now
            </Button>
          </div>
        </div>
        <CardHeader>
          <CardTitle>Discover Matches</CardTitle>
          <CardDescription>Find compatible partners based on your preferences</CardDescription>
        </CardHeader>
        <CardContent className="blur-sm">
          <div className="grid grid-cols-3 gap-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="aspect-square bg-gray-200 rounded-lg"></div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Invite Modal */}
      <Modal
        isOpen={showInviteModal}
        onClose={() => setShowInviteModal(false)}
        title="Invite Your Partner"
      >
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <Input
            {...register('receiverEmail')}
            label="Partner's Email"
            type="email"
            placeholder="partner@example.com"
            error={errors.receiverEmail?.message}
            required
          />

          <div>
            <label className="label">Personal Message (Optional)</label>
            <textarea
              {...register('message')}
              className="input min-h-[100px]"
              placeholder="Add a personal message..."
            />
          </div>

          <div className="flex gap-3">
            <Button type="submit" loading={loading} className="flex-1">
              Generate Code
            </Button>
            <Button
              type="button"
              variant="secondary"
              onClick={() => setShowInviteModal(false)}
            >
              Cancel
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
