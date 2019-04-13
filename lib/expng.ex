defprotocol Expng.Data do
  @fallback_to_any true
  def prepare(data)
end

defimpl Expng.Data, for: Any do
  def prepare(_), do: <<>>
end

defmodule Expng do
  alias Expng, as: Image

  @signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  defstruct width: nil,
            height: nil,
            color_mode: nil,
            rows: [],
            chunk_size: 0,
            filter_type: 0,
            path: nil

  def image(width, height),
    do: %Image{width: width, height: height}

  def color_mode(image, color_mode),
    do: %{image | color_mode: color_mode}

  def row(%Image{rows: data} = image, row),
    do: %{image | rows: [row | data]}

  def rows(%Image{rows: data} = image, rows),
    do: %{image | rows: Enum.reduce(rows, data, &[&1 | &2])}

  def chunk_size(image, :none),
    do: %{image | chunk_size: 0}

  def chunk_size(image, chunk_size),
    do: %{image | chunk_size: chunk_size}

  def filter(image, filter_type),
    do: %{image | filter_type: filter_type}

  def save(image, path),
    do: create(%{image | path: path})

  def create(image) do
    alias Expng.Chunk.Header
    alias Expng.Chunk.Data
    alias Expng.ImageData

    %Image{
      width: width,
      height: height,
      color_mode: {_type, bit_depth} = color_mode,
      rows: rows,
      chunk_size: chunk_size,
      path: path
    } = image

    header_chunk =
      Header.init()
      |> Header.size(width, height)
      |> Header.color_mode(color_mode)

    data_chunks =
      ImageData.init()
      |> ImageData.rows(Enum.reverse(rows))
      |> ImageData.bit_depth(bit_depth)
      |> ImageData.filter_type(:none)
      |> ImageData.to_binary()
      |> Data.init(chunk_size)
      |> Data.split()

    chunks = [header_chunk | data_chunks]

    data = Enum.map_join(chunks, &(Expng.Chunk.create_chunk(&1) |> Expng.Chunk.to_binary()))
    end_chunk = Expng.Chunk.create_chunk("") |> Expng.Chunk.to_binary()

    File.write(path, <<@signature, data::binary, end_chunk::binary>>)
  end
end

width = 200
height = 200
image_row = fn i -> 1..width |> Enum.map(&{&1, i * 100, 0, i}) end

image_data =
  for i <- 1..height do
    image_row.(i)
  end

IO.inspect(image_data)

Expng.image(width, height)
|> Expng.chunk_size(:none)
|> Expng.color_mode({:color_alpha, 16})
|> Expng.rows(image_data)
|> Expng.save("test.png")
