# Hypex
[![Build Status](https://img.shields.io/travis/zackehh/hypex.svg)](https://travis-ci.org/zackehh/hypex) [![Coverage Status](https://img.shields.io/coveralls/zackehh/hypex.svg)](https://coveralls.io/github/zackehh/hypex) [![Hex.pm Version](https://img.shields.io/hexpm/v/hypex.svg)](https://hex.pm/packages/hypex) [![Documentation](https://img.shields.io/badge/docs-latest-yellowgreen.svg)](https://hexdocs.pm/hypex/)

Hypex is a fast HyperLogLog implementation in Elixir which provides an easy way to count unique values with a small memory footprint. This library is based on [the paper documenting the algorithm](http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf) written by Philippe Flajolet et al.

## Installation

Hypex is available on [Hex](https://hex.pm/). You can install the package via:

  1. Add hypex to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{ :hypex, "~> 1.0.0" }]
    end
    ```

  2. Ensure hypex is started before your application:

    ```elixir
    def application do
      [applications: [:hypex]]
    end
    ```

## Usage

Hypex is extremely straightforward to use, you simply create a new Hypex instance and start adding values to it:

```elixir
iex> hypex = Hypex.new(4)
{Hypex.Array, 4, {:array, 16, 0, 0, 100}}
iex> hypex = Hypex.update(hypex, "my term")
{Hypex.Array, 4,
 {:array, 16, 0, 0,
  {10, {0, 2, 0, 0, 0, 0, 0, 0, 0, 0}, 10, 10, 10, 10, 10, 10, 10, 10, 10}}}
iex> hypex |> Hypex.cardinality |> round
1
```

The `4` being passed to `Hypex.new/1` is the width which determines the underlying memory structure of a Hypex instance. This value can be within the range `4 <= width <= 16`, per the HyperLogLog algorithm. If you don't provide a width, it defaults to `16`. Be aware that you should typically scale this number higher based upon the more unique values you expect to see.

For any other examples of how to use Hypex, please read [the documentation](https://hexdocs.pm/hypex/).

## Memory Optimization

As of `v1.1.0`, the default implementation has moved from a Bitstring to an Erlang Array. This is mainly due to Arrays performing faster on all operations when compared with Bitstrings. However in the case that you're operating in a low-memory environment (or simply want predictable memory usage), you might still wish to use the Bitstring implementation. You can do this by simply using `Hypex.new(4, Bitstring)` when creating a Hypex.

A rough memory estimate (in bytes) for a Bitstring Hypex can be calculated using the formula `((2 ^ width) * width) / 8` - although this will only include the memory of the registers and not the rest of the tuple structure (which should be minimal). This means that using the highest width available of `16`, your memory usage will still only be `131,072` bytes.

At this point I don't know of a good way to measure the size of the Array implementation, but a rough estimate would suggest that it's probably within the range of 6-8 times more memory (if anyone can help measure, I'd appreciate it). Still, this amount of memory shouldn't pose an issue for most systems, and the throughput likely matters more to most users.

## Rough Benchmarks

Below are some rough benchmarks for Hypex instances with the different underlying structures. Note that the `update/2` tests are inserting a unique value - in the case a duplicate value is inserted, the operation is typically constant across widths at under `0.5 µs/op`.

These tests use a maximum width (16), so it should be noted that smaller widths will have better performance. However, these benchmarks are for reference only and you should gauge which widths work best for the data you're operating with, rather than the performance shown below.

```
## Array Hypex

Array Hypex.new/1                0.38 µs/op
Array Hypex.update/2             1.59 µs/op
Array Hypex.cardinality/1        11,470.53 µs/op
Array Hypex.merge/2              34,329.02 µs/op

## Bitstring Hypex

Bitstring Hypex.new/1            77.78 µs/op
Bitstring Hypex.update/2         10.32 µs/op
Bitstring Hypex.cardinality/1    12,643.60 µs/op
Bitstring Hypex.merge/2          67,265.52 µs/op
```

## Contributions

If you feel something can be improved, or have any questions about certain behaviours or pieces of implementation, please feel free to file an issue. Proposed changes should be taken to issues before any PRs to avoid wasting time on code which might not be merged upstream.

If you *do* make changes to the codebase, please make sure you test your changes thoroughly, and include any unit tests alongside new or changed behaviours. Hypex currently uses the excellent [excoveralls](https://github.com/parroty/excoveralls) to track code coverage.

```elixir
$ mix test
$ mix coveralls
$ mix coveralls.html && open cover/excoveralls.html
