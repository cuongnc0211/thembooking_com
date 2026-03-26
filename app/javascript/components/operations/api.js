import { jsonHeaders } from './csrf'

export async function updateBookingStatus(bookingsUrl, bookingId, action) {
  const res = await fetch(`${bookingsUrl}/${bookingId}/${action}`, {
    method: 'PATCH',
    headers: jsonHeaders()
  })
  if (!res.ok) {
    const data = await res.json().catch(() => ({}))
    throw new Error(data.errors?.join(', ') || `Failed to ${action}`)
  }
  return res.json()
}

export async function createBooking(bookingsUrl, bookingData) {
  const res = await fetch(bookingsUrl, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify({ booking: bookingData })
  })
  const data = await res.json()
  if (!res.ok) throw new Error(data.errors?.join(', ') || 'Failed to create booking')
  return data
}

export async function fetchServices(servicesUrl) {
  const res = await fetch(servicesUrl, { headers: { 'Accept': 'application/json' } })
  if (!res.ok) throw new Error('Failed to load services')
  return res.json()
}
