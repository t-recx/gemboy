module Gemboy
  class Utils
    class << self
      def get_hi(bytes)
        (bytes >> 8) & 0xFF
      end

      def get_lo(bytes)
        bytes & 0xFF
      end

      def get_16bit(hi, lo)
        (hi << 8) | lo
      end

      def get_io_address(address)
        0xFF00 + address
      end

      def get_signed_8bit(value)
        signed = value.to_i

        signed -= 0x100 if signed > 0x7F

        signed
      end

      def flag_set?(value, flag)
        (value & flag) != 0
      end

      def bit_set?(number, bit_position)
        (number & (1 << bit_position)) != 0
      end

      def set_bit(number, bit_position)
        number | (1 << bit_position)
      end

      def reset_bit(value, bit_position)
        value & ~(1 << bit_position)
      end
    end
  end
end
