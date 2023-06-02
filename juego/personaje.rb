class Personaje
  attr_reader :nombre, :hp, :mp, :daño_base, :tipo_ataque, :ataques, :menu, :estado, :efectos

  def initialize(nombre, menu)
    @nombre = nombre
    @menu = menu
    @max_hp = @menu.ajustes[:max_hp]
    @hp = @max_hp
    @vida_anterior = @hp
    @max_mp = @menu.ajustes[:max_mp]
    @mp = @max_mp
    @daño_base = @menu.ajustes[:daño_base]
    @efectos = [Normal.new]
    @estado = @efectos[0]
    @ataques = 0
    @tipo_ataque = Magia.new
    @bot = {
      
    }
  end

  def enviar(msg)
    @menu.enviar(msg)
  end

  # ----------------- Barras ---------------
  def barra_vida
    bar_hp = ''
    0.upto(9) do |i|
      bar_hp += 
      
      if i < @hp / (@max_hp / 10)
        @menu.ajustes[:fancy_bar] ? '♥' : '■'
      else
        @menu.ajustes[:fancy_bar] ? '♡' : '-'
      end
      
    end
    bar_hp
  end

  def barra_mana
    bar_mp = ''
    0.upto(9) do |i|
      bar_mp +=
        
      if i < @mp / (@max_mp / 10)
        @menu.ajustes[:fancy_bar] ? '★' : '■'
      else
        @menu.ajustes[:fancy_bar] ? '☆' : '-'
      end
      
    end
    bar_mp
  end

  # ---------------- Muestra info Personaje -------------
  def vida_cambio
    if @hp < @vida_anterior
      @vida_anterior = @hp
      true
    end
  end

  def nombre_efectos
    nombre_efectos = []
    efectos = @efectos[1..(@efectos.size - 1)].group_by { |effects| effects.class}
    efectos.each do |efecto, cuantos|
      cuanto = cuantos.count
      if cuanto > 1
        nombre_efectos.push("#{efecto} x#{cuanto}")
      else 
        nombre_efectos.push("#{efecto}")
      end
    end
    nombre_efectos
  end

  def mostrar_personaje
    puts '--------------------------------'
    puts "Nombre: #{@nombre}, AtaquesMelee: #{@ataques}"
    if @efectos.any? { |efectos| efectos.instance_of?(Desorientación) }
      puts 'HP: [__________]??%, MP: [__________]??%'
      puts 'Estado: ??????'
      puts 'Hechizo: ??????'
    else
      puts "HP: [#{barra_vida}]#{@hp}%, MP: [#{barra_mana}]#{@mp}%"
      puts "Estado: #{@estado.nombre}"
      puts "Hechizo: #{@tipo_ataque.nombre}"
    end
    puts "Effectos: #{nombre_efectos}" if @efectos.size > 1
    puts '--------------------------------'
  end

  # --------------------------------- Cambios ------------------------------------
  def cambiar_nombre(nombre)
    @nombre = nombre
  end

  def cambiar_estado(ataques, mismo, estado)
    @estado = @estado.cambiar_estado(ataques, mismo, estado) if @ataques == 5 or @ataques == 10 || !estado.nil?
  end

  def remover_efecto(efecto)
    @efectos.delete(efecto)
  end

  def añadir_efecto(efecto, jugador)
    añadido = @estado.añadir_efecto(efecto, jugador)
    @efectos.push(añadido)
  end

  def cambiar_ataque(ataque)
    @tipo_ataque = @tipo_ataque.cambiar_ataque(ataque, self)
    enviar("#{nombre} cambió su hechizo a #{@tipo_ataque.nombre}")
  end

  def hacer_efecto
    @efectos[1..(@efectos.size - 1)].each { |efecto| efecto.efecto } if @efectos.size > 1
  end

  # ---------------------------------------- Vida / Mana ---------------------------------------
  def disminuir_hp(una_cant)
    @hp -= una_cant
    @hp = 0 if @hp < 0
    "-#{una_cant}HP "
  end

  def regenerar_hp(una_cant)
    regenerado = (@hp - @max_hp).abs
    if regenerado > una_cant
      @hp += una_cant
      "+#{una_cant}HP "
    elsif @hp == @max_hp
      '+MAXHP '
    else
      @hp += regenerado
      "+#{regenerado}HP "
    end
  end

  def disminuir_mp(una_cant)
    @mp -= una_cant
    @mp = 0 if @mp <= 0
    enviar("#{@nombre} te quedaste sin mana!") if @mp <= 0
    "-#{una_cant}MP "
  end

  def regenerar_mp(una_cant)
    regenerado = (@mp - @max_mp).abs
    if regenerado > una_cant
      @mp += una_cant
      "+#{una_cant}MP "
    elsif @mp == @max_mp
      '+MAXMP '
    else
      @mp += regenerado
      "+#{regenerado}MP "
    end
  end

  # ----------------------------------------- Ataques -------------------------------------------
  def atacar(otro_personaje)
    daño_echo = @estado.dañar(otro_personaje, @daño_base)
    cambiar_estado(@ataques, self, nil) if @ataques == 5 || @ataques == 10
    enviar("'#{nombre}' a atacado \n #{otro_personaje.nombre} -> #{daño_echo}")
    @ataques += 1
    daño_echo
  end

  def hechizo(otro_personaje)
    succefully, daño_enemigo, daño_self, coste_enemigo, coste_self = @tipo_ataque.lanzar(otro_personaje, @daño_base, @mp, self)
    if succefully == true
      enviar("'#{nombre}' lanzó un hechizo: #{@tipo_ataque.nombre} \n      #{otro_personaje.nombre} -> #{daño_enemigo} #{coste_enemigo}\n      #{nombre} -> #{coste_self} #{daño_self}")
    elsif succefully == false
      enviar("Hechizo fallido! #{nombre} no tienes el MP suficiente!")
    end
  end

  # --------------------------------------- Bot :) --------------------------------------

 
  def elegir_bot
    ir, a_que = que_hacer_bot(false)
    result = cambiar_menu_bot(ir, a_que)
    # @menu.enviar("Result: #{result}")
    nil
  end

  # ----------- ejecuta sus opciones del "que_hacer_bot" -------------
  def cambiar_menu_bot(ir, a_que)
    opciones = @menu.menu.opciones
    jugador =  @menu.jugadores
    categoria = Ataque
    hechizos = categoria.subclasses.reverse

    
    # -------- selecciona opcion ----------
    if opciones.include?(ir)
      index = opciones.index(ir)
      @menu.cambiar_menu(index, @menu.jugador, @menu.jugadores) if @menu.menu.instance_of?(MenuPrincipal)
      
      if a_que.class == (Class) && a_que.ancestors.include?(Ataque) then
        categoria = a_que.superclass
        index = hechizos.index(categoria)
        @menu.cambiar_menu(index, @menu.jugador, @menu.jugadores) if @menu.menu.instance_of?(MenuCambiarHechizo)
        hechizos = categoria.subclasses.reverse
      end
    else
      # @menu.enviar("No encuetro la opción #{ir}") unless ir.nil?
      # que_hacer_bot(true)
      return
    end
    
    # -------- ejecuta opcion ------------
    if jugador.include?(a_que)
      index = jugador.index(a_que)
    elsif hechizos.include?(a_que)
      index = hechizos.index(a_que)
    else
      # @menu.enviar("No encotré a #{a_que}") unless a_que.nil?
      return
    end

    @menu.menu.accion(index, @menu.jugador)
    @menu.cambiar_jugador
    return "fui a #{ir} por #{a_que}"
    # ---------------------------------------
  end

  def que_hacer_bot(back)
    # ------- sus opciones -----------
    atacar = 'Atacar'
    lanzar = 'Lanzar hechizo'
    cambiar = 'Cambiar hechizo'
    descansar = 'Descansar'
    atras = '--Atras--'
    desicion = [atacar, lanzar, lanzar, cambiar, descansar].sample
    # desicion = cambiar

    desicion = atras if back == true

    # ------- atacar a ------------
    enemigo = elegir_enemigo
    mismo = self
    # ------ cambiar hechizo ---------
    hechizo_malo = elegir_hechizo_malo

    hechizo_defensive = Defensive.subclasses.reject { |spell| spell.new.coste > @mp }
    hechizo_buff = Buffs.subclasses.reject { |spell| spell.new.coste > @mp }
    hechizos_buenos = hechizo_defensive + hechizo_buff
    hechizo_bueno = hechizos_buenos.sample

    # --------- respuestas al daño -------
    frases_al_daño = ['ouch!', 'hey!', 'te odió', 'la vas a pagar', 'maldito seas', 'encerio?'].sample
    enviar("<#{nombre}> #{frases_al_daño} #{@menu.jugador_anterior.nombre}.") if vida_cambio == true && rand(1..3) == 2

    # --------- daño a melee -------------
    daño = @estado.dañar(self, @daño_base).scan(/\d+/)
    daño = daño[0].to_i
    regenerar_hp(daño)

    # ------------- celeblo ----------

    # ----- Atacar -------
    return [atacar, enemigo]           if desicion == atacar && !@estado.instance_of?(Dummy) || enemigo.hp <= daño || @mp == 0
    return [lanzar, enemigo]           if desicion == lanzar && @mp > @tipo_ataque.coste
    # ------ Curar -------
    return [cambiar, hechizo_bueno]    if desicion == cambiar && !hechizo_bueno.nil? && !@tipo_ataque.instance_of?(hechizo_bueno) && @hp < (@max_hp / 35)
    return [lanzar, mismo]             if !hechizo_bueno.nil? && hechizos_buenos.include?(@tipo_ataque) && @hp < (@max_hp / 35) && @mp > @tipo_ataque.coste
    # ----- Cambiar ------
    return [cambiar, hechizo_malo]     if desicion == lanzar && !@tipo_ataque.instance_of?(hechizo_malo)
    return [cambiar, hechizo_malo]     if desicion == cambiar && !@tipo_ataque.instance_of?(hechizo_malo)
    # ----- Otro ---------
    return [descansar, nil]            if desicion == descansar && @hp < (@max_hp / 35) || @mp == 0
    return [atras, nil]                if desicion == atras

    que_hacer_bot(false)
    # ------------ fin celeblo :( ---------
  end

  def elegir_enemigo
    jugador_debil = @menu.jugadores.reject { |jugador| jugador == self }.min_by(&:hp)
    jugador_fuerte = @menu.jugadores.reject { |jugador| jugador == self }.max_by(&:hp)
    jugador_random = @menu.jugadores.reject { |jugador| jugador == self }.sample
    return [jugador_debil, jugador_random, jugador_debil, jugador_random, jugador_fuerte].sample
  end

  def elegir_hechizo_malo
    hechizo_offensive = Offensive.subclasses.reject { |spell| spell.new.coste > @mp }.sample
    hechizo_debuff = Debuffs.subclasses.reject { |spell| spell.new.coste > @mp }.sample
    hechizos = [hechizo_offensive, hechizo_offensive, hechizo_debuff].sample
    return hechizos if !hechizos.nil?
    elegir_hechizo_malo
  end
end
