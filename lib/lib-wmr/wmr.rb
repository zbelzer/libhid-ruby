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

    def inspect_data(data_array)
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
      # data = @buffer.get_bytes(0, RECV_PACKET_LEN)
      # inspect_data(data)

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

    def read_bytes(length)
      1.upto(length).map {read_byte}
    end

    def verify_checksum!(data)
      length = data.size

      calc = (0...(length-2)).inject(0) { |sum, i| sum += data[i] }
      checksum = data[length-2] + (data[length-1] << 8)

      if calc != checksum
        raise "Bad checksum: #{checksum} / calc: #{calc}"
      end
    end

    def read_data
      # search for 0xff
      byte = read_byte while byte != 0xff 

      # search for not 0xff
      byte = read_byte while byte == 0xff 

      unk1 = byte
      type = read_byte

      if type_name = TYPES[type]
        raw_data = [unk1, type].push(*read_bytes(SIZES[type]))
        inspect_data(raw_data)

        verify_checksum!(raw_data)

        data = send("handle_#{type_name}", raw_data)
        puts data.inspect
      else
        printf("Unknown packet type: %02x, skipping\n", type)
      end

      WMR.send_ready_packet(@native_interface)
    end


    def handle_temp(data)
      temp = (data[3] + ((data[4] & 0x0f) << 8)) / 10.0;
      temp = ((data[4] >> 4) == 0x8) ? -temp : temp

      {:celcius => temp}
    end

    def handle_clock(data)
      minute = data[4];
      hour = data[5];
      day = data[6];
      month = data[7];
      year = data[8] + 2000;


      Time.mktime(year, month, day, hour, minute)
    end

    def cleanup
      LibHID::Native.hid_close(@native_interface)
      LibHID::Native.hid_delete_HIDInterface(@native_interface)
      LibHID::Native.hid_cleanup
    end
  end
end
