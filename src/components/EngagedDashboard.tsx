import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { supabase, Couple, User, Wedding } from '../lib/supabase'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from './Card'
import { Button } from './Button'

interface EngagedDashboardProps {
  couple: Couple
}

export const EngagedDashboard: React.FC<EngagedDashboardProps> = ({ couple }) => {
  const { user } = useAuth()
  const [dashboardData, setDashboardData] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      if (!user) return

      // Use stored procedure to get ALL dashboard data in ONE query
      const { data, error } = await supabase.rpc('get_engaged_dashboard_data', {
        p_user_id: user.id,
      })

      if (error) {
        console.error('Error fetching dashboard data:', error)
        setLoading(false)
        return
      }

      setDashboardData(data)
      setLoading(false)
    }

    fetchData()
  }, [user])

  if (loading) {
    return <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-400"></div>
  }

  if (!dashboardData) {
    return <div className="text-center text-gray-600">No data available</div>
  }

  const coupleData = dashboardData.couple
  const wedding = dashboardData.wedding
  const weddingStats = dashboardData.wedding_stats
  const daysUntilWedding = wedding?.days_until || null

  const partner = coupleData?.user1?.id === user?.id ? coupleData?.user2 : coupleData?.user1

  return (
    <div className="space-y-6">
      {/* Couple Header */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex -space-x-4">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary-400 to-secondary-400 flex items-center justify-center text-white font-bold text-xl border-4 border-white">
                  {user?.full_name.charAt(0)}
                </div>
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-secondary-400 to-primary-400 flex items-center justify-center text-white font-bold text-xl border-4 border-white">
                  {partner?.full_name?.charAt(0)}
                </div>
              </div>
              <div>
                <h2 className="text-2xl font-bold text-gray-900">
                  {user?.full_name} & {partner?.full_name}
                </h2>
                <p className="text-gray-600">
                  Engaged since {coupleData?.engaged_date && new Date(coupleData.engaged_date).toLocaleDateString()}
                </p>
              </div>
            </div>

            {daysUntilWedding !== null && daysUntilWedding > 0 && (
              <div className="text-right">
                <p className="text-4xl font-bold text-gradient">{daysUntilWedding}</p>
                <p className="text-sm text-gray-600">days to go</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {!wedding ? (
        /* Create Wedding CTA */
        <Card className="bg-gradient-to-br from-primary-50 to-secondary-50 border-primary-200">
          <CardHeader>
            <CardTitle>Ready to Plan Your Wedding?</CardTitle>
            <CardDescription>
              Create your wedding to unlock all features: guest management, vendor booking, RSVP tracking, and more.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Link to="/wedding/create">
              <Button size="lg">Create Our Wedding</Button>
            </Link>

            <div className="grid md:grid-cols-3 gap-4 mt-6">
              <div className="text-center p-4 bg-white rounded-lg">
                <div className="text-3xl mb-2">👥</div>
                <p className="font-semibold">Guest Management</p>
                <p className="text-sm text-gray-600">Invite & track guests</p>
              </div>
              <div className="text-center p-4 bg-white rounded-lg">
                <div className="text-3xl mb-2">📋</div>
                <p className="font-semibold">Event Planning</p>
                <p className="text-sm text-gray-600">7 auto-generated events</p>
              </div>
              <div className="text-center p-4 bg-white rounded-lg">
                <div className="text-3xl mb-2">⭐</div>
                <p className="font-semibold">Vendor Booking</p>
                <p className="text-sm text-gray-600">Verified vendors only</p>
              </div>
            </div>
          </CardContent>
        </Card>
      ) : (
        /* Wedding Overview */
        <>
          <Card>
            <CardHeader>
              <CardTitle>{wedding.name}</CardTitle>
              <CardDescription>
                {new Date(wedding.date).toLocaleDateString()} • {wedding.venue}, {wedding.city}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid md:grid-cols-4 gap-4">
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-2xl font-bold text-primary-400">
                    {weddingStats?.total_events || 0}/7
                  </p>
                  <p className="text-sm text-gray-600">Events</p>
                </div>
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-2xl font-bold text-primary-400">
                    {weddingStats?.total_guests || 0}/{wedding.guest_limit}
                  </p>
                  <p className="text-sm text-gray-600">Guests</p>
                </div>
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-2xl font-bold text-primary-400">
                    {weddingStats?.confirmed_vendors || 0}/8
                  </p>
                  <p className="text-sm text-gray-600">Vendors</p>
                </div>
                <div className="text-center p-4 bg-gray-50 rounded-lg">
                  <p className="text-2xl font-bold text-primary-400">
                    {weddingStats?.total_vendors || 0}
                  </p>
                  <p className="text-sm text-gray-600">Total Vendors</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Quick Actions */}
          <div className="grid md:grid-cols-4 gap-6">
            <Link to="/events">
              <Card className="hover:shadow-lg transition-shadow cursor-pointer h-full">
                <CardHeader>
                  <div className="text-4xl mb-2">📅</div>
                  <CardTitle>Events</CardTitle>
                  <CardDescription>Manage wedding events</CardDescription>
                </CardHeader>
              </Card>
            </Link>

            <Link to="/guests">
              <Card className="hover:shadow-lg transition-shadow cursor-pointer h-full">
                <CardHeader>
                  <div className="text-4xl mb-2">👥</div>
                  <CardTitle>Guests</CardTitle>
                  <CardDescription>Invite family and friends</CardDescription>
                </CardHeader>
              </Card>
            </Link>

            <Link to="/headcount">
              <Card className="hover:shadow-lg transition-shadow cursor-pointer h-full">
                <CardHeader>
                  <div className="text-4xl mb-2">📊</div>
                  <CardTitle>Headcount</CardTitle>
                  <CardDescription>Track RSVPs</CardDescription>
                </CardHeader>
              </Card>
            </Link>

            <Card className="hover:shadow-lg transition-shadow cursor-pointer h-full opacity-50">
              <CardHeader>
                <div className="text-4xl mb-2">⭐</div>
                <CardTitle>Vendors</CardTitle>
                <CardDescription>Coming in Phase 3</CardDescription>
              </CardHeader>
            </Card>
          </div>
        </>
      )}
    </div>
  )
}
