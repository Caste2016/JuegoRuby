class Menu
  attr_reader :seleccion, :jugadores, :jugador, :mensaje, :perdedores, :menu, :jugador_anterior, :ajustes

  def initialize
    @jugadores = []
    @perdedores = []
    @jugador = nil
    @player = @jugadores.size - 1
    @seleccion = 0
    @mensaje = []
    @num_msg = 0
    @jugador_anterior = nil
    @ajustes = {
      max_hp: 100,
      max_mp: 100
    }
    @menu = MenuAjustes.new(@ajustes)
  end

  def enviar(msg)
    @num_msg += 1
    @mensaje.unshift("#{@num_msg}) #{msg}")
    @mensaje.pop if @mensaje.size > 5
  end

  #----------------------------------------- control --------------------------------------------
  def seleccionar
    if @menu.instance_of?(MenuAjustes)
      input = read_char
      case input
      when 'w', "\e[A"
        @seleccion = (@seleccion - 1) % @menu.opciones.size # arriva
      when 's', "\e[B"
        @seleccion = (@seleccion + 1) % @menu.opciones.size # abajo
      when 'e', "\e[C"
        done = @menu.accion(@seleccion) # enter
        return true if done == true
      end
    elsif @jugador && @jugador.nombre.include?('bot') || @jugador.nombre.include?('Bot')
      @jugador.elegir_bot
    else
      input = read_char
      case input
      when 'w', "\e[A"
        @seleccion = (@seleccion - 1) % @menu.opciones.size # arriva
      when 's', "\e[B"
        @seleccion = (@seleccion + 1) % @menu.opciones.size # abajo
      when 'e', "\e[C"
        cambiar_menu(@seleccion, @jugador, @jugadores) # enter
      end
    end
  end

  #------------------------------------ Cambio de menu ----------------------------------

  def cambiar_menu(seleccion, jugador, jugadores)
    @seleccion = 0
    in_menu = @menu.instance_of?(MenuPrincipal)
    in_info = @menu.instance_of?(MenuHechizos)
    in_cambiar = @menu.instance_of?(MenuCambiarHechizo)
    if in_menu
      case seleccion
      when 0 # Atacar
        @menu = MenuAtacar.new(jugadores)
      when 1 # Lanzar hechizo
        @menu = MenuLanzarHechizo.new(jugadores)
      when 2 # Cambiar hechizo
        @menu = MenuCambiarHechizo.new
      when 3 # Hechizos
        @menu = MenuHechizos.new
      when 4
        # Decansar
        cambiar_jugador
        enviar("#{jugador.nombre} -> #{jugador.regenerar_hp(10)}#{jugador.regenerar_mp(1)}")
      end
    end

    if @jugadores.size <= 1 # Cambiar menu cuando y no hay mas enemigos
      cambiar_jugador
      @menu = MenuGameOver.new(@jugadores, @perdedores)
    end

    if @menu.instance_variable_defined?(:@opciones)
      back_button = @menu.opciones.index(@menu.opciones.last)
      @menu = @menu.atras if !in_menu && (seleccion == back_button)

      if !in_menu && seleccion != back_button
        if @menu.respond_to?(:category) && @menu.category == Ataque || in_info
          @menu.accion(seleccion, jugador)
        else
          @menu.accion(seleccion, jugador)
          cambiar_jugador
          @menu = MenuPrincipal.new
        end
      end

    end
  end

  # -------------------------------- Empezar juego ------------------------------

  def evento
    random = rand(1..150)
    if random == 1
      nombre = ['Bot el destructor de realidades', 'Bot el aniquilador', 'Terminaitbot', 'Bot conquistador'].sample
      @jugadores.push(un_personaje = Personaje.new(nombre, self))
      enviar("Evento: #{nombre} a venido a conquistar el mundo!!")
    elsif random == 2
      enviar("Evento: Terremotoooo!!\nTodos los jugadores toman daño!")
      @jugadores.each do |jugador|
        jugador.disminuir_hp(10)
        remover_jugador(Terremoto.new, jugador) if jugador.hp == 0
      end
    end
  end

  def start_game
    system('clear')
    mostrar_ajustes
    puts "Welcome to the game!\n(Presione 'enter' sin ningun nombre para empezar el juego)\n(Escribe '+' para añadir un bot)\n(Escribe '-' para remover el ultimo jugador)"
    puts "\nControles del menu:\n 'w' -> Arriba\n 's' -> Abajo\n 'e' -> Enter\n "
    registrar_jugador
    loop do
      seleccionar
      mostrar_menu
      break if @menu.instance_of?(MenuGameOver)
    end
  end

  def mostrar_ajustes
      mostrar_menu
    loop do
      done = seleccionar
      mostrar_menu
      break if done == true
    end
    system("clear")
    @seleccion = 0
  end

  # ----------------------------------- Registrar jugador -------------------------

  def registrar_jugador
    puts "Enter Player #{@jugadores.size + 1}'s name: "
    nombre = gets.chomp

    if nombre.empty?
      if @jugadores.size < 2
        puts 'No hay suficientes jugadores para empezar'
        registrar_jugador
        return
      else
        @player = rand(0..@jugadores.size - 1) # Empezar con jugador random
        cambiar_jugador
        mostrar_menu
        return
      end
    elsif nombre == '+'
      @jugadores.push(un_personaje = Personaje.new("bot#{@jugadores.size + 1}", self))
      puts "bot#{@jugadores.size}"
    elsif nombre == '-'
      puts "Se removió #{@jugadores.last.nombre}" unless @jugadores.empty?
      @jugadores.pop
    else
      @jugadores.push(un_personaje = Personaje.new(nombre, self))
    end

    registrar_jugador
  end

  # --------------------------------- Siguiente jugador ---------------------------

  def cambiar_jugador
    @jugador_anterior = @jugador
    @player = (@player + 1) % @jugadores.size # unless !@jugador.nil? && @jugador.efectos.any? { |efectos| efectos.instance_of?( 'clase para no pasar turno' ) }
    @jugador = @jugadores[@player]
    @jugador.hacer_efecto
    evento
    # @mensaje[0] << "\nAhora es turno de #{@jugador.nombre}" unless @mensaje[0].nil?
    @menu = MenuPrincipal.new
  end

  # -------------------------------- Remover un jugador -------------------------

  def remover_jugador(asesino, jugador)
    frases = ['mató', 'asesinó', 'se cogio', 'destruyó', 'decuartizó', 'pulverizó', 'destripó', 'mutiló', 'le arrancó el corazón',
              'explotó', 'rebentó', 'le dió una orden de restricción', 'hizo desaparecer de la faz de la tierra', 'baneó de twitter', 'ofendió', 'le cenceló por Twitter', 'le pisó el pie']
    @jugadores.delete(jugador)
    jugador.enviar("#{asesino.nombre} #{frases.sample} a #{jugador.nombre}. rip")
    jugador.menu.perdedores.push(jugador)
  end

  # -------------------------------------- Mostrar el menu ---------------------------

  def mostrar_menu
    system('clear')
    cambiar_menu(nil, nil, nil) if @jugadores.size == 1 # Cambiar menu cuando no hay mas jugadores
    # ------------------------- Ariiva del menu ------------------------------
    # puts "#{@jugadores.size} jugadores: #{players}\n#{@perdedores.size} perdedores: #{perdedor}" # Esto muestra el, Array de los jugadores
    # ------------------------- Nombre del menu + hechizos info -----------------------------
    puts "-------- #{@menu.nombre} ----------"
    puts @menu.mensaje if @menu.respond_to?(:mensaje)
    # -------------------------- Las opciones del menu --------------------------
    if @menu.respond_to?(:opciones) && !@menu.opciones.empty?
      @menu.opciones.each_with_index do |opcion, index|
        if index == @seleccion
          puts ' ', "-> #{opcion}", ' '
        else
          puts "#{opcion}" unless @jugador && @jugador.efectos.any? { |efectos| efectos.instance_of?(Desorientación) }
        end
      end
    else
      puts 'En este menu no hay opciones'
    end
    # ------------------------------ Debajo del menu -----------------------------
    puts "-----------------------------" if !@jugador
    puts @jugador.mostrar_personaje if @jugador
    puts @mensaje.join("\n--------------\n")
  end
