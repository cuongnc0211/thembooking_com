import { useState, useEffect, useCallback, useRef } from 'react'

const POLL_INTERVAL = 30000

export function useOperationsData(dataUrl) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const intervalRef = useRef(null)

  const fetchData = useCallback(async () => {
    try {
      const res = await fetch(dataUrl, { headers: { 'Accept': 'application/json' } })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const json = await res.json()
      setData(json)
      setError(null)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [dataUrl])

  useEffect(() => {
    fetchData()
    intervalRef.current = setInterval(fetchData, POLL_INTERVAL)
    return () => clearInterval(intervalRef.current)
  }, [fetchData])

  const refresh = useCallback(() => { fetchData() }, [fetchData])

  return { data, loading, error, refresh }
}
