class Base62Converter
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
  BASE = ALPHABET.length
  DECODE_MAP = ALPHABET.each_char.with_index.to_h.freeze

  # Encodes an integer into a Base62 string.
  # @param number [Integer] the integer to encode.
  # @return [String] the Base62 representation of the integer.
  def self.encode(number)
    return ALPHABET[0] if number == 0

    result = []

    while number > 0
      number, remainder = number.divmod(BASE)
      result << ALPHABET[remainder]
    end

    result.reverse.join
  end

  # Decodes a Base62 string into an integer.
  # @param string [String] the Base62 string to decode.
  # @return [Integer] the decoded integer.
  # @raise [ArgumentError] if the string contains an invalid character.
  def self.decode(string)
    number = 0
    string.reverse.each_char.with_index do |char, index|
      value = DECODE_MAP[char]
      raise ArgumentError, "Invalid character #{char}" if value.nil?

      number += value * (BASE**index)
    end
    number
  end
end
