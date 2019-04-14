defmodule ExpngTest.Chunk.Header do
  use ExUnit.Case, async: true
  doctest Expng.Chunk.Header

  alias Expng.Chunk.Header

  setup _header_context do
    {:ok,
     [
       header:
         {:ok,
          %Header{
            width: :invalid,
            height: :invalid,
            bit_depth: :invalid,
            color_type: :invalid
          }},
       valid_header:
         {:ok,
          %Header{
            width: 100,
            height: 100
          }}
     ]}
  end

  test "correct default values in Header structure" do
    assert {:ok,
            %Header{
              bit_depth: depth,
              color_type: color,
              compression_type: 0,
              filter_method: 0,
              interlace_method: interlace
            }} = Header.create()

    assert interlace in [0, 1]
    assert depth in [1, 2, 4, 8, 16]
    assert color in [0, 2, 3, 4, 6]
  end

  test "errors are propagated", header_context do
    assert {:error, _} = header_context[:header] |> Header.color_mode(:term) |> Header.size(1, 1)
    assert {:error, _} = header_context[:header] |> Header.size(-1, 1) |> Header.color_mode(:term)

    assert {:error, _} =
             header_context[:header]
             |> Header.size(-1, 1)
             |> Header.color_mode(:term)
             |> Header.to_binary()
  end

  test "has implemented Expng.Data protocol", header_context do
    assert Expng.Data.prepare(header_context[:valid_header])
  end

  test "converts Header structure to binary format", header_context do
    with {:ok, binary} <- header_context[:valid_header] |> Header.to_binary() do
      assert binary |> is_bitstring()
    end
  end

  test "binary Header has correct order" do
    header = %Header{
      width: 16_843_009,
      height: 16_843_009,
      bit_depth: 8,
      color_type: 2,
      compression_type: 0,
      filter_method: 0,
      interlace_method: 1
    }

    with {:ok, binary} <- header |> Header.to_binary() do
      <<
        width::32-big,
        height::32-big,
        bit_depth::8-big,
        color_type::8-big,
        compression_type::8-big,
        filter_method::8-big,
        interlace_method::8-big
      >> = binary

      # This value is equal to <<1, 1, 1, 1>> which is the same in big and little endian
      assert width === 16_843_009
      assert height === 16_843_009
      assert bit_depth === 8
      assert color_type === 2
      assert compression_type === 0
      assert filter_method === 0
      assert interlace_method === 1
    end
  end

  test "width is saved in big endian", header_context do
    {:ok, <<width::32-big, _::bitstring>>} = header_context[:valid_header] |> Header.to_binary()
    assert width === 100
  end

  test "height is saved in big endian", header_context do
    {:ok, <<_::32-big, height::32-big, _::bitstring>>} =
      header_context[:valid_header] |> Header.to_binary()

    assert height === 100
  end
end
