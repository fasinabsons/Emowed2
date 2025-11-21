import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import toast from 'react-hot-toast'

interface GameType {
  id: string
  name: string
  description: string
  icon: string
  min_participants: number
  max_participants?: number
}

interface WeddingGame {
  id: string
  wedding_id: string
  game_type_id: string
  status: 'active' | 'completed' | 'cancelled'
  created_at: string
}

const GamesPage = () => {
  const { user } = useAuth()
  const [wedding, setWedding] = useState<any>(null)
  const [gameTypes, setGameTypes] = useState<GameType[]>([])
  const [activeGames, setActiveGames] = useState<WeddingGame[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)

      // Get wedding
      const { data: coupleData } = await supabase
        .from('couples')
        .select('id')
        .or(`user1_id.eq.${user?.id},user2_id.eq.${user?.id}`)
        .single()

      if (coupleData) {
        const { data: weddingData } = await supabase
          .from('weddings')
          .select('*')
          .eq('couple_id', coupleData.id)
          .single()

        setWedding(weddingData)

        if (weddingData) {
          // Fetch game types
          const { data: typesData } = await supabase
            .from('game_types')
            .select('*')
            .order('name')

          setGameTypes(typesData || [])

          // Fetch active games
          const { data: gamesData } = await supabase
            .from('wedding_games')
            .select('*')
            .eq('wedding_id', weddingData.id)
            .eq('status', 'active')

          setActiveGames(gamesData || [])
        }
      }
    } catch (error: any) {
      console.error('Error fetching data:', error)
      toast.error('Failed to load games')
    } finally {
      setLoading(false)
    }
  }

  const handleStartGame = async (gameTypeId: string) => {
    if (!wedding) return

    try {
      const { error } = await supabase.from('wedding_games').insert({
        wedding_id: wedding.id,
        game_type_id: gameTypeId,
        status: 'active',
      })

      if (error) throw error

      toast.success('Game started!')
      fetchData()
    } catch (error: any) {
      console.error('Error starting game:', error)
      toast.error('Failed to start game')
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

  if (!wedding) {
    return (
      <Layout>
        <Card>
          <CardContent className="p-12 text-center">
            <div className="text-6xl mb-4">💒</div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Create Your Wedding First</h2>
            <p className="text-gray-600 mb-6">
              You need to create a wedding before you can play games
            </p>
            <Button onClick={() => window.location.href = '/wedding/create'}>
              Create Wedding
            </Button>
          </CardContent>
        </Card>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Wedding Games</h1>
          <p className="text-gray-600 mt-1">
            Engage your guests with fun interactive games
          </p>
        </div>

        {/* Active Games */}
        {activeGames.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Active Games ({activeGames.length})</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
                {activeGames.map((game) => (
                  <div
                    key={game.id}
                    className="p-4 border rounded-lg hover:shadow-md transition-shadow"
                  >
                    <h3 className="font-semibold text-gray-900 mb-2">Active Game</h3>
                    <p className="text-sm text-gray-600 mb-3">
                      Started: {new Date(game.created_at).toLocaleDateString()}
                    </p>
                    <Button size="sm" variant="outline" className="w-full">
                      View Details
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Available Games */}
        <div>
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Available Games</h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Trivia Game */}
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="text-4xl mb-2">🎯</div>
                <CardTitle>Couple Trivia</CardTitle>
                <CardDescription>
                  Test how well guests know the couple with fun questions
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => handleStartGame('trivia')} className="w-full">
                  Start Game
                </Button>
              </CardContent>
            </Card>

            {/* Photo Challenge */}
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="text-4xl mb-2">📸</div>
                <CardTitle>Photo Challenge</CardTitle>
                <CardDescription>
                  Guests compete to take the best themed photos
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => handleStartGame('photo')} className="w-full">
                  Start Game
                </Button>
              </CardContent>
            </Card>

            {/* Dance Competition */}
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="text-4xl mb-2">💃</div>
                <CardTitle>Dance Battle</CardTitle>
                <CardDescription>
                  Groom's side vs Bride's side dance competition
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => handleStartGame('dance')} className="w-full">
                  Start Game
                </Button>
              </CardContent>
            </Card>

            {/* Wishes & Predictions */}
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="text-4xl mb-2">🔮</div>
                <CardTitle>Wishes & Predictions</CardTitle>
                <CardDescription>
                  Guests share wishes and predictions for the couple
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => handleStartGame('wishes')} className="w-full">
                  Start Game
                </Button>
              </CardContent>
            </Card>

            {/* Scavenger Hunt */}
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="text-4xl mb-2">🔍</div>
                <CardTitle>Scavenger Hunt</CardTitle>
                <CardDescription>
                  Create a fun scavenger hunt for guests
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => handleStartGame('scavenger')} className="w-full">
                  Start Game
                </Button>
              </CardContent>
            </Card>

            {/* Leaderboard */}
            <Card className="hover:shadow-lg transition-shadow bg-gradient-to-br from-yellow-50 to-orange-50">
              <CardHeader>
                <div className="text-4xl mb-2">🏆</div>
                <CardTitle>Leaderboard</CardTitle>
                <CardDescription>
                  View rankings and scores across all games
                </CardDescription>
              </CardHeader>
              <CardContent>
                <Button variant="outline" onClick={() => toast.info('Coming soon!')} className="w-full">
                  View Leaderboard
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Side Competition */}
        <Card className="bg-gradient-to-r from-blue-50 to-pink-50">
          <CardHeader>
            <CardTitle>Groom vs Bride Side Competition</CardTitle>
            <CardDescription>
              Track points for each side across all games
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-8">
              <div className="text-center">
                <h3 className="text-lg font-semibold text-blue-700 mb-2">Groom's Side</h3>
                <div className="text-5xl font-bold text-blue-600 mb-2">0</div>
                <p className="text-sm text-gray-600">Total Points</p>
              </div>
              <div className="text-center">
                <h3 className="text-lg font-semibold text-pink-700 mb-2">Bride's Side</h3>
                <div className="text-5xl font-bold text-pink-600 mb-2">0</div>
                <p className="text-sm text-gray-600">Total Points</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  )
}

export default GamesPage
