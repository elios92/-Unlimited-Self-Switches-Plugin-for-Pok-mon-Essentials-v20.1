#===========================================================================
# Menu Avanzato - Sistema Modulare
#===========================================================================

# Registra il menu avanzato principale nel debug menu
MenuHandlers.add(:debug_menu, :advanced_tools, {
  "parent"      => :main,
  "name"        => "Strumenti Avanzati",
  "description" => "Accedi a strumenti avanzati e plugin personalizzati.",
  "always_show" => true,
  "effect"      => proc { 
    pbAdvancedToolsMenu  # Ora chiama il menu principale
  }
})

# Menu principale degli strumenti avanzati
def pbAdvancedToolsMenu
  puts "[DEBUG] Entrato nel menu Strumenti Avanzati"
  
  # Comandi del menu principale
  commands = [
    "Gestione Switch Personalizzate",  # Sottomenu per le UnlimitedSelfSwitches
    "Gestione delle Traduzioni",       # Per gestione multilingua del gioco
    "Esportazione Mappe ed Eventi",    # Per export/import di mappe e eventi
    "Utilità di Debug",                # Per strumenti di debug personalizzati
    "Esci"
  ]
  
  puts "[DEBUG] Menu avanzato - Opzioni disponibili: #{commands.inspect}"
  
  # Configura la finestra dei comandi
  begin
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99999
    cmdwindow = Window_CommandPokemonEx.new(commands)
    cmdwindow.x = 0
    cmdwindow.y = 0
    cmdwindow.width = Graphics.width
    cmdwindow.height = Graphics.height
    cmdwindow.viewport = viewport
    
    # Loop principale
    loop do
      Graphics.update
      Input.update
      cmdwindow.update
      
      if Input.trigger?(Input::USE)
        selected_index = cmdwindow.index
        puts "[DEBUG] Menu avanzato - Opzione selezionata: Indice=#{selected_index}"
        
        case selected_index
        when 0 # Gestione Switch Personalizzate
          puts "[DEBUG] Aprendo il sottomenu delle Switch Personalizzate"
          begin
            manageSelfSwitches  # Ora è un sottomenu
          rescue => e
            puts "[ERROR] Errore nel sottomenu Switch Personalizzate: #{e.message}"
            puts e.backtrace.join("\n") if $DEBUG
            pbMessage(_INTL("Si è verificato un errore: {1}", e.message))
          end
        when 1 # Gestione delle Traduzioni
          pbMessage(_INTL("Gestione delle Traduzioni non ancora implementata.\nQuesta funzione permetterà di gestire i file di traduzione del gioco."))
        when 2 # Esportazione Mappe ed Eventi
          pbMessage(_INTL("Esportazione Mappe ed Eventi non ancora implementata.\nQuesta funzione permetterà di esportare e importare mappe ed eventi."))
        when 3 # Utilità di Debug
          pbMessage(_INTL("Utilità di Debug non ancora implementate.\nQuesta funzione conterrà strumenti di debug avanzati."))
        when 4 # Esci
          puts "[DEBUG] Uscita dal menu Strumenti Avanzati"
          break
        end
      elsif Input.trigger?(Input::BACK)
        puts "[DEBUG] Tornando al menu di debug principale"
        break
      end
    end
  ensure
    # Pulizia delle risorse
    cmdwindow.dispose if cmdwindow && !cmdwindow.disposed?
    viewport.dispose if viewport && !viewport.disposed?
  end
end

##############################################################################
# Sottomenu: Gestione Switch Personalizzate
##############################################################################

