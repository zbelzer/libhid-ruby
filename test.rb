require File.expand_path('../lib/libhid-ruby', __FILE__)

puts LibHID::Native.hid_init

# interface_ptr = FFI::MemoryPointer.new :pointer
interface_ptr = LibHID::Native.hid_new_HIDInterface
interface = LibHID::Native::HIDInterface.new(interface_ptr)

matcher_ptr = FFI::MemoryPointer.new LibHID::Native::HIDInterfaceMatcher.size
matcher = LibHID::Native::HIDInterfaceMatcher.new(matcher_ptr)

matcher[:vendor_id] = WMR::WMR100_VENDOR_ID
matcher[:product_id] = WMR::WMR100_PRODUCT_ID

puts LibHID::Native.hid_force_open(
  interface,
  0,
  matcher_ptr,
  10
)
