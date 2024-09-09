---
title: GitLab RunnerでローカルMacにLaTeX組版サーバーを作る [JA]
date: 2024-09-11
language: ja
link: https://shinobuamasaki.github.io/items/gitlab-runner-latex-auto-typesetting-with-macos.html
description: GitLab Runnerを使ってLaTeX組版をローカルMacで自動化する方法に関する記事
---

# GitLab RunnerでローカルMacにLaTeX組版サーバーを作る

Author: 雨崎しのぶ

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2024-09-11 JST

## 概要

本稿では、Gitを使ってLaTeX文書を執筆していく過程における作業の自動化について、GitLab Runnerを使ったアプローチについて解説する。GitリポジトリにおいてCI/CDを実行できるサービスはGitLabやGitHubなどで提供されている。前者のCI/CDであるGitLab Runnerは、ローカルマシンを使って自由にカスタマイズされた環境で実行できる点が特徴的である。これに対し、後者のGitHub Actionsはクラウドベースで実行されるため、ローカルにインストールされたソフトウェアやフォントを利用したビルドには適していない。そのため、ローカルリソースを使用する目的であればGitLab Runnerが適しているだろう。

本稿は以下のような要求から執筆された。

- LaTeXを使った文書の執筆において、Gitを使ったバージョン管理をしたい。
- データのバックアップや複数の端末からの利用を容易にするため、リモートリポジトリにもファイルを置きたい。
- TeXファイルのコミット履歴とそれに対応する組版結果（PDFファイル）を管理したい。
- TeXファイルのコンパイルはできるだけ自動化したい。
- ローカルのOSに入っているフォントを使いたい。
- 文書の執筆は、非公開の内容を含むため、プライベートリポジトリで行いたい。

これらの要件を満たすため、GitLab RunnerとLuaLaTeXを使用して、Mac miniを組版サーバーとして使用する方法について記述する。最終的な目標はTeXファイルをリポジトリに送信すると、自動的にPDFファイルが生成・登録されて、常に最新のドキュメントを利用できる状態を確保することである。

## 目次

