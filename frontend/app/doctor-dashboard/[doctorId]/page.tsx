'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import axios from 'axios'
import toast from 'react-hot-toast'
import { 
  ArrowLeftIcon, 
  CalendarDaysIcon,
  ClockIcon,
  UserIcon,
  PlusIcon,
  DocumentTextIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline'
import { format, isToday, isPast, isFuture } from 'date-fns'
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

interface Prescription {
  id: string
  appointment_id: string
  doctor_id: string
  patient_name: string
  medications: string
  dosage: string
  instructions: string
  created_at: string
}

interface Appointment {
  id: string
  doctor_id: string
  patient_name: string
  patient_email: string
  date_time: string
  duration_minutes: number
  status: string
  created_at: string
  prescription?: Prescription
}

interface PrescriptionForm {
  medications: string
  dosage: string
  instructions: string
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080'

export default function DoctorDashboard() {
  const params = useParams()
  const router = useRouter()
  const doctorId = params.doctorId as string
  
  const [doctor, setDoctor] = useState<Doctor | null>(null)
  const [appointments, setAppointments] = useState<Appointment[]>([])
  const [loading, setLoading] = useState(true)
  const [activeFilter, setActiveFilter] = useState<'all' | 'today' | 'past' | 'future'>('all')
  const [showPrescriptionModal, setShowPrescriptionModal] = useState(false)
  const [selectedAppointment, setSelectedAppointment] = useState<Appointment | null>(null)
  const [prescriptionForm, setPrescriptionForm] = useState<PrescriptionForm>({
    medications: '',
    dosage: '',
    instructions: ''
  })
  const [submitting, setSubmitting] = useState(false)

  const fetchDoctor = async () => {
    try {
      const response = await axios.get(`${API_URL}/api/v1/doctors/${doctorId}`)
      setDoctor(response.data)
    } catch (error) {
      console.error('Error fetching doctor:', error)
      toast.error('Error loading doctor information')
    }
  }

  const fetchAppointments = async (filter: string = 'all') => {
    try {
      setLoading(true)
      const params = filter !== 'all' ? `?filter=${filter}` : ''
      const response = await axios.get(`${API_URL}/api/v1/doctors/${doctorId}/appointments${params}`)
      setAppointments(response.data || [])
    } catch (error) {
      console.error('Error fetching appointments:', error)
      toast.error('Error loading appointments')
      setAppointments([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (doctorId) {
      fetchDoctor()
      fetchAppointments(activeFilter)
    }
  }, [doctorId, activeFilter]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleFilterChange = (filter: 'all' | 'today' | 'past' | 'future') => {
    setActiveFilter(filter)
  }

  const openPrescriptionModal = (appointment: Appointment) => {
    setSelectedAppointment(appointment)
    setShowPrescriptionModal(true)
    setPrescriptionForm({
      medications: appointment.prescription?.medications || '',
      dosage: appointment.prescription?.dosage || '',
      instructions: appointment.prescription?.instructions || ''
    })
  }

  const closePrescriptionModal = () => {
    setShowPrescriptionModal(false)
    setSelectedAppointment(null)
    setPrescriptionForm({ medications: '', dosage: '', instructions: '' })
  }

  const handlePrescriptionSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!selectedAppointment || !prescriptionForm.medications || !prescriptionForm.dosage) {
      toast.error('Please fill in medications and dosage')
      return
    }

    setSubmitting(true)
    
    try {
      const prescriptionData = {
        appointment_id: selectedAppointment.id,
        medications: prescriptionForm.medications,
        dosage: prescriptionForm.dosage,
        instructions: prescriptionForm.instructions
      }
      
      await axios.post(`${API_URL}/api/v1/prescriptions`, prescriptionData)
      toast.success('Prescription created successfully!')
      
      // Refresh appointments to show the new prescription
      await fetchAppointments(activeFilter)
      closePrescriptionModal()
      
    } catch (error) {
      console.error('Error creating prescription:', error)
      toast.error('Error creating prescription')
    } finally {
      setSubmitting(false)
    }
  }

  const getAppointmentStatus = (appointment: Appointment) => {
    const appointmentDate = new Date(appointment.date_time)
    
    if (appointment.status === 'cancelled') {
      return { color: 'text-red-600 bg-red-50', icon: XCircleIcon, text: 'Cancelled' }
    }
    
    if (appointment.status === 'completed') {
      return { color: 'text-green-600 bg-green-50', icon: CheckCircleIcon, text: 'Completed' }
    }
    
    if (isToday(appointmentDate)) {
      return { color: 'text-blue-600 bg-blue-50', icon: ExclamationTriangleIcon, text: 'Today' }
    }
    
    if (isPast(appointmentDate)) {
      return { color: 'text-gray-600 bg-gray-50', icon: ClockIcon, text: 'Past' }
    }
    
    return { color: 'text-orange-600 bg-orange-50', icon: CalendarDaysIcon, text: 'Upcoming' }
  }

  const getFilteredAppointments = () => {
    if (activeFilter === 'all') return appointments
    
    return appointments.filter(appointment => {
      const appointmentDate = new Date(appointment.date_time)
      
      switch (activeFilter) {
        case 'today':
          return isToday(appointmentDate)
        case 'past':
          return isPast(appointmentDate) && !isToday(appointmentDate)
        case 'future':
          return isFuture(appointmentDate)
        default:
          return true
      }
    })
  }

  const getAppointmentCounts = () => {
    const today = appointments.filter(apt => isToday(new Date(apt.date_time))).length
    const past = appointments.filter(apt => isPast(new Date(apt.date_time)) && !isToday(new Date(apt.date_time))).length
    const future = appointments.filter(apt => isFuture(new Date(apt.date_time))).length
    
    return { today, past, future, total: appointments.length }
  }

  if (!doctor) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-doctolib-blue"></div>
      </div>
    )
  }

  const filteredAppointments = getFilteredAppointments()
  const counts = getAppointmentCounts()

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between py-6">
            <div className="flex items-center">
              <button
                onClick={() => router.push('/')}
                className="flex items-center text-gray-600 hover:text-doctolib-darkblue mr-6"
              >
                <ArrowLeftIcon className="h-5 w-5 mr-2" />
                Back to Home
              </button>
              <div>
                <h1 className="text-3xl font-bold text-doctolib-darkblue">Doctor Dashboard</h1>
                <p className="text-gray-600">Welcome, Dr. {doctor.name}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm text-gray-600">{doctor.specialty}</p>
              <p className="text-sm text-gray-600">{doctor.location}</p>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="card text-center">
            <div className="text-2xl font-bold text-doctolib-darkblue">{counts.total}</div>
            <div className="text-gray-600">Total Appointments</div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold text-blue-600">{counts.today}</div>
            <div className="text-gray-600">Today</div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold text-green-600">{counts.past}</div>
            <div className="text-gray-600">Completed</div>
          </div>
          <div className="card text-center">
            <div className="text-2xl font-bold text-orange-600">{counts.future}</div>
            <div className="text-gray-600">Upcoming</div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <h3 className="text-lg font-semibold mb-4">Filter Appointments</h3>
          <div className="flex flex-wrap gap-2">
            {[
              { key: 'all', label: `All (${counts.total})` },
              { key: 'today', label: `Today (${counts.today})` },
              { key: 'future', label: `Upcoming (${counts.future})` },
              { key: 'past', label: `Past (${counts.past})` }
            ].map((filter) => (
              <button
                key={filter.key}
                onClick={() => handleFilterChange(filter.key as any)}
                className={`px-4 py-2 rounded-lg border text-sm font-medium transition-colors ${
                  activeFilter === filter.key
                    ? 'bg-doctolib-blue text-white border-doctolib-blue'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-doctolib-blue'
                }`}
              >
                {filter.label}
              </button>
            ))}
          </div>
        </div>

        {/* Appointments List */}
        <div className="bg-white rounded-lg shadow-sm">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold">
              {activeFilter === 'all' ? 'All Appointments' : 
               activeFilter === 'today' ? 'Today\'s Appointments' :
               activeFilter === 'past' ? 'Past Appointments' : 'Upcoming Appointments'}
              {` (${filteredAppointments.length})`}
            </h3>
          </div>
          
          {loading ? (
            <div className="p-12 text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-doctolib-blue mx-auto"></div>
              <p className="mt-4 text-gray-600">Loading appointments...</p>
            </div>
          ) : filteredAppointments.length > 0 ? (
            <div className="divide-y divide-gray-200">
              {filteredAppointments.map((appointment) => {
                const status = getAppointmentStatus(appointment)
                const StatusIcon = status.icon
                const appointmentDate = new Date(appointment.date_time)
                
                return (
                  <div key={appointment.id} className="p-6 hover:bg-gray-50 transition-colors">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center mb-2">
                          <UserIcon className="h-5 w-5 text-gray-400 mr-2" />
                          <h4 className="text-lg font-semibold text-gray-900">
                            {appointment.patient_name}
                          </h4>
                          <span className={`ml-3 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${status.color}`}>
                            <StatusIcon className="h-3 w-3 mr-1" />
                            {status.text}
                          </span>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 text-sm text-gray-600 mb-4">
                          <div className="flex items-center">
                            <CalendarDaysIcon className="h-4 w-4 mr-2" />
                            {format(appointmentDate, 'EEEE, MMMM d, yyyy', { locale: enUS })}
                          </div>
                          <div className="flex items-center">
                            <ClockIcon className="h-4 w-4 mr-2" />
                            {format(appointmentDate, 'h:mm a', { locale: enUS })} ({appointment.duration_minutes}min)
                          </div>
                          <div>
                            <span className="font-medium">Email:</span> {appointment.patient_email}
                          </div>
                        </div>
                        
                        {appointment.prescription && (
                          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mt-4">
                            <div className="flex items-center mb-2">
                              <DocumentTextIcon className="h-5 w-5 text-blue-600 mr-2" />
                              <span className="font-semibold text-blue-900">Prescription</span>
                            </div>
                            <div className="space-y-2 text-sm">
                              <div>
                                <span className="font-medium text-gray-700">Medications:</span>
                                <span className="ml-2">{appointment.prescription.medications}</span>
                              </div>
                              <div>
                                <span className="font-medium text-gray-700">Dosage:</span>
                                <span className="ml-2">{appointment.prescription.dosage}</span>
                              </div>
                              {appointment.prescription.instructions && (
                                <div>
                                  <span className="font-medium text-gray-700">Instructions:</span>
                                  <span className="ml-2">{appointment.prescription.instructions}</span>
                                </div>
                              )}
                            </div>
                          </div>
                        )}
                      </div>
                      
                      <div className="ml-6 flex-shrink-0">
                        {appointment.status === 'completed' && !appointment.prescription && (
                          <button
                            onClick={() => openPrescriptionModal(appointment)}
                            className="inline-flex items-center px-4 py-2 bg-doctolib-blue text-white text-sm font-medium rounded-lg hover:bg-doctolib-darkblue transition-colors"
                          >
                            <PlusIcon className="h-4 w-4 mr-2" />
                            Add Prescription
                          </button>
                        )}
                        
                        {appointment.prescription && (
                          <button
                            onClick={() => openPrescriptionModal(appointment)}
                            className="inline-flex items-center px-4 py-2 bg-gray-100 text-gray-700 text-sm font-medium rounded-lg hover:bg-gray-200 transition-colors"
                          >
                            <DocumentTextIcon className="h-4 w-4 mr-2" />
                            Edit Prescription
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="p-12 text-center">
              <CalendarDaysIcon className="h-12 w-12 text-gray-300 mx-auto mb-4" />
              <p className="text-gray-600">No appointments found for this filter.</p>
            </div>
          )}
        </div>
      </div>

      {/* Prescription Modal */}
      {showPrescriptionModal && selectedAppointment && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">
                {selectedAppointment.prescription ? 'Edit Prescription' : 'Create Prescription'}
              </h3>
              <p className="text-gray-600">Patient: {selectedAppointment.patient_name}</p>
            </div>
            
            <form onSubmit={handlePrescriptionSubmit} className="p-6 space-y-6">
              <div>
                <label htmlFor="medications" className="block text-sm font-medium text-gray-700 mb-2">
                  Medications *
                </label>
                <input
                  type="text"
                  id="medications"
                  required
                  className="input-field"
                  placeholder="e.g., Amoxicillin 500mg"
                  value={prescriptionForm.medications}
                  onChange={(e) => setPrescriptionForm({...prescriptionForm, medications: e.target.value})}
                />
              </div>
              
              <div>
                <label htmlFor="dosage" className="block text-sm font-medium text-gray-700 mb-2">
                  Dosage *
                </label>
                <input
                  type="text"
                  id="dosage"
                  required
                  className="input-field"
                  placeholder="e.g., 1 capsule twice daily"
                  value={prescriptionForm.dosage}
                  onChange={(e) => setPrescriptionForm({...prescriptionForm, dosage: e.target.value})}
                />
              </div>
              
              <div>
                <label htmlFor="instructions" className="block text-sm font-medium text-gray-700 mb-2">
                  Instructions
                </label>
                <textarea
                  id="instructions"
                  rows={4}
                  className="input-field"
                  placeholder="e.g., Take with food. Complete entire course even if symptoms improve."
                  value={prescriptionForm.instructions}
                  onChange={(e) => setPrescriptionForm({...prescriptionForm, instructions: e.target.value})}
                />
              </div>
              
              <div className="flex space-x-4 pt-4">
                <button
                  type="button"
                  onClick={closePrescriptionModal}
                  className="btn-secondary flex-1"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="btn-primary flex-1 disabled:opacity-50"
                >
                  {submitting ? 'Saving...' : selectedAppointment.prescription ? 'Update Prescription' : 'Create Prescription'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}