# BYOK 扩展（Bring Your Own Key）

把任意 OpenAI / Anthropic 兼容端点注册为 pi provider，支持自定义
`base_url`、`api_key`、`api` 类型、`headers`、模型列表与采样参数
（`temperature` / `top_p`），并集成 `/model` 选择。

## 安装位置

扩展随 pi 自动发现，文件位于：

```
~/.pi/agent/extensions/byok/
├── index.ts      # 入口：读配置、注册 provider、采样注入、状态
├── config.ts     # 配置类型、读写、环境变量解析、脱敏、校验
├── models.ts     # /models 拉取、模型映射、provider 注册/注销
├── wizard.ts     # /byok 命令与交互式向导
└── README.md
```

配置文件（自动创建）：

```
${PI_CODING_AGENT_DIR:-~/.pi/agent}/byok.json   # 权限 0600
```

## 快速开始

1. 在 pi 交互式 TUI 中运行 `/byok`，选择 **add**。
2. 依次填写 provider id、Base URL、API Key，选择 API 类型与兼容预设。
3. 扩展会请求 `GET <baseUrl>/models` 并让你选择要注册的模型
   （拉取失败时回退为手动输入模型 ID）。
4. 保存后立即生效，运行 `/model` 选择 `byok 的 provider id/<model>`。

非交互用法（无需 TUI）：

```
/byok list
/byok show <id>
/byok use <id> [model]
/byok temp <id> <n|off>
/byok url <id> <baseUrl>
/byok key <id> <key>
/byok models <id>
/byok test <id>
```

交互式菜单：运行 `/byok` 不带参数。

## 配置文件字段

```jsonc
{
  "version": 1,
  "providers": {
    "my-openai": {
      "name": "My OpenAI",            // 可选展示名，默认 BYOK (id)
      "baseUrl": "https://api.example.com/v1",
      "apiKey": "$MY_API_KEY",         // 字面值 / $ENV_VAR / !command
      "api": "openai-completions",    // 默认 openai-completions
      "headers": {                    // 可选，额外请求头，值支持 $ENV_VAR
        "X-Api-Version": "1"
      },
      "sampling": {                    // 可选采样参数
        "temperature": 0.7,            // 数字=注入；null/省略=不注入
        "topP": 0.95                   // 映射为请求体 top_p
      },
      "compatPreset": "openai",        // openai | openai-compat | deepseek
      "modelsPath": "/v1/models",      // 可选，覆盖模型目录地址
      "models": [
        { "id": "gpt-4o-mini", "contextWindow": 128000, "maxTokens": 16384,
          "reasoning": false, "input": ["text"] }
      ],
      "lastModel": "gpt-4o-mini"       // /byok use 记录，可手动编辑
    }
  }
}
```

### 环境变量引用

`apiKey` 与 `headers` 的值遵循 pi 的解析规则：

- `$VAR` / `${VAR}` → 读取环境变量
- `$$` → 字面 `$`，`$!` → 字面 `!`
- `!command` → 由 pi 在请求时执行；**扩展内部的 `/models` 拉取不会执行命令**
  （此时会原样使用，可能失败，请改用 `$ENV_VAR`）

通过 `/byok add` 输入的字面 key 中的 `$` 会自动转义为 `$$`，避免被误解析。

### 兼容预设

| 预设 | 效果 |
|------|------|
| `openai` | 不设置 `compat`（默认） |
| `openai-compat` | `supportsStore:false`、`supportsDeveloperRole:false`、`supportsReasoningEffort:false`，适配 Ollama / vLLM 等 |
| `deepseek` | `thinkingFormat:"deepseek"`、`supportsReasoningEffort:true` |

## 模型目录地址规则

- `baseUrl` 以 `/v1`（或 `/v2`…）结尾 → 请求 `<baseUrl>/models`
- `baseUrl` 以 `/openai` 结尾 → 请求 `<baseUrl>/models`
- 其它 → 请求 `<baseUrl>/v1/models`
- 可用 `modelsPath` 覆盖（相对路径拼在 `baseUrl` 后，也可填绝对 URL）

## 已知限制

- **Google Generative AI 采样参数**位于 `generationConfig`，本扩展不注入
  `temperature` / `top_p`（选择该 `api` 时采样设置被忽略）。
- **`!command` 不参与 `/models` 拉取**，仅供 pi 在真实请求时执行。
- **密钥明文存储**于 `byok.json`：已设置 `0600`、列表脱敏，建议优先用 `$ENV_VAR`。
- **`ctx.ui.input` 无掩码**：pi 未提供 secret 输入类型，输入密钥时会回显，
  建议使用环境变量引用。
- **payload 改写顺序**：本扩展用 `before_provider_request` 注入采样参数，仅对
  已注册的 BYOK provider 生效；若其他扩展（如 `provider-payload.ts`）也改写
  payload，按扩展加载顺序，后运行者可能覆盖。
- **内置 provider 重名**：provider id 若与内置同名（如 `openai`），注册会覆盖
  该内置 provider 的模型；向导会提示确认。可用 `/byok remove` 恢复。
- 单个 provider 注册失败只会记录警告，不影响其它 provider 与扩展加载。

## 迁移说明

早期若使用单 provider 的扁平配置，将其包裹进 `providers` map 即可：

```jsonc
// 旧（扁平）
{ "baseUrl": "...", "apiKey": "...", "models": [...] }

// 新（多 provider）
{
  "version": 1,
  "providers": {
    "my-provider": { "baseUrl": "...", "apiKey": "...", "models": [...] }
  }
}
```

每个 key 即 pi provider id，可同时配置多个端点，各自独立注册与切换。
