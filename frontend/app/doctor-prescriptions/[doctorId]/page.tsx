'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import axios from 'axios'
import Link from 'next/link'
import toast from 'react-hot-toast'
import { 
  ArrowLeftIcon, 
  MagnifyingGlassIcon,
  DocumentTextIcon,
  CalendarDaysIcon,
  ClockIcon,
  UserIcon,
  BeakerIcon
} from '@heroicons/react/24/outline'
import { format } from 'date-fns'
import { enUS } from 'date-fns/locale'

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

interface PrescriptionWithAppointment {
  id: string
  appointment_id: string
  doctor_id: string
  patient_name: string
  medications: string
  dosage: string
  instructions: string
  created_at: string
  appointment_date: string
  appointment_duration: number
  appointment_status: string
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'

export default function DoctorPrescriptions() {
  const params = useParams()
  const router = useRouter()
  const doctorId = params.doctorId as string
  
  const [doctor, setDoctor] = useState<Doctor | null>(null)
  const [prescriptions, setPrescriptions] = useState<PrescriptionWithAppointment[]>([])
  const [loading, setLoading] = useState(true)
  const [searchPatient, setSearchPatient] = useState('')
  const [searchMedication, setSearchMedication] = useState('')

  const fetchDoctor = async () => {
    try {
      const response = await axios.get(`${API_URL}/api/v1/doctors/${doctorId}`)
      setDoctor(response.data)
    } catch (error) {
      console.error('Error fetching doctor:', error)
      toast.error('Error loading doctor information')
    }
  }

  const fetchPrescriptions = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams()
      if (searchPatient) params.append('patient', searchPatient)
      if (searchMedication) params.append('medication', searchMedication)
      
      const response = await axios.get(`${API_URL}/api/v1/prescriptions/doctor/${doctorId}?${params}`)
      setPrescriptions(response.data || [])
    } catch (error) {
      console.error('Error fetching prescriptions:', error)
      toast.error('Error loading prescriptions')
      setPrescriptions([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (doctorId) {
      fetchDoctor()
      fetchPrescriptions()
    }
  }, [doctorId]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    fetchPrescriptions()
  }

  const clearSearch = () => {
    setSearchPatient('')
    setSearchMedication('')
    // Trigger fetch with empty search
    setTimeout(() => fetchPrescriptions(), 100)
  }

  const groupPrescriptionsByPatient = () => {
    const grouped: { [key: string]: PrescriptionWithAppointment[] } = {}
    prescriptions.forEach(prescription => {
      const patientName = prescription.patient_name
      if (!grouped[patientName]) {
        grouped[patientName] = []
      }
      grouped[patientName].push(prescription)
    })
    return grouped
  }

  const getUniquePatients = () => {
    const patients = new Set(prescriptions.map(p => p.patient_name))
    return Array.from(patients).length
  }

  const getUniqueMedications = () => {
    const medications = new Set(prescriptions.map(p => p.medications))
    return Array.from(medications).length
  }

  const getRecentPrescriptions = () => {
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    return prescriptions.filter(p => new Date(p.created_at) > thirtyDaysAgo).length
  }

  if (!doctor) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-doctolib-blue"></div>
      </div>
    )
  }

  const groupedPrescriptions = groupPrescriptionsByPatient()

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-6">
            <div className="flex items-center">
              <Link
                href={`/doctor-dashboard/${doctorId}`}
                className="flex items-center text-gray-600 hover:text-doctolib-darkblue mr-6"
              >
                <ArrowLeftIcon className="h-5 w-5 mr-2" />
                Back to Dashboard
              </Link>
              <div>
                <h1 className="text-3xl font-bold text-doctolib-darkblue">My Prescriptions</h1>
                <p className="text-gray-600">Dr. {doctor.name} - {doctor.specialty}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-600">{doctor.location}</p>
              <p className="text-sm text-doctolib-blue font-medium">
                {prescriptions.length} Total Prescriptions
              </p>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="card text-center">
            <div className="text-2xl font-bold text-doctolib-darkblue">{prescriptions.length}</div>
            <div className="text-gray-600 flex items-center justify-center">
              <DocumentTextIcon className="h-4 w-4 mr-1" />
              Total Prescriptions
            </div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold text-green-600">{getUniquePatients()}</div>
            <div className="text-gray-600 flex items-center justify-center">
              <UserIcon className="h-4 w-4 mr-1" />
              Unique Patients
            </div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold text-blue-600">{getUniqueMedications()}</div>
            <div className="text-gray-600 flex items-center justify-center">
              <BeakerIcon className="h-4 w-4 mr-1" />
              Different Medications
            </div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold text-orange-600">{getRecentPrescriptions()}</div>
            <div className="text-gray-600">Last 30 Days</div>
          </div>
        </div>

        {/* Search */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h3 className="text-lg font-semibold mb-4">Search Prescriptions</h3>
          <form onSubmit={handleSearch} className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
              <input
                type="text"
                className="input-field pl-10"
                placeholder="Search by patient name..."
                value={searchPatient}
                onChange={(e) => setSearchPatient(e.target.value)}
              />
            </div>
            <div className="relative">
              <BeakerIcon className="absolute left-3 top-3 h-5 w-5 text-gray-400" />
              <input
                type="text"
                className="input-field pl-10"
                placeholder="Search by medication..."
                value={searchMedication}
                onChange={(e) => setSearchMedication(e.target.value)}
              />
            </div>
            <div className="flex space-x-2">
              <button type="submit" className="btn-primary flex-1">
                Search
              </button>
              <button 
                type="button" 
                onClick={clearSearch}
                className="btn-secondary"
              >
                Clear
              </button>
            </div>
          </form>
        </div>

        {/* Prescriptions List */}
        <div className="bg-white rounded-lg shadow-sm">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold">
              Prescriptions {searchPatient || searchMedication ? '(Filtered)' : ''}
              {` (${prescriptions.length})`}
            </h3>
          </div>
          
          {loading ? (
            <div className="p-12 text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-doctolib-blue mx-auto"></div>
              <p className="mt-4 text-gray-600">Loading prescriptions...</p>
            </div>
          ) : prescriptions.length > 0 ? (
            <div className="divide-y divide-gray-200">
              {prescriptions.map((prescription) => {
                const prescriptionDate = new Date(prescription.created_at)
                const appointmentDate = new Date(prescription.appointment_date)
                
                return (
                  <div key={prescription.id} className="p-6 hover:bg-gray-50 transition-colors">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <div className="flex items-center mb-2">
                          <UserIcon className="h-5 w-5 text-gray-400 mr-2" />
                          <h4 className="text-lg font-semibold text-gray-900">
                            {prescription.patient_name}
                          </h4>
                          <span className="ml-3 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <DocumentTextIcon className="h-3 w-3 mr-1" />
                            Prescribed
                          </span>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-600 mb-4">
                          <div className="flex items-center">
                            <CalendarDaysIcon className="h-4 w-4 mr-2" />
                            Prescribed: {format(prescriptionDate, 'MMMM d, yyyy', { locale: enUS })}
                          </div>
                          <div className="flex items-center">
                            <ClockIcon className="h-4 w-4 mr-2" />
                            Appointment: {format(appointmentDate, 'MMMM d, yyyy', { locale: enUS })}
                          </div>
                        </div>
                      </div>
                      
                      <div className="ml-6 text-right text-sm text-gray-500">
                        ID: {prescription.id.slice(0, 8)}...
                      </div>
                    </div>
                    
                    {/* Prescription Details */}
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
                        <div>
                          <h5 className="font-semibold text-blue-900 mb-2 flex items-center">
                            <BeakerIcon className="h-4 w-4 mr-2" />
                            Medication
                          </h5>
                          <p className="text-blue-800 font-medium">{prescription.medications}</p>
                        </div>
                        
                        <div>
                          <h5 className="font-semibold text-blue-900 mb-2">Dosage</h5>
                          <p className="text-blue-800">{prescription.dosage}</p>
                        </div>
                        
                        <div className="lg:col-span-1">
                          <h5 className="font-semibold text-blue-900 mb-2">Instructions</h5>
                          <p className="text-blue-800 text-sm">
                            {prescription.instructions || 'No special instructions'}
                          </p>
                        </div>
                      </div>
                      
                      {/* Appointment Reference */}
                      <div className="mt-4 pt-4 border-t border-blue-200">
                        <div className="text-sm text-blue-700">
                          <span className="font-medium">Related Appointment:</span>
                          <span className="ml-2">
                            {format(appointmentDate, 'MMM d, yyyy')} • 
                            {prescription.appointment_duration}min • 
                            {prescription.appointment_status}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="p-12 text-center">
              <DocumentTextIcon className="h-12 w-12 text-gray-300 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No prescriptions found</h3>
              <p className="text-gray-600">
                {searchPatient || searchMedication 
                  ? 'No prescriptions match your search criteria.' 
                  : 'You haven\'t created any prescriptions yet.'}
              </p>
              {(searchPatient || searchMedication) && (
                <button 
                  onClick={clearSearch}
                  className="mt-4 btn-secondary"
                >
                  Clear Search
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}