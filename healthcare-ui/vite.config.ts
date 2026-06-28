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
    port: 3000,
    proxy: {
      '/patient-svc': {
        target: 'http://localhost:8081',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/patient-svc/, ''),
      },
      '/clinical-svc': {
        target: 'http://localhost:8082',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/clinical-svc/, ''),
      },
      '/billing-svc': {
        target: 'http://localhost:8083',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/billing-svc/, ''),
      },
      '/audit-svc': {
        target: 'http://localhost:8085',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/audit-svc/, ''),
      },
      '/portal-svc': {
        target: 'http://localhost:8084',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/portal-svc/, ''),
      },
    },
  },
});
