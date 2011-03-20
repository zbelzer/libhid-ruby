require 'rubygems'
require 'ffi'

module LibHID
  module Native
    extend FFI::Library
    ffi_lib "libhid"

    HID_DEBUG_NONE      = 0x0		# Default
    HID_DEBUG_ERRORS    = 0x1   # Serious conditions
    HID_DEBUG_WARNINGS  = 0x2   # Less serious conditions
    HID_DEBUG_NOTICES   = 0x4   # Informational messages
    HID_DEBUG_TRACES    = 0x8   # Verbose tracing of functions
    HID_DEBUG_ASSERTS   = 0x10	# Assertions for sanity checking
    # hid_debug_notraces, hid_debug_errors | hid_debug_warnings | hid_debug_notices | hid_debug_asserts,
    # This is what you probably want to start with while developing with libhid
    HID_DEBUG_ALL = HID_DEBUG_ERRORS | HID_DEBUG_WARNINGS | HID_DEBUG_NOTICES | HID_DEBUG_TRACES | HID_DEBUG_ASSERTS

    # Incomplete debug helpers
    enum :hid_debug_level, [
      :hid_debug_none, HID_DEBUG_NONE,
      :hid_debug_errors, HID_DEBUG_ERRORS,
      :hid_debug_warnings, HID_DEBUG_WARNINGS,
      :hid_debug_notices,  HID_DEBUG_NOTICES,
      :hid_debug_traces, HID_DEBUG_TRACES,
      :hid_debug_asserts, HID_DEBUG_ASSERTS,
      :hid_debug_all, HID_DEBUG_ALL
    ]

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

    attach_function :hid_set_debug, [:hid_debug_level], :void

    attach_function :hid_set_debug_stream, [:pointer], :void
    attach_function :hid_set_usb_debug, [:int], :void

    attach_function :hid_new_HIDInterface, [], :pointer

    attach_function :hid_delete_HIDInterface, [:pointer], :void
    attach_function :hid_reset_HIDInterface, [:pointer], :void
    

    attach_function :hid_init, [], :hid_return
    attach_function :hid_cleanup, [], :hid_return

    attach_function :hid_is_initialised, [], :bool

    attach_function :hid_open, [:pointer, :int, :pointer], :hid_return
    attach_function :hid_force_open, [:pointer, :int, :pointer, :int], :hid_return

    attach_function :hid_close, [:pointer], :hid_return

    attach_function :hid_is_opened, [:pointer], :bool

    attach_function :hid_get_input_report, [:pointer, :pointer, :int, :pointer, :int], :hid_return
    attach_function :hid_set_output_report, [:pointer, :pointer, :int, :pointer, :int], :hid_return

    attach_function :hid_get_feature_report, [:pointer, :pointer, :int, :pointer, :int], :hid_return
    attach_function :hid_set_feature_report, [:pointer, :pointer, :int, :pointer, :int], :hid_return

    attach_function :hid_write_identification, [:pointer, :pointer], :hid_return

    attach_function :hid_dump_tree, [:pointer, :pointer], :hid_return

    attach_function :hid_interrupt_read, [:pointer, :uint, :buffer_inout, :uint, :uint], :hid_return
    attach_function :hid_interrupt_write, [:pointer, :uint, :buffer_inout, :uint, :uint], :hid_return

    attach_function :hid_set_idle, [:pointer, :uint, :uint],  :hid_return

    #This will take something like 0xff000001 (which is a Bignum in Ruby),
    #and write it out to an integer pointer correctly, which doesn't normally
    #work due to the lack of unsigned values in Ruby
    def self.write_bignum32(pointer, uint)
      pointer.write_array_of_ushort bignum32_to_little_endian_short_array(uint)
    end

    def self.write_bignum32_array(pointer, uints)
      array = uints.map { |uint| bignum32_to_little_endian_short_array(uint) }.flatten
      pointer.write_array_of_ushort array
    end

    private

    def self.bignum32_to_little_endian_short_array(uint)
      top = (uint >> 16) & 0xffff
      bottom = uint & 0x0000ffff
      [bottom, top]
    end
  end
end
