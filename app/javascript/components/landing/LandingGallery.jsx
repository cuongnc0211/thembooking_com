import React, { useState } from 'react'
import GalleryLightbox from './GalleryLightbox'

export default function LandingGallery({ photos }) {
  const [lightboxIndex, setLightboxIndex] = useState(null)

  if (!photos || photos.length === 0) return null

  const total = photos.length

  function openAt(i) { setLightboxIndex(i) }
  function close() { setLightboxIndex(null) }
  function prev() { setLightboxIndex(i => (i - 1 + total) % total) }
  function next() { setLightboxIndex(i => (i + 1) % total) }

  return (
    <section id="gallery" className="py-16 px-4 bg-gray-50">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-2xl font-bold text-gray-900 mb-8 text-center">Gallery</h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {photos.map((photo, i) => (
            <button
              key={photo.id}
              onClick={() => openAt(i)}
              className="group relative aspect-square overflow-hidden rounded-lg bg-gray-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <img
                src={photo.thumbnail_url}
                alt={photo.caption || `Photo ${i + 1}`}
                loading="lazy"
                className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
              />
              {photo.caption && (
                <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors flex items-end">
                  <p className="px-3 py-2 text-white text-xs font-medium opacity-0 group-hover:opacity-100 transition-opacity">
                    {photo.caption}
                  </p>
                </div>
              )}
            </button>
          ))}
        </div>
      </div>

      {lightboxIndex !== null && (
        <GalleryLightbox
          photos={photos}
          currentIndex={lightboxIndex}
          onClose={close}
          onPrev={prev}
          onNext={next}
        />
      )}
    </section>
  )
}
