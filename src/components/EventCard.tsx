import { useState } from 'react'
import { Event } from '../lib/supabase'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from './Card'
import { Button } from './Button'
import { EditEventModal } from './EditEventModal'

interface EventCardProps {
  event: Event
  onDelete: (eventId: string) => void
  onRefresh: () => void
}

export const EventCard: React.FC<EventCardProps> = ({ event, onDelete, onRefresh }) => {
  const [showEditModal, setShowEditModal] = useState(false)

  const getEventIcon = (type: string) => {
    const icons: Record<string, string> = {
      engagement: '💍',
      save_the_date: '📅',
      haldi: '💛',
      mehendi: '🎨',
      sangeet: '🎵',
      wedding: '👰',
      reception: '🎉',
      custom: '⭐',
    }
    return icons[type] || '📌'
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-IN', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  const formatTime = (time?: string) => {
    if (!time) return null
    return new Date(`2000-01-01T${time}`).toLocaleTimeString('en-IN', {
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const daysUntil = Math.ceil((new Date(event.date).getTime() - Date.now()) / (1000 * 60 * 60 * 24))

  return (
    <>
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="text-4xl">{getEventIcon(event.event_type)}</div>
              <div>
                <CardTitle>{event.name}</CardTitle>
                <CardDescription className="flex items-center gap-2 mt-1">
                  {event.auto_generated && (
                    <span className="px-2 py-0.5 bg-blue-100 text-blue-700 text-xs rounded">
                      Auto-Generated
                    </span>
                  )}
                  <span className="capitalize">{event.event_type.replace('_', ' ')}</span>
                </CardDescription>
              </div>
            </div>
            {daysUntil >= 0 && (
              <div className="text-right">
                <p className="text-2xl font-bold text-primary-400">{daysUntil}</p>
                <p className="text-xs text-gray-600">days</p>
              </div>
            )}
          </div>
        </CardHeader>

        <CardContent className="space-y-3">
          {event.description && (
            <p className="text-sm text-gray-600">{event.description}</p>
          )}

          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2">
              <span className="text-gray-500">📅</span>
              <span className="font-medium">{formatDate(event.date)}</span>
            </div>

            {event.start_time && (
              <div className="flex items-center gap-2">
                <span className="text-gray-500">🕐</span>
                <span className="font-medium">
                  {formatTime(event.start_time)}
                  {event.end_time && ` - ${formatTime(event.end_time)}`}
                </span>
              </div>
            )}

            <div className="flex items-center gap-2">
              <span className="text-gray-500">📍</span>
              <span className="font-medium">{event.venue}, {event.city}</span>
            </div>

            {event.dress_code && (
              <div className="flex items-center gap-2">
                <span className="text-gray-500">👔</span>
                <span className="font-medium">{event.dress_code}</span>
              </div>
            )}
          </div>
        </CardContent>

        <CardFooter>
          <div className="flex gap-2 w-full">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowEditModal(true)}
              className="flex-1"
            >
              Edit
            </Button>
            {!event.auto_generated && (
              <Button
                variant="secondary"
                size="sm"
                onClick={() => onDelete(event.id)}
                className="flex-1"
              >
                Delete
              </Button>
            )}
          </div>
        </CardFooter>
      </Card>

      <EditEventModal
        isOpen={showEditModal}
        onClose={() => setShowEditModal(false)}
        event={event}
        onEventUpdated={() => {
          setShowEditModal(false)
          onRefresh()
        }}
      />
    </>
  )
}
