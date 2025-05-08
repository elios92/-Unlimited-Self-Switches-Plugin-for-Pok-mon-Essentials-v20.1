#===============================================================================
# Unlimited Self Switches Plugin for Pokémon Essentials v20.1
#-------------------------------------------------------------------------------
# Author: Adapted by elios92 & assistant
# Version: 1.1
#===============================================================================
# Estensione della Classe Interpreter
#===============================================================================
class Interpreter
  # Alias del metodo originale execute_command
  alias original_execute_command execute_command
  def execute_command
    # Rende i parametri del comando corrente disponibili tramite @parameters
    @parameters = @list[@index].parameters

    case @list[@index].code
    when 108 then process_self_switch_comment(@parameters[0]) # Inizio commento
    when 408 then process_self_switch_comment(@parameters[0]) # Continuazione commento
    else
      # Esegui il metodo originale per gli altri comandi
      return original_execute_command
    end
  end

  # Metodo per processare i commenti relativi ai Self Switch personalizzati
  def process_self_switch_comment(comment)
    # Controlla se il commento contiene un Self Switch personalizzato
    if comment =~ /^Switch:\s*(\w+)\s*=\s*(ON|OFF)/i
      switch_name = $1 # Nome del Self Switch
      switch_state = $2.upcase == "ON" # Stato del Self Switch (true per ON, false per OFF)

      # Regola: verifica che il nome del Self Switch non superi i 10 caratteri
      if switch_name.length > 10
        puts "Ignorato: Nome del Self Switch '#{switch_name}' troppo lungo (max 10 caratteri)."
        return
      end

      # Assicura che @event_id sia definito correttamente
      event_id = @event_id || @list[@index].parameters[0]

      # Costruisce la chiave per il Self Switch personalizzato
      key = [$game_map.map_id, event_id, switch_name]

      # Imposta lo stato del Self Switch personalizzato (ha priorità)
      $game_self_switches[key] = switch_state
      puts "Self Switch personalizzato '#{switch_name}' per Evento #{event_id} impostato su #{switch_state ? 'ON' : 'OFF'}."

      # Se esiste un Self Switch standard, lo sovrascrive
      if $game_self_switches[key]
        puts "Self Switch standard sovrascritto da '#{switch_name}'."
      end

      # Richiede un aggiornamento della mappa per riflettere i cambiamenti
      $game_map.need_refresh = true
    end
  end

  # Metodo per gestire direttamente i Self Switch personalizzati (chiamabile da script evento)
  def custom_self_switch(event_id, switch_name, state)
    # Controlla che il nome del Self Switch sia valido
    if switch_name.length > 10
      raise "Errore: Nome del Self Switch '#{switch_name}' troppo lungo (max 10 caratteri)."
    end

    # Costruisce la chiave per il Self Switch personalizzato
    key = [$game_map.map_id, event_id, switch_name]

    # Imposta lo stato del Self Switch
    $game_self_switches[key] = state

    # Aggiorna la mappa per riflettere il cambiamento
    $game_map.need_refresh = true

    # Messaggio di debug
    puts "Self Switch personalizzato '#{switch_name}' per Evento #{event_id} impostato su #{state ? 'ON' : 'OFF'}."
  end
end
#===============================================================================
# Metodo principale nel modulo UnlimitedSelfSwitches
#===============================================================================
# Esegui il codice solo dopo che tutti i plugin sono stati caricati
# Modulo per gestire Self Switch personalizzate
# Modulo per gestire Self Switch personalizzate
module UnlimitedSelfSwitches
  # Metodo per inizializzare il plugin
  def self.initialize
    # Log per indicare che il plugin è stato inizializzato
    puts "Plugin UnlimitedSelfSwitches inizializzato!"
  end
end

