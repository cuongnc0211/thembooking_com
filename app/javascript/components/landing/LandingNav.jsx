import React, { useState } from 'react'

const NAV_LINKS = [
  { id: 'services', label: 'Services', configKey: 'show_services' },
  { id: 'gallery',  label: 'Gallery',  configKey: 'show_gallery' },
  { id: 'hours',    label: 'Hours',    configKey: 'show_hours' },
  { id: 'contact',  label: 'Contact',  configKey: 'show_contact' },
]

function scrollTo(id) {
  const el = document.getElementById(id)
  if (el) el.scrollIntoView({ behavior: 'smooth' })
}

export default function LandingNav({ config, themeColor, hasGallery }) {
  const [open, setOpen] = useState(false)

  const visibleLinks = NAV_LINKS.filter(link => {
    if (!config[link.configKey]) return false
    if (link.id === 'gallery' && !hasGallery) return false
    return true
  })

  if (visibleLinks.length === 0) return null

  return (
    <nav className="sticky top-0 z-40 bg-white/90 backdrop-blur border-b border-gray-100 shadow-sm">
      <div className="max-w-5xl mx-auto px-4 flex items-center justify-between h-14">
        {/* Desktop links */}
        <div className="hidden sm:flex gap-6">
          {visibleLinks.map(link => (
            <button
              key={link.id}
              onClick={() => scrollTo(link.id)}
              className="text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
            >
              {link.label}
            </button>
          ))}
        </div>

        {/* Mobile hamburger */}
        <button
          className="sm:hidden p-2 rounded text-gray-600 hover:text-gray-900"
          onClick={() => setOpen(o => !o)}
          aria-label="Toggle menu"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            {open
              ? <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              : <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            }
          </svg>
        </button>

        <div className="hidden sm:block w-4" />
      </div>

      {/* Mobile dropdown */}
      {open && (
        <div className="sm:hidden border-t border-gray-100 bg-white px-4 py-2 flex flex-col gap-1">
          {visibleLinks.map(link => (
            <button
              key={link.id}
              onClick={() => { scrollTo(link.id); setOpen(false) }}
              className="text-sm font-medium text-gray-600 hover:text-gray-900 py-2 text-left"
            >
              {link.label}
            </button>
          ))}
        </div>
      )}
    </nav>
  )
}
