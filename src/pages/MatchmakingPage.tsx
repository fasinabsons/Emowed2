import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import toast from 'react-hot-toast'

interface MatchProfile {
  id: string
  user_id: string
  full_name: string
  age: number
  city?: string
  bio?: string
  interests?: string[]
  profile_photo_url?: string
}

const MatchmakingPage = () => {
  const { user } = useAuth()
  const [matchProfiles, setMatchProfiles] = useState<MatchProfile[]>([])
  const [currentIndex, setCurrentIndex] = useState(0)
  const [loading, setLoading] = useState(true)
  const [userProfile, setUserProfile] = useState<MatchProfile | null>(null)

  useEffect(() => {
    if (user?.relationship_status !== 'single') {
      toast.error('Matchmaking is only available for single users')
      return
    }
    fetchMatchProfiles()
  }, [user])

  const fetchMatchProfiles = async () => {
    try {
      setLoading(true)

      // Check if user has a matchmaking profile
      const { data: profileData } = await supabase
        .from('matchmaking_profiles')
        .select('*')
        .eq('user_id', user?.id)
        .single()

      setUserProfile(profileData)

      if (!profileData) {
        setLoading(false)
        return
      }

      // Fetch potential matches
      const { data: matchesData } = await supabase
        .from('matchmaking_profiles')
        .select('*')
        .neq('user_id', user?.id)
        .limit(20)

      setMatchProfiles(matchesData || [])
    } catch (error: any) {
      console.error('Error fetching matches:', error)
      toast.error('Failed to load matches')
    } finally {
      setLoading(false)
    }
  }

  const handleSwipe = async (profileId: string, direction: 'like' | 'dislike') => {
    try {
      await supabase.from('match_swipes').insert({
        swiper_id: user?.id,
        swiped_id: profileId,
        swipe_type: direction,
      })

      if (direction === 'like') {
        // Check for mutual like
        const { data: mutualSwipe } = await supabase
          .from('match_swipes')
          .select('*')
          .eq('swiper_id', profileId)
          .eq('swiped_id', user?.id)
          .eq('swipe_type', 'like')
          .single()

        if (mutualSwipe) {
          // Create match
          await supabase.from('matches').insert({
            user1_id: user?.id,
            user2_id: profileId,
            match_status: 'active',
          })

          toast.success("It's a match! 🎉")
        }
      }

      setCurrentIndex(currentIndex + 1)
    } catch (error: any) {
      console.error('Error swiping:', error)
      toast.error('Failed to process swipe')
    }
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-400"></div>
        </div>
      </Layout>
    )
  }

  if (user?.relationship_status !== 'single') {
    return (
      <Layout>
        <Card>
          <CardContent className="p-12 text-center">
            <div className="text-6xl mb-4">💑</div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Matchmaking for Singles Only
            </h2>
            <p className="text-gray-600">
              This feature is only available for single users
            </p>
          </CardContent>
        </Card>
      </Layout>
    )
  }

  if (!userProfile) {
    return (
      <Layout>
        <Card>
          <CardContent className="p-12 text-center">
            <div className="text-6xl mb-4">💝</div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Create Your Matchmaking Profile
            </h2>
            <p className="text-gray-600 mb-6">
              Set up your profile to start discovering compatible matches
            </p>
            <Button onClick={() => toast.info('Profile creation coming soon!')}>
              Create Profile
            </Button>
          </CardContent>
        </Card>
      </Layout>
    )
  }

  const currentProfile = matchProfiles[currentIndex]

  if (!currentProfile) {
    return (
      <Layout>
        <Card>
          <CardContent className="p-12 text-center">
            <div className="text-6xl mb-4">🎯</div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              No More Profiles
            </h2>
            <p className="text-gray-600 mb-6">
              You've seen all available profiles. Check back later for new matches!
            </p>
            <Button onClick={() => setCurrentIndex(0)}>
              Start Over
            </Button>
          </CardContent>
        </Card>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">Discover</h1>
          <p className="text-gray-600 mt-1">
            Swipe right to like, left to pass
          </p>
        </div>

        {/* Profile Card */}
        <Card className="overflow-hidden">
          <div className="relative h-96 bg-gradient-to-br from-primary-100 to-secondary-100">
            {currentProfile.profile_photo_url ? (
              <img
                src={currentProfile.profile_photo_url}
                alt={currentProfile.full_name}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center">
                <div className="text-8xl text-white">
                  {currentProfile.full_name.charAt(0)}
                </div>
              </div>
            )}
          </div>

          <CardContent className="p-6">
            <div className="mb-4">
              <h2 className="text-2xl font-bold text-gray-900">
                {currentProfile.full_name}, {currentProfile.age}
              </h2>
              {currentProfile.city && (
                <p className="text-gray-600">{currentProfile.city}</p>
              )}
            </div>

            {currentProfile.bio && (
              <p className="text-gray-700 mb-4">{currentProfile.bio}</p>
            )}

            {currentProfile.interests && currentProfile.interests.length > 0 && (
              <div className="mb-4">
                <h3 className="text-sm font-semibold text-gray-900 mb-2">Interests</h3>
                <div className="flex flex-wrap gap-2">
                  {currentProfile.interests.map((interest, idx) => (
                    <span
                      key={idx}
                      className="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm"
                    >
                      {interest}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Action Buttons */}
            <div className="grid grid-cols-2 gap-4 mt-6">
              <Button
                variant="outline"
                size="lg"
                onClick={() => handleSwipe(currentProfile.id, 'dislike')}
                className="text-red-600 border-red-600 hover:bg-red-50"
              >
                ✕ Pass
              </Button>
              <Button
                size="lg"
                onClick={() => handleSwipe(currentProfile.id, 'like')}
                className="bg-green-600 hover:bg-green-700"
              >
                ♥ Like
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* Progress Indicator */}
        <div className="text-center text-sm text-gray-600">
          {currentIndex + 1} of {matchProfiles.length} profiles
        </div>

        {/* Quick Links */}
        <div className="grid grid-cols-2 gap-4">
          <Card className="cursor-pointer hover:shadow-md transition-shadow">
            <CardContent className="p-4 text-center">
              <div className="text-2xl mb-1">💬</div>
              <p className="text-sm font-medium">My Matches</p>
            </CardContent>
          </Card>
          <Card className="cursor-pointer hover:shadow-md transition-shadow">
            <CardContent className="p-4 text-center">
              <div className="text-2xl mb-1">⚙️</div>
              <p className="text-sm font-medium">Preferences</p>
            </CardContent>
          </Card>
        </div>
      </div>
    </Layout>
  )
}

export default MatchmakingPage