end
# ---------------------------------- Menu principal ----------------------------------

class MenuPrincipal
  attr_reader :nombre, :opciones

  def initialize
    @nombre = 'Menu principal'
    @opciones = ['Atacar', 'Lanzar hechizo', 'Cambiar hechizo', 'Hechizos', 'Descansar']
  end
end

# ---------------------------------- Menu de atacar ----------------------------------

class MenuAtacar < Menu
  attr_reader :opciones, :nombre

  def initialize(jugadores)
    @nombre = 'Atacar'
    @opciones = []
    @jugadores = jugadores
    @mensaje = 'Elije a un jugador para atacar'
    executar
  end

  def executar
    @opciones.clear
    @jugadores.each { |enemigo| @opciones.push(enemigo.nombre) }
    @opciones.push('--Atras--')
  end

  def accion(seleccion, jugador)
    executar
    enemigo = @jugadores[seleccion]
    jugador.atacar(enemigo)
    remover_jugador(jugador, enemigo) if enemigo.hp == 0
  end

  def atras
    MenuPrincipal.new
  end
end

# ---------------------------------- Menu lanzar hechizo ----------------------------------

class MenuLanzarHechizo < Menu
  attr_reader :opciones, :nombre

  def initialize(jugadores)
    @nombre = 'Lechizo hechizo'
    @opciones = []
    @jugadores = jugadores
    @mensaje = 'Elije a un jugador para lanzarle un hechizo'
    executar
  end

  def executar
    @opciones.clear
    @jugadores.each { |enemigo| @opciones.push(enemigo.nombre) }
    @opciones.push('--Atras--')
  end

  def accion(seleccion, jugador)
    enemigo = @jugadores[seleccion]
    jugador.hechizo(enemigo)
    remover_jugador(jugador, enemigo) if enemigo.hp == 0
  end

  def atras
    MenuPrincipal.new
  end
