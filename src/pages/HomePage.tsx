import { Link } from 'react-router-dom'
import { Button } from '../components/Button'

const HomePage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-pink-50 to-white">
      {/* Navigation */}
      <nav className="container py-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gradient">Emowed</h1>
          <div className="flex gap-4">
            <Link to="/login">
              <Button variant="secondary">Login</Button>
            </Link>
            <Link to="/signup">
              <Button variant="primary">Sign Up</Button>
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container py-20">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
            From First Swipe to <span className="text-gradient">Forever</span>
          </h2>
          <p className="text-xl text-gray-600 mb-10 max-w-2xl mx-auto">
            The only platform that supports Indian couples through every stage - from dating to marriage and beyond
          </p>
          <Link to="/signup">
            <Button size="lg" className="text-lg px-8">
              Get Started Free
            </Button>
          </Link>
        </div>
      </section>

      {/* Features Section */}
      <section className="container py-20">
        <h3 className="text-3xl font-bold text-center mb-12">Everything You Need for Your Wedding Journey</h3>
        <div className="grid md:grid-cols-3 gap-8">
          <FeatureCard
            title="Partner Connect"
            description="Invite your partner with a simple code. Start planning together instantly."
            icon="💕"
          />
          <FeatureCard
            title="Family Integration"
            description="Involve both families with proper hierarchy and permissions. Just like real weddings."
            icon="👨‍👩‍👧‍👦"
          />
          <FeatureCard
            title="Smart Planning"
            description="Manage guests, vendors, RSVPs, and budgets all in one place with real-time updates."
            icon="📋"
          />
          <FeatureCard
            title="Vendor Trust System"
            description="Book verified vendors based on actual wedding performance. No fake reviews."
            icon="⭐"
          />
          <FeatureCard
            title="Digital Invitations"
            description="Beautiful wedding cards with QR codes. Track RSVPs and dietary preferences automatically."
            icon="💌"
          />
          <FeatureCard
            title="Post-Marriage Support"
            description="Access marriage counseling, family planning resources, and couple activities."
            icon="🏡"
          />
        </div>
      </section>

      {/* CTA Section */}
      <section className="container py-20">
        <div className="bg-gradient-to-r from-primary-400 to-secondary-400 rounded-2xl p-12 text-center text-white">
          <h3 className="text-4xl font-bold mb-4">Ready to Start Your Journey?</h3>
          <p className="text-xl mb-8 opacity-90">Join thousands of couples planning their perfect wedding</p>
          <Link to="/signup">
            <Button variant="secondary" size="lg">
              Create Free Account
            </Button>
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="container py-12 border-t border-gray-200">
        <div className="text-center text-gray-600">
          <p>&copy; 2025 Emowed. All rights reserved.</p>
          <div className="flex justify-center gap-6 mt-4">
            <a href="#" className="hover:text-primary-400">About</a>
            <a href="#" className="hover:text-primary-400">Privacy</a>
            <a href="#" className="hover:text-primary-400">Terms</a>
            <a href="#" className="hover:text-primary-400">Contact</a>
          </div>
        </div>
      </footer>
    </div>
  )
}

const FeatureCard: React.FC<{ title: string; description: string; icon: string }> = ({ title, description, icon }) => {
  return (
    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
      <div className="text-4xl mb-4">{icon}</div>
      <h4 className="text-xl font-semibold mb-2">{title}</h4>
      <p className="text-gray-600">{description}</p>
    </div>
  )
}

export default HomePage
