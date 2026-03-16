---
name: mutate
description: >
  既存テストの品質をミューテーションテストで検証し、フィードバックループで改善するスキル。
  /mutate [テストファイルパス] で起動する。
  ユーザーが「テストの品質を上げて」「ミューテーションテストを回して」「テストを改善して」と言った場合にも使う。
user_invocable: true
arguments:
  - name: test_path
    description: 対象のテストファイルパス（省略時は対話で特定）
    required: false
---

# Mutation Test Quality Improvement

あなたは既存テストの品質改善パイプラインのオーケストレーターです。既に書かれたテストに対してミューテーションテストを実行し、フィードバックループでテスト品質を向上させます。

## 設定値

デフォルト値。`.claude/mutation-pipeline.local.md` があればそのYAMLフロントマターで上書きする。

- `mutation_score_threshold`: 80
- `max_loop_count`: 5
- `improvement_threshold`: 2 (%)
- `stagnation_count`: 2 (連続改善停止回数)

## 手順

### ステップ1: 準備

1. 対象テストファイルを特定する:
   - `$ARGUMENTS` にテストファイルパスがあればそれを使う
   - なければユーザーに確認する
2. テストファイルを読んで、対象の実装モジュールを特定する（importから逆引き）
3. specファイルがあれば特定する（`docs/specs/` 配下を検索、なくてもよい）
4. 言語を自動検出する（package.json → TypeScript/Stryker, Cargo.toml → Rust, pyproject.toml → Python, go.mod → Go）
5. ミューテーションテストツールのインストールを確認する
6. ミューテーションテストの設定で `mutate` を対象モジュールに設定する

### ステップ2: ベースライン計測

1. 既存テストを実行して全件パスすることを確認する。失敗しているテストがあればユーザーに報告して中断する
2. ミューテーションテストを実行する（例: `npx stryker run`）
3. ベースラインのmutation scoreを記録する
4. mutation score ≥ 閾値なら **ステップ5（レポート出力）** へ

### ステップ3: Mutation-Driven Test Refinement

以下のループを実行する:

1. **test-reviewer** エージェントを起動する。以下を渡す:
   - mutation report JSONのパス
   - specファイルのパス（あれば）
   - 実装コードのパス
   - テストコードのパス
   - ループ番号
   - **前回ターゲットしたが殺せなかったmutantのIDリスト**（ループ2以降。前回のtest-reviewerの「テスト追加指示」に含まれていたmutant IDのうち、今回もSurvived/NoCoverageのもの）

2. test-reviewerの出力から**停止判定**を確認する:
   - 「改善余地なし」→ **ステップ4（Design Escalation）** へ
   - 「改善可能」→ 続行

3. test-reviewerの「テスト追加指示」をそのまま **test-generator** エージェントに渡す。追加で以下を伝える:
   - テストファイルのパス
   - 実装コードのパス
   - **実装コードの変更は禁止**
   - **既存テストの削除・変更は禁止。追加のみ**

4. テスト実行で全件パスを確認し、ミューテーションテストを再実行する

5. **停止条件を評価**する:
   - mutation score ≥ 閾値 → **ステップ5（レポート出力）**
   - 直近の改善が improvement_threshold% 未満が stagnation_count 回連続 → **ステップ4（Design Escalation）**
   - ループ回数が max_loop_count に到達 → **ステップ5（レポート出力）**
   - いずれにも該当しない → ループの先頭に戻る

### ステップ4: Design Escalation

test-reviewerの最後の出力にある「設計懸念」セクションを基に、ユーザーに設計改善の選択肢を提示する:
- ガードコードの削除（到達しないなら不要）
- DI導入（テスタビリティ向上）
- 責務分割（観測可能性の向上）
- そのまま残す（untestableとして記録）

**ユーザーに判断を委ねる。** 自動でリファクタリングしない。

### ステップ5: レポート出力

```
## Mutation Test Report

### 結果: {成功 / 改善停止 / 設計問題検出 / ループ上限到達}

### スコア推移
| ループ | mutation score | killed | survived | 改善量 |
|--------|---------------|--------|----------|--------|

### Surviving Mutants分類
- テスト不足: N件
- 仕様曖昧性: N件
- 設計起因: N件
- 等価mutant候補: N件

### 推奨アクション
- [ ] ...
```

## 重要な制約

- **実装コードを変更しない**
- **既存テストを削除・変更しない。追加のみ**
- **等価mutantを無理にkillしようとしない**
- **mutation scoreを絶対視しない**（仕様レビューの代替ではない）
