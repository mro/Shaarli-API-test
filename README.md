# pinboard.in.cgi

The natural API for shaarli.

## Why?

The wish to have an API goes back to the [early
days](https://sebsauvage.net/wiki/doku.php?id=php:shaarli:ideas).

And because shaarli started as a personal, minimal, delicious clone, using a
minimal subset of just that very API seems natural to me.
[pinboard.in](https://pinboard.in/api/) prooves the API is not only seasoned and
mature, but also still up the job today.

Also another project of mine, [ShaarliOS](/mro/ShaarliOS/) needs a drop-in API
compatibility layer for a wide range of shaarlis out in the wild.

## How?

You find a single, statically linked, zero-dependencies ([🐫
Ocaml](https://ocaml.org/)) binary which is both a

1. cgi to drop into your shaarli php webapplication next to index.php – as the API
   endpoint,
2. commandline client to any shaarli out there, mostly for debugging and
   compatibility-testing purposes.

![post flow](post.png)

## Compatibility

All shaarlis from the old ages until spring 2020
([v0.11.1](https://github.com/shaarli/Shaarli/releases/tag/v0.11.1)).

All systems [🐫 Ocaml](https://ocaml.org/) can produce binaries for.

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

