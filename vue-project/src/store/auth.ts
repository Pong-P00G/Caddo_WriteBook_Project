import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api/Api'
import type { User, AuthTokens } from './types/interface'

export const useAuthStore = defineStore('auth', () => {
  const user         = ref<User | null>(null)
  const accessToken  = ref<string | null>(null)

  const isAuthenticated = computed(() => !!user.value)

  function init() {
    const stored = localStorage.getItem('wb_access_token')
    if (stored) accessToken.value = stored
    const storedUser = localStorage.getItem('wb_user')
    if (storedUser) user.value = JSON.parse(storedUser)
  }

  async function login(email: string, password: string) {
    const { data } = await api.post<AuthTokens>('/auth/login', { email, password })
    setTokens(data)
  }

  async function register(name: string, email: string, password: string) {
    const { data } = await api.post<AuthTokens>('/auth/register', { name, email, password })
    setTokens(data)
  }

  async function refresh() {
    const { data } = await api.post<{ accessToken: string }>('/auth/refresh')
    accessToken.value = data.accessToken
    localStorage.setItem('wb_access_token', data.accessToken)
  }

  async function logout() {
    try { await api.post('/auth/logout') } catch { /* ignore */ }
    user.value = null
    accessToken.value = null
    localStorage.removeItem('wb_access_token')
    localStorage.removeItem('wb_user')
  }

  function setTokens(tokens: AuthTokens) {
    user.value = tokens.user
    accessToken.value = tokens.accessToken
    localStorage.setItem('wb_access_token', tokens.accessToken)
    localStorage.setItem('wb_user', JSON.stringify(tokens.user))
  }

  return { user, accessToken, isAuthenticated, init, login, register, refresh, logout }
})