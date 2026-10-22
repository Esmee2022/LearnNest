import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
export default defineConfig({ root, plugins: [react()], server: { port: 5173 }, build: { outDir: 'apps/web/dist', emptyOutDir: true } });