end

# ---------------------------------- Menu cambiar de hechizo ----------------------------------

class MenuCambiarHechizo < Menu
  attr_reader :opciones, :nombre, :category

  def initialize
    @nombre = 'Cambiar hechizo'
    @mensaje = 'Elije un hechizo para cambiar'
    @opciones = []
    @category = Ataque
    executar
  end

  def executar
    @opciones = []

    @category.subclasses.reverse.each do |clases|
      clase = clases.new
      @opciones.push(clase.nombre)
    end
    @opciones.push('--Atras--')
  end

  def accion(seleccion, jugador)
    if @category == Ataque
      @category = @category.subclasses.reverse[seleccion]
      executar
      @nombre += " [#{@category}]"
    else
      ataque = @category.subclasses.reverse[seleccion]
      jugador.cambiar_ataque(ataque)
    end
  end

  def atras
    return MenuCambiarHechizo.new if @category != Ataque

    MenuPrincipal.new
  end
end

# ---------------------------------- Menu info hechizos ----------------------------------

class MenuHechizos < Menu
  attr_reader :opciones, :nombre, :category

  def initialize
    @nombre = 'Hechizos'
    @opciones = []
    @mensaje = []
    @category = Ataque
    executar
  end

  def executar
    @opciones = []
    @mensaje = []

    @category.subclasses.reverse.each do |clases|
      clase = clases.new
      @mensaje.push("- [#{clase.nombre}]:")
      @mensaje.push("#{clase.desc}\n--------------------------------")
      @opciones.push("#{clase.nombre}") if @category == Ataque
    end
    @opciones.push('--Atras--')
  end

  def accion(seleccion, _jugador)
    @category = @category.subclasses.reverse[seleccion]
    executar
    @nombre = @category
  end

  def atras
    return MenuHechizos.new if @category != Ataque

    MenuPrincipal.new
  end
end

# ---------------------------------- Pantalla Game Over ----------------------------------

class MenuGameOver < Menu
  attr_reader :nombre

  def initialize(jugadores, perdedores)
    @nombre = 'Game over'
    @jugadores = jugadores
    @perdedores = perdedores
    @mensaje = ''
    executar
  end

  def executar
    if @jugadores.empty?
      @mensaje = "El juego a terminado!! \nNo hubo ganadores\nPerdedores: #{@perdedores.map(&:nombre).join(', ')}"
    else
      @mensaje = "El juego a terminado!! \nGanador: #{@jugadores.first.nombre}\nPerdedores: #{@perdedores.map(&:nombre).join(', ')}"
    end
  end
end

class MenuAjustes < Menu
  attr_reader :nombre, :opciones

  def initialize(ajustes)
    @nombre = 'Ajustes'
    @mensaje = 'Menu para ajustar la partida'
    @opciones = []
    @ajustes = ajustes
    executar
  end

  def executar
    @opciones = []
    
    @ajustes.each do |item, valor| 
      @opciones.push("#{item}: #{valor}")
    end
    @opciones.push('-- Start --')
  end

  def accion(seleccion)
    back_button = @opciones.index(@opciones.last)
    if seleccion != back_button
      puts "Ingresa un numero:"
      valor = gets.chomp
      if valor =~ /\A\d+\z/
        valor = valor.to_i
        if valor < 10
          @mensaje = "Valor muy pequeño"
        else
          item = @ajustes.keys[seleccion]
          @ajustes[item] = valor
          @mensaje = 'Menu para ajustar la partida'
        end
      else @mensaje = "Valor invalido"
      end
    else
      return true
    end
    executar
  end

  def atras
    return
  end
end

class Terremoto
  def nombre
    self.class
  end
end
