import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { Button } from './Button'
import toast from 'react-hot-toast'

interface LayoutProps {
  children: React.ReactNode
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    toast.success('Logged out successfully')
    navigate('/')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white border-b border-gray-200">
        <div className="container py-4">
          <div className="flex items-center justify-between">
            <Link to="/dashboard" className="text-2xl font-bold text-gradient">
              Emowed
            </Link>

            <div className="flex items-center gap-6">
              <Link
                to="/dashboard"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Dashboard
              </Link>
              <Link
                to="/events"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Events
              </Link>
              <Link
                to="/guests"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Guests
              </Link>
              <Link
                to="/vendors"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Vendors
              </Link>
              <Link
                to="/gallery"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Gallery
              </Link>
              <Link
                to="/games"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Games
              </Link>
              {user?.relationship_status === 'single' && (
                <Link
                  to="/matchmaking"
                  className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
                >
                  Matchmaking
                </Link>
              )}
              <Link
                to="/profile"
                className="text-gray-700 hover:text-primary-400 font-medium transition-colors"
              >
                Profile
              </Link>

              <div className="flex items-center gap-3 border-l border-gray-200 pl-6">
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900">{user?.full_name}</p>
                  <p className="text-xs text-gray-500 capitalize">{user?.relationship_status}</p>
                </div>
                <Button variant="secondary" size="sm" onClick={handleSignOut}>
                  Logout
                </Button>
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="container py-8">{children}</main>
    </div>
  )
}