# Assicurati che Game_Event sia definita prima di estenderla
if defined?(Game_Event)
  class Game_Event
    # Alias e decorazione del metodo refresh
    if method_defined?(:refresh)
      alias unlimited_self_switch_refresh refresh
      def refresh
        # Richiama il metodo originale
        unlimited_self_switch_refresh if defined?(unlimited_self_switch_refresh)

        # Log di debug
        puts "Metodo 'refresh' chiamato per Evento #{@id} sulla mappa #{@map_id}."

        # Controlla le Self Switch personalizzate
        return if @page.nil? # Se non ci sono pagine attive, esci

        @page.list.each do |command|
          # Cerca il formato SelfSwitch: NomeSwitch nei commenti
          next unless command.code == 108 || command.code == 408
          if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/
            switch_name = $1
            key = [$game_map.map_id, @id, switch_name]
            unless $game_self_switches[key]
              puts "Self Switch '#{switch_name}' non attiva, disattivo la pagina."
              @page = nil
              break
            end
          end
        end

        puts "Evento #{@id}: Pagina aggiornata correttamente."
      end
    else
      puts "Il metodo 'refresh' non è definito nella classe Game_Event."
    end

    # Alias e decorazione del metodo conditions_met?
    if method_defined?(:conditions_met?)
      alias unlimited_self_switch_conditions_met conditions_met?
      def conditions_met?(page)
        # Richiama il metodo originale
        return false unless unlimited_self_switch_conditions_met(page)

        # Controlla le Self Switch personalizzate
        page.list.each do |command|
          next unless command.code == 108 || command.code == 408
          if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/
            switch_name = $1
            key = [$game_map.map_id, @id, switch_name]
            puts "Controllo Self Switch '#{switch_name}': #{$game_self_switches[key]}"
            return false unless $game_self_switches[key]
          end
        end

        true
      end
    else
      puts "Il metodo 'conditions_met?' non è definito nella classe Game_Event."
    end
  end
else
  puts "La classe Game_Event non è definita. Il plugin non può essere caricato."
end

# Inizializza il plugin
UnlimitedSelfSwitches.initialize
#===============================================================================
# Debug: Gestione manuale dei self switch
#===============================================================================
def self.toggle_self_switch
  # Controlla se la mappa è definita
  if $game_map.nil?
    pbMessage(_INTL("Errore: Nessuna mappa attualmente attiva."))
    return
  end

  map_id = $game_map.map_id
  choices = []
  keys = []

  # Itera sugli eventi della mappa corrente
  $game_map.events.each do |event_id, event|
    event.list.each do |command|
      if command.code == 108 || command.code == 408 # Commento
        if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/ # Regex per "SelfSwitch: NomeSwitch"
          switch_name = $1
          key = [map_id, event_id, switch_name]
          status = $game_self_switches[key] ? "ON" : "OFF"
          choices << _INTL("Evento {1} - '{2}' ({3})", event_id, switch_name, status)
          keys << key
        end
      end
    end
  end

  if choices.empty?
    pbMessage(_INTL("Nessun self switch personalizzato da modificare in questa mappa."))
    return
  end

  choice = pbShowCommands(nil, choices, -1)
  return if choice < 0

  key = keys[choice]
  $game_self_switches[key] = !$game_self_switches[key] # Inverti lo stato
  $game_map.need_refresh = true
  pbMessage(_INTL("Self Switch '{1}' per Evento {2} impostato su {3}.",
                  key[2], key[1], $game_self_switches[key] ? "ON" : "OFF"))
end
#===============================================================================
# Altre funzioni - Gestione Self Switch Personalizzati
# Other functions - Custom Self Switch Management
#===============================================================================
MenuHandlers.add(:debug_menu, :self_switches, {
  "name"        => _INTL("Gestisci Self Switch Personalizzati"),
  "parent"      => :other_menu,
  "description" => _INTL("Visualizza, modifica o aggiungi Self Switch personalizzati attivi nella mappa corrente."),
  "effect"      => proc {
    cmd = pbShowCommands(nil, [
      _INTL("Visualizza Self Switch"),  # Opzione per visualizzare
      _INTL("Modifica Self Switch"),   # Opzione per modificare
      _INTL("Aggiungi Self Switch"),   # Nuova opzione per aggiungere
      _INTL("Elimina Self Switch")     # Opzione per eliminare
    ], -1)
    case cmd
    when 0
      UnlimitedSelfSwitches.showSelfSwitches
    when 1
      UnlimitedSelfSwitches.toggle_self_switch
    when 2
      UnlimitedSelfSwitches.add_self_switch  # Nuova funzione
    when 3
      UnlimitedSelfSwitches.deleteSelfSwitch
    end
  }
})
#===============================================================================
# Visualizza Self Switch Personalizzati (Aggiornata per gestire contesti senza mappa)
#===============================================================================
def showSelfSwitches
  # Controlla se $game_map è definito
  if $game_map.nil?
    pbMessage(_INTL("Errore: Nessuna mappa attualmente attiva."))
    return
  end

  # Verifica che $game_self_switches sia inizializzato
  if $game_self_switches.nil? || $game_self_switches.instance_variable_get(:@data).empty?
    pbMessage(_INTL("Nessun self switch personalizzato attivo in questa mappa."))
    return
  end

  list = []
  $game_self_switches.instance_variable_get(:@data).each_key do |key|
    map_id, event_id, switch_name = key
    next unless map_id == $game_map.map_id # Filtra solo gli eventi della mappa attuale
    status = $game_self_switches[key] ? "ON" : "OFF"
    list << _INTL("Evento {1} - Switch '{2}' -> {3}", event_id, switch_name, status)
  end

  if list.empty?
    pbMessage(_INTL("Nessun self switch personalizzato attivo in questa mappa."))
  else
    pbMessage(_INTL("Self Switch attivi:\n{1}", list.join("\n")))
  end
