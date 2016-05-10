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
{ 4, << 0, 0, 0, 0, 0, 0, 0, 0 >> }
iex> hypex = Hypex.update(hypex, "my term")
{ 4, << 0, 0, 0, 0, 0, 3, 0, 0 >> }
iex> Hypex.cardinality(hypex) |> round
1
```

The `4` being passed to `Hypex.new/1` is the width which determines the underlying memory structure of a Hypex instance. This value can be within the range `4 <= width <= 16`, per the HyperLogLog algorithm. If you don't provide a width, it defaults to `16`. Be aware that you should typically scale this number higher based upon the more unique values you expect to see.

For any other examples of how to use Hypex, please read [the documentation](https://hexdocs.pm/hypex/).

## Memory Overhead

The current implementation is based around the use of a `bitstring` to store the registers, and as such the memory of a Hypex instance is constant. A rough memory estimate (in bytes) can be calculated using the formula `((2 ^ width) * width) / 8` - although this will only include the memory of the registers and not the rest of the tuple structure. This means that using the highest width available of `16`, your memory usage will still only be `131,072` bytes.

The cost for being so memory efficient is that some operations are (relatively) slow. I'm going to look at providing alternative implementations in future which trade memory for speed, so that there's an implementation for both use cases.

## Rough Benchmarks

Below are some rough benchmarks for Hypex instances with varying widths. These benchmarks are for reference only and you should gauge which widths work best for the data you're operating with, rather than the performance shown below. Note that the `update/2` tests are inserting a unique value - in the case a duplicate value is inserted, the operation is typically constant across widths at under `0.5 µs/op`.

```
## Hypex Benchmarks w/ width == 4

Hypex.new/1            0.12 µs/op
Hypex.update/2         0.71 µs/op
Hypex.cardinality/1    3.63 µs/op
Hypex.merge/2          5.19 µs/op

## Hypex Benchmarks w/ width == 8

Hypex.new/1            0.44 µs/op
Hypex.update/2         0.71 µs/op
Hypex.cardinality/1    51.63 µs/op
Hypex.merge/2          106.90 µs/op

## Hypex Benchmarks w/ width == 12

Hypex.new/1            3.99 µs/op
Hypex.update/2         5.88 µs/op
Hypex.cardinality/1    843.25 µs/op
Hypex.merge/2          2,973.71 µs/op

## Hypex Benchmarks w/ width == 16

Hypex.new/1            76.64 µs/op
Hypex.update/2         9.83 µs/op
Hypex.cardinality/1    12,718.94 µs/op
Hypex.merge/2          64,585.58 µs/op
```

## Contributions

If you feel something can be improved, or have any questions about certain behaviours or pieces of implementation, please feel free to file an issue. Proposed changes should be taken to issues before any PRs to avoid wasting time on code which might not be merged upstream.

If you *do* make changes to the codebase, please make sure you test your changes thoroughly, and include any unit tests alongside new or changed behaviours. Hypex currently uses the excellent [excoveralls](https://github.com/parroty/excoveralls) to track code coverage.

```elixir
$ mix test
$ mix coveralls
$ mix coveralls.html && open cover/excoveralls.html
