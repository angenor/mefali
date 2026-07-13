import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'

const tokens = readFileSync(
  fileURLToPath(new URL('../app/assets/tokens.css', import.meta.url)),
  'utf8',
)

describe('tokens.css', () => {
  it('porte la couleur primaire de docs/design/tokens.md', () => {
    expect(tokens).toContain('--primary: #F97316')
  })

  it('porte le plancher typographique 16px', () => {
    expect(tokens).toContain('--font-body: 400 16px/1.5')
  })
})
