# Amasaki Shinobu's site hosted by github.io

## License

Unauthorized duplication of articles provided in this repository beyond that permitted by GitHub's Terms of Service is prohibited. See [LICENSE](LICENSE).

However, the source code in the `sample-code` directory is provided under the MIT License. See [sample-code/LICENSE](sample-code/LICENSE).

## Writing Notes

### 大きい画像

大きい画像は以下のように`:::`でブロックを囲む。これで、Pandocの機能により、出力先のHTMLに`div`タグと属性`class=large-img`が設定される。`large-img`のスタイルは`common.css`に定義されている。

```markdown
::: {class=large-img}

![phpPgAdmin - Login](../img/postgres/phppgadmin-login.png)

:::
```

cf. https://pandoc-doc-ja.readthedocs.io/ja/latest/users-guide.html#divs-and-spans
