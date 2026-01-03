require "test_helper"

class Base62ConverterTest < ActiveSupport::TestCase
  test ".encode should correctly encode a number" do
    assert_equal "0", Base62Converter.encode(0)
    assert_equal "1", Base62Converter.encode(1)
    assert_equal "a", Base62Converter.encode(10)
    assert_equal "z", Base62Converter.encode(35)
    assert_equal "A", Base62Converter.encode(36)
    assert_equal "Z", Base62Converter.encode(61)
    assert_equal "10", Base62Converter.encode(62)
    assert_equal "11", Base62Converter.encode(63)
    assert_equal "g8", Base62Converter.encode(1000)
  end

  test ".decode should correctly decode a string" do
    assert_equal 0, Base62Converter.decode("0")
    assert_equal 1, Base62Converter.decode("1")
    assert_equal 10, Base62Converter.decode("a")
    assert_equal 35, Base62Converter.decode("z")
    assert_equal 36, Base62Converter.decode("A")
    assert_equal 61, Base62Converter.decode("Z")
    assert_equal 62, Base62Converter.decode("10")
    assert_equal 63, Base62Converter.decode("11")
    assert_equal 1000, Base62Converter.decode("g8")
  end

  test ".decode should raise an error for invalid characters" do
    assert_raises ArgumentError do
      Base62Converter.decode("!")
    end
  end

  test "encode and decode should be reversible" do
    (0..1000).each do |i|
      encoded = Base62Converter.encode(i)
      decoded = Base62Converter.decode(encoded)
      assert_equal i, decoded
    end
  end
end
