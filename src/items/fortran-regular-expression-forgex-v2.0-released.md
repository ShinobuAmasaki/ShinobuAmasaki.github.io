---
title: Forgex v2.0 Released
date: 2024-07-10
author: Amasaki Shinobu
description: Fortran Regular Expresion (Forgex) v2.0 have been released.
---

# Fortran Regular Expression: Forgex v2.0 Released

Author: Amasaki Shinobu (雨崎しのぶ)

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2024-07-10 JST

## Abstract

[Forgex v2.0 with Lazy DFA is available.](https://github.com/ShinobuAmasaki/forgex/releases/tag/v2.0)

## Details

I have released version 2.0 of Forgex (short for Fortran Regular Expression), and [it is now available on GitHub.](https://github.com/ShinobuAmasaki/forgex) 

Starting with this version, I have adopted a lazy-evaluated deterministic finite automaton (Lazy DFA) approach for subset construction, which has reduced the consumption of time and memory resources compared to using previous statically compiled DFA.

As a minor fix, I have added the `forgex_` prefix to the names of all internal modules. This prevents module name collisions when introducing Forgex into a new project. The API module name `forgex` and the APIs of `.in.` and `.match.` operators, and `regex` function will remain unchanged.

Thank you.

------

## To Do

Here are some of the things I am considering for the future of this project:

- improving documentation of the internal implementation for developers (*top priority*),
- optimizing with a literal search method,
- supporting escape sequences for Unicode,
- Parallelizing matching.

## Memo

*The following are just my own thoughts and notes, so I cannot guarantee their accuracy.*

### Documentation

​	I am trying to decide where to place and how to build the documentation for my Fortran project. Should I put it in the main repository or create a separate repository for the documentation? Should I use FORD or Sphinx? FORD is very easy to use as it automatically generates the reference documentation, but I am considering Sphinx because of the wide selection of visual themes and good typesetting.

### Regex Literals Optimization

​	The regex literals optimization is a method which avoids executing the regex engine on parts of the input character string that cannot possibly match the regex pattern (cf. [5]). I need to think in advance about which part of the engine this feature should be implemented in. Since I want to avoid changing the syntax tree construction as much as possible, would it be better to implement this naively in a relatively shallow layer, in a module close to the users and API?

### Parallelization

​	The thread parallelization of regex engines can be discussed in two parts: DFA construction and matching. Parallelizing DFA construction will undoubtedly be difficult. Care must be taken to avoid race conditions. On the other hand, parallelizing matching is more realistic, and is possible if I prepare as many pointer variables as there are threads, with the upper limit being the number of starting points for matching. In other words, the `.in.` operator and the `regex` function can be parallelized, but the `.match.` operator cannot.

​	The above discussion pertains to **static** DFA construction. However, in Lazy DFA, it will be necessary to balance both of these, that is, to avoid race conditions during matching and execute DFA construction in parallel. At this point, I don't know whether this is possible or not, so I need to learn by reading computer science papers and studying other implementations of regex engines.

Nonetheless, even if I were to implement it to this extent, it is unclear whether I could expect  any significant from parallelization.

### Miscellaneous

- I would like to implement escape sequences for Unicode, adopting a notation that is widely used in other engines. But which one should I use?
- I would like to have more effective testing methods and a sufficient number of test cases.]

------

## References

1. [Article for version 1.0 release (including usage details)](./new-light-on-fortran-string-processing-forgex-1st-release.html)

2. [Article for version 1.0 release in Japanese](https://qiita.com/amasaki203/items/9382f05f7c3efafea7a9)

3. [Forgex Repository on GitHub](https://github.com/ShinobuAmasaki/forgex)

4. [Discussions on Fortran-lang Discourse](https://fortran-lang.discourse.group/t/new-release-of-forgex-fortran-regular-expression/8325)

5. [*Regex literals optimization* - Nitely's Thoughts by Esteban Castro Borsani](https://nitely.github.io/2020/11/30/regex-literals-optimization.html)

