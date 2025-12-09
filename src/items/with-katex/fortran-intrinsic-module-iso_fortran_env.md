---
title: "Fortran標準モジュール要約【iso_fortran_env編】[JA]"
date: 2025-12-09
language: ja
link: https://shinobuamasaki.github.io/items/fortran-intrinsic-module-iso_fortran_env.html
author: Amasaki Shinobu
description: "Fortran 2003で導入された標準モジュールの一つであるiso_fortran_envについてを扱った解説記事"
---

# Fortran標準モジュール要約【iso_fortran_env編】

Author: Amasaki Shinobu (雨崎しのぶ)

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2025-12-09 JST

## 概要

Fortran 2003以降では、言語の規格で定められた組込みモジュールを使うことができる。組込みモジュールはいくつか用意されているが、本稿ではFortranによるプログラミングで最も基本的であり、使うことによる恩恵の大きい`iso_fortran_env`モジュールについて解説する。

まず初めに、モジュールの導入の仕方について簡単に解説し、`iso_fortran_env`モジュールを導入できるようにする。この際に組込みモジュールとユーザ定義／サードパーティモジュールとでのキーワードの指定の違いについても説明する。

その後に、当該モジュールで定義されている定数・変数および手続について、筆者が独自に分類したカテゴリに分けて、それぞれについて簡単に説明を記す。

## 目次

