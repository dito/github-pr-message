# github-pull-message

## 概要
`release` ブランチから `master` ブランチへプルリクを作ったときに、
プルリクの説明文を、含まれるマージコミットから生成します。

## 条件
- タイトルが `r2m`
- 説明文が空
- `release` から `master`へのプルリク
- 最後にページをリロード

## environment variables

- SECRET_TOKEN
  - githubのwebhookのためのシークレット
  - `ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'` などで作る
  - 該当repository -> Setting -> Webhooks -> Secret

- ENTRY_POINT
  - githubのwebhookを受け取るエントリーポイント
  - 該当repository -> Setting -> Webhooks -> Payload URL

- GITHUB_API_TOKEN
  - github の パーソナルトークン
  - 必須スコープ
    - repos

- TARGET_REPOS
  - CSV形式でリポジトリを指定
  - ex `user/repo,org/repo`
