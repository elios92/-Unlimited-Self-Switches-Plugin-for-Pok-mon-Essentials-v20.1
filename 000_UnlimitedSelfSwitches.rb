#==============================================================================#
#                         Unlimited Self Switches v1.1                        #
#------------------------------------------------------------------------------#
#   Plugin per Pokémon Essentials v20.1                                       #
#   Autore: elios92                                                           #
#                                                                              #
#   Questo plugin consente di utilizzare Self Switch personalizzate,          #
#   definite nei commenti delle pagine evento.                                #
#                                                                              #
#   Le Self Switch personalizzate sono utili per creare eventi più dinamici e #
#   flessibili nei giochi sviluppati con Pokémon Essentials.                  #
#                                                                              #
#   Funzionalità principali:                                                  #
#     - Permette di definire Self Switch personalizzate nei commenti.         #
#     - Supporta il controllo dello stato ("on" o "off") delle Self Switch.   #
#     - Si integra con il metodo refresh di Game_Event.                       #
#==============================================================================#

module UnlimitedSelfSwitches
  # Metodo per verificare se una pagina ha commenti con switch personalizzate
  def self.has_custom_switch_comment?(page)
    return false unless page && page.list
    
    page.list.each do |command|
      next unless command.code == 108 || command.code == 408 # Controlla solo i commenti
      if command.parameters[0] =~ /Switch:\s*(\w+):\s*(on|off)/i
        return true
      end
    end
    
    return false
  end
  
  # Metodo per ottenere il nome e lo stato richiesto dalla switch
  def self.get_switch_info(page)
    return nil unless page && page.list
    
    page.list.each do |command|
      next unless command.code == 108 || command.code == 408 # Controlla solo i commenti
      if command.parameters[0] =~ /Switch:\s*(\w+):\s*(on|off)/i
        switch_name = $1
        required_state = ($2.downcase == "on")
        return [switch_name, required_state]
      end
    end
    
    return nil
  end
  
  # Verifica se la switch è nello stato richiesto
  def self.switch_has_correct_state?(map_id, event_id, switch_name, required_state)
    key = [map_id, event_id, switch_name]
    current_state = $game_self_switches[key] || false
    return current_state == required_state
  end
  
  # Debug: mostra lo stato di tutte le switch personalizzate
  def self.debug_switches
    puts "--- DEBUG: STATO SWITCH PERSONALIZZATE ---"
    $game_self_switches.each_key do |key|
      map_id, event_id, switch_name = key
      # Mostra solo le switch personalizzate (non A,B,C,D)
      next if ["A", "B", "C", "D"].include?(switch_name)
      value = $game_self_switches[key]
      puts "Mappa #{map_id}, Evento #{event_id}, Switch '#{switch_name}' = #{value ? 'ON' : 'OFF'}"
    end
    puts "----------------------------------------"
  end
  
  # Metodo per impostare una switch personalizzata
  def self.set_switch(map_id, event_id, switch_name, state)
    # Imposta la switch personalizzata
    key = [map_id, event_id, switch_name]
    $game_self_switches[key] = state
    puts "Switch personalizzata '#{switch_name}' per evento #{event_id} impostata a #{state ? 'ON' : 'OFF'}" if $DEBUG
    
    # Assicurati che la self-switch A sia OFF se richiesto
    key_a = [map_id, event_id, "A"]
    $game_self_switches[key_a] = false
    
    # Forza un refresh immediato dell'evento
    if $game_map && $game_map.events[event_id]
      # Forza un refresh diretto dell'evento
      $game_map.events[event_id].refresh
    else
      # Refresh generale della mappa
      $game_map.need_refresh = true
      $game_map.refresh if $game_map
    end
  end
end

