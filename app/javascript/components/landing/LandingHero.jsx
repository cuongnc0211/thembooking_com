import React from 'react'

function BusinessInitials({ name }) {
  const initials = name
    .split(' ')
    .slice(0, 2)
    .map(w => w[0])
    .join('')
    .toUpperCase()
  return (
    <span className="text-2xl font-bold text-white">{initials}</span>
  )
}

export default function LandingHero({ business, branches, onBookNow, themeColor }) {
  const { name, headline, description, logo_url, cover_photo_url } = business

  function handleBookNow() {
    if (branches.length === 1) {
      window.location.href = `/${branches[0].slug}`
    } else {
      onBookNow()
    }
  }

  const bgStyle = cover_photo_url
    ? { backgroundImage: `linear-gradient(to bottom, rgba(0,0,0,0.4), rgba(0,0,0,0.6)), url(${cover_photo_url})`, backgroundSize: 'cover', backgroundPosition: 'center' }
    : { background: 'linear-gradient(135deg, #1e3a5f 0%, #2d6a9f 100%)' }

  return (
    <section
      id="hero"
      className="relative min-h-[70vh] flex flex-col items-center justify-center text-white text-center px-4 py-16"
      style={bgStyle}
    >
      {/* Logo circle */}
      <div className="mb-6 w-24 h-24 rounded-full border-4 border-white/80 overflow-hidden flex items-center justify-center bg-white/20 backdrop-blur-sm shadow-lg">
        {logo_url
          ? <img src={logo_url} alt={name} className="w-full h-full object-cover" />
          : <BusinessInitials name={name} />
        }
      </div>

      <h1 className="text-4xl md:text-5xl font-bold mb-2 drop-shadow">{name}</h1>

      {headline && (
        <h2 className="text-xl md:text-2xl font-light mb-4 text-white/90 drop-shadow">{headline}</h2>
      )}

      {description && (
        <p className="max-w-xl text-base text-white/80 mb-8 leading-relaxed">{description}</p>
      )}

      <button
        onClick={handleBookNow}
        className="px-8 py-3 rounded-full text-white font-semibold text-lg shadow-lg hover:opacity-90 active:scale-95 transition-all"
        style={{ backgroundColor: themeColor || '#2d6a9f' }}
      >
        {business.landing_page_config?.custom_cta_text || 'Book Now'}
      </button>
    </section>
  )
}
