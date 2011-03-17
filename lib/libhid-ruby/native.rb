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
        :id, :char,
        :hid_data, :pointer,
        :hid_parser, :pointer
      )
    end

    # typedef struct HIDInterfaceMatcher_t {
    #   unsigned short vendor_id;
    #   unsigned short product_id;
    #   matcher_fn_t matcher_fn;	//!< Only supported in C library (not via SWIG)
    #   void* custom_data;		   //!< Only used by matcher_fn
    #   unsigned int custom_data_length; //!< Only used by matcher_fn
    # } HIDInterfaceMatcher;
    class HIDInterfaceMatcher < FFI::Struct
      layout(
        :vendor_id, :short,
        :product_id, :short
      )
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

    attach_function :hid_init, [], :hid_return
  end
end
