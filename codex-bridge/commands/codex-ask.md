---
description: Codexにセカンドオピニオンを求める
argument-hint: [質問内容]
---

ユーザーからの質問「$ARGUMENTS」についてCodexのセカンドオピニオンを取得する。

まず質問の内容を分析し、以下の特化スキルに該当するか判断する:

- 要件分析に関する質問 → codex-bridge:codex-requirements-analysis スキルを使用
- 設計・アーキテクチャに関する質問 → codex-bridge:codex-design-review スキルを使用
- コードレビューに関する質問 → codex-bridge:codex-code-review スキルを使用
- アルゴリズムに関する質問 → codex-bridge:codex-algorithm-design スキルを使用
- 提案への反論が欲しい → codex-bridge:codex-devils-advocate スキルを使用
- 上記に該当しない → codex-bridge:codex-ask スキルを使用

適切なスキルのワークフローに従ってCodexとの対話を行う。
結果はClaudeの見解とCodexの見解を比較して提示し、
相違点がある場合はシフィさんに判断を委ねる。
