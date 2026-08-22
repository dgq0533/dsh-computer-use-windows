import { readdir } from 'node:fs/promises'
import { spawnSync } from 'node:child_process'

const files = ['index.js', ...(await readdir('lib')).filter((name) => name.endsWith('.js')).map((name) => `lib/${name}`)]
for (const file of files) {
  const result = spawnSync(process.execPath, ['--check', file], { stdio: 'inherit' })
  if (result.status !== 0) process.exit(result.status ?? 1)
}
console.log(`Syntax OK: ${files.length} JavaScript files`)
