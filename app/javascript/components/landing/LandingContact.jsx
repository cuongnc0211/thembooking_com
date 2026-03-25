import React from 'react'

function BranchCard({ branch, businessType }) {
  const mapUrl = branch.address
    ? `https://maps.google.com/?q=${encodeURIComponent(branch.address)}`
    : null

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
      <div className="flex items-start justify-between gap-4 mb-4">
        <h3 className="font-semibold text-gray-900">{branch.name}</h3>
        {businessType && (
          <span className="shrink-0 text-xs px-2 py-1 rounded-full bg-indigo-50 text-indigo-600 capitalize font-medium">
            {businessType.replace(/_/g, ' ')}
          </span>
        )}
      </div>

      {branch.address && (
        <div className="flex items-start gap-3 mb-3">
          <svg className="w-4 h-4 text-gray-400 mt-0.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
              d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          {mapUrl
            ? <a href={mapUrl} target="_blank" rel="noopener noreferrer"
                className="text-sm text-indigo-600 hover:underline leading-snug">{branch.address}</a>
            : <span className="text-sm text-gray-600">{branch.address}</span>
          }
        </div>
      )}

      {branch.phone && (
        <div className="flex items-center gap-3">
          <svg className="w-4 h-4 text-gray-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
              d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
          </svg>
          <a href={`tel:${branch.phone}`}
            className="text-sm text-indigo-600 hover:underline">{branch.phone}</a>
        </div>
      )}
    </div>
  )
}

export default function LandingContact({ branches, businessType }) {
  return (
    <section id="contact" className="py-16 px-4 bg-gray-50">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">Contact</h2>
        <div className={`grid gap-6 ${branches.length > 1 ? 'sm:grid-cols-2' : ''}`}>
          {branches.map(branch => (
            <BranchCard key={branch.id} branch={branch} businessType={businessType} />
          ))}
        </div>
      </div>
    </section>
  )
}
