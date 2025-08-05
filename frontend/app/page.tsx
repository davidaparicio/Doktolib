'use client'

import { useState, useEffect } from 'react'
import axios from 'axios'
import Link from 'next/link'
import Image from 'next/image'
import { MagnifyingGlassIcon, MapPinIcon, StarIcon } from '@heroicons/react/24/outline'
import { StarIcon as StarSolidIcon } from '@heroicons/react/24/solid'

interface Doctor {
  id: string
  name: string
  specialty: string
  location: string
  rating: number
  price_per_hour: number
  avatar: string
  experience_years: number
  languages: string
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'

export default function Home() {
  const [doctors, setDoctors] = useState<Doctor[]>([])
  const [loading, setLoading] = useState(true)
  const [searchSpecialty, setSearchSpecialty] = useState('')
  const [searchLocation, setSearchLocation] = useState('')

  const fetchDoctors = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams()
      if (searchSpecialty) params.append('specialty', searchSpecialty)
      if (searchLocation) params.append('location', searchLocation)
      
      const response = await axios.get(`${API_URL}/api/v1/doctors?${params}`)
      setDoctors(response.data || [])
    } catch (error) {
      console.error('Error fetching doctors:', error)
      setDoctors([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const loadInitialDoctors = async () => {
      try {
        setLoading(true)
        const response = await axios.get(`${API_URL}/api/v1/doctors`)
        setDoctors(response.data || [])
      } catch (error) {
        console.error('Error fetching doctors:', error)
        setDoctors([])
      } finally {
        setLoading(false)
      }
    }
    
    loadInitialDoctors()
  }, [])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    fetchDoctors()
  }

  const renderStars = (rating: number) => {
    const stars = []
    const fullStars = Math.floor(rating)
    const hasHalfStar = rating % 1 !== 0

    for (let i = 0; i < fullStars; i++) {
      stars.push(
        <StarSolidIcon key={i} className="h-4 w-4 text-yellow-400" />
      )
    }
    
    if (hasHalfStar) {
      stars.push(
        <StarIcon key="half" className="h-4 w-4 text-yellow-400" />
      )
    }
    
    const emptyStars = 5 - Math.ceil(rating)
    for (let i = 0; i < emptyStars; i++) {
      stars.push(
        <StarIcon key={`empty-${i}`} className="h-4 w-4 text-gray-300" />
      )
    }
    
    return stars
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center">
              <h1 className="text-3xl font-bold text-doctolib-darkblue">Doktolib</h1>
            </div>
            <nav className="hidden md:flex space-x-8">
              <a href="#" className="text-gray-700 hover:text-doctolib-darkblue">Find a Doctor</a>
              <a href="#" className="text-gray-700 hover:text-doctolib-darkblue">Teleconsultation</a>
              <a href="#" className="text-gray-700 hover:text-doctolib-darkblue">Sign In</a>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="bg-gradient-to-r from-doctolib-blue to-doctolib-darkblue py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-4xl font-bold text-white mb-4">
              Find and Book Your Medical Appointment
            </h2>
            <p className="text-xl text-blue-100 mb-8">
              Over 10,000 healthcare professionals are waiting for you
            </p>
            
            {/* Search Form */}
            <form onSubmit={handleSearch} className="max-w-4xl mx-auto">
              <div className="bg-white rounded-lg shadow-lg p-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="relative">
                    <MagnifyingGlassIcon className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Specialty, condition..."
                      className="input-field pl-10"
                      value={searchSpecialty}
                      onChange={(e) => setSearchSpecialty(e.target.value)}
                    />
                  </div>
                  <div className="relative">
                    <MapPinIcon className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Where? (city, postal code...)"
                      className="input-field pl-10"
                      value={searchLocation}
                      onChange={(e) => setSearchLocation(e.target.value)}
                    />
                  </div>
                  <button type="submit" className="btn-primary w-full">
                    Search
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </section>

      {/* Doctors List */}
      <section className="py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h3 className="text-2xl font-bold text-gray-900 mb-8">
            {doctors.length > 0 ? `${doctors.length} doctor${doctors.length > 1 ? 's' : ''} found` : 'Available doctors'}
          </h3>
          
          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="card animate-pulse">
                  <div className="flex items-start space-x-4">
                    <div className="w-16 h-16 bg-gray-200 rounded-full"></div>
                    <div className="flex-1 space-y-2">
                      <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                      <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                      <div className="h-3 bg-gray-200 rounded w-2/3"></div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : doctors.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {doctors.map((doctor) => (
                <div key={doctor.id} className="card hover:shadow-md transition-shadow duration-200">
                  <div className="flex items-start space-x-4 mb-4">
                    <Image
                      src={doctor.avatar}
                      alt={doctor.name}
                      width={64}
                      height={64}
                      className="rounded-full object-cover"
                    />
                    <div className="flex-1">
                      <h4 className="text-lg font-semibold text-gray-900">{doctor.name}</h4>
                      <p className="text-doctolib-darkblue font-medium">{doctor.specialty}</p>
                      <p className="text-gray-600 text-sm flex items-center">
                        <MapPinIcon className="h-4 w-4 mr-1" />
                        {doctor.location}
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center space-x-1">
                      {renderStars(doctor.rating)}
                      <span className="text-sm text-gray-600 ml-1">({doctor.rating})</span>
                    </div>
                    <span className="text-lg font-semibold text-gray-900">{doctor.price_per_hour}€</span>
                  </div>
                  
                  <div className="text-sm text-gray-600 mb-4">
                    <p>{doctor.experience_years} years of experience</p>
                    <p>Languages: {doctor.languages}</p>
                  </div>
                  
                  <Link href={`/doctor/${doctor.id}`} className="btn-primary w-full text-center block">
                    Book appointment
                  </Link>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12">
              <p className="text-gray-600">No doctors found for your search.</p>
            </div>
          )}
        </div>
      </section>
    </div>
  )
}