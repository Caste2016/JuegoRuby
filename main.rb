require 'io/console'


# ----------------------------------------- Personajes -------------------------------------
require_relative 'personaje'
# ------------------------------------------ Estados --------------------------------------
require_relative 'estados'
# ------------------------------------------ Hechizos --------------------------------------
require_relative 'ataques'
# ------------------------------------------ Menues -----------------------------------------
require_relative 'menu'
# -------------------------------------------------------------------------------------------

def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

system('clear')
menu = Menu.new
menu.start_game