defmodule ExpngTest.Chunk.Header do
  use ExUnit.Case, async: true
  doctest Expng.Chunk.Header

  alias Expng.Chunk.Header

  setup _guard_context do
    {:ok,
     [
       grayscale_depth_input: [1, 2, 4, 8, 16],
       color_alpha_depth_input: [8, 16],
       palette_depth_input: [1, 2, 4, 8],
       invalid_depth_input: [-1, -2, 2.0, "abcd", 18, 21, nil, :term, %{}]
     ]}
  end

  setup _header_context do
    {:ok,
     [
       header: %Header{
         width: :invalid,
         height: :invalid,
         bit_depth: :invalid,
         color_type: :invalid
       },
       grayscale: {:grayscale, 8},
       color: {:color, 8},
       color_alpha: {:color_alpha, 8},
       grayscale_alpha: {:grayscale_alpha, 8},
       palette: {:indexed, 8},
       valid_header: %Header{
         width: 100,
         height: 100
       }
     ]}
  end

  test "validates grayscale depth", guard_context do
    validate_depth_guard(
      guard_context[:grayscale_depth_input],
      guard_context[:invalid_depth_input],
      &Header.is_valid_grayscale_depth/1
    )
  end

  test "validates color and alpha depth", guard_context do
    # Append specific incorrect values for this specific guard
    validate_depth_guard(
      guard_context[:color_alpha_depth_input],
      guard_context[:invalid_depth_input] ++ [1, 2, 4],
      &Header.is_valid_color_depth/1
    )

    validate_depth_guard(
      guard_context[:color_alpha_depth_input],
      guard_context[:invalid_depth_input] ++ [1, 2, 4],
      &Header.is_valid_alpha_depth/1
    )
  end

  test "validates palette depth", guard_context do
    # Append specific incorrect values for this specific guard
    validate_depth_guard(
      guard_context[:palette_depth_input],
      guard_context[:invalid_depth_input] ++ [16],
      &Header.is_valid_indexed_depth/1
    )
  end

  test "creates Header structure" do
    assert Header.init() == %Header{}
  end

  test "correct default values in Header structure" do
    assert %Header{
             bit_depth: depth,
             color_type: color,
             compression_type: 0,
             filter_method: 0,
             interlace_method: interlace
           } = Header.init()

    assert interlace in [0, 1]
    assert depth in [1, 2, 4, 8, 16]
    assert color in [0, 2, 3, 4, 6]
  end

  test "sets width and height", header_context do
    assert %Header{width: 1, height: 1} = header_context[:header] |> Header.size(1, 1)
  end

  test "sets color mode", header_context do
    assert %Header{color_type: 0, bit_depth: 8} =
             header_context[:header] |> Header.color_mode(header_context[:grayscale])

    assert %Header{color_type: 4, bit_depth: 8} =
             header_context[:header] |> Header.color_mode(header_context[:grayscale_alpha])

    assert %Header{color_type: 2, bit_depth: 8} =
             header_context[:header] |> Header.color_mode(header_context[:color])

    assert %Header{color_type: 6, bit_depth: 8} =
             header_context[:header] |> Header.color_mode(header_context[:color_alpha])

    assert %Header{color_type: 3, bit_depth: 8} =
             header_context[:header] |> Header.color_mode(header_context[:palette])
  end

  test "cannot set invalid image size", header_context do
    assert {:error, _} = header_context[:header] |> Header.size(1, :term)
    assert {:error, _} = header_context[:header] |> Header.size(-1, 100)
  end

  test "cannot set invalid color mode", header_context do
    assert {:error, _} = header_context[:header] |> Header.color_mode(:term)
    assert {:error, _} = header_context[:header] |> Header.color_mode({:indexed, -1})
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
    assert header_context[:valid_header] |> Header.to_binary() |> is_bitstring()
  end

  test "binary Header has correct order" do
    <<
      width::32-big,
      height::32-big,
      bit_depth::8-big,
      color_type::8-big,
      compression_type::8-big,
      filter_method::8-big,
      interlace_method::8-big
    >> =
      %Header{
        width: 16_843_009,
        height: 16_843_009,
        bit_depth: 8,
        color_type: 2,
        compression_type: 0,
        filter_method: 0,
        interlace_method: 1
      }
      |> Header.to_binary()

    # This value is equal to <<1, 1, 1, 1>> which is the same in big and little endian
    assert width === 16_843_009
    assert height === 16_843_009
    assert bit_depth === 8
    assert color_type === 2
    assert compression_type === 0
    assert filter_method === 0
    assert interlace_method === 1
  end

  test "width is saved in big endian", header_context do
    <<width::32-big, _::bitstring>> = header_context[:valid_header] |> Header.to_binary()
    assert width === 100
  end

  test "height is saved in big endian", header_context do
    <<_::32-big, height::32-big, _::bitstring>> =
      header_context[:valid_header] |> Header.to_binary()

    assert height === 100
  end

  test "cannot pass invalid Header structure to binary converter" do
    assert {:error, _} = %{width: 1, height: 2} |> Header.to_binary()
    assert {:error, _} = :term |> Header.to_binary()
  end

  defp validate_depth_guard(valid_input, invalid_depth_input, guard) do
    Enum.map(valid_input, fn val ->
      assert guard.(val)
    end)

    Enum.map(invalid_depth_input, fn val ->
      refute guard.(val)
    end)
  end
end
