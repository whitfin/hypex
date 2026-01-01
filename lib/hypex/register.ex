defmodule Hypex.Register do
  @moduledoc """
  This module defines the behaviour required by all internal Hypex registers.

  There are no requirements for the underlying storage of a register, only that
  it conforms to this behaviour and provides a correct implementation.
  """

  @typedoc """
  Register implementations currently available in the core of the Hypex library.
  """
  @opaque t :: __MODULE__.Array.t() | __MODULE__.Bitstring.t() | __MODULE__.List.t() | any()

  @doc """
  Initialize an empty register of a given width.

  The `width` parameter supplied here will have been pre-validated by the main
  `Hypex` interface. Calls to `init/1` should always return a fresh register.
  """
  @callback init(width :: number()) :: register :: Register.t()

  @doc """
  Retrieve a specific bit from a register.
  """
  @callback get(register :: Register.t(), index :: number(), width :: number()) ::
              result :: number()

  @doc """
  Set a specific bit in a register.
  """
  @callback put(register :: Register.t(), index :: number(), width :: number(), value :: number()) ::
              register :: Register.t()

  @doc """
  Merge together two registers of the same width and type.
  """
  @callback merge(left :: Register.t(), right :: Register.t()) :: Register.t()

  @doc """
  Run a reduction over the inner bits of a register.
  """
  @callback reduce(register :: Register.t(), width :: number(), acc :: any(), (number, any -> any)) ::
              acc :: any
end
