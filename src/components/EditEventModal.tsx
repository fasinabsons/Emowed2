import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { supabase, Event } from '../lib/supabase'
import { Modal } from './Modal'
import { Input } from './Input'
import { Button } from './Button'

const eventSchema = z.object({
  name: z.string().min(3, 'Event name must be at least 3 characters'),
  description: z.string().optional(),
  date: z.string().min(1, 'Date is required'),
  startTime: z.string().optional(),
  endTime: z.string().optional(),
  venue: z.string().min(3, 'Venue is required'),
  city: z.string().min(2, 'City is required'),
  dressCode: z.string().optional(),
})

type EventFormData = z.infer<typeof eventSchema>

interface EditEventModalProps {
  isOpen: boolean
  onClose: () => void
  event: Event
  onEventUpdated: () => void
}

export const EditEventModal: React.FC<EditEventModalProps> = ({
  isOpen,
  onClose,
  event,
  onEventUpdated,
}) => {
  const [loading, setLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<EventFormData>({
    resolver: zodResolver(eventSchema),
    defaultValues: {
      name: event.name,
      description: event.description || '',
      date: event.date,
      startTime: event.start_time || '',
      endTime: event.end_time || '',
      venue: event.venue,
      city: event.city,
      dressCode: event.dress_code || '',
    },
  })

  const onSubmit = async (data: EventFormData) => {
    setLoading(true)
    try {
      const { error } = await supabase
        .from('events')
        .update({
          name: data.name,
          description: data.description,
          date: data.date,
          start_time: data.startTime || null,
          end_time: data.endTime || null,
          venue: data.venue,
          city: data.city,
          dress_code: data.dressCode,
          updated_at: new Date().toISOString(),
        })
        .eq('id', event.id)

      if (error) throw error

      toast.success('Event updated successfully!')
      onEventUpdated()
    } catch (error: any) {
      toast.error(error.message || 'Failed to update event')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Edit Event" size="lg">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <Input
          {...register('name')}
          label="Event Name"
          error={errors.name?.message}
          required
        />

        <div>
          <label className="label">Description (Optional)</label>
          <textarea
            {...register('description')}
            className="input min-h-[80px]"
            placeholder="Add event details..."
          />
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
            error={errors.venue?.message}
            required
          />

          <Input
            {...register('city')}
            label="City"
            error={errors.city?.message}
            required
          />
        </div>

        <Input
          {...register('dressCode')}
          label="Dress Code (Optional)"
          error={errors.dressCode?.message}
        />

        <div className="flex gap-3">
          <Button type="submit" loading={loading} className="flex-1">
            Update Event
          </Button>
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
        </div>
      </form>
    </Modal>
  )
}
