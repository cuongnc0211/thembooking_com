import React from 'react'
import { createRoot } from 'react-dom/client'
import BookingApp from './components/BookingApp'
import LandingApp from './components/landing/LandingApp'

function mountBookingApp(container) {
  const { businessSlug, business, branches } = container.dataset
  createRoot(container).render(
    <BookingApp
      businessSlug={businessSlug}
      business={JSON.parse(business)}
      branches={JSON.parse(branches)}
    />
  )
}

function mountLandingApp(container) {
  const { business, branches, galleryPhotos } = container.dataset
  createRoot(container).render(
    <LandingApp
      business={JSON.parse(business)}
      branches={JSON.parse(branches)}
      galleryPhotos={JSON.parse(galleryPhotos)}
    />
  )
}

document.addEventListener('DOMContentLoaded', () => {
  const bookingRoot = document.getElementById('react-booking-root')
  if (bookingRoot) mountBookingApp(bookingRoot)

  const landingRoot = document.getElementById('react-landing-root')
  if (landingRoot) mountLandingApp(landingRoot)
})

// Support Turbo Drive navigation
document.addEventListener('turbo:load', () => {
  const bookingRoot = document.getElementById('react-booking-root')
  if (bookingRoot && !bookingRoot.hasAttribute('data-react-mounted')) {
    mountBookingApp(bookingRoot)
    bookingRoot.setAttribute('data-react-mounted', 'true')
  }

  const landingRoot = document.getElementById('react-landing-root')
  if (landingRoot && !landingRoot.hasAttribute('data-react-mounted')) {
    mountLandingApp(landingRoot)
    landingRoot.setAttribute('data-react-mounted', 'true')
  }
})
