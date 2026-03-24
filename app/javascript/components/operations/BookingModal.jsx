import React, { useState, useEffect } from 'react'
import { createBooking, fetchServices } from './api'

function localDateTimeValue(date) {
  const pad = n => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export default function BookingModal({ bookingsUrl, servicesUrl, onClose, onCreated }) {
  const [services, setServices] = useState([])
  const [form, setForm] = useState({
    customer_name: '',
    customer_phone: '',
    customer_email: '',
    scheduled_at: localDateTimeValue(new Date(Date.now() + 3600000)), // default: 1h from now
    service_ids: []
  })
  const [submitting, setSubmitting] = useState(false)
  const [errors, setErrors] = useState([])

  useEffect(() => {
    fetchServices(servicesUrl).then(setServices).catch(() => {})
  }, [servicesUrl])

  function toggleService(id) {
    setForm(f => ({
      ...f,
      service_ids: f.service_ids.includes(id)
        ? f.service_ids.filter(s => s !== id)
        : [...f.service_ids, id]
    }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setErrors([])

    if (form.service_ids.length === 0) {
      setErrors(['Please select at least one service.'])
      return
    }
    if (new Date(form.scheduled_at) <= new Date()) {
      setErrors(['Scheduled time must be in the future.'])
      return
    }

    setSubmitting(true)
    try {
      await createBooking(bookingsUrl, {
        customer_name: form.customer_name,
        customer_phone: form.customer_phone,
        customer_email: form.customer_email || undefined,
        scheduled_at: new Date(form.scheduled_at).toISOString(),
        service_ids: form.service_ids,
        source: 'walk_in',
        status: 'confirmed'
      })
      onCreated()
      onClose()
    } catch (err) {
      setErrors([err.message])
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={onClose}>
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6" onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between mb-5">
          <h2 className="text-lg font-semibold text-gray-900">New Booking</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl leading-none">&times;</button>
        </div>

        {errors.length > 0 && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded text-sm text-red-700">
            {errors.map((e, i) => <p key={i}>{e}</p>)}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
            <input type="text" required value={form.customer_name}
              onChange={e => setForm(f => ({ ...f, customer_name: e.target.value }))}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Customer name" />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone *</label>
            <input type="tel" required value={form.customer_phone}
              onChange={e => setForm(f => ({ ...f, customer_phone: e.target.value }))}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="0901234567" />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email (optional)</label>
            <input type="email" value={form.customer_email}
              onChange={e => setForm(f => ({ ...f, customer_email: e.target.value }))}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="customer@email.com" />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Date & Time *</label>
            <input type="datetime-local" required value={form.scheduled_at}
              onChange={e => setForm(f => ({ ...f, scheduled_at: e.target.value }))}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Services *</label>
            <div className="space-y-2 max-h-40 overflow-y-auto border border-gray-200 rounded-lg p-3">
              {services.length === 0 && <p className="text-sm text-gray-400">Loading services…</p>}
              {services.map(s => (
                <label key={s.id} className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" checked={form.service_ids.includes(s.id)}
                    onChange={() => toggleService(s.id)}
                    className="rounded border-gray-300 text-indigo-600" />
                  <span className="text-sm text-gray-800">{s.name}</span>
                  <span className="text-xs text-gray-400 ml-auto">{s.duration_minutes}m</span>
                </label>
              ))}
            </div>
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose}
              className="flex-1 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg">
              Cancel
            </button>
            <button type="submit" disabled={submitting}
              className="flex-1 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-50">
              {submitting ? 'Booking…' : 'Book'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