# Metodo per gestire le Self Switch personalizzate (ora è un sottomenu)
def manageSelfSwitches
  puts "[DEBUG] Entrato nel sottomenu Switch Personalizzate"

  # Controlla se il gestore delle switch personalizzate è inizializzato
  unless $self_switch_manager
    puts "[DEBUG] Inizializzazione del gestore delle switch personalizzate"
    $self_switch_manager = SelfSwitchManager.new
    # Scansiona tutte le switch personalizzate esistenti nel gioco
    $self_switch_manager.scan_all_custom_switches
    pbMessage(_INTL("Il gestore delle switch personalizzate è stato inizializzato."))
  end
  
  # Menu delle operazioni per le switch personalizzate
  commands = [
    "Gestisci switch per mappa",
    "Visualizza switch della mappa corrente",
    "Cerca switch per nome", 
    "Torna al Menu Avanzato"  # Cambiato da "Esci" per essere più chiaro
  ]
  
  # Configura la finestra dei comandi
  begin
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99999
    cmdwindow = Window_CommandPokemonEx.new(commands)
    cmdwindow.x = 0
    cmdwindow.y = 0
    cmdwindow.width = Graphics.width
    cmdwindow.height = Graphics.height
    cmdwindow.viewport = viewport
    
    # Loop principale per gestire l'interazione con l'utente
    loop do
      Graphics.update
      Input.update
      cmdwindow.update
      
      if Input.trigger?(Input::USE)
        case cmdwindow.index
        when 0 # Gestisci switch per mappa
          manageSwitchesByMap
        when 1 # Visualizza switch della mappa corrente
          pbShowAllCustomSwitchesInMap
        when 2 # Cerca switch per nome
          pbSearchCustomSwitches
        when 3 # Torna al Menu Avanzato
          puts "[DEBUG] Tornando al menu Strumenti Avanzati"
          break
        end
      elsif Input.trigger?(Input::BACK)
        puts "[DEBUG] Tornando al menu Strumenti Avanzati"
        break
      end
    end
  ensure
    # Pulizia delle risorse
    cmdwindow.dispose if cmdwindow && !cmdwindow.disposed?
    viewport.dispose if viewport && !viewport.disposed?
  end
end
#===============================================================================

#===============================================================================
# Metodo per gestire le switch personalizzate per mappa
def manageSwitchesByMap
  puts "[DEBUG] Entrato in manageSwitchesByMap"
  
  # Metodo locale per caricare i nomi delle mappe
  load_map_names = lambda do
    puts "[DEBUG] Caricamento dei nomi delle mappe..."
    map_names = {}
    
    # MIGLIORAMENTO: Gestione degli errori durante il caricamento
    begin
      mapinfos = load_data("Data/MapInfos.rxdata") rescue nil
      
      # MIGLIORAMENTO: Controllo se mapinfos è nil prima di usare .each
      if mapinfos.nil?
        puts "[ERROR] Impossibile caricare le informazioni delle mappe."
        pbMessage(_INTL("Impossibile caricare le informazioni delle mappe."))
        return {}
      end
      
      mapinfos.each do |id, info|
        # MIGLIORAMENTO: Controllo del tipo per prevenire errori
        next unless id.is_a?(Integer) && info.respond_to?(:name)
        puts "[DEBUG] Mappa caricata: ID=#{id}, Nome=#{info.name}"
        map_names[id] = info.name
      end
    rescue => e
      # MIGLIORAMENTO: Gestione di qualsiasi errore durante il caricamento
      puts "[ERROR] Errore durante il caricamento delle mappe: #{e.message}"
      pbMessage(_INTL("Si è verificato un errore durante il caricamento delle mappe: {1}", e.message))
      return {}
    end
    
    map_names
  end
  
  # Carica la lista delle mappe e le ordina per ID
  map_list = load_map_names.call
  
  # MIGLIORAMENTO: Verifica che map_list risponda a .sort prima di chiamarlo
  map_list = map_list.sort.to_h if map_list.respond_to?(:sort)
  
  puts "[DEBUG] Lista delle mappe ordinate: #{map_list.inspect}"
  if map_list.empty?
    pbMessage(_INTL("Non ci sono mappe disponibili."))
    puts "[DEBUG] Nessuna mappa trovata"
    return
  end

  # Crea i comandi del menu
  commands = []
  map_list.each do |id, name|
    commands << "Mappa #{id}: #{name}"
  end
  commands << "Esci"
  puts "[DEBUG] Comandi del menu creati: #{commands.inspect}"

  # Configura la finestra dei comandi
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  cmdwindow = Window_CommandPokemonEx.new(commands)
  cmdwindow.x = 0
  cmdwindow.y = 0
  cmdwindow.width = Graphics.width
  cmdwindow.height = Graphics.height
  cmdwindow.viewport = viewport

  # Loop principale per gestire l'interazione con l'utente
  loop do
    Graphics.update
    Input.update
    cmdwindow.update

    if Input.trigger?(Input::USE)
      selected_map_index = cmdwindow.index
      puts "[DEBUG] Opzione selezionata: Indice=#{selected_map_index}"
      if selected_map_index == commands.length - 1 # Se è selezionato "Esci"
        puts "[DEBUG] Selezionata l'opzione Esci"
        break
      else
        # Ottiene l'ID della mappa selezionata e chiama la gestione delle switch per quella mappa
        map_id = map_list.keys[selected_map_index]
        puts "[DEBUG] ID della mappa selezionata: #{map_id}"
        manageSwitchesForMap(map_id)
      end
    elsif Input.trigger?(Input::BACK)
      puts "[DEBUG] Tornando al menu precedente"
      break
    end
  end

  # Pulizia delle risorse
  cmdwindow.dispose
  viewport.dispose
