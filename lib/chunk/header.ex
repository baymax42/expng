defmodule Expng.Chunk.Header do
  alias __MODULE__

  defstruct width: nil,
            height: nil,
            bit_depth: nil,
            color_type: nil,
            compression_type: 0,
            filter_method: 0,
            interlace_method: 0

  defimpl Expng.Data, for: Header do
    def prepare(chunk),
      do: Header.to_binary(chunk)
  end

  defguard is_valid_grayscale_depth(bit_depth)
           when bit_depth in [1, 2, 4, 8, 16]

  defguard is_valid_color_depth(bit_depth)
           when bit_depth in [8, 16]

  defguard is_valid_indexed_depth(bit_depth)
           when bit_depth in [1, 2, 4, 8]

  defguard is_valid_alpha_depth(bit_depth)
           when bit_depth in [8, 16]

  def init,
    do: %Header{}

  def size(header, width, height)
      when is_integer(width) and is_integer(height) and width >= 0 and height >= 0,
      do: %{header | width: width, height: height}

  def size({:error, _msg} = error, _width, _height),
    do: error

  def size(_header, _width, _height),
    do: {:error, "invalid image size"}

  def color_mode(header, {:grayscale, bit_depth})
      when is_valid_grayscale_depth(bit_depth),
      do: %{header | color_type: 0, bit_depth: bit_depth}

  def color_mode(header, {:grayscale_alpha, bit_depth})
      when is_valid_grayscale_depth(bit_depth),
      do: %{header | color_type: 4, bit_depth: bit_depth}

  def color_mode(header, {:color, bit_depth})
      when is_valid_grayscale_depth(bit_depth),
      do: %{header | color_type: 2, bit_depth: bit_depth}

  def color_mode(header, {:color_alpha, bit_depth})
      when is_valid_grayscale_depth(bit_depth),
      do: %{header | color_type: 6, bit_depth: bit_depth}

  def color_mode(header, {:indexed, bit_depth})
      when is_valid_grayscale_depth(bit_depth),
      do: %{header | color_type: 3, bit_depth: bit_depth}

  def color_mode({:error, _msg} = error, _),
    do: error

  def color_mode(_header, _),
    do: {:error, "invalid color mode"}

  def to_binary(header) do
    %Header{
      width: width,
      height: height,
      bit_depth: bit_depth,
      color_type: color_type,
      compression_type: compression_type,
      filter_method: filter_method,
      interlace_method: interlace_method
    } = header

    <<
      width::32-big,
      height::32-big,
      bit_depth::8-big,
      color_type::8-big,
      compression_type::8-big,
      filter_method::8-big,
      interlace_method::8-big
    >>
  end
end