- [概要](#概要)
- [目次](#目次)
- [組込みモジュールを導入する](#組込みモジュールを導入する)
  - [組込みモジュール一覧](#組込みモジュール一覧)
  - [`use`文によるモジュールの導入](#use文による組込みモジュールの導入)
- [`iso_fortran_env`モジュールで定義されているもの](#iso_fortran_envモジュールで定義されているもの)
  - [型の情報に関わるもの](#型の情報に関わるもの)
  - [文字列処理に関わるもの](#文字列処理に関わるもの)
  - [入出力に関わるもの](#入出力に関わるもの)
  - [コンパイル時の情報に関わるもの](#コンパイル時の情報に関わるもの)
  - [Coarray機能に関わるもの](#coarray機能に関わるもの)
  - [非推奨のもの](#非推奨のもの)
- [ノート](#ノート)
- [参考文献](#参考文献)

## 組込みモジュールを導入する

### 組込みモジュール一覧

Fortran 2018標準では、次の5つの組込みモジュールを処理系が提供するものと定めている：

- `iso_fortran_env`
- `ieee_arithmetic`
- `ieee_exceptions`
- `ieee_features`
- `iso_c_binding`

以下では、Fortranプログラミング環境に関する組込みモジュールの`iso_fortran_env`で定められている内容、すなわち変数や定数および手続について解説する。

### `use`文による組込みモジュールの導入

通常、モジュールの導入には`use`文を使う。`iso_fortran_env`はFortran標準の組込みモジュールであり、これも例外ではなく、`program`文または`module`文の直後に`use`文を置いて使うことが多い。なお、組込みモジュールを導入する際には`intrinsic`キーワードを加えて記述すると、組込みモジュールを指しているという意図が明確になるため、筆者はこれを推奨している。また、ユーザー定義モジュールを導入したい場合には、`non_intrinsic`キーワードを指定して、それを強制することが可能だ。

```fortran
program main
   use :: iso_fortran_env  ! iso_fortran_envモジュールを導入する。
   use, intrinsic :: ieee_arithmetic     ! 組込みモジュールのieee_arithmeticを導入
   use, non_intrinsic :: ieee_arithmetic ! ユーザー定義モジュールのieee_arithmeticを導入する。
   ...
end program main
```

なお、組込みモジュールとユーザー定義モジュールの名前空間は別のものと定められているため、同名の2つのモジュールを使うことが、規格では一応許可されている[^1]。けれども、やむを得ずそのような構成をとる際には`intrinsic`と`non_intrinsic`キーワードを適切に使い分けることが要求されるだろう。

## `iso_fortran_env`モジュールで定義されているもの

### 型の情報に関わるもの

組込み型の型パラメータとして与えたり、`kind()`の引数に指定して利用したりするものを以下に示す。

- `int8`：8ビット（1バイト）の整数型を指す種別値を持つ定数。範囲は-128から127
- `int16`：16ビット（2バイト）の整数型を指す種別値を持つ定数。範囲は-32,768から32,767
- `int32`：32ビット（4バイト）の整数型を指す種別値を持つ定数。範囲は-2,147,483,648から2,147,483,647
- `int64`：64ビット（8バイト）の整数型を指す種別値を持つ定数。範囲は-9,223,372,036,854,775,808から9,223,372,036,854,775,807
- `real32`：32ビットの浮動小数点数を指す実数型種別値持つ定数。単精度実数と呼ばれる型の種別に対応する
- `real64`：64ビットの浮動小数点数を指す実数型の種別値を持つ定数。倍精度実数と呼ばれる型の種別に対応する
- `real128`：128ビット（16バイト）の浮動小数点数を指す実数型の種別値を持つ定数。四倍精度実数と呼ばれる場合もある。実装されているかは処理系により異なる
- `logical8`：8ビットの論理型を指す種別値を持つ定数
- `logical16`：16ビットの論理型を指す種別値を持つ定数
- `logical32`：32ビットの論理型を指す種別値を持つ定数
- `logical64`：64ビットの論理型を指す種別値を持つ定数
- `integer_kinds`：処理系がサポートする整数型の種別値一覧を持つ配列定数
- `real_kinds`：処理系がサポートする実数型の種別値一覧を持つ配列定数
- `logical_kinds`：処理系がサポートする論理型の種別値一覧を持つ配列定数

最後の3つは、それぞれの型の種別値の一覧を取得でき、その処理系で利用可能な（非負整数をもつ）型パラメータを知ることができる。

### 文字列処理に関わるもの

`character_kinds`は、処理系がサポートする文字列型の種別値一覧を持つ配列定数であり、これに含まれる値の一つを`character`型変数の宣言時に`kind`型パラメータとして渡すことで、異なる文字種別の文字列変数を扱うことが可能になる[^2]。

### 入出力に関わるもの

- `input_unit`：標準入力のユニット（装置番号）を指す値を持つ定数
- `output_unit`：標準出力のユニットを指す値を持つ定数
- `error_unit`：標準エラー出力のユニットを指す値を持つ定数
- `iostat_end`：入出力文の実行で、`iostat`指定子から渡された値がEnd Of Fileの条件に該当するかを確認するための定数
- `iostat_eor`：入出力文の実行で、`iostat`指定子から渡された値がEnd Of Recordの条件に該当するかを確認するための定数
- `iostat_inquire_internal_unit`：`inquire`文の実行で、内部ファイルに割り当てられた装置番号を指して照会した際に、`iostat`指定子に返される値と比較するための定数。この比較を行うことで、不適切な`inquire`文の実行に対してのエラーハンドリングができるようになる
- `file_storage_size`：外部ファイルの記憶単位のビット長を表す定数。`open`文の`recl`指定子に用いる。

標準入力・出力・エラー出力については、従来のコードでは慣例的にそれぞれ`5`, `6`, `0`の値が直接書かれていたが、Fortran 2003において標準化され、`iso_fortran_env`から利用可能となっている。ただし、多くの処理系で`input_unit`が`5`に、`output_unit`が`6`に、`error_unit`が`0`に結び付けられているので、ファイルを開く`open`文では、これらの値を使わないほうがよい。

### コンパイル時の情報に関わるもの

実行ファイルの中に、ビルド時のコンパイラのバージョン、コンパイルオプションを埋め込むことができる手続が提供されている：

- `compiler_version()`：ビルド時に使用されたコンパイラのバージョン情報を表す文字列を返す関数。
- `compier_options()`：ビルド時に使用されたコンパイルオプションの情報を表す文字列を返す関数。

### Coarray機能に関わるもの

Coarrayに関する定数と変数、および手続については、詳しく解説できるだけの理解と技量を筆者はまだ持ち合わせていないので、モジュールで定義されているものの名前を紹介するに留める。以下は、Fortran 2018で定義されている名前である[^3]。

- `atomic_int_kind`
- `atomic_logical_kind`
- `current_team`
- `initial_team`
- `parent_team`
- `stat_locked`
- `stat_locked_other_image`
- `stat_stopped_image`
- `stat_failed_image`
- `stat_unlocked`
- `stat_unlocked_failed_image`
- `lock_type`
- `event_type`
- `team_type`

### 非推奨のもの

以下の2つは、Fortranのstorage association（記憶列結合）という機能に関わるものだが、これはFortran 90の時点で非推奨になっており[^4]、今後も使うべきではないものに分類されている。そのためここでは名前だけを紹介することに留める。もし古いコードのメンテナンス等で、知識が必要になったら参考文献1の付録Aなどを参照してほしい。

- `numerical_storage_size`
- `character_storage_size`

## ノート

1. `logical8`から`logical64`は、Fortran 2023標準で採用された比較的新しいもので、論理型の種別値を持つ定数である。
2. Fortran 90で追加された `selected_int_kind()`・ `selected_real_kind()`と、Fortran 2003で追加された`selected_char_kind()`の3つの手続は、モジュールではなく言語組込みの手続である。
3. 2と同様に、Fortran 2023で追加された`selected_logical_kind()`も言語組込みの手続である。
4. `atomic_and`, `atomic_or`,`atomic_xor`, `atomic_add`, `atomic_fetch_add`, `atomic_fetch_and`, `atomic_fetch_or`, `atomic_fetch_xor`, `atomic_cas`, `atomic_define`, `atomic_ref`, の手続はすべて、モジュールではなく言語組込みの手続である。
5. Fortran 2018において、複素数型の型種別を指す定数は用意されていない。
6. `real128`の実数型が提供されている（すなわち定数`real128`が非負整数の値を持つ）かどうかについて次のコンパイラを調べた：
   - GNU Fortran `gfortran`（Linux環境のGNU Fortran 14.3.0）では値`16`を持つ。
   - Intel Fortran Compiler `ifx`（Linux環境のIFX 2024.0.0 20231017）では値`16`を持つ。
   - LLVM Flang `flang`（Linux (Ubuntu 24.04) 環境の`flang-new-21`）は値`-1`を持ち、これを型パラメータに指定するとコンパイルエラーとなる。
7. 一部の処理系では半精度浮動小数点数（16ビット実数型）を扱える処理系もあるようだが、標準化されていないことに注意（参考文献3を参照）。
8. 一部の処理系では拡張倍精度浮動小数点数（例: `real(kind=10)`）を指定できるが、これについては標準化されておらず、当該モジュールでこれを指す定数は存在しない。加えて、筆者はこれについて語るに足る知見を持たないので、ここで触れるだけにしておく。
9. 現在のFortran標準では、モジュールにおいても符号なし整数型は提供されていないが、次の規格 "F202Y" 策定の議論において、導入が議論されている（参考文献4を参照）。

## 参考文献

1. Michael Metcalf, John Reid, Malcolm Cohen, “Modern Fortran Explained: Incorporating Fortran 2018”, Oxford University Press, 2018, https://doi.org/10.1093/oso/9780198811893.001.0001, ISBN: 9780198811886

2. Michael Metcalf, John Reid 著, 西村恕彦・和田英穂・西村和夫・高田正之 訳,"bit別冊 詳解 Fortran90", 共立出版株式会社, 1993

3. NAG Fortran コンパイラ 7.0 マニュアル, 第2.12節 "半精度浮動小数点数", Nihon Numerical Algorithms Group K.K., https://www.nag-j.co.jp/nagfor/np70_manual/compiler_2_12.html

4. Document #N2230, DIN-6 "Proposal for UNSIGNED type", ISO/IEC JTC1/SC22/WG5—The Home of Fortran Standard: https://wg5-fortran.org, PDF: https://wg5-fortran.org/N2201-N2250/N2230.pdf

[^1]: ただし、Intel Fortran Compiler `ifx`ではコンパイルエラーとなる。
[^2]: 処理系ごとに異なる文字種別については、筆者の別の記事でテーマに取り上げて解説をする予定である（2025年12月9日現在）。
[^3]: 参考文献1の第17章（pp. 325-346）と第20章（pp. 383-396）を参照のこと。
[^4]:  参考文献3「bit別冊 詳解Fortran 90」の第11章（pp. 253-265）において「使わないほうがよい機能」に挙げられている。