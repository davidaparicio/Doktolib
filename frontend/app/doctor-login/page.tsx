'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import axios from 'axios'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { ArrowLeftIcon, UserCircleIcon } from '@heroicons/react/24/outline'
import DoctorAvatar from '../../components/DoctorAvatar'

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

export default function DoctorLogin() {
  const router = useRouter()
  const [doctors, setDoctors] = useState<Doctor[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  const fetchDoctors = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_URL}/api/v1/doctors`)
      setDoctors(response.data || [])
    } catch (error) {
      console.error('Error fetching doctors:', error)
      toast.error('Error loading doctors')
      setDoctors([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchDoctors()
  }, [])

  const filteredDoctors = doctors.filter(doctor =>
    doctor.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    doctor.specialty.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const handleDoctorSelect = (doctorId: string) => {
    router.push(`/doctor-dashboard/${doctorId}`)
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-6">
            <div className="flex items-center">
              <Link
                href="/"
                className="flex items-center text-gray-600 hover:text-doctolib-darkblue mr-6"
              >
                <ArrowLeftIcon className="h-5 w-5 mr-2" />
                Back to Home
              </Link>
              <div>
                <h1 className="text-3xl font-bold text-doctolib-darkblue">Doctor Login</h1>
                <p className="text-gray-600">Select your profile to access your dashboard</p>
              </div>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Search */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-8">
          <div className="max-w-md">
            <label htmlFor="search" className="block text-sm font-medium text-gray-700 mb-2">
              Search Doctors
            </label>
            <input
              type="text"
              id="search"
              className="input-field"
              placeholder="Search by name or specialty..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        {/* Doctors Grid */}
        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-doctolib-blue mx-auto mb-4"></div>
            <p className="text-gray-600">Loading doctors...</p>
          </div>
        ) : filteredDoctors.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredDoctors.map((doctor) => (
              <div key={doctor.id} className="card hover:shadow-lg transition-shadow duration-200">
                <div className="flex items-center space-x-4 mb-4">
                  <DoctorAvatar
                    src={doctor.avatar}
                    alt={doctor.name}
                    width={60}
                    height={60}
                    className="rounded-full object-cover"
                  />
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-gray-900">{doctor.name}</h3>
                    <p className="text-doctolib-darkblue font-medium">{doctor.specialty}</p>
                    <p className="text-gray-600 text-sm">{doctor.location}</p>
                  </div>
                </div>
                
                <div className="text-sm text-gray-600 mb-4">
                  <p>{doctor.experience_years} years of experience</p>
                  <p>Rating: {doctor.rating}/5 ⭐</p>
                </div>
                
                <button
                  onClick={() => handleDoctorSelect(doctor.id)}
                  className="btn-primary w-full flex items-center justify-center"
                >
                  <UserCircleIcon className="h-5 w-5 mr-2" />
                  Access Dashboard
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-12">
            <UserCircleIcon className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-600">No doctors found matching your search.</p>
          </div>
        )}
      </div>
    </div>
  )
}