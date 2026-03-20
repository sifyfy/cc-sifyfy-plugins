---
name: teammate-driven-development
description: >-
  Use when executing implementation plans with persistent teammates instead of
  disposable subagents. Teammates accumulate context across tasks for increasing
  efficiency. Trigger phrases - "チームメイトで実装", "teammate-driven",
  "/teammate-driven-development"
user_invocable: true
arguments:
  - name: lines
    description: >-
      並列パイプラインのライン数（implementer の数）。デフォルト: 1。
      複数ライン時は implementer を並列に動かし、レビュアーが順次処理するパイプライン型で実行する。
    required: false
---

# Teammate-Driven Development

TeamCreate で永続的なチームメイトを作成し、プラン内の各タスクを実行する。
チームメイトはコンテキストを蓄積するため、タスクが進むほど効率が上がる。

**コア原則:** 永続チームメイト + コンテキスト蓄積 + 2段階レビュー = 高品質・高効率

**開始時アナウンス:** 「Teammate-Driven Development で実装を進めます。」

## プロセス

### Step 1: プラン読み込み・チーム作成

1. プランファイルを読む
2. 全タスクをフルテキストで抽出し、コンテキストを把握
3. **TeamCreate** でチームを作成（タスクリストが同時に作成される）
4. **TaskCreate** で全タスクを登録（TeamCreate 後に実行すること — チームのタスクリストに自動的に紐づく）

### Step 2: チームメイト作成（初回のみ）

**Agent tool** でチームメイトを生成（全て **model: sonnet**, **team_name** 付き）:

**lines=1（デフォルト）の場合:**

| name | ロールプロンプト | 役割 |
|---|---|---|
| `implementer` | `./references/implementer-role.md` | 実装・テスト・コミット |
| `spec-reviewer` | `./references/spec-reviewer-role.md` | 仕様準拠レビュー |
| `code-reviewer` | `./references/code-reviewer-role.md` | コード品質レビュー |

**lines=N（N≥2）の場合:**

| name | ロールプロンプト | 役割 |
|---|---|---|
| `implementer-1` 〜 `implementer-N` | `./references/implementer-role.md` | 実装・テスト・コミット（N名） |
| `spec-reviewer` | `./references/spec-reviewer-role.md` | 仕様準拠レビュー（共有・1名） |
| `code-reviewer` | `./references/code-reviewer-role.md` | コード品質レビュー（共有・1名） |

レビュアーを共有することで、プロジェクト全体のレビュー基準の一貫性を保つ。

全チームメイトが idle になるのを待ってから Step 3 へ。

### Step 3: パイプライン実行

> **SendMessage 共通ルール:** プレーンテキスト送信時は `summary`（5-10語のUIプレビュー）を必ず付与する。

チームリードが以下の3つのキューを管理し、イベント駆動で進行する:

- **タスクキュー:** 未着手タスクの順序付きリスト
- **spec-review キュー:** 仕様レビュー待ちタスク（FIFO）
- **code-review キュー:** 品質レビュー待ちタスク（FIFO）

lines=1 の場合、パイプラインは従来の逐次ループと同じ動作になる。

#### オーケストレーションルール

| イベント | アクション |
|---|---|
| idle の implementer がいる & タスクキューに独立タスクがある | **SendMessage** でタスクを割り当て |
| implementer が完了報告 | spec-review キューに追加。spec-reviewer が idle なら即レビュー依頼 |
| spec-review ✅ | code-review キューに追加。code-reviewer が idle なら即レビュー依頼。implementer は次タスク割り当て可能 |
| spec-review ❌ | 該当 implementer に **SendMessage** で修正指示。修正完了まで新タスクを受けない |
| code-review ✅ | **TaskUpdate** で完了。implementer は次タスク割り当て可能 |
| code-review ❌ | 該当 implementer に **SendMessage** で修正指示。修正完了まで新タスクを受けない |
| implementer からの質問 | **SendMessage** で回答。必要なら追加コンテキストを提供 |

#### コンテキスト提供ルール

- **各 implementer の初回タスク:** フルコンテキスト（タスク全文、プロジェクト構造、アーキテクチャ、作業ディレクトリ）
- **同じ implementer の2回目以降:** タスク全文 + 差分コンテキストのみ（前タスクの文脈を覚えているので「前タスクと同じパターンで」等の参照が有効）

#### タスク割り当ての制約

- 各 implementer は同時に1タスクのみ。レビュー中の修正待ちも含む
- 依存関係のあるタスクは、依存先の完了（code-review ✅）を待ってから割り当てる
- 独立したタスクは複数の implementer に並列割り当て可能

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
- 同一 implementer に複数タスクを同時送信（1 implementer につき1タスクずつ）
- チームメイトを途中で再作成（コンテキストが失われる）
- **仕様レビュー前にコード品質レビューを開始**（順序厳守）

**If implementer asks questions:**
- SendMessage で明確に回答。実装を急かさない。

**If reviewer finds issues:**
- 該当 implementer に修正指示 → 修正後に再レビュー依頼。再レビューをスキップしない。

## 障害時の対応

- **チームメイトが応答しない場合:** SendMessage で状態確認を送信。応答がなければ、コンテキスト消失を受け入れた上で同じ `name` で新規作成し、プロジェクト概要 + 前タスクまでの完了状況をフルコンテキストとして提供する（最終手段）
- **レビューループが収束しない場合:** 同一タスクで3回以上の修正→再レビューループに入ったら、チームリードが介入して仕様の曖昧さや実装方針を見直す

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** — 作業開始前に隔離ワークスペースをセットアップ
- **superpowers:writing-plans** — このスキルが実行するプランを作成
- **superpowers:finishing-a-development-branch** — 全タスク完了後の仕上げ
