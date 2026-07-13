<script setup lang="ts">
// Page publique — rendue en SSR (défaut). Chaînes en i18n fr.
const { t } = useI18n()
useHead({ title: () => t('siteTitle') })
</script>

<template>
  <main class="hero">
    <h1 class="hero__title">{{ t('siteTitle') }}</h1>
    <p class="hero__tagline">{{ t('heroTagline') }}</p>
    <p class="hero__intro">{{ t('publicIntro') }}</p>
  </main>
</template>

<style scoped>
.hero {
  max-width: 720px;
  margin: 0 auto;
  padding: var(--space-5) var(--screen-margin);
}
.hero__title {
  font: var(--font-display);
  color: var(--primary);
  margin: 0 0 var(--space-3);
}
.hero__tagline {
  font: var(--font-title);
  margin: 0 0 var(--space-3);
}
.hero__intro {
  font: var(--font-body);
  color: var(--text-muted);
}
</style>
