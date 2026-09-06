# 已弃用的扩展

## freellmapi

- **状态**：已弃用（禁用）
- **弃用时间**：2026-09-06
- **原文件**：`freellmapi.ts` → 已重命名为 `freellmapi.ts.disabled`

### 弃用原因

FreeLLMAPI 免费层存在以下问题（非 bug，属免费层特性）：

- 慢速：TTFT 可能长达 50 秒+，单个请求最多等 1-2 分钟
- 限流：免费层有 RPM/RPD 配额，429 时 router 会冷却并切换模型
- 上游不稳定：部分 provider 可能临时不可用（fetch failed / upstream_failed）

会话记录中也多次出现 `Request timed out`。

### 恢复方法

如需重新启用，执行：

```bash
mv agent/extensions/freellmapi.ts.disabled agent/extensions/freellmapi.ts
```

然后在 pi 中执行 `/reload` 重新加载扩展。

### 说明

- 该扩展在被禁用前会注册 `freellmapi` provider 与 `/freellmapi-models` 命令。
- 内嵌的 `DEFAULT_API_KEY` 仍保留在 `.disabled` 文件中；如需彻底清除该密钥，可删除 `.disabled` 文件。