end

# Metodo per gestire le switch personalizzate per una mappa specifica
def manageSwitchesForMap(map_id)
  puts "[DEBUG] Entrato in manageSwitchesForMap con map_id=#{map_id}"

  # Ottieni tutte le switch personalizzate per la mappa specifica
  custom_switches = $self_switch_manager.get_switches_for_map(map_id)
  puts "[DEBUG] Switch personalizzate trovate: #{custom_switches.inspect}"

  # Controlla se ci sono switch personalizzate
  if custom_switches.empty?
    pbMessage(_INTL("Nessuna switch personalizzata trovata per la mappa con ID #{map_id}."))
    puts "[DEBUG] Nessuna switch personalizzata trovata per la mappa #{map_id}"
    return
  end

  # Prepara la lista dei comandi
  commands = custom_switches.keys.map { |switch_name| "Switch: #{switch_name}" }
  commands << "Aggiungi nuova switch"
  commands << "Esci"
  puts "[DEBUG] Comandi del menu delle switch creati: #{commands.inspect}"

  # Configura la finestra dei comandi
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  cmdwindow = Window_CommandPokemonEx.new(commands)
  cmdwindow.x = 0
  cmdwindow.y = 0
  cmdwindow.width = Graphics.width
  cmdwindow.height = Graphics.height
  cmdwindow.viewport = viewport

  # Loop principale per gestire l'interazione con l'utente
  loop do
    Graphics.update
    Input.update
    cmdwindow.update

    if Input.trigger?(Input::USE)
      selected_index = cmdwindow.index
      puts "[DEBUG] Opzione selezionata: Indice=#{selected_index}"
      
      if selected_index == commands.length - 1 # Se è selezionato "Esci"
        puts "[DEBUG] Selezionata l'opzione Esci"
        break
      elsif selected_index == commands.length - 2 # Se è selezionato "Aggiungi nuova switch"
        puts "[DEBUG] Selezionata l'opzione Aggiungi nuova switch"
        pbCreateCustomSwitch(map_id)
      else
        # Ottiene il nome della switch selezionata
        selected_switch_name = custom_switches.keys[selected_index]
        puts "[DEBUG] Switch selezionata: #{selected_switch_name}"
        
        # Ottieni gli eventi che usano questa switch
        event_ids = custom_switches[selected_switch_name]
        
        # MIGLIORAMENTO: Verifica che event_ids non sia nil e sia un array
        if event_ids && event_ids.is_a?(Array) && !event_ids.empty?
          puts "[DEBUG] Eventi trovati per la switch: #{event_ids.inspect}"
          
          # Mostra le opzioni disponibili per questa switch
          manageCustomSwitch(map_id, selected_switch_name, event_ids)
        else
          # Se non ci sono eventi collegati, mostra un messaggio
          puts "[DEBUG] Nessun evento trovato per la switch '#{selected_switch_name}'"
          pbMessage(_INTL("Nessun evento trovato per la switch '#{selected_switch_name}'."))
          
          # MIGLIORAMENTO: Inizializza l'array se è nil
          if custom_switches[selected_switch_name].nil?
            custom_switches[selected_switch_name] = []
            puts "[DEBUG] Inizializzato array vuoto per la switch"
          end
        end
      end
    elsif Input.trigger?(Input::BACK)
      puts "[DEBUG] Tornando al menu precedente"
      break
    end
  end

  # Pulizia delle risorse
  cmdwindow.dispose
  viewport.dispose
