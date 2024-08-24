---
title: Forgex v3.4 Released
date: 2024-08-25
author: Amasaki Shinobu
description: Fortran Regular Expression version 3.4 have been released.
---

# Forgex v3.4: Literal Search Optimizations

Author: Amasaki Shinobu（雨崎しのぶ）

Twitter: [@amasaki203](https://x.com/amasaki203)

Posted on: 2024-08-25 JST

## Abstract

[Forgex—Fortran Regular Expression—version 3.4](https://github.com/ShinobuAmasaki/forgex/releases/tag/v3.4) with literal search optimizations and a CLI tool is available. 

## Details

Referring to [my previous article](./dream-of-pure-regex.html), here is an introduction to the features of the version 3.4 of Forgex.

### API changes

The `.in.` and `.match.` operators remain functional, and have been extended to work on arrays.
From version 3.0, the `regex` procedure has been changed from a function to a subroutine.
If you want to get a string as the return value, use the `regex_f` function.
For detailed usage information, [see the README in the repository](https://github.com/ShinobuAmasaki/forgex).
The next section describes the two operators with pure element attributes.

### Operators with Pure Elemental attribute

A dream that I discussed in the previous article—to provide `pure` API procedures—has come true in v3.0.
From version 3.0 onward, Forgex provides API operators with `pure elemental` attributes, and users can use them on array operations and in `do concurrent` blocks and OpenMP parallel blocks.
While I could have parallelized the internal processing of Forgex to achieve faster text processing, I chose instead to provide a robust, easy-to-use API that, although not particularly fast, is primarily aimed at assisting with numerical calculations which is the main interest of Fortran users. 

Below is an example of using the `.in.` operator in an array operation:

```fortran
block
   integer, parameter :: siz = 5
   character(:), allocatable :: pattern
   character(8) :: text_array(siz)
   logical :: result_array(siz)
   
   pattern = "(^a)|(.*a\s*$)"
   ! This pattern matches character a at the beginning or the trailing.

   text_array = ["alpha   ", "bravo   ", "charlie ", "delta   ", "echo    "]
   result_array(1:siz) = pattern .in. text_array(1:siz)
   
   print *, result_array    ! T F F T F
end block
```

The internal implementation of Forgex uses one-dimensional arrays of derived types to represent an abstract syntax tree (AST), non-deterministic finite automaton (NFA), and deterministic finite automaton (DFA).
Child nodes of AST, as well as states and transitional destinations of NFA and DFA, are managed as indices of arrays.
This approach helps Forgex achieve fast processing because arrays in Fortran are fast and feature-rich, unlike graph implementations using pointers.
However, this comes at the expense of some memory efficiency.

The previous pointer-based implementation has been revamped, and most of the source code has been replaced with new code.
During this process, the principles of object-oriented programming are introduced.
Each node in the tree and automata is defined as a derived type, and to represent AST, NFA, and DFA, further derived types are defined containing arrays of these types.
Using type-bound procedures reduces the number of arguments needed when calling procedures, resulting in more concise code description.
Additionally, this implementation helps avoid using global variables, which cannot be utilized in procedures with the `pure` attribute, by substituting component variables of derived types.

Note: the version 1.4 feature of remembering the DFA of previous patterns has been removed, as it was incompatible with the `pure` attribute of operators.

### Literal Search Optimization

The previous article also discussed literal search optimization as a next step in this project.
This feature has been implemented in the version 3.3, and it performs more efficiently than brute-force matching for certain regex patterns and input text strings. 
For instance, consider checking whether the regex pattern `ab[^x]d` is contained in the input text `cdefghabcde`.
This matches `abcd` from the 7th to 10th characters.
In previous versions, the algorithm was naive and inefficient, trying to match from the 1st character and, if that failed, moving on to the 2nd character, and so on.
Literal search optimization first extracts the prefix `ab` and the suffix `d` from the AST of the regex pattern, then uses the `index` intrinsic function to locate the prefix.
The `index` function is much faster than the regex engine, so it skips the first 6 characters, `cdefgh`, which do not need to be checked, and starts the engine directly from the 7th character.
This reduces unnecessary comparisons and enables more efficient processing.

Currently, one prefix and one suffix are extracted as literal strings, excluding character classes and closures.
For alternations, the intersection of the literal is extracted.
Literal extraction can be extended to small character classes, but this involves a trade-off between the overhead of extraction and the additional time spent on searching, on the one hand, and time saved by skipping, on the other hand.
Therefore, I'm currently wondering if this should be implemented. 

### Command-line Tool

Although not mentioned in the previous article, since version 3.1 the development process has required additional tools.
Starting with version 3.2 a command line tool was introduced that can be used to test and benchmark Forgex.
This application uses both Forgex's internal modules and APIs to provide step-by-step information on how the AST, NFA and DFA are generated from the pattern, along with approximate execution time and memory consumption.

For example, to perform the matching discussed in the previous section, run the following command:

```shell
forgex-cli find match lazy-dfa "ab[^x]d" .in. "cdefghabcde"
```

Or if you execute it from `fpm run`, run the following command:

```shell
fpm run forgex-cli --profile release -- find match lazy-dfa "ab[^x]d" .in. "cdefghabcde"
```

These will give you the following output:

<div class="none-highlight-user">

```
             pattern: ab[^x]d
                text: 'cdefghabcde'
          parse time:        61.8μs
extract literal time:        28.2μs
         runs engine:         T
    compile nfa time:        18.7μs
 dfa initialize time:         1.6μs
         search time:       191.3μs
     matching result:         T
  memory (estimated):      5943

========== Thompson NFA ===========
state    1: (a, 5)
state    2: <Accepted>
state    3: (d, 2)
state    4: ([<SPACE>-"`"], 3)(a, 3)(b, 3)(c, 3)(d, 3)(["e"-"w"], 3)(["y"-<U+1FFFFF>], 3)
state    5: (b, 4)
=============== DFA ===============
   1 : a=>2
   2 : b=>3
   3 : c=>4
   4 : d=>5
   5A:
state    1  = ( 1 )
state    2  = ( 5 )
state    3  = ( 4 )
state    4  = ( 3 )
state    5A = ( 2 )
===================================
```

</div>

If you want to get information about the AST, run the following command:

```shell
forgex-cli debug ast  "ab[^x]d"    
```

And then, you will get output similar to the following.

<div class="none-highlight-user">

```
        parse time:        51.1μs 
      extract time:        19.7μs
 extracted literal:
  extracted prefix: ab
  extracted suffix: d
memory (estimated):       827
(concatenate (concatenate (concatenate "a" "b") [ " "-"w"; "y"-"<U+1FFFFF>;]) "d")
```

</div>

From the result, we can see that in this example, `ab` is extracted as the prefix and `d` is extracted as the suffix.
[See the documentation for more information on how to use this command.](https://shinobuamasaki.github.io/forgex)

### Bugfix

Versions prior to v3.3 did not handle position matching carets and dollars very well.
I fixed the handling of these by improving the `forgex_api_internal_m` module.
This fix allows the caret and dollar signs to be matched correctly even when they are surrounded by parentheses, such as in the example above: `(^a)|(.*a\s*$)`.
The relevant test cases have been added in `test/test_api/test_case_007.f90`. 

### To Do 

I aim to add features in the future for the following:

- Implement advanced Unicode features.
- Handle invalid characters in UTF-8.

## Conclusion

This article covered new features, the `pure` attribute, a command line tool, optimization and a bug fix since Forgex version 3. With this upgrade, Forgex has made minimal changes to the API and significant changes to the internal implementation to add functionality and improve processing speed, and also provided tools to verify this. Not much is decided about the future of this project, but in the short term I will be focusing on improving the documentation and adding test cases.

## Acknowledgements

The command line interface design for this application was inspired by [the Rust language's `regex-cli`](https://github.com/rust-lang/regex/tree/master/regex-cli).

## References

1. [Dream of PURE Regex - Amasaki Shinobu](./dream-of-pure-regex.html), Jul. 2024
2. [rust-lang/regex/regex-cli](https://github.com/rust-lang/regex/tree/master/regex-cli) 
