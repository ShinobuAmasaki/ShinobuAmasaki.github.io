# Fortranから使うPLplot入門 #??

## 演習問題 #1 - 地震学におけるグーテンベルグ・リクター則


例題として、ここでは、片対数グラフのプロットを行う実践的な方法について述べます。

- Fortranを使ってデータセットから値を集計し、配列に格納する
- PLplotで片対数グラフを構成し、配列の値をプロットする
- 配列の値から対数回帰線を計算し、これをプロットする
- PNGファイルとして出力する

地震学におけるグーテンベルグ・リクター則（GR則）とは、

例として扱うデータセットは、[気象庁の「地震月報（カタログ編）」](https://www.data.jma.go.jp/eqev/data/bulletin/index.html)の[震源データ](https://www.data.jma.go.jp/eqev/data/bulletin/hypo.html)のページで公開されている、2018年から2022年までの5年間の地震活動に関するファイル（h2018.zip, h2019.zip, h2020.zip, h2021.zip, h2022.zip）を使用します。

なお、このデータの利用にあたっては[「地震月報（カタログ編）- 利用にあたって」](https://www.data.jma.go.jp/eqev/data/bulletin/readme_j.html)を読んでください。

これらのファイル（例えば`h2022.zip`）を解凍して得られるデータファイル（同様に`h2022`）は、96バイト固定長レコードのテキストで構成されています。
フォーマットの詳細は[震源レコードフォーマット](https://www.data.jma.go.jp/eqev/data/bulletin/data/format/hypfmt_j.html)を参照してください。

この例で必要となるのはマグニチュードの値です。あるマグニチュードの範囲（例えば0.1刻みなど）で全レコードを集計して、地震規模に対する発生回数のデータを得ます。


### プログラム全体

```fortran
```

## 草稿

使用しているAPI一覧

- init
  - `plspal0`
  - `plsdev`
  - `plsfnam`
  - `plinit`
- frame
  - `pladv`
  - `plvpor`
  - `plvasp`
  - `plwind`
  - `plcol0`
  - `plbox`
  - `plfont`
  - `pllab`
- plot
  - `log10` (Fortran intrinsic)
  - `least_square_method` (User Function)
  - `plstyl`
  - `plline`
  - `plwidth`
  - `plssym`
  - `plsym`
- legend
  - `pllegend`
- text_plot
  - `plschr`
  - `plpsty`
  - `plfill`
  - `plptex`
- finalize
  - `plend`