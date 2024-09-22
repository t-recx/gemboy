require 'test_helper'
require 'gemboy'
require 'fakes/fake_memory'

include Gemboy

describe CPU do
    let(:memory) { FakeMemory.new }
    subject { CPU.new memory }

    describe :instruction do
        describe 'call' do
            describe 'CALL nn' do
                let(:data) { [0xCD, 0x56, 0x34] }

                before do
                    subject.program_counter = 0x1000
                end

                it 'should push the program counter to the stack' do
                    subject.instruction data 

                    _(memory[0xFFFC]).must_equal(0x03)
                    _(memory[0xFFFD]).must_equal(0x10)
                    _(subject.sp).must_equal(0xFFFC) 
                end

                it 'should set the program counter to specified address' do
                    subject.instruction data

                    _(subject.program_counter).must_equal 0x3456
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(24)
                end
            end

            call_cc_nn_instructions = [
                { 
                    opcode: 0xC4, # condition = zero is not set
                    n1: 0x34,
                    n2: 0x12,
                    program_counter: 0x2000, 
                    flags_set: [CPU::ZERO_FLAG], 
                    expected_cycles: 12, 
                    expected_program_counter: 0x2003, 
                    expected_sp: 0xFFFE, 
                    expected_memory_FFFC: nil,
                    expected_memory_FFFD: nil
                },
                { 
                    opcode: 0xC4, # condition = zero is not set
                    n1: 0x34,
                    n2: 0x12,
                    program_counter: 0x2000, 
                    flags_set: [], 
                    expected_cycles: 24, 
                    expected_program_counter: 0x1234, 
                    expected_sp: 0xFFFC, 
                    expected_memory_FFFC: 0x03,
                    expected_memory_FFFD: 0x20
                },
                { 
                    opcode: 0xCC, # condition = zero is set
                    n1: 0x41,
                    n2: 0x20,
                    program_counter: 0x1004, 
                    flags_set: [CPU::ZERO_FLAG], 
                    expected_cycles: 24, 
                    expected_program_counter: 0x2041, 
                    expected_sp: 0xFFFC, 
                    expected_memory_FFFC: 0x07,
                    expected_memory_FFFD: 0x10
                },
                { 
                    opcode: 0xCC, # condition = zero is set
                    n1: 0x34,
                    n2: 0x12,
                    program_counter: 0x4000, 
                    flags_set: [], 
                    expected_cycles: 12, 
                    expected_program_counter: 0x4003, 
                    expected_sp: 0xFFFE, 
                    expected_memory_FFFC: nil,
                    expected_memory_FFFD: nil
                },
                { 
                    opcode: 0xD4, # condition = carry not set
                    n1: 0x34,
                    n2: 0x12,
                    program_counter: 0x2000, 
                    flags_set: [CPU::CARRY_FLAG], 
                    expected_cycles: 12, 
                    expected_program_counter: 0x2003, 
                    expected_sp: 0xFFFE, 
                    expected_memory_FFFC: nil,
                    expected_memory_FFFD: nil
                },
                { 
                    opcode: 0xD4, # condition = carry not set
                    n1: 0x34,
                    n2: 0x12,
                    program_counter: 0x2000, 
                    flags_set: [], 
                    expected_cycles: 24, 
                    expected_program_counter: 0x1234, 
                    expected_sp: 0xFFFC, 
                    expected_memory_FFFC: 0x03,
                    expected_memory_FFFD: 0x20
                },
                { 
                    opcode: 0xDC, # condition = carry is set
                    n1: 0x41,
                    n2: 0x20,
                    program_counter: 0x1004, 
                    flags_set: [CPU::CARRY_FLAG], 
                    expected_cycles: 24, 
                    expected_program_counter: 0x2041, 
                    expected_sp: 0xFFFC, 
                    expected_memory_FFFC: 0x07,
                    expected_memory_FFFD: 0x10
                },
                { 
                    opcode: 0xDC, # condition = carry is set
                    n1: 0x34,
                    n2: 0x12,
                    program_counter: 0x4000, 
                    flags_set: [], 
                    expected_cycles: 12, 
                    expected_program_counter: 0x4003, 
                    expected_sp: 0xFFFE, 
                    expected_memory_FFFC: nil,
                    expected_memory_FFFD: nil
                },
            ]

            call_cc_nn_instructions.each do |inst|
                describe 'CALL cc, nn' do
                    let(:data) { [inst[:opcode], inst[:n1], inst[:n2]] }

                    before do
                        subject.program_counter = inst[:program_counter]

                        inst[:flags_set].each do |flag|
                            subject.registers[:f] |= flag
                        end
                    end

                    it 'should update the program_counter correctly' do
                        subject.instruction data

                        _(subject.program_counter).must_equal(inst[:expected_program_counter])
                    end

                    it 'should update the memory correctly' do
                        subject.instruction data

                        _(subject.sp).must_equal(inst[:expected_sp])
                        if (inst[:expected_memory_FFFC])
                            _(memory[0xFFFC]).must_equal(inst[:expected_memory_FFFC])
                        end
                        if (inst[:expected_memory_FFFD])
                            _(memory[0xFFFD]).must_equal(inst[:expected_memory_FFFD])
                        end
                    end
                
                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal inst[:expected_cycles]
                    end
                end
            end
        end

        describe 'return' do
            describe 'RET' do
                let(:data_setup) { [0xCD, 0x56, 0x34] } # CALL nn instruction
                let(:data) { [0xC9] }

                before do
                    subject.program_counter = 0x2130

                    subject.instruction data_setup
                end

                it 'should pop the value from the stack' do
                    subject.instruction data

                    _(subject.sp).must_equal(0xFFFE) 
                end

                it 'should set the program counter to the value on stack' do
                    subject.instruction data

                    _(subject.program_counter).must_equal 0x2133
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(16)
                end
            end

            describe 'RETI' do
                let(:data_setup) { [0xCD, 0x56, 0x34] } # CALL nn instruction
                let(:data) { [0xD9] }

                before do
                    subject.program_counter = 0x2130

                    subject.instruction data_setup
                end

                it 'should pop the value from the stack' do
                    subject.instruction data

                    _(subject.sp).must_equal(0xFFFE) 
                end

                it 'should set the program counter to the value on stack' do
                    subject.instruction data

                    _(subject.program_counter).must_equal 0x2133
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(16)
                end

                it 'should set the ime flag to true' do
                    subject.ime = false

                    subject.instruction data

                    _(subject.ime).must_equal true
                end

                it 'should keep the ime flag to true if that is already the case' do
                    subject.ime = true

                    subject.instruction data

                    _(subject.ime).must_equal true
                end
            end

            ret_cc_instructions = [
                { opcode: 0xC0, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [], expected_sp: 0xFFFE, expected_program_counter: 0x3020, expected_cycles: 20 },
                { opcode: 0xC0, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [CPU::ZERO_FLAG], expected_sp: 0xFFFC, expected_program_counter: 0x4001, expected_cycles: 8 },
                { opcode: 0xC8, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [CPU::ZERO_FLAG], expected_sp: 0xFFFE, expected_program_counter: 0x3020, expected_cycles: 20 },
                { opcode: 0xC8, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [], expected_sp: 0xFFFC, expected_program_counter: 0x4001, expected_cycles: 8 },
                { opcode: 0xD0, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [], expected_sp: 0xFFFE, expected_program_counter: 0x3020, expected_cycles: 20 },
                { opcode: 0xD0, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [CPU::CARRY_FLAG], expected_sp: 0xFFFC, expected_program_counter: 0x4001, expected_cycles: 8 },
                { opcode: 0xD8, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [CPU::CARRY_FLAG], expected_sp: 0xFFFE, expected_program_counter: 0x3020, expected_cycles: 20 },
                { opcode: 0xD8, program_counter: 0x4000, memory_FFFC: 0x20, memory_FFFD: 0x30, sp: 0xFFFC, flags_set: [], expected_sp: 0xFFFC, expected_program_counter: 0x4001, expected_cycles: 8 }
            ]

            ret_cc_instructions.each do |inst|
                describe 'RET cc' do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.program_counter = inst[:program_counter]

                        subject.sp = inst[:sp]
                        memory[0xFFFC] = inst[:memory_FFFC]
                        memory[0xFFFD] = inst[:memory_FFFD]

                        inst[:flags_set].each do |flag|
                            subject.registers[:f] |= flag
                        end
                    end

                    it 'should set sp to expected value' do
                        subject.instruction data

                        _(subject.sp).must_equal(inst[:expected_sp]) 
                    end

                    it 'should set the program counter to expected value' do
                        subject.instruction data

                        _(subject.program_counter).must_equal inst[:expected_program_counter]
                    end

                    it 'should return correct amount of cycles used' do
                        cycles = subject.instruction data

                        _(cycles).must_equal(inst[:expected_cycles])
                    end
                end
            end
        end

        describe 'control' do
            describe 'NOP' do
                let(:data) { [0x00] }

                before do
                    subject.program_counter = 0x2001
                end

                it 'should set the program counter to expected value' do
                    subject.instruction data

                    _(subject.program_counter).must_equal 0x2002
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(4)
                end
            end

            describe 'DI' do
                let(:data) { [0xF3] }

                before do
                    subject.program_counter = 0x1001
                end

                it 'should set ime to false, but only after the next instruction executes' do
                    _(subject.disable_ime_next).must_equal false
                    subject.ime = true

                    subject.instruction data

                    _(subject.ime).must_equal true
                    _(subject.disable_ime_next).must_equal true

                    subject.instruction 0x00

                    _(subject.ime).must_equal false
                    _(subject.disable_ime_next).must_equal false
                end

                it 'should set the program counter to expected value' do
                    subject.instruction data

                    _(subject.program_counter).must_equal 0x1002
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(4)
                end
            end

            describe 'EI' do
                let(:data) { [0xFB] }

                before do
                    subject.program_counter = 0x1001
                end

                it 'should set ime to true, but only after the next instruction executes' do
                    _(subject.enable_ime_next).must_equal false
                    subject.ime = false

                    subject.instruction data

                    _(subject.ime).must_equal false
                    _(subject.enable_ime_next).must_equal true

                    subject.instruction 0x00

                    _(subject.ime).must_equal true
                    _(subject.enable_ime_next).must_equal false
                end

                it 'should set the program counter to expected value' do
                    subject.instruction data

                    _(subject.program_counter).must_equal 0x1002
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(4)
                end
            end
        end

        describe 'reset' do
            rst_instructions = [
                { opcode: 0xC7, program_counter: 0x1234, expected_program_counter: 0x0000, expected_memory_FFFC: 0x35, expected_memory_FFFD: 0x12 },
                { opcode: 0xCF, program_counter: 0x5678, expected_program_counter: 0x0008, expected_memory_FFFC: 0x79, expected_memory_FFFD: 0x56 },
                { opcode: 0xD7, program_counter: 0x9ABC, expected_program_counter: 0x0010, expected_memory_FFFC: 0xBD, expected_memory_FFFD: 0x9A },
                { opcode: 0xDF, program_counter: 0xDEAD, expected_program_counter: 0x0018, expected_memory_FFFC: 0xAE, expected_memory_FFFD: 0xDE },
                { opcode: 0xE7, program_counter: 0xBEEF, expected_program_counter: 0x0020, expected_memory_FFFC: 0xF0, expected_memory_FFFD: 0xBE },
                { opcode: 0xEF, program_counter: 0xCAFE, expected_program_counter: 0x0028, expected_memory_FFFC: 0xFF, expected_memory_FFFD: 0xCA },
                { opcode: 0xF7, program_counter: 0x1337, expected_program_counter: 0x0030, expected_memory_FFFC: 0x38, expected_memory_FFFD: 0x13 },
                { opcode: 0xFF, program_counter: 0xABCD, expected_program_counter: 0x0038, expected_memory_FFFC: 0xCE, expected_memory_FFFD: 0xAB },
            ]

            rst_instructions.each do |inst|
                describe 'RST n' do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.program_counter = inst[:program_counter]
                    end

                    it 'should update the memory correctly' do
                        subject.instruction data

                        _(subject.sp).must_equal(0xFFFC)
                        if (inst[:expected_memory_FFFC])
                            _(memory[0xFFFC]).must_equal(inst[:expected_memory_FFFC])
                        end
                        if (inst[:expected_memory_FFFD])
                            _(memory[0xFFFD]).must_equal(inst[:expected_memory_FFFD])
                        end
                    end

                    it 'should set the program counter to expected value' do
                        subject.instruction data

                        _(subject.program_counter).must_equal inst[:expected_program_counter]
                    end

                    it 'should return correct amount of cycles used' do
                        cycles = subject.instruction data

                        _(cycles).must_equal(16)
                    end
                end
            end
        end

        describe 'jump' do
            before do
                subject.program_counter = 0x00
            end

            describe 'to address' do
                let(:data) { [0xC3, 0x34, 0x12] }

                it 'should set program_counter to address' do
                    subject.instruction data

                    _(subject.program_counter).must_equal(0x1234)
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(16)
                end
            end

            describe 'to address, conditionally' do
                describe 'when condition NZ (not zero)' do
                    let(:data) { [0xC2, 0x34, 0x12] }

                    describe 'when zero flag is set' do
                        before do
                            subject.registers[:f] |= CPU::ZERO_FLAG
                        end

                        it 'should advance program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 3)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end

                    describe 'when zero flag is not set' do
                        it 'should set program_counter to address' do
                            subject.instruction data

                            _(subject.program_counter).must_equal(0x1234)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(16)
                        end
                    end
                end

                describe 'when condition Z (zero flag set)' do
                    let(:data) { [0xCA, 0x34, 0x12] }

                    describe 'when zero flag is not set' do
                        it 'should advance program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 3)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end

                    describe 'when zero flag is set' do
                        before do
                            subject.registers[:f] |= CPU::ZERO_FLAG
                        end

                        it 'should set program_counter to address' do
                            subject.instruction data

                            _(subject.program_counter).must_equal(0x1234)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(16)
                        end
                    end
                end
            
                describe 'when condition NC (no carry)' do
                    let(:data) { [0xD2, 0x34, 0x12] }

                    describe 'when carry flag is set' do
                        before do
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end

                        it 'should advance program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 3)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end

                    describe 'when carry flag is not set' do
                        it 'should set program_counter to address' do
                            subject.instruction data

                            _(subject.program_counter).must_equal(0x1234)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(16)
                        end
                    end
                end

                describe 'when condition C (carry)' do
                    let(:data) { [0xDA, 0x34, 0x12] }

                    describe 'when carry flag is not set' do
                        it 'should advance program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 3)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end

                    describe 'when carry flag is set' do
                        before do
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end

                        it 'should set program_counter to address' do
                            subject.instruction data

                            _(subject.program_counter).must_equal(0x1234)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(16)
                        end
                    end
                end
            end

            describe 'to HL register' do
                let(:data) { [0xE9] }
                
                before do
                    subject.registers[:h] = 0x12
                    subject.registers[:l] = 0x34
                end

                it 'should set program_counter to hl value' do
                    subject.instruction data

                    _(subject.program_counter).must_equal(0x1234)
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(4)
                end
            end

            describe 'relative to' do
                let(:data) { [0x18, 0xFE] }
                let(:program_counter_value) { 0x0100 }

                before do
                    subject.program_counter = program_counter_value
                end

                describe 'when moving forward' do
                    let(:data) { [0x18, 0x04] }

                    it 'should move program_counter correctly' do
                        subject.instruction data

                        _(subject.program_counter).must_equal(0x0106)
                    end
                end

                describe 'when moving backwards' do
                    let(:data) { [0x18, 0xFA] }

                    it 'should move program_counter correctly' do
                        subject.instruction data

                        _(subject.program_counter).must_equal(0x0FC)
                    end
                end

                it 'should return correct amount of cycles used' do
                    cycles = subject.instruction data

                    _(cycles).must_equal(12)
                end
            end

            describe 'relative to, conditionally' do
                let(:program_counter_value) { 0x0100 }

                before do
                    subject.program_counter = program_counter_value
                end

                describe 'when condition NZ (not zero)' do
                    let(:data) { [0x20, 0x04] }

                    describe 'when zero flag is set' do
                        before do
                            subject.registers[:f] |= CPU::ZERO_FLAG
                        end

                        it 'should move program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 2)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(8)
                        end
                    end

                    describe 'when zero flag is not set' do
                        describe 'when moving forward' do
                            let(:data) { [0x20, 0x04] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0106)
                            end
                        end

                        describe 'when moving backwards' do
                            let(:data) { [0x20, 0xFA] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0FC)
                            end
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end
                end

                describe 'when condition Z (zero flag set)' do
                    let(:data) { [0x28, 0x04] }

                    describe 'when zero flag is not set' do
                        it 'should move program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 2)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(8)
                        end
                    end

                    describe 'when zero flag is not set' do
                        before do
                            subject.registers[:f] |= CPU::ZERO_FLAG
                        end

                        describe 'when moving forward' do
                            let(:data) { [0x28, 0x04] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0106)
                            end
                        end

                        describe 'when moving backwards' do
                            let(:data) { [0x28, 0xFA] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0FC)
                            end
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end
                end

                describe 'when condition NC (no carry)' do
                    let(:data) { [0x30, 0x04] }

                    describe 'when carry flag is set' do
                        before do
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end

                        it 'should move program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 2)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(8)
                        end
                    end

                    describe 'when carry flag is not set' do
                        describe 'when moving forward' do
                            let(:data) { [0x30, 0x04] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0106)
                            end
                        end

                        describe 'when moving backwards' do
                            let(:data) { [0x30, 0xFA] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0FC)
                            end
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end
                end

                describe 'when condition C (carry flag set)' do
                    let(:data) { [0x38, 0x04] }

                    describe 'when carry flag is not set' do
                        it 'should move program_counter to next instruction' do
                            before = subject.program_counter

                            subject.instruction data

                            _(subject.program_counter).must_equal(before + 2)
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(8)
                        end
                    end

                    describe 'when carry flag is set' do
                        before do
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end

                        describe 'when moving forward' do
                            let(:data) { [0x38, 0x04] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0106)
                            end
                        end

                        describe 'when moving backwards' do
                            let(:data) { [0x38, 0xFA] }

                            it 'should move program_counter correctly' do
                                subject.instruction data

                                _(subject.program_counter).must_equal(0x0FC)
                            end
                        end

                        it 'should return correct amount of cycles used' do
                            cycles = subject.instruction data

                            _(cycles).must_equal(12)
                        end
                    end
                end
            end
        end

        describe 'load' do
            ld_r1_r2_instructions = [
              { destination: :a, source: :b, source_value: 0x50, opcode: 0x78 },
              { destination: :a, source: :c, source_value: 0x51, opcode: 0x79 },
              { destination: :a, source: :d, source_value: 0x52, opcode: 0x7A },
              { destination: :a, source: :e, source_value: 0x53, opcode: 0x7B },
              { destination: :a, source: :h, source_value: 0x54, opcode: 0x7C },
              { destination: :a, source: :l, source_value: 0x55, opcode: 0x7D },

              { destination: :b, source: :a, source_value: 0x50, opcode: 0x47 },
              { destination: :b, source: :c, source_value: 0x51, opcode: 0x41 },
              { destination: :b, source: :d, source_value: 0x52, opcode: 0x42 },
              { destination: :b, source: :e, source_value: 0x53, opcode: 0x43 },
              { destination: :b, source: :h, source_value: 0x54, opcode: 0x44 },
              { destination: :b, source: :l, source_value: 0x55, opcode: 0x45 },

              { destination: :c, source: :a, source_value: 0x50, opcode: 0x4F },
              { destination: :c, source: :b, source_value: 0x51, opcode: 0x48 },
              { destination: :c, source: :d, source_value: 0x52, opcode: 0x4A },
              { destination: :c, source: :e, source_value: 0x53, opcode: 0x4B },
              { destination: :c, source: :h, source_value: 0x54, opcode: 0x4C },
              { destination: :c, source: :l, source_value: 0x55, opcode: 0x4D },

              { destination: :d, source: :a, source_value: 0x50, opcode: 0x57 },
              { destination: :d, source: :b, source_value: 0x51, opcode: 0x50 },
              { destination: :d, source: :c, source_value: 0x52, opcode: 0x51 },
              { destination: :d, source: :e, source_value: 0x53, opcode: 0x53 },
              { destination: :d, source: :h, source_value: 0x54, opcode: 0x54 },
              { destination: :d, source: :l, source_value: 0x55, opcode: 0x55 },

              { destination: :e, source: :a, source_value: 0x50, opcode: 0x5F },
              { destination: :e, source: :b, source_value: 0x51, opcode: 0x58 },
              { destination: :e, source: :c, source_value: 0x52, opcode: 0x59 },
              { destination: :e, source: :d, source_value: 0x53, opcode: 0x5A },
              { destination: :e, source: :h, source_value: 0x54, opcode: 0x5C },
              { destination: :e, source: :l, source_value: 0x55, opcode: 0x5D },

              { destination: :h, source: :a, source_value: 0x50, opcode: 0x67 },
              { destination: :h, source: :b, source_value: 0x51, opcode: 0x60 },
              { destination: :h, source: :c, source_value: 0x52, opcode: 0x61 },
              { destination: :h, source: :d, source_value: 0x53, opcode: 0x62 },
              { destination: :h, source: :e, source_value: 0x54, opcode: 0x63 },
              { destination: :h, source: :l, source_value: 0x55, opcode: 0x65 },

              { destination: :l, source: :a, source_value: 0x50, opcode: 0x6F },
              { destination: :l, source: :b, source_value: 0x51, opcode: 0x68 },
              { destination: :l, source: :c, source_value: 0x52, opcode: 0x69 },
              { destination: :l, source: :d, source_value: 0x53, opcode: 0x6A },
              { destination: :l, source: :e, source_value: 0x54, opcode: 0x6B },
              { destination: :l, source: :h, source_value: 0x55, opcode: 0x6C },
            ]

            ld_r1_r2_instructions.each do |inst|
              describe "ld #{inst[:destination]}, #{inst[:source]}" do
                let(:data) { [inst[:opcode]] }
                let(:source_value) { inst[:source_value] }

                before do
                  subject.registers[inst[:destination]] = 0x00
                  subject.registers[inst[:source]] = source_value
                end

                it "should copy register #{inst[:source]} to #{inst[:destination]}" do
                  subject.instruction data
                  _(subject.registers[inst[:destination]]).must_equal source_value
                  _(subject.registers[inst[:source]]).must_equal source_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  _(cycles).must_equal 4
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
              end
            end

            ld_r_n_instructions = [
                { destination: :a, value: 0x34, opcode: 0x3E },
                { destination: :b, value: 0x35, opcode: 0x06 },
                { destination: :c, value: 0x36, opcode: 0x0E },
                { destination: :d, value: 0x37, opcode: 0x16 },
                { destination: :e, value: 0x38, opcode: 0x1E },
                { destination: :h, value: 0x39, opcode: 0x26 },
                { destination: :l, value: 0x40, opcode: 0x2E }
            ]

            ld_r_n_instructions.each do |inst|
                describe "ld #{inst[:destination]}, #{inst[:value]}" do
                    let(:data) { [inst[:opcode], inst[:value]] }

                    before do
                      subject.registers[inst[:destination]] = 0x00
                    end

                    it "should copy value #{inst[:value]} to #{inst[:destination]}" do
                      subject.instruction data
                      _(subject.registers[inst[:destination]]).must_equal inst[:value]
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data
                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            ld_r_hl_instructions = [
                { destination: :a, hl_value: 0x1234, memory_value: 0x40, opcode: 0x7E },
                { destination: :b, hl_value: 0x1235, memory_value: 0x41, opcode: 0x46 },
                { destination: :c, hl_value: 0x1236, memory_value: 0x42, opcode: 0x4E },
                { destination: :d, hl_value: 0x1237, memory_value: 0x43, opcode: 0x56 },
                { destination: :e, hl_value: 0x1238, memory_value: 0x44, opcode: 0x5E },
                { destination: :h, hl_value: 0x1239, memory_value: 0x45, opcode: 0x66 },
                { destination: :l, hl_value: 0x1233, memory_value: 0x46, opcode: 0x6E }
            ]

            ld_r_hl_instructions.each do |inst|
                describe "ld #{inst[:destination]}, (HL)" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        memory[inst[:hl_value]] = inst[:memory_value]

                        subject.registers[:h] = Utils.get_hi(inst[:hl_value])
                        subject.registers[:l] = Utils.get_lo(inst[:hl_value])
                    end

                    it "should copy value of memory at address #{inst[:hl_value]} to #{inst[:destination]}" do
                        subject.instruction data

                        _(subject.registers[inst[:destination]]).must_equal(inst[:memory_value])
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data
                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            ld_hl_r_instructions = [
                { source: :a, register_value: 0x10, hl_value: 0x1000, opcode: 0x77 },
                { source: :b, register_value: 0x20, hl_value: 0x2020, opcode: 0x70 },
                { source: :c, register_value: 0x30, hl_value: 0x3112, opcode: 0x71 },
                { source: :d, register_value: 0x35, hl_value: 0x4406, opcode: 0x72 },
                { source: :e, register_value: 0x42, hl_value: 0x5625, opcode: 0x73 },
                { source: :h, register_value: 0x60, hl_value: 0x6011, opcode: 0x74 },
                { source: :l, register_value: 0xCF, hl_value: 0x7BCF, opcode: 0x75 }
            ]

            ld_hl_r_instructions.each do |inst|
                describe "ld (HL), #{inst[:destination]}" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:register_value]
                        subject.registers[:h] = Utils.get_hi(inst[:hl_value])
                        subject.registers[:l] = Utils.get_lo(inst[:hl_value])
                    end

                    it "should copy value of register #{inst[:source]} (#{inst[:register_value]}) to memory at address #{inst[:hl_value]}" do
                        subject.instruction data

                        _(memory[inst[:hl_value]]).must_equal(inst[:register_value])
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data
                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            ld_hl_n_instructions = [
                { hl_value: 0x1234, value_to_store: 0x11, opcode: 0x36 },
                { hl_value: 0x00FE, value_to_store: 0xC8, opcode: 0x36 }
            ]

            ld_hl_n_instructions.each do |inst|
                describe "ld (HL), n" do
                    let(:data) { [inst[:opcode], inst[:value_to_store]] }

                    before do
                        subject.registers[:h] = Utils.get_hi(inst[:hl_value])
                        subject.registers[:l] = Utils.get_lo(inst[:hl_value])
                    end

                    it "should set value at memory address #{inst[:hl_value]} to #{inst[:value_to_store]}" do
                        subject.instruction data

                        _(memory[inst[:hl_value]]).must_equal(inst[:value_to_store])
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data
                      _(cycles).must_equal 12
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            describe 'ld (0xFF00 + n), A' do
                let(:a_value) { 0xBE }
                let(:n_value) { 0x0A }
                let(:data) { [0xE0, n_value] }

                before do 
                    subject.registers[:a] = a_value
                end

                it "should load value from register A into memory address 0xFF00 + n" do
                    subject.instruction data

                    _(memory[0xFF00 + n_value]).must_equal a_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 12
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x102)
                end
            end

            describe 'ld A, (0xFF00 + n)' do
                let(:memory_value) { 0xF2 }
                let(:n_value) { 0x1C }
                let(:data) { [0xF0, n_value] }

                before do 
                    memory[0xFF1C] = memory_value
                end

                it "should load value from memory address 0xFF00 + n into register A" do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal memory_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  
                  _(cycles).must_equal 12
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x102)
                end
            end

            describe "ld A, (BC)" do
                let(:memory_value) { 0xF2 }
                let(:bc) { 0x1090 }
                let(:data) { [0x0A] }

                before do
                    memory[bc] = memory_value

                    subject.registers[:b] = Utils.get_hi(bc)
                    subject.registers[:c] = Utils.get_lo(bc)
                end

                it "should load value at memory address BC into register A" do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal memory_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe "ld A, (DE)" do
                let(:memory_value) { 0x15 }
                let(:de) { 0xFE9A }
                let(:data) { [0x1A] }

                before do
                    memory[de] = memory_value

                    subject.registers[:d] = Utils.get_hi(de)
                    subject.registers[:e] = Utils.get_lo(de)
                end

                it "should load value at memory address DE into register A" do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal memory_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe "ld (BC), A" do
                let(:a_value) { 0xFD }
                let(:bc) { 0x91BB }
                let(:data) { [0x02]}

                before do
                    subject.registers[:a] = a_value
                    subject.registers[:b] = Utils.get_hi bc
                    subject.registers[:c] = Utils.get_lo bc
                end

                it 'store value of A into memory address of BC' do
                    subject.instruction data

                    _(memory[bc]).must_equal a_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe "ld (DE), A" do
                let(:a_value) { 0x94 }
                let(:de) { 0x1AAC }
                let(:data) { [0x12]}

                before do
                    subject.registers[:a] = a_value
                    subject.registers[:d] = Utils.get_hi de
                    subject.registers[:e] = Utils.get_lo de
                end

                it 'store value of A into memory address of DE' do
                    subject.instruction data

                    _(memory[de]).must_equal a_value
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ld A, (nn)' do
                let(:memory_value) { 0xF2 }
                let(:data) { [0xFA, 0x15, 0x23]}

                before do
                    memory[0x2315] = memory_value
                end

                it 'should load the memory value at the specified address into the A register' do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal(memory_value)
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data
                  _(cycles).must_equal 16
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x103)
                end
            end

            describe 'ld (nn), A' do
                let(:a_value) { 0x7A }
                let(:data) { [0xEA, 0x11, 0x22] }

                before do
                    subject.registers[:a] = a_value
                end

                it 'should store the value in register A into the memory address nn' do
                    subject.instruction data

                    _(memory[0x2211]).must_equal(a_value)
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 16
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x103)
                end
            end

            describe 'ld A, (C)' do
                let(:memory_value) { 0xAB }
                let(:c_value) { 0xE1 }
                let(:data) { [0xF2]}

                before do
                    memory[0xFF00 + c_value] = memory_value

                    subject.registers[:c] = c_value
                end

                it 'should load the value at the address 0xFF00 + C into the A register' do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal(memory_value)
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ld (C), A' do
                let(:a_value) { 0xBB }
                let(:c_value) { 0x01 }
                let(:data) { [0xE2] }

                before do
                    subject.registers[:a] = a_value
                    subject.registers[:c] = c_value
                end

                it 'should store the value of the A register into the IO memory address 0xFF00 + C' do
                    subject.instruction data

                    _(memory[0xFF00 + 0x01]).must_equal(a_value)
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ldd A, (HL)' do
                let(:h_value) { 0xC0 }
                let(:l_value) { 0x00 }
                let(:memory_value) { 0xBF }
                let(:data) { [0x3A] }

                before do
                    subject.registers[:h] = h_value
                    subject.registers[:l] = l_value
                    memory[0xC000] = memory_value
                end

                it 'should load the value from the memory location pointed by HL into register A' do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal memory_value
                end

                it 'should decrement HL by 1' do
                    subject.instruction data

                    _(subject.registers[:h]).must_equal 0xBF
                    _(subject.registers[:l]).must_equal 0xFF
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ldd (HL), A' do
                let(:h_value) { 0xC0 }
                let(:l_value) { 0x00 }
                let(:a_value) { 0xBF }
                let(:data) { [0x32] }

                before do
                    subject.registers[:h] = h_value
                    subject.registers[:l] = l_value
                    subject.registers[:a] = a_value
                end

                it 'should store the value in register A into the memory address pointed by HL' do
                    subject.instruction data

                    _(memory[0xC000]).must_equal a_value
                end

                it 'should decrement HL by 1' do
                    subject.instruction data

                    _(subject.registers[:h]).must_equal 0xBF
                    _(subject.registers[:l]).must_equal 0xFF
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ldi A, (HL)' do
                let(:h_value) { 0xC0 }
                let(:l_value) { 0x00 }
                let(:memory_value) { 0x42 }
                let(:data) { [0x2A] }

                before do
                    subject.registers[:h] = h_value
                    subject.registers[:l] = l_value
                    memory[0xC000] = memory_value
                end

                it 'should load the value from the memory location pointed by HL into register A' do
                    subject.instruction data

                    _(subject.registers[:a]).must_equal memory_value
                end

                it 'should increment HL by 1' do
                    subject.instruction data

                    _(subject.registers[:h]).must_equal 0xC0
                    _(subject.registers[:l]).must_equal 0x01
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ldi (HL), A' do
                let(:h_value) { 0xC0 }
                let(:l_value) { 0x00 }
                let(:a_value) { 0xBF }
                let(:data) { [0x22] }

                before do
                    subject.registers[:h] = h_value
                    subject.registers[:l] = l_value
                    subject.registers[:a] = a_value
                end

                it 'should store the value in register A into the memory address pointed by HL' do
                    subject.instruction data

                    _(memory[0xC000]).must_equal a_value
                end

                it 'should decrement HL by 1' do
                    subject.instruction data

                    _(subject.registers[:h]).must_equal 0xC0
                    _(subject.registers[:l]).must_equal 0x01
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe 'ld (nn), SP' do
                let(:sp_value) { 0xDFF0 }
                let(:data) { [0x08, 0x01, 0x20] }

                before do
                    subject.sp = sp_value
                end

                it 'should store the current value of SP into the memory at address nn' do
                    subject.instruction data

                    _(memory[0x2001]).must_equal(0xF0)
                    _(memory[0x2002]).must_equal(0xDF)
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 20
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x103)
                end
            end

            describe 'ld SP, HL' do
                let(:data) { [0xF9] }

                before do
                    subject.registers[:h] = 0x12
                    subject.registers[:l] = 0x34
                end

                it 'should set SP to the value in HL' do
                    subject.instruction data

                    _(subject.sp).must_equal(0x1234)
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 8
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            ld_rr_nn_instructions = [
                { destination1: :b, destination2: :c, opcode: 0x01 },
                { destination1: :d, destination2: :e, opcode: 0x11 },
                { destination1: :h, destination2: :l, opcode: 0x21 }
            ]

            ld_rr_nn_instructions.each do |inst|
                describe "ld #{inst[:destination1]}#{inst[:destination2]}, nn" do
                    let(:hi) { 0x12 }
                    let(:lo) { 0x34 }
                    let(:data) { [inst[:opcode], lo, hi] }

                    it 'should load the value into the correct register pair' do
                        subject.instruction data

                        _(subject.registers[inst[:destination1]]).must_equal hi
                        _(subject.registers[inst[:destination2]]).must_equal lo
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 12
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x103)
                    end
                end
            end

            describe "ld SP, nn" do
                let(:hi) { 0x12 }
                let(:lo) { 0x34 }
                let(:data) { [0x31, lo, hi] }

                it 'should load the value into SP' do
                    subject.instruction data

                    _(subject.sp).must_equal 0x1234
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 12
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x103)
                end
            end

            describe "ldhl sp, n" do
                let(:sp_value) { 0xFF00 }
                let(:data) { [0xF8, 0x10] }

                before do
                    subject.sp = sp_value
                end

                it 'should load a value into the HL register by adding a signed value to the SP' do
                    subject.instruction data

                    _(subject.registers[:h]).must_equal 0xFF
                    _(subject.registers[:l]).must_equal 0x10
                end

                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 12
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x102)
                end
            end

            push_rr_instructions = [
                { source1: :b, source2: :c, opcode: 0xC5 },
                { source1: :d, source2: :e, opcode: 0xD5 },
                { source1: :h, source2: :l, opcode: 0xE5 },
                { source1: :a, source2: :f, opcode: 0xF5 }
            ]

            push_rr_instructions.each do |inst| 
                describe "push #{inst[:source1]}#{inst[:source2]}" do
                    let(:data) { [inst[:opcode]]}

                    before do
                        subject.registers[inst[:source1]] = 0x12
                        subject.registers[inst[:source2]] = 0x34

                        subject.sp = 0xFFFE
                    end

                    it 'should push value from register pair onto the stack' do
                        subject.instruction data

                        _(memory[0xFFFC]).must_equal(0x12)
                        _(memory[0xFFFD]).must_equal(0x34)
                        _(subject.sp).must_equal(0xFFFC) 

                        subject.instruction data

                        _(memory[0xFFFA]).must_equal(0x12)
                        _(memory[0xFFFB]).must_equal(0x34)
                        _(subject.sp).must_equal(0xFFFA) 
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 16
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            pop_rr_instructions = [
                { destination1: :b, destination2: :c, opcode: 0xC1 },
                { destination1: :d, destination2: :e, opcode: 0xD1 },
                { destination1: :h, destination2: :l, opcode: 0xE1 },
                { destination1: :a, destination2: :f, opcode: 0xF1 }
            ]

            pop_rr_instructions.each do |inst| 
                describe "pop #{inst[:destination1]}#{inst[:destination2]}" do
                    let(:data) { [inst[:opcode]]}

                    before do
                        memory[0xFFFA] = 0x12
                        memory[0xFFFB] = 0x34
                        memory[0xFFFC] = 0x56
                        memory[0xFFFD] = 0x78
                        subject.sp = 0xFFFA
                    end

                    it 'should pop value from register pair onto the stack' do
                        subject.instruction data

                        _(subject.registers[inst[:destination1]]).must_equal 0x12
                        _(subject.registers[inst[:destination2]]).must_equal 0x34
                        _(subject.sp).must_equal(0xFFFC) 
                        # the stack shouldn't be cleared even if we pop values from it:
                        _(memory[0xFFFA]).must_equal(0x12) 
                        _(memory[0xFFFB]).must_equal(0x34)
                        _(memory[0xFFFC]).must_equal(0x56)
                        _(memory[0xFFFD]).must_equal(0x78)

                        subject.instruction data

                        _(subject.registers[inst[:destination1]]).must_equal 0x56
                        _(subject.registers[inst[:destination2]]).must_equal 0x78
                        _(memory[0xFFFA]).must_equal(0x12) 
                        _(memory[0xFFFB]).must_equal(0x34)
                        _(memory[0xFFFC]).must_equal(0x56)
                        _(memory[0xFFFD]).must_equal(0x78)
                        _(subject.sp).must_equal(0xFFFE) 
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 12
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end
        end

        describe 'arithmetic' do
            add_a_r_instructions = [
                { source: :a, source_value: 0x04, a_value: 0x04, opcode: 0x87, expected_a_value_after_op: 0x08, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x00, a_value: 0x00, opcode: 0x80, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x01, a_value: 0x0F, opcode: 0x80, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x10, a_value: 0xF0, opcode: 0x80, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :b, source_value: 0x10, a_value: 0xF5, opcode: 0x80, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :c, source_value: 0x00, a_value: 0x00, opcode: 0x81, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x02, a_value: 0x0E, opcode: 0x81, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x10, a_value: 0xF0, opcode: 0x81, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :c, source_value: 0x10, a_value: 0xF5, opcode: 0x81, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :d, source_value: 0x00, a_value: 0x00, opcode: 0x82, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x03, a_value: 0x0E, opcode: 0x82, expected_a_value_after_op: 0x11, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x10, a_value: 0xF0, opcode: 0x82, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :d, source_value: 0x10, a_value: 0xF5, opcode: 0x82, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :e, source_value: 0x00, a_value: 0x00, opcode: 0x83, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x05, a_value: 0x0E, opcode: 0x83, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x10, a_value: 0xF0, opcode: 0x83, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :e, source_value: 0x10, a_value: 0xF5, opcode: 0x83, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :h, source_value: 0x00, a_value: 0x00, opcode: 0x84, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x05, a_value: 0x0E, opcode: 0x84, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x10, a_value: 0xF0, opcode: 0x84, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :h, source_value: 0x10, a_value: 0xF5, opcode: 0x84, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :l, source_value: 0x00, a_value: 0x00, opcode: 0x85, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x05, a_value: 0x0E, opcode: 0x85, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x10, a_value: 0xF0, opcode: 0x85, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :l, source_value: 0x10, a_value: 0xF5, opcode: 0x85, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            add_a_r_instructions.each do |inst|
                describe "add A, #{inst[:source]}" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should add the value in #{inst[:source]} register to A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            add_a_hl_instructions = [
                { source_value: 0x00, a_value: 0x00, opcode: 0x86, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source_value: 0x01, a_value: 0x0F, opcode: 0x86, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source_value: 0x10, a_value: 0xF0, opcode: 0x86, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { source_value: 0x10, a_value: 0xF5, opcode: 0x86, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            add_a_hl_instructions.each do |inst|
                describe "add A, (HL)" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]
                        memory[0x1234] = inst[:source_value]
                    end

                    it "should add the value in the memory address pointed to by HL register to A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            add_a_n_instructions = [
                { value: 0x00, a_value: 0x00, opcode: 0xC6, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { value: 0x01, a_value: 0x0F, opcode: 0xC6, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { value: 0x10, a_value: 0xF0, opcode: 0xC6, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { value: 0x10, a_value: 0xF5, opcode: 0xC6, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            add_a_n_instructions.each do |inst|
                describe "add A, n" do
                    let(:data) { [inst[:opcode], inst[:value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should add the value n to A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            adc_a_r_instructions = [
                { carry_flag: false, source: :a, source_value: 0x04, a_value: 0x04, opcode: 0x8F, expected_a_value_after_op: 0x08, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x00, a_value: 0x00, opcode: 0x88, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x01, a_value: 0x0F, opcode: 0x88, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x10, a_value: 0xF0, opcode: 0x88, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x10, a_value: 0xF5, opcode: 0x88, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x00, a_value: 0x00, opcode: 0x89, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x02, a_value: 0x0E, opcode: 0x89, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x10, a_value: 0xF0, opcode: 0x89, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x10, a_value: 0xF5, opcode: 0x89, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x00, a_value: 0x00, opcode: 0x8A, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x03, a_value: 0x0E, opcode: 0x8A, expected_a_value_after_op: 0x11, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x10, a_value: 0xF0, opcode: 0x8A, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x10, a_value: 0xF5, opcode: 0x8A, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x00, a_value: 0x00, opcode: 0x8B, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x05, a_value: 0x0E, opcode: 0x8B, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x10, a_value: 0xF0, opcode: 0x8B, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x10, a_value: 0xF5, opcode: 0x8B, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x00, a_value: 0x00, opcode: 0x8C, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x05, a_value: 0x0E, opcode: 0x8C, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x10, a_value: 0xF0, opcode: 0x8C, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x10, a_value: 0xF5, opcode: 0x8C, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x00, a_value: 0x00, opcode: 0x8D, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x05, a_value: 0x0E, opcode: 0x8D, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x10, a_value: 0xF0, opcode: 0x8D, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x10, a_value: 0xF5, opcode: 0x8D, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :a, source_value: 0x04, a_value: 0x04, opcode: 0x8F, expected_a_value_after_op: 0x09, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x00, a_value: 0x00, opcode: 0x88, expected_a_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x00, a_value: 0x0F, opcode: 0x88, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x0F, a_value: 0xF0, opcode: 0x88, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x0F, a_value: 0xF5, opcode: 0x88, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x01, a_value: 0x00, opcode: 0x89, expected_a_value_after_op: 0x02, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x01, a_value: 0x0E, opcode: 0x89, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x0F, a_value: 0xF0, opcode: 0x89, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x10, a_value: 0xF4, opcode: 0x89, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x01, a_value: 0x00, opcode: 0x8A, expected_a_value_after_op: 0x02, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x02, a_value: 0x0E, opcode: 0x8A, expected_a_value_after_op: 0x11, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x0F, a_value: 0xF0, opcode: 0x8A, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x10, a_value: 0xF4, opcode: 0x8A, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x00, a_value: 0x00, opcode: 0x8B, expected_a_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x04, a_value: 0x0E, opcode: 0x8B, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x0F, a_value: 0xF0, opcode: 0x8B, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x10, a_value: 0xF4, opcode: 0x8B, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x00, a_value: 0x00, opcode: 0x8C, expected_a_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x04, a_value: 0x0E, opcode: 0x8C, expected_a_value_after_op: 0x13, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x0F, a_value: 0xF0, opcode: 0x8C, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x10, a_value: 0xF4, opcode: 0x8C, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x00, a_value: 0x00, opcode: 0x8D, expected_a_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x05, a_value: 0x0E, opcode: 0x8D, expected_a_value_after_op: 0x14, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x0F, a_value: 0xF0, opcode: 0x8D, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x10, a_value: 0xF5, opcode: 0x8D, expected_a_value_after_op: 0x06, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            adc_a_r_instructions.each do |inst|
                describe "adc A, #{inst[:source]}" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]

                        if (inst[:carry_flag])
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end
                    end

                    it "should add the value in #{inst[:source]} register + #{inst[:carry_flag] ? 1 : 0} to A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            adc_a_hl_instructions = [
                { carry_flag: false, source_value: 0x00, a_value: 0x00, opcode: 0x8E, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source_value: 0x01, a_value: 0x0F, opcode: 0x8E, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source_value: 0x10, a_value: 0xF0, opcode: 0x8E, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, source_value: 0x10, a_value: 0xF5, opcode: 0x8E, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source_value: 0x00, a_value: 0x00, opcode: 0x8E, expected_a_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source_value: 0x00, a_value: 0x0F, opcode: 0x8E, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source_value: 0x0F, a_value: 0xF0, opcode: 0x8E, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, source_value: 0x0F, a_value: 0xF5, opcode: 0x8E, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG] },
            ]

            adc_a_hl_instructions.each do |inst|
                describe "adc A, (HL)" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]

                        memory[0x1234] = inst[:source_value]

                        if (inst[:carry_flag])
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end
                    end

                    it "should add the value in the memory address pointed to by HL register to A + #{inst[:carry_flag] ? 1 : 0}" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            adc_a_n_instructions = [
                { carry_flag: false, value: 0x00, a_value: 0x00, opcode: 0xCE, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, value: 0x01, a_value: 0x0F, opcode: 0xCE, expected_a_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, value: 0x10, a_value: 0xF0, opcode: 0xCE, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG] },
                { carry_flag: false, value: 0x10, a_value: 0xF5, opcode: 0xCE, expected_a_value_after_op: 0x05, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, value: 0x00, a_value: 0x00, opcode: 0xCE, expected_a_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, value: 0x01, a_value: 0x0F, opcode: 0xCE, expected_a_value_after_op: 0x11, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, value: 0x0F, a_value: 0xF0, opcode: 0xCE, expected_a_value_after_op: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG] },
                { carry_flag: true, value: 0x10, a_value: 0xF5, opcode: 0xCE, expected_a_value_after_op: 0x06, flags_set: [CPU::CARRY_FLAG], flags_unset: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            adc_a_n_instructions.each do |inst|
                describe "adc A, n" do
                    let(:data) { [inst[:opcode], inst[:value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]

                        if (inst[:carry_flag])
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end
                    end

                    it "should add the value n to A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            sub_r_instructions = [
                { source: :a, source_value: 0x04, a_value: 0x04, opcode: 0x97, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0x10, opcode: 0x90, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :b, source_value: 0x01, a_value: 0x00, opcode: 0x90, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :b, source_value: 0x10, a_value: 0x00, opcode: 0x90, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :b, source_value: 0x10, a_value: 0x20, opcode: 0x90, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x10, a_value: 0x10, opcode: 0x90, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0x10, opcode: 0x91, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :c, source_value: 0x01, a_value: 0x00, opcode: 0x91, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :c, source_value: 0x10, a_value: 0x00, opcode: 0x91, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :c, source_value: 0x10, a_value: 0x20, opcode: 0x91, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x10, a_value: 0x10, opcode: 0x91, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0x10, opcode: 0x92, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :d, source_value: 0x01, a_value: 0x00, opcode: 0x92, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :d, source_value: 0x10, a_value: 0x00, opcode: 0x92, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :d, source_value: 0x10, a_value: 0x20, opcode: 0x92, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x10, a_value: 0x10, opcode: 0x92, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0x10, opcode: 0x93, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :e, source_value: 0x01, a_value: 0x00, opcode: 0x93, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :e, source_value: 0x10, a_value: 0x00, opcode: 0x93, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :e, source_value: 0x10, a_value: 0x20, opcode: 0x93, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x10, a_value: 0x10, opcode: 0x93, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0x10, opcode: 0x94, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :h, source_value: 0x01, a_value: 0x00, opcode: 0x94, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :h, source_value: 0x10, a_value: 0x00, opcode: 0x94, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :h, source_value: 0x10, a_value: 0x20, opcode: 0x94, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x10, a_value: 0x10, opcode: 0x94, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0x10, opcode: 0x95, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :l, source_value: 0x01, a_value: 0x00, opcode: 0x95, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :l, source_value: 0x10, a_value: 0x00, opcode: 0x95, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source: :l, source_value: 0x10, a_value: 0x20, opcode: 0x95, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x10, a_value: 0x10, opcode: 0x95, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
            ]

            sub_r_instructions.each do |inst|
                describe "sub #{inst[:source]}" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should subtract the value in #{inst[:source]} register from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            sub_a_hl_instructions = [
                { source_value: 0x10, a_value: 0x20, opcode: 0x96, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source_value: 0x20, a_value: 0x20, opcode: 0x96, expected_a_value_after_op: 0x00, flags_set: [CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source_value: 0x05, a_value: 0x10, opcode: 0x96, expected_a_value_after_op: 0x0B, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { source_value: 0x30, a_value: 0x10, opcode: 0x96, expected_a_value_after_op: 0xE0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { source_value: 0x0F, a_value: 0x10, opcode: 0x96, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            sub_a_hl_instructions.each do |inst|
                describe "sub (HL)" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]
                        memory[0x1234] = inst[:source_value]
                    end

                    it "should subtract the value in the memory address pointed to by HL register from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            sub_n_instructions = [
                { n_value: 0x0F, a_value: 0x10, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::ZERO_FLAG] },
                { n_value: 0x01, a_value: 0x00, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { n_value: 0x10, a_value: 0x00, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { n_value: 0x10, a_value: 0x20, expected_a_value_after_op: 0x10, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0x10, a_value: 0x10, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
            ]

            sub_n_instructions.each do |inst|
                describe "sub N" do
                    let(:data) { [0xD6, inst[:n_value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should subtract the value #{inst[:n_value]} from A (#{inst[:a_value]})" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            sbc_a_r_instructions = [
                { carry_flag: false, source: :a, source_value: 0x04, a_value: 0x04, opcode: 0x9F, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :a, source_value: 0x04, a_value: 0x04, opcode: 0x9F, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x00, a_value: 0x00, opcode: 0x98, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x0F, a_value: 0x10, opcode: 0x98, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x01, a_value: 0x00, opcode: 0x98, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :b, source_value: 0x10, a_value: 0x00, opcode: 0x98, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x01, a_value: 0x02, opcode: 0x98, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0xFF, a_value: 0x01, opcode: 0x98, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x01, a_value: 0x03, opcode: 0x98, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x02, a_value: 0x03, opcode: 0x98, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x0F, a_value: 0x1F, opcode: 0x98, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x80, a_value: 0x00, opcode: 0x98, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x02, a_value: 0x02, opcode: 0x98, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :b, source_value: 0x10, a_value: 0x01, opcode: 0x98, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x00, a_value: 0x00, opcode: 0x99, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x0F, a_value: 0x10, opcode: 0x99, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x01, a_value: 0x00, opcode: 0x99, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :c, source_value: 0x10, a_value: 0x00, opcode: 0x99, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x01, a_value: 0x02, opcode: 0x99, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :c, source_value: 0xFF, a_value: 0x01, opcode: 0x99, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x01, a_value: 0x03, opcode: 0x99, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x02, a_value: 0x03, opcode: 0x99, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x0F, a_value: 0x1F, opcode: 0x99, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x80, a_value: 0x00, opcode: 0x99, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x02, a_value: 0x02, opcode: 0x99, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :c, source_value: 0x10, a_value: 0x01, opcode: 0x99, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x00, a_value: 0x00, opcode: 0x9A, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x0F, a_value: 0x10, opcode: 0x9A, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x01, a_value: 0x00, opcode: 0x9A, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :d, source_value: 0x10, a_value: 0x00, opcode: 0x9A, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x01, a_value: 0x02, opcode: 0x9A, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :d, source_value: 0xFF, a_value: 0x01, opcode: 0x9A, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x01, a_value: 0x03, opcode: 0x9A, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x02, a_value: 0x03, opcode: 0x9A, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x0F, a_value: 0x1F, opcode: 0x9A, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x80, a_value: 0x00, opcode: 0x9A, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x02, a_value: 0x02, opcode: 0x9A, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :d, source_value: 0x10, a_value: 0x01, opcode: 0x9A, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x00, a_value: 0x00, opcode: 0x9B, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x0F, a_value: 0x10, opcode: 0x9B, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x01, a_value: 0x00, opcode: 0x9B, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :e, source_value: 0x10, a_value: 0x00, opcode: 0x9B, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x01, a_value: 0x02, opcode: 0x9B, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :e, source_value: 0xFF, a_value: 0x01, opcode: 0x9B, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x01, a_value: 0x03, opcode: 0x9B, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x02, a_value: 0x03, opcode: 0x9B, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x0F, a_value: 0x1F, opcode: 0x9B, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x80, a_value: 0x00, opcode: 0x9B, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x02, a_value: 0x02, opcode: 0x9B, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :e, source_value: 0x10, a_value: 0x01, opcode: 0x9B, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x00, a_value: 0x00, opcode: 0x9C, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x0F, a_value: 0x10, opcode: 0x9C, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x01, a_value: 0x00, opcode: 0x9C, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :h, source_value: 0x10, a_value: 0x00, opcode: 0x9C, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x01, a_value: 0x02, opcode: 0x9C, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :h, source_value: 0xFF, a_value: 0x01, opcode: 0x9C, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x01, a_value: 0x03, opcode: 0x9C, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x02, a_value: 0x03, opcode: 0x9C, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x0F, a_value: 0x1F, opcode: 0x9C, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x80, a_value: 0x00, opcode: 0x9C, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x02, a_value: 0x02, opcode: 0x9C, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :h, source_value: 0x10, a_value: 0x01, opcode: 0x9C, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x00, a_value: 0x00, opcode: 0x9D, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x0F, a_value: 0x10, opcode: 0x9D, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x01, a_value: 0x00, opcode: 0x9D, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, source: :l, source_value: 0x10, a_value: 0x00, opcode: 0x9D, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x01, a_value: 0x02, opcode: 0x9D, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :l, source_value: 0xFF, a_value: 0x01, opcode: 0x9D, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x01, a_value: 0x03, opcode: 0x9D, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x02, a_value: 0x03, opcode: 0x9D, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x0F, a_value: 0x1F, opcode: 0x9D, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x80, a_value: 0x00, opcode: 0x9D, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x02, a_value: 0x02, opcode: 0x9D, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, source: :l, source_value: 0x10, a_value: 0x01, opcode: 0x9D, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            sbc_a_r_instructions.each do |inst|
                describe "SBC A, #{inst[:source]}" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]

                        if (inst[:carry_flag])
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end
                    end

                    it "should subtract the value in (#{inst[:source]} register + #{inst[:carry_flag] ? 1 : 0}) from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            sbc_a_hl_instructions = [
                { carry_flag: false, hl_value: 0x00, a_value: 0x00, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, hl_value: 0x0F, a_value: 0x10, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, hl_value: 0x01, a_value: 0x00, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, hl_value: 0x10, a_value: 0x00, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, hl_value: 0x01, a_value: 0x02, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, hl_value: 0xFF, a_value: 0x01, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, hl_value: 0x01, a_value: 0x03, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, hl_value: 0x02, a_value: 0x03, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, hl_value: 0x0F, a_value: 0x1F, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, hl_value: 0x80, a_value: 0x00, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, hl_value: 0x02, a_value: 0x02, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, hl_value: 0x10, a_value: 0x01, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            sbc_a_hl_instructions.each do |inst|
                describe "SBC A, (HL)" do
                    let(:data) { [0x9E] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]
                        memory[0x1234] = inst[:hl_value]

                        if (inst[:carry_flag])
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end
                    end

                    it "should subtract the value in the memory address pointed to by HL + #{inst[:carry_flag] ? 1 : 0} from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            sbc_a_n_instructions = [
                { carry_flag: false, n_value: 0x00, a_value: 0x00, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, n_value: 0x0F, a_value: 0x10, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: false, n_value: 0x01, a_value: 0x00, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: false, n_value: 0x10, a_value: 0x00, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
                { carry_flag: true, n_value: 0x01, a_value: 0x02, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, n_value: 0xFF, a_value: 0x01, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, n_value: 0x01, a_value: 0x03, expected_a_value_after_op: 0x01, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, n_value: 0x02, a_value: 0x03, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, n_value: 0x0F, a_value: 0x1F, expected_a_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { carry_flag: true, n_value: 0x80, a_value: 0x00, expected_a_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, n_value: 0x02, a_value: 0x02, expected_a_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { carry_flag: true, n_value: 0x10, a_value: 0x01, expected_a_value_after_op: 0xF0, flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            sbc_a_n_instructions.each do |inst|
                describe "SBC A, n" do
                    let(:data) { [0xDE, inst[:n_value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]

                        if (inst[:carry_flag])
                            subject.registers[:f] |= CPU::CARRY_FLAG
                        end
                    end

                    it "should subtract the value (#{inst[:n_value]} + #{inst[:carry_flag] ? 1 : 0}) from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            and_a_r_instructions = [
                { source: :a, source_value: 0x00, a_value: 0x00, opcode: 0xA7, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0x0F, a_value: 0x0F, opcode: 0xA7, expected_a_value_after_op: 0x0F, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xAA, a_value: 0xAA, opcode: 0xA7, expected_a_value_after_op: 0xAA, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xFF, a_value: 0xFF, opcode: 0xA7, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0x01, a_value: 0x01, opcode: 0xA7, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x04, a_value: 0xA0, opcode: 0xA0, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0xA5, opcode: 0xA0, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xF0, a_value: 0x0F, opcode: 0xA0, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xFF, a_value: 0xFF, opcode: 0xA0, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xF0, a_value: 0xA5, opcode: 0xA0, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0xAA, opcode: 0xA0, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x01, a_value: 0x0F, opcode: 0xA0, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x04, a_value: 0xA0, opcode: 0xA1, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0xA5, opcode: 0xA1, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xF0, a_value: 0x0F, opcode: 0xA1, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xFF, a_value: 0xFF, opcode: 0xA1, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xF0, a_value: 0xA5, opcode: 0xA1, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0xAA, opcode: 0xA1, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x01, a_value: 0x0F, opcode: 0xA1, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x04, a_value: 0xA0, opcode: 0xA2, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0xA5, opcode: 0xA2, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xF0, a_value: 0x0F, opcode: 0xA2, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xFF, a_value: 0xFF, opcode: 0xA2, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xF0, a_value: 0xA5, opcode: 0xA2, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0xAA, opcode: 0xA2, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x01, a_value: 0x0F, opcode: 0xA2, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x04, a_value: 0xA0, opcode: 0xA3, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0xA5, opcode: 0xA3, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xF0, a_value: 0x0F, opcode: 0xA3, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xFF, a_value: 0xFF, opcode: 0xA3, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xF0, a_value: 0xA5, opcode: 0xA3, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0xAA, opcode: 0xA3, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x01, a_value: 0x0F, opcode: 0xA3, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x04, a_value: 0xA0, opcode: 0xA4, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0xA5, opcode: 0xA4, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xF0, a_value: 0x0F, opcode: 0xA4, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xFF, a_value: 0xFF, opcode: 0xA4, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xF0, a_value: 0xA5, opcode: 0xA4, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0xAA, opcode: 0xA4, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x01, a_value: 0x0F, opcode: 0xA4, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x04, a_value: 0xA0, opcode: 0xA5, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0xA5, opcode: 0xA5, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xF0, a_value: 0x0F, opcode: 0xA5, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xFF, a_value: 0xFF, opcode: 0xA5, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xF0, a_value: 0xA5, opcode: 0xA5, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0xAA, opcode: 0xA5, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x01, a_value: 0x0F, opcode: 0xA5, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            and_a_r_instructions.each do |inst|
                describe "AND A, r" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should AND the value in #{inst[:source]} register from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            and_a_hl_instructions = [
                { hl_value: 0x04, a_value: 0xA0, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x0F, a_value: 0xA5, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xF0, a_value: 0x0F, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xFF, a_value: 0xFF, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xF0, a_value: 0xA5, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x0F, a_value: 0xAA, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x01, a_value: 0x0F, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            and_a_hl_instructions.each do |inst|
                describe "AND A, (HL)" do
                    let(:data) { [0xA6] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]
                        memory[0x1234] = inst[:hl_value]
                    end

                    it "should AND the value in memory at (HL) #{inst[:hl_value]} register from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            and_a_n_instructions = [
                { n_value: 0x04, a_value: 0xA0, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x0F, a_value: 0xA5, expected_a_value_after_op: 0x05, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xF0, a_value: 0x0F, expected_a_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xFF, a_value: 0xFF, expected_a_value_after_op: 0xFF, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xF0, a_value: 0xA5, expected_a_value_after_op: 0xA0, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x0F, a_value: 0xAA, expected_a_value_after_op: 0x0A, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x01, a_value: 0x0F, expected_a_value_after_op: 0x01, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            and_a_n_instructions.each do |inst|
                describe "AND A, n" do
                    let(:data) { [0xE6, inst[:n_value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should AND the value #{inst[:n_value]} from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            or_a_r_instructions = [
                { source: :a, source_value: 0x00, a_value: 0x00, opcode: 0xB7, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0x05, a_value: 0x05, opcode: 0xB7, expected_a_value_after_op: 0x05, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xFF, a_value: 0xFF, opcode: 0xB7, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x00, a_value: 0x00, opcode: 0xB0, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xFF, a_value: 0x00, opcode: 0xB0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x00, a_value: 0xFF, opcode: 0xB0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0xF0, opcode: 0xB0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xAA, a_value: 0x55, opcode: 0xB0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0x00, opcode: 0xB0, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xFF, a_value: 0xFF, opcode: 0xB0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x01, a_value: 0x02, opcode: 0xB0, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x3C, a_value: 0x0A, opcode: 0xB0, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x12, a_value: 0x24, opcode: 0xB0, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x40, a_value: 0x08, opcode: 0xB0, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x04, a_value: 0x10, opcode: 0xB0, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x00, a_value: 0x00, opcode: 0xB1, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xFF, a_value: 0x00, opcode: 0xB1, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x00, a_value: 0xFF, opcode: 0xB1, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0xF0, opcode: 0xB1, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xAA, a_value: 0x55, opcode: 0xB1, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0x00, opcode: 0xB1, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xFF, a_value: 0xFF, opcode: 0xB1, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x01, a_value: 0x02, opcode: 0xB1, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x3C, a_value: 0x0A, opcode: 0xB1, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x12, a_value: 0x24, opcode: 0xB1, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x40, a_value: 0x08, opcode: 0xB1, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x04, a_value: 0x10, opcode: 0xB1, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x00, a_value: 0x00, opcode: 0xB2, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xFF, a_value: 0x00, opcode: 0xB2, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x00, a_value: 0xFF, opcode: 0xB2, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0xF0, opcode: 0xB2, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xAA, a_value: 0x55, opcode: 0xB2, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0x00, opcode: 0xB2, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xFF, a_value: 0xFF, opcode: 0xB2, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x01, a_value: 0x02, opcode: 0xB2, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x3C, a_value: 0x0A, opcode: 0xB2, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x12, a_value: 0x24, opcode: 0xB2, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x40, a_value: 0x08, opcode: 0xB2, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x04, a_value: 0x10, opcode: 0xB2, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x00, a_value: 0x00, opcode: 0xB3, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xFF, a_value: 0x00, opcode: 0xB3, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x00, a_value: 0xFF, opcode: 0xB3, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0xF0, opcode: 0xB3, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xAA, a_value: 0x55, opcode: 0xB3, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0x00, opcode: 0xB3, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xFF, a_value: 0xFF, opcode: 0xB3, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x01, a_value: 0x02, opcode: 0xB3, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x3C, a_value: 0x0A, opcode: 0xB3, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x12, a_value: 0x24, opcode: 0xB3, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x40, a_value: 0x08, opcode: 0xB3, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x04, a_value: 0x10, opcode: 0xB3, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x00, a_value: 0x00, opcode: 0xB4, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xFF, a_value: 0x00, opcode: 0xB4, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x00, a_value: 0xFF, opcode: 0xB4, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0xF0, opcode: 0xB4, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xAA, a_value: 0x55, opcode: 0xB4, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0x00, opcode: 0xB4, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xFF, a_value: 0xFF, opcode: 0xB4, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x01, a_value: 0x02, opcode: 0xB4, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x3C, a_value: 0x0A, opcode: 0xB4, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x12, a_value: 0x24, opcode: 0xB4, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x40, a_value: 0x08, opcode: 0xB4, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x04, a_value: 0x10, opcode: 0xB4, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x00, a_value: 0x00, opcode: 0xB5, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xFF, a_value: 0x00, opcode: 0xB5, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x00, a_value: 0xFF, opcode: 0xB5, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0xF0, opcode: 0xB5, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xAA, a_value: 0x55, opcode: 0xB5, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0x00, opcode: 0xB5, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xFF, a_value: 0xFF, opcode: 0xB5, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x01, a_value: 0x02, opcode: 0xB5, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x3C, a_value: 0x0A, opcode: 0xB5, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x12, a_value: 0x24, opcode: 0xB5, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x40, a_value: 0x08, opcode: 0xB5, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x04, a_value: 0x10, opcode: 0xB5, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            or_a_r_instructions.each do |inst|
                describe "OR A, r" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should OR the value in #{inst[:source]} register from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            or_a_hl_instructions = [
                { hl_value: 0x00, a_value: 0x00, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xFF, a_value: 0x00, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x00, a_value: 0xFF, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x0F, a_value: 0xF0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xAA, a_value: 0x55, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x0F, a_value: 0x00, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xFF, a_value: 0xFF, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x01, a_value: 0x02, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x3C, a_value: 0x0A, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x12, a_value: 0x24, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x40, a_value: 0x08, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x04, a_value: 0x10, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            or_a_hl_instructions.each do |inst|
                describe "OR A, (HL)" do
                    let(:data) { [0xB6] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]

                        memory[0x1234] = inst[:hl_value]
                    end

                    it "should OR the value in memory at address (HL) from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            or_a_n_instructions = [
                { n_value: 0x00, a_value: 0x00, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xFF, a_value: 0x00, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x00, a_value: 0xFF, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x0F, a_value: 0xF0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xAA, a_value: 0x55, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x0F, a_value: 0x00, expected_a_value_after_op: 0x0F, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xFF, a_value: 0xFF, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x01, a_value: 0x02, expected_a_value_after_op: 0x03, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x3C, a_value: 0x0A, expected_a_value_after_op: 0x3E, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x12, a_value: 0x24, expected_a_value_after_op: 0x36, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x40, a_value: 0x08, expected_a_value_after_op: 0x48, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x04, a_value: 0x10, expected_a_value_after_op: 0x14, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            or_a_n_instructions.each do |inst|
                describe "OR A, n" do
                    let(:data) { [0xF6, inst[:n_value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should OR the value #{inst[:n_value]} from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            xor_a_r_instructions = [
                { source: :a, source_value: 0x00, a_value: 0x00, opcode: 0xAF, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0x0F, a_value: 0x0F, opcode: 0xAF, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xF0, a_value: 0xF0, opcode: 0xAF, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xFF, a_value: 0xFF, opcode: 0xAF, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0xF0, opcode: 0xA8, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x3C, a_value: 0xA5, opcode: 0xA8, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x55, a_value: 0xAA, opcode: 0xA8, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xA3, a_value: 0xA3, opcode: 0xA8, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x11, a_value: 0x22, opcode: 0xA8, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x7F, a_value: 0x80, opcode: 0xA8, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0xF0, opcode: 0xA9, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x3C, a_value: 0xA5, opcode: 0xA9, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x55, a_value: 0xAA, opcode: 0xA9, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xA3, a_value: 0xA3, opcode: 0xA9, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x11, a_value: 0x22, opcode: 0xA9, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x7F, a_value: 0x80, opcode: 0xA9, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0xF0, opcode: 0xAA, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x3C, a_value: 0xA5, opcode: 0xAA, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x55, a_value: 0xAA, opcode: 0xAA, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xA3, a_value: 0xA3, opcode: 0xAA, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x11, a_value: 0x22, opcode: 0xAA, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x7F, a_value: 0x80, opcode: 0xAA, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0xF0, opcode: 0xAB, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x3C, a_value: 0xA5, opcode: 0xAB, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x55, a_value: 0xAA, opcode: 0xAB, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xA3, a_value: 0xA3, opcode: 0xAB, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x11, a_value: 0x22, opcode: 0xAB, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x7F, a_value: 0x80, opcode: 0xAB, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0xF0, opcode: 0xAC, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x3C, a_value: 0xA5, opcode: 0xAC, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x55, a_value: 0xAA, opcode: 0xAC, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xA3, a_value: 0xA3, opcode: 0xAC, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x11, a_value: 0x22, opcode: 0xAC, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x7F, a_value: 0x80, opcode: 0xAC, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0xF0, opcode: 0xAD, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x3C, a_value: 0xA5, opcode: 0xAD, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x55, a_value: 0xAA, opcode: 0xAD, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xA3, a_value: 0xA3, opcode: 0xAD, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x11, a_value: 0x22, opcode: 0xAD, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x7F, a_value: 0x80, opcode: 0xAD, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            xor_a_r_instructions.each do |inst|
                describe "XOR A, r" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should XOR the value in #{inst[:source]} register from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            xor_a_hl_instructions = [
                { hl_value: 0x0F, a_value: 0xF0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x3C, a_value: 0xA5, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x55, a_value: 0xAA, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xA3, a_value: 0xA3, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x11, a_value: 0x22, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x7F, a_value: 0x80, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            xor_a_hl_instructions.each do |inst|
                describe "XOR A, (HL)" do
                    let(:data) { [0xAE] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]

                        memory[0x1234] = inst[:hl_value]
                    end

                    it "should XOR the value in memory at address (HL) from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            xor_a_n_instructions = [
                { n_value: 0x0F, a_value: 0xF0, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x3C, a_value: 0xA5, expected_a_value_after_op: 0x99, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x55, a_value: 0xAA, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0xA3, a_value: 0xA3, expected_a_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x11, a_value: 0x22, expected_a_value_after_op: 0x33, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { n_value: 0x7F, a_value: 0x80, expected_a_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            xor_a_n_instructions.each do |inst|
                describe "XOR A, n" do
                    let(:data) { [0xEE, inst[:n_value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should XOR the value #{inst[:n_value]} from A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end

            cp_a_r_instructions = [
                { source: :a, source_value: 0x00, a_value: 0x00, opcode: 0xBF, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x0F, a_value: 0x0F, opcode: 0xBF, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0xF0, a_value: 0xF0, opcode: 0xBF, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0xFF, a_value: 0xFF, opcode: 0xBF, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x00, a_value: 0x00, opcode: 0xB8, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x00, a_value: 0x00, opcode: 0xB8, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x10, a_value: 0x20, opcode: 0xB8, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0xFF, a_value: 0x00, opcode: 0xB8, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :b, source_value: 0x0F, a_value: 0x1F, opcode: 0xB8, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0xF0, a_value: 0xFF, opcode: 0xB8, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x01, a_value: 0x01, opcode: 0xB8, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x80, a_value: 0x00, opcode: 0xB8, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :b, source_value: 0x3F, a_value: 0x40, opcode: 0xB8, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x00, a_value: 0x00, opcode: 0xB9, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x00, a_value: 0x00, opcode: 0xB9, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x10, a_value: 0x20, opcode: 0xB9, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0xFF, a_value: 0x00, opcode: 0xB9, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :c, source_value: 0x0F, a_value: 0x1F, opcode: 0xB9, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0xF0, a_value: 0xFF, opcode: 0xB9, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x01, a_value: 0x01, opcode: 0xB9, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x80, a_value: 0x00, opcode: 0xB9, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :c, source_value: 0x3F, a_value: 0x40, opcode: 0xB9, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x00, a_value: 0x00, opcode: 0xBA, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x00, a_value: 0x00, opcode: 0xBA, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x10, a_value: 0x20, opcode: 0xBA, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0xFF, a_value: 0x00, opcode: 0xBA, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :d, source_value: 0x0F, a_value: 0x1F, opcode: 0xBA, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0xF0, a_value: 0xFF, opcode: 0xBA, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x01, a_value: 0x01, opcode: 0xBA, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x80, a_value: 0x00, opcode: 0xBA, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :d, source_value: 0x3F, a_value: 0x40, opcode: 0xBA, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x00, a_value: 0x00, opcode: 0xBB, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x00, a_value: 0x00, opcode: 0xBB, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x10, a_value: 0x20, opcode: 0xBB, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0xFF, a_value: 0x00, opcode: 0xBB, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :e, source_value: 0x0F, a_value: 0x1F, opcode: 0xBB, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0xF0, a_value: 0xFF, opcode: 0xBB, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x01, a_value: 0x01, opcode: 0xBB, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x80, a_value: 0x00, opcode: 0xBB, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :e, source_value: 0x3F, a_value: 0x40, opcode: 0xBB, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x00, a_value: 0x00, opcode: 0xBC, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x00, a_value: 0x00, opcode: 0xBC, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x10, a_value: 0x20, opcode: 0xBC, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0xFF, a_value: 0x00, opcode: 0xBC, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :h, source_value: 0x0F, a_value: 0x1F, opcode: 0xBC, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0xF0, a_value: 0xFF, opcode: 0xBC, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x01, a_value: 0x01, opcode: 0xBC, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x80, a_value: 0x00, opcode: 0xBC, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :h, source_value: 0x3F, a_value: 0x40, opcode: 0xBC, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x00, a_value: 0x00, opcode: 0xBD, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x00, a_value: 0x00, opcode: 0xBD, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x10, a_value: 0x20, opcode: 0xBD, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0xFF, a_value: 0x00, opcode: 0xBD, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { source: :l, source_value: 0x0F, a_value: 0x1F, opcode: 0xBD, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0xF0, a_value: 0xFF, opcode: 0xBD, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x01, a_value: 0x01, opcode: 0xBD, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x80, a_value: 0x00, opcode: 0xBD, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { source: :l, source_value: 0x3F, a_value: 0x40, opcode: 0xBD, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
            ]

            cp_a_r_instructions.each do |inst|
                describe "CP A, r" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should not change value of A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:a_value])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            cp_a_hl_instructions = [
                { hl_value: 0x00, a_value: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x00, a_value: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x10, a_value: 0x20, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0xFF, a_value: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { hl_value: 0x0F, a_value: 0x1F, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0xF0, a_value: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x01, a_value: 0x01, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x80, a_value: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { hl_value: 0x3F, a_value: 0x40, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
            ]
            cp_a_hl_instructions = []

            cp_a_hl_instructions.each do |inst|
                describe "CP A, (HL)" do
                    let(:data) { [0xBE] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34
                        subject.registers[:a] = inst[:a_value]

                        memory[0x1234] = inst[:hl_value]
                    end

                    it "should not change value of A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:a_value])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            cp_a_n_instructions = [
                { n_value: 0x00, a_value: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0x00, a_value: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0x10, a_value: 0x20, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0xFF, a_value: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG] },
                { n_value: 0x0F, a_value: 0x1F, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0xF0, a_value: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0x01, a_value: 0x01, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { n_value: 0x80, a_value: 0x00, flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                { n_value: 0x3F, a_value: 0x40, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
            ]
            cp_a_n_instructions = []

            cp_a_n_instructions.each do |inst|
                describe "CP A, n" do
                    let(:data) { [0xFE, inst[:n_value]] }

                    before do
                        subject.registers[:a] = inst[:a_value]
                    end

                    it "should not change value of A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:a_value])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 8
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x102)
                    end
                end
            end
            
            inc_r_instructions = [
                { source: :a, source_value: 0x00, opcode: 0x3C, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0x0F, opcode: 0x3C, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xFF, opcode: 0x3C, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0x7F, opcode: 0x3C, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :a, source_value: 0xFE, opcode: 0x3C, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x00, opcode: 0x04, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x0F, opcode: 0x04, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xFF, opcode: 0x04, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0x7F, opcode: 0x04, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :b, source_value: 0xFE, opcode: 0x04, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x00, opcode: 0x0C, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x0F, opcode: 0x0C, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xFF, opcode: 0x0C, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0x7F, opcode: 0x0C, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :c, source_value: 0xFE, opcode: 0x0C, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x00, opcode: 0x14, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x0F, opcode: 0x14, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xFF, opcode: 0x14, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0x7F, opcode: 0x14, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :d, source_value: 0xFE, opcode: 0x14, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x00, opcode: 0x1C, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x0F, opcode: 0x1C, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xFF, opcode: 0x1C, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0x7F, opcode: 0x1C, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :e, source_value: 0xFE, opcode: 0x1C, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x00, opcode: 0x24, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x0F, opcode: 0x24, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xFF, opcode: 0x24, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0x7F, opcode: 0x24, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :h, source_value: 0xFE, opcode: 0x24, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x00, opcode: 0x2C, expected_source_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x0F, opcode: 0x2C, expected_source_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xFF, opcode: 0x2C, expected_source_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0x7F, opcode: 0x2C, expected_source_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { source: :l, source_value: 0xFE, opcode: 0x2C, expected_source_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            inc_r_instructions.each do |inst|
                describe "INC r" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                    end

                    it "should leave carry flag unaffected" do
                        subject.registers[:f] |= CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true

                        subject.registers[:f] &= ~CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal false
                    end

                    it "should INC the value in #{inst[:source]} by 1" do
                        subject.instruction data

                        _(subject.registers[inst[:source]]).must_equal(inst[:expected_source_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            inc_hl_instructions = [
                { hl_value: 0x00, expected_memory_value_after_op: 0x01, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x0F, expected_memory_value_after_op: 0x10, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xFF, expected_memory_value_after_op: 0x00, flags_set: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG], flags_unset: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0x7F, expected_memory_value_after_op: 0x80, flags_set: [CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
                { hl_value: 0xFE, expected_memory_value_after_op: 0xFF, flags_set: [], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG] },
            ]

            inc_hl_instructions.each do |inst|
                describe "INC (HL)" do
                    let(:data) { [0x34] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34

                        memory[0x1234] = inst[:hl_value]
                    end

                    it "should leave carry flag unaffected" do
                        subject.registers[:f] |= CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true

                        subject.registers[:f] &= ~CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal false
                    end

                    it "should INC the value in (HL) by 1" do
                        subject.instruction data

                        _(memory[0x1234]).must_equal(inst[:expected_memory_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 12
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            dec_r_instructions = [
                { source: :a, source_value: 0x10, opcode: 0x3D, expected_source_value_after_op: 0x0F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x20, opcode: 0x3D, expected_source_value_after_op: 0x1F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x30, opcode: 0x3D, expected_source_value_after_op: 0x2F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x40, opcode: 0x3D, expected_source_value_after_op: 0x3F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x50, opcode: 0x3D, expected_source_value_after_op: 0x4F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x60, opcode: 0x3D, expected_source_value_after_op: 0x5F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x70, opcode: 0x3D, expected_source_value_after_op: 0x6F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x01, opcode: 0x3D, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x00, opcode: 0x3D, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x10, opcode: 0x3D, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0xFF, opcode: 0x3D, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :a, source_value: 0x80, opcode: 0x3D, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x01, opcode: 0x05, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x00, opcode: 0x05, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x10, opcode: 0x05, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0xFF, opcode: 0x05, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :b, source_value: 0x80, opcode: 0x05, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x01, opcode: 0x0D, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x00, opcode: 0x0D, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x10, opcode: 0x0D, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0xFF, opcode: 0x0D, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :c, source_value: 0x80, opcode: 0x0D, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x01, opcode: 0x15, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x00, opcode: 0x15, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x10, opcode: 0x15, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0xFF, opcode: 0x15, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :d, source_value: 0x80, opcode: 0x15, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x01, opcode: 0x1D, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x00, opcode: 0x1D, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x10, opcode: 0x1D, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0xFF, opcode: 0x1D, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :e, source_value: 0x80, opcode: 0x1D, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x01, opcode: 0x25, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x00, opcode: 0x25, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x10, opcode: 0x25, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0xFF, opcode: 0x25, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :h, source_value: 0x80, opcode: 0x25, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x01, opcode: 0x2D, expected_source_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x00, opcode: 0x2D, expected_source_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x10, opcode: 0x2D, expected_source_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0xFF, opcode: 0x2D, expected_source_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { source: :l, source_value: 0x80, opcode: 0x2D, expected_source_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
            ]

            dec_r_instructions.each do |inst|
                describe "DEC r" do
                    let(:data) { [inst[:opcode]] }

                    before do
                        subject.registers[inst[:source]] = inst[:source_value]
                    end

                    it "should leave carry flag unaffected" do
                        subject.registers[:f] |= CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true

                        subject.registers[:f] &= ~CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal false
                    end

                    it "should DEC the value in #{inst[:source]} by 1" do
                        subject.instruction data

                        _(subject.registers[inst[:source]]).must_equal(inst[:expected_source_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            dec_hl_instructions = [
                { hl_value: 0x10, expected_memory_value_after_op: 0x0F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x20, expected_memory_value_after_op: 0x1F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x30, expected_memory_value_after_op: 0x2F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x40, expected_memory_value_after_op: 0x3F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x50, expected_memory_value_after_op: 0x4F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x60, expected_memory_value_after_op: 0x5F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x70, expected_memory_value_after_op: 0x6F, flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x01, expected_memory_value_after_op: 0x00, flags_set: [CPU::ZERO_FLAG, CPU::SUBTRACT_FLAG], flags_unset: [CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x00, expected_memory_value_after_op: 0xFF, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x10, expected_memory_value_after_op: 0x0F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0xFF, expected_memory_value_after_op: 0xFE, flags_set: [CPU::SUBTRACT_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG, CPU::CARRY_FLAG] },
                { hl_value: 0x80, expected_memory_value_after_op: 0x7F, flags_set: [CPU::SUBTRACT_FLAG, CPU::HALF_CARRY_FLAG], flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
            ]

            dec_hl_instructions.each do |inst|
                describe "DEC (HL)" do
                    let(:data) { [0x35] }

                    before do
                        subject.registers[:h] = 0x12
                        subject.registers[:l] = 0x34

                        memory[0x1234] = inst[:hl_value]
                    end

                    it "should leave carry flag unaffected" do
                        subject.registers[:f] |= CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true

                        subject.registers[:f] &= ~CPU::CARRY_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal false
                    end

                    it "should DEC the value in (HL) by 1" do
                        subject.instruction data

                        _(memory[0x1234]).must_equal(inst[:expected_memory_value_after_op])
                    end

                    it "should set the flags #{inst[:flags_set]}" do
                        subject.instruction data

                        inst[:flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:flags_unset]}" do
                        subject.instruction data

                        inst[:flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 12
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            daa_instructions = [
                { a_value: 0x110, expected_a_value_after_op: 0x70, before_op_flags_set: [CPU::CARRY_FLAG], after_op_expected_flags_set: [CPU::CARRY_FLAG], after_op_expected_flags_unset: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG] },
                { a_value: 0x11, expected_a_value_after_op: 0x17, before_op_flags_set: [CPU::HALF_CARRY_FLAG], after_op_expected_flags_set: [], after_op_expected_flags_unset: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0x0D, expected_a_value_after_op: 0x07, before_op_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_set: [CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0xE4, expected_a_value_after_op: 0x84, before_op_flags_set: [CPU::CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_set: [CPU::SUBTRACT_FLAG, CPU::CARRY_FLAG], after_op_expected_flags_unset: [CPU::HALF_CARRY_FLAG, CPU::ZERO_FLAG] },
            ]

            daa_instructions.each do |inst|
                describe "DAA" do
                    let(:data) { [0x27] }

                    before do
                        subject.registers[:a] = inst[:a_value]

                        inst[:before_op_flags_set].each do |flag|
                            subject.registers[:f] |= flag
                        end
                    end

                    it "should leave subtract flag unaffected" do
                        subject.registers[:f] |= CPU::SUBTRACT_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal true

                        subject.registers[:f] &= ~CPU::SUBTRACT_FLAG

                        subject.instruction data

                        _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                    end

                    it "should DAA the value in A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:after_op_expected_flags_set]}" do
                        subject.instruction data

                        inst[:after_op_expected_flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:after_op_expected_flags_unset]}" do
                        subject.instruction data

                        inst[:after_op_expected_flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            cpl_instructions = [
                { a_value: 0x4F, expected_a_value_after_op: 0xB0, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0x00, expected_a_value_after_op: 0xFF, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0x01, expected_a_value_after_op: 0xFE, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0x7F, expected_a_value_after_op: 0x80, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0x80, expected_a_value_after_op: 0x7F, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0xA5, expected_a_value_after_op: 0x5A, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                { a_value: 0xFF, expected_a_value_after_op: 0x00, before_op_flags_set: [], after_op_expected_flags_set: [CPU::HALF_CARRY_FLAG, CPU::SUBTRACT_FLAG], after_op_expected_flags_unset: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
            ]

            cpl_instructions.each do |inst|
                describe "CPL" do
                    let(:data) { [0x2F] }

                    before do
                        subject.registers[:a] = inst[:a_value]

                        inst[:before_op_flags_set].each do |flag|
                            subject.registers[:f] |= flag
                        end
                    end

                    it "should CPL the value in A" do
                        subject.instruction data

                        _(subject.registers[:a]).must_equal(inst[:expected_a_value_after_op])
                    end

                    it "should set the flags #{inst[:after_op_expected_flags_set]}" do
                        subject.instruction data

                        inst[:after_op_expected_flags_set].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                        end
                    end

                    it "should unset the flags #{inst[:after_op_expected_flags_unset]}" do
                        subject.instruction data

                        inst[:after_op_expected_flags_unset].each do |flag|
                            _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                        end
                    end

                    it 'should return correct amount of cycles used' do
                      cycles = subject.instruction data

                      _(cycles).must_equal 4
                    end

                    it 'should update the program_counter correctly' do
                        subject.program_counter = 0x100

                        subject.instruction data

                        _(subject.program_counter).must_equal(0x101)
                    end
                end
            end

            describe "SCF" do
                let(:data) { [0x37] }

                it 'should always set carry flag' do 
                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true
                end
                
                it 'should always unset half carry flag' do 
                    subject.registers[:f] |= CPU::HALF_CARRY_FLAG

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false
                end
                
                it 'should always unset subtract flag' do 
                    subject.registers[:f] |= CPU::SUBTRACT_FLAG

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                end
                
                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 4
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end

            describe "CCF" do
                let(:data) { [0x3F] }

                it 'should always flip carry flag' do 
                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal true

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::CARRY_FLAG)).must_equal false
                end
                
                it 'should always unset half carry flag' do 
                    subject.registers[:f] |= CPU::HALF_CARRY_FLAG

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false
                end
                
                it 'should always unset subtract flag' do 
                    subject.registers[:f] |= CPU::SUBTRACT_FLAG

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false

                    subject.instruction data

                    _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                end
                
                it 'should return correct amount of cycles used' do
                  cycles = subject.instruction data

                  _(cycles).must_equal 4
                end

                it 'should update the program_counter correctly' do
                    subject.program_counter = 0x100

                    subject.instruction data

                    _(subject.program_counter).must_equal(0x101)
                end
            end
        end

        describe 'bit manipulation' do
            describe 'rotate and shift' do
                bit_manipulation_instructions = [
                    { type: "RLC", opcodes: [0xCB, 0x07], source: :a, source_value: 0b00000000, expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "RLC", opcodes: [0xCB, 0x00], source: :b, source_value: 0b11001010, expected_source_value_after: 0b10010101, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RLC", opcodes: [0xCB, 0x01], source: :c, source_value: 0b11111111, expected_source_value_after: 0b11111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RLC", opcodes: [0xCB, 0x02], source: :d, source_value: 0b01010101, expected_source_value_after: 0b10101010, expected_flags_set_after: [] },
                    { type: "RLC", opcodes: [0xCB, 0x03], source: :e, source_value: 0b10000000, expected_source_value_after: 0b00000001, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RLC", opcodes: [0xCB, 0x04], source: :h, source_value: 0b00000001, expected_source_value_after: 0b00000010, expected_flags_set_after: [] },
                    { type: "RLC", opcodes: [0xCB, 0x05], source: :l, source_value: 0b11110000, expected_source_value_after: 0b11100001, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RRC", opcodes: [0xCB, 0x0F], source: :a, source_value: 0b00000000, expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "RRC", opcodes: [0xCB, 0x08], source: :b, source_value: 0b00000001, expected_source_value_after: 0b10000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RRC", opcodes: [0xCB, 0x09], source: :c, source_value: 0b11110000, expected_source_value_after: 0b01111000, expected_flags_set_after: [] },
                    { type: "RRC", opcodes: [0xCB, 0x0A], source: :d, source_value: 0b10101010, expected_source_value_after: 0b01010101, expected_flags_set_after: [] },
                    { type: "RRC", opcodes: [0xCB, 0x0B], source: :e, source_value: 0b00000010, expected_source_value_after: 0b00000001, expected_flags_set_after: [] },
                    { type: "RRC", opcodes: [0xCB, 0x0C], source: :h, source_value: 0b10000001, expected_source_value_after: 0b11000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RRC", opcodes: [0xCB, 0x0D], source: :l, source_value: 0b00000001, expected_source_value_after: 0b10000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x17], source: :a, source_value: 0b00000000, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x10], source: :b, source_value: 0b10000000, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x11], source: :c, source_value: 0b00000001, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b00000011, expected_flags_set_after: [] },
                    { type: "RL", opcodes: [0xCB, 0x12], source: :d, source_value: 0b10101010, flags_set_before: [], expected_source_value_after: 0b01010100, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x13], source: :e, source_value: 0b11111111, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b11111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x14], source: :h, source_value: 0b10000001, flags_set_before: [], expected_source_value_after: 0b00000010, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x15], source: :l, source_value: 0b00000001, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b00000011, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1F], source: :a, source_value: 0b11001001, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b11100100, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1F], source: :a, source_value: 0b11001001, flags_set_before: [], expected_source_value_after: 0b01100100, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1F], source: :a, source_value: 0b00000001, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1F], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b10000000, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x18], source: :b, source_value: 0b10101010, flags_set_before: [], expected_source_value_after: 0b01010101, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x19], source: :c, source_value: 0b11111111, flags_set_before: [], expected_source_value_after: 0b01111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1A], source: :d, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b10000000, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1B], source: :e, source_value: 0b00000010, flags_set_before: [], expected_source_value_after: 0b00000001, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1C], source: :h, source_value: 0b01010101, flags_set_before: [CPU::CARRY_FLAG], expected_source_value_after: 0b10101010, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1D], source: :l, source_value: 0b10000000, flags_set_before: [], expected_source_value_after: 0b01000000, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x27], source: :a, source_value: 0b01101010, flags_set_before: [], expected_source_value_after: 0b11010100, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x27], source: :a, source_value: 0b10000000, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SLA", opcodes: [0xCB, 0x27], source: :a, source_value: 0b00000001, flags_set_before: [], expected_source_value_after: 0b00000010, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x27], source: :a, source_value: 0b00000000, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SLA", opcodes: [0xCB, 0x20], source: :b, source_value: 0b01010101, flags_set_before: [], expected_source_value_after: 0b10101010, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x21], source: :c, source_value: 0b00111111, flags_set_before: [], expected_source_value_after: 0b01111110, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x22], source: :d, source_value: 0b00000010, flags_set_before: [], expected_source_value_after: 0b00000100, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x23], source: :e, source_value: 0b11111111, flags_set_before: [], expected_source_value_after: 0b11111110, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SLA", opcodes: [0xCB, 0x24], source: :h, source_value: 0b00001111, flags_set_before: [], expected_source_value_after: 0b00011110, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x25], source: :l, source_value: 0b01111111, flags_set_before: [], expected_source_value_after: 0b11111110, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2F], source: :a, source_value: 0b01111111, flags_set_before: [], expected_source_value_after: 0b00111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2F], source: :a, source_value: 0b10000000, flags_set_before: [], expected_source_value_after: 0b11000000, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2F], source: :a, source_value: 0b00000000, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2F], source: :a, source_value: 0b11010101, flags_set_before: [], expected_source_value_after: 0b11101010, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x28], source: :b, source_value: 0b11010101, flags_set_before: [], expected_source_value_after: 0b11101010, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x29], source: :c, source_value: 0b10101010, flags_set_before: [], expected_source_value_after: 0b11010101, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2A], source: :d, source_value: 0b10101010, flags_set_before: [], expected_source_value_after: 0b11010101, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2A], source: :d, source_value: 0b10101010, flags_set_before: [], expected_source_value_after: 0b11010101, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2B], source: :e, source_value: 0b01111111, flags_set_before: [], expected_source_value_after: 0b00111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2C], source: :h, source_value: 0b00001111, flags_set_before: [], expected_source_value_after: 0b00000111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2D], source: :l, source_value: 0b11101111, flags_set_before: [], expected_source_value_after: 0b11110111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SWAP", opcodes: [0xCB, 0x37], source: :a, source_value: 0b00000000, expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SWAP", opcodes: [0xCB, 0x37], source: :a, source_value: 0b01010101, expected_source_value_after: 0b01010101, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x30], source: :b, source_value: 0b10110011, expected_source_value_after: 0b00111011, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x31], source: :c, source_value: 0b11110000, expected_source_value_after: 0b00001111, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x32], source: :d, source_value: 0b00001111, expected_source_value_after: 0b11110000, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x33], source: :e, source_value: 0b10011001, expected_source_value_after: 0b10011001, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x34], source: :h, source_value: 0b01100110, expected_source_value_after: 0b01100110, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x35], source: :l, source_value: 0b11110011, expected_source_value_after: 0b00111111, expected_flags_set_after: [] },
                    { type: "SRL", opcodes: [0xCB, 0x3F], source: :a, source_value: 0b10000000, flags_set_before: [], expected_source_value_after: 0b01000000, expected_flags_set_after: [] },
                    { type: "SRL", opcodes: [0xCB, 0x3F], source: :a, source_value: 0b00000001, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x38], source: :b, source_value: 0b00000001, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x39], source: :c, source_value: 0b10000001, flags_set_before: [], expected_source_value_after: 0b01000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3A], source: :d, source_value: 0b00000010, flags_set_before: [], expected_source_value_after: 0b00000001, expected_flags_set_after: [] },
                    { type: "SRL", opcodes: [0xCB, 0x3B], source: :e, source_value: 0b11111111, flags_set_before: [], expected_source_value_after: 0b01111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3C], source: :h, source_value: 0b00000000, flags_set_before: [], expected_source_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3D], source: :l, source_value: 0b11111110, flags_set_before: [], expected_source_value_after: 0b01111111, expected_flags_set_after: [] },
                    { type: "BIT 0", opcodes: [0xCB, 0x47], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x47], source: :a, source_value: 0b10000001, flags_set_before: [],                 expected_source_value_after: 0b10000001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x40], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x40], source: :b, source_value: 0b10000001, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10000001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x41], source: :c, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x41], source: :c, source_value: 0b10001001, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10001001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x42], source: :d, source_value: 0b00101000, flags_set_before: [],                 expected_source_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x42], source: :d, source_value: 0b11001001, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11001001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x43], source: :e, source_value: 0b00011000, flags_set_before: [],                 expected_source_value_after: 0b00011000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x43], source: :e, source_value: 0b10101001, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x44], source: :h, source_value: 0b00001100, flags_set_before: [],                 expected_source_value_after: 0b00001100, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x44], source: :h, source_value: 0b10111001, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x45], source: :l, source_value: 0b00001110, flags_set_before: [],                 expected_source_value_after: 0b00001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x45], source: :l, source_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4F], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4F], source: :a, source_value: 0b10000010, flags_set_before: [],                 expected_source_value_after: 0b10000010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x48], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x48], source: :b, source_value: 0b10000010, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10000010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x49], source: :c, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x49], source: :c, source_value: 0b10001010, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4A], source: :d, source_value: 0b00101000, flags_set_before: [],                 expected_source_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4A], source: :d, source_value: 0b11001010, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4B], source: :e, source_value: 0b00011000, flags_set_before: [],                 expected_source_value_after: 0b00011000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4B], source: :e, source_value: 0b10101010, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4C], source: :h, source_value: 0b00001100, flags_set_before: [],                 expected_source_value_after: 0b00001100, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4C], source: :h, source_value: 0b10111010, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4D], source: :l, source_value: 0b00001100, flags_set_before: [],                 expected_source_value_after: 0b00001100, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4D], source: :l, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x57], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x57], source: :a, source_value: 0b10000101, flags_set_before: [],                 expected_source_value_after: 0b10000101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x50], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x50], source: :b, source_value: 0b10000101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10000101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x51], source: :c, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x51], source: :c, source_value: 0b10001101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10001101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x52], source: :d, source_value: 0b00101000, flags_set_before: [],                 expected_source_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x52], source: :d, source_value: 0b11001101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11001101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x53], source: :e, source_value: 0b00011000, flags_set_before: [],                 expected_source_value_after: 0b00011000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x53], source: :e, source_value: 0b10101101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x54], source: :h, source_value: 0b00001000, flags_set_before: [],                 expected_source_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x54], source: :h, source_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x55], source: :l, source_value: 0b00001010, flags_set_before: [],                 expected_source_value_after: 0b00001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x55], source: :l, source_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5F], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5F], source: :a, source_value: 0b10001110, flags_set_before: [],                 expected_source_value_after: 0b10001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x58], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x58], source: :b, source_value: 0b10001110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x59], source: :c, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x59], source: :c, source_value: 0b10001110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5A], source: :d, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5A], source: :d, source_value: 0b11001110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5B], source: :e, source_value: 0b00010000, flags_set_before: [],                 expected_source_value_after: 0b00010000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5B], source: :e, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5C], source: :h, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5C], source: :h, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5D], source: :l, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5D], source: :l, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x67], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x67], source: :a, source_value: 0b10010101, flags_set_before: [],                 expected_source_value_after: 0b10010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x60], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x60], source: :b, source_value: 0b10010101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x61], source: :c, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x61], source: :c, source_value: 0b10011101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x62], source: :d, source_value: 0b00101000, flags_set_before: [],                 expected_source_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x62], source: :d, source_value: 0b11011101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x63], source: :e, source_value: 0b00001000, flags_set_before: [],                 expected_source_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x63], source: :e, source_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x64], source: :h, source_value: 0b00001000, flags_set_before: [],                 expected_source_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x64], source: :h, source_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x65], source: :l, source_value: 0b00001010, flags_set_before: [],                 expected_source_value_after: 0b00001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x65], source: :l, source_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6F], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6F], source: :a, source_value: 0b10101110, flags_set_before: [],                 expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x68], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x68], source: :b, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x69], source: :c, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x69], source: :c, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6A], source: :d, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6A], source: :d, source_value: 0b11101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6B], source: :e, source_value: 0b00010000, flags_set_before: [],                 expected_source_value_after: 0b00010000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6B], source: :e, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6C], source: :h, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6C], source: :h, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6D], source: :l, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6D], source: :l, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x77], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x77], source: :a, source_value: 0b11010101, flags_set_before: [],                 expected_source_value_after: 0b11010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x70], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x70], source: :b, source_value: 0b11010101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x71], source: :c, source_value: 0b00100000, flags_set_before: [],                 expected_source_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x71], source: :c, source_value: 0b11011101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x72], source: :d, source_value: 0b00101000, flags_set_before: [],                 expected_source_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x72], source: :d, source_value: 0b11011101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x73], source: :e, source_value: 0b00001000, flags_set_before: [],                 expected_source_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x73], source: :e, source_value: 0b11111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x74], source: :h, source_value: 0b00001000, flags_set_before: [],                 expected_source_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x74], source: :h, source_value: 0b11111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x75], source: :l, source_value: 0b00001010, flags_set_before: [],                 expected_source_value_after: 0b00001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x75], source: :l, source_value: 0b11111101, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7F], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7F], source: :a, source_value: 0b10101110, flags_set_before: [],                 expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x78], source: :b, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x78], source: :b, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x79], source: :c, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x79], source: :c, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7A], source: :d, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7A], source: :d, source_value: 0b11101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b11101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7B], source: :e, source_value: 0b00010000, flags_set_before: [],                 expected_source_value_after: 0b00010000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7B], source: :e, source_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7C], source: :h, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7C], source: :h, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7D], source: :l, source_value: 0b00000000, flags_set_before: [],                 expected_source_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7D], source: :l, source_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_source_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC7], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b00000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC7], source: :a, source_value: 0b10000001, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC0], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b00000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC0], source: :b, source_value: 0b10000001, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC1], source: :c, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b00100001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC1], source: :c, source_value: 0b10001001, flags_set_before: [],                     expected_source_value_after: 0b10001001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC2], source: :d, source_value: 0b00101000, flags_set_before: [],                     expected_source_value_after: 0b00101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC2], source: :d, source_value: 0b11001001, flags_set_before: [],                     expected_source_value_after: 0b11001001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC3], source: :e, source_value: 0b00011000, flags_set_before: [],                     expected_source_value_after: 0b00011001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC3], source: :e, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC4], source: :h, source_value: 0b00001100, flags_set_before: [],                     expected_source_value_after: 0b00001101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC4], source: :h, source_value: 0b10111001, flags_set_before: [],                     expected_source_value_after: 0b10111001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC5], source: :l, source_value: 0b00001110, flags_set_before: [],                     expected_source_value_after: 0b00001111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC5], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCF], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b00000010, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xCF], source: :a, source_value: 0b10000001, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10000011, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xC8], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b00000010, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xC8], source: :b, source_value: 0b10000001, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10000011, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xC9], source: :c, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b00100010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xC9], source: :c, source_value: 0b10001001, flags_set_before: [],                     expected_source_value_after: 0b10001011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCA], source: :d, source_value: 0b00101000, flags_set_before: [],                     expected_source_value_after: 0b00101010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCA], source: :d, source_value: 0b11001001, flags_set_before: [],                     expected_source_value_after: 0b11001011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCB], source: :e, source_value: 0b00011000, flags_set_before: [],                     expected_source_value_after: 0b00011010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCB], source: :e, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCC], source: :h, source_value: 0b00001100, flags_set_before: [],                     expected_source_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCC], source: :h, source_value: 0b10111001, flags_set_before: [],                     expected_source_value_after: 0b10111011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCD], source: :l, source_value: 0b00001110, flags_set_before: [],                     expected_source_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCD], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD7], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b00000100, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD7], source: :a, source_value: 0b10000101, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10000101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD0], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b00000100, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD0], source: :b, source_value: 0b10000101, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10000101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD1], source: :c, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b00100100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD1], source: :c, source_value: 0b10001101, flags_set_before: [],                     expected_source_value_after: 0b10001101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD2], source: :d, source_value: 0b00101000, flags_set_before: [],                     expected_source_value_after: 0b00101100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD2], source: :d, source_value: 0b11001101, flags_set_before: [],                     expected_source_value_after: 0b11001101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD3], source: :e, source_value: 0b00011000, flags_set_before: [],                     expected_source_value_after: 0b00011100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD3], source: :e, source_value: 0b10101101, flags_set_before: [],                     expected_source_value_after: 0b10101101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD4], source: :h, source_value: 0b00001000, flags_set_before: [],                     expected_source_value_after: 0b00001100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD4], source: :h, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD5], source: :l, source_value: 0b00001010, flags_set_before: [],                     expected_source_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD5], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDF], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b00001000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xDF], source: :a, source_value: 0b10001001, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10001001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xD8], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b00001000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xD8], source: :b, source_value: 0b10001001, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10001001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xD9], source: :c, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b00101000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xD9], source: :c, source_value: 0b10001001, flags_set_before: [],                     expected_source_value_after: 0b10001001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDA], source: :d, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b00101000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDA], source: :d, source_value: 0b11001001, flags_set_before: [],                     expected_source_value_after: 0b11001001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDB], source: :e, source_value: 0b00010000, flags_set_before: [],                     expected_source_value_after: 0b00011000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDB], source: :e, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDC], source: :h, source_value: 0b00000100, flags_set_before: [],                     expected_source_value_after: 0b00001100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDC], source: :h, source_value: 0b10111001, flags_set_before: [],                     expected_source_value_after: 0b10111001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDD], source: :l, source_value: 0b00000110, flags_set_before: [],                     expected_source_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDD], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE7], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b00010000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE7], source: :a, source_value: 0b10010101, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE0], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b00010000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE0], source: :b, source_value: 0b10010101, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE1], source: :c, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b00110000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE1], source: :c, source_value: 0b10011101, flags_set_before: [],                     expected_source_value_after: 0b10011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE2], source: :d, source_value: 0b00101000, flags_set_before: [],                     expected_source_value_after: 0b00111000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE2], source: :d, source_value: 0b11011101, flags_set_before: [],                     expected_source_value_after: 0b11011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE3], source: :e, source_value: 0b00001000, flags_set_before: [],                     expected_source_value_after: 0b00011000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE3], source: :e, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE4], source: :h, source_value: 0b00001000, flags_set_before: [],                     expected_source_value_after: 0b00011000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE4], source: :h, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE5], source: :l, source_value: 0b00001010, flags_set_before: [],                     expected_source_value_after: 0b00011010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE5], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEF], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xEF], source: :a, source_value: 0b10101001, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xE8], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xE8], source: :b, source_value: 0b10101001, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xE9], source: :c, source_value: 0b00000000, flags_set_before: [],                     expected_source_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xE9], source: :c, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEA], source: :d, source_value: 0b00000000, flags_set_before: [],                     expected_source_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEA], source: :d, source_value: 0b11101001, flags_set_before: [],                     expected_source_value_after: 0b11101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEB], source: :e, source_value: 0b00010000, flags_set_before: [],                     expected_source_value_after: 0b00110000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEB], source: :e, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEC], source: :h, source_value: 0b00000100, flags_set_before: [],                     expected_source_value_after: 0b00100100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEC], source: :h, source_value: 0b10111001, flags_set_before: [],                     expected_source_value_after: 0b10111001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xED], source: :l, source_value: 0b00000110, flags_set_before: [],                     expected_source_value_after: 0b00100110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xED], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF7], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b01000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF7], source: :a, source_value: 0b11010101, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b11010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF0], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b01000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF0], source: :b, source_value: 0b11010101, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b11010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF1], source: :c, source_value: 0b00100000, flags_set_before: [],                     expected_source_value_after: 0b01100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF1], source: :c, source_value: 0b11011101, flags_set_before: [],                     expected_source_value_after: 0b11011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF2], source: :d, source_value: 0b00101000, flags_set_before: [],                     expected_source_value_after: 0b01101000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF2], source: :d, source_value: 0b11011101, flags_set_before: [],                     expected_source_value_after: 0b11011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF3], source: :e, source_value: 0b00001000, flags_set_before: [],                     expected_source_value_after: 0b01001000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF3], source: :e, source_value: 0b11111101, flags_set_before: [],                     expected_source_value_after: 0b11111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF4], source: :h, source_value: 0b00001000, flags_set_before: [],                     expected_source_value_after: 0b01001000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF4], source: :h, source_value: 0b11111101, flags_set_before: [],                     expected_source_value_after: 0b11111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF5], source: :l, source_value: 0b00001010, flags_set_before: [],                     expected_source_value_after: 0b01001010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF5], source: :l, source_value: 0b11111101, flags_set_before: [],                     expected_source_value_after: 0b11111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFF], source: :a, source_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_source_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xFF], source: :a, source_value: 0b10101001, flags_set_before: [CPU::ZERO_FLAG],       expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xF8], source: :b, source_value: 0b00000000, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_source_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xF8], source: :b, source_value: 0b10101001, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xF9], source: :c, source_value: 0b00000000, flags_set_before: [],                     expected_source_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xF9], source: :c, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFA], source: :d, source_value: 0b00000000, flags_set_before: [],                     expected_source_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFA], source: :d, source_value: 0b11101001, flags_set_before: [],                     expected_source_value_after: 0b11101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFB], source: :e, source_value: 0b00010000, flags_set_before: [],                     expected_source_value_after: 0b10010000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFB], source: :e, source_value: 0b10101001, flags_set_before: [],                     expected_source_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFC], source: :h, source_value: 0b00000100, flags_set_before: [],                     expected_source_value_after: 0b10000100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFC], source: :h, source_value: 0b10111001, flags_set_before: [],                     expected_source_value_after: 0b10111001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFD], source: :l, source_value: 0b00000110, flags_set_before: [],                     expected_source_value_after: 0b10000110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFD], source: :l, source_value: 0b10111101, flags_set_before: [],                     expected_source_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                ]

                bit_manipulation_instructions.each do |inst|
                    describe "#{inst[:type]} r" do
                        let(:data) { inst[:opcodes] }

                        before do
                            subject.registers[inst[:source]] = inst[:source_value]

                            unless inst[:flags_set_before].nil?
                                inst[:flags_set_before].each do |flag|
                                    subject.registers[:f] |= flag
                                end
                            end
                        end

                        it "should update value in source" do
                            subject.instruction data

                            _(subject.registers[inst[:source]]).must_equal(inst[:expected_source_value_after])
                        end

                        it "should set the flags #{inst[:expected_flags_set_after]}" do
                            subject.instruction data

                            inst[:expected_flags_set_after].each do |flag|
                                _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                            end
                        end

                        if (inst[:expected_flags_unset_after].nil?)
                            it 'should clear half-carry and subtract flags' do
                                subject.registers[:f] |= CPU::HALF_CARRY_FLAG
                                subject.registers[:f] |= CPU::SUBTRACT_FLAG

                                subject.instruction data

                                _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false
                                _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                            end
                        else
                            it "should unset the flags #{inst[:expected_flags_unset_after]}" do
                                subject.instruction data

                                inst[:expected_flags_unset_after].each do |flag|
                                    _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                                end
                            end
                        end

                        it 'should return correct amount of cycles used' do
                          cycles = subject.instruction data

                          _(cycles).must_equal 8
                        end

                        it 'should update the program_counter correctly' do
                            subject.program_counter = 0x100

                            subject.instruction data

                            _(subject.program_counter).must_equal(0x102)
                        end
                    end
                end

                bit_manipulation_hl_instructions = [
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0xFF00, memory_value: 0b00000000, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0xFF01, memory_value: 0b10000000, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0xFA00, memory_value: 0b00000001, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b00000011, expected_flags_set_after: [] },
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0xF020, memory_value: 0b10101010, flags_set_before: [], expected_memory_value_after: 0b01010100, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0xFE02, memory_value: 0b11111111, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b11111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0xAFC0, memory_value: 0b10000001, flags_set_before: [], expected_memory_value_after: 0b00000010, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RL", opcodes: [0xCB, 0x16], memory_address: 0x2211, memory_value: 0b00000001, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b00000011, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x2212, memory_value: 0b11001001, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b11100100, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x2251, memory_value: 0b11001001, flags_set_before: [], expected_memory_value_after: 0b01100100, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x2211, memory_value: 0b00000001, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x2A11, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b10000000, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0xF211, memory_value: 0b10101010, flags_set_before: [], expected_memory_value_after: 0b01010101, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x2B11, memory_value: 0b11111111, flags_set_before: [], expected_memory_value_after: 0b01111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x22A1, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b10000000, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x22C1, memory_value: 0b00000010, flags_set_before: [], expected_memory_value_after: 0b00000001, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x0211, memory_value: 0b01010101, flags_set_before: [CPU::CARRY_FLAG], expected_memory_value_after: 0b10101010, expected_flags_set_after: [] },
                    { type: "RR", opcodes: [0xCB, 0x1E], memory_address: 0x2111, memory_value: 0b10000000, flags_set_before: [], expected_memory_value_after: 0b01000000, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0001, memory_value: 0b01101010, flags_set_before: [], expected_memory_value_after: 0b11010100, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0011, memory_value: 0b10000000, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0021, memory_value: 0b00000001, flags_set_before: [], expected_memory_value_after: 0b00000010, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0301, memory_value: 0b00000000, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x5001, memory_value: 0b01010101, flags_set_before: [], expected_memory_value_after: 0b10101010, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0501, memory_value: 0b00111111, flags_set_before: [], expected_memory_value_after: 0b01111110, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0A01, memory_value: 0b00000010, flags_set_before: [], expected_memory_value_after: 0b00000100, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x0B01, memory_value: 0b11111111, flags_set_before: [], expected_memory_value_after: 0b11111110, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x00C1, memory_value: 0b00001111, flags_set_before: [], expected_memory_value_after: 0b00011110, expected_flags_set_after: [] },
                    { type: "SLA", opcodes: [0xCB, 0x26], memory_address: 0x000D, memory_value: 0b01111111, flags_set_before: [], expected_memory_value_after: 0b11111110, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x0234, memory_value: 0b01111111, flags_set_before: [], expected_memory_value_after: 0b00111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x0235, memory_value: 0b10000000, flags_set_before: [], expected_memory_value_after: 0b11000000, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x0236, memory_value: 0b00000000, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x0237, memory_value: 0b11010101, flags_set_before: [], expected_memory_value_after: 0b11101010, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x0238, memory_value: 0b11010101, flags_set_before: [], expected_memory_value_after: 0b11101010, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x0239, memory_value: 0b10101010, flags_set_before: [], expected_memory_value_after: 0b11010101, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x023A, memory_value: 0b10101010, flags_set_before: [], expected_memory_value_after: 0b11010101, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x023B, memory_value: 0b10101010, flags_set_before: [], expected_memory_value_after: 0b11010101, expected_flags_set_after: [] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x023C, memory_value: 0b01111111, flags_set_before: [], expected_memory_value_after: 0b00111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x023D, memory_value: 0b00001111, flags_set_before: [], expected_memory_value_after: 0b00000111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRA", opcodes: [0xCB, 0x2E], memory_address: 0x023E, memory_value: 0b11101111, flags_set_before: [], expected_memory_value_after: 0b11110111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b00000000, expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b01010101, expected_memory_value_after: 0b01010101, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b10110011, expected_memory_value_after: 0b00111011, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b11110000, expected_memory_value_after: 0b00001111, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b00001111, expected_memory_value_after: 0b11110000, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b10011001, expected_memory_value_after: 0b10011001, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b01100110, expected_memory_value_after: 0b01100110, expected_flags_set_after: [] },
                    { type: "SWAP", opcodes: [0xCB, 0x36], memory_address: 0x0010, memory_value: 0b11110011, expected_memory_value_after: 0b00111111, expected_flags_set_after: [] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b10000000, flags_set_before: [], expected_memory_value_after: 0b01000000, expected_flags_set_after: [] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b00000001, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b00000001, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b10000001, flags_set_before: [], expected_memory_value_after: 0b01000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b00000010, flags_set_before: [], expected_memory_value_after: 0b00000001, expected_flags_set_after: [] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b11111111, flags_set_before: [], expected_memory_value_after: 0b01111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b00000000, flags_set_before: [], expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SRL", opcodes: [0xCB, 0x3E], memory_address: 0x0020, memory_value: 0b11111110, flags_set_before: [], expected_memory_value_after: 0b01111111, expected_flags_set_after: [] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b10000001, flags_set_before: [],                 expected_memory_value_after: 0b10000001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b10000001, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10000001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b10001001, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10001001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                 expected_memory_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b11001001, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11001001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00011000, flags_set_before: [],                 expected_memory_value_after: 0b00011000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b10101001, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00001100, flags_set_before: [],                 expected_memory_value_after: 0b00001100, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b10111001, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111001, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b00001110, flags_set_before: [],                 expected_memory_value_after: 0b00001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 0", opcodes: [0xCB, 0x46], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b10000010, flags_set_before: [],                 expected_memory_value_after: 0b10000010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b10000010, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10000010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b10001010, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00101000, flags_set_before: [],                 expected_memory_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b11001010, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00011000, flags_set_before: [],                 expected_memory_value_after: 0b00011000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b10101010, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00001100, flags_set_before: [],                 expected_memory_value_after: 0b00001100, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b10111010, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b00001100, flags_set_before: [],                 expected_memory_value_after: 0b00001100, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 1", opcodes: [0xCB, 0x4E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b10000101, flags_set_before: [],                 expected_memory_value_after: 0b10000101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b10000101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10000101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b10001101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10001101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                 expected_memory_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b11001101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11001101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00011000, flags_set_before: [],                 expected_memory_value_after: 0b00011000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b10101101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                 expected_memory_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b00001010, flags_set_before: [],                 expected_memory_value_after: 0b00001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 2", opcodes: [0xCB, 0x56], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b10001110, flags_set_before: [],                 expected_memory_value_after: 0b10001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b10001110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b10001110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b11001110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11001110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00010000, flags_set_before: [],                 expected_memory_value_after: 0b00010000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 3", opcodes: [0xCB, 0x5E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b10010101, flags_set_before: [],                 expected_memory_value_after: 0b10010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b10010101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b10011101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                 expected_memory_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b11011101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                 expected_memory_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                 expected_memory_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b00001010, flags_set_before: [],                 expected_memory_value_after: 0b00001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 4", opcodes: [0xCB, 0x66], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [],                 expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b11101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00010000, flags_set_before: [],                 expected_memory_value_after: 0b00010000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 5", opcodes: [0xCB, 0x6E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11010101, flags_set_before: [],                 expected_memory_value_after: 0b11010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11010101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11010101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                 expected_memory_value_after: 0b00100000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11011101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                 expected_memory_value_after: 0b00101000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11011101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11011101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                 expected_memory_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                 expected_memory_value_after: 0b00001000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b00001010, flags_set_before: [],                 expected_memory_value_after: 0b00001010, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 6", opcodes: [0xCB, 0x76], memory_address: 0x0321, memory_value: 0b11111101, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11111101, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [],                 expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b11101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b11101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00010000, flags_set_before: [],                 expected_memory_value_after: 0b00010000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b10101110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10101110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b00000000, flags_set_before: [],                 expected_memory_value_after: 0b00000000, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::ZERO_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "BIT 7", opcodes: [0xCB, 0x7E], memory_address: 0x0410, memory_value: 0b10111110, flags_set_before: [CPU::CARRY_FLAG],  expected_memory_value_after: 0b10111110, expected_flags_unset_after: [CPU::SUBTRACT_FLAG], expected_flags_set_after: [CPU::CARRY_FLAG, CPU::HALF_CARRY_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b00000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b10000001, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b00000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b10000001, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10000001, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b00100001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b10001001, flags_set_before: [],                     expected_memory_value_after: 0b10001001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                     expected_memory_value_after: 0b00101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b11001001, flags_set_before: [],                     expected_memory_value_after: 0b11001001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00011000, flags_set_before: [],                     expected_memory_value_after: 0b00011001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b10101001, flags_set_before: [],                     expected_memory_value_after: 0b10101001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00001100, flags_set_before: [],                     expected_memory_value_after: 0b00001101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b10111001, flags_set_before: [],                     expected_memory_value_after: 0b10111001, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b00001110, flags_set_before: [],                     expected_memory_value_after: 0b00001111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 0", opcodes: [0xCB, 0xC6], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [],                     expected_memory_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b00000010, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b10000011, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10000011, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b00000010, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b10000011, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10000011, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b00100010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b10001011, flags_set_before: [],                     expected_memory_value_after: 0b10001011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                     expected_memory_value_after: 0b00101010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b11001011, flags_set_before: [],                     expected_memory_value_after: 0b11001011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00011000, flags_set_before: [],                     expected_memory_value_after: 0b00011010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b10101011, flags_set_before: [],                     expected_memory_value_after: 0b10101011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00001100, flags_set_before: [],                     expected_memory_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b10111011, flags_set_before: [],                     expected_memory_value_after: 0b10111011, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b00001100, flags_set_before: [],                     expected_memory_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 1", opcodes: [0xCB, 0xCE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b00000100, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b10000101, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10000101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b00000100, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b10000101, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10000101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b00100100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b10001101, flags_set_before: [],                     expected_memory_value_after: 0b10001101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                     expected_memory_value_after: 0b00101100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b11001101, flags_set_before: [],                     expected_memory_value_after: 0b11001101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00011000, flags_set_before: [],                     expected_memory_value_after: 0b00011100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b10101101, flags_set_before: [],                     expected_memory_value_after: 0b10101101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                     expected_memory_value_after: 0b00001100, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [],                     expected_memory_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b00001010, flags_set_before: [],                     expected_memory_value_after: 0b00001110, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 2", opcodes: [0xCB, 0xD6], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [],                     expected_memory_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b00001000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b10001111, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10001111, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b00001000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b10001111, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10001111, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b00101000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b10001111, flags_set_before: [],                     expected_memory_value_after: 0b10001111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b00101000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b11001111, flags_set_before: [],                     expected_memory_value_after: 0b11001111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00010000, flags_set_before: [],                     expected_memory_value_after: 0b00011000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [],                     expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b00001000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b00001000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 3", opcodes: [0xCB, 0xDE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b00010000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b10010101, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b00010000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b10010101, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b00110000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b10011101, flags_set_before: [],                     expected_memory_value_after: 0b10011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                     expected_memory_value_after: 0b00111000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b11011101, flags_set_before: [],                     expected_memory_value_after: 0b11011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                     expected_memory_value_after: 0b00011000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [],                     expected_memory_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                     expected_memory_value_after: 0b00011000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [],                     expected_memory_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b00001010, flags_set_before: [],                     expected_memory_value_after: 0b00011010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 4", opcodes: [0xCB, 0xE6], memory_address: 0x0321, memory_value: 0b10111101, flags_set_before: [],                     expected_memory_value_after: 0b10111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [],                     expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b11101111, flags_set_before: [],                     expected_memory_value_after: 0b11101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00010000, flags_set_before: [],                     expected_memory_value_after: 0b00110000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [],                     expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b00100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 5", opcodes: [0xCB, 0xEE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b01000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11010101, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b11010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b01000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11010101, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b11010101, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00100000, flags_set_before: [],                     expected_memory_value_after: 0b01100000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11011101, flags_set_before: [],                     expected_memory_value_after: 0b11011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00101000, flags_set_before: [],                     expected_memory_value_after: 0b01101000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11011101, flags_set_before: [],                     expected_memory_value_after: 0b11011101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                     expected_memory_value_after: 0b01001000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11111101, flags_set_before: [],                     expected_memory_value_after: 0b11111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00001000, flags_set_before: [],                     expected_memory_value_after: 0b01001000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11111101, flags_set_before: [],                     expected_memory_value_after: 0b11111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b00001010, flags_set_before: [],                     expected_memory_value_after: 0b01001010, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 6", opcodes: [0xCB, 0xF6], memory_address: 0x0321, memory_value: 0b11111101, flags_set_before: [],                     expected_memory_value_after: 0b11111101, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::CARRY_FLAG],      expected_memory_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [CPU::ZERO_FLAG],       expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [CPU::HALF_CARRY_FLAG], expected_memory_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [CPU::HALF_CARRY_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [CPU::SUBTRACT_FLAG],   expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [CPU::SUBTRACT_FLAG] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [],                     expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b11101111, flags_set_before: [],                     expected_memory_value_after: 0b11101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00010000, flags_set_before: [],                     expected_memory_value_after: 0b10010000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b10101111, flags_set_before: [],                     expected_memory_value_after: 0b10101111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b00000000, flags_set_before: [],                     expected_memory_value_after: 0b10000000, expected_flags_unset_after: [], expected_flags_set_after: [] },
                    { type: "SET 7", opcodes: [0xCB, 0xFE], memory_address: 0x0321, memory_value: 0b10111111, flags_set_before: [],                     expected_memory_value_after: 0b10111111, expected_flags_unset_after: [], expected_flags_set_after: [] },
                ]

                bit_manipulation_hl_instructions.each do |inst|
                    describe "#{inst[:type]} (HL)" do
                        let(:data) { inst[:opcodes] }

                        before do
                            memory[inst[:memory_address]] = inst[:memory_value]

                            subject.registers[:h] = Utils.get_hi(inst[:memory_address])
                            subject.registers[:l] = Utils.get_lo(inst[:memory_address])

                            unless inst[:flags_set_before].nil?
                                inst[:flags_set_before].each do |flag|
                                    subject.registers[:f] |= flag
                                end
                            end
                        end

                        it "should update value in (HL)" do
                            subject.instruction data

                            _(memory[inst[:memory_address]]).must_equal(inst[:expected_memory_value_after])
                        end

                        it "should set the flags #{inst[:expected_flags_set_after]}" do
                            subject.instruction data

                            inst[:expected_flags_set_after].each do |flag|
                                _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                            end
                        end

                        if (inst[:expected_flags_unset_after].nil?)
                            it 'should clear half-carry and subtract flags' do
                                subject.registers[:f] |= CPU::HALF_CARRY_FLAG
                                subject.registers[:f] |= CPU::SUBTRACT_FLAG

                                subject.instruction data

                                _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false
                                _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                            end
                        else
                            it "should unset the flags #{inst[:expected_flags_unset_after]}" do
                                subject.instruction data

                                inst[:expected_flags_unset_after].each do |flag|
                                    _(Utils.flag_set?(subject.registers[:f], flag)).must_equal false
                                end
                            end
                        end


                        it 'should return correct amount of cycles used' do
                          cycles = subject.instruction data

                          _(cycles).must_equal 16
                        end

                        it 'should update the program_counter correctly' do
                            subject.program_counter = 0x100

                            subject.instruction data

                            _(subject.program_counter).must_equal(0x102)
                        end
                    end
                end

                rlc_hl_instructions = [
                    { opcodes: [0xCB, 0x06], memory_address: 0xFF00, memory_value: 0b00000000, expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { opcodes: [0xCB, 0x06], memory_address: 0xFF01, memory_value: 0b11001010, expected_memory_value_after: 0b10010101, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { opcodes: [0xCB, 0x06], memory_address: 0xFA00, memory_value: 0b11111111, expected_memory_value_after: 0b11111111, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { opcodes: [0xCB, 0x06], memory_address: 0xF020, memory_value: 0b01010101, expected_memory_value_after: 0b10101010, expected_flags_set_after: [] },
                    { opcodes: [0xCB, 0x06], memory_address: 0xFE02, memory_value: 0b10000000, expected_memory_value_after: 0b00000001, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { opcodes: [0xCB, 0x06], memory_address: 0xAFC0, memory_value: 0b00000001, expected_memory_value_after: 0b00000010, expected_flags_set_after: [] },
                    { opcodes: [0xCB, 0x06], memory_address: 0x2211, memory_value: 0b11110000, expected_memory_value_after: 0b11100001, expected_flags_set_after: [CPU::CARRY_FLAG] },
                ]

                rlc_hl_instructions.each do |inst|
                    describe 'RLC (HL)' do
                        let(:data) { inst[:opcodes] }

                        before do
                            memory[inst[:memory_address]] = inst[:memory_value]

                            subject.registers[:h] = Utils.get_hi(inst[:memory_address])
                            subject.registers[:l] = Utils.get_lo(inst[:memory_address])
                        end

                        it "should rotate value in (HL)" do
                            subject.instruction data

                            _(memory[inst[:memory_address]]).must_equal(inst[:expected_memory_value_after])
                        end

                        it "should set the flags #{inst[:expected_flags_set_after]}" do
                            subject.instruction data

                            inst[:expected_flags_set_after].each do |flag|
                                _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                            end
                        end

                        it 'should clear half-carry and subtract flags' do
                            subject.registers[:f] |= CPU::HALF_CARRY_FLAG
                            subject.registers[:f] |= CPU::SUBTRACT_FLAG

                            subject.instruction data

                            _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false
                            _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                        end

                        it 'should return correct amount of cycles used' do
                          cycles = subject.instruction data

                          _(cycles).must_equal 16
                        end

                        it 'should update the program_counter correctly' do
                            subject.program_counter = 0x100

                            subject.instruction data

                            _(subject.program_counter).must_equal(0x102)
                        end
                    end
                end

                rrc_hl_instructions = [
                    { opcodes: [0xCB, 0x0E], memory_address: 0xFF00, memory_value: 0b00000000, expected_memory_value_after: 0b00000000, expected_flags_set_after: [CPU::ZERO_FLAG] },
                    { opcodes: [0xCB, 0x0E], memory_address: 0xFF01, memory_value: 0b00000001, expected_memory_value_after: 0b10000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { opcodes: [0xCB, 0x0E], memory_address: 0xFA00, memory_value: 0b11110000, expected_memory_value_after: 0b01111000, expected_flags_set_after: [] },
                    { opcodes: [0xCB, 0x0E], memory_address: 0xF020, memory_value: 0b10101010, expected_memory_value_after: 0b01010101, expected_flags_set_after: [] },
                    { opcodes: [0xCB, 0x0E], memory_address: 0xFE02, memory_value: 0b00000010, expected_memory_value_after: 0b00000001, expected_flags_set_after: [] },
                    { opcodes: [0xCB, 0x0E], memory_address: 0xAFC0, memory_value: 0b10000001, expected_memory_value_after: 0b11000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                    { opcodes: [0xCB, 0x0E], memory_address: 0x2211, memory_value: 0b00000001, expected_memory_value_after: 0b10000000, expected_flags_set_after: [CPU::CARRY_FLAG] },
                ]

                rrc_hl_instructions.each do |inst|
                    describe 'rrc (HL)' do
                        let(:data) { inst[:opcodes] }

                        before do
                            memory[inst[:memory_address]] = inst[:memory_value]

                            subject.registers[:h] = Utils.get_hi(inst[:memory_address])
                            subject.registers[:l] = Utils.get_lo(inst[:memory_address])
                        end

                        it "should rotate value in (HL)" do
                            subject.instruction data

                            _(memory[inst[:memory_address]]).must_equal(inst[:expected_memory_value_after])
                        end

                        it "should set the flags #{inst[:expected_flags_set_after]}" do
                            subject.instruction data

                            inst[:expected_flags_set_after].each do |flag|
                                _(Utils.flag_set?(subject.registers[:f], flag)).must_equal true
                            end
                        end

                        it 'should clear half-carry and subtract flags' do
                            subject.registers[:f] |= CPU::HALF_CARRY_FLAG
                            subject.registers[:f] |= CPU::SUBTRACT_FLAG

                            subject.instruction data

                            _(Utils.flag_set?(subject.registers[:f], CPU::HALF_CARRY_FLAG)).must_equal false
                            _(Utils.flag_set?(subject.registers[:f], CPU::SUBTRACT_FLAG)).must_equal false
                        end

                        it 'should return correct amount of cycles used' do
                          cycles = subject.instruction data

                          _(cycles).must_equal 16
                        end

                        it 'should update the program_counter correctly' do
                            subject.program_counter = 0x100

                            subject.instruction data

                            _(subject.program_counter).must_equal(0x102)
                        end
                    end
                end
            end
        end
    end
end