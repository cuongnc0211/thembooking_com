import React, { useState, useEffect } from 'react'
import { updateBookingStatus } from './api'

function useElapsed(startedAt) {
  const [elapsed, setElapsed] = useState(
    startedAt ? Math.floor((Date.now() - new Date(startedAt)) / 60000) : 0
  )
  useEffect(() => {
    if (!startedAt) return
    const id = setInterval(() => {
      setElapsed(Math.floor((Date.now() - new Date(startedAt)) / 60000))
    }, 60000)
    return () => clearInterval(id)
  }, [startedAt])
  return elapsed
}

export default function ServiceCard({ booking, bookingsUrl, onRefresh }) {
  const [busy, setBusy] = useState(false)
  const elapsed = useElapsed(booking.started_at)
  const total   = booking.total_duration_minutes || 1
  const pct     = Math.min(Math.round((elapsed / total) * 100), 100)
  const overtime = elapsed > total

  async function handleAction(action) {
    setBusy(true)
    try {
      await updateBookingStatus(bookingsUrl, booking.id, action)
      onRefresh()
    } catch (err) {
      alert(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className={`rounded-lg border p-4 space-y-3 ${overtime ? 'border-red-400 bg-red-50' : 'border-gray-200 bg-white'}`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="font-semibold text-gray-900">{booking.customer_name}</p>
          <p className="text-sm text-gray-500">{booking.customer_phone}</p>
        </div>
        {overtime && (
          <span className="text-xs font-medium text-red-600 bg-red-100 px-2 py-0.5 rounded">Overtime</span>
        )}
      </div>

      <ul className="text-sm text-gray-700 space-y-0.5">
        {booking.services.map(s => (
          <li key={s.id}>{s.name} <span className="text-gray-400">({s.duration_minutes}m)</span></li>
        ))}
      </ul>

      {/* Progress bar */}
      <div>
        <div className="flex justify-between text-xs text-gray-500 mb-1">
          <span>{elapsed}m elapsed</span>
          <span>{total}m total</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className={`h-2 rounded-full transition-all ${overtime ? 'bg-red-500' : 'bg-indigo-500'}`}
            style={{ width: `${pct}%` }}
          />
        </div>
      </div>

      <div className="flex gap-2 pt-1">
        <button
          onClick={() => handleAction('complete')}
          disabled={busy}
          className="flex-1 py-1.5 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded disabled:opacity-50"
        >
          Complete
        </button>
        <button
          onClick={() => handleAction('no_show')}
          disabled={busy}
          className="px-3 py-1.5 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded disabled:opacity-50"
        >
          No-show
        </button>
      </div>
    </div>
  )
}
