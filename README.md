# Hypex
[![Build Status](https://img.shields.io/github/actions/workflow/status/whitfin/hypex/ci.yml?branch=main)](https://github.com/whitfin/hypex/actions) [![Coverage Status](https://img.shields.io/coveralls/whitfin/hypex.svg)](https://coveralls.io/github/whitfin/hypex) [![Hex.pm Version](https://img.shields.io/hexpm/v/hypex.svg)](https://hex.pm/packages/hypex) [![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://hexdocs.pm/hypex/)

Hypex is a fast HyperLogLog implementation in Elixir which provides an easy way to count unique values with a small memory footprint. This library is based on [the paper documenting the algorithm](http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf) written by Philippe Flajolet et al.

## Installation

Hypex is available on [Hex](https://hex.pm/). You can install the package via:

```elixir
def deps do
  [{ :hypex, "~> 2.0" }]
end
```

## Usage

Hypex is extremely straightforward to use, you simply create a new Hypex instance and start adding values to it:

```elixir
iex> hypex = Hypex.new(4)
{:hypex, Hypex.Register.Array, 4, {:array, 16, 0, 0, 100}}
iex> hypex = Hypex.update(hypex, "my term")
{:hypex, Hypex.Register.Array, 4,
 {:array, 16, 0, 0,
  {10, {0, 2, 0, 0, 0, 0, 0, 0, 0, 0}, 10, 10, 10, 10, 10, 10, 10, 10, 10}}}
iex> Hypex.cardinality(hypex)
1.0326163382011386
```

The `4` being passed to `Hypex.new/1` is the width which determines the underlying memory structure of a Hypex instance. This value can be within the range `4 <= width <= 16`, per the HyperLogLog algorithm. If you don't provide a width, it defaults to `8`. Be aware that you should typically scale this number higher based upon the more unique values you expect to see.

You can control the underlying storage register via the second parameter of `Hypex.new/2`. This defaults to an `:array` implementation, but Hypex includes a few different implementations based on your use case. Please see the documentation to view the registers available in your current version of `Hypex`.

For any other examples of how to use Hypex, please read [the documentation](https://hexdocs.pm/hypex/).

## Memory Optimization

As of `v1.1.0`, the default implementation has moved from a Bitstring to an Erlang Array. This is mainly due to Arrays performing faster on all operations when compared with Bitstrings. However in the case that you're operating in a low-memory environment (or simply want predictable memory usage), you might still wish to use the Bitstring implementation. You can do this by simply using `Hypex.new(4, Bitstring)` when creating a Hypex.

A rough memory estimate (in bytes) for a Bitstring Hypex can be calculated using the formula `((2 ^ width) * width) / 8` - although this will only include the memory of the registers and not the rest of the tuple structure (which should be minimal). This means that using the highest width available of `16`, your memory usage will still only be `131,072` bytes.

At this point I don't know of a good way to measure the size of the Array implementation, but a rough estimate would suggest that it's probably within the range of 6-8 times more memory (if anyone can help measure, I'd appreciate it). Still, this amount of memory shouldn't pose an issue for most systems, and the throughput likely matters more to most users.

## Rough Benchmarks

Below are some rough benchmarks for the different Hypex registers. Any tests with updates will be inserting a unique value; a duplicate value is significantly faster due to skipping modifications. These tests use a width of 8, and it should be noted that the width heavily impacts these numbers. The smallest widths (4) are measured in `ns` rather than `μs`, whereas the largest widths (16) are typically in the millisecond range for cardinality calculations.

```
## Hypex (Array)

Array Hypex.new/1               0.09 μs/op
Array Hypex.update/2            0.35 μs/op
Array Hypex.cardinality/1       4.56 μs/op
Array Hypex.merge/2             9.09 μs/op

## Hypex (Bitstring)

Bitstring Hypex.new/1           0.17 μs/op
Bitstring Hypex.update/2        0.31 μs/op
Bitstring Hypex.cardinality/1   8.47 μs/op
Bitstring Hypex.merge/2         9.09 μs/op

## Hypex (List)

List Hypex.new/1                0.74 μs/op
List Hypex.update/2             1.13 μs/op
List Hypex.cardinality/1        3.16 μs/op
List Hypex.merge/2              5.53 μs/op
```

In most cases it won't matter which register you choose, so it's a good idea to start with the default until you see some reason to change. If you would like some very rough guidance, here are some simple rules:

* If you're using low `width` values, use `Hypex.Register.List`
* If you're trying to minimize memory, use `Hypex.Register.Bitstring`
* For anything else, use `Hypex.Register.Array` (the current default)

These guidelines are based on Elixir 1.19; it's possible that they display different characteristics on earlier Elixir/OTP versions. Make sure to measure inside your application using your real traffic and data!

## Contributions

If you feel something can be improved, or have any questions about certain behaviours or pieces of implementation, please feel free to file an issue. Proposed changes should be taken to issues before any PRs to avoid wasting time on code which might not be merged upstream.

If you *do* make changes to the codebase, please make sure you test your changes thoroughly, and include any unit tests alongside new or changed behaviours. Hypex currently uses the excellent [excoveralls](https://github.com/parroty/excoveralls) to track code coverage.

```elixir
$ mix test
$ mix coveralls
$ mix coveralls.html && open cover/excoveralls.html
