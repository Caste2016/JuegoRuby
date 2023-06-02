class Estado
  def nombre
    self.class
  end
  def cambiar_estado(ataques, persona, estado)
    estado = cambiar_rage(persona) if ataques == 5
    estado = cambiar_dummy(persona) if ataques == 10 || estado == Dummy
    estado
  end

  def remover_efecto(efecto, jugador)
    jugador.remover_efecto(efecto)
  end

  def añadir_efecto(efecto, jugador)
    efecto.new(jugador)
  end

  def cambiar_rage(persona)
    persona.enviar("#{persona.nombre} esta en llamas!")
    Rage.new
  end

  def cambiar_dummy(persona)
    persona.enviar("#{persona.nombre} se a cansado...")
    Dummy.new
  end

  def dañar(otro_personaje, daño_base)
    otro_personaje.disminuir_hp(daño_base)
  end
end

class Normal < Estado
end

class Rage < Estado

  def dañar(otro_personaje, daño_base)
    otro_personaje.disminuir_hp(daño_base * 2)
  end
end

class Dummy < Estado
  def dañar(otro_personaje, daño_base)
    otro_personaje.disminuir_hp(daño_base / 2)
  end
end

class Desorientación < Estado
  def initialize(jugador)
    @turnos = 5
    @jugador = jugador
  end

  def efecto
    @turnos -= 1
    @jugador.disminuir_hp(3)
    @jugador.menu.remover_jugador(self, @jugador) if @jugador.hp <= 0
    remover_efecto(self, @jugador) if @turnos == 0
  end
end
