---
title: Dream of PURE Forgex
date: 2024-07-26
author: Amasaki Shinobu
description: With the next Forgex release, what I want to do.
---

# Dream of `PURE` Regex

Author: Amasaki Shinobu (雨崎しのぶ)

Twitter: @amasaki203

Posted on: 2024-07-26 JST

## Abstract

In the next major release of Fortran Regular Expression, I hope to provide `pure` operators and a `pure` procedure. 

## Details

One of my personal projects I have been working on recently is Forgex—Fortran Regular Expression. [The latest version of this is version 2.0](https://github.com/ShinobuAmasaki/forgex/releases/tag/v2.0), which is still under development, and it has implemented Lazy DFA and released documentation. In this version, the regular expression engine is driven by modern Fortran features, especially modules, object-oriented programming, and pointers. For implementation inside the engine, regular expressions are parsed using module variables of derived-types, and matching is achieved by constructing equivalent an abstract syntax tree (AST), an non-deterministic finite automaton (NFA), and a deterministic finite automaton (DFA).

For the next version of the project, one of the goals to be achieved is to support parallelization. Naively, there are two possible approaches (although I'm not sure if the former is actually possible):

- parallelizing of automaton construction,
- parallelizing on matching.

The former is a challenge to parallelize the process of constructing an NFA from an AST and a DFA from an NFA. I don't know if this is even possible, theoretically. If any readers have any information, please let me know.

The latter is simpler than this. The `.in.` operator and `regex` procedure shift the text string to be matched from the beginning to the right by one character at a time and try to match, so in theory it can be parallelized by the length of the string. However, this cannot be applied to the `.match.`operator. Also, it should be noted that the upper limit of parallelization will be reduced when the optimization by literal search [1], which is planned to be incorporated in the future, is implemented. 

I initially considered these above approaches, but after reassessing the assumptions that users would benefit from parallelization, I realized that parallelization did not need to be achieved within the library. The `.in.`, `.match.` and `regex` procedures provided by the library depend only on two arguments, a pattern and text string, and their results are determined without side effects. In Fortran, procedures that have the properties of pure function can be written as procedures with the `pure` attribute. These can be used in `do concurrent` constructs, and the compiler can partially optimize this code block. In other words, by implementing thread-safe procedures, users will be able to address parallelization by themselves.

Therefore, the goal of Forgex version 3 is to rewrite the code, give all procedures the `pure` attribute, and provide `pure` `.in.` and `.match.` operators, and `regex` subroutines (which are `function` as of v2.0). To achieve this, the following will be added:

- Remove pointers and module variables from the implementation of AST, NFA and DFA.
- Implement the construction and processing of these using arrays of derived-types with index management.
- Allow reverse transition in DFA for **literal search optimization** [1, 2] which I intend to implement in a later version.

Finally, almost all of the source code will be rewritten, but since Forgex v2.0 is only about 3000 lines at most, I don't expect it to be too difficult. As of July 24, about 80% of the new AST construction has already been written, so if all goes well, I should be able to release version 3 within this year. 

## Conclusion

Here's what I'm working on for the next version of Forgex:

- Provide `pure` operators (`.in.` and `.match.`) and subroutine (`regex`).
- Remove pointers and module variables, implement arrays of derived-types.
- Leave room for extension to implement literal search optimization.

## References

1. [*Regex literals optimization* - Nitely's Thoughts ](https://nitely.github.io/2020/11/30/regex-literals-optimization.html), Esteban C. Borsani, 2020.
2. [*Regex engine internals as a library* - Andrew Gallant's Blog ](https://blog.burntsushi.net/regex-internals/), Andrew Gallant, 2023