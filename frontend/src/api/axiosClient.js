import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

export const ACCESS_TOKEN_KEY = 'smart_agrotech_access_token'
export const REFRESH_TOKEN_KEY = 'smart_agrotech_refresh_token'

export function getAccessToken() {
  return localStorage.getItem(ACCESS_TOKEN_KEY)
}

export function getRefreshToken() {
  return localStorage.getItem(REFRESH_TOKEN_KEY)
}

export function setTokens({ access, refresh }) {
  if (access) localStorage.setItem(ACCESS_TOKEN_KEY, access)
  if (refresh) localStorage.setItem(REFRESH_TOKEN_KEY, refresh)
}

export function clearTokens() {
  localStorage.removeItem(ACCESS_TOKEN_KEY)
  localStorage.removeItem(REFRESH_TOKEN_KEY)
}

const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use((requestConfig) => {
  const token = getAccessToken()
  if (token) {
    requestConfig.headers.Authorization = `Bearer ${token}`
  }
  return requestConfig
})

let isRefreshing = false
let pendingRequests = []

function resolvePendingRequests(error, token) {
  pendingRequests.forEach(({ resolve, reject }) => {
    if (error) {
      reject(error)
    } else {
      resolve(token)
    }
  })
  pendingRequests = []
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config
    const isAuthEndpoint = originalRequest?.url?.includes('/auth/login/') ||
      originalRequest?.url?.includes('/auth/refresh/')

    if (error.response?.status === 401 && !originalRequest._retry && !isAuthEndpoint) {
      const refreshToken = getRefreshToken()
      if (!refreshToken) {
        clearTokens()
        return Promise.reject(error)
      }

      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          pendingRequests.push({ resolve, reject })
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return apiClient(originalRequest)
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      try {
        const { data } = await axios.post(`${API_URL}/auth/refresh/`, {
          refresh: refreshToken,
        })
        setTokens({ access: data.access })
        resolvePendingRequests(null, data.access)
        originalRequest.headers.Authorization = `Bearer ${data.access}`
        return apiClient(originalRequest)
      } catch (refreshError) {
        resolvePendingRequests(refreshError, null)
        clearTokens()
        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }

    return Promise.reject(error)
  },
)

export default apiClient
