import React from 'react'
import { createRoot } from 'react-dom/client'
import BookingApp from './components/BookingApp'

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('react-booking-root')

  if (container) {
    const root = createRoot(container)
    const { branchSlug, business, services } = container.dataset

    root.render(
      <BookingApp
        branchSlug={branchSlug}
        business={JSON.parse(business)}
        services={JSON.parse(services)}
      />
    )
  }
})

// Support Turbo Drive navigation
document.addEventListener('turbo:load', () => {
  const container = document.getElementById('react-booking-root')

  if (container && !container.hasAttribute('data-react-mounted')) {
    const root = createRoot(container)
    const { branchSlug, business, services } = container.dataset

    root.render(
      <BookingApp
        branchSlug={branchSlug}
        business={JSON.parse(business)}
        services={JSON.parse(services)}
      />
    )

    container.setAttribute('data-react-mounted', 'true')
  }
})
