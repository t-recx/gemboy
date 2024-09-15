require 'test_helper'
require 'gemboy'
require 'fakes/fake_memory'

include Gemboy

describe CPU do
    let(:memory) { FakeMemory.new }
    subject { CPU.new memory }

    describe :instruction do
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
        end
    end
end