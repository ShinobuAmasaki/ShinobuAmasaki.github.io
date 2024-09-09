---
title: Dream of PURE Regex [EN]
date: 2024-07-26
language: en
link: https://shinobuamasaki.github.io/items/dream-of-pure-regex.html
author: Amasaki Shinobu
description: With the next Forgex release, what I want to do.
---

# Dream of `PURE` Regex

Author: Amasaki Shinobu (雨崎しのぶ)

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2024-07-26 JST

## Abstract

In the next major release of Fortran Regular Expression library, I aim to provide `pure` operators and a `pure` procedure. 

## Details

One of my recent personal projects is Forgex—Fortran Regular Expression. [The latest version, version 2.0](https://github.com/ShinobuAmasaki/forgex/releases/tag/v2.0), is still under development. It has implemented Lazy DFA and released its documentation. In this version, the regular expression engine utilizes modern Fortran features, particularly modules, object-oriented programming, and pointers. Within the engine, regular expressions are parsed using module variables of derived-types, and matching is achieved by constructing an abstract syntax tree (AST), an equivalent non-deterministic finite automaton (NFA), and an equivalent deterministic finite automaton (DFA).

In the next version of the project, one of the goals is to support parallelization. There are two possible approaches to parallelize within the library (although I'm not sure if the first one is feasible):

- parallelizing the construction  of automata,
- parallelizing the matching process.

The first approach involves the challenge of parallelizing the process of constructing an NFA from an AST and a DFA from an NFA. I'm not sure if this is even theoretically possible. If any readers have information on this, please let me know ([feel free to contact me through GitHub issue page](https://github.com/ShinobuAmasaki/ShinobuAmasaki.github.io/issues)).

The second approach is simpler. The `.in.` operator and `regex` procedure shift the text string to be matched from the beginning to the right by one character at a time, trying to match, so in theory,  this process can be parallelized by the length of the string. However, this approach cannot be applied to the `.match.`operator. Additionally, the potential for parallelization will be limited when the optimization by literal search[1, 2], which is planned for future implementation, is incorporated.

I initially considered these approaches, but after reassessing the assumption that users would benefit from parallelization, I realized that parallelization did not need to be achieved within the library. The `.in.`, `.match.` and `regex` procedures provided by the library depend only on two arguments—a pattern and text string—and their results are determined without side effects. In Fortran, procedures that have the properties of pure functions can be written with the `pure` attribute. These can be used in `do concurrent` constructs, allowing the compiler to partially optimize the code block. In other words, by implementing thread-safe procedures, users will be able to handle parallelization themselves.

Therefore, the goal of Forgex version 3 is to rewrite the code, giving all procedures the `pure` attribute, and to provide `pure` `.in.` and `.match.` operators, as well as `pure subroutine regex` (which are `function` in v2.0). To achieve this, the following changes will be added:

- Remove pointers and module variables from the implementation of AST, NFA, and DFA.
- Implement the construction and processing of these using arrays of derived-types with index management.
- Allow reverse transitions in DFA for **literal search optimization** [1, 2] which I intend to implement in a later version.

Finally, almost all of the source code will be rewritten, but since Forgex v2.0 is only about 3000 lines, I don't expect it to be too difficult. As of July 24, about 80% of the new AST construction has been written, so if all goes well, I should be able to release version 3 within this year. 

## Conclusion

Here's what I'm planning for the next version of Forgex:

- Provide `pure` operators (`.in.` and `.match.`) and a subroutine (`regex`).
- Remove pointers and module variables, implement arrays of derived-types.
- Allow for future extensions to implement literal search optimization.

## References

1. [*Regex literals optimization* - Nitely's Thoughts ](https://nitely.github.io/2020/11/30/regex-literals-optimization.html), Esteban C. Borsani, 2020.
2. [*Regex engine internals as a library* - Andrew Gallant's Blog ](https://blog.burntsushi.net/regex-internals/), Andrew Gallant, 2023