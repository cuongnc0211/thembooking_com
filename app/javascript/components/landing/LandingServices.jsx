import React, { useState } from 'react'

function formatDuration(minutes) {
  if (!minutes) return ''
  if (minutes < 60) return `${minutes} min`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m > 0 ? `${h}h ${m}min` : `${h}h`
}

function groupByCategory(services) {
  return services.reduce((acc, s) => {
    const cat = s.category_name || 'Other'
    if (!acc[cat]) acc[cat] = []
    acc[cat].push(s)
    return acc
  }, {})
}

function ServiceList({ services, branchSlug }) {
  const groups = groupByCategory(services)
  return (
    <div className="space-y-6">
      {Object.entries(groups).map(([cat, items]) => (
        <div key={cat}>
          <h4 className="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-2 border-b pb-1">{cat}</h4>
          <div className="divide-y divide-gray-100">
            {items.map(svc => (
              <div key={svc.id} className="flex items-center justify-between py-3 gap-4">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-800 text-sm">{svc.name}</p>
                  {svc.description && (
                    <p className="text-xs text-gray-500 truncate mt-0.5">{svc.description}</p>
                  )}
                  <p className="text-xs text-gray-400 mt-0.5">{formatDuration(svc.duration_minutes)}</p>
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  <span className="text-sm font-semibold text-gray-700">{svc.price_format}</span>
                  {branchSlug && (
                    <a
                      href={`/booking/${branchSlug}`}
                      className="text-xs px-3 py-1 rounded-full border border-current text-indigo-600 hover:bg-indigo-50 transition-colors"
                    >
                      Book
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}

export default function LandingServices({ branches }) {
  const [activeTab, setActiveTab] = useState(0)

  const multiBranch = branches.length > 1
  const activeBranch = branches[activeTab] || branches[0]

  return (
    <section id="services" className="py-16 px-4 bg-white">
      <div className="max-w-3xl mx-auto">
        <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">Services</h2>

        {multiBranch && (
          <div className="flex gap-2 mb-8 overflow-x-auto pb-2">
            {branches.map((b, i) => (
              <button
                key={b.id}
                onClick={() => setActiveTab(i)}
                className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
                  activeTab === i
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {b.name}
              </button>
            ))}
          </div>
        )}

        {activeBranch.services.length === 0
          ? <p className="text-center text-gray-400 py-8">No services available.</p>
          : <ServiceList services={activeBranch.services} branchSlug={activeBranch.slug} />
        }
      </div>
    </section>
  )
}
