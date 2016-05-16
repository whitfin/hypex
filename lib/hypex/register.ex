defmodule Hypex.Register do
  @moduledoc """
  This module defines the behaviour required by all internal Hypex register
  structures.

  Assuming all of the function callbacks defined in this module are implemented
  correctly, it should be possible to use as an implementation inside a Hypex.
  This makes it possible to provide custom implementations of the underlying
  register without having to modify the actual source of Hypex.
  """

  @doc """
  Invoked to initialize a set of registers.

  `width` is the desired width of the registers and should be used to determine
  how large the register set should be. Calls to `init/1` should always return
  a new register set.
  """
  @callback init(width :: number) :: register :: Register.t

  @doc """
  Invoked after operating on registers on a bit level.

  This function will receive a list of bits as created by the `to_list/1` callback.
  The result of calling this should return a register set in the same form as when
  first being initialized.
  """
  @callback from_list([ bit :: number ]) :: register :: Register.t

  @doc """
  Invoked when operating on registers on a bit level.

  This function should operate in tandem with `from_list/1` to convert between
  a register set and a list of bits.
  """
  @callback to_list(register :: Register.t) :: [ bit :: number ]

  @doc """
  Invoked to retrieve a specific bit register.

  `idx` refers to the head of the hashes value, and `width` refers to the width
  of the register. The `get_value/3` callback should use these values when finding
  the required register.
  """
  @callback get_value(register :: Register.t, idx :: number, width :: number) :: result :: number

  @doc """
  Invoked to set a bit register with a given value.

  Similar to the `get_value/3` callback, we supply `idx` and `width` to allow the
  callback to determine where the value should be written.
  """
  @callback set_value(register :: Register.t, idx :: number, width :: number, value :: number) :: register :: Register.t

  @doc """
  Invoked when there's a need to iterate/accumulate a register.
  """
  @callback reduce(register :: Register.t, width :: number, acc :: any, (number, any -> any)) :: acc :: any

  @typedoc """
  Register implementations currently available
  """
  @opaque t :: :array.array(number) | bitstring

end
