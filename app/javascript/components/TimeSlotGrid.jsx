import React from 'react'

export default function TimeSlotGrid({ slots, selectedTime, onTimeSelect, loading }) {
  const formatTime = (timeString) => {
    const [hours, minutes] = timeString.split(':')
    const hour = parseInt(hours)
    const ampm = hour >= 12 ? 'PM' : 'AM'
    const displayHour = hour % 12 || 12
    return `${displayHour}:${minutes} ${ampm}`
  }

  if (loading) {
    return (
      <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
        <h2 className="text-2xl font-bold text-slate-900 mb-4">Available Times</h2>

        <div className="flex flex-col items-center justify-center py-12">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin" />
            <div className="absolute inset-0 w-16 h-16 border-4 border-transparent border-r-purple-600 rounded-full animate-spin" style={{ animationDirection: 'reverse', animationDuration: '1s' }} />
          </div>
          <p className="mt-4 text-slate-600 font-medium">Finding available times...</p>
        </div>
      </div>
    )
  }

  if (slots.length === 0) {
    return (
      <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
        <h2 className="text-2xl font-bold text-slate-900 mb-4">Available Times</h2>

        <div className="flex flex-col items-center justify-center py-12">
          <svg className="w-20 h-20 text-slate-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <p className="text-slate-600 font-medium">No available time slots</p>
          <p className="text-sm text-slate-500 mt-1">Try selecting a different date</p>
        </div>
      </div>
    )
  }

  // Group slots by time period
  const morningSlots = slots.filter(s => {
    const hour = parseInt(s.split(':')[0])
    return hour < 12
  })

  const afternoonSlots = slots.filter(s => {
    const hour = parseInt(s.split(':')[0])
    return hour >= 12 && hour < 17
  })

  const eveningSlots = slots.filter(s => {
    const hour = parseInt(s.split(':')[0])
    return hour >= 17
  })

  const SlotGroup = ({ title, icon, timeSlots, accentColor }) => {
    if (timeSlots.length === 0) return null

    return (
      <div>
        <div className="flex items-center gap-2 mb-3">
          <div className={`w-8 h-8 rounded-lg ${accentColor} flex items-center justify-center`}>
            {icon}
          </div>
          <h3 className="font-semibold text-slate-700">{title}</h3>
          <span className="text-sm text-slate-500">({timeSlots.length} slots)</span>
        </div>

        <div className="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-2">
          {timeSlots.map((time) => {
            const isSelected = selectedTime === time

            return (
              <button
                key={time}
                type="button"
                onClick={() => onTimeSelect(time)}
                className={`
                  px-3 py-3 rounded-xl font-medium text-sm transition-all duration-200
                  ${isSelected
                    ? 'bg-gradient-to-br from-blue-600 to-purple-600 text-white shadow-lg scale-105 ring-4 ring-blue-100'
                    : 'bg-white border-2 border-slate-200 text-slate-700 hover:border-blue-300 hover:bg-blue-50 hover:text-blue-700 hover:shadow-md'}
                `}
              >
                {formatTime(time)}
              </button>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
      <h2 className="text-2xl font-bold text-slate-900 mb-6">Available Times</h2>

      <div className="space-y-6">
        <SlotGroup
          title="Morning"
          icon={
            <svg className="w-5 h-5 text-yellow-600" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
            </svg>
          }
          timeSlots={morningSlots}
          accentColor="bg-yellow-100"
        />

        <SlotGroup
          title="Afternoon"
          icon={
            <svg className="w-5 h-5 text-orange-600" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
            </svg>
          }
          timeSlots={afternoonSlots}
          accentColor="bg-orange-100"
        />

        <SlotGroup
          title="Evening"
          icon={
            <svg className="w-5 h-5 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
              <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
            </svg>
          }
          timeSlots={eveningSlots}
          accentColor="bg-indigo-100"
        />
      </div>
    </div>
  )
}
