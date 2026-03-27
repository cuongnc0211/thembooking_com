import React, { useState, useEffect } from 'react'
import BranchSelector from './BranchSelector'
import ServiceSelector from './ServiceSelector'
import DateNavigation from './DateNavigation'
import TimeSlotGrid from './TimeSlotGrid'
import CustomerForm from './CustomerForm'

export default function BookingApp({ businessSlug, business, branches }) {
  // Auto-select branch when there is only one active branch
  const autoSelectedBranch = branches.length === 1 ? branches[0] : null

  const [selectedBranch, setSelectedBranch] = useState(autoSelectedBranch)
  const [selectedServices, setSelectedServices] = useState([])
  const [selectedDate, setSelectedDate] = useState(new Date())
  const [availableSlots, setAvailableSlots] = useState([])
  const [selectedTime, setSelectedTime] = useState(null)
  const [loading, setLoading] = useState(false)

  // Steps: 1=Branch (skipped if auto), 2=Services, 3=DateTime, 4=Customer
  const [currentStep, setCurrentStep] = useState(autoSelectedBranch ? 2 : 1)

  const services = selectedBranch?.services || []

  const totalDuration = selectedServices.reduce((sum, id) => {
    const service = services.find(s => s.id === parseInt(id))
    return sum + (service?.duration_minutes || 0)
  }, 0)

  const totalPrice = selectedServices.reduce((sum, id) => {
    const service = services.find(s => s.id === parseInt(id))
    return sum + (service?.price_cents || 0)
  }, 0)

  useEffect(() => {
    if (selectedServices.length > 0 && selectedBranch) {
      fetchAvailability()
    } else {
      setAvailableSlots([])
      setSelectedTime(null)
    }
  }, [selectedServices, selectedDate, selectedBranch])

  const fetchAvailability = async () => {
    setLoading(true)
    setSelectedTime(null)

    const year = selectedDate.getFullYear()
    const month = String(selectedDate.getMonth() + 1).padStart(2, '0')
    const day = String(selectedDate.getDate()).padStart(2, '0')
    const dateStr = `${year}-${month}-${day}`

    const params = new URLSearchParams({ date: dateStr, branch_slug: selectedBranch.slug })
    selectedServices.forEach(id => params.append('service_ids[]', id))

    try {
      const response = await fetch(`/booking/${businessSlug}/availability?${params}`)
      const data = await response.json()
      setAvailableSlots(data.available_slots || [])
    } catch (error) {
      console.error('Error fetching availability:', error)
      setAvailableSlots([])
    } finally {
      setLoading(false)
    }
  }

  const handleBranchSelect = (branch) => {
    setSelectedBranch(branch)
    setSelectedServices([])
    setSelectedTime(null)
    setAvailableSlots([])
    setCurrentStep(2)
  }

  const handleServicesChange = (serviceIds) => {
    setSelectedServices(serviceIds)
    setCurrentStep(serviceIds.length > 0 ? 3 : 2)
  }

  const handleTimeSelect = (time) => {
    setSelectedTime(time)
    setCurrentStep(4)
  }

  // Progress steps shown to the user (branch step hidden when auto-selected)
  const visibleSteps = autoSelectedBranch
    ? [{ num: 2, label: 'Services' }, { num: 3, label: 'Date & Time' }, { num: 4, label: 'Details' }]
    : [{ num: 1, label: 'Branch' }, { num: 2, label: 'Services' }, { num: 3, label: 'Date & Time' }, { num: 4, label: 'Details' }]

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 py-8">
      <div className="max-w-5xl mx-auto px-4">
        {/* Header */}
        <div className="text-center mb-10">
          <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-2">
            {business.name}
          </h1>
          <p className="text-slate-600">{business.description || 'Book your appointment'}</p>
          {selectedBranch && autoSelectedBranch === null && (
            <div className="mt-3 inline-flex items-center gap-2 px-4 py-2 bg-blue-50 rounded-full">
              <span className="text-sm font-medium text-blue-700">{selectedBranch.name}</span>
              <button
                onClick={() => { setSelectedBranch(null); setSelectedServices([]); setSelectedTime(null); setCurrentStep(1) }}
                className="text-blue-400 hover:text-blue-600 text-xs underline"
              >
                Change
              </button>
            </div>
          )}
        </div>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-center gap-4">
            {visibleSteps.map((step, idx) => (
              <React.Fragment key={step.num}>
                <div className={`flex flex-col items-center gap-1 text-center ${currentStep >= step.num ? 'opacity-100' : 'opacity-40'}`}>
                  <div className={`
                    w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm
                    ${currentStep >= step.num
                      ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white'
                      : 'bg-slate-200 text-slate-500'}
                  `}>
                    {idx + 1}
                  </div>
                  <span className="text-sm font-medium text-slate-700">{step.label}</span>
                </div>
                {idx < visibleSteps.length - 1 && (
                  <div className={`h-0.5 w-16 ${currentStep > step.num ? 'bg-gradient-to-r from-blue-600 to-purple-600' : 'bg-slate-200'}`} />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Step 1: Branch Selection (hidden when auto-selected) */}
        {currentStep === 1 && !autoSelectedBranch && (
          <BranchSelector branches={branches} onSelect={handleBranchSelect} />
        )}

        {/* Step 2: Service Selection */}
        {currentStep >= 2 && selectedBranch && (
          <ServiceSelector
            services={services}
            selectedServices={selectedServices}
            onServicesChange={handleServicesChange}
            totalDuration={totalDuration}
            totalPrice={totalPrice}
          />
        )}

        {/* Step 3: Date & Time Selection */}
        {currentStep >= 3 && (
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

        {/* Step 4: Customer Form */}
        {currentStep >= 4 && selectedTime && (
          <div className="mt-6">
            <CustomerForm
              businessSlug={businessSlug}
              branchSlug={selectedBranch.slug}
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
