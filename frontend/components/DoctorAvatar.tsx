'use client'

import { useState } from 'react'
import Image from 'next/image'
import { UserIcon } from '@heroicons/react/24/solid'

interface DoctorAvatarProps {
  src: string
  alt: string
  width: number
  height: number
  className?: string
}

export default function DoctorAvatar({ src, alt, width, height, className = '' }: DoctorAvatarProps) {
  const [imageError, setImageError] = useState(false)
  const [imageLoading, setImageLoading] = useState(true)

  if (imageError) {
    // Show placeholder when image fails to load
    return (
      <div 
        className={`bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center ${className}`}
        style={{ width, height }}
      >
        <UserIcon className="text-blue-400" style={{ width: width * 0.6, height: height * 0.6 }} />
      </div>
    )
  }

  return (
    <div className={`relative ${className}`} style={{ width, height }}>
      {imageLoading && (
        <div 
          className="absolute inset-0 bg-gradient-to-br from-gray-200 to-gray-300 animate-pulse rounded-full"
          style={{ width, height }}
        />
      )}
      <Image
        src={src}
        alt={alt}
        width={width}
        height={height}
        className={`${className} ${imageLoading ? 'opacity-0' : 'opacity-100'} transition-opacity duration-300`}
        onError={() => {
          setImageError(true)
          setImageLoading(false)
        }}
        onLoad={() => setImageLoading(false)}
        priority={width > 80} // Prioritize larger images
      />
    </div>
  )
}