module Colorize
  def colour(text, colour_code)
    "#{colour_code}#{text}\e[0m"
  end

  def green(text); colour(text, "\e[32m"); end
  def red(text); colour(text, "\e[31m"); end
  def yellow(text); colour(text, "\e[33m"); end
  def blue(text); colour(text, "\e[34m"); end
end
