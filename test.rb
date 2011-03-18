require File.expand_path('../lib/libhid-ruby', __FILE__)

module LibHID
  begin
    check_result "Initilizing device", Native.hid_init

    interface_ptr = Native.hid_new_HIDInterface
    interface = Native::HIDInterface.new(interface_ptr)

    matcher_ptr = FFI::MemoryPointer.new Native::HIDInterfaceMatcher.size
    matcher = Native::HIDInterfaceMatcher.new(matcher_ptr)

    matcher[:vendor_id] = WMR::WMR100_VENDOR_ID
    matcher[:product_id] = WMR::WMR100_PRODUCT_ID

    check_result "Opening device", Native.hid_force_open(interface_ptr, 0, matcher_ptr, Native::RETRIES)

    Native.send_init_packet(interface)
    Native.send_ready_packet(interface)

    puts "Found on USB: #{interface[:id]}"

    loop do
      interface.read_data
    end

  rescue => e
    puts e.message
    puts e.backtrace.join("\n")
  ensure
    puts "Cleaning up"
    Native.hid_close(interface) unless interface_ptr.null?
    Native.hid_delete_HIDInterface(interface) unless interface_ptr.null?
    Native.hid_cleanup
  end
end
