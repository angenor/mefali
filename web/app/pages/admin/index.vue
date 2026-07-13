<script setup lang="ts">
// Console d'administration — rendue côté client uniquement (routeRules ssr:false).
// Style : utilitaires Tailwind pilotés par les design tokens.
const { t } = useI18n()
useHead({ title: () => t('adminTitle') })
</script>

<template>
  <main class="mx-auto max-w-[1440px] px-4 py-6">
    <h1 class="text-title font-semibold text-text">{{ t('adminTitle') }}</h1>
    <p class="mt-4 text-body text-text-muted">{{ t('adminIntro') }}</p>
  </main>
</template>
