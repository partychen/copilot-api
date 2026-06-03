# 一键部署 (本地 + Cloudflare Tunnel)

把本机的 `copilot-api` 通过你自己的域名暴露出去，**无需公网 IP / 无需开端口 / 自动 HTTPS**。

## 架构

```
你的域名 (Cloudflare)
       │
       ▼  HTTPS
  Cloudflare Edge
       │
       ▼  加密隧道 (出站连接, 不需要开端口)
  你本机的 cloudflared
       │
       ▼  HTTP localhost:4141
  copilot-api (Bun)
```

## 准备工作 (Cloudflare 侧, 5 分钟)

1. 域名已托管在 Cloudflare (NS 已切过去)
2. 打开 [Cloudflare Zero Trust 后台](https://one.dash.cloudflare.com/) → **Networks → Tunnels → Create a tunnel**
3. 类型选 **Cloudflared**, 起个名字 (例如 `copilot-api`)
4. 创建后会显示一段安装命令, **复制其中的 token**(`--token` 后面那段长字符串)
5. 下一步 **Public Hostnames**: 添加
   - Subdomain: `xieyan`
   - Domain: `junquick.com`
   - Path: 留空
   - Service Type: `HTTP`
   - URL: `localhost:4141`
6. 保存 —— Cloudflare 会自动给 `xieyan.junquick.com` 加 CNAME 记录

## 本机一键启动 (3 步)

```cmd
:: 1. 安装 cloudflared (只装一次)
deploy\install-cloudflared.cmd

:: 2. 配置 token
copy deploy\.env.example deploy\.env
:: 用记事本打开 deploy\.env, 把 CLOUDFLARE_TUNNEL_TOKEN 填上

:: 3. 启动
deploy\start-all.cmd
```

启动后访问 `https://xieyan.junquick.com/` 应该能打通到 `localhost:4141`。

测试：
```bash
curl https://xieyan.junquick.com/v1/models
```

配置 Claude Code 用这个远程地址：
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://xieyan.junquick.com",
    "ANTHROPIC_AUTH_TOKEN": "dummy",
    "ANTHROPIC_MODEL": "claude-opus-4-6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-haiku-4-5"
  }
}
```

## 开机自启 (可选, 推荐)

把 cloudflared 注册为 Windows 服务，开机后自动连接 Cloudflare:

```cmd
:: 管理员身份运行
deploy\install-cloudflared-service.cmd
```

> 注意: `copilot-api` 本身不会被注册为服务 —— 因为它首次需要交互式 GitHub 登录。
> 如果你已经登录过 (token 缓存在 `%LOCALAPPDATA%\copilot-api\` 或类似路径), 
> 可以用 [nssm](https://nssm.cc/) 把 `bun run start` 也包成服务。

## 文件说明

| 文件 | 作用 |
|---|---|
| `.env.example` | 配置模板 |
| `.env` | 你的实际配置 (已 gitignore) |
| `install-cloudflared.cmd` | 用 winget 安装 cloudflared |
| `install-cloudflared-service.cmd` | cloudflared 注册为开机自启服务 (管理员) |
| `install-nssm.cmd` | 用 winget 安装 nssm (service 包装工具) |
| `install-copilot-api-service.cmd` | copilot-api 注册为开机自启服务 (管理员) |
| `uninstall-services.cmd` | 一键卸载上面两个服务 (管理员) |
| `start-all.cmd` | 一键启动 copilot-api + cloudflared (开发用, 不走服务) |
| `logs/` | 服务模式下的 stdout/stderr 日志 |

## 安全提醒

- `CLOUDFLARE_TUNNEL_TOKEN` 等同于隧道的"密钥", 不要提交到 git (已加入 .gitignore)
- **强烈建议在 `deploy/.env` 设置 `PROXY_AUTH_TOKEN`** —— 服务端已内置 Bearer 校验,
  设置后所有请求必须带 `Authorization: Bearer <token>` (或 Anthropic 风格的 `x-api-key: <token>`),
  否则返回 401。留空则不校验 (危险, 仅本地使用)。
  生成 token:
  ```powershell
  [guid]::NewGuid().ToString("N")
  ```
- 客户端配置示例 (Claude Code):
  ```json
  {
    "env": {
      "ANTHROPIC_BASE_URL": "https://xieyan.junquick.com",
      "ANTHROPIC_AUTH_TOKEN": "你设置的 PROXY_AUTH_TOKEN"
    }
  }
  ```
- 进阶: 也可以在 Cloudflare Zero Trust 后台加 Access Policy (邮箱白名单 / Google 登录) 做第二层防护
