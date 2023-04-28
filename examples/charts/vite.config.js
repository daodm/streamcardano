/* ~\~ language=JavaScript filename=vite.config.js */
/* ~\~ begin <<README.md|vite.config.js>>[init] */
import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

console.log(elmPlugin.plugin())

export default defineConfig({
  plugins: [elmPlugin.plugin()],
  base: '/streamcardano/',
  css: {
    preprocessorOptions: {
      scss: {
        includePaths: ['node_modules'],
      },
    },
  }
})
/* ~\~ end */
