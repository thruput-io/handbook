# IntelliJ Companion MCP Instructions

When interacting with the IntelliJ companion MCP server or running subcommands/agent tasks, agents MUST ensure the MCP
server configuration in [`.agents/mcp_config.json`](../mcp_config.json) connects to port `64342` and dynamically passes `IJ_MCP_SERVER_PROJECT_PATH`.

## Rule Guidelines

- **MCP Config Location:** The MCP server is declared locally in [`.agents/mcp_config.json`](../mcp_config.json) using SSE URL `http://127.0.0.1:64342/sse`.
- **Dynamic Project Path:** `IJ_MCP_SERVER_PROJECT_PATH` MUST be set dynamically in the environment (`${IJ_MCP_SERVER_PROJECT_PATH}`). No hardcoded default paths are allowed in the configuration. 
— **Command Prefixing:** Prefix terminal invocations or subagent executions with `IJ_MCP_SERVER_PROJECT_PATH="$(pwd)"`.