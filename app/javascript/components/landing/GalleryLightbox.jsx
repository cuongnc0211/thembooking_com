import React, { useEffect } from 'react'

export default function GalleryLightbox({ photos, currentIndex, onClose, onPrev, onNext }) {
  const photo = photos[currentIndex]

  useEffect(() => {
    function onKey(e) {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowLeft') onPrev()
      if (e.key === 'ArrowRight') onNext()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose, onPrev, onNext])

  if (!photo) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/90"
      onClick={onClose}
    >
      {/* Prev */}
      <button
        className="absolute left-4 p-3 text-white hover:text-gray-300 text-2xl"
        onClick={e => { e.stopPropagation(); onPrev() }}
        aria-label="Previous"
      >
        &#8592;
      </button>

      {/* Image */}
      <div className="relative max-w-4xl max-h-screen px-16" onClick={e => e.stopPropagation()}>
        <img
          src={photo.image_url}
          alt={photo.caption || ''}
          className="max-h-[80vh] max-w-full object-contain rounded shadow-2xl"
        />
        {photo.caption && (
          <p className="mt-3 text-center text-white/80 text-sm">{photo.caption}</p>
        )}
        <p className="text-center text-white/40 text-xs mt-1">{currentIndex + 1} / {photos.length}</p>
      </div>

      {/* Next */}
      <button
        className="absolute right-4 p-3 text-white hover:text-gray-300 text-2xl"
        onClick={e => { e.stopPropagation(); onNext() }}
        aria-label="Next"
      >
        &#8594;
      </button>

      {/* Close */}
      <button
        className="absolute top-4 right-4 text-white hover:text-gray-300 text-2xl"
        onClick={onClose}
        aria-label="Close"
      >
        &times;
      </button>
    </div>
  )
}
