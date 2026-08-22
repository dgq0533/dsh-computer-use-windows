import test from 'node:test'
import assert from 'node:assert/strict'

import { setSnapshot, clearSnapshot, requireFreshSnapshot, resolveToken } from '../lib/snapshot.js'
import { screenPointOf, windowLocalOf, SCREEN_SCALE } from '../lib/human.js'
import { isDangerousLabel } from '../lib/guard.js'

test('fresh snapshots are required for unscoped actions', () => {
  clearSnapshot()
  assert.throws(() => requireFreshSnapshot(1000), /screen_observe/)
  setSnapshot({ at: Date.now() - 2000, ttlMs: 1000, entries: new Map() })
  assert.throws(() => requireFreshSnapshot(1000), /过期/)
})

test('element tokens resolve only from a fresh snapshot', () => {
  setSnapshot({ at: Date.now(), pid: 7, windowId: 9, entries: new Map([[3, { token: 's00000001:3' }]]) })
  assert.deepEqual(resolveToken(3, 1000), { pid: 7, windowId: 9, token: 's00000001:3', role: undefined, label: undefined })
})

test('Windows screenshot coordinates are not multiplied by a fixed Retina scale', () => {
  assert.equal(SCREEN_SCALE, 1)
  assert.deepEqual(windowLocalOf(150, 260, { windowBounds: { x: 50, y: 60 } }), { x: 100, y: 200 })
  assert.deepEqual(screenPointOf({ x: 150, y: 260 }, {}), { sx: 150, sy: 260 })
})

test('package exposes the installable Windows bundle', async () => {
  const fs = await import('node:fs/promises')
  const pkg = JSON.parse(await fs.readFile(new URL('../package.json', import.meta.url), 'utf8'))
  assert.equal(pkg.dsh.bundle.patch, 'cordis.patch.yml')
  assert.equal(pkg.version, '0.2.3')
  assert.ok(pkg.files.includes('README_EN.md'))
  assert.ok(pkg.files.includes('tools/'))
})

test('dangerous labels are detected', () => {
  assert.equal(isDangerousLabel('永久删除'), true)
  assert.equal(isDangerousLabel('保存草稿'), false)
})
