require 'io/console'


# ----------------------------------------- Personajes -------------------------------------
require_relative 'juego/personaje'
# ------------------------------------------ Estados --------------------------------------
require_relative 'juego/estados'
# ------------------------------------------ Hechizos --------------------------------------
require_relative 'juego/ataques'
# ------------------------------------------ Menues -----------------------------------------
require_relative 'juego/menu'
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