end

#===============================================================================
# Modifica Self Switch Personalizzati (Aggiornata per aggiungere ramo condizionale e rinomina)
#===============================================================================
def self.modify_self_switches
  loop do
    # Controlla se la mappa è definita
    if $game_map.nil?
      pbMessage(_INTL("Errore: Nessuna mappa attualmente attiva."))
      return
    end

    # Verifica che $game_self_switches abbia Self Switch attivi
    if !$game_self_switches || $game_self_switches.instance_variable_get(:@data).empty?
      pbMessage(_INTL("Nessun self switch personalizzato da modificare in questa mappa."))
      return
    end

    map_id = $game_map.map_id
    choices = []
    keys = []

    # Itera sugli eventi della mappa corrente
    $game_map.events.each do |event_id, event|
      event.list.each do |command|
        # Cerca i commenti che definiscono Self Switch personalizzati
        if command.code == 108 || command.code == 408 # Commento
          if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/ # Regex per "SelfSwitch: NomeSwitch"
            switch_name = $1
            key = [map_id, event_id, switch_name]
            status = $game_self_switches[key] ? "ON" : "OFF"
            choices << _INTL("Evento {1} - '{2}' ({3})", event_id, switch_name, status)
            keys << key
          end
        end
      end
    end

    if choices.empty?
      pbMessage(_INTL("Nessun self switch personalizzato da modificare in questa mappa."))
      return
    end

    # Mostra il menu per selezionare il Self Switch da modificare
    choice = pbShowCommands(nil, choices, -1)
    return if choice < 0 # L'utente ha annullato

    # Chiave del Self Switch selezionato
    key = keys[choice]

    # Menu per modificare il Self Switch selezionato
    cmd = pbShowCommands(nil, [
      _INTL("Inverti Stato"),             # Opzione per invertire ON/OFF
      _INTL("Modifica Ramo Condizionale"), # Modifica ramo condizionale
      _INTL("Rinomina Self Switch"),       # Rinominare la Self Switch
      _INTL("Torna al menu principale")    # Torna al menu principale
    ], -1)

    case cmd
    when 0 # Inverti Stato
      $game_self_switches[key] = !$game_self_switches[key] # Inverti lo stato
      pbMessage(_INTL("Self Switch '{1}' per Evento {2} impostato su {3}.",
                      key[2], key[1], $game_self_switches[key] ? "ON" : "OFF"))
    when 1 # Modifica Ramo Condizionale
      modify_conditional_branch(key)
    when 2 # Rinomina Self Switch
      rename_self_switch(key)
    when 3 # Torna al menu principale
      return # Esce dal loop e torna al menu principale
    end

    $game_map.need_refresh = true
  end
end

#===============================================================================
# Modifica il Ramo Condizionale Associato a una Self Switch
#===============================================================================
def self.modify_conditional_branch(key)
  pbMessage(_INTL("Modifica ramo condizionale associato a '{1}' per Evento {2}.", key[2], key[1]))
  # Puoi aggiungere qui la logica per configurare o modificare il ramo condizionale
  # Ad esempio, potresti chiedere all'utente di inserire una condizione personalizzata
  pbMessage(_INTL("Questa funzionalità è in fase di sviluppo."))
end

