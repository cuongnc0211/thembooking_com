import React, { useState, useEffect } from 'react'
import ServiceSelector from './ServiceSelector'
import DateNavigation from './DateNavigation'
import TimeSlotGrid from './TimeSlotGrid'
import CustomerForm from './CustomerForm'

export default function BookingApp({ businessSlug, business, services }) {
  // State management
  const [selectedServices, setSelectedServices] = useState([])
  const [selectedDate, setSelectedDate] = useState(new Date())
  const [availableSlots, setAvailableSlots] = useState([])
  const [selectedTime, setSelectedTime] = useState(null)
  const [loading, setLoading] = useState(false)
  const [currentStep, setCurrentStep] = useState(1) // 1: Services, 2: DateTime, 3: Customer

  // Calculate totals when services change
  const totalDuration = selectedServices.reduce((sum, id) => {
    const service = services.find(s => s.id === parseInt(id))
    return sum + (service?.duration_minutes || 0)
  }, 0)

  const totalPrice = selectedServices.reduce((sum, id) => {
    const service = services.find(s => s.id === parseInt(id))
    return sum + (service?.price_cents || 0)
  }, 0)

  // Fetch availability when services or date change
  useEffect(() => {
    if (selectedServices.length > 0) {
      fetchAvailability()
    } else {
      setAvailableSlots([])
      setSelectedTime(null)
    }
  }, [selectedServices, selectedDate])

  const fetchAvailability = async () => {
    setLoading(true)
    setSelectedTime(null) // Reset time selection

    const year = selectedDate.getFullYear()
    const month = String(selectedDate.getMonth() + 1).padStart(2, '0')
    const day = String(selectedDate.getDate()).padStart(2, '0')
    const dateStr = `${year}-${month}-${day}`

    const params = new URLSearchParams({ date: dateStr })
    selectedServices.forEach(id => params.append('service_ids[]', id))

    try {
      const response = await fetch(`/${businessSlug}/availability?${params}`)
      const data = await response.json()

      setAvailableSlots(data.available_slots || [])
    } catch (error) {
      console.error('Error fetching availability:', error)
      setAvailableSlots([])
    } finally {
      setLoading(false)
    }
  }

  const handleServicesChange = (serviceIds) => {
    setSelectedServices(serviceIds)
    if (serviceIds.length > 0) {
      setCurrentStep(2)
    } else {
      setCurrentStep(1)
    }
  }

  const handleTimeSelect = (time) => {
    setSelectedTime(time)
    setCurrentStep(3)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 py-8">
      <div className="max-w-5xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-10">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-2">
            {business.name}
          </h1>
          <p className="text-slate-600">{business.description || 'Book your appointment'}</p>
          <div className="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-blue-50 rounded-full">
            <span className="text-sm font-medium text-blue-700">React Booking Experience</span>
          </div>
        </div>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-center gap-4">
            {[
              { num: 1, label: 'Services' },
              { num: 2, label: 'Date & Time' },
              { num: 3, label: 'Details' }
            ].map((step, idx) => (
              <React.Fragment key={step.num}>
                <div className={`flex flex-col items-center gap-1 text-center ${currentStep >= step.num ? 'opacity-100' : 'opacity-40'}`}>
                  <div className={`
                    w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm
                    ${currentStep >= step.num
                      ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white'
                      : 'bg-slate-200 text-slate-500'}
                  `}>
                    {step.num}
                  </div>
                  <span className="text-sm font-medium text-slate-700">{step.label}</span>
                </div>
                {idx < 2 && (
                  <div className={`h-0.5 w-16 ${currentStep > step.num ? 'bg-gradient-to-r from-blue-600 to-purple-600' : 'bg-slate-200'}`} />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Step 1: Service Selection */}
        <ServiceSelector
          services={services}
          selectedServices={selectedServices}
          onServicesChange={handleServicesChange}
          totalDuration={totalDuration}
          totalPrice={totalPrice}
        />

        {/* Step 2: Date & Time Selection */}
        {currentStep >= 2 && (
          <div className="mt-6 space-y-6">
            <DateNavigation
              selectedDate={selectedDate}
              onDateChange={setSelectedDate}
            />

            <TimeSlotGrid
              slots={availableSlots}
              selectedTime={selectedTime}
              onTimeSelect={handleTimeSelect}
              loading={loading}
            />
          </div>
        )}

        {/* Step 3: Customer Form */}
        {currentStep >= 3 && selectedTime && (
          <div className="mt-6">
            <CustomerForm
              businessSlug={businessSlug}
              selectedServices={selectedServices}
              selectedDate={selectedDate}
              selectedTime={selectedTime}
              services={services}
            />
          </div>
        )}
      </div>
    </div>
  )
}
