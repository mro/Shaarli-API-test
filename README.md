# pinboard.in.cgi

The natural API for Shaarli.

## Why?

The wish to have an API goes back to the [early
days](https://sebsauvage.net/wiki/doku.php?id=php:shaarli:ideas).

And because Shaarli started as a personal, minimal, delicious clone, using a
minimal subset of just that very API seems natural to me.
[pinboard.in](https://pinboard.in/api/) prooves the API is not only seasoned and
mature, but also still up the job today.

Also another project of mine, [ShaarliOS](/mro/ShaarliOS/) could benefit from a
drop-in API compatibility layer for a wide range of Shaarlis out in the wild.

## How?

You find a single, statically linked, zero-dependencies ([OCaml
🐫](https://ocaml.org/)) binary which is both a

1. cgi to drop into your Shaarli php webapplication next to index.php – as the API
   endpoint,
2. commandline client to any Shaarli out there, mostly for debugging and
   compatibility-testing purposes.

![post flow](post.png)

## Compatibility

All Shaarlis from the old ages until spring 2020
([v0.11.1](https://github.com/shaarli/Shaarli/releases/tag/v0.11.1)).

All systems [OCaml 🐫](https://ocaml.org/) can produce binaries for.

Just the delicious API calls in
[pinboard.in/v1/openapi.yaml](pinboard.in/v1/openapi.yaml)

## Design Goals

| Quality         | very good | good | normal | irrelevant |
|-----------------|:---------:|:----:|:------:|:----------:|
| Functionality   |           |      |    ×   |            |
| Reliability     |     ×     |      |        |            |
| Usability       |           |   ×  |        |            |
| Efficiency      |           |      |    ×   |            |
| Changeability   |           |   ×  |        |            |
| Portability     |     ×     |      |        |            |

