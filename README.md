# github-pull-message

## 概要
`release` ブランチから `master` ブランチへPRを作ったときに、
PRの説明文を、含まれるマージコミットから生成します。

## 使い方
新しくPRを作る場合は、タイトルを`r2m`としてください。
ページをリロードすると、bodyにコミットの要約が入っています。

既にあるオープンしてある`r2m`を更新したい場合は、
bodyを空にしてページをリロードするか、PRを一旦クローズして再度オープンしてください。

## 条件
- タイトルが `r2m`
- 説明文が空
- `release` から `master`へのPR

## requirement
ruby '2.3.3'
## installation
clone して `bundle install`
## usage
`bundle exec rackup config.ru -p $PORT`
rack立ち上げて
`http://localhost:9292/{{ENTRY_POINT}}`
で webhook を受け取る

## environment variables

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
  - ![image](https://raw.githubusercontent.com/jabropt/github-pr-message/image/images/github_api_token.png)

- TARGET_REPOS
  - CSV形式でリポジトリを指定
  - ex `user/repo,org/repo`

## herokuで動かす例
[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

heroku config:set 環境変数名=セットしたい値
