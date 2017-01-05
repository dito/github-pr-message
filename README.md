# github-pull-message

## 概要
`release` ブランチから `master` ブランチへプルリクを作ったときに、  
プルリクの説明文を、含まれるマージコミットから生成します。

## 条件
- タイトルが `r2m`
- 説明文が空
- `release` から `master`へのプルリク
- 最後にページをリロード

## setup
[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## environment variables

`heroku config:set 環境変数名=セットしたい値`

- SECRET_TOKEN
  - githubのwebhookのためのシークレット
  - `ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'` などで作る
  - 該当repository -> Setting -> Webhooks -> Secret
  - ![image](https://raw.githubusercontent.com/jabropt/github-pr-message/image/images/secret_token.png)

- ENTRY_POINT
  - githubのwebhookを受け取るエントリーポイント
  - 該当repository -> Setting -> Webhooks -> Payload URL
  - ![image](https://raw.githubusercontent.com/jabropt/github-pr-message/image/images/entry_point.png)

- GITHUB_API_TOKEN
  - github の パーソナルトークン
  - 必須スコープ
    - repos
    - admin:repo_hook
  - ![image](https://raw.githubusercontent.com/jabropt/github-pr-message/image/images/github_api_token.png)

- TARGET_REPOS
  - CSV形式でリポジトリを指定
  - ex `user/repo,org/repo`