#===============================================================================
# Rinomina una Self Switch Personalizzata
#===============================================================================
def self.rename_self_switch(key)
  # Chiedi il nuovo nome per la Self Switch
  new_name = pbEnterText(_INTL("Inserisci il nuovo nome per la Self Switch:"), 1, 20)
  if new_name.nil? || new_name.empty?
    pbMessage(_INTL("Nessun nome inserito."))
    return
  end

  if new_name.length > 10
    pbMessage(_INTL("Il nome inserito è troppo lungo (max 10 caratteri)."))
    return
  end

  # Crea una nuova chiave con il nuovo nome
  new_key = [key[0], key[1], new_name]

  # Sposta lo stato della Self Switch alla nuova chiave
  $game_self_switches[new_key] = $game_self_switches.delete(key)

  pbMessage(_INTL("Self Switch '{1}' rinominata in '{2}' per Evento {3}.", key[2], new_name, key[1]))
end
#===============================================================================
# aggunge Self Switch Personalizzate
#===============================================================================
def self.add_self_switch
  # Controlla se la mappa è attiva
  if $game_map.nil?
    pbMessage(_INTL("Errore: Nessuna mappa attualmente attiva."))
    return
  end
  
  # Ottieni l'elenco degli eventi nella mappa corrente
  events = $game_map.events.keys
  if events.empty?
    pbMessage(_INTL("Nessun evento disponibile in questa mappa."))
    return
  end

  # Mostra un menu per selezionare l'evento
  choices = events.map { |id| _INTL("Evento {1}", id) }
  event_choice = pbShowCommands(nil, choices, -1)
  return if event_choice < 0 # L'utente ha annullato
  selected_event_id = events[event_choice]

  # Chiedi all'utente di inserire il nome del Self Switch
  switch_name = pbEnterText(_INTL("Inserisci il nome del Self Switch:"), 1, 20)
  if switch_name.nil? || switch_name.empty?
    pbMessage(_INTL("Nessun nome inserito."))
    return
  end

  # Chiedi lo stato iniziale del Self Switch
  state_choice = pbShowCommands(nil, [_INTL("ON"), _INTL("OFF")], -1)
  return if state_choice < 0 # L'utente ha annullato
  initial_state = (state_choice == 0) # 0 = ON, 1 = OFF

  # Aggiungi il nuovo Self Switch al sistema
  key = [$game_map.map_id, selected_event_id, switch_name]
  $game_self_switches[key] = initial_state
  $game_map.need_refresh = true

  # Conferma all'utente
  pbMessage(_INTL("Self Switch '{1}' per Evento {2} creato e impostato su {3}.",
                  switch_name, selected_event_id, initial_state ? "ON" : "OFF"))
end
#===============================================================================
# Elimina un Self Switch Personalizzato
# Delete a Custom Self Switch
#===============================================================================
def self.deleteSelfSwitch
  # Controlla se la mappa è definita
  if $game_map.nil?
    pbMessage(_INTL("Errore: Nessuna mappa attualmente attiva."))
    return
  end

  # Verifica che $game_self_switches abbia Self Switch personalizzati
  if !$game_self_switches || $game_self_switches.instance_variable_get(:@data).empty?
    pbMessage(_INTL("Nessun self switch personalizzato da eliminare in questa mappa."))
    return
  end

  map_id = $game_map.map_id
  choices = []
  keys = []

  # Itera attraverso i Self Switch memorizzati
  $game_self_switches.instance_variable_get(:@data).each_key do |key|
    next unless key[0] == map_id # Filtra solo gli eventi della mappa attuale
    event_id, switch_name = key[1], key[2]
    status = $game_self_switches[key] ? "ON" : "OFF"
    choices << _INTL("Evento {1} - '{2}' ({3})", event_id, switch_name, status)
    keys << key
  end

  if choices.empty?
    pbMessage(_INTL("Nessun self switch personalizzato da eliminare in questa mappa."))
    return
  end

  # Mostra il menu per selezionare il Self Switch da eliminare
  choice = pbShowCommands(nil, choices, -1)
  return if choice < 0

  key = keys[choice]
  # Prima Conferma
  confirmed = pbConfirmMessage(_INTL("Sei sicuro di voler eliminare il Self Switch '{1}' per Evento {2}?", key[2], key[1]))
  return unless confirmed

  # Elimina il Self Switch selezionato
  $game_self_switches.instance_variable_get(:@data).delete(key)
  $game_map.need_refresh = true
  pbMessage(_INTL("Self Switch '{1}' per Evento {2} eliminato con successo.", key[2], key[1]))