end

# Metodo per filtrare gli eventi con switch personalizzate
def filter_events_with_switches(map_id)
  puts "[DEBUG] Filtraggio eventi per la mappa #{map_id}"

  # Ottieni tutte le switch personalizzate per la mappa
  custom_switches = $self_switch_manager.get_switches_for_map(map_id)
  if custom_switches.empty?
    puts "[DEBUG] Non ci sono switch personalizzate per la mappa #{map_id}."
    return []
  end

  # Itera attraverso gli eventi della mappa
  filtered_events = []
  
  # MIGLIORAMENTO: Verifica che $game_map.events non sia nil
  if $game_map && $game_map.events
    $game_map.events.each do |event_id, event|
      next unless event # MIGLIORAMENTO: Salta eventi nil
      
      custom_switches.each do |switch_name, event_ids|
        # MIGLIORAMENTO: Verifica che event_ids sia un array
        next unless event_ids && event_ids.is_a?(Array)
        
        if event_ids.include?(event_id) # Controlla se l'evento ha una switch personalizzata
          # Ottieni lo stato della switch
          switch_status = $game_self_switches[[$game_map.map_id, event_id, switch_name]] ? "Attiva" : "Disattiva"

          # Aggiungi alla lista degli eventi filtrati
          filtered_events << {
            evento_id: event_id,
            nome_evento: event.name,
            nome_switch: switch_name,
            stato_switch: switch_status
          }
        end
      end
    end
  else
    puts "[DEBUG] $game_map o $game_map.events è nil"
  end

  # Debug degli eventi filtrati (italiano per console)
  filtered_events.each do |evento|
    puts "[DEBUG] Evento ID: #{evento[:evento_id]}, Nome: #{evento[:nome_evento]}, Switch: #{evento[:nome_switch]}, Stato: #{evento[:stato_switch]}"
  end

  filtered_events
end

