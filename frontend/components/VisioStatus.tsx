'use client'

import { useState, useEffect } from 'react'
import { VideoCameraIcon } from '@heroicons/react/24/outline'

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

export default function VisioStatus() {
  const [status, setStatus] = useState<'healthy' | 'unhealthy' | 'loading' | 'unavailable'>('loading')
  const [showTooltip, setShowTooltip] = useState(false)

  const VISIO_HEALTH_URL = process.env.NEXT_PUBLIC_VISIO_HEALTH_URL

  useEffect(() => {
    const checkVisioHealth = async () => {
      if (!VISIO_HEALTH_URL) {
        setStatus('unavailable')
        return
      }

      try {
        const response = await fetch(VISIO_HEALTH_URL, {
          method: 'GET',
          cache: 'no-store',
        })

        if (response.ok) {
          const data: VisioHealthResponse = await response.json()
          if (data.status === 'healthy') {
            setStatus('healthy')
          } else {
            setStatus('unhealthy')
          }
        } else {
          setStatus('unhealthy')
        }
      } catch (error) {
        console.error('Error checking visio health:', error)
        setStatus('unhealthy')
      }
    }

    checkVisioHealth()
    // Check every 30 seconds
    const interval = setInterval(checkVisioHealth, 30000)

    return () => clearInterval(interval)
  }, [VISIO_HEALTH_URL])

  if (status === 'unavailable') {
    return null // Don't show if not configured
  }

  const getStatusColor = () => {
    switch (status) {
      case 'healthy':
        return 'text-green-500'
      case 'unhealthy':
        return 'text-red-500'
      case 'loading':
        return 'text-gray-400'
      default:
        return 'text-gray-400'
    }
  }

  const getStatusText = () => {
    switch (status) {
      case 'healthy':
        return 'Visio Service: Online'
      case 'unhealthy':
        return 'Visio Service: Offline'
      case 'loading':
        return 'Visio Service: Checking...'
      default:
        return 'Visio Service: Unknown'
    }
  }

  const getStatusDot = () => {
    switch (status) {
      case 'healthy':
        return 'bg-green-500'
      case 'unhealthy':
        return 'bg-red-500'
      case 'loading':
        return 'bg-gray-400 animate-pulse'
      default:
        return 'bg-gray-400'
    }
  }

  return (
    <div
      className="relative inline-flex items-center space-x-2 px-3 py-1.5 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors cursor-pointer"
      onMouseEnter={() => setShowTooltip(true)}
      onMouseLeave={() => setShowTooltip(false)}
    >
      <VideoCameraIcon className={`h-5 w-5 ${getStatusColor()}`} />
      <div className={`h-2 w-2 rounded-full ${getStatusDot()}`} />
      <span className="text-sm font-medium text-gray-700">Visio</span>

      {/* Tooltip */}
      {showTooltip && (
        <div className="absolute top-full mt-2 right-0 z-50 px-3 py-2 bg-gray-900 text-white text-xs rounded-md shadow-lg whitespace-nowrap">
          {getStatusText()}
          <div className="absolute bottom-full right-4 w-0 h-0 border-l-4 border-r-4 border-b-4 border-transparent border-b-gray-900" />
        </div>
      )}
    </div>
  )
}
