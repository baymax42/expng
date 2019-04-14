defmodule Expng.Chunk.Header do
  alias __MODULE__

  defstruct width: nil,
            height: nil,
            bit_depth: 8,
            color_type: 0,
            compression_type: 0,
            filter_method: 0,
            interlace_method: 0

  @typedoc """
  To be done
  """
  @type t :: %__MODULE__{
          width: nil,
          height: nil,
          bit_depth: 8,
          color_type: 0,
          compression_type: 0,
          filter_method: 0,
          interlace_method: 0
        }

  defimpl Expng.Data, for: Header do
    def prepare(chunk),
      do: Header.to_binary(chunk)
  end

  @typedoc """
  Either a tuple with correct Header structure or error with a message.
  """
  @type header_or_error :: {:ok, Expng.Chunk.Header.t()} | {:error, any()}
  @doc """
  Checks is passed value is correct grayscale bit depth.
  PNG specification states that for grayscale color types
  correct values are: 1, 2, 4, 8, 16

  ## Examples

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(1)
      true

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(2)
      true

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(4)
      true

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(8)
      true

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(16)
      true

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(-1)
      false

      iex> Expng.Chunk.Header.is_valid_grayscale_depth(:atom)
      false

  """
  defguard is_valid_grayscale_depth(bit_depth)
           when bit_depth in [1, 2, 4, 8, 16]

  @doc """
  Checks is passed value is correct color bit depth.
  PNG specification states that for RGB color types
  correct values are: 8, 16

  ## Examples

      iex> Expng.Chunk.Header.is_valid_color_depth(8)
      true

      iex> Expng.Chunk.Header.is_valid_color_depth(16)
      true

      iex> Expng.Chunk.Header.is_valid_color_depth(-1)
      false

      iex> Expng.Chunk.Header.is_valid_color_depth(:atom)
      false

      iex> Expng.Chunk.Header.is_valid_color_depth(1)
      false

      iex> Expng.Chunk.Header.is_valid_color_depth(2)
      false

      iex> Expng.Chunk.Header.is_valid_color_depth(4)
      false

  """
  defguard is_valid_color_depth(bit_depth)
           when bit_depth in [8, 16]

  @doc """
  Checks is passed value is correct palette bit depth.
  PNG specification states that for indexed (palette) color types
  correct values are: 1, 2, 4, 8

  ## Examples

      iex> Expng.Chunk.Header.is_valid_indexed_depth(1)
      true

      iex> Expng.Chunk.Header.is_valid_indexed_depth(2)
      true

      iex> Expng.Chunk.Header.is_valid_indexed_depth(4)
      true

      iex> Expng.Chunk.Header.is_valid_indexed_depth(8)
      true

      iex> Expng.Chunk.Header.is_valid_indexed_depth(16)
      false

      iex> Expng.Chunk.Header.is_valid_indexed_depth(-1)
      false

      iex> Expng.Chunk.Header.is_valid_indexed_depth(:atom)
      false

  """
  defguard is_valid_indexed_depth(bit_depth)
           when bit_depth in [1, 2, 4, 8]

  @doc """
  Checks is passed value is correct grayscale or color with alpha channel bit depth.
  PNG specification states that for color types with alpha channel
  correct values are: 8, 16

  ## Examples

      iex> Expng.Chunk.Header.is_valid_alpha_depth(8)
      true

      iex> Expng.Chunk.Header.is_valid_alpha_depth(16)
      true

      iex> Expng.Chunk.Header.is_valid_alpha_depth(-1)
      false

      iex> Expng.Chunk.Header.is_valid_alpha_depth(:atom)
      false

      iex> Expng.Chunk.Header.is_valid_alpha_depth(1)
      false

      iex> Expng.Chunk.Header.is_valid_alpha_depth(2)
      false

      iex> Expng.Chunk.Header.is_valid_alpha_depth(4)
      false

  """
  defguard is_valid_alpha_depth(bit_depth)
           when bit_depth in [8, 16]

  @doc """
  Creates a Header structure. It returns, a tuple with second value being the structure.
  It is used as an entry point for building the structure.

  ## Examples

    iex> Expng.Chunk.Header.create()
    {:ok, %Expng.Chunk.Header{}}

  """
  @spec create() :: header_or_error()
  def create(),
    do: {:ok, %Header{}}

  @doc """
  Assings width and height fields in passed Header structure.
  Width and height should be non negative integers.

  ## Examples

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.size(100, 100)
    {:ok, %Expng.Chunk.Header{width: 100, height: 100}}

  Passing wrong values will return error tuple:

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.size(-1, 100)
    {:error, "invalid image size"}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.size(100, :atom)
    {:error, "invalid image size"}
  """
  @spec size(header_or_error(), non_neg_integer(), non_neg_integer()) :: header_or_error()
  def size(header_tuple, width, height)
      when is_integer(width) and is_integer(height) and width >= 0 and height >= 0 do
    with {:ok, header} <- header_tuple,
         do: {:ok, %{header | width: width, height: height}}
  end

  def size(_header, _width, _height),
    do: {:error, "invalid image size"}

  @doc """
  Assings color type and bit depth fields in passed Header structure.
  It validates  given combination of color type and bit depth.

  Color mode argument should be a tuple consisting of color type atom and bit depth.
  Supported color modes are:
    {:grayscale, 1 | 2 | 4 | 8 | 16}
    {:grayscale_alpha, 8 | 16}
    {:color, 8 | 16}
    {:color_alpha, 8 | 16}
    {:indexed, 1 | 2 | 4 | 8}

  ## Examples

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:grayscale, 1})
    {:ok, %Expng.Chunk.Header{color_type: 0, bit_depth: 1}}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:grayscale_alpha, 8})
    {:ok, %Expng.Chunk.Header{color_type: 4, bit_depth: 8}}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:color, 16})
    {:ok, %Expng.Chunk.Header{color_type: 2, bit_depth: 16}}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:color_alpha, 8})
    {:ok, %Expng.Chunk.Header{color_type: 6, bit_depth: 8}}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:indexed, 4})
    {:ok, %Expng.Chunk.Header{color_type: 3, bit_depth: 4}}

  Passing wrong values will return error tuple:

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:grayscale, -1})
    {:error, "invalid color mode"}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode({:color, 2})
    {:error, "invalid color mode"}

    iex> Expng.Chunk.Header.create() |> Expng.Chunk.Header.color_mode(:atom)
    {:error, "invalid color mode"}
  """
  @spec color_mode(header_or_error(), tuple()) :: header_or_error()
  def color_mode(header_tuple, color_mode) do
    with {:ok, header} <- header_tuple do
      case color_mode do
        {:grayscale, bit_depth} when is_valid_grayscale_depth(bit_depth) ->
          {:ok, %{header | color_type: 0, bit_depth: bit_depth}}

        {:grayscale_alpha, bit_depth} when is_valid_alpha_depth(bit_depth) ->
          {:ok, %{header | color_type: 4, bit_depth: bit_depth}}

        {:color, bit_depth} when is_valid_color_depth(bit_depth) ->
          {:ok, %{header | color_type: 2, bit_depth: bit_depth}}

        {:color_alpha, bit_depth} when is_valid_alpha_depth(bit_depth) ->
          {:ok, %{header | color_type: 6, bit_depth: bit_depth}}

        {:indexed, bit_depth} when is_valid_indexed_depth(bit_depth) ->
          {:ok, %{header | color_type: 3, bit_depth: bit_depth}}

        _ ->
          {:error, "invalid color mode"}
      end
    end
  end

  @doc """
  Converts Header structure to its binary representation as defined in PNG specification.
  Header chunk fields should have order and sizes like stated below:
    width: 4 bytes,
    height 4 bytes,
    bit_depth 1 bytes,
    color_type 1 byte,
    compression_type 1 byte,
    filter_method 1 byte,
    interlace_method 1 byte

  ## Examples

  Create binary header for grayscale image with size 100x100 and bit depth equal to 1:

    iex>Expng.Chunk.Header.create() |> Expng.Chunk.Header.size(100, 100) |> Expng.Chunk.Header.color_mode({:grayscale, 1}) |> Expng.Chunk.Header.to_binary()
    {:ok, <<0, 0, 0, 100, 0, 0, 0, 100, 1, 0, 0, 0, 0>>}

  Error at any time when constructing the Header will be passed to the end:

    iex>Expng.Chunk.Header.create() |> Expng.Chunk.Header.size(-1, 100) |> Expng.Chunk.Header.color_mode({:grayscale, 1}) |> Expng.Chunk.Header.to_binary()
    {:error, "invalid image size"}

    iex>Expng.Chunk.Header.create() |> Expng.Chunk.Header.size(100, 100) |> Expng.Chunk.Header.color_mode({:atom, 1}) |> Expng.Chunk.Header.to_binary()
    {:error, "invalid color mode"}
  """
  @spec to_binary(header_or_error()) :: {:ok, <<_::104>>} | {:error, any()}
  def to_binary(header_tuple) do
    with {:ok, header} <- header_tuple do
      %Header{
        width: width,
        height: height,
        bit_depth: bit_depth,
        color_type: color_type,
        compression_type: compression_type,
        filter_method: filter_method,
        interlace_method: interlace_method
      } = header

      {:ok,
       <<
         width::32-big,
         height::32-big,
         bit_depth::8-big,
         color_type::8-big,
         compression_type::8-big,
         filter_method::8-big,
         interlace_method::8-big
       >>}
    end
  end
end