#===========================================================================
# SelfSwitchManager - Gestore per le Switch Personalizzate
#===========================================================================
class SelfSwitchManager
  def initialize
    # Hash per memorizzare switch personalizzate:
    # { map_id => { "switch_name" => [event_id1, event_id2, ...] } }
    @switches = {}
  end

  # Scansiona tutte le switch personalizzate nel gioco
  def scan_all_custom_switches
    puts "[DEBUG] Iniziando la scansione di tutte le switch personalizzate..."
    
    # Resetta le informazioni sulle switch
    @switches = {}
    
    # In Essentials v20.1, $game_self_switches non è un Hash standard
    # Non possiamo usare each_key, quindi andiamo direttamente alla scansione delle mappe
    
    # Cerca nei dati delle mappe
    scan_map_data
    
    puts "[DEBUG] Scansione completata. Trovate switch in #{@switches.size} mappe."
  end
  
  # Scansiona i dati delle mappe per trovare switch personalizzate
  def scan_map_data
    # MIGLIORAMENTO: Gestione degli errori durante il caricamento
    begin
      # Carica le informazioni sulle mappe
      mapinfos = load_data("Data/MapInfos.rxdata") rescue nil
      
      # MIGLIORAMENTO: Verifica che mapinfos non sia nil
      if mapinfos.nil?
        puts "[ERROR] Impossibile caricare le informazioni delle mappe durante la scansione."
        pbMessage(_INTL("Impossibile caricare le informazioni delle mappe durante la scansione."))
        return
      end
      
      # Per ogni mappa
      mapinfos.each_key do |map_id|
        # Carica i dati della mappa in modo sicuro
        begin
          map_data = load_data(sprintf("Data/Map%03d.rxdata", map_id)) rescue nil
          
          # MIGLIORAMENTO: Verifica che map_data e map_data.events non siano nil
          next unless map_data && map_data.events
          
          puts "[DEBUG] Scansione della mappa #{map_id}..."
          
          # Per ogni evento nella mappa
          map_data.events.each do |event_id, event|
            next unless event && event.pages
            
            # Per ogni pagina dell'evento
            event.pages.each_with_index do |page, page_index|
              next unless page && page.list
              
              # Cerca commenti con switch personalizzate
              page.list.each do |command|
                next unless command && command.code && (command.code == 108 || command.code == 408) # Solo commenti
                next unless command.parameters && command.parameters[0].is_a?(String)
                
                # Cerca il pattern "Switch: nome: on/off"
                if command.parameters[0] =~ /Switch:\s*(\w+):\s*(on|off)/i
                  switch_name = $1
                  # Skip delle switch standard
                  next if ["A", "B", "C", "D"].include?(switch_name)
                  
                  puts "[DEBUG] Trovata switch nei dati mappa: Mappa=#{map_id}, Evento=#{event_id}, Nome=#{switch_name}, Pagina=#{page_index + 1}"
                  
                  # Aggiungi la switch al gestore
                  add_switch(map_id, switch_name, event_id)
                end
              end
            end
          end
        rescue => e
          puts "[ERROR] Errore durante la scansione della mappa #{map_id}: #{e.message}"
        end
      end
    rescue => e
      # MIGLIORAMENTO: Gestione completa degli errori
      puts "[ERROR] Errore generale durante la scansione delle mappe: #{e.message}"
      puts e.backtrace.join("\n") if $DEBUG
    end
  end

  # @param map_id [Integer] L'ID della mappa in cui si trova la switch
  # @param switch_name [String] Il nome della switch personalizzata
  # @param event_id [Integer] L'ID dell'evento collegato alla switch
  def add_switch(map_id, switch_name, event_id)
    @switches[map_id] ||= {}                           # Inizializza la mappa, se necessario
    @switches[map_id][switch_name] ||= []              # Inizializza la switch, se necessario
    @switches[map_id][switch_name] << event_id unless @switches[map_id][switch_name].include?(event_id)
  end

  # @param map_id [Integer] L'ID della mappa
  # @return [Hash] Hash delle switch associate alla mappa
  def get_switches_for_map(map_id)
    @switches[map_id] || {}                            # Restituisce l'hash o uno vuoto
  end

  # Metodo per recuperare tutte le Self Switch in tutte le mappe
  def get_all_switches
    @switches
  end

  # @param map_id [Integer] L'ID della mappa
  # @param switch_name [String] Il nome della switch da rimuovere
  def remove_switch(map_id, switch_name)
    return unless @switches[map_id]                   # Verifica che la mappa esista
    @switches[map_id].delete(switch_name)             # Rimuove la switch dalla mappa
    @switches.delete(map_id) if @switches[map_id].empty? # Elimina la mappa se vuota
  end

  # @param map_id [Integer] L'ID della mappa
  # @param switch_name [String] Il nome della switch da modificare
  # @param new_event_ids [Array<Integer>] Nuova lista di eventi collegati
  def modify_switch(map_id, switch_name, new_event_ids)
    return unless @switches[map_id] && @switches[map_id][switch_name] # Verifica esistenza
    @switches[map_id][switch_name] = new_event_ids  # Aggiorna la lista degli eventi
  end
end

def pbModifyCustomSwitch
  pbMessage(_INTL("Modifica di una switch personalizzata..."))
end

def pbCreateCustomSwitch
  pbMessage(_INTL("Creazione di una nuova switch personalizzata..."))
end

def pbRenameCustomSwitch
  pbMessage(_INTL("Rinominare una switch personalizzata..."))
end

def pbRemoveCustomSwitch
  pbMessage(_INTL("Rimuovere una switch personalizzata..."))
end

# MIGLIORAMENTO: Funzioni necessarie per evitare errori in altri metodi
def pbShowAllCustomSwitchesInMap
  if !$game_map
    pbMessage(_INTL("Nessuna mappa attiva."))
    return
  end
  
  map_id = $game_map.map_id
  custom_switches = $self_switch_manager.get_switches_for_map(map_id)
  
  if custom_switches.empty?
    pbMessage(_INTL("Nessuna switch personalizzata trovata per la mappa corrente (ID: {1}).", map_id))
    return
  end
  
  message = _INTL("Switch personalizzate nella mappa {1}:\n", map_id)
  custom_switches.each do |switch_name, event_ids|
    message += _INTL("- {1}: {2} evento/i\n", switch_name, event_ids.size)
  end
  
  pbMessage(message)
