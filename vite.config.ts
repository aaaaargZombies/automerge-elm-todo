import { defineConfig } from "vite";
import path from "path";
import elmPlugin from "vite-plugin-elm";
import wasmPlugin from "vite-plugin-wasm";

export default defineConfig({
  plugins: [elmPlugin(), wasmPlugin()],
  build: { target: "esnext" },
  resolve: {
    alias: {
      "~": path.resolve(import.meta.dirname, "."),
    },
  },
  worker: {
    format: "es",
    plugins: () => [wasmPlugin()],
  },
});
