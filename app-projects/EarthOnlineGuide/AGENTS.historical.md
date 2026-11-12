# EarthOnlineGuide 外接盘开发入口

本文件适用于 EarthOnlineGuide 的所有后续实现、构建、测试与验收任务；上级 `/Users/USER/Documents/app/AGENTS.md`、当前用户授权与安全规则优先。开始前必须完整读取本文件和 `PROJECT_CORE.md`。

## 唯一开发入口

- 后续代码、资源、Planning 文档、构建产物、测试结果与人工证据的唯一工作副本是 `/Volumes/EXTERNAL/AppWorkspace/app/EarthOnlineGuide`。
- 内置盘的 `/Users/USER/Documents/app/EarthOnlineGuide` 仅为受保护迁移前副本/回退现场：不得在其中修改源码、生成构建物、运行测试或写入新证据；不得删除，除非用户对精确路径另行授权。
- 启动任何写入、`xcodebuild`、测试、安装或 Simulator 验收前，必须确认 `/Volumes/EXTERNAL` 已挂载可写，且 `pwd` 位于本项目根或其子目录；并确认 `git -C "$PWD" rev-parse --show-toplevel` 输出为 `/Volumes/EXTERNAL/AppWorkspace/app`。任一项不满足即停止，不得回落到内置盘路径或 Codex 默认 worktree。

## 构建与证据落盘

- 所有命令行构建/测试必须显式使用 `-derivedDataPath /Volumes/EXTERNAL/AppWorkspace/.derived-data/EarthOnlineGuide/<任务标识>`；结果包、日志和截图同样必须写在 `/Volumes/EXTERNAL/AppWorkspace/` 下的任务目录。
- 不得为方便而使用默认 `~/Library/Developer/Xcode/DerivedData`，也不得在 `/tmp`、内置盘项目目录或 `~/.codex/worktrees` 生成可观体积的构建、测试或证据产物。
- Xcode.app、iOS runtime 与已保留的 EarthOnline 内置 Simulator 可继续使用；它们不改变“源码与构建输出必须外接盘”的规则。真机、Simulator 与用户验收仍须按各自门禁独立报告。
- 每个执行任务的回报必须给出：实际源码根、DerivedData 路径、结果包/证据路径、构建前后 `df -h /` 与 `df -h /Volumes/EXTERNAL`。路径证据缺失则构建/测试状态为 UNKNOWN，不得宣称外接盘闭环。

## 迁移保护

- 不得因本规则移动、删除、同步覆盖或重建内置盘副本、Git 历史、模拟器、DerivedData 或外接盘现有数据。
- 外接盘未挂载、卷名变化、Git 根不符、磁盘写入失败或可用空间不足时，立即停止当前执行并报告；不得在内置盘创建替代工程。
