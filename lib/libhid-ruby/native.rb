require 'ffi'

module LibHID
  module Native
    extend FFI::Library
    ffi_lib "/usr/lib/libhid.so"

    # class Event < FFI::Struct
    #   layout(
    #     :wd, :int,
    #     :mask, :uint32,
    #     :cookie, :uint32,
    #     :len, :uint32)
    # end
    #

    # typedef enum hid_return_t {
    #   HID_RET_SUCCESS = 0,
    #   HID_RET_INVALID_PARAMETER,
    #   HID_RET_NOT_INITIALISED,
    #   HID_RET_ALREADY_INITIALISED,
    #   HID_RET_FAIL_FIND_BUSSES,
    #   HID_RET_FAIL_FIND_DEVICES,
    #   HID_RET_FAIL_OPEN_DEVICE,
    #   HID_RET_DEVICE_NOT_FOUND,
    #   HID_RET_DEVICE_NOT_OPENED,
    #   HID_RET_DEVICE_ALREADY_OPENED,
    #   HID_RET_FAIL_CLOSE_DEVICE,
    #   HID_RET_FAIL_CLAIM_IFACE,
    #   HID_RET_FAIL_DETACH_DRIVER,
    #   HID_RET_NOT_HID_DEVICE,
    #   HID_RET_HID_DESC_SHORT,
    #   HID_RET_REPORT_DESC_SHORT,
    #   HID_RET_REPORT_DESC_LONG,
    #   HID_RET_FAIL_ALLOC,
    #   HID_RET_OUT_OF_SPACE,
    #   HID_RET_FAIL_SET_REPORT,
    #   HID_RET_FAIL_GET_REPORT,
    #   HID_RET_FAIL_INT_READ,
    #   HID_RET_NOT_FOUND
    # } hid_return;
    # 

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

    class HIDInterfaceMatcher
    end
    #  char const* const serial = "01518";
    #  HIDInterfaceMatcher matcher = {
    #    0x06c2,                      // vendor ID
    #    0x0038,                      // product ID
    #    match_serial_number,         // custom matcher function pointer
    #    (void*)serial,               // custom matching data
    #    strlen(serial)+1             // length of custom data
    #  };
    #
    # typedef struct HIDInterface_t {
    #   struct usb_dev_handle *dev_handle;
    #   struct usb_device *device;
    #   int interface;
    #   char id[32];
    #   HIDData* hid_data;
    #   HIDParser* hid_parser;
    # } HIDInterface;
    # #  

    attach_function :hid_init, [], :hid_return
  end
end
