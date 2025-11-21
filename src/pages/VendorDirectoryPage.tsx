import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase, VendorProfile } from '../lib/supabase'
import { toast } from 'react-hot-toast'
import { Card } from '../components/Card'
import { Button } from '../components/Button'
import { Input } from '../components/Input'

const categories = [
  { value: 'photographer', label: 'Photographer' },
  { value: 'videographer', label: 'Videographer' },
  { value: 'caterer', label: 'Caterer' },
  { value: 'decorator', label: 'Decorator' },
  { value: 'makeup_artist', label: 'Makeup Artist' },
  { value: 'mehendi_artist', label: 'Mehendi Artist' },
  { value: 'dj', label: 'DJ' },
  { value: 'band', label: 'Band' },
  { value: 'venue', label: 'Venue' },
  { value: 'florist', label: 'Florist' },
  { value: 'priest', label: 'Priest' },
  { value: 'travel', label: 'Travel & Accommodation' },
]

const cities = [
  'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai',
  'Kolkata', 'Pune', 'Ahmedabad', 'Jaipur', 'Goa',
  'Udaipur', 'Lucknow', 'Indore', 'Chandigarh'
]

export default function VendorDirectoryPage() {
  const navigate = useNavigate()
  const [vendors, setVendors] = useState<VendorProfile[]>([])
  const [filteredVendors, setFilteredVendors] = useState<VendorProfile[]>([])
  const [loading, setLoading] = useState(true)

  // Filters
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string>('')
  const [selectedCity, setSelectedCity] = useState<string>('')
  const [minPrice, setMinPrice] = useState<number>(0)
  const [maxPrice, setMaxPrice] = useState<number>(500000)
  const [verifiedOnly, setVerifiedOnly] = useState(false)
  const [minRating, setMinRating] = useState<number>(0)

  // Pagination
  const [currentPage, setCurrentPage] = useState(1)
  const vendorsPerPage = 12

  useEffect(() => {
    fetchVendors()
  }, [])

  useEffect(() => {
    applyFilters()
  }, [vendors, searchQuery, selectedCategory, selectedCity, minPrice, maxPrice, verifiedOnly, minRating])

  const fetchVendors = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('vendor_profiles')
        .select('*')
        .eq('blocked', false)
        .order('rating', { ascending: false })

      if (error) throw error
      setVendors(data || [])
    } catch (error: any) {
      console.error('Error fetching vendors:', error)
      toast.error('Failed to load vendors')
    } finally {
      setLoading(false)
    }
  }

  const applyFilters = () => {
    let filtered = [...vendors]

    // Search query
    if (searchQuery) {
      filtered = filtered.filter(v =>
        v.business_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.city.toLowerCase().includes(searchQuery.toLowerCase())
      )
    }

    // Category filter
    if (selectedCategory) {
      filtered = filtered.filter(v => v.category === selectedCategory)
    }

    // City filter
    if (selectedCity) {
      filtered = filtered.filter(v =>
        v.city === selectedCity ||
        v.service_areas?.includes(selectedCity)
      )
    }

    // Price range filter
    filtered = filtered.filter(v => {
      const price = v.base_price || v.price_range_min || 0
      return price >= minPrice && price <= maxPrice
    })

    // Verified filter
    if (verifiedOnly) {
      filtered = filtered.filter(v => v.verification_star)
    }

    // Rating filter
    if (minRating > 0) {
      filtered = filtered.filter(v => v.rating >= minRating)
    }

    setFilteredVendors(filtered)
    setCurrentPage(1) // Reset to first page when filters change
  }

  const clearFilters = () => {
    setSearchQuery('')
    setSelectedCategory('')
    setSelectedCity('')
    setMinPrice(0)
    setMaxPrice(500000)
    setVerifiedOnly(false)
    setMinRating(0)
  }

  // Pagination
  const indexOfLastVendor = currentPage * vendorsPerPage
  const indexOfFirstVendor = indexOfLastVendor - vendorsPerPage
  const currentVendors = filteredVendors.slice(indexOfFirstVendor, indexOfLastVendor)
  const totalPages = Math.ceil(filteredVendors.length / vendorsPerPage)

  const VendorCard = ({ vendor }: { vendor: VendorProfile }) => (
    <Card className="hover:shadow-xl transition-all duration-300 cursor-pointer group"
          onClick={() => navigate(`/vendors/${vendor.id}`)}>
      <div className="relative h-48 bg-gradient-to-br from-pink-100 to-purple-100 rounded-t-xl overflow-hidden">
        {vendor.profile_image_url ? (
          <img
            src={vendor.profile_image_url}
            alt={vendor.business_name}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <div className="text-6xl text-pink-300">
              {vendor.category === 'photographer' && '📸'}
              {vendor.category === 'videographer' && '🎥'}
              {vendor.category === 'caterer' && '🍽️'}
              {vendor.category === 'decorator' && '🎨'}
              {vendor.category === 'makeup_artist' && '💄'}
              {vendor.category === 'mehendi_artist' && '🖐️'}
              {vendor.category === 'dj' && '🎧'}
              {vendor.category === 'band' && '🎵'}
              {vendor.category === 'venue' && '🏛️'}
              {vendor.category === 'florist' && '🌸'}
              {vendor.category === 'priest' && '🕉️'}
              {vendor.category === 'travel' && '✈️'}
              {!['photographer', 'videographer', 'caterer', 'decorator', 'makeup_artist', 'mehendi_artist', 'dj', 'band', 'venue', 'florist', 'priest', 'travel'].includes(vendor.category) && '🎊'}
            </div>
          </div>
        )}
        {vendor.verification_star && (
          <div className="absolute top-2 right-2 bg-yellow-400 text-white px-2 py-1 rounded-full text-xs font-semibold flex items-center gap-1">
            <span>⭐</span> Verified
          </div>
        )}
        {vendor.featured && (
          <div className="absolute top-2 left-2 bg-pink-600 text-white px-2 py-1 rounded-full text-xs font-semibold">
            Featured
          </div>
        )}
      </div>
      <Card.Content className="p-4">
        <h3 className="text-lg font-bold text-gray-900 mb-1 group-hover:text-pink-600 transition-colors">
          {vendor.business_name}
        </h3>
        <p className="text-sm text-gray-600 mb-2 capitalize">
          {vendor.category.replace('_', ' ')}
        </p>

        {/* Rating */}
        <div className="flex items-center gap-2 mb-2">
          <div className="flex items-center">
            {[1, 2, 3, 4, 5].map((star) => (
              <span key={star} className={star <= vendor.rating ? 'text-yellow-400' : 'text-gray-300'}>
                ★
              </span>
            ))}
          </div>
          <span className="text-sm text-gray-600">
            {vendor.rating.toFixed(1)} ({vendor.total_reviews} reviews)
          </span>
        </div>

        {/* Wedding Count */}
        <div className="flex items-center gap-2 mb-3 text-sm text-gray-600">
          <span>💍</span>
          <span>{vendor.wedding_count} weddings completed</span>
        </div>

        {/* Location */}
        <div className="flex items-center gap-2 mb-3 text-sm text-gray-600">
          <span>📍</span>
          <span>{vendor.city}</span>
          {vendor.service_areas && vendor.service_areas.length > 0 && (
            <span className="text-xs text-gray-500">
              +{vendor.service_areas.length} more
            </span>
          )}
        </div>

        {/* Price */}
        <div className="flex items-center justify-between border-t pt-3">
          <div>
            <p className="text-xs text-gray-500">Starting at</p>
            <p className="text-lg font-bold text-pink-600">
              ₹{(vendor.base_price || vendor.price_range_min || 0).toLocaleString('en-IN')}
            </p>
          </div>
          <Button variant="primary" size="sm">
            View Profile
          </Button>
        </div>
      </Card.Content>
    </Card>
  )

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-pink-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading vendors...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50">
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            Find Your Perfect Vendors
          </h1>
          <p className="text-gray-600">
            Browse verified wedding vendors for your special day
          </p>
        </div>

        {/* Filters */}
        <Card className="mb-8">
          <Card.Content className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
              {/* Search */}
              <div className="lg:col-span-4">
                <Input
                  type="text"
                  placeholder="Search by business name, description, or city..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full"
                />
              </div>

              {/* Category Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Category
                </label>
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                >
                  <option value="">All Categories</option>
                  {categories.map(cat => (
                    <option key={cat.value} value={cat.value}>{cat.label}</option>
                  ))}
                </select>
              </div>

              {/* City Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  City
                </label>
                <select
                  value={selectedCity}
                  onChange={(e) => setSelectedCity(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                >
                  <option value="">All Cities</option>
                  {cities.map(city => (
                    <option key={city} value={city}>{city}</option>
                  ))}
                </select>
              </div>

              {/* Min Price */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Min Price (₹)
                </label>
                <input
                  type="number"
                  value={minPrice}
                  onChange={(e) => setMinPrice(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  min="0"
                  step="10000"
                />
              </div>

              {/* Max Price */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Max Price (₹)
                </label>
                <input
                  type="number"
                  value={maxPrice}
                  onChange={(e) => setMaxPrice(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                  min="0"
                  step="10000"
                />
              </div>

              {/* Rating Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Minimum Rating
                </label>
                <select
                  value={minRating}
                  onChange={(e) => setMinRating(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-pink-500 focus:border-transparent"
                >
                  <option value="0">All Ratings</option>
                  <option value="4">4+ Stars</option>
                  <option value="4.5">4.5+ Stars</option>
                </select>
              </div>

              {/* Verified Only */}
              <div className="flex items-center">
                <label className="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={verifiedOnly}
                    onChange={(e) => setVerifiedOnly(e.target.checked)}
                    className="w-4 h-4 text-pink-600 border-gray-300 rounded focus:ring-pink-500"
                  />
                  <span className="ml-2 text-sm font-medium text-gray-700">
                    ⭐ Verified Only
                  </span>
                </label>
              </div>

              {/* Clear Filters */}
              <div className="flex items-center">
                <Button
                  variant="outline"
                  onClick={clearFilters}
                  className="w-full"
                >
                  Clear All Filters
                </Button>
              </div>
            </div>

            {/* Results Count */}
            <div className="text-sm text-gray-600">
              Showing {filteredVendors.length} vendor{filteredVendors.length !== 1 ? 's' : ''}
            </div>
          </Card.Content>
        </Card>

        {/* Vendors Grid */}
        {currentVendors.length === 0 ? (
          <Card>
            <Card.Content className="p-12 text-center">
              <div className="text-6xl mb-4">🔍</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                No vendors found
              </h3>
              <p className="text-gray-600 mb-4">
                Try adjusting your filters or search criteria
              </p>
              <Button variant="primary" onClick={clearFilters}>
                Clear Filters
              </Button>
            </Card.Content>
          </Card>
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
              {currentVendors.map(vendor => (
                <VendorCard key={vendor.id} vendor={vendor} />
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-center gap-2">
                <Button
                  variant="outline"
                  onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                >
                  Previous
                </Button>

                <div className="flex items-center gap-2">
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                    <button
                      key={page}
                      onClick={() => setCurrentPage(page)}
                      className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                        currentPage === page
                          ? 'bg-pink-600 text-white'
                          : 'bg-white text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      {page}
                    </button>
                  ))}
                </div>

                <Button
                  variant="outline"
                  onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                  disabled={currentPage === totalPages}
                >
                  Next
                </Button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  )
}
