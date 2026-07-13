<script setup lang="ts">
// Console d'administration — rendue côté client uniquement (routeRules ssr:false).
const { t } = useI18n()
useHead({ title: () => t('adminTitle') })
</script>

<template>
  <main class="admin">
    <h1 class="admin__title">{{ t('adminTitle') }}</h1>
    <p class="admin__intro">{{ t('adminIntro') }}</p>
  </main>
</template>

<style scoped>
.admin {
  max-width: 1440px;
  margin: 0 auto;
  padding: var(--space-4) var(--screen-margin);
}
.admin__title {
  font: var(--font-title);
  color: var(--text);
}
.admin__intro {
  font: var(--font-body);
  color: var(--text-muted);
}
</style>
