# Amasaki Shinobu's site hosted by github.io

## このサイト用のマークダウンの書き方

### 大きい画像

大きい画像は以下のように`:::`でブロックを囲む。これで、Pandocの機能により、出力先のHTMLに`div`タグと属性`class=large-img`が設定される。`large-img`のスタイルは`common.css`に定義されている。

```markdown
::: {class=large-img}

![phpPgAdmin - Login](../img/postgres/phppgadmin-login.png)

:::
```

cf. https://pandoc-doc-ja.readthedocs.io/ja/latest/users-guide.html#divs-and-spans