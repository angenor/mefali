<script setup lang="ts">
// Page publique — rendue en SSR (défaut). Style : utilitaires Tailwind pilotés
// par les design tokens. Chaînes en i18n fr.
const { t } = useI18n()
useHead({ title: () => t('siteTitle') })
</script>

<template>
  <main class="mx-auto max-w-3xl px-4 py-8">
    <h1 class="mb-4 text-display font-bold text-primary">{{ t('siteTitle') }}</h1>
    <p class="mb-4 text-title font-semibold text-text">{{ t('heroTagline') }}</p>
    <p class="text-body text-text-muted">{{ t('publicIntro') }}</p>
  </main>
</template>
