---
name: teammate-driven-development
description: >-
  Use when executing implementation plans with persistent teammates instead of
  disposable subagents. Teammates accumulate context across tasks for increasing
  efficiency. Trigger phrases - "チームメイトで実装", "teammate-driven",
  "/teammate-driven-development"
---

# Teammate-Driven Development

TeamCreate で永続的なチームメイトを作成し、プラン内の各タスクを実行する。
チームメイトはコンテキストを蓄積するため、タスクが進むほど効率が上がる。

**コア原則:** 永続チームメイト + コンテキスト蓄積 + 2段階レビュー = 高品質・高効率

**開始時アナウンス:** 「Teammate-Driven Development で実装を進めます。」

## プロセス

### Step 1: プラン読み込み・タスク抽出

1. プランファイルを読む
2. 全タスクをフルテキストで抽出し、コンテキストを把握
3. TaskCreate で全タスクを登録（チーム内でタスクリストを共有するため TodoWrite ではなく TaskCreate を使う）

### Step 2: チーム作成（初回のみ）

1. **TeamCreate** でチームを作成
2. **Agent tool** で3つのチームメイトを生成（全て **model: sonnet**, **team_name** 付き）:

| name | ロールプロンプト | 役割 |
|---|---|---|
| `implementer` | `./references/implementer-role.md` | 実装・テスト・コミット |
| `spec-reviewer` | `./references/spec-reviewer-role.md` | 仕様準拠レビュー |
| `code-reviewer` | `./references/code-reviewer-role.md` | コード品質レビュー |

3つのチームメイトが idle になるのを待ってから Step 3 へ。

### Step 3: タスク実行ループ

各タスクについて以下を繰り返す:

> **SendMessage 共通ルール:** プレーンテキスト送信時は `summary`（5-10語のUIプレビュー）を必ず付与する。

#### 3a. 実装依頼

**SendMessage** で `implementer` にタスクを送信。

- **初回タスク:** フルコンテキスト（タスク全文、プロジェクト構造、アーキテクチャ、作業ディレクトリ）
- **2回目以降:** タスク全文 + 差分コンテキストのみ。implementer は前タスクの文脈を覚えているので、「前タスクと同じディレクトリ構造で」等の参照が使える

#### 3b. 質問対応

implementer からの質問には **SendMessage** で回答。何度でもやり取り可能。

#### 3c. 仕様レビュー

implementer が完了報告したら:

1. **SendMessage** で `spec-reviewer` にレビュー依頼（タスク仕様 + implementer の報告）
2. ❌ → **SendMessage** で `implementer` に修正指示 → 修正後に再レビュー
3. ✅ → 次のステップへ

#### 3d. コード品質レビュー

1. **SendMessage** で `code-reviewer` にレビュー依頼（変更ファイル + commit SHA + タスク概要）
2. ❌ → **SendMessage** で `implementer` に修正指示 → 修正後に再レビュー
3. ✅ → TaskUpdate で完了、次のタスクへ

### Step 4: 全タスク完了

1. `code-reviewer` に全体の最終レビューを **SendMessage** で依頼
2. **superpowers:finishing-a-development-branch** で完了処理
3. 各チームメイトに **SendMessage** で `{ type: "shutdown_request" }` を送信してシャットダウン
4. 全チームメイトの shutdown 完了後、**TeamDelete** でチーム・タスクディレクトリをクリーンアップ

## チームメイトの特性を活かすポイント

### コンテキスト蓄積（最大のメリット）

- implementer: 前タスクで学んだパターン・規約・構造を次タスクに自然に適用
- spec-reviewer: プロジェクトの仕様理解を蓄積し、一貫した基準でレビュー
- code-reviewer: コードベース全体の品質の一貫性を維持

### 効率的なコミュニケーション

- 初回は詳細コンテキスト、2回目以降は差分のみ送信
- 「前タスクと同じパターンで」のような参照が有効
- 質問→回答の往復がスムーズ（Agent 再起動不要）

### 共有タスクリスト

- 全チームメイトが TaskList を参照して進捗を把握可能

## Red Flags

**Never:**
- main/master ブランチで直接実装を開始（明示的な同意なしに）
- レビュースキップ（仕様レビュー・品質レビュー両方必須）
- 未修正 issue を残して次タスクへ
- 複数タスクを implementer に同時送信（1タスクずつ順番に）
- チームメイトを途中で再作成（コンテキストが失われる）
- **仕様レビュー前にコード品質レビューを開始**（順序厳守）

**If implementer asks questions:**
- SendMessage で明確に回答。必要なら追加コンテキストを提供。実装を急かさない。

**If reviewer finds issues:**
- implementer に SendMessage で修正指示 → reviewer に再レビュー依頼。再レビューをスキップしない。

## 障害時の対応

- **チームメイトが応答しない場合:** SendMessage で状態確認を送信。応答がなければ、コンテキスト消失を受け入れた上で同じ `name` で新規作成し、プロジェクト概要 + 前タスクまでの完了状況をフルコンテキストとして提供する（最終手段）
- **レビューループが収束しない場合:** 同一タスクで3回以上の修正→再レビューループに入ったら、チームリードが介入して仕様の曖昧さや実装方針を見直す

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** — 作業開始前に隔離ワークスペースをセットアップ
- **superpowers:writing-plans** — このスキルが実行するプランを作成
- **superpowers:finishing-a-development-branch** — 全タスク完了後の仕上げ
