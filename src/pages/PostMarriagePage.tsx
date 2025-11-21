import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import { Modal } from '../components/Modal'
import toast from 'react-hot-toast'

interface DiaryEntry {
  id: string
  couple_id: string
  entry_date: string
  title: string
  content: string
  mood?: string
  created_by: string
  created_at: string
}

interface Goal {
  id: string
  couple_id: string
  title: string
  description?: string
  category: 'financial' | 'health' | 'career' | 'family' | 'personal' | 'other'
  target_date?: string
  status: 'active' | 'completed' | 'abandoned'
  created_at: string
}

const PostMarriagePage = () => {
  const { user } = useAuth()
  const [couple, setCouple] = useState<any>(null)
  const [diaryEntries, setDiaryEntries] = useState<DiaryEntry[]>([])
  const [goals, setGoals] = useState<Goal[]>([])
  const [loading, setLoading] = useState(true)
  const [showDiaryModal, setShowDiaryModal] = useState(false)
  const [showGoalModal, setShowGoalModal] = useState(false)
  const [diaryTitle, setDiaryTitle] = useState('')
  const [diaryContent, setDiaryContent] = useState('')
  const [diaryMood, setDiaryMood] = useState('')
  const [goalTitle, setGoalTitle] = useState('')
  const [goalDescription, setGoalDescription] = useState('')
  const [goalCategory, setGoalCategory] = useState<Goal['category']>('personal')

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)

      // Get couple
      const { data: coupleData } = await supabase
        .from('couples')
        .select('*')
        .or(`user1_id.eq.${user?.id},user2_id.eq.${user?.id}`)
        .single()

      setCouple(coupleData)

      if (coupleData && coupleData.status === 'married') {
        // Fetch diary entries
        const { data: diaryData } = await supabase
          .from('couple_diary_entries')
          .select('*')
          .eq('couple_id', coupleData.id)
          .order('entry_date', { ascending: false })
          .limit(10)

        setDiaryEntries(diaryData || [])

        // Fetch goals
        const { data: goalsData } = await supabase
          .from('couple_shared_goals')
          .select('*')
          .eq('couple_id', coupleData.id)
          .order('created_at', { ascending: false })

        setGoals(goalsData || [])
      }
    } catch (error: any) {
      console.error('Error fetching data:', error)
      toast.error('Failed to load data')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateDiaryEntry = async () => {
    if (!diaryTitle || !diaryContent || !couple) {
      toast.error('Please fill in all required fields')
      return
    }

    try {
      const { error } = await supabase.from('couple_diary_entries').insert({
        couple_id: couple.id,
        entry_date: new Date().toISOString().split('T')[0],
        title: diaryTitle,
        content: diaryContent,
        mood: diaryMood || null,
        created_by: user?.id,
      })

      if (error) throw error

      toast.success('Diary entry created!')
      setShowDiaryModal(false)
      setDiaryTitle('')
      setDiaryContent('')
      setDiaryMood('')
      fetchData()
    } catch (error: any) {
      console.error('Error creating diary entry:', error)
      toast.error('Failed to create diary entry')
    }
  }

  const handleCreateGoal = async () => {
    if (!goalTitle || !couple) {
      toast.error('Please enter a goal title')
      return
    }

    try {
      const { error } = await supabase.from('couple_shared_goals').insert({
        couple_id: couple.id,
        title: goalTitle,
        description: goalDescription || null,
        category: goalCategory,
        status: 'active',
      })

      if (error) throw error

      toast.success('Goal created!')
      setShowGoalModal(false)
      setGoalTitle('')
      setGoalDescription('')
      setGoalCategory('personal')
      fetchData()
    } catch (error: any) {
      console.error('Error creating goal:', error)
      toast.error('Failed to create goal')
    }
  }

  const handleCompleteGoal = async (goalId: string) => {
    try {
      const { error } = await supabase
        .from('couple_shared_goals')
        .update({ status: 'completed' })
        .eq('id', goalId)

      if (error) throw error

      toast.success('Goal marked as complete! 🎉')
      fetchData()
    } catch (error: any) {
      console.error('Error completing goal:', error)
      toast.error('Failed to complete goal')
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

  if (!couple || couple.status !== 'married') {
    return (
      <Layout>
        <Card>
          <CardContent className="p-12 text-center">
            <div className="text-6xl mb-4">💑</div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              For Married Couples Only
            </h2>
            <p className="text-gray-600">
              This feature is only available for married couples
            </p>
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
          <h1 className="text-3xl font-bold text-gray-900">Our Journey Together</h1>
          <p className="text-gray-600 mt-1">
            Track your life as a married couple
          </p>
        </div>

        {/* Quick Stats */}
        <div className="grid md:grid-cols-4 gap-6">
          <Card>
            <CardContent className="p-6 text-center">
              <div className="text-3xl font-bold text-pink-600 mb-1">
                {Math.floor((new Date().getTime() - new Date(couple.married_date || couple.created_at).getTime()) / (1000 * 60 * 60 * 24))}
              </div>
              <div className="text-sm text-gray-600">Days Married</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-6 text-center">
              <div className="text-3xl font-bold text-blue-600 mb-1">
                {diaryEntries.length}
              </div>
              <div className="text-sm text-gray-600">Diary Entries</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-6 text-center">
              <div className="text-3xl font-bold text-green-600 mb-1">
                {goals.filter(g => g.status === 'active').length}
              </div>
              <div className="text-sm text-gray-600">Active Goals</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-6 text-center">
              <div className="text-3xl font-bold text-purple-600 mb-1">
                {goals.filter(g => g.status === 'completed').length}
              </div>
              <div className="text-sm text-gray-600">Goals Achieved</div>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <div className="grid lg:grid-cols-2 gap-6">
          {/* Couple Diary */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Couple Diary</CardTitle>
                <Button size="sm" onClick={() => setShowDiaryModal(true)}>
                  + New Entry
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {diaryEntries.length === 0 ? (
                <div className="text-center py-12">
                  <div className="text-5xl mb-3">📖</div>
                  <p className="text-gray-600 mb-4">No diary entries yet</p>
                  <Button size="sm" onClick={() => setShowDiaryModal(true)}>
                    Write First Entry
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  {diaryEntries.map((entry) => (
                    <div key={entry.id} className="p-4 border rounded-lg hover:shadow-md transition-shadow">
                      <div className="flex items-start justify-between mb-2">
                        <h3 className="font-semibold text-gray-900">{entry.title}</h3>
                        {entry.mood && <span className="text-2xl">{entry.mood}</span>}
                      </div>
                      <p className="text-sm text-gray-600 mb-2 line-clamp-2">{entry.content}</p>
                      <p className="text-xs text-gray-500">
                        {new Date(entry.entry_date).toLocaleDateString()}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Shared Goals */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Shared Goals</CardTitle>
                <Button size="sm" onClick={() => setShowGoalModal(true)}>
                  + New Goal
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {goals.length === 0 ? (
                <div className="text-center py-12">
                  <div className="text-5xl mb-3">🎯</div>
                  <p className="text-gray-600 mb-4">No goals yet</p>
                  <Button size="sm" onClick={() => setShowGoalModal(true)}>
                    Set First Goal
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  {goals.map((goal) => (
                    <div key={goal.id} className="p-4 border rounded-lg">
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex-1">
                          <h3 className="font-semibold text-gray-900">{goal.title}</h3>
                          {goal.description && (
                            <p className="text-sm text-gray-600 mt-1">{goal.description}</p>
                          )}
                          <div className="flex items-center gap-2 mt-2">
                            <span className="text-xs px-2 py-1 bg-gray-100 text-gray-700 rounded capitalize">
                              {goal.category}
                            </span>
                            <span
                              className={`text-xs px-2 py-1 rounded ${
                                goal.status === 'completed'
                                  ? 'bg-green-100 text-green-700'
                                  : goal.status === 'active'
                                  ? 'bg-blue-100 text-blue-700'
                                  : 'bg-gray-100 text-gray-700'
                              }`}
                            >
                              {goal.status}
                            </span>
                          </div>
                        </div>
                        {goal.status === 'active' && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleCompleteGoal(goal.id)}
                          >
                            ✓ Complete
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Additional Features */}
        <div className="grid md:grid-cols-3 gap-6">
          <Card className="cursor-pointer hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="text-4xl mb-2">📅</div>
              <CardTitle>Date Night Planner</CardTitle>
              <CardDescription>Plan your next romantic date</CardDescription>
            </CardHeader>
          </Card>

          <Card className="cursor-pointer hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="text-4xl mb-2">🎁</div>
              <CardTitle>Gift Tracker</CardTitle>
              <CardDescription>Track gifts for special occasions</CardDescription>
            </CardHeader>
          </Card>

          <Card className="cursor-pointer hover:shadow-lg transition-shadow">
            <CardHeader>
              <div className="text-4xl mb-2">🗣️</div>
              <CardTitle>Counseling</CardTitle>
              <CardDescription>Connect with relationship counselors</CardDescription>
            </CardHeader>
          </Card>
        </div>

        {/* Diary Entry Modal */}
        <Modal
          isOpen={showDiaryModal}
          onClose={() => setShowDiaryModal(false)}
          title="New Diary Entry"
        >
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
              <input
                type="text"
                value={diaryTitle}
                onChange={(e) => setDiaryTitle(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
                placeholder="A beautiful day together..."
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">How are you feeling?</label>
              <div className="flex gap-2">
                {['😊', '😍', '🥰', '😌', '😔'].map((emoji) => (
                  <button
                    key={emoji}
                    onClick={() => setDiaryMood(emoji)}
                    className={`text-3xl p-2 rounded-lg transition-colors ${
                      diaryMood === emoji ? 'bg-primary-100' : 'hover:bg-gray-100'
                    }`}
                  >
                    {emoji}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Entry</label>
              <textarea
                value={diaryContent}
                onChange={(e) => setDiaryContent(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
                rows={6}
                placeholder="Write about your day together..."
              />
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowDiaryModal(false)} className="flex-1">
                Cancel
              </Button>
              <Button onClick={handleCreateDiaryEntry} className="flex-1">
                Save Entry
              </Button>
            </div>
          </div>
        </Modal>

        {/* Goal Modal */}
        <Modal
          isOpen={showGoalModal}
          onClose={() => setShowGoalModal(false)}
          title="New Shared Goal"
        >
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Goal Title</label>
              <input
                type="text"
                value={goalTitle}
                onChange={(e) => setGoalTitle(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
                placeholder="e.g., Save for a house"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Category</label>
              <select
                value={goalCategory}
                onChange={(e) => setGoalCategory(e.target.value as Goal['category'])}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
              >
                <option value="financial">Financial</option>
                <option value="health">Health</option>
                <option value="career">Career</option>
                <option value="family">Family</option>
                <option value="personal">Personal</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description (Optional)
              </label>
              <textarea
                value={goalDescription}
                onChange={(e) => setGoalDescription(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
                rows={3}
                placeholder="Describe your goal..."
              />
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowGoalModal(false)} className="flex-1">
                Cancel
              </Button>
              <Button onClick={handleCreateGoal} className="flex-1">
                Create Goal
              </Button>
            </div>
          </div>
        </Modal>
      </div>
    </Layout>
  )
}

export default PostMarriagePage
