import axios from 'axios'
import { useAuthStore } from '../store/auth'

const api = axios.create({
  baseURL: '/api/v1',
  withCredentials: true,
  headers: { 'Content-Type': 'application/json' },
})

// Attach access token
api.interceptors.request.use((config) => {
  const auth = useAuthStore()
  if (auth.accessToken) {
    config.headers.Authorization = `Bearer ${auth.accessToken}`
  }
  return config
})

// Refresh on 401
api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    if (error.response?.status === 401 && !original._retry) {
      original._retry = true
      try {
        const auth = useAuthStore()
        await auth.refresh()
        original.headers.Authorization = `Bearer ${auth.accessToken}`
        return api(original)
      } catch {
        const auth = useAuthStore()
        auth.logout()
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export default api