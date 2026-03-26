import React, { useState, useEffect } from 'react'
import { useOperationsData } from './operations/use-operations-data'
import InServicePanel from './operations/InServicePanel'
import ScheduleTimeline from './operations/ScheduleTimeline'
import WalkInModal from './operations/WalkInModal'
import BookingModal from './operations/BookingModal'

function LoadingState() {
  return (
    <div className="flex items-center justify-center h-48 text-gray-400">
      <svg className="animate-spin h-6 w-6 mr-2" fill="none" viewBox="0 0 24 24">
        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
      </svg>
      Loading…
    </div>
  )
}

function ErrorState({ message, onRetry }) {
  return (
    <div className="flex flex-col items-center justify-center h-48 text-red-600 gap-3">
      <p className="text-sm">Failed to load data: {message}</p>
      <button onClick={onRetry} className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg">
        Retry
      </button>
    </div>
  )
}

function Header({ branch, counts, onWalkIn, onBook }) {
  const [now, setNow] = useState(new Date())

  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 60000)
    return () => clearInterval(id)
  }, [])

  const capacityPct = branch.capacity > 0
    ? Math.min(Math.round((counts.in_service / branch.capacity) * 100), 100)
    : 0
  const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  const dateStr = now.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' })

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-gray-900">{branch.name} — Operations</h1>
          <p className="text-sm text-gray-500">{dateStr} · {timeStr}</p>
        </div>

        <div className="flex items-center gap-3">
          {/* Capacity bar */}
          <div className="hidden sm:block w-32">
            <p className="text-xs text-gray-500 mb-1">
              Capacity: {counts.in_service}/{branch.capacity}
            </p>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div
                className={`h-2 rounded-full transition-all ${capacityPct >= 100 ? 'bg-red-500' : capacityPct >= 75 ? 'bg-amber-500' : 'bg-green-500'}`}
                style={{ width: `${capacityPct}%` }}
              />
            </div>
          </div>

          {/* Stat badges */}
          <div className="flex gap-2 text-center">
            <div className="px-3 py-1 bg-indigo-50 rounded-lg">
              <p className="text-lg font-bold text-indigo-700">{counts.in_service}</p>
              <p className="text-xs text-indigo-500">In Service</p>
            </div>
            <div className="px-3 py-1 bg-blue-50 rounded-lg">
              <p className="text-lg font-bold text-blue-700">{counts.waiting}</p>
              <p className="text-xs text-blue-500">Waiting</p>
            </div>
            <div className="px-3 py-1 bg-green-50 rounded-lg">
              <p className="text-lg font-bold text-green-700">{counts.completed_today}</p>
              <p className="text-xs text-green-500">Done Today</p>
            </div>
          </div>

          {/* Action buttons */}
          <div className="flex gap-2">
            <button
              onClick={onWalkIn}
              className="px-3 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg"
            >
              + Walk-in
            </button>
            <button
              onClick={onBook}
              className="px-3 py-2 text-sm font-medium text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg"
            >
              + Book
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function OperationsApp({ branchId, branchName, dataUrl, bookingsUrl, servicesUrl }) {
  const { data, loading, error, refresh } = useOperationsData(dataUrl)
  const [activeModal, setActiveModal] = useState(null) // 'walkin' | 'booking' | null

  if (loading && !data) return <LoadingState />
  if (error && !data) return <ErrorState message={error} onRetry={refresh} />

  const { branch, in_service, waiting, today_schedule, counts } = data

  return (
    <div className="space-y-4">
      <Header
        branch={branch}
        counts={counts}
        onWalkIn={() => setActiveModal('walkin')}
        onBook={() => setActiveModal('booking')}
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <InServicePanel
          inService={in_service}
          waiting={waiting}
          bookingsUrl={bookingsUrl}
          onRefresh={refresh}
        />
        <ScheduleTimeline
          schedule={today_schedule}
          bookingsUrl={bookingsUrl}
          onRefresh={refresh}
        />
      </div>

      {activeModal === 'walkin' && (
        <WalkInModal
          bookingsUrl={bookingsUrl}
          servicesUrl={servicesUrl}
          onClose={() => setActiveModal(null)}
          onCreated={refresh}
        />
      )}
      {activeModal === 'booking' && (
        <BookingModal
          bookingsUrl={bookingsUrl}
          servicesUrl={servicesUrl}
          onClose={() => setActiveModal(null)}
          onCreated={refresh}
        />
      )}
    </div>
  )
}