end

def pbSearchCustomSwitches
  # Richiedi il nome della switch da cercare
  switch_name = pbMessageFreeText(_INTL("Inserisci il nome della switch da cercare:"), "", false, 20)
  
  if switch_name.nil? || switch_name.empty?
    pbMessage(_INTL("Ricerca annullata."))
    return
  end
  
  # Cerca la switch in tutte le mappe
  all_switches = $self_switch_manager.get_all_switches
  found = false
  message = _INTL("Risultati della ricerca per '{1}':\n", switch_name)
  
  all_switches.each do |map_id, switches|
    switches.each do |sw_name, event_ids|
      if sw_name.downcase.include?(switch_name.downcase)
        found = true
        message += _INTL("Mappa {1}: '{2}' ({3} evento/i)\n", map_id, sw_name, event_ids.size)
      end
    end
  end
  
  if found
    pbMessage(message)
  else
    pbMessage(_INTL("Nessuna switch trovata con il nome '{1}'.", switch_name))
  end
end

def manageCustomSwitch(map_id, switch_name, event_ids)
  commands = [
    _INTL("Visualizza eventi collegati"),
    _INTL("Attiva switch"),
    _INTL("Disattiva switch"),
    _INTL("Rinomina switch"),
    _INTL("Elimina switch"),
    _INTL("Esci")
  ]
  
  cmdwindow = Window_CommandPokemonEx.new(commands)
  cmdwindow.viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  cmdwindow.viewport.z = 99999
  
  loop do
    Graphics.update
    Input.update
    cmdwindow.update
    
    if Input.trigger?(Input::USE)
      case cmdwindow.index
      when 0 # Visualizza eventi collegati
        show_events_info(map_id, switch_name, event_ids)
      when 1 # Attiva switch
        toggle_custom_switches(map_id, switch_name, event_ids, true)
      when 2 # Disattiva switch
        toggle_custom_switches(map_id, switch_name, event_ids, false)
      when 3 # Rinomina switch
        pbRenameCustomSwitch
        break
      when 4 # Elimina switch
        if pbConfirmMessage(_INTL("Sei sicuro di voler eliminare la switch '{1}'?", switch_name))
          $self_switch_manager.remove_switch(map_id, switch_name)
          pbMessage(_INTL("La switch '{1}' è stata eliminata.", switch_name))
          break
        end
      when 5 # Esci
        break
      end
    elsif Input.trigger?(Input::BACK)
      break
    end
  end
  
  cmdwindow.dispose
end

def show_events_info(map_id, switch_name, event_ids)
  message = _INTL("Eventi collegati alla switch '{1}' nella mappa {2}:\n", switch_name, map_id)
  
  # Carica i dati della mappa per ottenere i nomi degli eventi
  begin
    map_data = load_data(sprintf("Data/Map%03d.rxdata", map_id)) rescue nil
    
    if map_data && map_data.events
      event_ids.each do |event_id|
        event = map_data.events[event_id]
        event_name = event ? event.name : "Sconosciuto"
        
        # Ottieni lo stato attuale della switch per questo evento
        switch_key = [map_id, event_id, switch_name]
        state = $game_self_switches[switch_key] ? "ON" : "OFF"
        
        message += _INTL("- ID {1}: {2} ({3})\n", event_id, event_name, state)
      end
    else
      message += _INTL("Impossibile caricare i dati degli eventi.")
    end
  rescue => e
    message += _INTL("Errore durante il caricamento dei dati: {1}", e.message)
  end
  
  pbMessage(message)
end

def toggle_custom_switches(map_id, switch_name, event_ids, state)
  count = 0
  
  event_ids.each do |event_id|
    switch_key = [map_id, event_id, switch_name]
    $game_self_switches[switch_key] = state
    count += 1
  end
  
  # Aggiorna la mappa
  $game_map.need_refresh = true
  
  pbMessage(_INTL("{1} switch impostate su {2}.", count, state ? "ON" : "OFF"))
end