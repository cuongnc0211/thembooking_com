import React from 'react'

const DAYS = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
const DAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

function parseTime(str) {
  if (!str) return null
  const [h, m] = str.split(':').map(Number)
  return h * 60 + (m || 0)
}

function formatTime(str) {
  if (!str) return ''
  const [h, m] = str.split(':').map(Number)
  const ampm = h >= 12 ? 'PM' : 'AM'
  const hh = h % 12 || 12
  return `${hh}:${String(m || 0).padStart(2, '0')} ${ampm}`
}

function isOpenNow(hours) {
  const now = new Date()
  const dayKey = DAYS[now.getDay()]
  const dayHours = hours?.[dayKey]
  if (!dayHours || dayHours.closed) return false
  const nowMins = now.getHours() * 60 + now.getMinutes()
  const open = parseTime(dayHours.open)
  const close = parseTime(dayHours.close)
  return open !== null && close !== null && nowMins >= open && nowMins < close
}

function HoursTable({ operatingHours }) {
  const todayIndex = new Date().getDay()

  return (
    <table className="w-full text-sm">
      <thead>
        <tr className="text-xs text-gray-400 uppercase tracking-wider">
          <th className="pb-2 text-left font-medium w-16">Day</th>
          <th className="pb-2 text-left font-medium">Hours</th>
          <th className="pb-2 text-left font-medium">Break</th>
        </tr>
      </thead>
      <tbody className="divide-y divide-gray-100">
        {DAYS.map((dayKey, i) => {
          const day = operatingHours?.[dayKey]
          const isToday = i === todayIndex
          return (
            <tr key={dayKey} className={isToday ? 'bg-indigo-50' : ''}>
              <td className={`py-2 font-medium ${isToday ? 'text-indigo-700' : 'text-gray-600'}`}>
                {DAY_LABELS[i]}
                {isToday && <span className="ml-1 text-xs text-indigo-400">(today)</span>}
              </td>
              <td className="py-2 text-gray-700">
                {!day || day.closed
                  ? <span className="text-gray-400 italic">Closed</span>
                  : `${formatTime(day.open)} – ${formatTime(day.close)}`
                }
              </td>
              <td className="py-2 text-gray-500 text-xs">
                {day?.breaks?.map((b, j) => (
                  <span key={j}>{formatTime(b.start)} – {formatTime(b.end)}</span>
                ))}
              </td>
            </tr>
          )
        })}
      </tbody>
    </table>
  )
}

export default function LandingHours({ branches }) {
  const multiBranch = branches.length > 1

  return (
    <section id="hours" className="py-16 px-4 bg-white">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">Hours</h2>

        <div className={multiBranch ? 'grid sm:grid-cols-2 gap-8' : ''}>
          {branches.map(branch => {
            const open = isOpenNow(branch.operating_hours)
            return (
              <div key={branch.id}>
                {multiBranch && (
                  <h3 className="font-semibold text-gray-800 mb-3">{branch.name}</h3>
                )}
                <div className="flex items-center gap-2 mb-4">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    open ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600'
                  }`}>
                    {open ? 'Open Now' : 'Closed Now'}
                  </span>
                </div>
                <HoursTable operatingHours={branch.operating_hours} />
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
