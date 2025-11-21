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

const eventSchema = z.object({
  name: z.string().min(3, 'Event name must be at least 3 characters'),
  description: z.string().optional(),
  eventType: z.enum(['custom', 'engagement', 'save_the_date', 'haldi', 'mehendi', 'sangeet', 'wedding', 'reception']),
  date: z.string().min(1, 'Date is required'),
  startTime: z.string().optional(),
  endTime: z.string().optional(),
  venue: z.string().min(3, 'Venue is required'),
  city: z.string().min(2, 'City is required'),
  dressCode: z.string().optional(),
})

type EventFormData = z.infer<typeof eventSchema>

interface CreateEventModalProps {
  isOpen: boolean
  onClose: () => void
  weddingId: string
  onEventCreated: () => void
}

export const CreateEventModal: React.FC<CreateEventModalProps> = ({
  isOpen,
  onClose,
  weddingId,
  onEventCreated,
}) => {
  const { user } = useAuth()
  const [loading, setLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<EventFormData>({
    resolver: zodResolver(eventSchema),
    defaultValues: {
      eventType: 'custom',
    },
  })

  const onSubmit = async (data: EventFormData) => {
    if (!user) return

    setLoading(true)
    try {
      const { error } = await supabase.from('events').insert({
        wedding_id: weddingId,
        name: data.name,
        description: data.description,
        event_type: data.eventType,
        date: data.date,
        start_time: data.startTime || null,
        end_time: data.endTime || null,
        venue: data.venue,
        city: data.city,
        dress_code: data.dressCode,
        auto_generated: false,
        created_by: user.id,
      })

      if (error) throw error

      reset()
      onEventCreated()
    } catch (error: any) {
      toast.error(error.message || 'Failed to create event')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Create Custom Event" size="lg">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          {...register('name')}
          label="Event Name"
          placeholder="e.g., Cocktail Party"
          error={errors.name?.message}
          required
        />

        <div>
          <label className="label">Event Type</label>
          <select {...register('eventType')} className="input">
            <option value="custom">Custom</option>
            <option value="engagement">Engagement</option>
            <option value="haldi">Haldi</option>
            <option value="mehendi">Mehendi</option>
            <option value="sangeet">Sangeet</option>
            <option value="wedding">Wedding</option>
            <option value="reception">Reception</option>
          </select>
        </div>

        <div>
          <label className="label">Description (Optional)</label>
          <textarea
            {...register('description')}
            className="input min-h-[80px]"
            placeholder="Add event details..."
          />
          {errors.description && <p className="error-text">{errors.description.message}</p>}
        </div>

        <div className="grid md:grid-cols-3 gap-4">
          <Input
            {...register('date')}
            label="Date"
            type="date"
            error={errors.date?.message}
            required
          />

          <Input
            {...register('startTime')}
            label="Start Time"
            type="time"
            error={errors.startTime?.message}
          />

          <Input
            {...register('endTime')}
            label="End Time"
            type="time"
            error={errors.endTime?.message}
          />
        </div>

        <div className="grid md:grid-cols-2 gap-4">
          <Input
            {...register('venue')}
            label="Venue"
            placeholder="e.g., Grand Palace Hotel"
            error={errors.venue?.message}
            required
          />

          <Input
            {...register('city')}
            label="City"
            placeholder="e.g., Mumbai"
            error={errors.city?.message}
            required
          />
        </div>

        <Input
          {...register('dressCode')}
          label="Dress Code (Optional)"
          placeholder="e.g., Formal, Traditional"
          error={errors.dressCode?.message}
        />

        <div className="flex gap-3">
          <Button type="submit" loading={loading} className="flex-1">
            Create Event
          </Button>
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
        </div>
      </form>
    </Modal>
  )
}
