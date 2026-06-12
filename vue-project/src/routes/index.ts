import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/store/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    // Public
    {
      path: '/',
      component: () => import('../views/HomeViews.vue'),
    },
    {
      path: '/login',
      component: () => import('../views/auth/Login.vue'),
      meta: { guest: true },
    },
    {
      path: '/register',
      component: () => import('../views/auth/Register.vue'),
      meta: { guest: true },
    },

    // App shell (auth required)
    {
      path: '/app',
      component: () => import('../components/layout/AppLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        { path: '', redirect: '/app/library' },
        { path: 'library', component: () => import('../views/Library.vue') },
        { path: 'books/new', component: () => import('../views/NewBook.vue') },
        { path: 'books/:bookId', component: () => import('../views/Books.vue') },
        {
          path: 'books/:bookId/chapters/:chapterId/edit',
          component: () => import('../views/Editor.vue'),
        },
        { path: 'settings', component: () => import('../views/Settings.vue') },
      ],
    },

    // Public book reading
    {
      path: '/read/:slug',
      component: () => import('../views/ReadViews.vue'),
    },

    // 404
    {
      path: '/:pathMatch(.*)*',
      component: () => import('../views/NotFoundView.vue'),
    },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }
  if (to.meta.guest && auth.isAuthenticated) {
    return { path: '/app/library' }
  }
})

export default router