# github-pull-message

## 概要
r2mのpullreqの説明文を自動で作るやつ。

## 条件
- タイトルが `r2m`
- `release` から `master`への pull req
- pull req を作ったときの説明文が空


## Setup

### SECRET_TOKEN

Please set secret token for GitHub Webhook which you'll put on 'secret' field.

githubのhookを受け取るエントリーポイント

### GITHUB_API_TOKEN

Please set Personal access token for your GitHub account(or Bot account) which has following permissions.

### TARGET_REPOS

- CSV形式でリポジトリを指定
- ex `user/repo,org/repo`
