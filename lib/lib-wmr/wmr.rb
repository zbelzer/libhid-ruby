module WMR
  WMR100_VENDOR_ID = 0x0fde
  WMR100_PRODUCT_ID = 0xca01

  RECV_PACKET_LEN   = 8
  BUF_SIZE = 255
  PATHLEN = 2
  PATH_IN  = [ 0xff000001, 0xff000001 ]
  PATH_OUT = [ 0xff000001, 0xff000002 ]
  INIT_PACKET1 = [ 0x20, 0x00, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
  INIT_PACKET2 = [ 0x01, 0xd0, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
  USB_ENDPOINT_IN	= 0x80
  USB_ENDPOINT_OUT = 0x00

  RETRIES = 10

  def self.send_init_packet(interface)
    path_in = FFI::Buffer.new :int, 2
    LibHID::Native.write_bignum32_array path_in, PATH_IN

    init_packet = FFI::MemoryPointer.new(INIT_PACKET1.size * 1).write_array_of_char(INIT_PACKET1)
    result = LibHID::Native.hid_set_output_report(interface.to_ptr, path_in, 2, init_packet, init_packet.size)
    # LibHID.check_result "Sending init packet", result
  end

  def self.send_ready_packet(interface)
    path_in = FFI::Buffer.new :int, 2
    LibHID::Native.write_bignum32_array path_in, PATH_IN

    ready_packet = FFI::MemoryPointer.new(INIT_PACKET2.size * 1).write_array_of_char(INIT_PACKET2)
    result = LibHID::Native.hid_set_output_report(interface.to_ptr, path_in, 2, ready_packet, ready_packet.size)
    # LibHID.check_result "Sending init packet", result
  end

  def self.check_result(operation, result)
    if result == :hid_ret_success
      puts "#{operation}... success"
    else
      raise "#{operation} failed with #{result}"
    end
  end

  class Interface
    include Colorize

    def initialize
      initialize_native_interface

      @buffer = FFI::Buffer.new :char, BUF_SIZE
      @remaining = 0
      @position = 1
    end

    def initialize_native_interface
      WMR.check_result "Initilizing device", LibHID::Native.hid_init

      interface_ptr = LibHID::Native.hid_new_HIDInterface
      @native_interface = LibHID::Native::HIDInterface.new(interface_ptr)

      matcher_ptr = FFI::MemoryPointer.new LibHID::Native::HIDInterfaceMatcher.size
      matcher = LibHID::Native::HIDInterfaceMatcher.new(matcher_ptr)

      matcher[:vendor_id] = WMR100_VENDOR_ID
      matcher[:product_id] = WMR100_PRODUCT_ID

      WMR.check_result "Opening device", LibHID::Native.hid_force_open(interface_ptr, 0, matcher_ptr, RETRIES)

      WMR.send_init_packet(@native_interface)
      WMR.send_ready_packet(@native_interface)

      puts "Found on USB: #{@native_interface[:id]}"
    end

    def inspect_packet(offset, length)
      data = @buffer.get_bytes(offset, length)
      data_array = (0...RECV_PACKET_LEN).map {|x| data[x]}

      pretty = data_array.map do |byte|
        if byte.nil?
          red("nil")
        else
          text = byte.to_s(16).rjust(2, '0')

          case text
          when "ff"
            yellow(text)
          when "01"
            blue(text)
          when "42"
            green(text)
          else
            text
          end
        end
      end

      puts pretty.compact.join(' ')
    end

    def read_packet
      # puts "Reading packet"
      LibHID::Native.hid_interrupt_read(@native_interface.to_ptr, USB_ENDPOINT_IN + 1, @buffer, RECV_PACKET_LEN, 0)
      inspect_packet(0, RECV_PACKET_LEN)

      len = @buffer.get_bytes(0, 1)[0].to_i
      # puts "Length is #{len.to_s(16)}" unless len.nil?

      length = [len, 7].min
      @position = 1
      @remaining = length
    end

    def read_byte
      read_packet while @remaining.zero? 
      # puts "Reading byte at position #{@position}"

      byte = @buffer.get_bytes(@position, 1)[0].to_i
      @position += 1
      @remaining -= 1

      # puts "Read byte #{byte.to_s(16)}, position #{@position}, remaining #{@remaining}" unless byte.nil?

      byte
    end

    def fetch_data(unk1, type, data_len)
      if data_len > 0
        data = [unk1, type]

        (data_len -2).times do
          data << read_byte
        end

        data
      end
    end

    def read_data
      byte = read_byte
      while byte != 0xff do
        byte = read_byte
      end

      # search for not 0xff
      byte = read_byte
      while byte == 0xff do
        byte = read_byte
      end

      unk1 = byte
      type = read_byte

      data_len = 0

      case(type)
      when 0x41
        data = fetch_data(unk1, type, 17)
        puts "Rain: #{data.inspect}"
      when 0x42
        data = fetch_data(unk1, type, 12)
        temp = (data[3] + ((data[4] & 0x0f) << 8)) / 10.0;
        temp = ((data[4] >> 4) == 0x8) ? -temp : temp

        puts "Temp: #{temp}"
      when 0x44
        data = fetch_data(unk1, type, 7)
        puts "Water: #{data.inspect}"
      when 0x46
        data = fetch_data(unk1, type, 8)
        puts "Pressure: #{data.inspect}"
      when 0x47
        data = fetch_data(unk1, type, 5)
        puts "UV: #{data.inspect}"
      when 0x48
        data = fetch_data(unk1, type, 11)
        puts "Wind: #{data.inspect}"
      when 0x60
        data = fetch_data(unk1, type, 12)
        puts "Clock: #{print_data(data)}"

        mi = data[4];
        hr = data[5];
        dy = data[6];
        mo = data[7];
        yr = data[8] + 2000;

        printf("%02d/%02d/%04d %02d:%02d\n", mo, dy, yr, hr, mi)
      else
        printf("Unknown packet type: %02x, skipping\n", type)
      end

      #  if verify_checksum(data, data_len) == 0
      #    wmr_handle_packet(wmr, data, data_len)
      #  end

      WMR.send_ready_packet(@native_interface)
    end

    def print_data(data)
      data.map {|d| d.to_s(16).rjust(2, '0') if d}.join(' ')
    end

    def cleanup
      LibHID::Native.hid_close(@native_interface)
      LibHID::Native.hid_delete_HIDInterface(@native_interface)
      LibHID::Native.hid_cleanup
    end
  end
end
