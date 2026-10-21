import { resolve } from 'node:path';
import { defineConfig } from 'vite';

export default defineConfig({
  // The sample configurations in ../config are used when running in a normal browser.
  server: { port: 5173, strictPort: true, fs: { allow: ['..'] } },
  clearScreen: false,
  build: {
    target: 'es2022',
    rollupOptions: {
      input: {
        home: resolve(__dirname, 'index.html'),
        bar: resolve(__dirname, 'bar.html'),
      },
    },
  },
});
