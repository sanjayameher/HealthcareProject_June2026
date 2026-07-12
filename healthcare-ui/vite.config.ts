import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5002,
    proxy: {
      '/patient-svc': {
        target: 'http://localhost:7081',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/patient-svc/, ''),
      },
      '/clinical-svc': {
        target: 'http://localhost:7082',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/clinical-svc/, ''),
      },
      '/billing-svc': {
        target: 'http://localhost:7083',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/billing-svc/, ''),
      },
      '/audit-svc': {
        target: 'http://localhost:7085',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/audit-svc/, ''),
      },
      '/portal-svc': {
        target: 'http://localhost:7084',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/portal-svc/, ''),
      },
    },
  },
});