#===============================================================================
# ** Game_Event
#===============================================================================
class Game_Event < Game_Character
  # Ottieni l'indice della pagina corrente
  def current_page_index
    return -1 unless @event && @page && @event.pages.is_a?(Array)
    idx = @event.pages.index(@page)
    idx ? idx : -1
  end

  # Alias per refresh (solo se non già definito, per evitare alias multipli)
  alias uss_original_refresh refresh unless method_defined?(:uss_original_refresh)

  # Override per refresh che controlla anche le switch personalizzate
  def refresh
    # Protezione: @event e @event.pages devono esistere ed essere un array
    return unless @event && @event.pages.is_a?(Array) && !@event.pages.empty?
    old_page_index = current_page_index

    # Esegui il refresh standard
    uss_original_refresh

    new_page_index = current_page_index
    return if old_page_index != new_page_index

    return unless @event && @event.pages.is_a?(Array) && @page

    @event.pages.each_with_index do |page, i|
      next unless page.is_a?(RPG::Event::Page)
      next if i == current_page_index

      c = page.condition
      next unless c
      next if c.switch1_valid && !$game_switches[c.switch1_id]
      next if c.switch2_valid && !$game_switches[c.switch2_id]
      next if c.variable_valid && $game_variables[c.variable_id] < c.variable_value

      switch_info = UnlimitedSelfSwitches.get_switch_info(page)
      next unless switch_info

      switch_name, required_state = switch_info
      if UnlimitedSelfSwitches.switch_has_correct_state?(@map_id, @id, switch_name, required_state)
        @page = page
        setup_page
        return
      end
    end
  end

  def setup_page
    return unless @page && @page.respond_to?(:graphic)

    @tile_id         = @page.graphic.tile_id
    @character_name  = @page.graphic.character_name
    @character_hue   = @page.graphic.character_hue
    if @original_direction != @page.graphic.direction
      @direction = @page.graphic.direction
      @original_direction = @direction
      @prelock_direction = 0
    end
    if @original_pattern != @page.graphic.pattern
      @pattern = @page.graphic.pattern
      @original_pattern = @pattern
    end
    @move_type      = @page.move_type
    @move_speed     = @page.move_speed
    @move_frequency = @page.move_frequency
    @move_route     = @page.move_route
    @move_route_index = 0
    @move_route_forcing = false
    @walk_anime     = @page.walk_anime
    @step_anime     = @page.step_anime
    @direction_fix  = @page.direction_fix
    @through        = @page.through
    @always_on_top  = @page.always_on_top
    @trigger        = @page.trigger
    @list           = @page.list
    @interpreter    = nil

    check_event_trigger_auto if @trigger == 3
  end
end
#==============================================================================
# ** Game_Interpreter
#==============================================================================
class Game_Interpreter
  # Imposta una switch personalizzata
  def set_custom_switch(event_id, switch_name, state)
    event_id = @event_id if event_id == 0
    map_id = @map_id > 0 ? @map_id : $game_map.map_id
    
    UnlimitedSelfSwitches.set_switch(map_id, event_id, switch_name, state)
  end
  
  # Controlla lo stato di una switch personalizzata
  def custom_switch_on?(event_id, switch_name)
    event_id = @event_id if event_id == 0
    map_id = @map_id > 0 ? @map_id : $game_map.map_id
    
    key = [map_id, event_id, switch_name]
    return $game_self_switches[key] == true
  end
  
  # Attiva una switch personalizzata
  def activate_custom_switch(event_id, switch_name)
    set_custom_switch(event_id, switch_name, true)
  end
  
  # Disattiva una switch personalizzata
  def deactivate_custom_switch(event_id, switch_name)
    set_custom_switch(event_id, switch_name, false)
  end
  
  # Debug: mostra lo stato di tutte le switch personalizzate
  def debug_custom_switches
    UnlimitedSelfSwitches.debug_switches
    return "Verifica la console di debug per i risultati"
  end
end

#==============================================================================
# ** Interpreter (aggiunto per essere compatibile con Essentials v20.1)
#==============================================================================
class Interpreter
  # Imposta una switch personalizzata
  def set_custom_switch(event_id, switch_name, state)
    event_id = @event_id if event_id == 0
    map_id = @map_id > 0 ? @map_id : $game_map.map_id
    
    UnlimitedSelfSwitches.set_switch(map_id, event_id, switch_name, state)
  end
  
  # Controlla lo stato di una switch personalizzata
  def custom_switch_on?(event_id, switch_name)
    event_id = @event_id if event_id == 0
    map_id = @map_id > 0 ? @map_id : $game_map.map_id
    
    key = [map_id, event_id, switch_name]
    return $game_self_switches[key] == true
  end
  
  # Attiva una switch personalizzata
  def activate_custom_switch(event_id, switch_name)
    set_custom_switch(event_id, switch_name, true)
  end
  
  # Disattiva una switch personalizzata
  def deactivate_custom_switch(event_id, switch_name)
    set_custom_switch(event_id, switch_name, false)
  end
  
  # Debug: mostra lo stato di tutte le switch personalizzate
  def debug_custom_switches
    UnlimitedSelfSwitches.debug_switches
    return "Verifica la console di debug per i risultati"
  end
end

