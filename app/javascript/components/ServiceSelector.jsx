import React from 'react'

export default function ServiceSelector({
  services,
  selectedServices,
  onServicesChange,
  totalDuration,
  totalPrice
}) {
  const handleToggle = (serviceId) => {
    const id = String(serviceId)
    if (selectedServices.includes(id)) {
      onServicesChange(selectedServices.filter(s => s !== id))
    } else {
      onServicesChange([...selectedServices, id])
    }
  }

  const formatPrice = (priceInVND) => {
    console.log(`[ServiceSelector] formatPrice received:`, priceInVND)
    return (priceInVND).toLocaleString('vi-VN') + ' ₫'
  }

  return (
    <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-slate-900">Select Services</h2>
        {selectedServices.length > 0 && (
          <div className="flex items-center gap-4 px-4 py-2 bg-gradient-to-r from-blue-50 to-purple-50 rounded-full">
            <div className="text-sm">
              <span className="font-semibold text-blue-700">{totalDuration}</span>
              <span className="text-slate-600"> min</span>
            </div>
            <div className="w-px h-4 bg-slate-300" />
            <div className="text-sm">
              <span className="font-semibold text-purple-700">{formatPrice(totalPrice)}</span>
            </div>
          </div>
        )}
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {services.map((service) => {
          const isSelected = selectedServices.includes(String(service.id))

          return (
            <button
              key={service.id}
              type="button"
              onClick={() => handleToggle(service.id)}
              className={`
                relative p-5 rounded-xl border-2 text-left transition-all duration-200
                ${isSelected
                  ? 'border-blue-500 bg-gradient-to-br from-blue-50 to-purple-50 shadow-md scale-[1.02]'
                  : 'border-slate-200 bg-white hover:border-slate-300 hover:shadow-sm'}
              `}
            >
              {/* Checkbox indicator */}
              <div className="absolute top-3 right-3">
                <div className={`
                  w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors
                  ${isSelected ? 'border-blue-500 bg-blue-500' : 'border-slate-300 bg-white'}
                `}>
                  {isSelected && (
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  )}
                </div>
              </div>

              <div className="pr-8">
                <h3 className={`font-semibold text-lg mb-1 ${isSelected ? 'text-blue-900' : 'text-slate-900'}`}>
                  {service.name}
                </h3>

                {service.description && (
                  <p className={`text-sm mb-3 line-clamp-2 ${isSelected ? 'text-slate-700' : 'text-slate-500'}`}>
                    {service.description}
                  </p>
                )}

                <div className="flex items-center gap-4 mt-3">
                  <div className="flex items-center gap-1.5">
                    <svg className={`w-4 h-4 ${isSelected ? 'text-blue-600' : 'text-slate-400'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span className={`text-sm font-medium ${isSelected ? 'text-slate-700' : 'text-slate-600'}`}>
                      {service.duration_minutes} min
                    </span>
                  </div>

                  <div className={`text-lg font-bold ${isSelected ? 'text-purple-700' : 'text-slate-900'}`}>
                    {formatPrice(service.price_cents)}
                  </div>
                </div>
              </div>
            </button>
          )
        })}
      </div>

      {selectedServices.length === 0 && (
        <div className="mt-6 text-center py-4">
          <p className="text-slate-500 text-sm">
            Select one or more services to continue
          </p>
        </div>
      )}
    </div>
  )
}
