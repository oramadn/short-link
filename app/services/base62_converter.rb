class Base62Converter
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
  BASE = ALPHABET.length

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
      power = BASE**index
      value = ALPHABET.index(char)
      number += value * power
    end
    number
  end
end
