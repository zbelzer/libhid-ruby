require File.expand_path('../lib/libhid-ruby', __FILE__)

puts LibHID::Native.hid_init
interface_pointer = LibHID::Native.hid_new_HIDInterface
obj = LibHID::Native::HIDInterface.new(interface_pointer)

matcher_ptr = FFI::MemoryPointer.new :pointer
matcher = LibHID::Native::HIDInterfaceMatcher.new(matcher_ptr)

matcher[:vendor_id] = WMR::WMR100_VENDOR_ID
matcher[:product_id] = WMR::WMR100_PRODUCT_ID

conn = LibHID::Native.hid_force_open(
  interface_pointer.get_pointer(0),
  0,
  matcher_ptr.get_pointer(0),
  10
)
