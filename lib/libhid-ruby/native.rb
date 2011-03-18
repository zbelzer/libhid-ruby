require 'rubygems'
require 'ffi'

module LibHID
  def self.check_result(operation, result)
    if result == :hid_ret_success
      puts "#{operation}... success"
    else
      raise "#{operation} failed with #{result}"
    end
  end

  module Native
    extend FFI::Library
    ffi_lib "libhid"

    RECV_PACKET_LEN   = 8
    BUF_SIZE = 255
    PATHLEN = 2
    PATH_IN  = [ 0xff00, 0x0001, 0xff00, 0x0001 ]
    PATH_OUT = [ 0xff00, 0x0001, 0xff00, 0x0002 ]
    INIT_PACKET1 = [ 0x20, 0x00, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
    INIT_PACKET2 = [ 0x01, 0xd0, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
    USB_ENDPOINT_IN	= 0x80
    USB_ENDPOINT_OUT = 0x00

    RETRIES = 10

    def self.send_init_packet(interface)
      path_in = FFI::Buffer.new :ushort, 4
      path_in.write_array_of_ushort PATH_IN

      init_packet = FFI::MemoryPointer.new(INIT_PACKET1.size * 1).write_array_of_char(INIT_PACKET1)
      result = Native.hid_set_output_report(interface.to_ptr, path_in, 2, init_packet, init_packet.size)
      # LibHID.check_result "Sending init packet", result
    end

    def self.send_ready_packet(interface)
      path_in = FFI::Buffer.new :ushort, 4
      path_in.write_array_of_ushort PATH_IN

      ready_packet = FFI::MemoryPointer.new(INIT_PACKET2.size * 1).write_array_of_char(INIT_PACKET2)
      result = Native.hid_set_output_report(interface.to_ptr, path_in, 2, ready_packet, ready_packet.size)
      # LibHID.check_result "Sending init packet", result
    end

    # typedef struct HIDInterface_t {
    #   struct usb_dev_handle *dev_handle;
    #   struct usb_device *device;
    #   int interface;
    #   char id[32];
    #   HIDData* hid_data;
    #   HIDParser* hid_parser;
    # } HIDInterface;
    # #  
    class HIDInterface < FFI::Struct
      attr_accessor :length, :remaining, :position

      def buffer
        @buffer ||= FFI::Buffer.new :char, BUF_SIZE
      end

      def remaining
        @remaining ||= 0
      end

      def position
        @position ||= 0
      end

      layout(
        :usb_dev_handle, :pointer,
        :usb_device, :pointer,
        :interface, :int,
        :id, [:char, 32],
        :hid_data, :pointer,
        :hid_parser, :pointer
      )

      def read_packet
        # puts "Reading packet"
        Native.hid_interrupt_read(self.to_ptr, USB_ENDPOINT_IN + 1, buffer, RECV_PACKET_LEN, 0)
        data =  buffer.get_bytes(0, RECV_PACKET_LEN)
        data_array = (0..Native::RECV_PACKET_LEN).map {|x| data[x] if data[x]}
        # puts (0..Native::RECV_PACKET_LEN).map {|x| data[x].to_s(16).rjust(2, '0') if data[x]}.join(' ')

        len = buffer.get_bytes(0, 1)[0].to_i
        # puts "Length is #{len.to_s(16)}" unless len.nil?

        @length = [len, 7].max
        @remaining = @length
        @position = 0
      end

      def read_byte
        # puts "Reading byte at position #{@position}"
        while remaining.zero?
          read_packet
        end

        byte = buffer.get_bytes(position, 1)[0].to_i
        # puts "Read byte #{byte.to_s(16)}" unless byte.nil?
        @position += 1
        @remaining -= 1

        byte
      end

      def fetch_data(unk1, type, data_len)
        if data_len > 0
          data = [unk1, type]

          data_len.times do
            data << read_byte
          end

          data
        end
      end

      def read_data
        byte = read_byte
        while byte != 0xff  do
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
          puts "Rain #{data.inspect}"
          fetch_data(unk1, type, 17)
        when 0x42
          data = fetch_data(unk1, type, 12)
          puts "Temp #{data.inspect}"

          temp = (data[3] + ((data[4] & 0x0f) << 8)) / 10.0;
          temp = ((data[4] >> 4) == 0x8) ? -temp : temp
          puts temp

        when 0x44
          data = fetch_data(unk1, type, 7)
          puts "Water #{data.inspect}"
        when 0x46
          data = fetch_data(unk1, type, 8)
          puts "Pressure #{data.inspect}"
        when 0x47
          data = fetch_data(unk1, type, 5)
          puts "UV #{data.inspect}"
        when 0x48
          data = fetch_data(unk1, type, 11)
          puts "Wind #{data.inspect}"
        when 0x60
          data = fetch_data(unk1, type, 12)
          puts "Clock #{data.inspect}"
        else
          printf("Unknown packet type: %02x, skipping\n", type)
        end

        #  if verify_checksum(data, data_len) == 0
        #    wmr_handle_packet(wmr, data, data_len)
        #  end

        LibHID::Native.send_ready_packet(self)

      end

      def self.release(ptr)
        Native.free_object(ptr)
      end
    end

    # typedef struct HIDInterfaceMatcher_t {
    #   unsigned short vendor_id;
    #   unsigned short product_id;
    #   matcher_fn_t matcher_fn;	# Only supported in C library (not via SWIG)
    #   void* custom_data;		   # Only used by matcher_fn
    #   unsigned int custom_data_length; # Only used by matcher_fn
    # } HIDInterfaceMatcher;
    class HIDInterfaceMatcher < FFI::Struct
      layout(
        :vendor_id, :short,
        :product_id, :short,
        :foo, :pointer,
        :bar, :pointer,
        :baz, :int
      )

      def self.release(ptr)
        Native.free_object(ptr)
      end
    end

    #  char const* const serial = "01518";
    #  HIDInterfaceMatcher matcher = {
    #    0x06c2,                      // vendor ID
    #    0x0038,                      // product ID
    #    match_serial_number,         // custom matcher function pointer
    #    (void*)serial,               // custom matching data
    #    strlen(serial)+1             // length of custom data
    #  };

    enum :hid_return, [
      :hid_ret_success,
      :hid_ret_invalid_parameter,
      :hid_ret_not_initialised,
      :hid_ret_already_initialised,
      :hid_ret_fail_find_busses,
      :hid_ret_fail_find_devices,
      :hid_ret_fail_open_device,
      :hid_ret_device_not_found,
      :hid_ret_device_not_opened,
      :hid_ret_device_already_opened,
      :hid_ret_fail_close_device,
      :hid_ret_fail_claim_iface,
      :hid_ret_fail_detach_driver,
      :hid_ret_not_hid_device,
      :hid_ret_hid_desc_short,
      :hid_ret_report_desc_short,
      :hid_ret_report_desc_long,
      :hid_ret_fail_alloc,
      :hid_ret_out_of_space,
      :hid_ret_fail_set_report,
      :hid_ret_fail_get_report,
      :hid_ret_fail_int_read,
      :hid_ret_not_foun
    ]

    # Incomplete debug helpers
    # enum :hid_debug_level, [
    #   HID_DEBUG_NONE, 0x0,		# Default
    #   HID_DEBUG_ERRORS, 0x1,	# Serious conditions
    #   HID_DEBUG_WARNINGS, 0x2,	# Less serious conditions
    #   HID_DEBUG_NOTICES, 0x4,	# Informational messages
    #   HID_DEBUG_TRACES, 0x8,	# Verbose tracing of functions
    #   HID_DEBUG_ASSERTS, 0x10,	# Assertions for sanity checking
    #   hid_debug_notraces, hid_debug_errors | hid_debug_warnings | hid_debug_notices | hid_debug_asserts,
    #   # This is what you probably want to start with while developing with libhid
    #   HID_DEBUG_ALL = HID_DEBUG_ERRORS | HID_DEBUG_WARNINGS | HID_DEBUG_NOTICES | HID_DEBUG_TRACES | HID_DEBUG_ASSERTS
    # ]

    # hid_set_debug(HID_DEBUG_ALL);
    # attach_function :hid_set_debug, [], :void

    # # hid_set_debug_stream(stderr);
    # attach_function :hid_set_debug_stream, [:pointer], :void

    # # hid_set_usb_debug(0);
    # attach_function :hid_set_usb_debug, [:int], :void


    attach_function :hid_init, [], :hid_return
    attach_function :hid_new_HIDInterface, [], :pointer
    attach_function :hid_force_open, [:pointer, :int, :pointer, :int], :hid_return
    attach_function :hid_write_identification, [:pointer, :pointer], :hid_return
    attach_function :hid_set_output_report, [:pointer, :pointer, :int, :pointer, :int], :hid_return

    attach_function :hid_interrupt_read, [:pointer, :uint, :buffer_inout, :uint, :uint], :hid_return

    attach_function :hid_close, [:pointer], :hid_return
    attach_function :hid_delete_HIDInterface, [:pointer], :void
    attach_function :hid_cleanup, [], :hid_return
  end
end
