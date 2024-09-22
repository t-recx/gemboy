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
        attr_accessor :ime
        attr_accessor :disable_ime_next
        attr_accessor :enable_ime_next

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

            @ime = false
            @disable_ime_next = false
            @enable_ime_next = false

            @memory = memory || Memory.new
        end

        def instruction(data, i = 0)
            ime_after = nil

            if @disable_ime_next
                ime_after = false
                @disable_ime_next = false
            end

            if @enable_ime_next
                ime_after = true
                @enable_ime_next = false
            end

            cycles_instruction = case data[i]
                when 0x00
                    nop
                # TODO: has interactions with interrupts
                #when 0x10
                    #stop
                # TODO: has interactions with interrupts
                #when 0x76
                    #halt
                when 0xC3
                    jp(data[i + 1, 2])
                when 0xE9
                    jp_hl
                when 0x18
                    jr(data[i + 1])
                when 0xC2
                    jp_cc(data[i + 1, 2], ZERO_FLAG, false)
                when 0xCA
                    jp_cc(data[i + 1, 2], ZERO_FLAG, true)
                when 0xD2
                    jp_cc(data[i + 1, 2], CARRY_FLAG, false)
                when 0xDA
                    jp_cc(data[i + 1, 2], CARRY_FLAG, true)
                when 0x20
                    jr_cc(data[i + 1], ZERO_FLAG, false)    
                when 0x28
                    jr_cc(data[i + 1], ZERO_FLAG, true)    
                when 0x30
                    jr_cc(data[i + 1], CARRY_FLAG, false)
                when 0x38
                    jr_cc(data[i + 1], CARRY_FLAG, true)
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
                    ld_r_n(:a, data[i + 1])
                when 0x06
                    ld_r_n(:b, data[i + 1])
                when 0x0E
                    ld_r_n(:c, data[i + 1])
                when 0x16
                    ld_r_n(:d, data[i + 1])
                when 0x1E
                    ld_r_n(:e, data[i + 1])
                when 0x26
                    ld_r_n(:h, data[i + 1])
                when 0x2E
                    ld_r_n(:l, data[i + 1])
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
                    ld_hl_n(data[i + 1])
                when 0x0A
                    ld_a_bc
                when 0x1A
                    ld_a_de
                when 0x02
                    ld_bc_a
                when 0x12
                    ld_de_a
                when 0xFA
                    ld_a_nn(data[i + 1, 2])
                when 0xEA
                    ld_nn_a(data[i + 1, 2])
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
                    ld_nn_sp(data[i + 1, 2])
                when 0xF9
                    ld_sp_hl
                when 0x01
                    ld_rr_nn(data[i + 1, 2], :b, :c)
                when 0x11
                    ld_rr_nn(data[i + 1, 2], :d, :e)
                when 0x21
                    ld_rr_nn(data[i + 1, 2], :h, :l)
                when 0x31
                    ld_sp_nn(data[i + 1, 2])
                when 0xF8
                    ldhl_sp_n(data[i + 1]) 
                when 0xE0
                    ld_0xFF00_n_a(data[i + 1])
                when 0xF0
                    ld_a_0xFF00_n(data[i + 1])
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
                    add_a_n(data[i + 1])
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
                    adc_a_n(data[i + 1])
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
                    sub_n(data[i + 1])
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
                    sbc_a_n(data[i + 1])
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
                    and_a_n(data[i + 1])
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
                    or_a_n(data[i + 1])
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
                    xor_a_n(data[i + 1])
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
                    cp_a_n(data[i + 1])
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
                when 0x3D
                    dec_r(:a)
                when 0x05
                    dec_r(:b)
                when 0x0D
                    dec_r(:c)
                when 0x15
                    dec_r(:d)
                when 0x1D
                    dec_r(:e)
                when 0x25
                    dec_r(:h)
                when 0x2D
                    dec_r(:l)
                when 0x35
                    dec_hl
                when 0x27
                    daa
                when 0x2F
                    cpl
                when 0x37
                    scf
                when 0x3F
                    ccf
                when 0xCD
                    call_nn(data[i + 1, 2])
                when 0xC4
                    call_nz(data[i + 1, 2])
                when 0xCC
                    call_z(data[i + 1, 2])
                when 0xD4
                    call_nc(data[i + 1, 2])
                when 0xDC
                    call_c(data[i + 1, 2])
                when 0xC9
                    ret
                when 0xC0
                    ret_nz
                when 0xC8
                    ret_z
                when 0xD0
                    ret_nc
                when 0xD8
                    ret_c
                when 0xD9
                    reti
                when 0xC7
                    rst 0x0000
                when 0xCF
                    rst 0x0008
                when 0xD7
                    rst 0x0010
                when 0xDF
                    rst 0x0018
                when 0xE7
                    rst 0x0020
                when 0xEF
                    rst 0x0028
                when 0xF7
                    rst 0x0030
                when 0xFF
                    rst 0x0038
                when 0xF3
                    di
                when 0xFB
                    ei
                when 0xCB
                    case data[i + 1]
                        when 0x07
                            rlc_r(:a)
                        when 0x00
                            rlc_r(:b)
                        when 0x01
                            rlc_r(:c)
                        when 0x02
                            rlc_r(:d)
                        when 0x03
                            rlc_r(:e)
                        when 0x04
                            rlc_r(:h)
                        when 0x05
                            rlc_r(:l)
                        when 0x06
                            rlc_hl
                        when 0x0F
                            rrc_r(:a)
                        when 0x08
                            rrc_r(:b)
                        when 0x09
                            rrc_r(:c)
                        when 0x0A
                            rrc_r(:d)
                        when 0x0B
                            rrc_r(:e)
                        when 0x0C
                            rrc_r(:h)
                        when 0x0D
                            rrc_r(:l)
                        when 0x0E
                            rrc_hl
                        when 0x17
                            rl_r(:a)
                        when 0x10
                            rl_r(:b)
                        when 0x11
                            rl_r(:c)
                        when 0x12
                            rl_r(:d)
                        when 0x13
                            rl_r(:e)
                        when 0x14
                            rl_r(:h)
                        when 0x15
                            rl_r(:l)
                        when 0x16
                            rl_hl
                        when 0x1F
                            rr_r(:a)
                        when 0x18
                            rr_r(:b)
                        when 0x19
                            rr_r(:c)
                        when 0x1A
                            rr_r(:d)
                        when 0x1B
                            rr_r(:e)
                        when 0x1C
                            rr_r(:h)
                        when 0x1D
                            rr_r(:l)
                        when 0x1E
                            rr_hl
                        when 0x27
                            sla_r(:a)
                        when 0x20
                            sla_r(:b)
                        when 0x21
                            sla_r(:c)
                        when 0x22
                            sla_r(:d)
                        when 0x23
                            sla_r(:e)
                        when 0x24
                            sla_r(:h)
                        when 0x25
                            sla_r(:l)
                        when 0x26
                            sla_hl
                        when 0x2F
                            sra_r(:a)
                        when 0x28
                            sra_r(:b)
                        when 0x29
                            sra_r(:c)
                        when 0x2A
                            sra_r(:d)
                        when 0x2B
                            sra_r(:e)
                        when 0x2C
                            sra_r(:h)
                        when 0x2D
                            sra_r(:l)
                        when 0x2E
                            sra_hl
                        when 0x37
                            swap_r(:a)
                        when 0x30
                            swap_r(:b)
                        when 0x31
                            swap_r(:c)
                        when 0x32
                            swap_r(:d)
                        when 0x33
                            swap_r(:e)
                        when 0x34
                            swap_r(:h)
                        when 0x35
                            swap_r(:l)
                        when 0x36
                            swap_hl
                        when 0x3F
                            srl_r(:a)
                        when 0x38
                            srl_r(:b)
                        when 0x39
                            srl_r(:c)
                        when 0x3A
                            srl_r(:d)
                        when 0x3B
                            srl_r(:e)
                        when 0x3C
                            srl_r(:h)
                        when 0x3D
                            srl_r(:l)
                        when 0x3E
                            srl_hl
                        when 0x47
                            bit_r(:a, 0)
                        when 0x40
                            bit_r(:b, 0)
                        when 0x41
                            bit_r(:c, 0)
                        when 0x42
                            bit_r(:d, 0)
                        when 0x43
                            bit_r(:e, 0)
                        when 0x44
                            bit_r(:h, 0)
                        when 0x45
                            bit_r(:l, 0)
                        when 0x46
                            bit_hl(0)
                        when 0x4F
                            bit_r(:a, 1)
                        when 0x48
                            bit_r(:b, 1)
                        when 0x49
                            bit_r(:c, 1)
                        when 0x4A
                            bit_r(:d, 1)
                        when 0x4B
                            bit_r(:e, 1)
                        when 0x4C
                            bit_r(:h, 1)
                        when 0x4D
                            bit_r(:l, 1)
                        when 0x4E
                            bit_hl(1)
                        when 0x57
                            bit_r(:a, 2)
                        when 0x50
                            bit_r(:b, 2)
                        when 0x51
                            bit_r(:c, 2)
                        when 0x52
                            bit_r(:d, 2)
                        when 0x53
                            bit_r(:e, 2)
                        when 0x54
                            bit_r(:h, 2)
                        when 0x55
                            bit_r(:l, 2)
                        when 0x56
                            bit_hl(2)
                        when 0x5F
                            bit_r(:a, 3)
                        when 0x58
                            bit_r(:b, 3)
                        when 0x59
                            bit_r(:c, 3)
                        when 0x5A
                            bit_r(:d, 3)
                        when 0x5B
                            bit_r(:e, 3)
                        when 0x5C
                            bit_r(:h, 3)
                        when 0x5D
                            bit_r(:l, 3)
                        when 0x5E
                            bit_hl(3)
                        when 0x67
                            bit_r(:a, 4)
                        when 0x60
                            bit_r(:b, 4)
                        when 0x61
                            bit_r(:c, 4)
                        when 0x62
                            bit_r(:d, 4)
                        when 0x63
                            bit_r(:e, 4)
                        when 0x64
                            bit_r(:h, 4)
                        when 0x65
                            bit_r(:l, 4)
                        when 0x66
                            bit_hl(4)
                        when 0x6F
                            bit_r(:a, 5)
                        when 0x68
                            bit_r(:b, 5)
                        when 0x69
                            bit_r(:c, 5)
                        when 0x6A
                            bit_r(:d, 5)
                        when 0x6B
                            bit_r(:e, 5)
                        when 0x6C
                            bit_r(:h, 5)
                        when 0x6D
                            bit_r(:l, 5)
                        when 0x6E
                            bit_hl(5)
                        when 0x77
                            bit_r(:a, 6)
                        when 0x70
                            bit_r(:b, 6)
                        when 0x71
                            bit_r(:c, 6)
                        when 0x72
                            bit_r(:d, 6)
                        when 0x73
                            bit_r(:e, 6)
                        when 0x74
                            bit_r(:h, 6)
                        when 0x75
                            bit_r(:l, 6)
                        when 0x76
                            bit_hl(6)
                        when 0x7F
                            bit_r(:a, 7)
                        when 0x78
                            bit_r(:b, 7)
                        when 0x79
                            bit_r(:c, 7)
                        when 0x7A
                            bit_r(:d, 7)
                        when 0x7B
                            bit_r(:e, 7)
                        when 0x7C
                            bit_r(:h, 7)
                        when 0x7D
                            bit_r(:l, 7)
                        when 0x7E
                            bit_hl(7)
                        when 0xC7
                            set_r(:a, 0)
                        when 0xC0
                            set_r(:b, 0)
                        when 0xC1
                            set_r(:c, 0)
                        when 0xC2
                            set_r(:d, 0)
                        when 0xC3
                            set_r(:e, 0)
                        when 0xC4
                            set_r(:h, 0)
                        when 0xC5
                            set_r(:l, 0)
                        when 0xC6
                            set_hl(0)
                        when 0xCF
                            set_r(:a, 1)
                        when 0xC8
                            set_r(:b, 1)
                        when 0xC9
                            set_r(:c, 1)
                        when 0xCA
                            set_r(:d, 1)
                        when 0xCB
                            set_r(:e, 1)
                        when 0xCC
                            set_r(:h, 1)
                        when 0xCD
                            set_r(:l, 1)
                        when 0xCE
                            set_hl(1)
                        when 0xD7
                            set_r(:a, 2)
                        when 0xD0
                            set_r(:b, 2)
                        when 0xD1
                            set_r(:c, 2)
                        when 0xD2
                            set_r(:d, 2)
                        when 0xD3
                            set_r(:e, 2)
                        when 0xD4
                            set_r(:h, 2)
                        when 0xD5
                            set_r(:l, 2)
                        when 0xD6
                            set_hl(2)
                        when 0xDF
                            set_r(:a, 3)
                        when 0xD8
                            set_r(:b, 3)
                        when 0xD9
                            set_r(:c, 3)
                        when 0xDA
                            set_r(:d, 3)
                        when 0xDB
                            set_r(:e, 3)
                        when 0xDC
                            set_r(:h, 3)
                        when 0xDD
                            set_r(:l, 3)
                        when 0xDE
                            set_hl(3)
                        when 0xE7
                            set_r(:a, 4)
                        when 0xE0
                            set_r(:b, 4)
                        when 0xE1
                            set_r(:c, 4)
                        when 0xE2
                            set_r(:d, 4)
                        when 0xE3
                            set_r(:e, 4)
                        when 0xE4
                            set_r(:h, 4)
                        when 0xE5
                            set_r(:l, 4)
                        when 0xE6
                            set_hl(4)
                        when 0xEF
                            set_r(:a, 5)
                        when 0xE8
                            set_r(:b, 5)
                        when 0xE9
                            set_r(:c, 5)
                        when 0xEA
                            set_r(:d, 5)
                        when 0xEB
                            set_r(:e, 5)
                        when 0xEC
                            set_r(:h, 5)
                        when 0xED
                            set_r(:l, 5)
                        when 0xEE
                            set_hl(5)
                        when 0xF7
                            set_r(:a, 6)
                        when 0xF0
                            set_r(:b, 6)
                        when 0xF1
                            set_r(:c, 6)
                        when 0xF2
                            set_r(:d, 6)
                        when 0xF3
                            set_r(:e, 6)
                        when 0xF4
                            set_r(:h, 6)
                        when 0xF5
                            set_r(:l, 6)
                        when 0xF6
                            set_hl(6)
                        when 0xFF
                            set_r(:a, 7)
                        when 0xF8
                            set_r(:b, 7)
                        when 0xF9
                            set_r(:c, 7)
                        when 0xFA
                            set_r(:d, 7)
                        when 0xFB
                            set_r(:e, 7)
                        when 0xFC
                            set_r(:h, 7)
                        when 0xFD
                            set_r(:l, 7)
                        when 0xFE
                            set_hl(7)
                    end
            end

            unless ime_after.nil?
                @ime = ime_after
            end

            return cycles_instruction
        end

        private

        def set_r(r, pos)
            @registers[r] = Utils.set_bit(@registers[r], pos)

            @program_counter += 2

            return 8
        end

        def set_hl(pos)
            @memory[hl] = Utils.set_bit(@memory[hl], pos)

            @program_counter += 2

            return 16
        end

        def bit_r(r, pos)
            _bit_n(@registers[r], pos)

            @program_counter += 2

            return 8
        end

        def bit_hl(pos)
            _bit_n(@memory[hl], pos)

            @program_counter += 2

            return 16
        end

        def srl_r(r)
            @registers[r] = _srl_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def srl_hl
            @memory[hl] = _srl_n(@memory[hl])

            @program_counter += 2

            return 16
        end

        def swap_r(r)
            @registers[r] = _swap_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def swap_hl
            @memory[hl] = _swap_n(@memory[hl])

            @program_counter += 2

            return 16
        end

        def sra_hl
            @memory[hl] = _sra_n(@memory[hl])

            @program_counter += 2

            return 16
        end

        def sra_r(r)
            @registers[r] = _sra_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def sla_hl
            @memory[hl] = _sla_n(@memory[hl])

            @program_counter += 2

            return 16
        end

        def sla_r(r)
            @registers[r] = _sla_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def rr_hl
            @memory[hl] = _rr_n(@memory[hl])

            @program_counter += 2

            return 16 
        end

        def rr_r(r)
            @registers[r] = _rr_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def rl_r(r)
            @registers[r] = _rl_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def rl_hl
            @memory[hl] = _rl_n(@memory[hl])

            @program_counter += 2

            return 16 
        end

        def rrc_r(r)
            @registers[r] = _rrc_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def rrc_hl
            @memory[hl] = _rrc_n(@memory[hl])

            @program_counter += 2

            return 16
        end

        def rlc_r(r)
            @registers[r] = _rlc_n(@registers[r])

            @program_counter += 2

            return 8
        end

        def rlc_hl
            @memory[hl] = _rlc_n(@memory[hl])

            @program_counter += 2

            return 16
        end

        def _bit_n(n, pos)
            set_flag(ZERO_FLAG) if !Utils.bit_set?(n, pos)
            set_flag(HALF_CARRY_FLAG)
            clear_flag(SUBTRACT_FLAG)
        end

        def _swap_n(n)
            new_value = ((n & 0x0F) << 4) | ((n & 0xF0) >> 4)

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0

            new_value
        end

        def _srl_n(n)
            original_value = n
            new_value = n

            new_value = original_value >> 1
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if (original_value & 0x01) == 1

            new_value
        end

        def _sra_n(n)
            original_value = n
            new_value = n

            new_value = (original_value >> 1) | (original_value & 0x80)
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if (original_value & 0x01) != 0

            new_value
        end

        def _sla_n(n)
            original_value = n
            new_value = n

            new_value = original_value << 1
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if (original_value & 0x80) != 0

            new_value
        end

        def _rl_n(n)
            original_value = n
            new_value = n

            carry_in = flag_set?(CARRY_FLAG) ? 1 : 0
            new_value = ((original_value << 1) | carry_in)
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if (original_value & 0x80) != 0

            new_value
        end

        def _rr_n(n)
            original_value = n
            new_value = n

            carry_in = flag_set?(CARRY_FLAG) ? 1 : 0
            new_value = ((carry_in << 7) | (original_value >> 1))
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if (original_value & 0x01) != 0

            new_value
        end

        def _rrc_n(n)
            original_value = n
            new_value = n

            carry_out = original_value & 0x01
            new_value = ((original_value >> 1) | (carry_out << 7))
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if carry_out == 1

            new_value
        end

        def _rlc_n(n)
            original_value = n
            new_value = n

            new_value = ((original_value << 1) | (original_value >> 7))
            new_value &= 0xFF

            reset_flags
            set_flag(ZERO_FLAG) if new_value == 0
            set_flag(CARRY_FLAG) if (original_value & 0x80) != 0

            new_value
        end

        def ei
            @program_counter += 1

            @enable_ime_next = true

            return 4
        end

        def di
            @program_counter += 1

            @disable_ime_next = true

            return 4
        end

        def nop
            @program_counter += 1

            return 4
        end

        def rst(n)
            @sp -= 2

            next_pc = @program_counter + 1

            @memory[@sp] = Utils.get_lo(next_pc)
            @memory[@sp + 1] = Utils.get_hi(next_pc)

            @program_counter = n

            return 16
        end

        def reti
            @ime = true

            ret
        end

        def ret_nz
            ret_cond(ZERO_FLAG, false)
        end

        def ret_z
            ret_cond(ZERO_FLAG, true)
        end

        def ret_nc
            ret_cond(CARRY_FLAG, false)
        end

        def ret_c
            ret_cond(CARRY_FLAG, true)
        end

        def ret_cond(flag, value)
            if flag_set?(flag) == value
                ret

                return 20
            else
                @program_counter += 1

                return 8
            end
        end

        def ret
            @sp += 2
            
            @program_counter = Utils.get_16bit(@memory[@sp - 1], @memory[@sp - 2])

            return 16
        end

        def call_c(data)
            call_cond(data, CARRY_FLAG, true)
        end

        def call_nc(data)
            call_cond(data, CARRY_FLAG, false)
        end

        def call_z(data)
            call_cond(data, ZERO_FLAG, true)
        end

        def call_nz(data)
            call_cond(data, ZERO_FLAG, false)
        end

        def call_cond(data, flag, value)
            if flag_set?(flag) == value
                return call_nn(data)
            else
                @program_counter += 3

                return 12
            end
        end

        def call_nn(data)
            @sp -= 2

            next_pc = @program_counter + 3

            @memory[@sp] = Utils.get_lo(next_pc)
            @memory[@sp + 1] = Utils.get_hi(next_pc)

            @program_counter = Utils.get_16bit(data[1], data[0])

            return 24
        end

        def ccf
            if flag_set?(CARRY_FLAG)
                clear_flag(CARRY_FLAG)
            else
                set_flag(CARRY_FLAG)
            end

            clear_flag(HALF_CARRY_FLAG)
            clear_flag(SUBTRACT_FLAG)

            @program_counter += 1

            return 4
        end

        def scf
            set_flag(CARRY_FLAG)

            clear_flag(HALF_CARRY_FLAG)
            clear_flag(SUBTRACT_FLAG)

            @program_counter += 1

            return 4
        end

        def cpl
            @registers[:a] = ~@registers[:a]

            @registers[:a] &= 0xFF

            set_flag(HALF_CARRY_FLAG)
            set_flag(SUBTRACT_FLAG)

            @program_counter += 1

            return 4
        end

        def daa
            offset = 0

            if (!flag_set?(SUBTRACT_FLAG) && (@registers[:a] & 0xF) > 0x09) || flag_set?(HALF_CARRY_FLAG)
               offset |= 0x06
            end

            if (!flag_set?(SUBTRACT_FLAG) && @registers[:a] > 0x99) || flag_set?(CARRY_FLAG)
                offset |= 0x60
                set_flag(CARRY_FLAG)
            end

            if flag_set?(SUBTRACT_FLAG)
                @registers[:a] = (@registers[:a] - offset) & 0xFF
            else
                @registers[:a] = (@registers[:a] + offset) & 0xFF
            end

            clear_flag(HALF_CARRY_FLAG)
            set_flag(ZERO_FLAG) if @registers[:a] == 0x00

            @program_counter += 1

            return 4
        end

        def dec_r(r)
            result = (@registers[r] - 1) & 0xFF

            set_flag(SUBTRACT_FLAG)
            set_flag(ZERO_FLAG) if result == 0x00
            set_flag(HALF_CARRY_FLAG) if ((@registers[r] & 0x0F) == 0x00) && (result & 0x0F == 0x0F) && result != 0xFF && result != 0x00

            @registers[r] = result

            @program_counter += 1

            return 4
        end

        def dec_hl
            result = (@memory[hl] - 1) & 0xFF

            set_flag(SUBTRACT_FLAG)
            set_flag(ZERO_FLAG) if result == 0x00
            set_flag(HALF_CARRY_FLAG) if ((@memory[hl] & 0x0F) == 0x00) && (result & 0x0F == 0x0F) && result != 0xFF && result != 0x00

            @memory[hl] = result

            @program_counter += 1

            return 12
        end

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

        def ld_a_0xFF00_n(n)
            @registers[:a] = @memory[0xFF00 + n]

            @program_counter += 2

            return 12
        end

        def ld_0xFF00_n_a(n)
            @memory[0xFF00 + n] = registers[:a]

            @program_counter += 2

            return 12
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