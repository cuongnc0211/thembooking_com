import React, { useState, useEffect } from 'react'
import LandingNav from './LandingNav'
import LandingHero from './LandingHero'
import LandingServices from './LandingServices'
import LandingGallery from './LandingGallery'
import LandingHours from './LandingHours'
import LandingContact from './LandingContact'

// Determines open/closed status from branch operating_hours (keyed by lowercase weekday name)
function OpenBadge({ operatingHours }) {
  const now = new Date()
  const dayName = now.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase()
  const hours = operatingHours?.[dayName]

  if (!hours || hours.closed) {
    return <span className="text-xs px-2 py-0.5 bg-red-100 text-red-700 rounded-full">Closed</span>
  }

  const currentTime = now.toTimeString().slice(0, 5) // "HH:MM"
  const isOpen = currentTime >= hours.open && currentTime < hours.close

  return isOpen
    ? <span className="text-xs px-2 py-0.5 bg-green-100 text-green-700 rounded-full">Open Now</span>
    : <span className="text-xs px-2 py-0.5 bg-red-100 text-red-700 rounded-full">Closed</span>
}

// Branch picker modal for multi-branch businesses
function BranchPickerModal({ branches, onClose }) {
  useEffect(() => {
    const handleEscape = (e) => { if (e.key === 'Escape') onClose() }
    document.addEventListener('keydown', handleEscape)
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', handleEscape)
      document.body.style.overflow = ''
    }
  }, [onClose])

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4" onClick={onClose}>
      <div
        className="bg-white rounded-2xl shadow-2xl max-w-sm w-full max-h-[80vh] overflow-y-auto"
        onClick={e => e.stopPropagation()}
        role="dialog"
        aria-label="Choose a location"
      >
        <div className="flex items-center justify-between p-5 border-b">
          <h3 className="text-lg font-semibold text-gray-900">Select a location</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-2xl leading-none" aria-label="Close">&times;</button>
        </div>
        <div className="p-4 space-y-2">
          {branches.map(branch => (
            <a
              key={branch.id}
              href={`/booking/${branch.slug}`}
              className="flex flex-col px-4 py-3 rounded-lg border border-gray-200 hover:border-indigo-400 hover:bg-indigo-50 transition-colors"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-medium text-gray-900 text-sm">{branch.name}</span>
                <OpenBadge operatingHours={branch.operating_hours} />
              </div>
              {branch.address && (
                <span className="text-xs text-gray-500 mt-1">{branch.address}</span>
              )}
              {branch.phone && (
                <span className="text-xs text-gray-400 mt-0.5">{branch.phone}</span>
              )}
            </a>
          ))}
        </div>
      </div>
    </div>
  )
}

export default function LandingApp({ business, branches, galleryPhotos }) {
  const [showBranchPicker, setShowBranchPicker] = useState(false)
  const config = business.landing_page_config || {}
  const themeColor = business.theme_color || '#4f46e5'

  return (
    <div style={{ '--theme-color': themeColor }}>
      <LandingNav
        config={config}
        themeColor={themeColor}
        hasGallery={galleryPhotos.length > 0}
      />

      <LandingHero
        business={business}
        branches={branches}
        onBookNow={() => setShowBranchPicker(true)}
        themeColor={themeColor}
      />

      {config.show_services !== false && (
        <LandingServices branches={branches} />
      )}

      {config.show_gallery !== false && galleryPhotos.length > 0 && (
        <LandingGallery photos={galleryPhotos} />
      )}

      {config.show_hours !== false && (
        <LandingHours branches={branches} />
      )}

      {config.show_contact !== false && (
        <LandingContact branches={branches} businessType={business.business_type} />
      )}

      {showBranchPicker && (
        <BranchPickerModal branches={branches} onClose={() => setShowBranchPicker(false)} />
      )}
    </div>
  )
}
