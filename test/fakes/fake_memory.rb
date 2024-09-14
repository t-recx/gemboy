class FakeMemory
    def initialize
        @memory = Array.new(0x10000, 0)
    end

    def [](address)
        return @memory[address]
    end

    def []=(address, value)
        @memory[address] = value
    end
end