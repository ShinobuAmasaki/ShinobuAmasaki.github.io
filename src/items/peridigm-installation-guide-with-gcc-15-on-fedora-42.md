---
title: "Peridigmインストールガイド【GCC 15編】"
date: 2025-08-08
link: https://shinobuamasaki.github.io/items/peridigm-installation-guide-with-gcc-15-on-fedora-42.html
language: ja
author: 雨崎しのぶ（Amasaki Shinobu）
description: "Fedora 42上でGCC 15を使って破壊解析ツールPeridigmをインストールする方法を解説する記事"
---

# Peridigmインストールガイド【GCC 15・Fedora 42編】

Author: 雨崎しのぶ

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2025-08-08 JST

## 概要

本稿では破壊解析ツールPeridigmのインストールについて述べる。Ubuntu（22.04 LTS）でのインストール方法は柴田（2025）が詳しいが、これはPeridigmの依存関係を基本的にすべてビルドしてインストールする方法について述べている。これに対し本稿では、HDF5とNetCDF、およびTrilinosについてのみビルドするが、それ以外のソフトウェアについてはパッケージマネージャで提供されるもので、かつできるだけ新しいバージョンを使ってのインストールを試みる。この目的は、Peridigmの簡便なインストール方法を提供し、依存関係のなかで新しいバージョンを使ってよいものとそうではないものを区別することである。これらの理由から、新しいパッケージが提供されやすいLinuxのディストリビューションであるFedora 42を例に用いる。

## 目次

