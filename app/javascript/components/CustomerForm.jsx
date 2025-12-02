import React, { useState } from 'react'

export default function CustomerForm({
  businessSlug,
  selectedServices,
  selectedDate,
  selectedTime,
  services
}) {
  const [formData, setFormData] = useState({
    customer_name: '',
    customer_phone: '',
    customer_email: '',
    notes: ''
  })

  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
    // Clear error when user types
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }))
    }
  }

  const validate = () => {
    const newErrors = {}

    if (!formData.customer_name.trim()) {
      newErrors.customer_name = 'Name is required'
    }

    if (!formData.customer_phone.trim()) {
      newErrors.customer_phone = 'Phone is required'
    } else if (!/^[0-9]{10,11}$/.test(formData.customer_phone.replace(/\s/g, ''))) {
      newErrors.customer_phone = 'Please enter a valid phone number'
    }

    if (formData.customer_email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.customer_email)) {
      newErrors.customer_email = 'Please enter a valid email'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    if (!validate()) return

    setSubmitting(true)

    // Format start_time as "YYYY-MM-DD HH:MM"
    const year = selectedDate.getFullYear()
    const month = String(selectedDate.getMonth() + 1).padStart(2, '0')
    const day = String(selectedDate.getDate()).padStart(2, '0')
    const startTime = `${year}-${month}-${day} ${selectedTime}`

    try {
      const csrfToken = document.querySelector('[name="csrf-token"]')?.content

      const response = await fetch(`/${businessSlug}/bookings`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          service_ids: selectedServices,
          start_time: startTime,
          booking: formData
        })
      })

      if (response.ok) {
        // Redirect to confirmation page
        const booking = await response.json()
        window.location.href = `/${businessSlug}/bookings/${booking.id || ''}`
      } else if (response.redirected) {
        // Rails might redirect on successful POST
        window.location.href = response.url
      } else {
        const data = await response.json()
        setErrors({ submit: data.error || 'Booking failed. Please try again.' })
      }
    } catch (error) {
      console.error('Booking error:', error)
      setErrors({ submit: 'Network error. Please check your connection and try again.' })
    } finally {
      setSubmitting(false)
    }
  }

  // Calculate totals for summary
  const totalDuration = selectedServices.reduce((sum, id) => {
    const service = services.find(s => s.id === parseInt(id))
    return sum + (service?.duration_minutes || 0)
  }, 0)

  const totalPrice = selectedServices.reduce((sum, id) => {
    const service = services.find(s => s.id === parseInt(id))
    return sum + (service?.price_cents || 0)
  }, 0)

  const selectedServiceObjects = selectedServices.map(id =>
    services.find(s => s.id === parseInt(id))
  ).filter(Boolean)

  return (
    <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
      <h2 className="text-2xl font-bold text-slate-900 mb-6">Your Information</h2>

      {/* Booking Summary */}
      <div className="mb-6 p-4 bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl border border-blue-100">
        <h3 className="font-semibold text-slate-900 mb-3">Booking Summary</h3>

        <div className="space-y-2 mb-3">
          {selectedServiceObjects.map(service => (
            <div key={service.id} className="flex justify-between text-sm">
              <span className="text-slate-700">{service.name}</span>
              <span className="text-slate-900 font-medium">
                {(service.price_cents / 100).toLocaleString('vi-VN')} ₫
              </span>
            </div>
          ))}
        </div>

        <div className="pt-3 border-t border-blue-200">
          <div className="flex justify-between items-center">
            <div>
              <div className="font-semibold text-slate-900">Total</div>
              <div className="text-sm text-slate-600">{totalDuration} minutes</div>
            </div>
            <div className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {(totalPrice / 100).toLocaleString('vi-VN')} ₫
            </div>
          </div>

          <div className="mt-3 pt-3 border-t border-blue-200 text-sm">
            <div className="flex items-center gap-2 text-slate-700">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span>
                {selectedDate.toLocaleDateString('vi-VN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
              </span>
            </div>

            <div className="flex items-center gap-2 text-slate-700 mt-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span>{selectedTime}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4">
        {errors.submit && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm">
            {errors.submit}
          </div>
        )}

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            Full Name *
          </label>
          <input
            type="text"
            name="customer_name"
            value={formData.customer_name}
            onChange={handleChange}
            className={`w-full px-4 py-3 rounded-xl border-2 transition-colors ${
              errors.customer_name
                ? 'border-red-300 focus:border-red-500'
                : 'border-slate-200 focus:border-blue-500'
            } focus:outline-none`}
            placeholder="Nguyen Van A"
          />
          {errors.customer_name && (
            <p className="mt-1 text-sm text-red-600">{errors.customer_name}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            Phone Number *
          </label>
          <input
            type="tel"
            name="customer_phone"
            value={formData.customer_phone}
            onChange={handleChange}
            className={`w-full px-4 py-3 rounded-xl border-2 transition-colors ${
              errors.customer_phone
                ? 'border-red-300 focus:border-red-500'
                : 'border-slate-200 focus:border-blue-500'
            } focus:outline-none`}
            placeholder="0912345678"
          />
          {errors.customer_phone && (
            <p className="mt-1 text-sm text-red-600">{errors.customer_phone}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            Email (Optional)
          </label>
          <input
            type="email"
            name="customer_email"
            value={formData.customer_email}
            onChange={handleChange}
            className={`w-full px-4 py-3 rounded-xl border-2 transition-colors ${
              errors.customer_email
                ? 'border-red-300 focus:border-red-500'
                : 'border-slate-200 focus:border-blue-500'
            } focus:outline-none`}
            placeholder="email@example.com"
          />
          {errors.customer_email && (
            <p className="mt-1 text-sm text-red-600">{errors.customer_email}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            Notes (Optional)
          </label>
          <textarea
            name="notes"
            value={formData.notes}
            onChange={handleChange}
            rows={3}
            className="w-full px-4 py-3 rounded-xl border-2 border-slate-200 focus:border-blue-500 focus:outline-none transition-colors resize-none"
            placeholder="Any special requests or notes..."
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className={`
            w-full py-4 px-6 rounded-xl font-semibold text-white text-lg
            transition-all duration-200
            ${submitting
              ? 'bg-slate-400 cursor-not-allowed'
              : 'bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 shadow-lg hover:shadow-xl transform hover:scale-[1.02]'}
          `}
        >
          {submitting ? (
            <span className="flex items-center justify-center gap-2">
              <svg className="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
              Processing...
            </span>
          ) : (
            'Confirm Booking'
          )}
        </button>
      </form>
    </div>
  )
}
