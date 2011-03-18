require 'rubygems'
require 'ffi'

module LibHID
  module Native
    extend FFI::Library
    ffi_lib "libhid"

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
      layout(
        :usb_dev_handle, :pointer,
        :usb_device, :pointer,
        :interface, :int,
        :id, [:char, 32],
        :hid_data, :pointer,
        :hid_parser, :pointer
      )

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
    
    RECV_PACKET_LEN   = 8
    BUF_SIZE = 255
    PATHLEN = 2
    PATH_IN  = [ 0xff000001, 0xff000001 ]
    PATH_OUT = [ 0xff000001, 0xff000002 ]
    INIT_PACKET1 = [ 0x20, 0x00, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
    INIT_PACKET2 = [ 0x01, 0xd0, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]


    attach_function :hid_init, [], :hid_return
    attach_function :hid_new_HIDInterface, [], :pointer
    attach_function :hid_force_open, [:pointer, :int, :pointer, :int], :hid_return
    attach_function :hid_write_identification, [:pointer, :pointer], :hid_return
    attach_function :hid_set_output_report, [:pointer, :pointer, :int, :pointer, :int], :hid_return

    attach_function :hid_close, [:pointer], :hid_return
    attach_function :hid_delete_HIDInterface, [:pointer], :void
    attach_function :hid_cleanup, [], :hid_return
  end
end
