import { createRequire } from 'node:module'
import { realpathSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const pluginRoot = resolve(here, '..')
const profileRoot = process.env.DSH_PROFILE_ROOT
if (!profileRoot) throw new Error('DSH_PROFILE_ROOT is required')
const pluginRequire = createRequire(resolve(pluginRoot, 'index.js'))
const profileRequire = createRequire(resolve(profileRoot, 'package.json'))
const pluginPath = realpathSync(pluginRequire.resolve('@deepseek-ai/dsh-tools/package.json'))
const hostPath = realpathSync(profileRequire.resolve('@deepseek-ai/dsh-tools/package.json'))
if (pluginPath !== hostPath) {
  console.error(JSON.stringify({ ok: false, pluginPath, hostPath }, null, 2))
  process.exit(1)
}
console.log(JSON.stringify({ ok: true, pluginPath, hostPath }, null, 2))
