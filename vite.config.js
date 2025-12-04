import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { VitePWA } from "vite-plugin-pwa";

// https://vitejs.dev/config/
export default defineConfig({
  base: "/pbm2/",
  plugins: [
    tailwindcss(),
    react({
      include: ["**/*.res.mjs"],
    }),
    VitePWA({
      injectRegister: "script",
      registerType: "autoUpdate",
      includeAssets: ["vite.svg"],
      manifest: {
        name: "Parabible Mobile",
        short_name: "Parabible",
        description: "Mobile Bible study application",
        theme_color: "#ffffff",
        background_color: "#ffffff",
        display: "standalone",
        icons: [
          {
            src: "/vite.svg",
            sizes: "any",
            type: "image/svg+xml",
            purpose: "any maskable",
          },
        ],
      },
      workbox: {
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/dev\.parabible\.com\/api\/.*/i,
            handler: "CacheFirst",
            options: {
              cacheName: "parabible-api-cache",
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 31, // 31 days
              },
              cacheableResponse: {
                statuses: [0, 200],
              },
            },
          },
        ],
      },
    }),
  ],
  server: {
    watch: {
      // We ignore ReScript build artifacts to avoid unnecessarily triggering HMR on incremental compilation
      ignored: ["**/lib/bs/**", "**/lib/ocaml/**", "**/lib/rescript.lock"],
    },
  },
});
