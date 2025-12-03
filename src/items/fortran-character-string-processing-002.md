---
title: "Fortranで文字列【基礎編その2—配列】[JA]"
date: 2025-12-03
language: ja
link: https://shinobuamasaki.github.io/items/fortran-character-string-processing-002.html
author: Amasaki Shinobu
description: "Fortranにおける文字列の取扱いとその処理に関する解説についての連載記事の第2回。文字列の配列について、組込み機能の固定長という制約と派生型でラップして実現する可変長文字列配列を扱った記事"
---

# Fortranで文字列【基礎編その2—文字列の配列】

Author: Amasaki Shinobu (雨崎しのぶ)1

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2025-12-03 JST

前の記事：[Fortranで文字列【基礎編その1】](https://shinobuamasaki.github.io/items/fortran-character-string-processing-001.html)

次の記事：Fortranで文字列【基礎編その3—文字種別】（準備中）

## 概要

「Fortranの特技といえば配列」と言えるくらいには、このプログラミング言語は豊富な配列処理の機能を持つ。そこで、本稿では連載シリーズ「Fortranで文字列」のテーマである文字列処理にフォーカスして、文字列型配列と可変長文字列を含む派生型の配列の取り扱いについて述べる。最初に組込みの文字列型配列の使い方とその制約を、次に派生型による可変長文字列の配列の模擬的な実現方法についてを述べる。

## 固定長の文字列型配列

Fortranで組込みで提供されている文字列型の配列は、そのすべての要素の長さが等しい固定長の配列である。この制約は動的割付け配列でも同じで、組込みの型を使うかぎり回避することはできない。このセクションでは、まずFortranに組込まれている文字列型配列とはどのようなものかを見ていこう。

### 文字列型配列の宣言と割付け

Fortranでは数値型や論理型と同様に、文字列型でも配列を扱うことができる。

```fortran
character :: a(5), b(0:7)
character(8) :: c(10)
```

`dimension`属性で配列形状を指定することもできる。

```fortran
character(8), dimension(10) :: d
character(4), dimension(4,4) :: e  ! 多次元配列も可
```

割付け可能な文字列型配列の宣言は次のように`allocatable`属性を指定する。

```fortran
character(8), allocatable, dimension(:) :: array1
character(:), allocatable, dimension(:) :: array2
```

ここで、配列要素の長さを割付け時に指定したい場合には、長さパラメータを整数値ではなく`:`と指定する。

これらの配列を割り付けるには`allocate`文を次のように記述する：

```fortran
allocate(character(8) :: array1(4)) ! 長さ8, サイズ4の配列
allocate(character(4) :: array2(5)) ! 長さ4, サイズ5の配列
allocate(array3(12), source='abcd') ! 各要素が長さ4をもち'abcd'で初期化されたサイズ12の配列
```

ここで、`array1`は長さ8でサイズ4の一次元配列、`array2`は長さ4でサイズ5の一次元配列で割り付けられる。

`array3`のように、割付け時に全要素の値を初期化したい場合には`source`タグを使用する。`source`タグを使用した場合には、与えたリテラルや文字列変数の長さがそのまま暗黙的に配列要素の文字列の長さとなる。

`allocate`文を実行する前に、既に長さが決まっている文字列変数と同じ長さの文字列配列を割付けたい場合には`mold`タグを使う：

```fortran
block
   integer :: i
   character(5) :: f ! 長さ5の固定長
   character(:), allocatable, dimension(:) :: array4
   f = 'abcde'
   allocate(array4(3), mold=f)

   do i = 1, size(array4)
      print *, len(array4(i))   ! 5が3回出力される
   end do
end block
```

なお、`source`や`mold`タグを`allocate`文に使いたい場合、型名と`::`を使った文はコンパイルエラーとなる。つまり次のコードはコンパイルできない：

```fortran
allocate(character(5) :: array4(3), source='abcd') ! コンパイルエラー
```

これは`source`指定子もしくは`mold`指定子を指定した場合には、型指定子（この場合の`character(4)`）があってはならないという文法上の制約に違反するためである[^1]。

割付けを解除するときは、通常の組込みの`allocatable`配列と同じように`deallocate`文を書く。

```fortran
deallocate(array1)
deallocate(array2, array3)
```

### 文字列配列の使い方

文字列の配列は、基本的に数値型や論理値型の配列と同じように扱うことができる。

```fortran
block
   character(4) :: array(3)
   integer :: i
   
   array(1) = 'hoge'             ! 配列変数名と添え字を与えて要素にアクセスする
   array(2:3) = ['fuga', 'piyo'] ! 部分配列も使える
   
   do i = 1, size(array, dim=1)
      print *, array(i) ! hogeとfugaとpiyoがそれぞれ1行に標準出力される
   end do
end block
```

注意するべきは、部分配列とその各要素の部分文字列を使いたい場合である。このとき、配列変数名と配列要素の添字を書いた直後に部分文字列の範囲を指定する必要がある。

```fortran
block
   character(4) :: array(3)
   integer :: i
   
   array(:) = ['hoge', 'fuga', 'piyo']
   
   ! 第2要素の値'fuga'より、2から3文字目の部分文字列'ug'を取り出したい場合
   print *, array(2)(2:3)   ! ug
   
   ! 'hoge'の'og'と'fuga'のugを取り出したい場合
   print *, array(1:2)(2:3) ! ogug
end block
```

上のコードで示した通り、配列添字を範囲で指定してその部分文字列を指定することで、複数の要素からその部分文字列を取り出すことができる[^2]。

Fortranでは、部分配列の参照と部分文字列の参照には、丸括弧とコロンを使った同様の形式（例えば`(1:3)`のような書き方）で記述する。そのため、文字列型配列の部分配列の部分文字列の参照を行う場合には、配列の添字と部分文字列の範囲指定の書き方を間違えないように注意しなければならない。筆者の個人的な意見では、配列添字の範囲と部分文字列の範囲を続けて書くやり方は特に混乱しやすいので、パフォーマンスへの影響などの特段の理由がない限り、本稿後半の派生型のアプローチを使うことを推奨する。

### 文字列配列の制約

ここまで、文字列型の配列をどのように扱うかについて述べてきた。前述の通り、Fortranの文字列型で許可されているのは固定長文字列の配列のみである。

しかし「要素ごとに長さの異なる文字列のリスト」を作りたいという要請は実際にプログラムを書いている場面では無きにしも非ずである。このような、例えば`array = ['alpha', 'beta', 'gamma', 'epsilon']`のようなリストは、他のプログラミング言語で散見されるが、Fortranの文字列型の配列では実現できない。すなわち組込み型では実現できないわけであるが、しかし、派生型を使うアプローチによりこれを疑似的に実現することが可能だ。これはFortran 2003以降において可変長文字列が導入されて、さらにそれを成分に持つ派生型を定義でき、Fortranでは派生型の配列の取扱うことができるためである。この機能を使って、可変長文字列の配列の疑似的な作り方を次のセクションで見ていこう。

## 派生型でラップするアプローチ

このセクションでは、派生型と可変長の文字列型成分を使って派生型の配列を作る方法について述べる。

### 派生型の定義と派生型の配列

まず最初に、可変長文字列を含む派生型（ここでは`str_t`とする）を定義する。派生型`str_t`は、**成分** (component) として可変長文字列`s`のみを含む。

```fortran
! 派生型の定義
type :: str_t
   character(:), allocatable :: s
end type str_t
```

派生型の宣言では、`type()`で型指定を行う。この時、通常の組込み型の配列宣言と同じ方法で派生型の配列を宣言することができる。

```fortran
type(str_t) :: s_array(8)　! str_t派生型の配列s_arrayを宣言
```

派生型の成分には、パーセント記号`%`を使ってアクセスするので、各要素の成分`s`への代入は次のように行う。

```fortran
s_array(1)%s = 'alpha'
s_array(2)%s = 'bravo'
s_array(3)%s = 'charlie'
s_array(4)%s = 'delta'
s_array(5)%s = 'foxtrot'
s_array(6)%s = 'golf'
s_array(7)%s = 'hotel'
s_array(8)%s = 'india'
```

各要素の成分の値を使う場面においても、代入時と同様に`%`を使ってアクセスする。

```fortran
block
   integer :: i
   do i = 1, size(s_array)
      print *, 'i = ', i, ': len = ', len(s_array(i)%s), ': ', s_array(i)%s
   end do
end block
```

このコードを実行して得られる出力は次の通り：

```
 i =            1 : len =            5 : alpha
 i =            2 : len =            5 : bravo
 i =            3 : len =            7 : charlie
 i =            4 : len =            5 : delta
 i =            5 : len =            7 : foxtrot
 i =            6 : len =            4 : golf
 i =            7 : len =            5 : hotel
 i =            8 : len =            5 : india
```

以上で、派生型の配列を使うことにより**各要素が可変長の文字列を持つ配列**を実現することができた。

### 派生型による可変長文字列配列を使う際のポイント

上で定義した派生型の成分は`allocatable`属性を持つので、それに由来する注意点がいくつか存在する。

#### 未割付成分の参照を避ける

まず、未割付け成分への参照を避けて安全に処理するためには、分岐処理を書くことが望ましい。ここでは、`allocated`関数を用いて成分`s`が割付済みか判定するために、次のような`if`文を置いて条件判定の処理を追加する。

```fortran
program main
implicit none

type :: str_t
   character(:), allocatable :: s
end type str_t

type(str_t) :: s_array(8)

assignment: block
   s_array(1)%s = 'alpha'
   s_array(2)%s = 'bravo'
   s_array(3)%s = 'charlie'
   s_array(4)%s = 'delta'
   ! s_array(5)%s = 'foxtrot' ! 第5要素には代入しない
   s_array(6)%s = 'golf'
   s_array(7)%s = 'hotel'
   s_array(8)%s = 'india'
end block assignment

printing: block
   integer :: i

   do i = 1, size(s_array, dim=1)
      if (allocated(s_array(i)%s)) then
         print *, 'i = ', i, ': len = ', len(s_array(i)%s), ': ', s_array(i)%s
      else
         print *, 'i = ', i, ':        unallocated :'
      end if
   end do
end block printing
end program main
```

このコードを実行すると以下のような出力を得られるだろう：

```
 i =            1 : len =            5 : alpha
 i =            2 : len =            5 : bravo
 i =            3 : len =            7 : charlie
 i =            4 : len =            5 : delta
 i =            5 :        unallocated :
 i =            6 : len =            4 : golf
 i =            7 : len =            5 : hotel
 i =            8 : len =            5 : india
```

#### 配列代入と`allocate`属性

次に、配列要素を範囲指定しての`allocatable`な成分への代入は、その成分を左辺に指定して行うことは基本的にできない。

これと同等のことを手軽にやりたい場合には派生型コンストラクタ (derived type constructor) [^3]を使う必要がある。派生型コンストラクタの使い方は、代入文の左辺に目的の派生型変数またはその配列を置き、右辺に派生型名を関数のように記述して、引数に生成したい派生型オブジェクトの成分に代入したい値を与える。

```fortran
program main
implicit none

type :: str_t
   character(:), allocatable :: s
end type str_t
type(str_t) :: s_array(8)

dt_construct: block
   integer :: i
   ! s_array(1:4)%s = 'aaa'  ! この書き方はコンパイルエラー

   ! 派生型コンストラクタによる代入をするには、派生型名に引数を与えて右辺に書く
   s_array(1:4) = str_t('aaa')
   s_array(5:8) = str_t('bbbb')
   do i = 1, size(s_array, dim=1)
      print *, len(s_array(i)%s), s_array(i)%s
   end do
end block dt_construct
end program main
```

以上のコードにおいて、`dt_construct`ブロック内の代入文では、`s_array`の第1要素から第4要素までの各成分`s`に文字列値`aaa`を、第5要素から第8要素のそれらに値`bbbb`を、それぞれ代入している。

### 多次元配列

派生型の配列においても、組込み型と同様に多次元配列を構成することができる

```fortran
block
   type(str_t) :: two_dim(3, 3)
   integer :: i, j

   two_dim(:,1) = str_t('aaa')
      ! 配列代入によりtwo_dim(1:3,1)のすべての要素にstr_t('aaa')が代入される

   two_dim(:,2) = str_t('bbb')
   two_dim(:,3) = [str_t('ccc'), str_t('ddd'), str_t('eee')]
      ! 派生型コンストラクタを使った配列構成子

   do j = 1, size(two_dim, dim=2)
      do i = 1, size(two_dim, dim=1)
         print *, i, j, ': ', two_dim(i,j)%s
      end do
   end do
end block
```

ここでは次のような出力を得る：

```
           1           1 : aaa
           2           1 : aaa
           3           1 : aaa
           1           2 : bbb
           2           2 : bbb
           3           2 : bbb
           1           3 : ccc
           2           3 : ddd
           3           3 : eee
```

## まとめ

ここまで、固定長の文字列型配列と、派生型による模擬的な可変長文字列配列の構築と使い方について簡単に述べた。現在のFortranプログラミング環境では、古典的な固定長配列のみならず、派生型を活用した文字列の処理で便利な使い方ができることを示したかったので、それが伝わっていれば、本稿の目的は達成されたと言える。

本連載では、Fortranの言語機能として利用可能な文字列処理について「あまり知られてはいないが実はリッチな側面」の情報を積極的に提供していきたい。次回の第3回は文字種別と型パラメータについて扱う予定である。

なお、本稿で用いたコードはWindows環境において`gfortran` (GCC 15.1.0) と`ifx` (Intel Fortran Compiler v2024.0.2)を用いて動作確認をした。

## 補遺

前回の記事において、文字列変数の部分文字列を取得する例については記していたが、一方で部分文字列への代入—つまり文字列変数の部分的な更新—をする方法については述べていなかった。Fortranでは、これを行うことができるのでやり方を紹介しておこう。

文字列の部分的な更新を行うには次のようなコードを書く：

```fortran
block
   character(5) :: str

   str = 'abcde'
   print *, str     ! abcde
   
   str(1:1) = 'A'   ! 左辺に更新したい部分を置き、右辺に値を置く
   print *, str     ! Abcde
   
   str(2:4) = 'ZZZ' ! 2文字目から4文字目を ZZZに更新する
   print *, str     ! AZZZe
   
   str(3:4) = 'YYY' ! 左辺で指定した範囲より右辺が長い場合は、切り詰められる
   print *, str     ! AZYYe

   str(3:4) = 'Y'   ! 左辺で指定した範囲より右辺が短い場合は、空白で埋められる
   print *, str     ! AZY e
end block
```

コード中のコメントで示しているように、指定した部分文字列の範囲と右辺の長さが一致しない場合の挙動に注意する必要がある。左辺の指定範囲長よりも、右辺が長い場合には余った文字は切り捨てられ、短い場合にはホワイトスペースで埋められる。[^4]

## 参考文献

1. Michael Metcalf and John Reid 著, 西村恕彦・和田英穂・西村和夫・高田正之 訳,"bit別冊 詳解 Fortran90", 共立出版株式会社, 1993, ISBN: 
2. Michael Metcalf, John Reid, Malcolm Cohen, "Modern Fortran explained: Incorporating Fortran 2018", Oxford University Press, 2018, https://doi.org/10.1093/oso/9780198811893.001.0001, ISBN: 9780198811886
3. J.C. Adams, W.S. Brainerd, J.T. Martin, B.T. Smith, J.L. Wagener, "Fortran 95 Handbook Complete ISO/ANSI Reference", MIT Press, 1997, ISBN: 978026251096

[^1]: 参考文献2の第15.4節 "Typed and sourced allocation", pp. 297-299を参照した。
[^2]: 参考文献3の第6.2節 "Substrings"を参照した。
[^3]: 規格では派生型のオブジェクトを構造体 (structure)と呼び、これを構造体構成子 (structure constructor)と呼ぶらしい。以前は`derived type`の和訳語は「構造型」を使っていたようだ（参考文献1のpp. 26-27を参照）。
[^4]: 詳細は参考文献2の第3.7節 "Scalar character expressions and assignments"を参照のこと。