defmodule Expng.ImageData do
  alias __MODULE__

  defstruct rows: "",
            bit_depth: 8,
            filter_type: 0

  def init(),
    do: %ImageData{}

  def rows(chunk, rows),
    do: %{chunk | rows: rows}

  def bit_depth(chunk, bit_depth),
    do: %{chunk | bit_depth: bit_depth}

  def filter_type(chunk, filter_type),
    do: %{chunk | filter_type: filter_type}

  def to_binary(%ImageData{} = chunk) do
    %ImageData{
      rows: rows,
      bit_depth: bit_depth,
      filter_type: filter_type
    } = chunk

    filter_rows(rows, bit_depth, filter_type)
    |> Enum.reduce(<<>>, &concat_bitstrings/2)
    |> compress()
  end

  defp filter_rows(rows, bit_depth, filter_type) when is_list(filter_type) do
    Enum.map(List.zip([rows, filter_type]), fn {row, filter} ->
      filter(row, bit_depth, filter)
    end)
  end

  defp filter_rows(rows, bit_depth, filter_type) do
    Enum.map(rows, fn row ->
      filter(row, bit_depth, filter_type)
    end)
  end

  defp compress(binary_data) do
    zlib_sock = :zlib.open()
    :zlib.deflateInit(zlib_sock)
    compressed_data = :zlib.deflate(zlib_sock, binary_data, :finish)
    :zlib.deflateEnd(zlib_sock)
    :zlib.close(zlib_sock)
    :erlang.list_to_binary(compressed_data)
  end

  defp filter(row, bit_depth, :none) do
    filtered_row =
      Enum.flat_map(row, fn tuple ->
        Tuple.to_list(tuple) |> Enum.map(&<<&1::size(bit_depth)-big>>)
      end)
      |> Enum.reduce(<<>>, &concat_bitstrings/2)

    # If not in byte boundary - pad the bitstring
    # This occurrs when bit_depth is less than 8 bits
    difference = byte_size(filtered_row) * 8 - bit_size(filtered_row)

    <<0::8-big, filtered_row::bitstring, 0::size(difference)-big>>
  end

  defp concat_bitstrings(b1, b2) do
    <<b2::bitstring, b1::bitstring>>
  end
end
