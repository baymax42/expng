defmodule Expng.Chunk.Data do
  alias __MODULE__

  defstruct chunk_size: 0,
            raw_data: ""

  defimpl Expng.Data, for: Data do
    def prepare(%Data{raw_data: raw_data}),
      do: raw_data
  end

  def init(raw_data, chunk_size),
    do: %Data{raw_data: raw_data, chunk_size: chunk_size}

  def split(%Data{chunk_size: 0} = chunk),
    do: [chunk]

  def split(%Data{raw_data: raw_data, chunk_size: chunk_size}),
    do: fragment_data(raw_data, chunk_size)

  defp fragment_data(image_data, chunk_size),
    do: fragment_data(image_data, chunk_size, [])

  defp fragment_data(<<>>, _chunk_size, chunks),
    do: Enum.reverse(chunks)

  defp fragment_data(image_data, chunk_size, chunks) when chunk_size > byte_size(image_data),
    do: fragment_data(<<>>, chunk_size, [init(image_data, 0) | chunks])

  defp fragment_data(image_data, chunk_size, chunks) do
    <<chunk::bytes-size(chunk_size)-big, data::bitstring>> = image_data
    fragment_data(data, chunk_size, [init(chunk, 0) | chunks])
  end
end
