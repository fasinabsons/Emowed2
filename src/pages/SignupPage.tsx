import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import toast from 'react-hot-toast'
import { useAuth } from '../contexts/AuthContext'
import { Button } from '../components/Button'
import { Input } from '../components/Input'
import { Card } from '../components/Card'

const signupSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number')
    .regex(/[@$!%*?&]/, 'Password must contain at least one special character'),
  confirmPassword: z.string(),
  fullName: z.string().min(3, 'Full name must be at least 3 characters'),
  age: z.number().min(18, 'You must be at least 18 years old'),
  phone: z.string().optional(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
})

type SignupFormData = z.infer<typeof signupSchema>

const SignupPage = () => {
  const navigate = useNavigate()
  const { signUp } = useAuth()
  const [loading, setLoading] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<SignupFormData>({
    resolver: zodResolver(signupSchema),
  })

  const onSubmit = async (data: SignupFormData) => {
    setLoading(true)
    try {
      const { error } = await signUp(data.email, data.password, {
        full_name: data.fullName,
        age: data.age,
        phone: data.phone,
        relationship_status: 'single',
      })

      if (error) {
        toast.error(error.message || 'Signup failed')
      } else {
        toast.success('Account created! Please check your email to verify.')
        navigate('/login')
      }
    } catch (err) {
      toast.error('An unexpected error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-pink-50 to-white flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link to="/" className="text-3xl font-bold text-gradient">
            Emowed
          </Link>
          <h2 className="mt-4 text-2xl font-bold text-gray-900">Create your account</h2>
          <p className="mt-2 text-gray-600">Start your journey to forever</p>
        </div>

        <Card>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <Input
              {...register('fullName')}
              label="Full Name"
              placeholder="Enter your full name"
              error={errors.fullName?.message}
              required
            />

            <Input
              {...register('email')}
              label="Email"
              type="email"
              placeholder="you@example.com"
              error={errors.email?.message}
              required
            />

            <Input
              {...register('age', { valueAsNumber: true })}
              label="Age"
              type="number"
              placeholder="18"
              error={errors.age?.message}
              required
            />

            <Input
              {...register('phone')}
              label="Phone (Optional)"
              type="tel"
              placeholder="+91 98765 43210"
              error={errors.phone?.message}
            />

            <Input
              {...register('password')}
              label="Password"
              type="password"
              placeholder="Create a strong password"
              error={errors.password?.message}
              required
              helperText="Min 8 chars, 1 uppercase, 1 number, 1 special char"
            />

            <Input
              {...register('confirmPassword')}
              label="Confirm Password"
              type="password"
              placeholder="Confirm your password"
              error={errors.confirmPassword?.message}
              required
            />

            <Button type="submit" className="w-full" loading={loading}>
              Sign Up
            </Button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <Link to="/login" className="text-primary-400 hover:text-primary-500 font-medium">
                Login
              </Link>
            </p>
          </div>
        </Card>
      </div>
    </div>
  )
}

export default SignupPage
