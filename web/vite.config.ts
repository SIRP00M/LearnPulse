import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

// Static SPA for Cloudflare Pages: absolute asset paths from the site root, hashed file names, no source maps.
export default defineConfig({
  plugins: [react()],
  base: '/',
  build: { sourcemap: false, target: 'es2022', chunkSizeWarningLimit: 600 },
  server: { port: 5173, strictPort: true, host: '127.0.0.1' },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
    css: false,
  },
});
