import React from 'react'

// Displays a card list of active branches for the customer to pick from.
export default function BranchSelector({ branches, onSelect }) {
  return (
    <div className="bg-white rounded-2xl shadow-lg border border-slate-100 p-6">
      <h2 className="text-2xl font-bold text-slate-900 mb-2">Select a Branch</h2>
      <p className="text-slate-500 mb-6">Choose the location most convenient for you.</p>

      <div className="space-y-3">
        {branches.map(branch => (
          <button
            key={branch.slug}
            onClick={() => onSelect(branch)}
            className="w-full text-left px-5 py-4 rounded-xl border-2 border-slate-200 hover:border-blue-500 hover:bg-blue-50 transition-all group"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="font-semibold text-slate-900 group-hover:text-blue-700">{branch.name}</p>
                {branch.address && (
                  <p className="text-sm text-slate-500 mt-0.5">{branch.address}</p>
                )}
                {branch.phone && (
                  <p className="text-sm text-slate-400 mt-0.5">{branch.phone}</p>
                )}
              </div>
              <svg className="w-5 h-5 text-slate-300 group-hover:text-blue-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </button>
        ))}
      </div>
    </div>
  )
}