end
#===============================================================================
# Eestensione della  della classe game event
#-------------------------------------------------------------------------------
# PluginManager: Caricamento ritardato del plugin per evitare problemi di ordine
PluginManager.register({ :name => "Unlimited Self Switches", :version => "1.1" })

# Esegui il codice solo quando Game_Event è definito
# Estensione della Classe Game_Event
if defined?(Game_Event)
  puts "DEBUG: La classe Game_Event è definita."

  class Game_Event
    # Metodo refresh
    def refresh
      puts "DEBUG: Inizio metodo 'refresh' per Evento #{@id} nella mappa #{@map_id}."
    
      # Controlla se la mappa è una "mappa grotta"
      map_ids_grotte = [550,05, 10, 15, 20] # Sostituisci con gli ID delle tue mappe grotte
 # Controlla se la mappa è una "mappa grotta"
 map_ids_grotte = [5, 10, 15, 20] # Sostituisci con gli ID delle tue mappe grotte
 is_grotta = map_ids_grotte.include?(@map_id)

 new_page = nil
 unless @erased
   @event.pages.reverse.each do |page|
     c = page.condition
     next if c.switch1_valid && !switchIsOn?(c.switch1_id)
     next if c.switch2_valid && !switchIsOn?(c.switch2_id)
     next if c.variable_valid && $game_variables[c.variable_id] < c.variable_value
     if c.self_switch_valid
       key = [@map_id, @event.id, c.self_switch_ch]
       # Per le mappe grotte, aggiungi logica personalizzata per i SelfSwitch
       if is_grotta
         puts "DEBUG: Evento #{@id} nella mappa grotta #{@map_id}: controllo SelfSwitch '#{c.self_switch_ch}'"

         # Esempio di logica per il ritorno dello stato del SelfSwitch
         if some_custom_condition_met?
           puts "DEBUG: Attivazione SelfSwitch '#{c.self_switch_ch}' per Evento #{@id}."
           $game_self_switches[key] = true
         else
           puts "DEBUG: Disattivazione SelfSwitch '#{c.self_switch_ch}' per Evento #{@id}."
           $game_self_switches[key] = false
         end

         # Forza il refresh della mappa per aggiornare lo stato dell'evento
         $game_map.need_refresh = true
       end
       next if $game_self_switches[key] != true
     end
     new_page = page
     break
   end
 end
 return if new_page == @page

 @page = new_page
 clear_starting
 if @page.nil?
   @tile_id        = 0
   @character_name = ""
   @character_hue  = 0
   @move_type      = 0
   @through        = true
   @trigger        = nil
   @list           = nil
   @interpreter    = nil
   return
 end
 # Configura i parametri della nuova pagina
 @tile_id              = @page.graphic.tile_id
 @character_name       = @page.graphic.character_name
 @character_hue        = @page.graphic.character_hue
 if @original_direction != @page.graphic.direction
   @direction          = @page.graphic.direction
   @original_direction = @direction
   @prelock_direction  = 0
 end
 if @original_pattern != @page.graphic.pattern
   @pattern            = @page.graphic.pattern
   @original_pattern   = @pattern
 end
 @opacity              = @page.graphic.opacity
 @blend_type           = @page.graphic.blend_type
 @move_type            = @page.move_type
 self.move_speed       = @page.move_speed
 self.move_frequency   = @page.move_frequency
 @move_route           = (@route_erased) ? RPG::MoveRoute.new : @page.move_route
 @move_route_index     = 0
 @move_route_forcing   = false
 @walk_anime           = @page.walk_anime
 @step_anime           = @page.step_anime
 @direction_fix        = @page.direction_fix
 @through              = @page.through
 @always_on_top        = @page.always_on_top
 calculate_bush_depth
 @trigger              = @page.trigger
 @list                 = @page.list
 @interpreter          = nil
 if @trigger == 4   # Parallel Process
   @interpreter        = Interpreter.new
 end
 check_event_trigger_auto
 puts "DEBUG: Fine metodo 'refresh' per Evento #{@id} nella mappa #{@map_id}."
