'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import {
  VideoCameraIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon,
  SignalIcon,
  GlobeAltIcon
} from '@heroicons/react/24/outline'

interface VisioHealthResponse {
  status: string
  service: string
  timestamp: string
  checks?: {
    api: string
    websocket: string
    streaming: string
  }
}

export default function TeleconsultationPage() {
  const [healthData, setHealthData] = useState<VisioHealthResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const VISIO_HEALTH_URL = process.env.NEXT_PUBLIC_VISIO_HEALTH_URL

  useEffect(() => {
    const checkVisioHealth = async () => {
      if (!VISIO_HEALTH_URL) {
        setError('Visio service not configured')
        setLoading(false)
        return
      }

      try {
        const response = await fetch(VISIO_HEALTH_URL, {
          method: 'GET',
          cache: 'no-store',
        })

        if (response.ok) {
          const data: VisioHealthResponse = await response.json()
          setHealthData(data)
          setError(null)
        } else {
          setError('Service unavailable')
        }
      } catch (err) {
        setError('Failed to connect to visio service')
      } finally {
        setLoading(false)
      }
    }

    checkVisioHealth()
    // Refresh every 10 seconds
    const interval = setInterval(checkVisioHealth, 10000)

    return () => clearInterval(interval)
  }, [VISIO_HEALTH_URL])

  const isHealthy = healthData?.status === 'healthy'

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center">
              <Link href="/">
                <h1 className="text-3xl font-bold text-doctolib-darkblue cursor-pointer">Doktolib</h1>
              </Link>
            </div>
            <nav className="hidden md:flex space-x-8">
              <Link href="/" className="text-gray-700 hover:text-doctolib-darkblue">Find a Doctor</Link>
              <a href="#" className="text-doctolib-darkblue font-semibold">Teleconsultation</a>
              <Link href="/files" className="text-gray-700 hover:text-doctolib-darkblue">Medical Files</Link>
              <Link href="/doctor-login" className="text-gray-700 hover:text-doctolib-darkblue">Doctor Login</Link>
              <a href="#" className="text-gray-700 hover:text-doctolib-darkblue">Sign In</a>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="bg-gradient-to-r from-doctolib-blue to-doctolib-darkblue py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <VideoCameraIcon className="h-20 w-20 text-white mx-auto mb-6" />
            <h2 className="text-4xl font-bold text-white mb-4">
              Video Consultation Service
            </h2>
            <p className="text-xl text-blue-100 mb-8">
              Consult with doctors from the comfort of your home
            </p>
          </div>
        </div>
      </section>

      {/* Service Status Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h3 className="text-2xl font-bold text-gray-900 mb-6">Service Status</h3>

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-doctolib-blue"></div>
              <span className="ml-4 text-gray-600">Checking service status...</span>
            </div>
          ) : error ? (
            <div className="bg-red-50 border-l-4 border-red-500 p-6 rounded-lg">
              <div className="flex items-center">
                <XCircleIcon className="h-8 w-8 text-red-500 mr-3" />
                <div>
                  <h4 className="text-lg font-semibold text-red-900">Service Unavailable</h4>
                  <p className="text-red-700 mt-1">{error}</p>
                </div>
              </div>
            </div>
          ) : (
            <div className={`${isHealthy ? 'bg-green-50 border-green-500' : 'bg-red-50 border-red-500'} border-l-4 p-6 rounded-lg`}>
              <div className="flex items-center mb-6">
                {isHealthy ? (
                  <CheckCircleIcon className="h-8 w-8 text-green-500 mr-3" />
                ) : (
                  <XCircleIcon className="h-8 w-8 text-red-500 mr-3" />
                )}
                <div>
                  <h4 className="text-lg font-semibold text-gray-900">
                    {isHealthy ? 'Service Online' : 'Service Offline'}
                  </h4>
                  <p className="text-gray-600 text-sm mt-1">
                    Service: {healthData?.service || 'Unknown'}
                  </p>
                </div>
              </div>

              {/* System Checks */}
              {healthData?.checks && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
                  <div className="bg-white rounded-lg p-4 shadow-sm">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <GlobeAltIcon className="h-6 w-6 text-doctolib-blue mr-2" />
                        <span className="font-medium text-gray-700">API</span>
                      </div>
                      <span className={`px-3 py-1 rounded-full text-sm font-semibold ${
                        healthData.checks.api === 'ok' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {healthData.checks.api === 'ok' ? 'OK' : 'Error'}
                      </span>
                    </div>
                  </div>

                  <div className="bg-white rounded-lg p-4 shadow-sm">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <SignalIcon className="h-6 w-6 text-doctolib-blue mr-2" />
                        <span className="font-medium text-gray-700">WebSocket</span>
                      </div>
                      <span className={`px-3 py-1 rounded-full text-sm font-semibold ${
                        healthData.checks.websocket === 'ok' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {healthData.checks.websocket === 'ok' ? 'OK' : 'Error'}
                      </span>
                    </div>
                  </div>

                  <div className="bg-white rounded-lg p-4 shadow-sm">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <VideoCameraIcon className="h-6 w-6 text-doctolib-blue mr-2" />
                        <span className="font-medium text-gray-700">Streaming</span>
                      </div>
                      <span className={`px-3 py-1 rounded-full text-sm font-semibold ${
                        healthData.checks.streaming === 'ok' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                      }`}>
                        {healthData.checks.streaming === 'ok' ? 'OK' : 'Error'}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Timestamp */}
              {healthData?.timestamp && (
                <div className="mt-6 flex items-center text-sm text-gray-600">
                  <ClockIcon className="h-5 w-5 mr-2" />
                  Last checked: {new Date(healthData.timestamp).toLocaleString()}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Features Section */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="bg-doctolib-blue rounded-full w-12 h-12 flex items-center justify-center mb-4">
              <VideoCameraIcon className="h-6 w-6 text-white" />
            </div>
            <h4 className="text-lg font-semibold text-gray-900 mb-2">HD Video Quality</h4>
            <p className="text-gray-600">
              Crystal clear video consultations with your doctor in high definition
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="bg-doctolib-blue rounded-full w-12 h-12 flex items-center justify-center mb-4">
              <CheckCircleIcon className="h-6 w-6 text-white" />
            </div>
            <h4 className="text-lg font-semibold text-gray-900 mb-2">Secure & Private</h4>
            <p className="text-gray-600">
              End-to-end encrypted consultations ensuring your privacy and security
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="bg-doctolib-blue rounded-full w-12 h-12 flex items-center justify-center mb-4">
              <ClockIcon className="h-6 w-6 text-white" />
            </div>
            <h4 className="text-lg font-semibold text-gray-900 mb-2">Available 24/7</h4>
            <p className="text-gray-600">
              Book video consultations anytime, day or night, at your convenience
            </p>
          </div>
        </div>

        {/* CTA Section */}
        <div className="mt-12 bg-gradient-to-r from-doctolib-blue to-doctolib-darkblue rounded-lg shadow-lg p-8 text-center">
          <h3 className="text-2xl font-bold text-white mb-4">
            Ready for your video consultation?
          </h3>
          <p className="text-blue-100 mb-6">
            Find a doctor and book your teleconsultation appointment today
          </p>
          <Link
            href="/"
            className="inline-block bg-white text-doctolib-darkblue px-8 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
          >
            Find a Doctor
          </Link>
        </div>
      </section>
    </div>
  )
}
