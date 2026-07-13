// Nuxt 4 hybride : routes publiques SSR, /admin/** en client-only (ssr:false).
// Versions figées (research.md R4). Style : Tailwind CSS v4 branché sur les
// design tokens (source unique : app/assets/tokens.css). Pas de bibliothèque de
// composants UI (Nuxt UI/PrimeVue toujours différés au cycle ADM/WEB).
import tailwindcss from '@tailwindcss/vite'

export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  future: { compatibilityVersion: 4 },

  modules: ['@nuxtjs/i18n', '@nuxt/eslint'],

  // main.css importe Tailwind + les tokens (voir app/assets/main.css).
  css: ['~/assets/main.css'],

  vite: {
    plugins: [tailwindcss()],
  },

  // Console d'administration : rendue côté client uniquement.
  routeRules: {
    '/admin/**': { ssr: false },
  },

  // Localisation fr dès la première page (constitution VII).
  i18n: {
    defaultLocale: 'fr',
    strategy: 'no_prefix',
    locales: [{ code: 'fr', language: 'fr-FR', name: 'Français', file: 'fr.json' }],
  },

  typescript: { strict: true },
})
