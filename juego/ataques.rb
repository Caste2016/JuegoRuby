class Ataque
  def nombre
    self.class
  end

  def desc
    'Hechizo sin descripción.'
  end

  def cambiar_ataque(ataque, _persona)
    ataque.new
  end

  def lanzar(_otro_personaje, _daño_base, _mana, personaje)
    personaje.enviar("(#{self.class})Este hechizo no hace nada")
  end
end
# ---------------------------------------------------------------------------------

class Offensive < Ataque
  def desc
    "Hechizos para dañar"
  end
end
class Defensive < Ataque
  def desc
    "Hechizos de defensa"
  end
end
class Buffs < Ataque
  def desc
    "Hechizos que causan un beneficio"
  end
end
class Debuffs < Ataque
  def desc
    "Hechizos que causan un desbeneficio"
  end
end

class Magia < Offensive
  attr_reader :nombre, :desc, :coste

  def initialize
    @nombre = 'Dardo Magico'
    @desc = "Produce 5 puntos de daño más que el daño que produce el atacar del personaje.\nTiene un costo de 5MP"
    @coste = 5
  end

  def lanzar(otro_personaje, daño_base, mana, personaje)
    if mana >= @coste
      daño_enemigo = otro_personaje.disminuir_hp(daño_base + 5)
      coste_self = personaje.disminuir_mp(@coste)
      [true, daño_enemigo, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end
# -----------------------------------------------------------------

class Fuego < Offensive
  attr_reader :nombre, :desc, :coste

  def initialize
    @nombre = 'Bola de fuego'
    @desc = "Produce el doble del daño que ya produce el atacar del personaje.\nTiene un costo de 10MP"
    @coste = 10
  end

  def lanzar(otro_personaje, daño_base, mana, personaje)
    if mana >= @coste
      daño_enemigo = otro_personaje.disminuir_hp(daño_base * 2)
      coste_self = personaje.disminuir_mp(@coste)
      [true, daño_enemigo, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end

# ----------------------------------------------------------------
class Psiquico < Offensive
  attr_reader :nombre, :desc

  def initialize
    @nombre = 'Ataque psiquico'
    @desc = "Produce una bonificador random que multiplica el daño que ya produce el atacar del personaje.\nTiene un costo random entre 0..10MP"
  end

  def coste
    rand(1..10)
  end

  def lanzar(otro_personaje, daño_base, mana, personaje)
    coste_mana = coste
    if mana >= coste
      daño_enemigo = otro_personaje.disminuir_hp((daño_base * coste_mana) / 2)
      coste_self = personaje.disminuir_mp(coste_mana)
      personaje.enviar('El hechizo no fue efectivo!') if [1, 2].include?(coste_mana)
      personaje.enviar('El hechizo fue efectivo!') if [9, 10].include?(coste_mana)
      [true, daño_enemigo, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end

# ---------------------------------------------------------------
class Alma < Offensive
  attr_reader :nombre, :desc

  def initialize
    @nombre = 'Ataque alma'
    @desc = "Igual que el Ataque psíquico pero además reduce 10% de MP del personaje atacado.\nTiene un costo random entre 0..10MP"
  end

  def coste
    rand(1..10)
  end

  def lanzar(otro_personaje, daño_base, mana, personaje)
    coste_mana = coste
    costeMalo = (otro_personaje.mp * 0.1).floor
    if mana >= coste_mana
      daño_enemigo = otro_personaje.disminuir_hp((daño_base * coste_mana) / 2)
      coste_enemigo = otro_personaje.disminuir_mp(costeMalo)
      coste_self = personaje.disminuir_mp(coste_mana)
      personaje.enviar('El hechizo no fue efectivo!') if [1, 2].include?(coste_mana)
      personaje.enviar('El hechizo fue efectivo!') if [9, 10].include?(coste_mana)
      [true, daño_enemigo, nil, coste_enemigo, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end

# -------------------------------------------------------------
class Kadavra < Offensive
  attr_reader :desc, :coste

  def initialize
    @desc = "Elimina automáticamente al personaje atacado.\nTiene un costo de 50MP"
    @coste = 50
  end

  def lanzar(otro_personaje, _daño_base, mana, personaje)
    if mana >= @coste
      if personaje.nombre == 'Aniquilador'
        daño_total = 0
        aniquilar = personaje.menu.jugadores.reject { |enemigo| enemigo == personaje }
        aniquilar.each do |enemigo|
          next if enemigo == personaje
          daño_total += enemigo.hp
          enemigo.disminuir_hp(enemigo.hp)
          personaje.menu.remover_jugador(personaje, enemigo) if enemigo.hp == 0
        end
        personaje.enviar("El Aniquilador aniquiló a todos los jugadores!!!!\nDaño total: #{daño_total}")
      else
        daño_enemigo = otro_personaje.disminuir_hp(otro_personaje.hp)
        coste_self = personaje.disminuir_mp(@coste)
        [true, daño_enemigo, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
      end
    else
      [false]
    end
  end
end

# -------------------------------------------------------------
class Liche < Debuffs
  attr_reader :desc, :coste

  def initialize
    @desc = 'Produce la mitad del daño que ya produce el atacar del personaje pero le resta el 15% del MP al atacado y se lo suma al atacante. Si el atacado no tiene MP le produce 10% de daño extra al HP y el atacante gana un punto de vida.'
    @coste = 0
  end

  def lanzar(otro_personaje, daño_base, _mana, personaje)
    costeMalo = (otro_personaje.mp * 0.15).floor
    daño_enemigo = otro_personaje.disminuir_hp(daño_base / 2)
    if costeMalo >= 0 && otro_personaje.mp > 6
      coste_enemigo = otro_personaje.disminuir_mp(costeMalo)
      coste_self = personaje.regenerar_mp(costeMalo)
      [true, daño_enemigo, nil, coste_enemigo, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      daño_enemigo += otro_personaje.disminuir_hp((otro_personaje.hp * 0.1).floor)
      daño_self = personaje.regenerar_hp(1)
      [true, daño_enemigo, daño_self, nil, nil] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    end
  end
end

class Oscuridad < Debuffs
  attr_reader :desc, :coste, :nombre

  def initialize
    @nombre = "Oscuridad abrasadora"
    @desc = "Este hechizo envuelve al enemigo en una oscuridad intensa, obstruyendo su visión y haciéndole incapaz de ver sus propias estadísticas. Además, cada 5 turnos, el efecto de la oscuridad inflige un ligero daño adicional al objetivo.\nTiene un coste de 30"
    @coste = 30
  end

  def lanzar(otro_personaje, _daño_base, mana, personaje)
    if mana >= @coste
      coste_self = personaje.disminuir_mp(@coste)
      otro_personaje.añadir_efecto(Desorientación, otro_personaje)
      [true, nil, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end

class Invalidador < Debuffs # Sugerencia por Ezequiel
  attr_reader :desc, :coste

  def initialize
    @desc = "Vuelve al personaje pelotudo. Sugerido por Ezequiel.\nTiene un coste de 10MP"
    @coste = 10
  end

  def lanzar(otro_personaje, _daño_base, mana, personaje)
    if mana >= @coste
      coste_self = personaje.disminuir_mp(@coste)
      daño_enemigo = otro_personaje.disminuir_hp(5)
      otro_personaje.cambiar_estado(nil, otro_personaje, Dummy)
      [true, daño_enemigo, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end

class Resplandor < Defensive
  attr_reader :nombre, :desc, :coste
  def initialize
    @nombre = "Resplandor curativo"
    @desc = "Es un poderoso hechizo de sanación que irradia una luz brillante y reconfortante. Al ser lanzado sobre el personaje, envuelve su cuerpo en una energía curativa, sanando sus heridas y restaurando su salud.\nTiene un coste de 20MP"
    @coste = 20
  end

  def lanzar(otro_personaje, daño_base, mana, personaje)
    if mana >= @coste
      coste_self = personaje.disminuir_mp(@coste)
      curacion = otro_personaje.regenerar_hp(20)
      [true, curacion, nil, nil, coste_self] # Se pudo lanzar?, HP enemigo, HP atacante, MP enemigo, Mp atacante
    else
      [false]
    end
  end
end