end

# Metodo per la tua condizione personalizzata
def some_custom_condition_met?
 # Sostituisci con la logica per determinare se il SelfSwitch deve essere attivato/disattivato
 # Ad esempio, puoi controllare una variabile, un timer o un'altra condizione
 return true # Esempio: sempre vero
end
    # Metodo conditions_met?
    if method_defined?(:conditions_met?)
      puts "DEBUG: Il metodo 'conditions_met?' è definito nella classe Game_Event."

      alias unlimited_self_switch_conditions_met conditions_met?

      def conditions_met?(page)
        puts "DEBUG: Metodo 'conditions_met?' chiamato per Evento #{@id}."

        # Richiama il metodo originale
        unless unlimited_self_switch_conditions_met(page)
          puts "DEBUG: Condizioni standard non soddisfatte per la pagina."
          return false
        end

        # Controlla le Self Switch personalizzate
        page.list.each do |command|
          next unless command.code == 108 || command.code == 408
          puts "DEBUG: Analizzo il commento: #{command.parameters[0]}"
          if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/
            switch_name = $1
            key = [$game_map.map_id, @id, switch_name]
            puts "DEBUG: Controllo Self Switch '#{switch_name}': #{$game_self_switches[key]}"
            return false unless $game_self_switches[key]
          end
        end

        puts "DEBUG: Tutte le condizioni sono soddisfatte per Evento #{@id}."
        true
      end
    else
      puts "DEBUG: Il metodo 'conditions_met?' NON è definito nella classe Game_Event. Aggiungo una definizione personalizzata."

      # Fallback per il metodo 'conditions_met?'
      def conditions_met?(page)
        puts "DEBUG: Metodo 'conditions_met?' (fallback) chiamato per Evento #{@id}."

        # Logica base per verificare le condizioni
        return true if page.list.nil? || page.list.empty?

        page.list.each do |command|
          if command.code == 108 || command.code == 408
            puts "DEBUG: Analizzo il commento: #{command.parameters[0]}"
            if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/
              switch_name = $1
              key = [$game_map.map_id, @id, switch_name]
              puts "DEBUG: Controllo Self Switch '#{switch_name}': #{$game_self_switches[key]}"
              return false unless $game_self_switches[key]
            end
          end
        end

        puts "DEBUG: Tutte le condizioni soddisfatte per Evento #{@id}."
        true
      end
    end

    puts "DEBUG: La classe Game_Event è stata estesa correttamente."
  end
else
  puts "DEBUG: La classe Game_Event NON è definita. Il plugin non può essere caricato."
end
# =============================================================================
# Estensionedella classe Game_Event game character per gestire Switch personalizzate
# =============================================================================
class Game_Event < Game_Character
  # Alias del metodo setup_page per aggiungere la logica dei Self Switch personalizzati
  unless method_defined?(:setup_page)
    def setup_page(new_page)
      @page = new_page
      clear_page_settings unless @page
    end
  end

  alias unlimited_self_switch_setup setup_page
  def setup_page(new_page)
    unlimited_self_switch_setup(new_page)
    return unless @page && @page.list

    @page.list.each do |command|
      next unless command.code == 108 || command.code == 408

      # Cerca nei commenti della pagina dell'evento i Self Switch personalizzati
      if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/
        switch_name = $1
        key = [$game_map.map_id, @id, switch_name]
        $game_self_switches[key] ||= false
      end
    end
  end

  # Controlla se una Self Switch personalizzata è attiva
  def custom_self_switch_active?(switch_name)
    key = [$game_map.map_id, @id, switch_name]
    $game_self_switches[key] == true
  end

  # Alias del metodo conditions_met? per aggiungere il supporto alle Self Switch personalizzate
  alias unlimited_self_switch_conditions_met? conditions_met?
  def conditions_met?(page)
    # Controlla le condizioni standard
    return false unless unlimited_self_switch_conditions_met?(page)

    # Controlla le Self Switch personalizzate nei commenti della pagina
    page.list.each do |command|
      next unless command.code == 108 || command.code == 408

      if command.parameters[0] =~ /SelfSwitch:\s*(\w+)/
        switch_name = $1
        return false unless custom_self_switch_active?(switch_name)
      end
    true
    end
  end
end