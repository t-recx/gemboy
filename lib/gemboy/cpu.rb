module Gemboy
    class CPU
        ZERO_FLAG = 0b10000000
        SUBTRACT_FLAG = 0b01000000
        HALF_CARRY_FLAG = 0b00100000
        CARRY_FLAG = 0b00010000

        attr_accessor :program_counter
        attr_accessor :registers
        attr_accessor :f
        attr_accessor :sp

        def initialize(memory = nil)
            @program_counter = 0x00

            @registers = {
                a: 0x00,
                b: 0x00,
                c: 0x00,
                d: 0x00,
                e: 0x00,
                f: 0x00,
                h: 0x00,
                l: 0x00
            }

            @sp = 0xFFFE

            @memory = memory || Memory.new
        end

        def instruction(data)
            case data[0]
                when 0xC3
                    jp(data[1..])
                when 0xE9
                    jp_hl
                when 0x18
                    jr(data[1])
                when 0xC2
                    jp_cc(data[1..], ZERO_FLAG, false)
                when 0xCA
                    jp_cc(data[1..], ZERO_FLAG, true)
                when 0xD2
                    jp_cc(data[1..], CARRY_FLAG, false)
                when 0xDA
                    jp_cc(data[1..], CARRY_FLAG, true)
                when 0x20
                    jr_cc(data[1], ZERO_FLAG, false)    
                when 0x28
                    jr_cc(data[1], ZERO_FLAG, true)    
                when 0x30
                    jr_cc(data[1], CARRY_FLAG, false)
                when 0x38
                    jr_cc(data[1], CARRY_FLAG, true)
                when 0x78
                    ld(:a, :b)
                when 0x79
                    ld(:a, :c)
                when 0x7A
                    ld(:a, :d)
                when 0x7B
                    ld(:a, :e)
                when 0x7C
                    ld(:a, :h)
                when 0x7D
                    ld(:a, :l)
                when 0x47
                    ld(:b, :a)
                when 0x41
                    ld(:b, :c)
                when 0x42
                    ld(:b, :d)
                when 0x43
                    ld(:b, :e)
                when 0x44
                    ld(:b, :h)
                when 0x45
                    ld(:b, :l)
                when 0x4F
                    ld(:c, :a)
                when 0x48
                    ld(:c, :b)
                when 0x4A
                    ld(:c, :d)
                when 0x4B
                    ld(:c, :e)
                when 0x4C
                    ld(:c, :h)
                when 0x4D
                    ld(:c, :l)
                when 0x57
                    ld(:d, :a)
                when 0x50
                    ld(:d, :b)
                when 0x51
                    ld(:d, :c)
                when 0x53
                    ld(:d, :e)
                when 0x54
                    ld(:d, :h)
                when 0x55
                    ld(:d, :l)
                when 0x5F
                    ld(:e, :a)
                when 0x58
                    ld(:e, :b)
                when 0x59
                    ld(:e, :c)
                when 0x5A
                    ld(:e, :d)
                when 0x5C
                    ld(:e, :h)
                when 0x5D
                    ld(:e, :l)
                when 0x67
                    ld(:h, :a)
                when 0x60
                    ld(:h, :b)
                when 0x61
                    ld(:h, :c)
                when 0x62
                    ld(:h, :d)
                when 0x63
                    ld(:h, :e)
                when 0x65
                    ld(:h, :l)
                when 0x6F
                    ld(:l, :a)
                when 0x68
                    ld(:l, :b)
                when 0x69
                    ld(:l, :c)
                when 0x6A
                    ld(:l, :d)
                when 0x6B
                    ld(:l, :e)
                when 0x6C
                    ld(:l, :h)
                when 0x3E
                    ld_r_n(:a, data[1])
                when 0x06
                    ld_r_n(:b, data[1])
                when 0x0E
                    ld_r_n(:c, data[1])
                when 0x16
                    ld_r_n(:d, data[1])
                when 0x1E
                    ld_r_n(:e, data[1])
                when 0x26
                    ld_r_n(:h, data[1])
                when 0x2E
                    ld_r_n(:l, data[1])
                when 0x7E
                    ld_r_hl(:a)
                when 0x46
                    ld_r_hl(:b)
                when 0x4E
                    ld_r_hl(:c)
                when 0x56
                    ld_r_hl(:d)
                when 0x5E
                    ld_r_hl(:e)
                when 0x66
                    ld_r_hl(:h)
                when 0x6E
                    ld_r_hl(:l)
                when 0x77
                    ld_hl_r(:a)
                when 0x70
                    ld_hl_r(:b)
                when 0x71
                    ld_hl_r(:c)
                when 0x72
                    ld_hl_r(:d)
                when 0x73
                    ld_hl_r(:e)
                when 0x74
                    ld_hl_r(:h)
                when 0x75
                    ld_hl_r(:l)
                when 0x36
                    ld_hl_n(data[1])
                when 0x0A
                    ld_a_bc
                when 0x1A
                    ld_a_de
                when 0x02
                    ld_bc_a
                when 0x12
                    ld_de_a
                when 0xFA
                    ld_a_nn(data[1..])
                when 0xEA
                    ld_nn_a(data[1..])
                when 0xF2
                    ld_a_c
                when 0xE2
                    ld_c_a
                when 0x3A
                    ldd_a_hl
                when 0x32
                    ldd_hl_a
                when 0x2A
                    ldi_a_hl
                when 0x22
                    ldi_hl_a
                when 0x08
                    ld_nn_sp(data[1..])
                when 0xF9
                    ld_sp_hl
                when 0x01
                    ld_rr_nn(data[1..], :b, :c)
                when 0x11
                    ld_rr_nn(data[1..], :d, :e)
                when 0x21
                    ld_rr_nn(data[1..], :h, :l)
                when 0x31
                    ld_sp_nn(data[1..])
                when 0xF8
                    ldhl_sp_n(data[1]) 
                when 0xC5
                    push_rr(@registers[:b], @registers[:c])
                when 0xD5
                    push_rr(@registers[:d], @registers[:e])
                when 0xE5
                    push_rr(@registers[:h], @registers[:l])
                when 0xF5
                    push_rr(@registers[:a], @registers[:f])
                when 0xC1
                    pop_rr(:b, :c)
                when 0xD1
                    pop_rr(:d, :e)
                when 0xE1
                    pop_rr(:h, :l)
                when 0xF1
                    pop_rr(:a, :f)
                when 0x87
                    add_a_r(:a)
                when 0x80
                    add_a_r(:b)
                when 0x81
                    add_a_r(:c)
                when 0x82
                    add_a_r(:d)
                when 0x83
                    add_a_r(:e)
                when 0x84
                    add_a_r(:h)
                when 0x85
                    add_a_r(:l)
                when 0x86
                    add_a_hl
                when 0xC6
                    add_a_n(data[1])
                when 0x8F
                    adc_a_r(:a)
                when 0x88
                    adc_a_r(:b)
                when 0x89
                    adc_a_r(:c)
                when 0x8A
                    adc_a_r(:d)
                when 0x8B
                    adc_a_r(:e)
                when 0x8C
                    adc_a_r(:h)
                when 0x8D
                    adc_a_r(:l)
                when 0x8E
                    adc_a_hl
                when 0xCE
                    adc_a_n(data[1])
                when 0x97
                    sub_a_r(:a)
                when 0x90
                    sub_a_r(:b)
                when 0x91
                    sub_a_r(:c)
                when 0x92
                    sub_a_r(:d)
                when 0x93
                    sub_a_r(:e)
                when 0x94
                    sub_a_r(:h)
                when 0x95
                    sub_a_r(:l)
                when 0x96
                    sub_a_hl
                when 0xD6
                    sub_n(data[1])
                when 0x9F
                    sbc_a_r(:a)
                when 0x98
                    sbc_a_r(:b)
                when 0x99
                    sbc_a_r(:c)
                when 0x9A
                    sbc_a_r(:d)
                when 0x9B
                    sbc_a_r(:e)
                when 0x9C
                    sbc_a_r(:h)
                when 0x9D
                    sbc_a_r(:l)
                when 0x9E
                    sbc_a_hl
                when 0xDE
                    sbc_a_n(data[1])
                when 0xA7
                    and_a_r(:a)
                when 0xA0
                    and_a_r(:b)
                when 0xA1
                    and_a_r(:c)
                when 0xA2
                    and_a_r(:d)
                when 0xA3
                    and_a_r(:e)
                when 0xA4
                    and_a_r(:h)
                when 0xA5
                    and_a_r(:l)
                when 0xA6
                    and_a_hl
                when 0xE6
                    and_a_n(data[1])
                when 0xB7
                    or_a_r(:a)
                when 0xB0
                    or_a_r(:b)
                when 0xB1
                    or_a_r(:c)
                when 0xB2
                    or_a_r(:d)
                when 0xB3
                    or_a_r(:e)
                when 0xB4
                    or_a_r(:h)
                when 0xB5
                    or_a_r(:l)
                when 0xB6
                    or_a_hl
                when 0xF6
                    or_a_n(data[1])
                when 0xA8
                    xor_a_r(:b)
                when 0xA9
                    xor_a_r(:c)
                when 0xAA
                    xor_a_r(:d)
                when 0xAB
                    xor_a_r(:e)
                when 0xAC
                    xor_a_r(:h)
                when 0xAD
                    xor_a_r(:l)
                when 0xAF
                    xor_a_r(:a)
                when 0xAE
                    xor_a_hl
                when 0xEE
                    xor_a_n(data[1])
                when 0xBF
                    cp_a_r(:a)
                when 0xB8
                    cp_a_r(:b)
                when 0xB9
                    cp_a_r(:c)
                when 0xBA
                    cp_a_r(:d)
                when 0xBB
                    cp_a_r(:e)
                when 0xBC
                    cp_a_r(:h)
                when 0xBD
                    cp_a_r(:l)
                when 0xBE
                    cp_a_hl
                when 0xFE
                    cp_a_n(data[1])
                when 0x3C
                    inc_r(:a)
                when 0x04
                    inc_r(:b)
                when 0x0C
                    inc_r(:c)
                when 0x14
                    inc_r(:d)
                when 0x1C
                    inc_r(:e)
                when 0x24
                    inc_r(:h)
                when 0x2C
                    inc_r(:l)
                when 0x34
                    inc_hl
            end
        end

        private

        def inc_hl
            result = (@memory[hl] + 1) & 0xFF

            clear_flag(SUBTRACT_FLAG)
            set_flag(ZERO_FLAG) if result == 0x00
            set_flag(HALF_CARRY_FLAG) if (((@memory[hl] & 0xF) + 1) & 0x10) == 0x10

            @memory[hl] = result

            @program_counter += 1

            return 12
        end

        def inc_r(r)
            result = (@registers[r] + 1) & 0xFF

            clear_flag(SUBTRACT_FLAG)
            set_flag(ZERO_FLAG) if result == 0x00
            set_flag(HALF_CARRY_FLAG) if (((@registers[r] & 0xF) + 1) & 0x10) == 0x10

            @registers[r] = result

            @program_counter += 1

            return 4
        end

        def cp_a_n(n)
            _cp_n(n)

            @program_counter += 2

            return 8
        end

        def cp_a_hl
            _cp_n(memory[hl])

            @program_counter += 1

            return 8
        end

        def cp_a_r(r)
            _cp_n(@registers[r])

            @program_counter += 1

            return 4
        end

        def _cp_n(n)
            o1 = @registers[:a]
            o2 = n

            result = o1 - o2

            set_flags_sub(o1, o2, result)
        end

        def xor_a_n(n)
            _xor_a_n(n)

            @program_counter += 2

            return 8
        end

        def xor_a_hl
            _xor_a_n(@memory[hl])

            @program_counter += 1

            return 8
        end

        def xor_a_r(r)
            _xor_a_n(registers[r])

            @program_counter += 1

            return 4
        end

        def _xor_a_n(n)
            o1 = registers[:a]
            o2 = n

            result = o1 ^ o2

            registers[:a] = result

            reset_flags

            set_flag(ZERO_FLAG) if result == 0x00
        end

        def or_a_n(n)
            _or_a_n(n)

            @program_counter += 2

            return 8
        end

        def or_a_hl
            _or_a_n(@memory[hl])

            @program_counter += 1

            return 8
        end

        def or_a_r(r)
            _or_a_n(registers[r])

            @program_counter += 1

            return 4
        end

        def _or_a_n(n)
            o1 = registers[:a]
            o2 = n

            result = o1 | o2

            registers[:a] = result

            reset_flags

            set_flag(ZERO_FLAG) if result == 0x00
        end

        def and_a_r(r)
            _and_n(registers[r])

            @program_counter += 1

            return 4
        end

        def and_a_hl
            _and_n(@memory[hl])

            @program_counter += 1

            return 8
        end

        def and_a_n(n)
            _and_n(n)

            @program_counter += 2

            return 8
        end

        def _and_n(n)
            o1 = registers[:a]
            o2 = n

            result = o1 & o2

            registers[:a] = result

            reset_flags

            set_flag(ZERO_FLAG) if result == 0x00
            set_flag(HALF_CARRY_FLAG) 
        end

        def sub_a_r(r)
            _sub_n(@registers[r])

            @program_counter += 1

            return 4
        end

        def sub_a_hl
            _sub_n(@memory[hl])

            @program_counter += 1

            return 8
        end

        def sub_n(n)
            _sub_n(n)

            @program_counter += 2

            return 8
        end

        def sbc_a_r(r)
            carry = flag_set?(CARRY_FLAG) ? 1 : 0

            _sub_n(@registers[r], carry)

            @program_counter += 1

            return 4
        end

        def sbc_a_hl
            carry = flag_set?(CARRY_FLAG) ? 1 : 0

            _sub_n(@memory[hl], carry)

            @program_counter += 1

            return 8
        end

        def sbc_a_n(n)
            carry = flag_set?(CARRY_FLAG) ? 1 : 0

            _sub_n(n, carry)

            @program_counter += 2

            return 8
        end

        def _sub_n(n, carry = 0)
            o1 = @registers[:a]
            o2 = n

            result = o1 - o2 - carry

            set_flags_sub(o1, o2, result, carry)

            @registers[:a] = result & 0xFF
        end

        def add_a_r(r)
            o1 = @registers[:a]
            o2 = @registers[r]

            result = o1 + o2

            set_flags_add(o1, o2, result)

            @registers[:a] = result & 0xFF

            @program_counter += 1

            return 4
        end

        def adc_a_r(r)
            carry = flag_set?(CARRY_FLAG) ? 1 : 0
            o1 = @registers[:a]
            o2 = @registers[r]

            result = o1 + o2 + carry

            set_flags_add(o1, o2, result, carry)

            @registers[:a] = result & 0xFF

            @program_counter += 1

            return 4
        end

        def add_a_hl
            o1 = @registers[:a]
            o2 = @memory[hl]

            result = o1 + o2

            set_flags_add(o1, o2, result)

            @registers[:a] = result & 0xFF

            @program_counter += 1

            return 8
        end

        def adc_a_hl
            carry = flag_set?(CARRY_FLAG) ? 1 : 0
            o1 = @registers[:a]
            o2 = @memory[hl]

            result = o1 + o2 + carry

            set_flags_add(o1, o2, result, carry)

            @registers[:a] = result & 0xFF

            @program_counter += 1

            return 8
        end

        def add_a_n(o2)
            o1 = @registers[:a]

            result = o1 + o2

            set_flags_add(o1, o2, result)

            @registers[:a] = result & 0xFF

            @program_counter += 2

            return 8
        end

        def adc_a_n(o2)
            carry = flag_set?(CARRY_FLAG) ? 1 : 0
            o1 = @registers[:a]

            result = o1 + o2 + carry

            set_flags_add(o1, o2, result, carry)

            @registers[:a] = result & 0xFF

            @program_counter += 2

            return 8
        end

        def set_flags_add(o1, o2, result, carry = 0)
            reset_flags

            set_flag(ZERO_FLAG) if result & 0xFF == 0x00
            set_flag(HALF_CARRY_FLAG) if (((o1 & 0xF) + (o2 & 0xF) + carry) & 0x10) == 0x10
            set_flag(CARRY_FLAG) if result > 0xFF
        end

        def set_flags_sub(o1, o2, result, carry = 0)
            reset_flags

            set_flag(SUBTRACT_FLAG)
            set_flag(ZERO_FLAG) if result & 0xFF == 0x00
            set_flag(HALF_CARRY_FLAG) if ((o1 & 0x0F) - (o2 & 0x0F) - carry) < 0
            set_flag(CARRY_FLAG) if result < 0
        end

        def ld(r1, r2)
            @registers[r1] = @registers[r2]

            @program_counter += 1

            return 4
        end

        def ld_r_n(r, n)
            @registers[r] = n
        
            @program_counter += 2
        
            return 8
        end

        def ld_r_hl(r)
            @registers[r] = @memory[hl]

            @program_counter += 1
            
            return 8
        end

        def ld_hl_r(r)
            @memory[hl] = @registers[r]
        
            @program_counter += 1
        
            return 8
        end

        def ld_hl_n(n)
            @memory[hl] = n

            @program_counter += 2

            return 12
        end

        def ld_a_bc
            @registers[:a] = @memory[bc]

            @program_counter += 1

            return 8
        end

        def ld_a_de
            @registers[:a] = @memory[de]

            @program_counter += 1

            return 8
        end

        def ld_bc_a
            @memory[bc] = @registers[:a]

            @program_counter += 1

            return 8
        end

        def ld_de_a
            @memory[de] = @registers[:a]

            @program_counter += 1

            return 8
        end

        def ld_a_nn(data)
            memory_address = Utils.get_16bit(data[1], data[0])

            @registers[:a] = @memory[memory_address]

            @program_counter += 3

            return 16
        end

        def ld_nn_a(data)
            memory_address = Utils.get_16bit(data[1], data[0])

            @memory[memory_address] = @registers[:a]

            @program_counter += 3

            return 16
        end

        def ld_a_c
            io_address = Utils.get_io_address(registers[:c])

            @registers[:a] = @memory[io_address]

            @program_counter += 1

            return 8
        end

        def ld_c_a
            io_address = Utils.get_io_address(registers[:c])

            @memory[io_address] = @registers[:a]

            @program_counter += 1

            return 8
        end

        def ldd_a_hl
            @registers[:a] = @memory[hl]

            hl_decremented = hl - 1

            @registers[:h] = Utils.get_hi(hl_decremented)
            @registers[:l] = Utils.get_lo(hl_decremented)

            @program_counter += 1

            return 8
        end

        def ldd_hl_a
            @memory[hl] = @registers[:a]

            hl_decremented = hl - 1

            @registers[:h] = Utils.get_hi(hl_decremented)
            @registers[:l] = Utils.get_lo(hl_decremented)

            @program_counter += 1

            return 8
        end

        def ldi_a_hl
            @registers[:a] = @memory[hl]

            hl_incremented = hl + 1

            @registers[:h] = Utils.get_hi(hl_incremented)
            @registers[:l] = Utils.get_lo(hl_incremented)

            @program_counter += 1

            return 8
        end

        def ldi_hl_a
            @memory[hl] = @registers[:a]

            hl_incremented = hl + 1

            @registers[:h] = Utils.get_hi(hl_incremented)
            @registers[:l] = Utils.get_lo(hl_incremented)

            @program_counter += 1

            return 8
        end

        def ld_nn_sp(data)
            memory_address = Utils.get_16bit(data[1], data[0])

            @memory[memory_address] = Utils.get_lo(@sp)
            @memory[memory_address + 1] = Utils.get_hi(@sp)

            @program_counter += 3

            return 20
        end

        def ld_sp_hl
            @sp = hl
        
            @program_counter += 1

            return 8
        end

        def ld_rr_nn(data, hi_register, lo_register)
            @registers[lo_register] = data[0]
            @registers[hi_register] = data[1]

            @program_counter += 3

            return 12
        end

        def ld_sp_nn(data)
            @sp = Utils.get_16bit(data[1], data[0])

            @program_counter += 3

            return 12
        end
        
        def ldhl_sp_n(data) 
            # todo: check if this affects any flags

            sp_incremented = @sp + Utils.get_signed_8bit(data)
        
            @registers[:h] = Utils.get_hi(sp_incremented)
            @registers[:l] = Utils.get_lo(sp_incremented)
        
            @program_counter += 2

            return 12
        end

        def push_rr(hi, lo)
            @sp -= 2

            @memory[@sp] = hi
            @memory[@sp + 1] = lo
        
            @program_counter += 1
        
            return 16
        end

        def pop_rr(hi_register, lo_register)
            @registers[hi_register] = @memory[@sp]
            @registers[lo_register] = @memory[@sp + 1]

            @sp += 2
        
            @program_counter += 1
        
            return 12
        end

        def jp(data)
            @program_counter = Utils.get_16bit(data[1], data[0])

            return 16
        end

        def jp_hl
            @program_counter = hl

            return 4
        end

        def jr(data)
            offset = Utils.get_signed_8bit(data)

            @program_counter += 2 + offset

            return 12
        end

        def jr_cc(data, flag, flag_value)
            if flag_set?(flag) == flag_value
                return jr(data)
            end

            @program_counter += 2

            return 8
        end

        def jp_cc(data, flag, flag_value)
            if flag_set?(flag) == flag_value
                return jp(data)
            end

            @program_counter += 3

            return 12
        end

        def hl
            Utils.get_16bit(@registers[:h], @registers[:l])
        end

        def bc
            Utils.get_16bit(@registers[:b], @registers[:c])
        end

        def de
            Utils.get_16bit(@registers[:d], @registers[:e])
        end

        def flag_set?(flag)
            Utils.flag_set?(@registers[:f], flag)
        end

        def set_flag(flag)
            @registers[:f] |= flag 
        end

        def clear_flag(flag)
            @registers[:f] &= ~flag
        end

        def reset_flags
            @registers[:f] = 0x00
        end
    end
end