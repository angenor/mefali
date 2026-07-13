// Nuxt 4 hybride : routes publiques SSR, /admin/** en client-only (ssr:false).
// Versions figées (research.md R4). Aucune bibliothèque UI (choix différé ADM/WEB).
export default defineNuxtConfig({
  compatibilityDate: '2026-07-01',
  future: { compatibilityVersion: 4 },

  modules: ['@nuxtjs/i18n', '@nuxt/eslint'],

  css: ['~/assets/tokens.css'],

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
