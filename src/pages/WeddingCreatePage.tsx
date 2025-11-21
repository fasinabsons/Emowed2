import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { useAuth } from '../contexts/AuthContext'
import { supabase } from '../lib/supabase'
import { Layout } from '../components/Layout'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '../components/Card'
import { Button } from '../components/Button'
import { Input } from '../components/Input'
import { Modal } from '../components/Modal'

const weddingSchema = z.object({
  name: z.string().min(3, 'Wedding name must be at least 3 characters'),
  date: z.string().refine((date) => new Date(date) > new Date(), {
    message: 'Wedding date must be in the future',
  }),
  venue: z.string().min(3, 'Venue is required'),
  city: z.string().min(2, 'City is required'),
  mode: z.enum(['combined', 'separate']),
  guestLimit: z.number().min(1, 'Guest limit must be at least 1').optional(),
  budgetLimit: z.number().optional(),
})

type WeddingFormData = z.infer<typeof weddingSchema>

const WeddingCreatePage = () => {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [showSeparateWarning, setShowSeparateWarning] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    getValues,
  } = useForm<WeddingFormData>({
    resolver: zodResolver(weddingSchema),
    defaultValues: {
      mode: 'combined',
      guestLimit: 500,
    },
  })

  const selectedMode = watch('mode')

  const onSubmit = async (data: WeddingFormData) => {
    if (!user) return

    setLoading(true)
    try {
      // Use stored procedure to create wedding + auto-generate 7 events
      const { data: result, error } = await supabase.rpc('create_wedding_with_events', {
        p_user_id: user.id,
        p_name: data.name,
        p_date: data.date,
        p_venue: data.venue,
        p_city: data.city,
        p_mode: data.mode,
        p_budget_limit: data.budgetLimit || null,
        p_guest_limit: data.guestLimit || 500,
      })

      if (error) throw error

      // Check result
      if (result && result.length > 0) {
        const weddingResult = result[0]

        if (weddingResult.success) {
          toast.success(
            `Wedding created successfully with ${weddingResult.events_created} events!`,
            { duration: 4000 }
          )
          navigate('/dashboard')
        } else {
          toast.error(weddingResult.error_message || 'Failed to create wedding')
        }
      }
    } catch (error: any) {
      toast.error(error.message || 'Failed to create wedding')
    } finally {
      setLoading(false)
    }
  }

  const handleModeChange = (mode: 'combined' | 'separate') => {
    if (mode === 'separate') {
      setShowSeparateWarning(true)
    }
  }

  return (
    <Layout>
      <div className="max-w-3xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create Your Wedding</h1>
          <p className="text-gray-600 mt-2">Let's start planning your special day</p>
        </div>

        {/* Progress Steps */}
        <div className="flex items-center justify-center mb-8">
          {[1, 2, 3].map((s) => (
            <div key={s} className="flex items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold ${
                  step >= s
                    ? 'bg-primary-400 text-white'
                    : 'bg-gray-200 text-gray-600'
                }`}
              >
                {s}
              </div>
              {s < 3 && (
                <div
                  className={`w-24 h-1 mx-2 ${
                    step > s ? 'bg-primary-400' : 'bg-gray-200'
                  }`}
                />
              )}
            </div>
          ))}
        </div>

        <form onSubmit={handleSubmit(onSubmit)}>
          {step === 1 && (
            <Card>
              <CardHeader>
                <CardTitle>Step 1: Basic Details</CardTitle>
                <CardDescription>Tell us about your wedding</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <Input
                  {...register('name')}
                  label="Wedding Name"
                  placeholder="e.g., Priya & Rahul's Wedding"
                  error={errors.name?.message}
                  required
                />

                <Input
                  {...register('date')}
                  label="Wedding Date"
                  type="date"
                  error={errors.date?.message}
                  required
                />

                <Input
                  {...register('venue')}
                  label="Venue"
                  placeholder="e.g., Grand Palace Hotel"
                  error={errors.venue?.message}
                  required
                />

                <Input
                  {...register('city')}
                  label="City"
                  placeholder="e.g., Mumbai"
                  error={errors.city?.message}
                  required
                />

                <div className="flex justify-end pt-4">
                  <Button type="button" onClick={() => setStep(2)}>
                    Next Step
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {step === 2 && (
            <Card>
              <CardHeader>
                <CardTitle>Step 2: Wedding Mode</CardTitle>
                <CardDescription>Choose how you want to manage your wedding</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-4">
                  <label className="flex items-start p-4 border-2 border-primary-400 rounded-lg cursor-pointer bg-primary-50">
                    <input
                      {...register('mode')}
                      type="radio"
                      value="combined"
                      className="mt-1 mr-3"
                      defaultChecked
                    />
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900">Combined (Recommended)</p>
                      <p className="text-sm text-gray-600 mt-1">
                        Both families share vendors, venues, and costs. Save up to 50%!
                      </p>
                      <div className="flex gap-2 mt-2">
                        <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded">
                          Save Money
                        </span>
                        <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs rounded">
                          Simpler
                        </span>
                      </div>
                    </div>
                  </label>

                  <label className="flex items-start p-4 border-2 border-gray-200 rounded-lg cursor-pointer hover:border-gray-300">
                    <input
                      {...register('mode')}
                      type="radio"
                      value="separate"
                      className="mt-1 mr-3"
                      onChange={() => handleModeChange('separate')}
                    />
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900">Separate</p>
                      <p className="text-sm text-gray-600 mt-1">
                        Each family manages their own vendors and events separately
                      </p>
                      <div className="flex gap-2 mt-2">
                        <span className="px-2 py-1 bg-yellow-100 text-yellow-700 text-xs rounded">
                          2x Cost
                        </span>
                        <span className="px-2 py-1 bg-orange-100 text-orange-700 text-xs rounded">
                          More Complex
                        </span>
                      </div>
                    </div>
                  </label>
                </div>

                <Input
                  {...register('guestLimit', { valueAsNumber: true })}
                  label="Guest Limit (Optional)"
                  type="number"
                  placeholder="500"
                  error={errors.guestLimit?.message}
                  helperText="Maximum number of guests you want to invite"
                />

                <Input
                  {...register('budgetLimit', { valueAsNumber: true })}
                  label="Budget Limit (Optional)"
                  type="number"
                  placeholder="500000"
                  error={errors.budgetLimit?.message}
                  helperText="Total budget for your wedding in INR"
                />

                <div className="flex justify-between pt-4">
                  <Button type="button" variant="secondary" onClick={() => setStep(1)}>
                    Previous
                  </Button>
                  <Button type="button" onClick={() => setStep(3)}>
                    Next Step
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {step === 3 && (
            <Card>
              <CardHeader>
                <CardTitle>Step 3: Review & Confirm</CardTitle>
                <CardDescription>Review your wedding details before creating</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="flex justify-between py-2 border-b border-gray-200">
                    <span className="text-gray-600">Wedding Name</span>
                    <span className="font-medium">{getValues('name')}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-gray-200">
                    <span className="text-gray-600">Date</span>
                    <span className="font-medium">
                      {new Date(getValues('date')).toLocaleDateString()}
                    </span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-gray-200">
                    <span className="text-gray-600">Venue</span>
                    <span className="font-medium">{getValues('venue')}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-gray-200">
                    <span className="text-gray-600">City</span>
                    <span className="font-medium">{getValues('city')}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-gray-200">
                    <span className="text-gray-600">Mode</span>
                    <span className="font-medium capitalize">{getValues('mode')}</span>
                  </div>
                  <div className="flex justify-between py-2 border-b border-gray-200">
                    <span className="text-gray-600">Guest Limit</span>
                    <span className="font-medium">{getValues('guestLimit') || 500}</span>
                  </div>
                  {getValues('budgetLimit') && (
                    <div className="flex justify-between py-2 border-b border-gray-200">
                      <span className="text-gray-600">Budget</span>
                      <span className="font-medium">
                        ₹{getValues('budgetLimit')?.toLocaleString()}
                      </span>
                    </div>
                  )}
                </div>

                <div className="flex justify-between pt-4">
                  <Button type="button" variant="secondary" onClick={() => setStep(2)}>
                    Previous
                  </Button>
                  <Button type="submit" loading={loading}>
                    Create Wedding
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </form>

        {/* Separate Mode Warning Modal */}
        <Modal
          isOpen={showSeparateWarning}
          onClose={() => setShowSeparateWarning(false)}
          title="⚠️ Separate Mode Warning"
        >
          <div className="space-y-4">
            <p className="text-gray-700">
              With Separate mode, you'll need to:
            </p>
            <ul className="list-disc list-inside space-y-2 text-gray-600">
              <li>Book vendors separately for bride and groom sides</li>
              <li>Manage two separate budgets and payments</li>
              <li>Coordinate between two sets of vendors</li>
              <li>Pay approximately 2x the cost of Combined mode</li>
            </ul>
            <p className="text-gray-700 font-medium">
              We recommend Combined mode for most weddings as it saves money and reduces complexity.
            </p>
            <div className="flex gap-3">
              <Button
                variant="secondary"
                onClick={() => {
                  setShowSeparateWarning(false)
                  // Reset to combined
                }}
                className="flex-1"
              >
                Switch to Combined
              </Button>
              <Button
                onClick={() => setShowSeparateWarning(false)}
                className="flex-1"
              >
                Continue with Separate
              </Button>
            </div>
          </div>
        </Modal>
      </div>
    </Layout>
  )
}

export default WeddingCreatePage