- [概要](#概要)
- [イントロダクション](#イントロダクション)
- [インストール](#インストール)
  - [Mac環境の想定](#mac環境の想定)
    - [ハードウェア](#ハードウェア)
    - [ソフトウェア](#ソフトウェア)
    - [フォントファイルの場所に関する注意事項](#フォントファイルの場所に関する注意事項)

  - [LaTeX環境](#latex環境)
    - [MacPortsのインストール](#macportsのインストール)
    - [TeX Liveのインストール](#tex-liveのインストール)

  - [GitLab Runnerのインストール](#gitlab-runnerのインストール)
    - [ユーザーの作成](#ユーザーの作成)
    - [LuaLaTeXの初期設定](#lualatexの初期設定)
    - [ダウンロード](#ダウンロード)
    - [トークンを取得](#トークンを取得)
    - [ランナーの登録](#ランナーの登録)
    - [設定ファイルの内容を編集する](#設定ファイルの内容を編集する)
    - [ランナーをサービスとして実行](#ランナーをサービスとして実行)
- [ランナーを動かす](#ランナーを動かす)
  - [Personal Access Tokenの取得・登録](#personal-access-tokenの取得登録)
  - [`latexmkrc`と`.gitlab-ci.yml`](#latexmkrcと.gitlab-ci.yml)
    - [キーの説明](#キーの説明)
    - [CI/CD環境変数の説明](#cicd環境変数の説明)
  - [`main.tex`](#main.tex)
  - [コミット&プッシュ](#コミットプッシュ)
  - [PDFを取得](#pdfを取得)
- [トラブルシューティング](#トラブルシューティング)
- [参考文献](#参考文献)

## イントロダクション

本稿では、GitLabで提供されるCI/CDの仕組みを活用して、LaTeX文書からPDFファイルを自動生成する方法について紹介する。この方法を使えば、手動でLaTeX文書をコンパイルしてリポジトリに登録する手間を削減し、履歴の管理や差分の取得がさらに容易になるだろう。また、これらの処理をローカルのmacOSマシンで行うことで、クラウドを使用した場合と比べて待ち時間が短くすることができる。また、幅広いフォントを選択肢を得られるため、より満足度の高いドキュメントを作成することができるだろう。

この方法は、具体的には以下のフェーズに分かれている。

1. GitLabのリポジトリに変更がプッシュされる。
2. ランナーの実行がトリガーされる。
3. ランナーをインストールしたローカルマシンにジョブが投入される。
4. ローカルマシンはLaTeX文書からPDFファイルを自動生成する。
5. 生成物をリポジトリにコミット・プッシュする。

以下では、これらの一連の処理を自動化する方法について述べる。本稿ではLaTeX文書のコンパイルにLuaLaTeXを使用するが、その他のLaTeXでも同様に自動化することができるだろう。なお、GitやLaTeXの基本的な使い方については説明せず、また非公開で複数人がリポジトリを使うことも想定しない。

### CI/CDとは

CI/CDとは「継続的インテグレーション（Continuous Integration, CI）」と「継続的デリバリー／デプロイメント（Continuous Delivery/Deployment, CD）」の略称で、主にソフトウェアの開発において効率的にコードの変更を、最終的な生成物（アプリケーションやドキュメントなど）を自動的に生成したり配布したりするための仕組みである。本稿ではこの仕組みを利用して、ソースファイルであるLaTeX文書から、生成物であるPDFファイルを自動的にGitリポジトリに登録する方法について述べる。

### GitLab Runnerとは

GitLabのCI/CDで定義された一連の処理（パイプライン、後述）を自動的に実行するためのエージェントである。GitLabサーバーからパイプラインジョブを受け取り、そのジョブをローカルまたはクラウドのマシンで実行する。RunnerはGitLab.comでも提供されているが、本稿ではローカルのMacにリポジトリから独立してインストール・設定した環境を使用する。GitLab Runner、`lualatex`やその他のフォントなどがインストールされたmacOS環境でランナーがジョブを実行することで、カスタマイズ自由度の高い（フォントの選択肢など）PDFドキュメントを自動生成することができるだろう。

## インストール

### Mac環境の想定

以下に、ランナーをインストールするMacの動作環境を記す。なおパッケージマネージャーはMacPortsを例に用いる。

#### ハードウェア

- Mac mini 2014 Late
- CPU: Intel Core i5-4260U 1.4 GHz
- RAM: 4GB
- SSD: 240GB

#### ソフトウェア

- macOS 12.7.6 Monterey
- Xcode: `Xcode 14.2, Build version 14C18`
- Git: `git version 2.37.1 (Apple Git-137.1)`
- OpenSSH: `OpenSSH_8.6p1, LibreSSL 3.3.6`
- TeX Live 2024
  - LuaLaTeX: `LuaHBTeX, Version 1.18.0 (TeX Live 2024/MacPorts 2024.70613_0)`
  - Latexmk: `Latexmk, John Collins, 6 Nov. 2023. Version 4.81`
- GitLab Runner: `Version 17.3.1, darwin/amd64`
- MacPorts: `MacPorts 2.10.1`

#### フォントファイルの場所に関する注意事項

今回紹介する方法で特定のユーザーに対してインストールされたフォントを使いたい場合には、以下のいずれかの処理を行う必要がある。

- それらのフォントをmacOSのすべてのユーザーに対してインストールする。
- それらのフォントを`gl-runner`ユーザーにもインストールする。
- Runnerを実行する際にそのユーザーを指定する

本稿では、LaTeXのビルドで使用するフォントはすべてのユーザーにインストールされたものと仮定する。

### LaTeX環境

先に述べたように、本稿ではMacPortsを使用し、これにより提供されるTeX Live 2024とそれに含まれる`latexmk`と`lualatex`使用する。Homebrewでもインストールされたものでもおそらく問題ないだろう。ただし、PATH環境変数に追加するために、実行ファイルのあるディレクトリを確認しておく必要がある。また、パッケージマネージャーのインストールには**Xcode**と**Xcode Command Line Toolsのインストール**が必要だが、ここでは省略する。

#### MacPortsのインストール

MacPorts公式サイトを参照してインストールする。リンク先のQuickstartから、適当なバージョン（ここでは`macOS Monterey v12`）を選択してダウンロード、インストーラーを起動してインストールを行う。

[www.macports.org](https://www.macports.org/install.php)

インストールが完了したら環境変数`PATH`に`/opt/local/bin`を追加する。

```shell
export PATH="/opt/local/bin:$PATH"
```

をターミナルで実行、もしくは`~/.zshrc`に書き込んでから`source ~/.zshrc`を実行するなどしてシェルをリロードする。なお、MacPortsに関係するファイルは基本的に`/opt/local`以下に配置されるので、パッケージのインストールや更新、削除を行うにはスーパーユーザーの権限が必要になるため、以下では適宜`sudo`を使用する。

#### TeX Liveのインストール

最初に`port`のアップデートを行う。

```shell
% sudo port selfupdate
```

次にTeX Liveのインストールを行う。ここでは参考文献2の「MacPortsによるインストール」の方法に従い、日本語関連のパッケージとtexlive-luatex、texlive-xetex, およびtexliveパッケージをインストールする。

```shell
% sudo port install texlive-lang-japanese texlive-luatex texlive-xetex texlive
```

なおパッケージをフルインストールする場合は以下を実行する。

```shell
% sudo port install texlive +full
```

インストールが完了したら、以下のコマンドで確認することができる。

```shell
% latexmk --version
Latexmk, John Collins, 6 Nov. 2023. Version 4.81

% lualatex --credits
This is LuaHBTeX, Version 1.18.0 (TeX Live 2024/MacPorts 2024.70613_0)

The LuaTeX team is Hans Hagen, Hartmut Henkel, Taco Hoekwater, Luigi Scarso.

LuaHBTeX merges and builds upon (parts of) the code from these projects:

tex       : Donald Knuth
etex      : Peter Breitenlohner, Phil Taylor and friends
omega     : John Plaice and Yannis Haralambous
aleph     : Giuseppe Bilotta
pdftex    : Han The Thanh and friends
kpathsea  : Karl Berry, Olaf Weber and others
lua       : Roberto Ierusalimschy, Waldemar Celes and Luiz Henrique de Figueiredo
metapost  : John Hobby, Taco Hoekwater, Luigi Scarso, Hans Hagen and friends
pplib     : Paweł Jackowski
fontforge : George Williams (partial)
luajit    : Mike Pall (used in LuajitTeX)

Compiled with libharfbuzz 8.3.0; using 8.5.0
Compiled with libpng 1.6.43; using 1.6.43
Compiled with lua version 5.3.6
Compiled with mplib version 2.10
Compiled with zlib 1.3.1; using 1.3.1

Development id: 7611
```

### GitLab Runnerのインストール

#### ユーザーの作成

このセクションではRunnerを動かすユーザー`gl-runner`を作成する。なお、**ランナーの実行に既存ユーザーを使う場合はこれらを行う必要はない**。

`dscl`コマンドを使用して新規ユーザーを作成する。まずは既存のグループIDとユーザーIDのリストを取得しよう。グループIDの一覧を取得するには次のコマンドを使用する。

```shell
% dscl . -list groups gid
...
```

このリストに含まれるものと重複しないグループIDを`gl-runner`のプライマリグループにする必要がある。仮にここでは`1111`とする。次に、ユーザーIDのリストを次のコマンドで取得する。

```shell
% dscl . -list users uid
...
```

先ほどと同様に、このリストに含まれるものと重複しないユーザーIDを`gl-runner`に割り当てる必要がある。仮にここでは`1111`とする。以下のコマンドでユーザー`gl-runner`を作成する。

```shell
% sudo dscl . -create /Users/gl-runner
% sudo dscl . -create /Users/gl-runner UserShell /bin/zsh
% sudo dscl . -create /Users/gl-runner RealName GitLab Runner
```

次にグループを作成する（もしくはオプションとして`staff`グループに所属させる運用でも良いだろう）。

```shell
% sudo dscl . -create /Groups/gl-runner PrimaryGroupID 1111
```

そして、ユーザーIDとグループIDを設定する。

```shell
% sudo dscl . -create /Users/gl-runner UniqueID 1111
% sudo dscl . -create /Users/gl-runner PrimaryGroupID 1111
```

ホームディレクトリを作成し、所有権を書き換える

```shell
% sudo mkdir /Users/gl-runner
% sudo dscl . -create /Users/gl-runner NFSHomeDirectory /Users/gl-runner
% sudo chown -R gl-runner:gl-runner /Users/gl-runner
```

以上で`gl-runner`ユーザーの作成は完了した。

#### LuaLaTeXの初期設定

ユーザー`gl-runner`で`luaotfload-tool`を実行してシステムにインストールされたフォントの情報を更新し、LuaLaTeXで使えるようにする。

```shell
% sudo su gl-runner
% luaotfload-tool --update
```

#### ダウンロード

以下のコマンドを実行し、GitLab Runnerの実行バイナリファイルをダウンロードする

Intel Macの場合：

```shell
% sudo curl --output /usr/local/bin/gitlab-runner "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-darwin-amd64"
```

Apple Silicon（M1など）の場合：

```shell
% sudo curl --output /usr/local/bin/gitlab-runner "https://s3.dualstack.us-east-1.amazonaws.com/gitlab-runner-downloads/latest/binaries/gitlab-runner-darwin-arm64"
```

ダウンロードしたバイナリに対して実行可能属性を付与する

```shell
% sudo chmod +x /usr/local/bin/gitlab-runner
```

以下のコマンドで実行可能か確認できる。

```shell
% gitlab-runner --version
Version:      17.3.1
Git revision: 66269445
Git branch:   17-3-stable
GO version:   go1.22.5
Built:        2024-08-21T15:23:40+0000
OS/Arch:      darwin/amd64
``` 

#### トークンを取得

プロジェクトの管理画面の左ペインから"Settings">"CI/CD"を選択し、右ペインの"Runners"を開いて、"Project runners"の"New project runner"ボタンをクリックする。

::: {class=large-img}

![Fig. 1: New Project Runner 1](https://github.com/ShinobuAmasaki/ShinobuAmasaki.github.io/blob/5ae2b54d5e903298474301165f5d613ae826e202/img/gitlab-latex/new-project-runner_1.png?raw=true)

:::

次にランナーのTagを設定するが、ここでは`macos, latex, shared, amd64`とする。オプションで構成の情報を設定する。最後に"Create Runner"ボタンをクリックする。

::: {class=large-img}

![Fig. 2: New Project Runner 2](https://github.com/ShinobuAmasaki/ShinobuAmasaki.github.io/blob/5ae2b54d5e903298474301165f5d613ae826e202/img/gitlab-latex/new-project-runner_2.png?raw=true)

:::



次の画面"Register runner"で、"Runner created."と表示されれば成功である。その画面でプラットフォームにmacOSを指定する。さらに**"runner authentication token"の部分にトークン文字列が表示されるのでこれを控えておく**。このトークンは次のセクションで使用する。

::: {class=large-img}

![Fig.3 Register runner 1](https://github.com/ShinobuAmasaki/ShinobuAmasaki.github.io/blob/5ae2b54d5e903298474301165f5d613ae826e202/img/gitlab-latex/register-runner_1.png?raw=true)

:::

::: {class=large-img}

![Fig. 4: ](https://github.com/ShinobuAmasaki/ShinobuAmasaki.github.io/blob/5ae2b54d5e903298474301165f5d613ae826e202/img/gitlab-latex/register-runner_2.png?raw=true)
:::

#### ランナーの登録

`gitlab-runner`をスーパーユーザーで実行し、対話的にランナーを登録することができる。

1. コマンドを起動する。

   ```shell
   sudo gitlab-runner register
   ```

2. GitLabインスタンスのURLを聞かれる。本稿ではGitLab.comにて管理されているグループにランナーを追加するので、`https://gitlab.com/`を指定する。

   ```
   Enter the GitLab instance URL (for example, https://gitlab.com/):
   https://gitlab.com/
   ```

3. トークンを指定する（`x`は伏せ字、前のセクションでブラウザに表示されたものを入力する）。

   ```
   Enter the registration token:
   xxxxxxxxxxxxxxxxxxxxxxxxx
   ```

   以下の表示が出力されれば、トークンの照合に成功している。

   ```
   Verifying runner... is valid                        runner=xxxxxxxxx
   ```

4. このランナーの名前を指定する。このMac miniのホスト名は`mini`なので、例えばここでは`mini.local`とする。

   ```
   Enter a name for the runner. This is stored only in the local config.toml file:
   [mini.local]: mini.local
   ```

5. Executerとして、`shell`を指定する。

   ```
   Enter an executor: parallels, virtualbox, kubernetes, docker-autoscaler, shell, ssh, docker-windows, docker+machine, instance, custom, docker:
   shell
   ```

6. 5を終えると、以下の表示が出力されて登録は成功となる。

   ```
   Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
   
   Configuration (with the authentication token) was saved in "/etc/gitlab-runner/config.toml" 
   ```

   ここで、`gitlab-runner`の設定ファイルが`/etc/gitlab-runner/config.toml`に保存されたことを覚えておこう。なお、この時点で、GitLab.comのプロジェクトの管理画面から登録されたランナーの情報を閲覧することができる（プロジェクトの左ペインから"Settings">"CI/CD"を選択して、右ペインの"Runners"を展開すると、"Assigned project runners"の項目に先ほど登録したランナーが追加されているはずである）。

#### 設定ファイルの内容を編集する

システムにインストールされた`config.toml`の内容を確認しよう。

```shell
% sudo cat /etc/gitlab-runner/config.toml
```
このコマンドを実行すると、以下のような出力を得る。`[[runners]]`の各項目に登録時に指定した値が書かれているはずである。

```
concurrent = 1
check_interval = 0
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "mini.local"
  url = "https://gitlab.com/"
  id = XXXXXXXX
  token = "xxxxxxxxxxxxxxxxxxxxxxxxx"
  token_obtained_at = 2024-09-06T11:41:00Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
  [runners.custom_build_dir]
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
```

ここで上のセクションで登録した`gl-user`のディレクトリでビルドを行うように設定する。`[[runners]]`の項目リストに次のような`builds_dir`の項目を追加する。

```toml
[[runners]]
  builds_dir = "/Users/gl-runner/builds"
```

また、**MacPortsを使用している場合**は、`[[runners]]`の項目に` environment`文を追加で指定して、以下のように環境変数`PATH`を上書きする。

```toml
[[runners]]
  environment = ["PATH=/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
```

結果として`config.toml`は以下のようになった。

```
concurrent = 1
check_interval = 0
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "mini.local"
  url = "https://gitlab.com/"
  id = XXXXXXXX
  token = "xxxxxxxxxxxxxxxxxxxxxxxxx"
  token_obtained_at = 2024-09-06T11:41:00Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
  builds_dir = "/Users/gl-runner/builds"
  environment = ["PATH=/opt/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
  [runners.custom_build_dir]
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
```

注：筆者の環境では最初、`environment = ["PATH=/opt/local/bin:$PATH"]`を指定していたが、環境変数の追加が期待通りにできなかったため`PATH`変数を完全に上書きすることで解決した。

注：Homebrewを使用している場合は、`/usr/local/bin`はデフォルトで`PATH`に含まれているはずなので`environment`文は必要ないだろう。

#### ランナーをサービスとして実行

ランナーを起動する準備ができたので、以下のコマンドでランナーをインストールし起動する。ランナーのユーザーに`gl-runner`以外を使用する場合は`--user`の引数値で指定する。

```
% sudo gitlab-runner install --user gl-runner
Runtime platform                                    arch=amd64 os=darwin pid=44959 revision=66269445 version=17.3.1
```

```
% sudo gitlab-runner start               
Runtime platform                                    arch=amd64 os=darwin pid=45010 revision=66269445 version=17.3.1
```

```
% sudo gitlab-runner status
Runtime platform                                    arch=amd64 os=darwin pid=45023 revision=66269445 version=17.3.1
gitlab-runner: Service is running
```

これでランナーのインストールは完了した。ローカルホストのランナーがGitLab.comのプロジェクトとコミュニケーションできているかについては、プロジェクトの管理画面の"Settings">"CI/CD">"Runners">"Assigned project runners"を参照して、登録したランナーをクリックしその状態を確認することができる。以上でRunnerのインストールは完了した。GitLab.comの管理画面を開き、Assigned project runnersの一覧に緑色にマークされたランナーを確認することができるはずである。

## ランナーを動かす

このセクションではGitLab.comのリポジトリにプッシュして、実際にCIを動かしてみる。

GitLab.comで空のリポジトリ（例えば`ci_test`）を作成し、ローカルにクローンする。クローンしたディレクトリに、次のような3つのファイルを作成する。

```
ci_test
 │
 ├──.gitlab-ci.yaml
 │
 ├──latexmkrc
 │
 └──main.tex
```

ここで、各ファイルの役割を記しておこう。

- `.gitlab-ci.yml`は、GitLabのCI/CDパイプラインの実行において、ジョブやステージの定義を記述する設定ファイルである。このファイルには、ジョブの実行環境や依存関係、実行するスクリプト、環境変数、生成物の受け渡し、などパイプラインの動作に必要な設定が含まれている。このファイルはリポジトリのルートに配置され、GitLabがパイプラインを実行するときに参照される。
- `latexmkrc`は、`latexmk`コマンドに渡すLaTeXビルドの構成ファイルである。通常は`~/.latexmkrc`としてOSユーザーのホームディレクトリに置かれることが多いが、ここではリポジトリのルートに置いて`latexmk -r ./latexmkrc`としてコマンドライン引数にファイルを渡す方法を採用する。
- `main.tex`は、テスト用のLaTeX原稿である。本稿ではLuaLaTeXで書かれたものを扱う。

それぞれのファイルの中身についての詳細は後述する。

### Personal Access Tokenの取得・登録

ランナーからGitLab.comのリポジトリにコミットできるようにするために、Personal Access Token（個人用アクセストークン）を取得する。このアクセストークンは、後述の`.gitlab-ci.yml`で変数`COMMIT_ACCESS_TOKEN`として使用され、パスワードの代替として認証を通す役割を担う。これを取得するにはGitLab.comの管理画面から以下の手順を実行する。

1. 左ペインのアバターをクリックし、**Edit profile**を選択する。
2. 次のページで、左ペインの**Access tokens**を選択する。
3. さらに**Add new token**を選択する。
4. トークンの名前と有効期限を入力する。
5. **Select scopes**において、`write_repository`を選択する。
6. **Create personal access token**のボタンをクリックする。
7. 表示されたアクセストークンを安全な場所に控える（このページを離れるとトークンを再び見ることはできない）。

次に、取得したアクセストークンをCI/CDの変数に加える。GitLab.comのプロジェクトのページを開き、左ペインの"Settings" > "CI/CD"を開き、"Variables"を展開すると、"CI/CD Variables"が表示される。ここで"Add variable"のボタンをクリックする。"Add variable"の画面が出てくるので、以下のように入力する。

- Visibilityを`Masked`にする（これを選択することでログにアクセストークンの値が表示されない）。
- Flagsは指定する必要はないのでチェックを外す（`Protect variable`は`main`ブランチのみで運用する限りは必要ないだろう）。
- Keyに、`COMMIT_ACCESS_TOKEN`と入力する。
- Valueに、先ほど取得したトークン文字列を入力する。
- オプションで、Descriptionを記述する。
- 最後に"Add variable"のボタンをクリックする。

以上を完了すると、`COMMIT_ACCESS_TOKEN`のCI/CD変数が設定ファイル`.gitlab-ci.yml`の中で利用可能になる。使い方については次のセクションにおいて述べる。

### `latexmkrc`と`.gitlab-ci.yml`

`latexmkrc`ファイルの内容を以下に示す。このファイルはPerlで記述され、`latexmk`コマンドの実行に関する指示が含まれる。ここで`$out_dir`に`'output'`が指定されていることに注目してほしい。これはこのコマンドにより生成されたファイルを、カレントディレクトリの`output`ディレクトリ内に配置するための命令で、後述のYAMLファイルの`artifacts`キーにおいて使用される。

```perl
#!/usr/bin/env perl
$pdf_mode = 4;
$latex = 'lualatex -halt-on-error -interact=nonstopmode -syntax=1 %O %S';
$shell_escape = 1;
$out_dir = 'output'
```

次に`.gitlab-ci.yml`の例を示す。

```yaml
variables:
  LATEX_JOB_NAME: "${CI_PROJECT_NAME}"

stages: # 3つのステージを定義する
  - preprocess
  - build
  - deploy

prep_job:  # 必要なソフトウェアがインストールされていて、パスが通っていることを確認するジョブ
  stage: preprocess
  tags:
   - macos
   - latex
  only:
    - main # mainブランチに変更があった場合のみジョブを実行する
  script:
    - uname -a
    - latexmk --version
    - lualatex -v
    - git --version

build_job:  # LuaLaTeXでビルドを実行するジョブ
  stage: build
  tags:
    - macos
    - latex
  only:
    - main
  script:
    - latexmk -lualatex -r ./latexmkrc -g -jobname="${LATEX_JOB_NAME}" ./main.tex
  artifacts: # 次以降のジョブに受け渡す生成ファイルを定義する
    paths:
      - output/
    when: on_success
    access: all
    expire_in: "1 hours"

deploy_job:  # 得られた生成物をgitリポジトリのpdfブランチに追加するジョブ
  stage: deploy
  tags:
    - macos
    - latex
  only:
    - main
  before_script:
    - git config --local user.name "${GITLAB_USER_NAME}"
    - git config --local user.email "${GITLAB_USER_EMAIL}"
    - git fetch origin pdf
  script:
    - git checkout pdf
    - git pull origin pdf
    - rm ${LATEX_JOB_NAME}.pdf
    - cp ./output/"${LATEX_JOB_NAME}.pdf" .
    - if [ -n "$(git status --porcelain)" ]; then
    - git add "${LATEX_JOB_NAME}.pdf"
    - git commit -m "Deploying to pdf by ${GITLAB_USER_NAME} from ${CI_COMMIT_SHA}"
    - git push "https://oauth2:${COMMIT_ACCESS_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" pdf
    - echo "Commit successful"
    - fi
  dependencies:
    - build_job
```

このファイルで実行されるCI/CDは、`prep_job`, `build_job`, `deploy_job`の3つのジョブに分かれており、それぞれ、ファイルの上方で定義された`stage:`の下にリストされた`preprocess`, `build`, `deploy`ステージに対応している。それぞれのジョブの定義には`stage`, `tags`, `only`, `before_script`, `script`, `artifacets`, `dependencies`などのキーが指定されている。これらの詳細は公式ドキュメントを参照してもらうこととして、各キーの重要なポイントに限定して述べる。

まず、パイプラインやステージ、ジョブといった用語について説明しておこう。GitLabの**パイプライン**は、コードをビルド、テストそしてデプロイする一連の処理を自動化するフローの全体像であり、これによってCI/CDが実現される。パイプラインは複数のステージから構成され、ステージの中ではジョブという単位で実行される。**ステージ**とは、CI/CDパイプラインの中で**ジョブを論理的にグループ化する単位**であり、**ジョブ**とは**実際に実行される処理単位**（一連のコマンドやスクリプトなど）である。

リポジトリへのプッシュやマージリクエストがトリガーとなりパイプラインが起動され、定義されたステージの順番に、ステージに含まれるジョブが実行される。ここで、YAMLファイルに`stages:`にリストされたステージは逐次実行されるが、同じステージに属するジョブは並列実行されうるという点に気をつけなければならない。

#### キーの説明

以下に、上の例で使用したYAML書式のキーを簡単に説明する。

- `stages`：このキーはパイプラインに含まれるステージをリストの形で定義する。
- `variables`：パイプラインを通してグローバルに使用可能なCI/CD変数を定義する。

次に、ジョブの定義で使用されたキーについて説明しよう。上で述べた2つ以外のインデントされていない3つのキーはそれぞれのジョブ（`prep_job`、 `build_job`、`deploy_job`）を定義している。

- `stage`：ジョブ定義の中で記述され、そのジョブが所属するステージを1つ指定する。
- `tags`：そのジョブを実行するランナーが持つべきタグを指定する。リストとして複数指定することができ、その場合は指定されたすべてのキーを持っているランナーでのみジョブが実行される。
- `only`：パイプラインがトリガーされた時、`only`で指定されたブランチに変更があった場合のみ、そのジョブを実行する。上の例では`main`ブランチに変更があった場合のみジョブが実行される構成になっている。
- `before_script`：このキーがジョブ定義の中に記述された場合、後述の`script`が実行される前にジョブに固有のセットアップの処理を定義する。コマンドやスクリプトをリストの形式で記述する。
- `script`：このキーは、そのジョブにおけるメインの処理を、コマンドおよびスクリプトのリストの形式で定義する。上の例では`build_job`において`latexmk`コマンドを実行している。また`deploy_job`においては`build_job`の生成ファイルで既存ファイルを上書きし、変更があればコミットしてリモートリポジトリへプッシュする操作を実行している。
- `artifacts`：ジョブが終了した後に保存される生成物（ビルド生成物やテスト結果、ログファイルなど）を指してアーティファクトと呼ぶ。ここで指定したファイルは次のジョブで利用したり、パイプライン完了後にWeb UIからダウンロードすることができる。詳細は[公式ドキュメント](https://docs.gitlab.com/ee/ci/yaml/#artifacts)を参照されたい。
- `dependencies`：このキーは、アーティファクトを特定のジョブから引き継ぐことを明示的に指定する。このキーを指定しない場合は、以前のすべてのジョブに依存しているとみなされ、生成されたアーティファクトをすべて引き継ぐことになる。

#### CI/CD環境変数の説明

上の例で`.gitlab-ci.yml`に含まれる`LATEX_JOB_NAME`、`COMMIT_ACCESS_TOKEN`、`CI_PROJECT_NAME`、`GITLAB_USER_NAME`, `GITLAB_USER_EMAIL`、　`CI_SERVER_HOST`、`CI_PROJECT_PATH`はCI/CD変数と呼ばれる、ある種の環境変数のようなものである。これらは再利用したい値や、YAMLファイルに値をハードコーディングしないために使用される。最初の1つ（`LATEX_JOB_NAME`）はYAMLファイル内でユーザーによって定義されたCI/CD変数であり、2つ目はWEB UIから設定したCI/CD変数で、残る5つは事前定義されたCI/CD変数である。YAMLファイル内でユーザー定義CI/CD変数を使うには、`variables`キーを使って記述する。これは事前定義の変数と同様にジョブの`script:`などの中で参照することができる。後者の詳細は[公式ドキュメント](https://docs.gitlab.com/ee/ci/variables/)を参照してほしい。

これらの変数を参照するためには、変数名の先頭にドル記号`$`をつけ、二重引用符`"`を使って囲んで記述する必要がある。

### `main.tex`

以下のようなシンプルなTeXファイルをビルドする。ここでは、ヒラギノフォントファミリーを指定することにする。

```latex
\documentclass[a4j,]{ltjsarticle}
\usepackage{luatexja-fontspec}
\usepackage[hiragino-pron]{luatexja-preset} % ヒラギノフォントを使用する

\begin{document}
テスト
\end{document}
```

### コミット＆プッシュ

以下のコマンドでこれら3つのファイルをコミットしてプッシュする。

```shell
% git add .gitlab-ci.yml latexmkrc main.tex
% git commit
% git push origin main
```

そしてGitLab.comのWeb UIを開き、プロジェクトのページの左ペインから"Build">"Pipeline"を選択すると、プッシュによってトリガーされたパイプラインが追加されているのを確認することができるはずである。追加されてしばらく待つとパイプラインが実行され、成功した場合はステータスが`Passed`となり、失敗した場合は`Failed`となる。

### PDFを取得

パイプラインが成功した場合は、プロジェクトのディレクトリで`git fetch origin pdf`/`git pull origin pdf`を実行し、`pdf`ブランチにスイッチすると成果物のPDFファイルを得ることができる。もしくは、アーティファクトの保存期間内ならば、Web UIのパイプラインのページからアーティファクトのアーカイブをダウンロードすることができる。

入手したPDFファイルに`pdffonts`コマンドを実行すると以下のように出力され、確かにヒラギノフォントが埋め込まれていることを確認できる。

```
% pdffonts ci_test.pdf 
name                                 type              encoding         emb sub uni object ID
------------------------------------ ----------------- ---------------- --- --- --- ---------
ROGHWJ+HiraMinProN-W3                CID Type 0C       Identity-H       yes yes yes      4  0
JFRMQG+LMRoman10-Regular             CID Type 0C       Identity-H       yes yes yes      5  0
```

これにて本稿の目標は達成された。

## トラブルシューティング

**プライベートリポジトリを`git clone`できない**

GitLabとの接続に`ssh-agent`を使うと解決するかもしれない。まず`~/.ssh/config`に以下の記述を加える。

```
Host gitlab.com
   HostName gitlab.com
   User    git
   IdentityFile /path/to/secret-key
```

SSHエージェントを起動し、秘密鍵を登録する。

```shell
% eval `ssh-agent`
% ssh-add ~/.ssh/<secret_key>
```

鍵認証で接続できるか試してみるには`ssh -T gitlab`コマンドを使用する。`Welcome ...`と表示されれば成功である。

```
% ssh -T gitlab
Welcome to GitLab, @<USER>!
```

これを設定したあとに`git clone`を行う。

```shell
% git clone git@gitlab.com:<project>/<repos>.git
```

なお、`ssh-add -L`でエージェントに登録された鍵を表示できる。

**最初のパイプラインを実行できない**

GitLab.comにユーザーを新しく登録した場合、CI/CDを動かす前にユーザーのSMS認証を終える必要があるかもしれない。これはGitLabのプロジェクトの管理画面に案内が表示されるので、それに従って認証を行う。

## おわりに

以上、LaTeX文書の執筆に付随する作業をGitLabのCI/CDを使ってできるだけ自動化する方法について述べた。当初は筆者自身の備忘録としてメモを書いて済ませるつもりであったが、この記事の提供する情報を自分以外にも必要とする人がいるかもしれないので公開することにした。この方法を使えばリモートリポジトリをマスターとして複数の端末から文書の編集を行うことができるようになる。読者のドキュメントの執筆がより便利になれば幸いである。

## 参考文献

1. [www.macports.org](https://www.macports.org/install.php)
2. [#MacPortsによるインストール TeX Live/Mac - TeX Wiki](https://texwiki.texjp.org/?TeX%20Live%2FMac#texlive-install-port)
3. [Install GitLab Runner on MacOS - GitLab Docs](https://docs.gitlab.com/runner/install/osx.html)
4. [Registering runners - GitLab Docs](https://docs.gitlab.com/runner/register/index.html?tab=macOS)
5. [CI/CD YAML syntax reference - GitLab Docs](https://docs.gitlab.com/ee/ci/yaml/)
6. [GitLab CI/CD variables - GitLab Docs](https://docs.gitlab.com/ee/ci/variables/)
7. [Personal Access Tokens - GitLab Docs](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