- [概要](#概要)
- [前準備](#前準備)
  - [WSLの場合](#WSLの場合)
  - [コンパイラやビルドツールのインストール](#コンパイラやビルドツールのインストール)
- [依存関係のインストール](#依存関係のインストール)
  - [パッケージマネージャからインストール](#パッケージマネージャからインストール)
    - [OpenMPI](#OpenMPI)
    - [BLAS/LAPACK](#BLAS\/LAPACK)
    - [OpenSSL](#OpenSSL)
    - [yaml-cpp](#yaml-cpp)
    - [Python3](#Python3)
    - [Boost](#Boost)
    - [zlib](zlib)
  - [ソースコードからビルドしてインストール](#ソースコードからビルドしてインストール)
    - [HDF5](#HDF5)
    - [NetCDF](#NetCDF)
- [Trilinosのインストール](#Trilinosのインストール)
  - [ダウンロードと展開](#ダウンロードと展開)
  - [CMakeで構成](#CMakeで構成)
  - [Trilinosのビルド](#Trilinosのビルド)
  - [Trilinosのインストール](#Trilinosのインストール)
- [Peridigmのインストール](#Peridigmのインストール)
  - [前準備とダウンロード](#前準備とダウンロード)
  - [ビルドしてインストール](#ビルドしてインストール)
  - [スクリプトファイルのコピー](#スクリプトファイルのコピー)
- [環境変数の設定](#環境変数の設定)
- [まとめ](#まとめ)
- [参考文献](#参考文献)

## 前準備

### WSLの場合

Windows Subsystem for Linuxのバージョン2（WSL2）を使う場合は以下を行うとよいだろう。そうでない場合は本節を読み飛ばして次節に移ってほしい。

まず最初に、PowerShellからFedora Linux 42を追加する。

```Powershell
wsl --install FedoraLinux-42
```

このコマンドを実行すると、以下のような出力を得る。

```
ダウンロードしています: Fedora Linux 42
インストールしています: Fedora Linux 42
ディストリビューションが正常にインストールされました。'wsl.exe -d FedoraLinux-42' を使用して起動できます
FedoraLinux-42 を起動しています...
Please create a default user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username:
```

UNIXユーザ名を尋ねるプロンプトが表示されるので、ここでは例えば`shinobu`とする（UNIXユーザ名は各自で好きな名前にしてほしい。本稿はユーザ名として`shinobu`使うものとして述べる）。

```
Enter new UNIX username: shinobu
Your user has been created, is included in the wheel group, and can use sudo without a password.
To set a password for your user, run 'sudo passwd shinobu'
```

ユーザ`shinobu`のパスワードを設定する。
```
sudo passwd shinobu
```

必要ならrootユーザーのパスワードも設定する。

```
sudo passwd
```

### コンパイラやビルドツールのインストール

ここでは、以下のコンパイラおよびビルドツールをパッケージマネージャからインストールする。

- GCC 15: `gcc`, `gfortran`, `g++`
- Make
- CMake
- M4
- Git
- `curl`
- `tree`

最初に、リポジトリの更新を確認する。

```
sudo dnf update -y
```

GCCと`make`、`cmake`、`m4`をインストールする。


```
sudo dnf install gcc gcc-fortran gcc-c++ make cmake m4
```

`git`をインストールする。

```
sudo dnf install git
```

`curl`と`tree`はデフォルトで入っていると思われるが、なければ以下のコマンドでインストールする。

```
sudo dnf install curl tree
```

## 依存関係のインストール

ここではTrilinos以外のPeridigmの依存関係のインストールについて解説する。

### パッケージマネージャからインストール

まず、Peridigmの依存関係のパッケージを、Fedora 42のデフォルトのパッケージマネージャコマンド`dnf`を使ってインストールする方法について述べる。

- OpenMPI
- BLAS/LAPACK
- OpenSSL
- yaml-cpp
- Python3
- Boost
- zlib-ng

#### OpenMPI

OpenMPIのインストールには次のコマンドを実行する：

```
sudo dnf install openmpi openmpi-devel
```

OpenMPIのバイナリ（ヘッダファイルも）は`/usr/lib64/openmpi`ディレクトリ下にインストールされるので、それらのファイルを使えるように環境変数を次のように設定する：

```
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
```

2025年8月現在では、OpenMPIのバージョン5.0.6がインストールされる。`mpirun --version`の実行結果は次の通り：

```
mpirun (Open MPI) 5.0.6

Report bugs to https://www.open-mpi.org/community/help/
```

#### BLAS/LAPACK

線形代数演算ライブラリのBLAS/LAPACKをインストールする。これらのインストールには次のコマンドを実行する。

```
sudo dnf install openblas openblas-devel lapack lapack-devel
```

2025年8月現在では、インストールされるBLAS (OpenBLAS) のバージョンは0.3.29、LAPACKのバージョンは3.12.0である。

#### OpenSSL

OpenSSLのインストールには次のコマンドを実行する。

```
sudo dnf install openssl
```

2025年8月現在では、OpenSSLのバージョン3.2.4がインストールされる。

#### yaml-cpp

yaml-cppのインストールには次のコマンドを実行する。

```
sudo dnf install yaml-cpp yaml-cpp-devel
```

`yaml-cpp-devel`をインストールしないとヘッダファイルがインストールされない点に注意する。2025年8月現在では、yaml-cppのバージョン0.8.0がインストールされる。

#### Python3

Python3のインストールには次のコマンドを実行する。

```
sudo dnf install python3 python3-devel
```

python3は既にインストールされているかもしれない。これはPeridigmのテストやスクリプト（分割されたファイルの統合など）の実行に必要となる。2025年8月現在、Pythonのバージョン3.13.5がインストールされる。

#### Boost

C++のライブラリであるBoostのインストールには次のコマンドを実行する。

```
sudo dnf install boost boost-devel
```

Boostのヘッダファイルは`/usr/include/boost`にインストールされる。

#### zlib

データ圧縮・伸張を行うライブラリのzlibをインストールするには次のコマンドを実行する：

```
sudo dnf install zlib-ng zlib-ng-devel zlib-ng-compat-devel
```

注：`zlib-ng`の`ng`は"next generation"の意味らしい（cf. https://github.com/zlib-ng/zlib-ng）。

### ソースコードからビルドしてインストール

次にHDF5とNetCDFをソースコードからビルドしてインストールする方法について述べる。Trilinosも同様にビルドしてインストールするが、その手順については別の節に後述する。

HDF5とNetCDFはともにTrilinosの依存関係である。Fedora 42ではHDF5を`dnf`コマンドで導入しようとすると、バージョン1.14.6がインストールされるが、これは後述の実行時エラーを起こすので、バージョン1.12.1をソースコードからビルドしてインストールする。NetCDFもこれに応じてバージョン4.8.1をソースコードからビルドしてインストールする。

インストール先は`/opt`ディレクトリ下にソフトウェアとそのバージョン毎に分けてインストールする。

#### HDF5

curlコマンドでダウンロードする

```
curl -O https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.1/src/hdf5-1.12.1.tar.gz
```

tarコマンドで展開する。
```
tar xf hdf5-1.12.1/
```

展開されたディレクトリ下に`build`ディレクトリを作成し、ここに移動して、構成を実行する。

```
mkdir -p hdf5-1.12.1/build
cd hdf5-1.12.1/build

../configure --prefix=/opt/hdf5/1.12.1 --enable-parallel --enable-shared --with-default-api-version=v110 --enable-hl --enable-fortran
```

読者の好みに応じて`--enable-cxx`や`--enable-fortran`などを付加してもよい（ここでは後者を採用した）。

`make`コマンドでビルドを実行する（`-j`オプションに渡す並列数はマシンに合わせて変更してほしい）。

```
make -j4
```

`su`コマンドでrootユーザーにスイッチし、インストールを実行する（`sudo make install`で行おうとすると環境変数が引き継がれない問題でエラーとなり失敗することがある）。

```
$ su
# make install
```

もしくは`sudo su`でrootユーザーになり、OpenMPIのパスを設定してインストールすれば良い。

```
$ sudo su
# export PATH=/usr/lib64/openmpi/bin:$PATH
# export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
# make install
```

インストールされたかどうかを確認する

```
$ export PATH=/opt/hdf5/1.12.1/bin:$PATH
```

##### HDF5のv1.14.6に起因するPeridigmの実行時エラーメッセージ

パッケージマネージャからHDF5をインストールすると、最終的なPeridigmの実行で次のようなエラーメッセージが表示されるようだ。

```
HDF5-DIAG: Error detected in HDF5 (1.14.6):
  #000: ../../src/H5FD.c line 368 in H5FDunregister(): not a file driver
    major: Invalid arguments to routine
    minor: Inappropriate type
```

#### NetCDF

curlコマンドでダウンロードする

```
curl -O -L https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.8.1.tar.gz
```

アーカイブを`tar`コマンドで展開して、そのディレクトリに移動する。

```
tar xf v4.8.1.tar.gz
cd netcdf-c-4.8.1
```

柴田（2025）に倣い、ヘッダファイルの数値を書き換える。変更するマクロ変数は`NC_MAX_DIMS`、`NC_MAX_VARS`、`NC_MAX_VAR_DIMS`の3つ。

デフォルトの値を確認する：

```
cat include/netcdf.h | grep  -e "#define NC_MAX_DIMS" -e "#define NC_MAX_VARS" -e "#define NC_MAX_VAR_DIMS"
```
上のコマンドを実行すると次のような出力が得られるだろう。
```
#define NC_MAX_DIMS     1024 /* not enforced after 4.5.0 */
#define NC_MAX_VARS     8192 /* not enforced after 4.5.0 */
#define NC_MAX_VAR_DIMS 1024 /**< max per variable dimensions */
```

柴田（2025）に倣い、マクロ変数の値を変更する。以下の3回の`sed`コマンドを実行して、`netcdf.h`のファイルを操作する：

```
sed -i \
-e 's@#define NC_MAX_DIMS     1024@#define NC_MAX_DIMS     65536@g' \
-e 's@#define NC_MAX_VARS     8192@#define NC_MAX_VARS     524288@g' \
-e 's@#define NC_MAX_VAR_DIMS 1024@#define NC_MAX_VAR_DIMS     8@g' \
./include/netcdf.h
```

変更されたことを確認するには上記の`cat`コマンドを再実行すればよい。以下のような出力を得られるだろう：

```
#define NC_MAX_DIMS     65536 /* not enforced after 4.5.0 */
#define NC_MAX_VARS     524288 /* not enforced after 4.5.0 */
#define NC_MAX_VAR_DIMS     8 /**< max per variable dimensions */
```

ヘッダファイルの編集が完了したら、ビルドディレクトリを作成し、そこに移動する。

```
mkdir -p build
cd build
```

構成を実行する。ここでコンパイラは最新のGCC バージョン15系なので、コンパイルを通すために、いくつかのオプションを`CFLAGS`に指定する：

- `-std=c11`
- `-D_GNU_SOURCE`
- ``-Wno-incompatible-pointer-type`
- `-I/opt/hdf5/1.12.1/include`

```
../configure --prefix=/opt/netcdf/4.8.1 CC=mpicc LDFLAGS="-L/opt/hdf5/1.12.1/lib" CFLAGS="-std=c11 -D_GNU_SOURCE -Wno-incompatible-pointer-types -I/opt/hdf5/1.12.1/include"
```

`make`コマンドでビルドする。

```
make -j4
```

rootユーザに切り替えて、ビルドしたファイルをインストールする。

```
$ su
# make install
```

`make install`の実行で以下のようなメッセージが表示されれば、NetCDFの

インストールは成功である。

```
+-------------------------------------------------------------+
| Congratulations! You have successfully installed netCDF!    |
|                                                             |
| You can use script "nc-config" to find out the relevant     |
| compiler options to build your application. Enter           |
|                                                             |
|     nc-config --help                                        |
|                                                             |
| for additional information.                                 |
|                                                             |
| CAUTION:                                                    |
|                                                             |
| If you have not already run "make check", then we strongly  |
| recommend you do so. It does not take very long.            |
|                                                             |
| Before using netCDF to store important data, test your      |
| build with "make check".                                    |
|                                                             |
| NetCDF is tested nightly on many platforms at Unidata       |
| but your platform is probably different in some ways.       |
|                                                             |
| If any tests fail, please see the netCDF web site:          |
| http://www.unidata.ucar.edu/software/netcdf/                |
|                                                             |
| NetCDF is developed and maintained at the Unidata Program   |
| Center. Unidata provides a broad array of data and software |
| tools for use in geoscience education and research.         |
| http://www.unidata.ucar.edu                                 |
+-------------------------------------------------------------+
```

## Trilinosのインストール

Peridigmの重要な依存関係ライブラリであるTrilinosをインストールする。このステップがPeridigmインストールの最難関であろう。

柴田（2025）に倣い、Trilinosはバージョン13.0.1を使用する。

### ダウンロードと展開

```
$ curl -O -L https://github.com/trilinos/Trilinos/archive/refs/tags/trilinos-release-13-0-1.tar.gz
$ tar xf trilinos-release-13-0-1.tar.gz
$ cd Trilinos-trilinos-release-13-0-1
```

### CMakeで構成

指定するオプションが多く、混乱しやすいので注意する。

```
cmake -S . -B build \
-DCMAKE_INSTALL_PREFIX:PATH=/opt/trilinos/13.0.1 \
-DMPI_BASE_DIR:PATH=/usr/lib64/openmpi \
-DCMAKE_BUILD_TYPE:STRING=Release \
-DBUILD_SHARED_LIBS:BOOL=OFF \
-DTrilinos_WARNINGS_AS_ERRORS_FLAGS:STRING="" \
-DTrilinos_ENABLE_ALL_PACKAGES:BOOL=OFF \
-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF \
-DTrilinos_ENABLE_ALL_FORWARD_DEP_PACKAGES:BOOL=OFF \
-DTrilinos_ENABLE_Teuchos:BOOL=ON \
-DTrilinos_ENABLE_Shards:BOOL=ON \
-DTrilinos_ENABLE_Sacado:BOOL=ON \
-DTrilinos_ENABLE_Epetra:BOOL=ON \
-DTrilinos_ENABLE_EpetraExt:BOOL=ON \
-DTrilinos_ENABLE_Ifpack:BOOL=ON \
-DTrilinos_ENABLE_AztecOO:BOOL=ON \
-DTrilinos_ENABLE_Belos:BOOL=ON \
-DTrilinos_ENABLE_Phalanx:BOOL=ON \
-DPhalanx_EXPLICIT_TEMPLATE_INSTANTIATION:BOOL=ON \
-DTrilinos_ENABLE_Zoltan:BOOL=ON \
-DTrilinos_ENABLE_SEACAS:BOOL=ON \
-DTrilinos_ENABLE_NOX:BOOL=ON \
-DTrilinos_ENABLE_Pamgen:BOOL=ON \
-DTrilinos_ENABLE_Kokkos:BOOL=ON \
-DTrilinos_ENABLE_SEACASPLT:BOOL=OFF \
-DTrilinos_ENABLE_SEACASBlot:BOOL=OFF \
-DTrilinos_ENABLE_SEACASFastq:BOOL=OFF \
-DTrilinos_ENABLE_EXAMPLES:BOOL=OFF \
-DTrilinos_ENABLE_TESTS:BOOL=OFF \
-DTPL_ENABLE_MATLAB:BOOL=OFF \
-DTPL_ENABLE_Matio:BOOL=OFF \
-DTPL_ENABLE_Netcdf:BOOL=ON \
-DNetcdf_INCLUDE_DIRS:PATH=/opt/netcdf/4.8.1/include \
-DNetcdf_LIBRARY_DIRS:PATH=/opt/netcdf/4.8.1/lib \
-DTPL_ENABLE_HDF5:BOOL=ON \
-DHDF5_INCLUDE_DIRS:PATH=/opt/hdf5/1.12.1/include \
-DHDF5_LIBRARY_DIRS:PATH=/opt/hdf5/1.12.1/lib \
-DTPL_ENABLE_MPI:BOOL=ON \
-DTPL_ENABLE_BLAS:BOOL=ON \
-DTPL_BLAS_LIBRARIES:FILEPATH=/usr/lib64/libblas.so \
-DTPL_ENABLE_LAPACK:BOOL=ON \
-DTPL_LAPACK_LIBRARIES:FILEPATH=/usr/lib64/liblapack.so \
-DTPL_ENABLE_Boost:BOOL=ON \
-DTPL_ENABLE_QT:BOOL=OFF \
-DTPL_ENABLE_X11:BOOL=OFF \
-DTPL_ENABLE_yaml-cpp:BOOL=ON \
-DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF \
-DTrilinos_VERBOSE_CONFIGURE:BOOL=OFF \
-DCMAKE_C_FLAGS="-std=c11" \
-DCMAKE_CXX_FLAGS="-include cstdint -Wno-template-body" \
-DCMAKE_Fortran_FLAGS="-std=legacy"
```

このコマンドで構成を実行すると、`build`ディレクトリが自動的に作成され、その下に必要なファイルとビルドのための情報がコピーされる。

GCC15を使った場合に、Trilinos13の構成とビルドが通るようにするには、いくつかのオプションを追加する必要がある。

- `-DCMAKE_C_FLAGS="-std=c11"`
  - Cの規格「C11」（ISO/IEC 9899:2011）を使用するように指示するオプション。

- `-DCMAKE_CXX_FLAGS="-include cstdint -Wno-template-body"`
  - `-include cstdint`はヘッダーファイルに`cstdint.h`を追加させるように指示する。
  - `-Wno-template-body`はテンプレートエラーを無効にするように指示する。

- `-DCMAKE_Fortran_FLAGS="-std=legacy"`
  - `-std=legacy`はFORTRAN 77相当の古い機能拡張を有効にしてビルドするように指示する。


なお、Boostとyaml-cppのインストールをパッケージマネージャを使ってデフォルトの場所にインストールした場合に限り、以下の構成オプションは指定しなくてよい。

- `-DTPL_Boost_INCLUDE_DIRS`
- `-DTPL_yaml-cpp_LIBRARIES`
- `-DTPL_yaml-cpp_INCLUDE_DIRS`

### Trilinosのビルド

CMakeコマンドでTrilinosのビルドをするには、次のコマンドを実行する。

```
cmake --build build -j 4
```

### Trilinosのインストール

ビルドが成功の後、インストールを行うには、次のコマンドを実行する。

```
sudo cmake --install build
```

## Peridigmのインストール

最後に、本稿の主題であるPeridigmをソースコードからビルドしてインストールする方法について述べる。

### 前準備とダウンロード

Trilinosのインストール先について、環境変数の設定する。

```
export PATH=/opt/trilinos/13.0.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/tirlinos/13.0.1/lib:$LD_LIBRARY_PATH
```

`git clone`でリポジトリを取得する。

```
git clone https://github.com/peridigm/peridigm.git
```

`peridigm`ディレクトリへ移動する。

```
cd peridigm
```

### ビルドしてインストール

`cmake`で構成を実行する。

```
cmake -S . -B build -DCMAKE_BUILD_TYPE:STRING=Release \
 -DCMAKE_INSTALL_PREFIX:PATH=/opt/peridigm \
 -DTRILINOS_DIR:PATH=/opt/trilions/13.0.1 \
 -DCMAKE_CXX_COMPILER:STRING="mpicxx"
```

`build`ディレクトリ内でビルドする。

```
cmake --build build -j 4
```

ビルドが完了したら最後にインストールする。

```
sudo cmake --install build
```

`PATH`環境変数を更新して、コマンド`Peridigm`を実行できるようにする。

```
export PATH=/opt/peridigm/bin:$PATH
```

`Peridimg`が実行可能かどうかを確かめる。

```
type Peridigm
```

以下のように出力されれば、Peridigmの実行ファイルのインストールには成功した。

```
Peridigm is /opt/peridigm/bin/Peridigm
```

### スクリプトファイルのコピー

最後に`peridigm/scripts`に含まれるPythonスクリプトを`/opt/peridigm/bin`にコピーする：

```
sudo cp scripts/* /opt/peridigm/bin
```

これは、`ls /opt/peridigm/bin`を実行して次のような結果を得られれば完了である。

```
CriticalInitialVelocityForBondBreaking.py
genesis_attributes_to_element_variables.py
image_to_text.py
MergeFiles.py
mirror.py
Peridigm
peridigm_to_yaml.py
plot_performance_test_results.py
run_unit_test.py
summarize_performance_test_results.py
text_to_genesis.py
xmlripper.py
```

## 環境変数の設定

`export`コマンドでセットした環境変数は再ログインした後には残らないので、シェルの設定ファイルにまとめて書いておくとよい。ここではBashを例にとり、その設定ファイル`~/.bashrc`に上で指定した環境変数について追記しておく（Zshの場合は`~/.zshrc`に記述する）。

```shell
export PATH=/usr/lib64/openmpi/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
export MANPATH=/usr/lib64/openmpi/share/man:$MANPATH

export PATH=/opt/netcdf/4.8.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/netcdf/4.8.1/lib:$LD_LIBRARY_PATH

export PATH=/opt/trilinos/13.0.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/trilinos/13.0.1/lib:$LD_LIBRARY_PATH

export PATH=/opt/peridigm/bin:$PATH
```

これらの行を設定ファイルに追記しておけば、再ログイン時に自動で環境変数が読み込まれ、`Peridigm`コマンドが常に利用可能となる。

また、必要に応じてHDF5のディレクトリへのパスを追加してもよい。

```shell
export PATH=/opt/hdf5/1.12.1/bin:$PATH
export LD_LIBRARY_PATH=/opt/hdf5/1.12.1/lib:$LD_LIBRARY_PATH
```

## まとめ

本稿ではFedora 42を用いて、破壊解析ツールのPeridigmについて、できるだけ新しいライブラリを使ったインストールの方法について述べた。依存関係のソフトウェアのうち、OpenMPIやBLAS/LAPACK、OpenSSL、Boost、yaml-cppについては新しいバージョンのライブラリを使ってPeridigmを実行することができる。

しかしながら、HDF5とNetCDF、およびこれらに依存するTrilinosを新しいバージョンに切り替えるのはハードルが高いだろう。特にHDF5のバージョン1.14系ではAPIが新しくなったようで、NetCDFバージョン4.8.1はこれには対応していない（NetCDFのリリースノートではv4.9.2でHDF5 v1.14系に対応し始めたと読み取れる記述がある）。また、Trilinosについては、PeridigmがどのようにTrilinosに依存しているかを詳細に確認してからバージョンアップを試みる必要があり、これには多大な労力がかかると見込まれるため今回は行っていない。そのため、これらのライブラリについては、柴田（2025）に従い、HDF5 v1.12.1、NetCDF v4.8.1、Trilinos v13.0.1を使ってインストールを行った。

Peridigmのインストールには苦労が多いという指摘もあるが、読者の扱う様々な環境でPeridigmを実行するために、本稿がその助けになれば幸いである。

## 参考文献

1. [柴田良一『はじめてのPeridigm　粒子モデルによる破壊解析』（インプレス・ネクスト・パブリッシング、2025年7月）、ISBN：9784295603948](https://nextpublishing.jp/book/18749.html)
1. [Migrating from HDF5 1.12 to HDF5 1.14 | The HDF Group](https://support.hdfgroup.org/documentation/hdf5-docs/Migrating+from+HDF5+1.12+to+HDF5+1.14.html)
1. [NetCDF Release Notes | Unidata](https://docs.unidata.ucar.edu/netcdf-c/4.9.2/RELEASE_NOTES.html)
1. [Peridigmをソースからインストールする | ぺんぎんや](https://e-penguiner.com/installation-of-peridigm/)
1. [New C++ features in GCC 15 | Red Hat Developer](https://developers.redhat.com/articles/2025/04/24/new-c-features-gcc-15#)
1. https://github.com/zlib-ng/zlib-ng
