import React, { useState } from 'react'
import ServiceCard from './ServiceCard'
import { updateBookingStatus } from './api'

function WaitingRow({ booking, bookingsUrl, onRefresh }) {
  const [busy, setBusy] = useState(false)

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

  const time = new Date(booking.scheduled_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })

  return (
    <div className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium text-gray-900 truncate">{booking.customer_name}</p>
        <p className="text-xs text-gray-500">{time} · {booking.services.map(s => s.name).join(', ')}</p>
      </div>
      <div className="flex gap-1.5 ml-3 shrink-0">
        <button
          onClick={() => handleAction('start')}
          disabled={busy}
          className="px-2.5 py-1 text-xs font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded disabled:opacity-50"
        >
          Start
        </button>
        <button
          onClick={() => handleAction('no_show')}
          disabled={busy}
          className="px-2.5 py-1 text-xs font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded disabled:opacity-50"
        >
          No-show
        </button>
        <button
          onClick={() => handleAction('cancel')}
          disabled={busy}
          className="px-2.5 py-1 text-xs font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded disabled:opacity-50"
        >
          Cancel
        </button>
      </div>
    </div>
  )
}

export default function InServicePanel({ inService, waiting, bookingsUrl, onRefresh }) {
  return (
    <div className="space-y-6">
      {/* In-service section */}
      <div>
        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          In Service <span className="ml-1 text-indigo-600">({inService.length})</span>
        </h2>
        {inService.length === 0 ? (
          <p className="text-sm text-gray-400 italic">No one in service right now.</p>
        ) : (
          <div className="grid gap-3">
            {inService.map(b => (
              <ServiceCard key={b.id} booking={b} bookingsUrl={bookingsUrl} onRefresh={onRefresh} />
            ))}
          </div>
        )}
      </div>

      {/* Waiting queue section */}
      <div>
        <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
          Waiting Queue <span className="ml-1 text-blue-600">({waiting.length})</span>
        </h2>
        {waiting.length === 0 ? (
          <p className="text-sm text-gray-400 italic">No one waiting.</p>
        ) : (
          <div className="bg-white rounded-lg border border-gray-200 divide-y divide-gray-100 px-4">
            {waiting.map(b => (
              <WaitingRow key={b.id} booking={b} bookingsUrl={bookingsUrl} onRefresh={onRefresh} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
