# Corriger des bugs — Approche BMAD

Guide pour corriger proprement les bugs découverts lors des tests des features implémentées.

---

## Scénario 1 : Bug mineur / isolé dans une story existante

Utiliser **Quick Dev** (`bmad-quick-dev-new-preview`) — workflow idéal pour les corrections ponctuelles sur du code déjà en place.

Barry 🚀 (Quick Flow Solo Dev) prend en charge : décrire le bug, il clarifie, implémente le fix et fait une review dans un seul flux.

---

## Scénario 2 : Bug complexe qui touche plusieurs composants

Utiliser le cycle story classique :

1. **`bmad-create-story`** — Bob 🏃 (Scrum Master) crée une story dédiée au bugfix avec tout le contexte nécessaire (reproduction, fichiers impactés, comportement attendu)
2. **`bmad-dev-story`** — Amelia 💻 (Developer) implémente le fix en suivant la story
3. **`bmad-code-review`** — Review adversariale du fix (idéalement dans un **contexte frais** et avec un **LLM différent** si possible)
4. Si la review trouve des problèmes → retour à `bmad-dev-story` (DS)

---

## Scénario 3 : Bug systémique / architectural

Si le bug révèle un problème de fond (ex: pattern incorrect répliqué dans plusieurs stories) :

1. **`bmad-correct-course`** — Bob 🏃 évalue l'impact et propose un plan de correction (mise à jour du sprint plan, éventuellement des epics)
2. Puis cycle DS → CR pour chaque correction

---

## Bonnes pratiques BMAD pour les bugfixes

- **Toujours un contexte frais** : chaque workflow doit tourner dans une nouvelle fenêtre de conversation
- **Pour la code review** : utiliser un LLM différent si disponible (validation croisée)
- **Edge cases** : lancer `bmad-review-edge-case-hunter` sur le code suspect pour détecter d'autres cas limites non gérés
- **Tests automatisés** : après le fix, `bmad-qa-generate-e2e-tests` (Quinn 🧪) peut générer des tests E2E pour éviter les régressions

---

## Résumé rapide

| Situation | Workflow | Commande |
|-----------|----------|----------|
| Bug simple/ponctuel | Quick Dev | `bmad-quick-dev-new-preview` |
| Bug complexe | Cycle CS → DS → CR | `bmad-create-story` puis `bmad-dev-story` |
| Bug architectural | Correct Course | `bmad-correct-course` |
| Prévention régression | QA Automation | `bmad-qa-generate-e2e-tests` |
| Chasse aux edge cases | Edge Case Hunter | `bmad-review-edge-case-hunter` |
