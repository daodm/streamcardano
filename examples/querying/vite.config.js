/* ~\~ language=JavaScript filename=vite.config.js */
import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

console.log(elmPlugin.plugin())
export default defineConfig({
  plugins: [elmPlugin.plugin()]
})
