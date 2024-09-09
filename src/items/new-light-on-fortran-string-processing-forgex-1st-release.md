---
title: "New Light on Fortran String Processing: Forgex 1st Release"
date: 2023-12-25
language: en
link: https://shinobuamasaki.github.io/items/new-light-on-fortran-string-processing-forgex-1st-release.html
author: Amasaki Shinobu
description: An article about Fortran Reguler Expression (Forgex).
---
# New Light on Fortran String Processing: Forgex 1st Release

Author: Amasaki Shinobu (雨崎しのぶ)

Twitter: [@amasaki203](https://twitter.com/amasaki203)

Posted on: 2023-12-25 JST
Updated on: 2023-12-27 JST

## Abstract

[I've developed a new project called 'Forgex', an abbreviation for 'Fortran Regular Expression', and its first release took place on December 24th.](https://github.com/ShinobuAmasaki/forgex)

Forgex is a regular expression engine written entirely in Fortran. It is a library module that is executable with just a Fortran compiler, devoid of dependencies other than a compiler and Fortran Package Manager (FPM). This library is freely available under the MIT license.

## About Forgex

Forgex is a library module designed for processing regular expressions (pronounced as 'forge x' by me).

The distinctive features implemented in this library include: 

- UTF-8 code set support
- Operator-oriented API
- FPM and CMake support

### Regular Expression Processing Implemented

This section lists the regular expression patterns that are implemented in Forgex.

#### Metacharacters

- `|`: Alternation
- `*`: Match zero or more
- `+`: Match one or more
- `?`: Match zero or one
- `\`: Escape a metacharacter
- `.`: Match any character

#### Character Classes

- `[a-z]`: Character classes
- `[^a-z]`: Inverted character classes

Both character classes and their invertion support UTF-8 character sets, e. g. `[α-ωぁ-ん]`

#### Anchor

- `^`: Match at the beginning of the line
- `$`: Match at the end of the line

#### Repetition

- `{2}`: number of repetitions
- `{,3}`: maximum number of repetitions
- `{5,}`: minimum number of repetitions
- `{7, 11}`: both minimum and maximum numbers of repetitions

#### Shorthand with Backslash

- `\t`: TAB
- `\n`: Line Feed (LF) or Carriage return (CR) and LF
- `\r`: CR
- `\s`: A blank character (white space, TAB, LF, CR, Form Feed, Idepgraphic Space U+3000)
- `\S`: Other than `\s`
- `\w`: `[a-zA-Z0-9_]`
- `\W`: Other than `\w`
- `\d`: `[0-9]`
- `\D`:  Other than`\d`（therefore `[^0-9]`）

## Usage

### Build

Operation has been confirmed with the following compilers:

- GNU Fortran (`gfortran`) v13.2.1
- Intel Fortran Compiler (`ifx`) 2024.0.0 20231017

To build this, the use of FPM is assumed. An alternative option is CMake.

#### Building with FPM

Add the following to your project's `fpm.toml`:

```toml
[dependencies]
forgex = {git = "https://github.com/shinobuamasaki/forgex"}
```

#### (Alternative) Building with CMake

Forgex also supports building with CMake. 

```shell
% wget https://github.com/ShinobuAmasaki/forgex/archive/refs/tags/v1.0.tar.gz   # download forgex

% tar xvzf ./v1.0.tar.gz    # decompress

% cd ./forgex-1.0           # change directory

% cmake -S . -B ./build     # make 'build' directory 

% cmake --build ./build     # build

% sudo cmake --install ./build --prefix /usr/local    # install

% cd ./build
% ctest       # test
```

While it is possible to build using CMake, I recommend the more straightforward approach using FPM.

### APIs

Declaring `use forgex` at the top of your program introduces the `.in.` and `.match.` operators and the `regex` function. Below we will look at how to use each of these three. 

#### The `.in.` operator

The `.in.` operator returns true if the pattern (left operand) is contained in the string (right operand).

```fortran
block
   character(:), allocatable :: pattern, str

   pattern = 'foo(bar|baz)'
   str = "foobarbaz"
   print *, pattern .in. str  ! T

   str = "foofoo"
   print *, pattern .in. str  ! F
end block
```

#### The `.match.` operator

The `.match.` operator returns true if the pattern and the string match exactly. 

```fortran
block
   character(:), allocatable :: pattern, str

   pattern = '\d{3}-\d{4}'
   str = '100-0001'
   print *, pattern .match. str  ! T

   str = '1234567'
   print *, pattern .match. str  ! F
end block
```

#### The `regex` function

The `regex` function takes a pattern and string as arguments and returns the matched substring. The substring is the leftmost and longmost match in the string.

```fortran
block
   character(:), allocatable :: pattern, str
   
   pattern = '[a-z]{3}'
   str = 'foobarbaz'

   print *, regex(pattern, str)  ! foo
end block
```

As an option, you can also pass an integer-type arugment `length` that will stores the byte length of the substring.

```fortran
block
   character(:), allocatable :: pattern, str
   integer :: length
   
   pattern = '[a-z]{3}'
   str = 'foobarbaz'

   print *, regex(pattern, str, length)  ! foo
   print *, length               ! 3
end block
```

The interface of the `regex` function is as follows:

```fortran
function regex (pattern, str, length) result(res)
   character(*), intent(in) :: pattern, str
   integer, intent(inout), optional :: length
   character(:), allocatable :: res
```

### UTF-8 String Processing

UTF-8 string can be matched using regular expression patterns just like ASCII strings. The following example demonstrates matching Chinese characters. In this example, the variable `length` stores the byte length, and in this case there 10 3-byte characters, so the length is 30.

```fortran
block
   character(:), allocatable :: pattern, str
   integer :: length
   
   pattern = "夢.{3,7}胡蝶"
   str = "昔者莊周夢爲胡蝶　栩栩然胡蝶也"
   
   print *, pattern .in. str            ! T
   print *, regex(pattern, str, length) ! 夢爲胡蝶　栩栩然胡蝶
   print *, length                      ! 30 (is 3-byte * 10 characters)
   
end block
```

## Internal Implementation

In the implementation of regular expression engines, there are broadly two approaches: using Deterministic Finite Automaton (DFA) and constructing a virtual machine. In Forgex, I have adopted the former approach based on DFA. 

Due to this choice, the following features will NOT be implemented:

- Backreference
- Recursive patterns

Additionally, at the current stage, an on-the-fly DFA construction algorithm has not been implemented, thereby failing to address the issue of state number explosion. Consequently, patterns like `[a-z]{20}b` fall into the category of challenging cases. 

## Conclusion

While challenges such as addressing state explosion, optimization, and incorporating parallel processing remain, I have opted for the current release as the essential features are now in place.

With the release of this library, I hope for an improvement in the convenience of your Fortran string processing.

## Acknowlegements

For the algorithm of the power set construction method and syntax analysis, I referred to Russ Cox's article and Kondo Yoshiyuki's book.

The implementation of the priority queue was based on [the code written by ue1221](https://github.com/ue1221/fortran-utilities).

The idea of applying the .in. operator to strings was inspired by kazulagi's one.

## References

1. Russ Cox ["Regular Expression Matching Can Be Simple And Fast"](https://swtch.com/~rsc/regexp/regexp1.html), 2007 
2.  近藤嘉雪 (Kondo Yoshiyuki), "定本 Cプログラマのためのアルゴリズムとデータ構造", 1998, SB Creative.
3. [ue1221/fortran-utilities](https://github.com/ue1221/fortran-utilities)
4. Haruka Tomobe (kazulagi), [https://github.com/kazulagi](https://github.com/kazulagi), [his article in Japanese](https://qiita.com/soybean/items/7cdd2156a9d8843c0d91)

