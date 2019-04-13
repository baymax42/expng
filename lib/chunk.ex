alias Expng.Chunk

defmodule Expng.Chunk do
  alias __MODULE__
  defstruct [:type, :data]

  def create_chunk(%Chunk.Data{} = data) do
    %Chunk{
      type: "IDAT",
      data: data
    }
  end

  def create_chunk(%Chunk.Header{} = header) do
    %Chunk{
      type: "IHDR",
      data: header
    }
  end

  def create_chunk(a) do
    %Chunk{
      type: "IEND",
      data: a
    }
  end

  def to_binary(%Chunk{type: type, data: data}) do
    data = Expng.Data.prepare(data)
    binary_data = <<type::binary, data::binary>>

    <<byte_size(data)::32-big, binary_data::binary, :erlang.crc32(binary_data)::32-big>>
  end
end
