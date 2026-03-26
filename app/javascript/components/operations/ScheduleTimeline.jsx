import React, { useState } from 'react'
import StatusBadge from './StatusBadge'
import { updateBookingStatus } from './api'

const DIMMED_STATUSES = new Set(['completed', 'cancelled', 'no_show'])

function TimelineRow({ booking, bookingsUrl, onRefresh }) {
  const [busy, setBusy] = useState(false)
  const dimmed = DIMMED_STATUSES.has(booking.status)
  const time = new Date(booking.scheduled_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const firstName = booking.services[0]?.name || '—'

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
    <div className={`flex items-center gap-3 py-2.5 border-b border-gray-100 last:border-0 ${dimmed ? 'opacity-50' : ''}`}>
      <span className="text-xs font-mono text-gray-500 w-12 shrink-0">{time}</span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900 truncate">
          {booking.customer_name}
          {booking.source === 'walk_in' && (
            <span className="ml-1.5 text-xs text-amber-600 font-normal">Walk-in</span>
          )}
        </p>
        <p className="text-xs text-gray-500 truncate">{firstName}</p>
      </div>
      <StatusBadge status={booking.status} />
      {!dimmed && (
        <div className="flex gap-1 shrink-0">
          {booking.status === 'pending' && (
            <>
              <button onClick={() => handleAction('confirm')} disabled={busy}
                className="px-2 py-1 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 rounded disabled:opacity-50">
                Confirm
              </button>
              <button onClick={() => handleAction('cancel')} disabled={busy}
                className="px-2 py-1 text-xs font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded disabled:opacity-50">
                Cancel
              </button>
            </>
          )}
          {booking.status === 'confirmed' && (
            <button onClick={() => handleAction('start')} disabled={busy}
              className="px-2 py-1 text-xs font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded disabled:opacity-50">
              Start
            </button>
          )}
          {booking.status === 'in_progress' && (
            <button onClick={() => handleAction('complete')} disabled={busy}
              className="px-2 py-1 text-xs font-medium text-white bg-green-600 hover:bg-green-700 rounded disabled:opacity-50">
              Complete
            </button>
          )}
        </div>
      )}
    </div>
  )
}

export default function ScheduleTimeline({ schedule, bookingsUrl, onRefresh }) {
  const now = Date.now()
  let nowInserted = false

  const rows = []
  const sorted = [...schedule].sort((a, b) => new Date(a.scheduled_at) - new Date(b.scheduled_at))

  sorted.forEach((booking, i) => {
    const bookingTime = new Date(booking.scheduled_at).getTime()
    if (!nowInserted && bookingTime > now) {
      nowInserted = true
      rows.push(
        <div key="now-divider" className="flex items-center gap-2 py-2">
          <div className="flex-1 h-px bg-indigo-300" />
          <span className="text-xs font-semibold text-indigo-600 shrink-0">NOW</span>
          <div className="flex-1 h-px bg-indigo-300" />
        </div>
      )
    }
    rows.push(
      <TimelineRow key={booking.id} booking={booking} bookingsUrl={bookingsUrl} onRefresh={onRefresh} />
    )
  })

  // If all bookings are in the past, append NOW at end
  if (!nowInserted && sorted.length > 0) {
    rows.push(
      <div key="now-divider" className="flex items-center gap-2 py-2">
        <div className="flex-1 h-px bg-indigo-300" />
        <span className="text-xs font-semibold text-indigo-600 shrink-0">NOW</span>
        <div className="flex-1 h-px bg-indigo-300" />
      </div>
    )
  }

  return (
    <div>
      <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
        Today's Schedule <span className="ml-1 text-gray-600">({schedule.length})</span>
      </h2>
      {schedule.length === 0 ? (
        <p className="text-sm text-gray-400 italic">No bookings scheduled for today.</p>
      ) : (
        <div className="bg-white rounded-lg border border-gray-200 px-4">
          {rows}
        </div>
      )}
    </div>
  )
}
