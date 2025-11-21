import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import { ProtectedRoute } from './components/ProtectedRoute'

// Pages
import HomePage from './pages/HomePage'
import SignupPage from './pages/SignupPage'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import ProfilePage from './pages/ProfilePage'
import WeddingCreatePage from './pages/WeddingCreatePage'
import AcceptInvitePage from './pages/AcceptInvitePage'
import EventsPage from './pages/EventsPage'
import GuestsPage from './pages/GuestsPage'
import RSVPPage from './pages/RSVPPage'
import HeadcountPage from './pages/HeadcountPage'
import VendorDirectoryPage from './pages/VendorDirectoryPage'
import VendorProfilePage from './pages/VendorProfilePage'
import VendorManagementPage from './pages/VendorManagementPage'
import VendorDashboardPage from './pages/VendorDashboardPage'
import GalleryPage from './pages/GalleryPage'
import GamesPage from './pages/GamesPage'
import MatchmakingPage from './pages/MatchmakingPage'
import PostMarriagePage from './pages/PostMarriagePage'

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public routes */}
          <Route path="/" element={<HomePage />} />
          <Route path="/signup" element={<SignupPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/invite/accept/:code" element={<AcceptInvitePage />} />

          {/* Protected routes */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <DashboardPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <ProfilePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/wedding/create"
            element={
              <ProtectedRoute>
                <WeddingCreatePage />
              </ProtectedRoute>
            }
          />

          {/* Phase 2: Events, Guests, RSVP */}
          <Route
            path="/events"
            element={
              <ProtectedRoute>
                <EventsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/guests"
            element={
              <ProtectedRoute>
                <GuestsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/rsvp/:eventId"
            element={
              <ProtectedRoute>
                <RSVPPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/headcount"
            element={
              <ProtectedRoute>
                <HeadcountPage />
              </ProtectedRoute>
            }
          />

          {/* Phase 3: Vendor System */}
          <Route
            path="/vendors"
            element={
              <ProtectedRoute>
                <VendorDirectoryPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/vendors/:vendorId"
            element={
              <ProtectedRoute>
                <VendorProfilePage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/wedding/vendors"
            element={
              <ProtectedRoute>
                <VendorManagementPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/vendor/dashboard"
            element={
              <ProtectedRoute>
                <VendorDashboardPage />
              </ProtectedRoute>
            }
          />

          {/* Phase 4: Media/Gallery */}
          <Route
            path="/gallery"
            element={
              <ProtectedRoute>
                <GalleryPage />
              </ProtectedRoute>
            }
          />

          {/* Phase 5: Games */}
          <Route
            path="/games"
            element={
              <ProtectedRoute>
                <GamesPage />
              </ProtectedRoute>
            }
          />

          {/* Phase 6: Matchmaking & Post-Marriage */}
          <Route
            path="/matchmaking"
            element={
              <ProtectedRoute>
                <MatchmakingPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/post-marriage"
            element={
              <ProtectedRoute>
                <PostMarriagePage />
              </ProtectedRoute>
            }
          />

          {/* Catch all */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
