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

  def size(header, width, height),
    do: %{header | width: width, height: height}

  def color_mode(header, mode) do
    case mode do
      {:grayscale, bit_depth} when is_valid_grayscale_depth(bit_depth) ->
        %{header | color_type: 0, bit_depth: bit_depth}

      {:grayscale_alpha, bit_depth} when is_valid_alpha_depth(bit_depth) ->
        %{header | color_type: 4, bit_depth: bit_depth}

      {:color, bit_depth} when is_valid_color_depth(bit_depth) ->
        %{header | color_type: 2, bit_depth: bit_depth}

      {:color_alpha, bit_depth} when is_valid_alpha_depth(bit_depth) ->
        %{header | color_type: 6, bit_depth: bit_depth}

      {:indexed, bit_depth} when is_valid_indexed_depth(bit_depth) ->
        %{header | color_type: 3, bit_depth: bit_depth}

      _ ->
        {:error, "invalid color mode"}
    end
  end

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
