import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { which } = require('zx') as typeof import('zx');

/**
 * Check whether the current environment has the required tools available.
 */
export async function checkRequiredToolsAsync(tools: string[]): Promise<void> {
  const results = await Promise.all(tools.map((tool) => which(tool, { nothrow: true })));
  for (const [index, result] of results.entries()) {
    if (!result) {
      throw new Error(`Missing required tool: ${tools[index]}`);
    }
  }
}
