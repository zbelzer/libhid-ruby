require File.expand_path('../lib/libhid-ruby', __FILE__)

module LibHID
  RETRIES = 10

  def self.check_result(operation, result)
    if result == :hid_ret_success
      puts "#{operation}... success"
    else
      raise "#{operation} failed with #{result}"
    end
  end

  begin
    check_result "Initilizing device", Native.hid_init

    interface_ptr = Native.hid_new_HIDInterface
    interface = Native::HIDInterface.new(interface_ptr)

    matcher_ptr = FFI::MemoryPointer.new Native::HIDInterfaceMatcher.size
    matcher = Native::HIDInterfaceMatcher.new(matcher_ptr)

    matcher[:vendor_id] = WMR::WMR100_VENDOR_ID
    matcher[:product_id] = WMR::WMR100_PRODUCT_ID

    check_result "Opening device", Native.hid_force_open(interface_ptr, 0, matcher_ptr, RETRIES)

    path_in = FFI::Buffer.new :ulong, 2
    path_in.write_array_of_ulong Native::PATH_IN

    init_packet_1 = FFI::MemoryPointer.new(Native::INIT_PACKET1.size * 1).write_array_of_char(Native::INIT_PACKET1)
    init_packet_2 = FFI::MemoryPointer.new(Native::INIT_PACKET2.size * 1).write_array_of_char(Native::INIT_PACKET2)

    check_result "Sending init packet", Native.hid_set_output_report(interface_ptr, path_in, 2, init_packet_1, init_packet_1.size)
    check_result "Sending ready packet", Native.hid_set_output_report(interface_ptr, path_in, 2, init_packet_2, init_packet_2.size)
  rescue => e
    puts e.message
  ensure
    puts "Cleaning up"
    Native.hid_close(interface) unless interface_ptr.null?
    Native.hid_delete_HIDInterface(interface) unless interface_ptr.null?
    Native.hid_cleanup
  end
end
