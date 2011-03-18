require File.expand_path('../lib/libhid-ruby', __FILE__)

module LibHID
  RETRIES = 10

  begin
    result = Native.hid_init

    if result == :hid_ret_success
      puts "Initialized successfully"
    else
      raise "Initialization failed with #{result}"
    end

    interface_ptr = Native.hid_new_HIDInterface
    interface = Native::HIDInterface.new(interface_ptr)

    matcher_ptr = FFI::MemoryPointer.new Native::HIDInterfaceMatcher.size
    matcher = Native::HIDInterfaceMatcher.new(matcher_ptr)

    matcher[:vendor_id] = WMR::WMR100_VENDOR_ID
    matcher[:product_id] = WMR::WMR100_PRODUCT_ID

    result = Native.hid_force_open(interface_ptr, 0, matcher_ptr, RETRIES)

    if result == :hid_ret_success
      puts "Device openened successfully"
    else
      raise "Failed to open device: #{result}"
    end

    path_in = FFI::Buffer.new :int, 2
    path_in.write_array_of_int [ 0xff000001, 0xff000001 ]
    # path_in = FFI::MemoryPointer.new(Native::PATH_IN.size * 4).write_array_of_int(Native::PATH_IN)
    # path_out = FFI::MemoryPointer.new(Native::PATH_OUT.size * 4).write_array_of_int(Native::PATH_OUT)

    init_packet_1 = FFI::MemoryPointer.new(INIT_PACKET1.size * 1).write_array_of_char(Native::INIT_PACKET1)
    init_packet_2 = FFI::MemoryPointer.new(INIT_PACKET2.size * 1).write_array_of_char(Native::INIT_PACKET2)

    Native.hid_set_output_report(interface_ptr, path_in, 2, init_packet_1, init_packet_1.size)
    # Native.hid_write_identification(, interface_ptr)
  rescue => e
    puts e.message
  ensure
    puts "Cleaning up"
    Native.hid_close(interface) unless interface_ptr.null?
    Native.hid_delete_HIDInterface(interface) unless interface_ptr.null?
    Native.hid_cleanup
  end
end
