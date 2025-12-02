import React from 'react'

export default function DateNavigation({ selectedDate, onDateChange }) {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const maxDate = new Date()
  maxDate.setDate(maxDate.getDate() + 30)
  maxDate.setHours(0, 0, 0, 0)

  const selectedDateOnly = new Date(selectedDate)
  selectedDateOnly.setHours(0, 0, 0, 0)

  const canGoPrev = selectedDateOnly > today
  const canGoNext = selectedDateOnly < maxDate

  const handlePrevDay = () => {
    if (!canGoPrev) return

    const newDate = new Date(selectedDate)
    newDate.setDate(newDate.getDate() - 1)
    onDateChange(newDate)
  }

  const handleNextDay = () => {
    if (!canGoNext) return

    const newDate = new Date(selectedDate)
    newDate.setDate(newDate.getDate() + 1)
    onDateChange(newDate)
  }

  const formatDate = (date) => {
    return date.toLocaleDateString('vi-VN', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  const isToday = selectedDateOnly.getTime() === today.getTime()
  const isTomorrow = selectedDateOnly.getTime() === (today.getTime() + 86400000)

  let dateLabel = formatDate(selectedDate)
  if (isToday) {
    dateLabel = `Hôm nay, ${formatDate(selectedDate)}`
  } else if (isTomorrow) {
    dateLabel = `Ngày mai, ${formatDate(selectedDate)}`
  }

  return (
    <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
      <h2 className="text-2xl font-bold text-slate-900 mb-4">Select Date</h2>

      <div className="flex items-center gap-4">
        <button
          type="button"
          onClick={handlePrevDay}
          disabled={!canGoPrev}
          className={`
            flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center
            transition-all duration-200
            ${canGoPrev
              ? 'bg-gradient-to-br from-blue-50 to-purple-50 hover:from-blue-100 hover:to-purple-100 text-blue-700 border-2 border-blue-200 hover:border-blue-300 hover:shadow-md'
              : 'bg-slate-100 text-slate-300 border-2 border-slate-200 cursor-not-allowed'}
          `}
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 19l-7-7 7-7" />
          </svg>
        </button>

        <div className="flex-1 text-center py-4 px-6 bg-gradient-to-r from-blue-50 via-purple-50 to-blue-50 rounded-xl border-2 border-blue-100">
          <div className="text-lg font-bold text-slate-900">
            {dateLabel}
          </div>
          {(isToday || isTomorrow) && (
            <div className="mt-1 inline-flex items-center gap-1.5 px-3 py-1 bg-white rounded-full">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <span className="text-xs font-medium text-slate-600">
                {isToday ? 'Available now' : 'Coming soon'}
              </span>
            </div>
          )}
        </div>

        <button
          type="button"
          onClick={handleNextDay}
          disabled={!canGoNext}
          className={`
            flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center
            transition-all duration-200
            ${canGoNext
              ? 'bg-gradient-to-br from-blue-50 to-purple-50 hover:from-blue-100 hover:to-purple-100 text-blue-700 border-2 border-blue-200 hover:border-blue-300 hover:shadow-md'
              : 'bg-slate-100 text-slate-300 border-2 border-slate-200 cursor-not-allowed'}
          `}
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>
    </div>
  )
}
