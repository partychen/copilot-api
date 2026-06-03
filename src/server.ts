import { Hono } from "hono"
import { cors } from "hono/cors"
import { logger } from "hono/logger"

import { completionRoutes } from "./routes/chat-completions/route"
import { embeddingRoutes } from "./routes/embeddings/route"
import { messageRoutes } from "./routes/messages/route"
import { modelRoutes } from "./routes/models/route"

export const server = new Hono()

server.use(logger())
server.use(cors())

// Optional Bearer-token gate for public exposure (e.g. via Cloudflare Tunnel).
// Enabled only when PROXY_AUTH_TOKEN is set; "/" health check stays open.
const PROXY_AUTH_TOKEN = process.env.PROXY_AUTH_TOKEN
if (PROXY_AUTH_TOKEN) {
  server.use("*", async (c, next) => {
    if (c.req.path === "/") return next()
    const header = c.req.header("authorization") ?? ""
    const token = header.startsWith("Bearer ") ? header.slice(7) : ""
    // x-api-key fallback for Anthropic SDK style clients
    const apiKey = c.req.header("x-api-key") ?? ""
    if (token !== PROXY_AUTH_TOKEN && apiKey !== PROXY_AUTH_TOKEN) {
      return c.json({ error: "Unauthorized" }, 401)
    }
    return next()
  })
}

server.get("/", (c) => c.text("Server running"))

server.route("/chat/completions", completionRoutes)
server.route("/models", modelRoutes)
server.route("/embeddings", embeddingRoutes)

// Compatibility with tools that expect v1/ prefix
server.route("/v1/chat/completions", completionRoutes)
server.route("/v1/models", modelRoutes)
server.route("/v1/embeddings", embeddingRoutes)

// Anthropic compatible endpoints
server.route("/v1/messages", messageRoutes)
