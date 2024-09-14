module Gemboy
# TODO: Handle all of this:
#0x0000 - 0x3FFF: ROM Bank 0 (Fixed)
#
#    This is where the system’s boot ROM and the first part of the game’s ROM reside.
#
#0x4000 - 0x7FFF: Switchable ROM Bank
#
#    Additional ROM banks from the cartridge can be mapped here, allowing for larger game programs.
#
#0x8000 - 0x9FFF: Video RAM (VRAM)
#
#    This is memory used by the Game Boy's GPU for storing tile data, backgrounds, and sprites.
#
#0xA000 - 0xBFFF: Switchable External RAM
#
#    Some Game Boy cartridges come with additional external RAM, which is mapped here.
#
#0xC000 - 0xCFFF: Internal RAM (Work RAM)
#
#    This is the Game Boy's internal work RAM, where the CPU can store variables and temporary data.
#
#0xD000 - 0xDFFF: Internal RAM (Work RAM - Banked)
#
#    Additional work RAM that can be banked in larger memory configurations (for Game Boy Color, for example).
#
#0xE000 - 0xFDFF: Echo RAM
#
#    This mirrors the addresses from 0xC000 to 0xDDFF. Writing here affects the same RAM as the internal work RAM.
#
#0xFE00 - 0xFE9F: Sprite Attribute Table (OAM)
#
#    This is where sprite data is stored.
#
#0xFEA0 - 0xFEFF: Not Usable
#
#    Unusable memory region.
#
#0xFF00 - 0xFF7F: Hardware I/O Registers
#
#    Memory-mapped I/O ports for controlling the Game Boy’s hardware (e.g., joypad input, timers, sound).
#
#0xFF80 - 0xFFFE: High RAM (HRAM)
#
#    A small chunk of high-speed RAM for the CPU to store small data.
#
#0xFFFF: Interrupt Enable Register
#
#    Used for enabling/disabling interrupts.

    class Memory
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
end