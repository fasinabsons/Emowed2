import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { useAuth } from '../contexts/AuthContext'
import { supabase, Event, Guest, RSVP as RSVPType } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import { Input } from '../components/Input'

const rsvpSchema = z.object({
  status: z.enum(['attending', 'not_attending', 'maybe']),
  adultsCount: z.number().min(0, 'Cannot be negative'),
  teensCount: z.number().min(0, 'Cannot be negative'),
  childrenCount: z.number().min(0, 'Cannot be negative'),
  dietaryPreferences: z.string().optional(),
  specialRequirements: z.string().optional(),
  rsvpNotes: z.string().optional(),
})

type RSVPFormData = z.infer<typeof rsvpSchema>

const RSVPPage = () => {
  const { eventId } = useParams<{ eventId: string }>()
  const { user } = useAuth()
  const navigate = useNavigate()
  const [event, setEvent] = useState<Event | null>(null)
  const [guest, setGuest] = useState<Guest | null>(null)
  const [existingRSVP, setExistingRSVP] = useState<RSVPType | null>(null)
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
  } = useForm<RSVPFormData>({
    resolver: zodResolver(rsvpSchema),
    defaultValues: {
      status: 'pending' as any,
      adultsCount: 1,
      teensCount: 0,
      childrenCount: 0,
    },
  })

  const status = watch('status')
  const adultsCount = watch('adultsCount') || 0
  const teensCount = watch('teensCount') || 0
  const childrenCount = watch('childrenCount') || 0

  const calculatedHeadcount = (adultsCount * 1.0) + (teensCount * 0.75) + (childrenCount * 0.3)

  useEffect(() => {
    fetchEventAndRSVP()
  }, [eventId, user])

  const fetchEventAndRSVP = async () => {
    if (!eventId || !user) return

    try {
      // Fetch event
      const { data: eventData, error: eventError } = await supabase
        .from('events')
        .select('*')
        .eq('id', eventId)
        .single()

      if (eventError) throw eventError
      setEvent(eventData)

      // Find guest record for this user
      const { data: guestData } = await supabase
        .from('guests')
        .select('*')
        .eq('wedding_id', eventData.wedding_id)
        .eq('user_id', user.id)
        .single()

      if (guestData) {
        setGuest(guestData)

        // Check for existing RSVP
        const { data: rsvpData } = await supabase
          .from('rsvps')
          .select('*')
          .eq('event_id', eventId)
          .eq('guest_id', guestData.id)
          .single()

        if (rsvpData) {
          setExistingRSVP(rsvpData)
        }
      }
    } catch (error: any) {
      toast.error(error.message || 'Failed to load event')
    } finally {
      setLoading(false)
    }
  }

  const onSubmit = async (data: RSVPFormData) => {
    if (!event || !guest) return

    setSubmitting(true)
    try {
      const dietaryPrefs = data.dietaryPreferences
        ? data.dietaryPreferences.split(',').map((p) => p.trim())
        : []

      const rsvpData = {
        event_id: event.id,
        guest_id: guest.id,
        wedding_id: event.wedding_id,
        status: data.status,
        adults_count: data.adultsCount,
        teens_count: data.teensCount,
        children_count: data.childrenCount,
        dietary_preferences: dietaryPrefs.length > 0 ? dietaryPrefs : null,
        special_requirements: data.specialRequirements,
        rsvp_notes: data.rsvpNotes,
        submitted_at: new Date().toISOString(),
      }

      if (existingRSVP) {
        // Update existing RSVP
        const { error } = await supabase
          .from('rsvps')
          .update(rsvpData)
          .eq('id', existingRSVP.id)

        if (error) throw error
        toast.success('RSVP updated successfully!')
      } else {
        // Create new RSVP
        const { error } = await supabase.from('rsvps').insert(rsvpData)

        if (error) throw error
        toast.success('RSVP submitted successfully!')
      }

      navigate('/events')
    } catch (error: any) {
      toast.error(error.message || 'Failed to submit RSVP')
    } finally {
      setSubmitting(false)
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

  if (!event || !guest) {
    return (
      <Layout>
        <Card>
          <CardContent className="py-12 text-center">
            <h3 className="text-xl font-semibold text-gray-900 mb-2">Event Not Found</h3>
            <p className="text-gray-600 mb-6">
              You don't have access to this event or it doesn't exist.
            </p>
            <Button onClick={() => navigate('/events')}>Back to Events</Button>
          </CardContent>
        </Card>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="max-w-3xl mx-auto space-y-6">
        {/* Event Header */}
        <Card>
          <CardHeader>
            <CardTitle>{event.name}</CardTitle>
            <CardDescription>
              {new Date(event.date).toLocaleDateString('en-IN', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
              })}
              {event.start_time && ` at ${event.start_time}`}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600">{event.venue}, {event.city}</p>
            {event.description && <p className="text-gray-600 mt-2">{event.description}</p>}
          </CardContent>
        </Card>

        {/* RSVP Form */}
        <Card>
          <CardHeader>
            <CardTitle>{existingRSVP ? 'Update Your RSVP' : 'Submit Your RSVP'}</CardTitle>
            <CardDescription>
              Let us know if you'll be attending this event
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
              {/* Attendance Status */}
              <div>
                <label className="label">Will you be attending? *</label>
                <div className="grid grid-cols-3 gap-3 mt-2">
                  <label className="flex items-center justify-center p-4 border-2 rounded-lg cursor-pointer hover:border-primary-400 has-[:checked]:border-primary-400 has-[:checked]:bg-primary-50">
                    <input
                      {...register('status')}
                      type="radio"
                      value="attending"
                      className="mr-2"
                    />
                    <span className="font-medium">✅ Yes</span>
                  </label>

                  <label className="flex items-center justify-center p-4 border-2 rounded-lg cursor-pointer hover:border-primary-400 has-[:checked]:border-primary-400 has-[:checked]:bg-primary-50">
                    <input
                      {...register('status')}
                      type="radio"
                      value="not_attending"
                      className="mr-2"
                    />
                    <span className="font-medium">❌ No</span>
                  </label>

                  <label className="flex items-center justify-center p-4 border-2 rounded-lg cursor-pointer hover:border-primary-400 has-[:checked]:border-primary-400 has-[:checked]:bg-primary-50">
                    <input
                      {...register('status')}
                      type="radio"
                      value="maybe"
                      className="mr-2"
                    />
                    <span className="font-medium">🤔 Maybe</span>
                  </label>
                </div>
                {errors.status && <p className="error-text">{errors.status.message}</p>}
              </div>

              {/* Headcount (only if attending) */}
              {status === 'attending' && (
                <>
                  <div>
                    <h3 className="text-lg font-semibold mb-3">Headcount</h3>
                    <div className="grid md:grid-cols-3 gap-4">
                      <Input
                        {...register('adultsCount', { valueAsNumber: true })}
                        label="Adults"
                        type="number"
                        min="0"
                        error={errors.adultsCount?.message}
                        helperText="1.0x"
                      />

                      <Input
                        {...register('teensCount', { valueAsNumber: true })}
                        label="Teens (13-17)"
                        type="number"
                        min="0"
                        error={errors.teensCount?.message}
                        helperText="0.75x"
                      />

                      <Input
                        {...register('childrenCount', { valueAsNumber: true })}
                        label="Children (0-12)"
                        type="number"
                        min="0"
                        error={errors.childrenCount?.message}
                        helperText="0.3x"
                      />
                    </div>

                    <div className="mt-4 p-4 bg-gray-50 rounded-lg">
                      <div className="flex justify-between items-center">
                        <span className="font-medium text-gray-700">Calculated Headcount:</span>
                        <span className="text-2xl font-bold text-primary-400">
                          {calculatedHeadcount.toFixed(2)}
                        </span>
                      </div>
                      <p className="text-xs text-gray-600 mt-1">
                        Used for food planning and seating arrangements
                      </p>
                    </div>
                  </div>

                  {/* Dietary Preferences */}
                  <Input
                    {...register('dietaryPreferences')}
                    label="Dietary Preferences"
                    placeholder="Vegetarian, Vegan, Gluten-free (comma-separated)"
                    helperText="Enter preferences separated by commas"
                  />

                  {/* Special Requirements */}
                  <div>
                    <label className="label">Special Requirements</label>
                    <textarea
                      {...register('specialRequirements')}
                      className="input min-h-[80px]"
                      placeholder="Wheelchair access, food allergies, etc."
                    />
                  </div>
                </>
              )}

              {/* Notes */}
              <div>
                <label className="label">Additional Notes (Optional)</label>
                <textarea
                  {...register('rsvpNotes')}
                  className="input min-h-[80px]"
                  placeholder="Any message for the hosts..."
                />
              </div>

              <div className="flex gap-3">
                <Button type="submit" loading={submitting} className="flex-1">
                  {existingRSVP ? 'Update RSVP' : 'Submit RSVP'}
                </Button>
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => navigate('/events')}
                >
                  Cancel
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}

export default RSVPPage
