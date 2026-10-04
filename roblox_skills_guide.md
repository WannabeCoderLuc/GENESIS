# Roblox Skills & Antigravity Customization Guide

## 1. Built-in Roblox Skills (`rbx-*`)

These built-in skills encapsulate expert, deeply technical knowledge for developing on Roblox. They are natively provided by the `Roblox_Studio` MCP server rather than existing as standalone Markdown files on your disk. 

When you instruct the agent to use them, it invokes the `skill` tool exposed by the MCP server, passing the `skill_name` and the `studio_id`. The server responds with comprehensive Markdown guides containing APIs, workflows, and best practices.

### Detailed Breakdown of Key Skills

#### **`rbx-debug` (Programmatic Debugging)**
- **What it does:** Uses `ScriptDebuggerService` to programmatically manage breakpoints, control execution, and inspect runtime state (threads, stack, variables, expressions) during a playtest. It gives the AI agent direct debugging capabilities without requiring the user to manually click in Studio.
- **How to trigger efficiently:** Ask the agent to "debug a script using breakpoints" or "check runtime state during playtest." The agent will set breakpoints via `AddBreakpoint()`, start play mode, and attach an `OnStopped` handler to log variable states.

#### **`rbx-perf-profiling` (MicroProfiler Scripting)**
- **What it does:** Uses the `LibMP` Luau module to programmatically access MicroProfiler data (Frames, Timers/Scopes, Threads, and Counters). Allows the agent to capture live performance data or analyze snapshots for CPU/GPU bottlenecks, memory allocations, and frame spikes.
- **How to trigger efficiently:** Ask the agent to "profile frame times" or "find performance bottlenecks." The agent can run `execute_luau` to read real-world elapsed time, CPU core times, or instance counts natively.

#### **`rbx-scene-analysis` (Scene Optimization)**
- **What it does:** Leverages `SceneAnalysisService` at runtime to measure scene health. It supports built-in commands like `/scene-health`, `/optimize-rendering`, `/optimize-memory`, and `/fix-leaks`, checking instance counts, draw calls, triangles per view, script memory, and unparented instances.
- **How to trigger efficiently:** Ask the agent to "analyze scene health," "optimize rendering," or "find unparented instance leaks." The agent will start a play session and run queries like `GetTriangleCompositionAsync()`.

#### **`rbx-luau-heap-profiling` (Memory Leaks)**
- **What it does:** Uses `HeapProfilerService` to take programmatic heap snapshots of the server or client (`ServerRequestDataAsync`, `ClientRequestDataAsync`). It returns JSON heap dumps that the agent can analyze to trace retained tables, un-disconnected events, and leaking objects.
- **How to trigger efficiently:** Tell the agent you have high RAM usage or ask it to "find memory leaks." The agent will take snapshots before and after an action and compare allocations.

#### **`rbx-docs-search` (API Reference Lookup)**
- **What it does:** Instructs the agent on how to use the `http_get` tool to dynamically fetch clean markdown docs from `https://create.roblox.com/docs/...`. It features an efficient `query` parameter that only returns matching sections, minimizing context window usage.
- **How to trigger efficiently:** When you need the agent to learn an unfamiliar Roblox API, tell it to "look up the documentation for [Class/API] first."

#### **`rbx-create-skill` (Skill Creation Wizard)**
- **What it does:** Teaches the agent the exact workflow to gather requirements using `ask_questions` and then call the `create_skill` tool. It enforces naming conventions (avoiding `rbx-` prefix) and structural rules for custom skills.
- **How to trigger efficiently:** Simply ask the agent to "help me create a new custom skill for my workflow."

---

## 2. Tutorial: Creating Custom Roblox Skills

You can create your own custom skills using the Antigravity Customization System. The system uses **progressive disclosure** — the agent reads the skill's name and description first, and only loads the full file into its context when it decides it is relevant.

### Step 1: Choose a Location
You can store your skill in one of two places:
1. **Workspace Scope (Project-specific):** Create it in `.agents/skills/` (or `.agent/skills/`) at the root of your project directory (e.g., `C:\Users\Luc\Desktop\DEV\.agents\skills\`). This allows you to commit the skill to version control and share it with your team.
2. **Global Scope (Machine-local):** Create it in `C:\Users\Luc\.gemini\config\skills\` to make the skill available across all your projects.

### Step 2: Create the Directory Structure
Each skill must have its own directory. For example, let's create a skill named `custom-deploy`:
```text
.agents/skills/custom-deploy/
├── SKILL.md          # Required: Main instruction file
├── scripts/          # Optional: Helper bash/powershell or luau scripts
└── references/       # Optional: Detailed API docs or heavy text
```

### Step 3: Write the `SKILL.md` File
The `SKILL.md` file is the entry point. It **must** begin with a YAML frontmatter block that defines the `name` and `description`. Do not use the `rbx-` prefix (it is reserved for built-ins).

```markdown
---
name: custom-deploy
description: >-
  Use this skill when the user asks to deploy the Roblox experience to production.
  It handles asset building, running checks, and uploading via Rojo.
---

# Custom Roblox Deploy

Follow these steps exactly to deploy the game.

## Steps
1. **Pre-flight Checks**: Run unit tests using the `rbx-unit-test` skill.
2. **Build**: Run the local build script `[build.ps1](./scripts/build.ps1)`.
3. **Deploy**: Upload the place file using Rojo CLI.
4. **Validation**: Check that the place version was updated successfully on the Roblox cloud.
```

### Best Practices for Your Custom Skills:
- **Write a strong description:** The agent relies on the YAML `description` field to decide whether the skill is relevant to the user's prompt. Be specific about *when* to trigger it.
- **Keep the main file concise:** If your skill requires large blocks of reference text (e.g., internal engine APIs), place them in a `.md` file inside the `references/` folder and link to them using relative paths (`[My Docs](./references/api.md)`). The agent will read them on-demand.
- **Provide executable scripts:** Put complex commands in `scripts/` and instruct the agent to run them, making the workflow more reliable than manually typing out long shell commands.
