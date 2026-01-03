class Base62Converter
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
  BASE = ALPHABET.length

  DECODE_MAP = ALPHABET.each_char.with_index.to_h.freeze

  def self.encode(number)
    return ALPHABET[0] if number == 0

    result = ""
    while number > 0
      remainder = number % BASE
      result.prepend(ALPHABET[remainder])
      number /= BASE
    end
    result
  end

  def self.decode(string)
    number = 0
    string.reverse.each_char.with_index do |char, index|
      value = DECODE_MAP[char]

      raise ArgumentError, "Invalid character #{char} in Base62 string" if value.nil?

      number += value * (BASE**index)
    end
    number
  end
end

