require File.expand_path('../lib/libhid-ruby', __FILE__)

module LibHID
  begin
    wmr = WMR::Interface.new

    loop do
      wmr.read_data
    end

  rescue => e
    puts e.message
    puts e.backtrace.join("\n")
  ensure
    puts "Cleaning up"
    wmr.cleanup
  end
end
