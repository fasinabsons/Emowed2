import { useEffect, useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { Layout } from '../components/Layout'
import { SingleDashboard } from '../components/SingleDashboard'
import { EngagedDashboard } from '../components/EngagedDashboard'
import { supabase, Couple } from '../lib/supabase'

const DashboardPage = () => {
  const { user } = useAuth()
  const [couple, setCouple] = useState<Couple | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchCouple = async () => {
      if (!user) return

      // Check if user is part of a couple
      const { data } = await supabase
        .from('couples')
        .select('*')
        .or(`user1_id.eq.${user.id},user2_id.eq.${user.id}`)
        .single()

      setCouple(data)
      setLoading(false)
    }

    fetchCouple()
  }, [user])

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-400"></div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      {user?.relationship_status === 'single' || !couple ? (
        <SingleDashboard />
      ) : (
        <EngagedDashboard couple={couple} />
      )}
    </Layout>
  )
}

export default DashboardPage
