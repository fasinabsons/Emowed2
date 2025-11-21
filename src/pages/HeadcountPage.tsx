import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { supabase, Event, Wedding, HeadcountSnapshot } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'

const HeadcountPage = () => {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [events, setEvents] = useState<Event[]>([])
  const [wedding, setWedding] = useState<Wedding | null>(null)
  const [snapshots, setSnapshots] = useState<Record<string, HeadcountSnapshot[]>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchHeadcountData()
  }, [user])

  const fetchHeadcountData = async () => {
    if (!user) return

    try {
      // Get couple and wedding
      const { data: coupleData } = await supabase
        .from('couples')
        .select('*')
        .or(`user1_id.eq.${user.id},user2_id.eq.${user.id}`)
        .single()

      if (!coupleData) {
        navigate('/dashboard')
        return
      }

      const { data: weddingData } = await supabase
        .from('weddings')
        .select('*')
        .eq('couple_id', coupleData.id)
        .single()

      if (!weddingData) {
        navigate('/wedding/create')
        return
      }

      setWedding(weddingData)

      // Fetch events
      const { data: eventsData } = await supabase
        .from('events')
        .select('*')
        .eq('wedding_id', weddingData.id)
        .order('date', { ascending: true })

      setEvents(eventsData || [])

      // Fetch headcount snapshots for all events
      const snapshotsMap: Record<string, HeadcountSnapshot[]> = {}
      for (const event of eventsData || []) {
        const { data: snapshotData } = await supabase
          .from('headcount_snapshots')
          .select('*')
          .eq('event_id', event.id)
          .order('snapshot_date', { ascending: false })
          .limit(1)

        if (snapshotData) {
          snapshotsMap[event.id] = snapshotData
        }
      }

      setSnapshots(snapshotsMap)
    } catch (error) {
      console.error('Failed to load headcount data', error)
    } finally {
      setLoading(false)
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

  const getTotalHeadcount = () => {
    let total = 0
    Object.values(snapshots).forEach((eventSnapshots) => {
      eventSnapshots.forEach((snapshot) => {
        total += snapshot.calculated_headcount
      })
    })
    return total
  }

  const getTotalByStatus = (status: 'attending' | 'declined' | 'maybe' | 'pending') => {
    const key = `total_${status}` as keyof HeadcountSnapshot
    let total = 0
    Object.values(snapshots).forEach((eventSnapshots) => {
      eventSnapshots.forEach((snapshot) => {
        total += snapshot[key] as number || 0
      })
    })
    return total
  }

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Headcount Dashboard</h1>
          <p className="text-gray-600 mt-1">
            Real-time RSVP tracking and attendance statistics
          </p>
        </div>

        {/* Overall Stats */}
        <div className="grid md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-primary-400">
                  {getTotalHeadcount().toFixed(1)}
                </p>
                <p className="text-sm text-gray-600 mt-1">Total Headcount</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-green-500">
                  {getTotalByStatus('attending')}
                </p>
                <p className="text-sm text-gray-600 mt-1">Attending</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-red-500">
                  {getTotalByStatus('declined')}
                </p>
                <p className="text-sm text-gray-600 mt-1">Declined</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="text-center">
                <p className="text-3xl font-bold text-yellow-500">
                  {getTotalByStatus('pending')}
                </p>
                <p className="text-sm text-gray-600 mt-1">Pending</p>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Event Breakdown */}
        <div className="space-y-4">
          <h2 className="text-2xl font-semibold text-gray-900">By Event</h2>

          {events.map((event) => {
            const eventSnapshots = snapshots[event.id] || []
            const groomSnapshot = eventSnapshots.find((s) => s.side === 'groom')
            const brideSnapshot = eventSnapshots.find((s) => s.side === 'bride')

            return (
              <Card key={event.id}>
                <CardHeader>
                  <CardTitle>{event.name}</CardTitle>
                  <CardDescription>
                    {new Date(event.date).toLocaleDateString()}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid md:grid-cols-2 gap-6">
                    {/* Groom's Side */}
                    <div>
                      <h3 className="text-lg font-semibold text-blue-600 mb-3">Groom's Side</h3>
                      {groomSnapshot ? (
                        <div className="space-y-2">
                          <div className="flex justify-between">
                            <span className="text-gray-600">Total Invited:</span>
                            <span className="font-medium">{groomSnapshot.total_invited}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Attending:</span>
                            <span className="font-medium text-green-600">
                              {groomSnapshot.total_attending}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Declined:</span>
                            <span className="font-medium text-red-600">
                              {groomSnapshot.total_declined}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Pending:</span>
                            <span className="font-medium text-yellow-600">
                              {groomSnapshot.total_pending}
                            </span>
                          </div>
                          <div className="pt-2 border-t border-gray-200">
                            <div className="flex justify-between">
                              <span className="text-gray-600">Headcount:</span>
                              <span className="text-lg font-bold text-primary-400">
                                {groomSnapshot.calculated_headcount.toFixed(1)}
                              </span>
                            </div>
                          </div>
                          <div className="text-xs text-gray-500 space-y-1">
                            <div className="flex justify-between">
                              <span>Adults:</span>
                              <span>{groomSnapshot.adults_count}</span>
                            </div>
                            <div className="flex justify-between">
                              <span>Teens:</span>
                              <span>{groomSnapshot.teens_count}</span>
                            </div>
                            <div className="flex justify-between">
                              <span>Children:</span>
                              <span>{groomSnapshot.children_count}</span>
                            </div>
                          </div>
                        </div>
                      ) : (
                        <p className="text-gray-500 text-sm">No RSVPs yet</p>
                      )}
                    </div>

                    {/* Bride's Side */}
                    <div>
                      <h3 className="text-lg font-semibold text-pink-600 mb-3">Bride's Side</h3>
                      {brideSnapshot ? (
                        <div className="space-y-2">
                          <div className="flex justify-between">
                            <span className="text-gray-600">Total Invited:</span>
                            <span className="font-medium">{brideSnapshot.total_invited}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Attending:</span>
                            <span className="font-medium text-green-600">
                              {brideSnapshot.total_attending}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Declined:</span>
                            <span className="font-medium text-red-600">
                              {brideSnapshot.total_declined}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Pending:</span>
                            <span className="font-medium text-yellow-600">
                              {brideSnapshot.total_pending}
                            </span>
                          </div>
                          <div className="pt-2 border-t border-gray-200">
                            <div className="flex justify-between">
                              <span className="text-gray-600">Headcount:</span>
                              <span className="text-lg font-bold text-primary-400">
                                {brideSnapshot.calculated_headcount.toFixed(1)}
                              </span>
                            </div>
                          </div>
                          <div className="text-xs text-gray-500 space-y-1">
                            <div className="flex justify-between">
                              <span>Adults:</span>
                              <span>{brideSnapshot.adults_count}</span>
                            </div>
                            <div className="flex justify-between">
                              <span>Teens:</span>
                              <span>{brideSnapshot.teens_count}</span>
                            </div>
                            <div className="flex justify-between">
                              <span>Children:</span>
                              <span>{brideSnapshot.children_count}</span>
                            </div>
                          </div>
                        </div>
                      ) : (
                        <p className="text-gray-500 text-sm">No RSVPs yet</p>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            )
          })}

          {events.length === 0 && (
            <Card>
              <CardContent className="py-12 text-center">
                <p className="text-gray-600">No events found. Create events to track RSVPs.</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </Layout>
  )
}

export default HeadcountPage
