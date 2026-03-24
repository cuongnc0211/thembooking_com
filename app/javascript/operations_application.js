import React from 'react'
import { createRoot } from 'react-dom/client'
import OperationsApp from './components/OperationsApp'

function mountOperations() {
  const container = document.getElementById('react-operations-root')
  if (!container || container.hasAttribute('data-react-mounted')) return

  const { branchId, branchName, dataUrl, bookingsUrl, servicesUrl } = container.dataset

  createRoot(container).render(
    <OperationsApp
      branchId={branchId}
      branchName={branchName}
      dataUrl={dataUrl}
      bookingsUrl={bookingsUrl}
      servicesUrl={servicesUrl}
    />
  )
  container.setAttribute('data-react-mounted', 'true')
}

document.addEventListener('DOMContentLoaded', mountOperations)
document.addEventListener('turbo:load', mountOperations)
