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
   （拉取失败时回退为手动输入模型 ID），并尽力从返回内容中识别
   `contextWindow` / `maxTokens` / `reasoning` / 图片输入 / 价格。
4. 识别后可选择立即调整模型属性（逐个或批量），也可稍后用
   `/byok edit` 或 `/byok meta` 修改。
5. 保存后立即生效，运行 `/model` 选择 `byok 的 provider id/<model>`。

非交互用法（无需 TUI）：

```
/byok list
/byok show <id>
/byok use <id> [model]
/byok temp <id> <n|off>
/byok url <id> <baseUrl>
/byok key <id> <key>
/byok models <id>
/byok meta <id>
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

## 模型属性（自动识别与手动编辑）

添加或刷新模型时，扩展会尝试从 `/models` 返回里识别下列字段（不同服务商名不一，
按优先级回退）：

| 属性 | 识别的字段（节选） |
|------|--------------------|
| 上下文窗口 | `context_window`、`context_length`（OpenRouter / SenseNova）、`max_model_len`（vLLM）、`max_input_length`（SenseNova）、`top_provider.context_length`、`model_info.max_input_tokens`（LiteLLM） |
| 最大输出 | `max_tokens`、`max_completion_tokens`、`max_output_tokens`、`max_output_length`（SenseNova）、`top_provider.max_completion_tokens`、`model_info.max_output_tokens` |
| 推理 | `supported_parameters`、`supported_sampling_parameters`、`supported_features`（SenseNova，值含 `reasoning`）、`model_info.supports_reasoning`、`capabilities.reasoning` |
| 图片输入 | `input_modalities`（SenseNova）、`architecture.input_modalities`、`modalities`、`supported_features` 含 `vision`、`model_info.supports_vision`、`capabilities.vision` |
| 价格 | `pricing.prompt/completion/input/output`（OpenRouter / SenseNova，$/token 自动换算为 $/M）、`*_cost_per_token`、`*_cost_per_million*` |

例如 SenseNova（`https://token.sensenova.cn/v1`）返回 `context_length` +
`max_output_length` + `supported_features`，可直接得到 1M 上下文 / 65K 输出 /
thinking 支持，无需手工填写。

无法识别的字段会回退到 pi 默认值（`contextWindow` 128000、`maxTokens` 自动）。
可用以下方式手动覆盖：

- `/byok add` 选择模型后，确认「调整模型属性」；
- `/byok edit <id>` → 选择「模型属性（contextWindow/maxTokens 等）」；
- `/byok meta <id>` 直接进入模型属性编辑器。

编辑器支持：

- **逐个编辑**每个模型的 `name` / `contextWindow` / `maxTokens` /
  `reasoning` / `input` / `cost`；
- **批量设置**全部模型的 `contextWindow` 或 `maxTokens`。

数值支持 `128000`、`128k`、`1m` 等写法；留空保持原值，`reset` / `default`
清除该字段回到 pi 默认。`cost` 用 JSON 编辑，单位是 $/百万 token：

```json
{ "input": 3, "output": 15, "cacheRead": 0.3, "cacheWrite": 3.75 }
```

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
- **模型属性识别是尽力而为**：部分服务端 `/models` 只返回 `id`（如原生 OpenAI、
  Ollama），此时上下文窗口等会回退到 pi 默认值，请用 `/byok meta <id>` 手动填写。
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
