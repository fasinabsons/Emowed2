import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import { Modal } from '../components/Modal'
import toast from 'react-hot-toast'

interface MediaItem {
  id: string
  album_id: string
  wedding_id: string
  uploaded_by: string
  media_type: 'photo' | 'video'
  url: string
  thumbnail_url?: string
  caption?: string
  taken_at?: string
  created_at: string
}

interface Album {
  id: string
  wedding_id: string
  name: string
  description?: string
  cover_image_url?: string
  is_private: boolean
  created_by: string
  created_at: string
}

const GalleryPage = () => {
  const { user } = useAuth()
  const [albums, setAlbums] = useState<Album[]>([])
  const [selectedAlbum, setSelectedAlbum] = useState<Album | null>(null)
  const [mediaItems, setMediaItems] = useState<MediaItem[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreateAlbum, setShowCreateAlbum] = useState(false)
  const [showUpload, setShowUpload] = useState(false)
  const [albumName, setAlbumName] = useState('')
  const [albumDescription, setAlbumDescription] = useState('')
  const [wedding, setWedding] = useState<any>(null)
  const [selectedImage, setSelectedImage] = useState<MediaItem | null>(null)

  useEffect(() => {
    fetchWeddingAndAlbums()
  }, [])

  useEffect(() => {
    if (selectedAlbum) {
      fetchMediaItems(selectedAlbum.id)
    }
  }, [selectedAlbum])

  const fetchWeddingAndAlbums = async () => {
    try {
      setLoading(true)

      // Get couple and wedding
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
          // Fetch albums
          const { data: albumsData } = await supabase
            .from('media_albums')
            .select('*')
            .eq('wedding_id', weddingData.id)
            .order('created_at', { ascending: false })

          setAlbums(albumsData || [])
          if (albumsData && albumsData.length > 0) {
            setSelectedAlbum(albumsData[0])
          }
        }
      }
    } catch (error: any) {
      console.error('Error fetching data:', error)
      toast.error('Failed to load albums')
    } finally {
      setLoading(false)
    }
  }

  const fetchMediaItems = async (albumId: string) => {
    try {
      const { data, error } = await supabase
        .from('media_items')
        .select('*')
        .eq('album_id', albumId)
        .order('created_at', { ascending: false })

      if (error) throw error

      setMediaItems(data || [])
    } catch (error: any) {
      console.error('Error fetching media:', error)
      toast.error('Failed to load media items')
    }
  }

  const handleCreateAlbum = async () => {
    if (!albumName || !wedding) {
      toast.error('Please enter an album name')
      return
    }

    try {
      const { error } = await supabase.from('media_albums').insert({
        wedding_id: wedding.id,
        name: albumName,
        description: albumDescription || null,
        is_private: false,
        created_by: user?.id,
      })

      if (error) throw error

      toast.success('Album created successfully!')
      setShowCreateAlbum(false)
      setAlbumName('')
      setAlbumDescription('')
      fetchWeddingAndAlbums()
    } catch (error: any) {
      console.error('Error creating album:', error)
      toast.error('Failed to create album')
    }
  }

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files
    if (!files || files.length === 0 || !selectedAlbum || !wedding) return

    toast.info('File upload requires Cloudinary configuration. Please add VITE_CLOUDINARY_* env variables.')

    // In production, you would upload to Cloudinary here:
    // const formData = new FormData()
    // formData.append('file', files[0])
    // formData.append('upload_preset', 'your_preset')
    //
    // const response = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/upload`, {
    //   method: 'POST',
    //   body: formData,
    // })
    //
    // const data = await response.json()
    //
    // await supabase.from('media_items').insert({
    //   album_id: selectedAlbum.id,
    //   wedding_id: wedding.id,
    //   uploaded_by: user?.id,
    //   media_type: files[0].type.startsWith('video/') ? 'video' : 'photo',
    //   url: data.secure_url,
    //   thumbnail_url: data.thumbnail_url,
    // })
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
              You need to create a wedding before you can manage photos
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Wedding Gallery</h1>
            <p className="text-gray-600 mt-1">{wedding.name}</p>
          </div>
          <div className="flex gap-3">
            <Button variant="outline" onClick={() => setShowCreateAlbum(true)}>
              + New Album
            </Button>
            <Button onClick={() => setShowUpload(true)} disabled={!selectedAlbum}>
              + Upload Photos
            </Button>
          </div>
        </div>

        {/* Albums Tabs */}
        <div className="flex gap-2 overflow-x-auto pb-2">
          {albums.map((album) => (
            <button
              key={album.id}
              onClick={() => setSelectedAlbum(album)}
              className={`px-4 py-2 rounded-lg font-medium whitespace-nowrap transition-colors ${
                selectedAlbum?.id === album.id
                  ? 'bg-primary-400 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-100'
              }`}
            >
              {album.name}
            </button>
          ))}
        </div>

        {/* Media Grid */}
        {selectedAlbum && (
          <Card>
            <CardHeader>
              <CardTitle>{selectedAlbum.name}</CardTitle>
              {selectedAlbum.description && (
                <p className="text-gray-600 text-sm">{selectedAlbum.description}</p>
              )}
            </CardHeader>
            <CardContent>
              {mediaItems.length === 0 ? (
                <div className="text-center py-12">
                  <div className="text-6xl mb-4">📸</div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">No photos yet</h3>
                  <p className="text-gray-600 mb-4">Start by uploading some photos to this album</p>
                  <Button onClick={() => setShowUpload(true)}>Upload Photos</Button>
                </div>
              ) : (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                  {mediaItems.map((item) => (
                    <div
                      key={item.id}
                      className="relative aspect-square bg-gray-200 rounded-lg overflow-hidden cursor-pointer hover:opacity-90 transition-opacity"
                      onClick={() => setSelectedImage(item)}
                    >
                      {item.media_type === 'photo' ? (
                        <img
                          src={item.url}
                          alt={item.caption || 'Wedding photo'}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center bg-gray-800">
                          <span className="text-white text-4xl">▶</span>
                        </div>
                      )}
                      {item.caption && (
                        <div className="absolute bottom-0 left-0 right-0 bg-black bg-opacity-50 text-white p-2 text-sm">
                          {item.caption}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {/* Create Album Modal */}
        <Modal
          isOpen={showCreateAlbum}
          onClose={() => setShowCreateAlbum(false)}
          title="Create New Album"
        >
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Album Name</label>
              <input
                type="text"
                value={albumName}
                onChange={(e) => setAlbumName(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
                placeholder="e.g., Mehendi Ceremony"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description (Optional)
              </label>
              <textarea
                value={albumDescription}
                onChange={(e) => setAlbumDescription(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
                rows={3}
                placeholder="Describe this album..."
              />
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowCreateAlbum(false)} className="flex-1">
                Cancel
              </Button>
              <Button onClick={handleCreateAlbum} className="flex-1">
                Create Album
              </Button>
            </div>
          </div>
        </Modal>

        {/* Upload Modal */}
        <Modal isOpen={showUpload} onClose={() => setShowUpload(false)} title="Upload Photos">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Select Files</label>
              <input
                type="file"
                accept="image/*,video/*"
                multiple
                onChange={handleFileUpload}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-400 focus:border-transparent"
              />
              <p className="text-xs text-gray-500 mt-1">
                Note: File upload requires Cloudinary configuration
              </p>
            </div>
            <Button variant="outline" onClick={() => setShowUpload(false)} className="w-full">
              Close
            </Button>
          </div>
        </Modal>

        {/* Image Viewer Modal */}
        {selectedImage && (
          <Modal
            isOpen={!!selectedImage}
            onClose={() => setSelectedImage(null)}
            title={selectedImage.caption || 'Photo'}
          >
            <div className="space-y-4">
              <img
                src={selectedImage.url}
                alt={selectedImage.caption || 'Wedding photo'}
                className="w-full rounded-lg"
              />
              {selectedImage.caption && (
                <p className="text-gray-700">{selectedImage.caption}</p>
              )}
              <p className="text-sm text-gray-500">
                Uploaded: {new Date(selectedImage.created_at).toLocaleDateString()}
              </p>
            </div>
          </Modal>
        )}
      </div>
    </Layout>
  )
}

export default GalleryPage
