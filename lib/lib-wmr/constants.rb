module WMR
  TYPES = {
    0x41 => :rain,
    0x42 => :temp,
    0x44 => :water,
    0x46 => :pressure,
    0x47 => :uv,
    0x48 => :wind,
    0x60 => :clock
  }

  SIZES = {
    :rain => 15,
    :temp => 10,
    :water => 5,
    :pressure => 6,
    :uv => 3,
    :wind => 9,
    :clock => 10
  }
end
