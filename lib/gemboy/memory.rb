module Gemboy
  # 0x0000 - 0x3FFF: ROM Bank 0 (Fixed)
  #
  #    This is where the system’s boot ROM and the first part of the game’s ROM reside.
  #
  # 0x4000 - 0x7FFF: Switchable ROM Bank
  #
  #    Additional ROM banks from the cartridge can be mapped here, allowing for larger game programs.
  #
  # 0x8000 - 0x9FFF: Video RAM (VRAM)
  #
  #    This is memory used by the Game Boy's GPU for storing tile data, backgrounds, and sprites.
  #
  # 0xA000 - 0xBFFF: Switchable External RAM
  #
  #    Some Game Boy cartridges come with additional external RAM, which is mapped here.
  #
  # 0xC000 - 0xCFFF: Internal RAM (Work RAM)
  #
  #    This is the Game Boy's internal work RAM, where the CPU can store variables and temporary data.
  #
  # 0xD000 - 0xDFFF: Internal RAM (Work RAM - Banked)
  #
  #    Additional work RAM that can be banked in larger memory configurations (for Game Boy Color, for example).
  #
  # 0xE000 - 0xFDFF: Echo RAM
  #
  #    This mirrors the addresses from 0xC000 to 0xDDFF. Writing here affects the same RAM as the internal work RAM.
  #
  # 0xFE00 - 0xFE9F: Sprite Attribute Table (OAM)
  #
  #    This is where sprite data is stored.
  #
  # 0xFEA0 - 0xFEFF: Not Usable
  #
  #    Unusable memory region.
  #
  # 0xFF00 - 0xFF7F: Hardware I/O Registers
  #
  #    Memory-mapped I/O ports for controlling the Game Boy’s hardware (e.g., joypad input, timers, sound).
  #
  # 0xFF80 - 0xFFFE: High RAM (HRAM)
  #
  #    A small chunk of high-speed RAM for the CPU to store small data.
  #
  # 0xFFFF: Interrupt Enable Register
  #
  #    Used for enabling/disabling interrupts.

  class Memory
    def initialize
      @vram = Array.new(0x2000, 0)        # 8KB Video RAM
      @wram = Array.new(0x2000, 0)        # 8KB Working RAM
      @oam = Array.new(0xA0, 0)           # Object Attribute Memory
      @io_registers = Array.new(0x80, 0)  # IO Registers
      @hram = Array.new(0x7F, 0)          # High RAM
      @rom = Array.new(0x8000, 0)         # ROM space for simplicity
      @ie_register = 0                    # Interrupt enable register
    end

    def [](address)
      case address
      when 0x0000..0x7FFF   # ROM
        @rom[address] # TODO: implement bank switching
      when 0x8000..0x9FFF   # VRAM
        @vram[address - 0x8000]
      when 0xA000..0xBFFF   # External RAM (if present)
        @external_ram[address - 0xA000] = value # TODO: implement bank switching, also: it might be used to save games if battery backed
      when 0xC000..0xDFFF   # WRAM
        @wram[address - 0xC000]
      when 0xE000..0xFDFF   # Echo of WRAM
        @wram[address - 0xE000]
      when 0xFE00..0xFE9F   # OAM
        @oam[address - 0xFE00]
      when 0xFF00..0xFF7F   # I/O Registers
        @io_registers[address - 0xFF00]
      when 0xFF80..0xFFFE   # HRAM
        @hram[address - 0xFF80]
      when 0xFFFF           # Interrupt Enable Register
        @ie_register
      else
        0  # Unused memory
      end
    end

    def []=(address, value)
      case address
      when 0xFF46  # DMA transfer
        start_address = value << 8  # The starting address for the DMA
        start_address &= 0xFF00     # Ensure the address is valid (0x0000 to 0x7F00)

        # Perform the DMA transfer
        dma_transfer(start_address)
      when 0x8000..0x9FFF   # VRAM
        @vram[address - 0x8000] = value
      when 0xA000..0xBFFF   # External RAM (if present)
        @external_ram[address - 0xA000] # TODO: implement bank switching, also: it might be used to save games if battery backed
      when 0xC000..0xDFFF   # WRAM
        @wram[address - 0xC000] = value
      when 0xE000..0xFDFF   # Echo of WRAM
        @wram[address - 0xE000] = value
      when 0xFE00..0xFE9F   # OAM
        @oam[address - 0xFE00] = value
      when 0xFF00..0xFF7F   # I/O Registers
        @io_registers[address - 0xFF00] = value
      when 0xFF80..0xFFFE   # HRAM
        @hram[address - 0xFF80] = value
      when 0xFFFF           # Interrupt Enable Register
        @ie_register = value & 0x1F
      end
    end

    private

    def dma_transfer(start_address)
      # Ensure we are within valid VRAM range (0x8000 to 0x97FF)
      return if start_address < 0x8000 || start_address >= 0xA000

      # Copy 160 bytes from VRAM to OAM
      (0..0x9F).each do |i|
        @oam[i] = read_memory(start_address + i)
      end
    end
  end
end
