import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { supabase, VendorProfile, VendorReview } from '../lib/supabase'
import { toast } from 'react-hot-toast'
import { Card } from '../components/Card'
import { Button } from '../components/Button'
import { Modal } from '../components/Modal'

export default function VendorProfilePage() {
  const { vendorId } = useParams<{ vendorId: string }>()
  const navigate = useNavigate()
  const [vendor, setVendor] = useState<VendorProfile | null>(null)
  const [reviews, setReviews] = useState<VendorReview[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedImage, setSelectedImage] = useState<string | null>(null)
  const [showInviteModal, setShowInviteModal] = useState(false)

  useEffect(() => {
    if (vendorId) {
      fetchVendorDetails()
      fetchReviews()
    }
  }, [vendorId])

  const fetchVendorDetails = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('vendor_profiles')
        .select('*')
        .eq('id', vendorId)
        .single()

      if (error) throw error
      setVendor(data)
    } catch (error: any) {
      console.error('Error fetching vendor:', error)
      toast.error('Failed to load vendor profile')
      navigate('/vendors')
    } finally {
      setLoading(false)
    }
  }

  const fetchReviews = async () => {
    try {
      const { data, error } = await supabase
        .from('vendor_reviews')
        .select('*')
        .eq('vendor_id', vendorId)
        .order('created_at', { ascending: false })
        .limit(10)

      if (error) throw error
      setReviews(data || [])
    } catch (error: any) {
      console.error('Error fetching reviews:', error)
    }
  }

  const getRatingDistribution = () => {
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 }
    reviews.forEach(review => {
      distribution[review.rating as keyof typeof distribution]++
    })
    return distribution
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-pink-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading vendor profile...</p>
        </div>
      </div>
    )
  }

  if (!vendor) {
    return null
  }

  const ratingDistribution = getRatingDistribution()

  return (
    <div className="min-h-screen bg-gradient-to-br from-pink-50 to-purple-50">
      <div className="max-w-6xl mx-auto px-4 py-8">
        {/* Back Button */}
        <Button
          variant="outline"
          onClick={() => navigate('/vendors')}
          className="mb-6"
        >
          ← Back to Vendors
        </Button>

        {/* Hero Section */}
        <Card className="mb-8 overflow-hidden">
          <div className="relative h-64 bg-gradient-to-r from-pink-400 to-purple-500">
            {vendor.portfolio_urls && vendor.portfolio_urls.length > 0 ? (
              <img
                src={vendor.portfolio_urls[0]}
                alt={vendor.business_name}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-white">
                <div className="text-8xl">
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
                </div>
              </div>
            )}
            {vendor.verification_star && (
              <div className="absolute top-4 right-4 bg-yellow-400 text-white px-4 py-2 rounded-full text-sm font-semibold flex items-center gap-2">
                <span>⭐</span> Verified Vendor
              </div>
            )}
          </div>

          <Card.Content className="p-8">
            <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-6">
              <div className="flex-1">
                <h1 className="text-4xl font-bold text-gray-900 mb-2">
                  {vendor.business_name}
                </h1>
                <p className="text-lg text-gray-600 mb-4 capitalize">
                  {vendor.category.replace('_', ' ')} • {vendor.city}
                </p>

                {/* Rating */}
                <div className="flex items-center gap-4 mb-4">
                  <div className="flex items-center">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <span key={star} className={`text-2xl ${star <= vendor.rating ? 'text-yellow-400' : 'text-gray-300'}`}>
                        ★
                      </span>
                    ))}
                  </div>
                  <span className="text-lg font-semibold text-gray-700">
                    {vendor.rating.toFixed(1)}
                  </span>
                  <span className="text-gray-600">
                    ({vendor.total_reviews} reviews)
                  </span>
                </div>

                {/* Stats */}
                <div className="flex flex-wrap gap-4 mb-6">
                  <div className="flex items-center gap-2 px-4 py-2 bg-pink-50 rounded-lg">
                    <span>💍</span>
                    <span className="font-semibold">{vendor.wedding_count}</span>
                    <span className="text-gray-600">Weddings</span>
                  </div>
                  <div className="flex items-center gap-2 px-4 py-2 bg-purple-50 rounded-lg">
                    <span>📍</span>
                    <span className="font-semibold">{vendor.city}</span>
                  </div>
                  {vendor.subscription_type === 'paid' && (
                    <div className="flex items-center gap-2 px-4 py-2 bg-yellow-50 rounded-lg">
                      <span>👑</span>
                      <span className="font-semibold text-yellow-700">Premium</span>
                    </div>
                  )}
                </div>
              </div>

              <div className="text-right">
                <p className="text-sm text-gray-600 mb-1">Starting at</p>
                <p className="text-3xl font-bold text-pink-600 mb-4">
                  ₹{(vendor.base_price || vendor.price_range_min || 0).toLocaleString('en-IN')}
                </p>
                <Button variant="primary" size="lg" onClick={() => setShowInviteModal(true)}>
                  Invite to Wedding
                </Button>
              </div>
            </div>
          </Card.Content>
        </Card>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-8">
            {/* About */}
            <Card>
              <Card.Header>
                <Card.Title>About</Card.Title>
              </Card.Header>
              <Card.Content>
                <p className="text-gray-700 whitespace-pre-line">
                  {vendor.description || 'No description available.'}
                </p>
              </Card.Content>
            </Card>

            {/* Services Offered */}
            {vendor.services_offered && vendor.services_offered.length > 0 && (
              <Card>
                <Card.Header>
                  <Card.Title>Services Offered</Card.Title>
                </Card.Header>
                <Card.Content>
                  <div className="flex flex-wrap gap-2">
                    {vendor.services_offered.map((service, index) => (
                      <span
                        key={index}
                        className="px-3 py-1 bg-pink-100 text-pink-700 rounded-full text-sm font-medium"
                      >
                        {service}
                      </span>
                    ))}
                  </div>
                </Card.Content>
              </Card>
            )}

            {/* Portfolio */}
            {vendor.portfolio_urls && vendor.portfolio_urls.length > 0 && (
              <Card>
                <Card.Header>
                  <Card.Title>Portfolio</Card.Title>
                </Card.Header>
                <Card.Content>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                    {vendor.portfolio_urls.map((url, index) => (
                      <div
                        key={index}
                        className="relative aspect-square rounded-lg overflow-hidden cursor-pointer group"
                        onClick={() => setSelectedImage(url)}
                      >
                        <img
                          src={url}
                          alt={`Portfolio ${index + 1}`}
                          className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                        />
                        <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-30 transition-opacity duration-300 flex items-center justify-center">
                          <span className="text-white opacity-0 group-hover:opacity-100 transition-opacity">
                            View
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card.Content>
              </Card>
            )}

            {/* Reviews */}
            <Card>
              <Card.Header>
                <Card.Title>Reviews ({vendor.total_reviews})</Card.Title>
              </Card.Header>
              <Card.Content>
                {reviews.length === 0 ? (
                  <div className="text-center py-8 text-gray-500">
                    No reviews yet. Be the first to review!
                  </div>
                ) : (
                  <div className="space-y-6">
                    {reviews.map(review => (
                      <div key={review.id} className="border-b pb-6 last:border-b-0">
                        <div className="flex items-start justify-between mb-2">
                          <div>
                            <div className="flex items-center gap-2 mb-1">
                              {[1, 2, 3, 4, 5].map((star) => (
                                <span key={star} className={star <= review.rating ? 'text-yellow-400' : 'text-gray-300'}>
                                  ★
                                </span>
                              ))}
                              {review.verified_booking && (
                                <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">
                                  Verified Booking
                                </span>
                              )}
                            </div>
                            <p className="text-sm text-gray-500">
                              {new Date(review.created_at).toLocaleDateString('en-IN', {
                                year: 'numeric',
                                month: 'long',
                                day: 'numeric'
                              })}
                            </p>
                          </div>
                        </div>

                        {review.review_text && (
                          <p className="text-gray-700 mb-3">{review.review_text}</p>
                        )}

                        {review.pros && review.pros.length > 0 && (
                          <div className="mb-2">
                            <p className="text-sm font-semibold text-green-700 mb-1">Pros:</p>
                            <ul className="list-disc list-inside text-sm text-gray-600">
                              {review.pros.map((pro, index) => (
                                <li key={index}>{pro}</li>
                              ))}
                            </ul>
                          </div>
                        )}

                        {review.cons && review.cons.length > 0 && (
                          <div className="mb-2">
                            <p className="text-sm font-semibold text-red-700 mb-1">Cons:</p>
                            <ul className="list-disc list-inside text-sm text-gray-600">
                              {review.cons.map((con, index) => (
                                <li key={index}>{con}</li>
                              ))}
                            </ul>
                          </div>
                        )}

                        {review.would_recommend !== null && (
                          <p className="text-sm text-gray-600 mt-2">
                            {review.would_recommend ? '👍 Would recommend' : '👎 Would not recommend'}
                          </p>
                        )}

                        {review.response_from_vendor && (
                          <div className="mt-3 ml-6 p-3 bg-gray-50 rounded-lg">
                            <p className="text-sm font-semibold text-gray-700 mb-1">
                              Response from vendor:
                            </p>
                            <p className="text-sm text-gray-600">{review.response_from_vendor}</p>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </Card.Content>
            </Card>
          </div>

          {/* Right Sidebar */}
          <div className="space-y-6">
            {/* Contact Info */}
            <Card>
              <Card.Header>
                <Card.Title>Contact Information</Card.Title>
              </Card.Header>
              <Card.Content className="space-y-3">
                <div>
                  <p className="text-sm text-gray-600 mb-1">Phone</p>
                  <a href={`tel:${vendor.phone}`} className="text-pink-600 hover:underline font-medium">
                    {vendor.phone}
                  </a>
                </div>
                {vendor.website && (
                  <div>
                    <p className="text-sm text-gray-600 mb-1">Website</p>
                    <a
                      href={vendor.website}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-pink-600 hover:underline font-medium break-all"
                    >
                      {vendor.website}
                    </a>
                  </div>
                )}
              </Card.Content>
            </Card>

            {/* Service Areas */}
            {vendor.service_areas && vendor.service_areas.length > 0 && (
              <Card>
                <Card.Header>
                  <Card.Title>Service Areas</Card.Title>
                </Card.Header>
                <Card.Content>
                  <div className="space-y-2">
                    {vendor.service_areas.map((area, index) => (
                      <div key={index} className="flex items-center gap-2">
                        <span className="text-pink-600">📍</span>
                        <span className="text-gray-700">{area}</span>
                      </div>
                    ))}
                  </div>
                </Card.Content>
              </Card>
            )}

            {/* Pricing */}
            <Card>
              <Card.Header>
                <Card.Title>Pricing</Card.Title>
              </Card.Header>
              <Card.Content>
                {vendor.price_range_min && vendor.price_range_max ? (
                  <div>
                    <p className="text-sm text-gray-600 mb-2">Price Range</p>
                    <p className="text-2xl font-bold text-gray-900">
                      ₹{vendor.price_range_min.toLocaleString('en-IN')} - ₹{vendor.price_range_max.toLocaleString('en-IN')}
                    </p>
                  </div>
                ) : (
                  <div>
                    <p className="text-sm text-gray-600 mb-2">Starting Price</p>
                    <p className="text-2xl font-bold text-gray-900">
                      ₹{(vendor.base_price || 0).toLocaleString('en-IN')}
                    </p>
                  </div>
                )}
                <p className="text-xs text-gray-500 mt-2">
                  Final pricing will be provided in the quote
                </p>
              </Card.Content>
            </Card>

            {/* Rating Breakdown */}
            {vendor.total_reviews > 0 && (
              <Card>
                <Card.Header>
                  <Card.Title>Rating Breakdown</Card.Title>
                </Card.Header>
                <Card.Content>
                  {[5, 4, 3, 2, 1].map(rating => {
                    const count = ratingDistribution[rating as keyof typeof ratingDistribution]
                    const percentage = vendor.total_reviews > 0 ? (count / vendor.total_reviews) * 100 : 0
                    return (
                      <div key={rating} className="flex items-center gap-3 mb-2">
                        <span className="text-sm font-medium w-8">{rating}★</span>
                        <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-yellow-400"
                            style={{ width: `${percentage}%` }}
                          />
                        </div>
                        <span className="text-sm text-gray-600 w-8">{count}</span>
                      </div>
                    )
                  })}
                </Card.Content>
              </Card>
            )}
          </div>
        </div>
      </div>

      {/* Image Modal */}
      {selectedImage && (
        <Modal
          isOpen={!!selectedImage}
          onClose={() => setSelectedImage(null)}
          title="Portfolio Image"
          size="large"
        >
          <img src={selectedImage} alt="Portfolio" className="w-full h-auto" />
        </Modal>
      )}

      {/* Invite Modal */}
      {showInviteModal && (
        <Modal
          isOpen={showInviteModal}
          onClose={() => setShowInviteModal(false)}
          title="Invite Vendor to Wedding"
        >
          <div className="text-center py-8">
            <p className="text-gray-600 mb-4">
              This feature will be available once you select your wedding.
            </p>
            <Button variant="primary" onClick={() => navigate('/wedding/vendors')}>
              Go to Vendor Management
            </Button>
          </div>
        </Modal>
      )}
    </div>
  )
}
