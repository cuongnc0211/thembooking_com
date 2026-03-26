import React from 'react'

const STATUS_CLASSES = {
  pending:     'bg-yellow-100 text-yellow-800',
  confirmed:   'bg-blue-100 text-blue-800',
  in_progress: 'bg-indigo-100 text-indigo-800',
  completed:   'bg-green-100 text-green-800',
  cancelled:   'bg-gray-100 text-gray-600',
  no_show:     'bg-red-100 text-red-800'
}

const STATUS_LABELS = {
  pending:     'Pending',
  confirmed:   'Confirmed',
  in_progress: 'In Service',
  completed:   'Completed',
  cancelled:   'Cancelled',
  no_show:     'No Show'
}

export default function StatusBadge({ status }) {
  const classes = STATUS_CLASSES[status] || 'bg-gray-100 text-gray-600'
  const label   = STATUS_LABELS[status]  || status

  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${classes}`}>
      {label}
    </span>
  )
}
