---
title: "できるだけ全部ビルドするPLplotインストール【Linux編】"
date: 2024-12-20
link: https://shinobuamasaki.github.io/items/how-to-install-plplot-from-source-code.html
language: ja
author: 雨崎しのぶ（Amasaki Shinobu）
description: "LinuxにおいてPLplotライブラリをソースコードからビルドしてインストールする方法についての記事"
---

# できるだけ全部ビルドするPLplotインストール【Linux編】

Author: 雨崎しのぶ

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2024-12-20 JST

## はじめに

先日から[『Fortranから使うPLplot入門』](https://qiita.com/amasaki203/items/1dbeb02a2adb7265654d)という一連の記事を書いていて、主にPLplotの使い方について解説しています。その記事では、このソフトウェアのインストールの方法について各OSごとに説明しましたが、Linuxでは管理者権限が必要な方法しか書いていませんでした。

本稿では、Linuxの計算機で管理者権限がない（`sudo`が使えない）場合でも、PLplotを試してみるための方法を解説します。依存関係ライブラリとPLplotライブラリをできる限り自分でビルドして、管理者権限の必要ない`~/.local`ディレクトリにインストールします。

ただし、コンパイラとビルドツールは利用可能であることを前提とします（[Ubuntuの準備](#ubuntuの準備)を参照）。

今回はUbuntu Server 22.04.5 LTSを例に使っていきますが、他のディストリビューションでもほぼ同様にできると思います。

なお、クロスコンパイルするアプローチについては触れません。

## 目次

- [はじめに](#はじめに)
- [Ubuntuの準備](#ubuntuの準備)
   - [必要なパッケージの追加](#必要なパッケージの追加)
   - [Cairoをインストールする場合](#cairoをインストールする場合オプショナル)
- [レギュレーション](#レギュレーション)
- [依存関係のインストール](#依存関係のインストール)
   - [libHaru](#libharu)
   - [Cairo](#cairo中級者向け)
      - [Cairoのインストール](#cairoのインストール)
      - [Pangoのインストール](#pangoのインストール)
- [PLplotのインストール](#plplotのインストール)
- [プログラムの実行](#プログラムの実行)
- [まとめ](#まとめ)
- [参考文献](#参考文献)

## Ubuntuの準備

まっさらな状態のUbuntu Server 22.04.5 LTS (minimized)からスタートします。

最初に`~/.local`ディレクトリを作成しておきます。また、インストール直後の場合には`sudo apt update`を実行しておきましょう。

```
% mkdir -p $HOME/.local/bin
% sudo apt update
```

ここで`$HOME/.local/bin`にパスが通っていることを確認しておきましょう。通っていない場合は以下のコマンドを実行します。

```
% export PATH=$HOME/.local/bin:$PATH
```

### 必要なパッケージの追加

LinuxでPLplotをビルドするには、最低限、`make`, `cmake`, `ld`, `gcc`, `g++`, `gfortran`, `curl`, `tar`, `gzip`のコマンドが必要となります。はじめにこれらが利用可能かどうか調べてみましょう。

Bashにビルドインされた`type`コマンドで、これらがインストールされているかどうか調べます。

```
% type make
-bash: type: make: not found
% type cmake
-bash: type: cmake: not found
% type ld
ld is /usr/bin/ld
% type gcc
-bash: type: gcc: not found
% type g++
-bash: type: g++: not found
% type gfortran
-bash: type: gfortran: not found
% type curl
curl is /usr/bin/curl
% type tar
tar is hashed (/usr/bin/tar)
$ type gzip
gzip is /usr/bin/gzip
```

`make`, `cmake`, `gcc`, `gfortran`, がインストールされていないので、これらを`apt`コマンドでインストールします。

```
% sudo apt install make cmake gcc g++ gfortran
```

### Cairoをインストールする場合（オプショナル）

Cairoは2次元グラフィックスのライブラリで、PLplotから使うとさまざまな出力形式が追加される強力なオプションです。便利ですが依存関係のライブラリが多く、自分でビルドして使うにはやや複雑なので、このセクションの内容は中級者向けとなります。ここではCairoをインストールする場合の必要なパッケージをインストールしておきます。

Cairoをビルドするには`git`, `python3`, `pip`, `pkg-config`が必要となります。

```
% type git
-bash: type: git: not found
% type python3
python3 is /usr/bin/pytho
% type pip
-bash: type: pip: not found
% type pkg-config
-bash: type: pkg-config: not found
```

デフォルトでは`git`,  `pip`, `pkg-config`が含まれていないのでこれらをインストールします。

```
sudo apt install git python3-pip pkg-config
```

Python3がインストールされたら、`pip`コマンドを使用して`ninja`と`meson`をユーザーディレクトリにインストールします。`apt`コマンドでインストールされるMesonはバージョンが古いので`pip`でインストールしましょう。

```
pip install --user meson
pip install --user ninja
```

**`sudo`コマンドを使用するのはここまでです。**

## レギュレーション

今回は管理者権限無しにPLplotをビルド、インストールすることに挑戦するので、以下のような制約を課します

- `sudo`を使わない
- `make`, `cmake`, `ld`, `gcc`, `g++`, `gfortran`, `curl`, `tar`のみでビルドする
   - ただしCairoをインストールする場合には`git`, `meson`, `ninja`, `python3`, `pip`, `pkg-config`を使用してよい
- ライブラリは`$HOME/.local`下に置く
- **Fortranバインディングを構成する**（ここが唯一のFortran要素）
- PDFを生成できれば成功
   - Cairoをインストールする場合にはPNGも生成する

## 依存関係のインストール

このセクションではPLplotの依存関係ライブラリをインストールする方法について解説します。

PDFを生成せずにSVGで十分という方はスキップしてください。その場合には、PLplotの出力形式は以下の6つに限定されます。

```
Plotting Options:
 < 1> ps         PostScript File (monochrome)
 < 2> psc        PostScript File (color)
 < 3> xfig       Xfig file
 < 4> null       Null device
 < 5> mem        User-supplied memory device
 < 6> svg        Scalable Vector Graphics (SVG 1.1)
```

PDFを生成するためにはlibHaruを、PNGを生成するためにはCairoをインストールします。

### libHaru

[libHaru](http://libharu.org/)はC言語で書かれたPDF生成のためのライブラリです。現在の最新版は2.4.4のようです。これを公式サイトまたはGitHubのリポジトリからダウンロードします。

```
% curl https://codeload.github.com/libharu/libharu/tar.gz/refs/tags/v2.4.4 -o libharu.tar.gz
```

ファイル`libharu.tar.gz`がダウンロードされるので、`tar`コマンドで展開し、展開先に移動します。

```
% tar xvzf libharu.tar.gz
% cd libharu-2.4.4
```

CMakeで構成を実行します。

```
% cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$HOME/.local
```

ビルドしてインストールします。

```
% cmake --build build
% cmake --install build
```

`libhpdf.so`などのライブラリファイルは`$HOME/.local/lib`に、ヘッダーファイルは`$HOME/.local/include`にインストールされます。

これでlibHaruのインストールは完了です。PDFを出力できればよいという方は、次のセクションをスキップして[PLplotのインストール](#plplotのインストール)に進んでください

### Cairo（中級者向け）

PNGやEPSで出力したい方はCairoをインストールする必要があります。

ここで、MesonやNinjaが使えることを確認しておきましょう（ユーザー名`shinobu`は例なので各自読み替えてください）。

```shell
% type meson
meson is /home/shinobu/.local/bin/meson
% type ninja
ninja is /home/shinobu/.local/bin/ninja
```

#### Cairoのインストール

Cairoの最新版は1.18.2です。これのソースコードを[公式リポジトリ](https://gitlab.freedesktop.org/cairo/cairo)からダウンロードしてインストールします。ホームディレクトリに戻ってtarファイルをダウンロードします（やや時間がかかります）。

```
% cd
% curl https://gitlab.freedesktop.org/cairo/cairo/-/archive/1.18.2/cairo-1.18.2.tar.gz -O
```

展開して、展開先のディレクトリに移動します。

```
% tar xvzf cairo-1.18.2.tar.gz 
% cd cairo-1.18.2
```

`meson`コマンドでビルドの構成を行いますが、この際にインストール先を`$HOME/.local`にするためのオプションを指定します。

```
% meson setup build -Dprefix=$HOME/.local
```

このコマンドでMesonは、Cairoの依存関係を自動的に解決してくれるのでとても便利です（この時に`git`が使用されます）。

`fontconfig`と`freetype`、`cairo`について以下のような出力が得られれば構成は成功です。

```
fontconfig 2.14.2

  General
    Documentation              : NO
    NLS                        : YES
    Tests                      : YES
    Tools                      : YES

  Defaults
    Hinting                    : slight
    Font directories           : /usr/share/fonts, /usr/local/share/fonts
    Additional font directories:

  Paths
    Cache directory            : /home/shinobu/.local/var/cache/fontconfig
    Template directory         : /home/shinobu/.local/share/fontconfig/conf.avail
    Base config directory      : /home/shinobu/.local/etc/fonts
    Config directory           : /home/shinobu/.local/etc/fonts/conf.d
    XML directory              : /home/shinobu/.local/share/xml/fontconfig

freetype2 2.13.2

  Operating System
    OS      : linux

  Used Libraries
    Zlib    : system
    Bzip2   : no
    Png     : yes
    Harfbuzz: no
    Brotli  : no

cairo 1.18.2

  Surface Backends
    Image                   : YES
    Recording               : YES
    Observer                : YES
    Mime                    : YES
    Tee                     : YES
    Xlib                    : NO
    Xlib Xrender            : NO
    Quartz                  : NO
    Quartz-image            : NO
    XCB                     : NO
    Win32                   : NO
    CairoScript             : YES
    PostScript              : YES
    PDF                     : YES
    SVG                     : YES

  Font Backends
    User                    : YES
    FreeType                : YES
    Fontconfig              : YES
    Win32                   : NO
    Win32 DWrite            : NO
    Quartz                  : NO

  Functions
    PNG functions           : YES
    X11-xcb                 : NO
    XCB-shm                 : NO

  Features and Utilities
    cairo-trace:            : YES
    cairo-script-interpreter: YES
    API reference           : NO

  Subprojects
    fontconfig              : YES
    freetype2               : YES (from fontconfig)
    glib                    : YES 3 warnings
    gperf                   : YES (from fontconfig)
    gvdb                    : YES (from glib)
    libffi                  : YES (from glib)
    libpng                  : YES
    pcre2                   : YES (from glib)
    pixman                  : YES

  User defined options
    prefix                  : /home/shinobu/.local

Found ninja-1.11.1.git.kitware.jobserver-1 at /home/shinobu/.local/bin/ninja
```

`ninja`コマンドでビルドを実行し、インストールします。コンパイルするオブジェクトの数が多いので気長に待ちましょう。

```
% ninja -C build
% ninja -C build install
```

ここで、`libcairo.so`や`libfontconfig.so`といったライブラリは`$HOME/.local/lib/x86_64-linux-gnu`にインストールされることに注意してください。

#### Pangoのインストール

Pangoは文字のレンダリングのためのライブラリで、PLplotではCairoを使用する際に必要となります。GTKプロジェクトの一部ですが、[GNOMEのリポジトリから単体で入手できます](https://gitlab.gnome.org/GNOME/pango)。最新版はバージョン1.55.5です。

TARファイルをダウンロードして展開します。

```
% cd
% curl https://gitlab.gnome.org/GNOME/pango/-/archive/1.55.5/pango-1.55.5.tar.gz -O
% tar xvzf pango-1.55.5.tar.gz
% cd pango-1.55.5
```

ここで、Pangoのインストール時にCairoのライブラリをリンカとMesonに伝えるため環境変数`LD_LIBRARY_PATH`を設定しておきます（なお、既に別のライブラリを使用する目的でこの環境変数が設定されている場合には、追記する形でセットしてください）。

```
% export LD_LIBRARY_PATH=$HOME/.local/lib:$HOME/.local/lib/x86_64-linux-gnu
```

Mesonを実行します。この時、`--pkg-config-path`オプションを指定して、Cairoをインストールした際に生成される`pkg-config`用のファイルが入ったディレクトリをMesonに伝えます。

```
% meson setup build -Dprefix=$HOME/.local --pkg-config-path=$HOME/.local/lib/x86_64-linux-gnu/pkgconfig
```

ビルド構成が完了したら、ビルドしてインストールします。

```
% ninja -C build
% ninja -C build install
```

## PLplotのインストール

```
curl -L https://sourceforge.net/projects/plplot/files/latest/download > plplot.tar.gz
```

ダウンロードできたらTARファイルを展開し、展開先に移動します。

```
% tar xvzf plplot.tar.gz 
% cd plplot-5.15.0
```

依存関係のプログラムをインストールした場合には以下の環境変数を設定します。

```
% export CMAKE_LIBRARY_PATH=~/.local/lib
% export CMAKE_INCLUDE_PATH=~/.local/include
```

Cairoをインストールした場合には次の環境変数も設定します。

```
% export PKG_CONFIG_PATH=$HOME/.local/lib/x86_64-linux-gnu/pkgconfig
```

CMakeでビルド構成を実行します。

```
% cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$HOME/.local
```

ビルドしてインストールします。

```
% cmake --build build
% cmake --install build
```

この時、`libplplot`や`libplplotfortran`は`$HOME/.local/lib`にインストールされますが、Fortran用のMODファイルは`$HOME/.local/lib/fortran/modules/plplot`ディレクトリに配置されることに注意してください。

## プログラムの実行

以下のようなFortranプログラム`main.f90`を実行します（詳細は[「Fortranから使うPLplot入門 #1」](https://qiita.com/amasaki203/items/1dbeb02a2adb7265654d)を参照してください）。

```fortran
program main
   use plplot
   implicit none

   initialize: block
      call plinit
   end block initialize

   frame: block
      real(PLFLT), parameter :: xmin = 0d0, xmax = 1d0
      real(PLFLT), parameter :: ymin = -1d0, ymax = 1d0
      integer :: just, axis
      
      just = 0
      axis = 0
      call plenv( xmin, xmax, ymin, ymax, just, axis)
      call pllab("x", "y", "Title")
   end block frame

   plot: block
      real(PLFLT) :: cx, cy, dx, dy
      
      call plschr(12._plflt, 1._plflt)

      cx = 0.5d0
      cy = 0d0
      dx = 1d0
      dy = 0.5d0
      call plptex(cx, cy, dx, dy, 0.5_plflt, "Hello World!")
   end block plot

   finalize: block
      call plend
   end block finalize
 
end program main
```

ここで、改めて`LD_LIBRARY_PATH`を設定します。libHaruのみインストールした場合は次のようにします。（なお、既に別のライブラリを使用する目的でこの環境変数が設定されている場合には、追記する形でセットしてください）。

```shell
% export LD_LIBRARY_PATH=$HOME/.local/lib
```

Cairoもインストールした場合には以下のようにします。

```shell
% export LD_LIBRARY_PATH=$HOME/.local/lib:$HOME/.local/lib/x86_64-linux-gnu
```

コンパイルするには次のオプションをつけて`gfortran`コマンドを実行します

```
% gfortran main.f90 -I$HOME/.local/lib/fortran/modules/plplot -L$HOME/.local/lib -lplplot -lplplotfortran -o helloworld
```

実行ファイル`helloworld`を実行すると、ドライバの一覧が表示されます（以下はCairoもインストールした場合）。

```
% ./helloworld

Plotting Options:
 < 1> ps         PostScript File (monochrome)
 < 2> psc        PostScript File (color)
 < 3> xfig       Xfig file
 < 4> null       Null device
 < 5> mem        User-supplied memory device
 < 6> svg        Scalable Vector Graphics (SVG 1.1)
 < 7> pdf        Portable Document Format PDF
 < 8> pdfcairo   Cairo PDF Driver
 < 9> epscairo   Cairo EPS Driver
 <10> pscairo    Cairo PS Driver
 <11> svgcairo   Cairo SVG Driver
 <12> pngcairo   Cairo PNG Driver
 <13> memcairo   Cairo memory driver
 <14> extcairo   Cairo external context driver

Enter device number or keyword: 
```

これでデバイスと出力ファイル名を指定すれば、成功です。

## まとめ

今回はLinuxでPLplotを使ってFortranプログラムを書くために、ライブラリをホームディレクトリにインストールする方法について解説しました。上で述べた方法で構築することで、（ルート権限が使えない）共用計算機でもPLplotを使うことができると思います。

なお、この方法でビルドしたライブラリを継続的に使用する場合には、環境変数`LD_LIBRARY_PATH`や`PATH`の設定を`.bashrc`などに追加しておくのがおすすめです。

## 参考文献

- https://sourceforge.net/p/plplot/wiki/Home/
- https://gitlab.freedesktop.org/cairo/cairo
- https://gitlab.gnome.org/GNOME/pango
- http://libharu.org/
- https://github.com/libharu/libharu/wiki/Installation
- https://sourceforge.net/p/plplot/wiki/Building_PLplot/