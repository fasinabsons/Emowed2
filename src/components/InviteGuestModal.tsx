import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { supabase } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'
import { Modal } from './Modal'
import { Input } from './Input'
import { Button } from './Button'

const guestSchema = z.object({
  fullName: z.string().min(3, 'Name must be at least 3 characters'),
  email: z.string().email('Invalid email address').optional().or(z.literal('')),
  phone: z.string().optional(),
  side: z.enum(['groom', 'bride']),
  role: z.enum(['parent', 'sibling', 'uncle', 'aunt', 'cousin', 'grandparent', 'friend', 'colleague', 'other']),
  canInviteOthers: z.boolean(),
  plusOneAllowed: z.boolean(),
  plusOneName: z.string().optional(),
  isVIP: z.boolean(),
  under18: z.boolean(),
  age: z.number().optional(),
  dietaryPreferences: z.string().optional(),
  specialRequirements: z.string().optional(),
})

type GuestFormData = z.infer<typeof guestSchema>

interface InviteGuestModalProps {
  isOpen: boolean
  onClose: () => void
  weddingId: string
  onGuestInvited: () => void
}

export const InviteGuestModal: React.FC<InviteGuestModalProps> = ({
  isOpen,
  onClose,
  weddingId,
  onGuestInvited,
}) => {
  const { user } = useAuth()
  const [loading, setLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    watch,
  } = useForm<GuestFormData>({
    resolver: zodResolver(guestSchema),
    defaultValues: {
      side: 'groom',
      role: 'friend',
      canInviteOthers: false,
      plusOneAllowed: false,
      isVIP: false,
      under18: false,
    },
  })

  const plusOneAllowed = watch('plusOneAllowed')
  const under18 = watch('under18')

  const onSubmit = async (data: GuestFormData) => {
    if (!user) return

    setLoading(true)
    try {
      // Prepare dietary preferences array
      const dietaryPrefs = data.dietaryPreferences
        ? data.dietaryPreferences.split(',').map((p) => p.trim())
        : []

      const { error } = await supabase.from('guests').insert({
        wedding_id: weddingId,
        full_name: data.fullName,
        email: data.email || null,
        phone: data.phone,
        side: data.side,
        role: data.role,
        invited_by: user.id,
        can_invite_others: data.canInviteOthers,
        plus_one_allowed: data.plusOneAllowed,
        plus_one_name: data.plusOneName,
        is_vip: data.isVIP,
        under_18: data.under18,
        age: data.age,
        dietary_preferences: dietaryPrefs.length > 0 ? dietaryPrefs : null,
        special_requirements: data.specialRequirements,
        status: 'invited',
        invitation_sent_at: new Date().toISOString(),
      })

      if (error) throw error

      reset()
      onGuestInvited()
    } catch (error: any) {
      toast.error(error.message || 'Failed to invite guest')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Invite Guest" size="xl">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {/* Basic Info */}
        <div className="grid md:grid-cols-2 gap-4">
          <Input
            {...register('fullName')}
            label="Full Name"
            placeholder="John Doe"
            error={errors.fullName?.message}
            required
          />

          <Input
            {...register('email')}
            label="Email"
            type="email"
            placeholder="john@example.com"
            error={errors.email?.message}
          />
        </div>

        <div className="grid md:grid-cols-2 gap-4">
          <Input
            {...register('phone')}
            label="Phone"
            type="tel"
            placeholder="+91 98765 43210"
            error={errors.phone?.message}
          />

          <div>
            <label className="label">Side *</label>
            <select {...register('side')} className="input">
              <option value="groom">Groom's Side</option>
              <option value="bride">Bride's Side</option>
            </select>
            {errors.side && <p className="error-text">{errors.side.message}</p>}
          </div>
        </div>

        {/* Role */}
        <div>
          <label className="label">Relationship/Role *</label>
          <select {...register('role')} className="input">
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
          {errors.role && <p className="error-text">{errors.role.message}</p>}
        </div>

        {/* Permissions */}
        <div className="space-y-3">
          <label className="flex items-center gap-2">
            <input type="checkbox" {...register('canInviteOthers')} className="rounded" />
            <span className="text-sm font-medium text-gray-700">
              Can invite other guests (only for parents/siblings)
            </span>
          </label>

          <label className="flex items-center gap-2">
            <input type="checkbox" {...register('plusOneAllowed')} className="rounded" />
            <span className="text-sm font-medium text-gray-700">Allow +1 guest</span>
          </label>

          {plusOneAllowed && (
            <Input
              {...register('plusOneName')}
              label="Plus One Name"
              placeholder="Guest's +1"
              className="ml-6"
            />
          )}

          <label className="flex items-center gap-2">
            <input type="checkbox" {...register('isVIP')} className="rounded" />
            <span className="text-sm font-medium text-gray-700">Mark as VIP</span>
          </label>

          <label className="flex items-center gap-2">
            <input type="checkbox" {...register('under18')} className="rounded" />
            <span className="text-sm font-medium text-gray-700">Under 18 years old</span>
          </label>

          {!under18 && (
            <Input
              {...register('age', { valueAsNumber: true })}
              label="Age"
              type="number"
              placeholder="25"
              className="ml-6"
            />
          )}
        </div>

        {/* Dietary & Special Requirements */}
        <Input
          {...register('dietaryPreferences')}
          label="Dietary Preferences"
          placeholder="Vegetarian, Vegan, Gluten-free (comma-separated)"
          helperText="Enter preferences separated by commas"
        />

        <div>
          <label className="label">Special Requirements</label>
          <textarea
            {...register('specialRequirements')}
            className="input min-h-[80px]"
            placeholder="Wheelchair access, food allergies, etc."
          />
        </div>

        <div className="flex gap-3">
          <Button type="submit" loading={loading} className="flex-1">
            Send Invitation
          </Button>
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
        </div>
      </form>
    </Modal>
  )
}
