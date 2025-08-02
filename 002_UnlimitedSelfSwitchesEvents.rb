#===========================================================================
# Gestione Eventi per Switch Personalizzate
#===========================================================================
# Questo file contiene le funzioni per la gestione degli eventi collegati 
# alle switch personalizzate, come modifica, creazione, rinomina, ecc.
#===========================================================================

# Funzioni per modificare una switch personalizzata
def pbModifyCustomSwitch(map_id, switch_name, event_ids)
  puts "[DEBUG] Modifica switch personalizzata '#{switch_name}' nella mappa #{map_id}"
  
  # Se non ci sono eventi collegati
  if !event_ids || event_ids.empty?
    pbMessage(_INTL("Nessun evento collegato a questa switch."))
    return
  end
  
  # Crea i comandi del menu
  commands = []
  event_ids.each do |event_id|
    event_name = "Evento #{event_id}"
    if $game_map && $game_map.map_id == map_id && $game_map.events[event_id]
      event_name = $game_map.events[event_id].name || event_name
    end
    commands.push("#{event_id}: #{event_name}")
  end
  commands.push("Aggiungi nuovo evento")
  commands.push("Esci")
  
  # Mostra il menu per scegliere l'evento da modificare
  command = pbShowCommands(nil, commands, -1)
  
  # Se l'utente annulla o sceglie Esci
  return if command < 0 || command >= commands.length - 1
  
  # Se l'utente sceglie "Aggiungi nuovo evento"
  if command == commands.length - 2
    pbCreateCustomSwitchEvent(map_id, switch_name)
    return
  end
  
  # Altrimenti, modifica l'evento selezionato
  selected_event_id = event_ids[command]
  
  # Opzioni per la modifica dell'evento
  modify_commands = [
    "Cambia stato ON/OFF",
    "Rimuovi collegamento",
    "Esci"
  ]
  
  # Mostra il menu per la modifica dell'evento
  modify_command = pbShowCommands(nil, modify_commands, -1)
  
  # Gestisci l'opzione scelta
  case modify_command
  when 0 # Cambia stato
    key = [map_id, selected_event_id, switch_name]
    current_state = $game_self_switches[key] || false
    new_state = !current_state
    $game_self_switches[key] = new_state
    state_text = new_state ? "ON" : "OFF"
    pbMessage(_INTL("La switch '#{switch_name}' dell'evento #{selected_event_id} è stata impostata su #{state_text}."))
    $game_map.need_refresh = true
  when 1 # Rimuovi collegamento
    # Chiedi conferma
    unless pbConfirmMessage(_INTL("Sei sicuro di voler rimuovere il collegamento della switch '#{switch_name}' dall'evento #{selected_event_id}?"))
      pbMessage(_INTL("Operazione annullata."))
      return
    end
    
    # Rimuovi il collegamento
    event_ids_new = event_ids.dup
    event_ids_new.delete(selected_event_id)
    
    # Rimuovi i dati della switch
    $game_self_switches[[map_id, selected_event_id, switch_name]] = nil
    
    # Aggiorna il gestore delle switch
    if event_ids_new.empty?
      # Se era l'unico evento collegato, rimuovi la switch completamente
      $self_switch_manager.remove_switch(map_id, switch_name)
      pbMessage(_INTL("La switch '#{switch_name}' è stata completamente rimossa poiché non ha più eventi collegati."))
    else
      # Aggiorna la lista degli eventi collegati
      $self_switch_manager.modify_switch(map_id, switch_name, event_ids_new)
      pbMessage(_INTL("La switch '#{switch_name}' è stata scollegata dall'evento #{selected_event_id}."))
    end
    
    # Aggiorna la mappa
    $game_map.need_refresh = true
  end
end

# Funzione per creare una nuova switch personalizzata
def pbCreateCustomSwitch(map_id)
  puts "[DEBUG] Creazione di una nuova switch personalizzata nella mappa #{map_id}"
  
  # Chiedi il nome della nuova switch
  switch_name = pbMessageFreeText(_INTL("Inserisci il nome della nuova switch:"), "", false, 30)
  
  # Verifica che sia stato inserito un nome valido
  if switch_name == "" || switch_name.nil?
    pbMessage(_INTL("Nome non valido. Creazione annullata."))
    return
  end
  
  # Verifica che non sia un nome riservato
  if ["A", "B", "C", "D"].include?(switch_name)
    pbMessage(_INTL("Non puoi usare '#{switch_name}' come nome. È riservato per le switch standard."))
    return
  end
  
  # Verifica se la switch esiste già
  existing_switches = $self_switch_manager.get_switches_for_map(map_id)
  if existing_switches.has_key?(switch_name)
    pbMessage(_INTL("Esiste già una switch con questo nome in questa mappa."))
    return
  end
  
  # Crea la switch (inizialmente senza eventi collegati)
  $self_switch_manager.add_switch(map_id, switch_name, [])
  
  # Chiedi se collegare subito un evento
  if pbConfirmMessage(_INTL("Switch creata. Vuoi collegarla a un evento?"))
    pbCreateCustomSwitchEvent(map_id, switch_name)
  else
    pbMessage(_INTL("Switch '#{switch_name}' creata con successo. Nessun evento collegato."))
  end
end

# Funzione per creare un nuovo collegamento a un evento
def pbCreateCustomSwitchEvent(map_id, switch_name)
  puts "[DEBUG] Collegamento della switch '#{switch_name}' a un evento"
  
  # Verifica se siamo nella mappa giusta per aggiungere eventi
  current_map = $game_map ? $game_map.map_id : -1
  
  if current_map != map_id
    pbMessage(_INTL("Per collegare la switch a un evento, devi essere nella mappa #{map_id}."))
    return
  end
  
  # Ottieni gli eventi disponibili nella mappa corrente
  available_events = []
  event_names = {}
  
  $game_map.events.each do |event_id, event|
    # Skip degli eventi già collegati a questa switch
    next if $self_switch_manager.get_switches_for_map(map_id)[switch_name]&.include?(event_id)
    
    # Aggiungi l'evento alla lista
    available_events.push(event_id)
    event_name = event.name.empty? ? "Evento #{event_id}" : event.name
    event_names[event_id] = "#{event_id}: #{event_name}"
  end
  
  # Verifica se ci sono eventi disponibili
  if available_events.empty?
    pbMessage(_INTL("Non ci sono eventi disponibili da collegare a questa switch."))
    return
  end
  
  # Crea la lista dei comandi con i nomi degli eventi
  commands = available_events.map { |id| event_names[id] }
  commands.push("Esci")
  
  # Mostra il menu per scegliere l'evento
  command = pbShowCommands(nil, commands, -1)
  
  # Esci se l'utente annulla o sceglie Esci
  return if command < 0 || command >= commands.length - 1
  
  # Ottieni l'ID dell'evento selezionato
  selected_event_id = available_events[command]
  
  # Collega la switch all'evento
  $self_switch_manager.add_switch(map_id, switch_name, selected_event_id)
  
  # Imposta lo stato iniziale della switch (default: OFF)
  $game_self_switches[[map_id, selected_event_id, switch_name]] = false
  
  # Aggiorna la mappa
  $game_map.need_refresh = true
  
  # Notifica
  event_name = $game_map.events[selected_event_id].name
  event_name = event_name.empty? ? "Evento #{selected_event_id}" : event_name
  pbMessage(_INTL("La switch '#{switch_name}' è stata collegata all'evento \"#{event_name}\"."))
  
  # Chiedi se si vuole aggiungere un altro evento
  if pbConfirmMessage(_INTL("Vuoi collegare la switch a un altro evento?"))
    pbCreateCustomSwitchEvent(map_id, switch_name)
  end
end

# Funzione per rinominare una switch personalizzata
def pbRenameCustomSwitch(map_id, old_name, event_ids)
  puts "[DEBUG] Rinomina della switch '#{old_name}' nella mappa #{map_id}"
  
  # Chiedi il nuovo nome
  new_name = pbMessageFreeText(_INTL("Inserisci il nuovo nome per la switch:"), old_name, false, 30)
  
  # Verifica che sia stato inserito un nome valido
  if new_name == "" || new_name.nil?
    pbMessage(_INTL("Nome non valido. Rinomina annullata."))
    return
  end
  
  # Verifica che non sia un nome riservato
  if ["A", "B", "C", "D"].include?(new_name)
    pbMessage(_INTL("Non puoi usare '#{new_name}' come nome. È riservato per le switch standard."))
    return
  end
  
  # Verifica che il nuovo nome non esista già
  existing_switches = $self_switch_manager.get_switches_for_map(map_id)
  if existing_switches.has_key?(new_name) && new_name != old_name
    pbMessage(_INTL("Esiste già una switch con questo nome in questa mappa."))
    return
  end
  
  # Nessun cambiamento se il nome è lo stesso
  if new_name == old_name
    pbMessage(_INTL("Il nome è rimasto invariato."))
    return
  end
  
  # Aggiorna tutti i riferimenti alla switch
  event_ids.each do |event_id|
    key_old = [map_id, event_id, old_name]
    key_new = [map_id, event_id, new_name]
    
    # Trasferisci lo stato dalla vecchia alla nuova switch
    $game_self_switches[key_new] = $game_self_switches[key_old] || false
    $game_self_switches[key_old] = nil
  end
  
  # Aggiorna il gestore delle switch
  $self_switch_manager.remove_switch(map_id, old_name)
  event_ids.each do |event_id|
    $self_switch_manager.add_switch(map_id, new_name, event_id)
  end
  
  # Notifica
  pbMessage(_INTL("La switch '#{old_name}' è stata rinominata in '#{new_name}'."))
  
  # Aggiorna la mappa
  $game_map.need_refresh = true
end

# Funzione per eliminare una switch personalizzata
def pbRemoveCustomSwitch(map_id, switch_name, event_ids)
  puts "[DEBUG] Rimozione della switch '#{switch_name}' nella mappa #{map_id}"
  
  # Chiedi conferma
  unless pbConfirmMessage(_INTL("Sei sicuro di voler eliminare la switch '#{switch_name}'?"))
    pbMessage(_INTL("Eliminazione annullata."))
    return
  end
  
  # Rimuovi tutti i riferimenti alla switch
  event_ids.each do |event_id|
    key = [map_id, event_id, switch_name]
    $game_self_switches[key] = nil
  end
  
  # Rimuovi la switch dal gestore
  $self_switch_manager.remove_switch(map_id, switch_name)
  
  # Notifica
  pbMessage(_INTL("La switch '#{switch_name}' è stata eliminata."))
  
  # Aggiorna la mappa
  $game_map.need_refresh = true
end

# Metodo per gestire una specifica switch personalizzata
def manageCustomSwitch(map_id, switch_name, event_ids)
  puts "[DEBUG] Gestione della switch '#{switch_name}' nella mappa #{map_id}, eventi: #{event_ids.inspect}"

  # Crea i comandi del menu
  commands = [
    "Cambia stato (ON/OFF)",
    "Visualizza dettagli",
    "Modifica switch",
    "Gestisci condizioni speciali",
    "Rinomina switch",
    "Elimina switch",
    "Esci"
  ]

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
      case cmdwindow.index
      when 0 # Cambia stato
        toggleCustomSwitchState(map_id, switch_name, event_ids)
      when 1 # Visualizza dettagli
        showCustomSwitchDetails(map_id, switch_name, event_ids)
      when 2 # Modifica switch
        pbModifyCustomSwitch(map_id, switch_name, event_ids)
      when 3 # Gestisci condizioni speciali
        pbManageSpecialConditions(map_id, switch_name, event_ids)
      when 4 # Rinomina switch
        pbRenameCustomSwitch(map_id, switch_name, event_ids)
      when 5 # Elimina switch
        pbRemoveCustomSwitch(map_id, switch_name, event_ids)
        break # Esci dopo l'eliminazione
      when 6 # Esci
        break
      end
    elsif Input.trigger?(Input::BACK)
      break
    end
  end

  # Pulizia delle risorse
  cmdwindow.dispose
  viewport.dispose
end

# Metodo per cambiare lo stato di una switch personalizzata
def toggleCustomSwitchState(map_id, switch_name, event_ids)
  puts "[DEBUG] Cambio stato per switch '#{switch_name}'"
  
  # Per ogni evento collegato alla switch
  event_ids.each do |event_id|
    key = [map_id, event_id, switch_name]
    current_state = $game_self_switches[key] || false
    new_state = !current_state
    
    # Cambia lo stato della switch
    $game_self_switches[key] = new_state
    
    # Log del cambio di stato
    state_text = new_state ? "ATTIVATA" : "DISATTIVATA"
    puts "[DEBUG] Switch '#{switch_name}' dell'evento #{event_id} è stata #{state_text}"
  end
  
  # Aggiorna la mappa
  $game_map.need_refresh = true
  
  # Notifica all'utente
  if event_ids.length == 1
    state_text = $game_self_switches[[map_id, event_ids[0], switch_name]] ? "ON" : "OFF"
    pbMessage(_INTL("La switch '#{switch_name}' è stata impostata su #{state_text}."))
  else
    pbMessage(_INTL("Sono state modificate #{event_ids.length} switch con nome '#{switch_name}'."))
  end
end

# Metodo per mostrare i dettagli di una switch personalizzata
def showCustomSwitchDetails(map_id, switch_name, event_ids)
  puts "[DEBUG] Visualizzazione dettagli per switch '#{switch_name}'"
  
  # Prepara il messaggio con i dettagli
  message = "Switch: #{switch_name}\n"
  message += "Mappa: #{map_id}\n"
  message += "Eventi collegati:\n"
  
  # Per ogni evento collegato alla switch
  event_ids.each do |event_id|
    key = [map_id, event_id, switch_name]
    state = $game_self_switches[key] || false
    state_text = state ? "ON" : "OFF"
    
    # Trova il nome dell'evento se possibile
    event_name = "Evento #{event_id}"
    if $game_map && $game_map.map_id == map_id && $game_map.events[event_id]
      event_name = $game_map.events[event_id].name || event_name
    end
    
    message += "- #{event_name}: #{state_text}\n"
  end
  
  # Mostra i dettagli
  pbMessage(message)
  
  # Chiedi se visualizzare anche le condizioni speciali
  if pbConfirmMessage(_INTL("Vuoi visualizzare le condizioni speciali per questa switch?"))
    pbShowSpecialConditions(map_id, switch_name, event_ids)
  end
end

# Metodo per visualizzare tutte le switch personalizzate nella mappa corrente
def pbShowAllCustomSwitchesInMap
  current_map = $game_map ? $game_map.map_id : -1
  
  if current_map < 0
    pbMessage(_INTL("Nessuna mappa caricata."))
    return
  end
  
  # Ottieni tutte le switch personalizzate per la mappa corrente
  custom_switches = $self_switch_manager.get_switches_for_map(current_map)
  
  if custom_switches.empty?
    pbMessage(_INTL("Non ci sono switch personalizzate in questa mappa."))
    return
  end
  
  # Prepara la visualizzazione
  message = _INTL("Switch personalizzate nella mappa {1}:\n", current_map)
  
  # Raggruppa gli eventi per switch
  custom_switches.each do |switch_name, event_ids|
    # Conta gli eventi ON e OFF
    on_count = 0
    off_count = 0
    
    event_ids.each do |event_id|
      state = $game_self_switches[[current_map, event_id, switch_name]] || false
      state ? on_count += 1 : off_count += 1
    end
    
    # Aggiungi la switch al messaggio
    message += _INTL("- {1}: {2} eventi ({3} ON, {4} OFF)\n", 
                    switch_name, 
                    event_ids.size,
                    on_count,
                    off_count)
  end
  
  # Mostra il riepilogo
  pbMessage(message)
  
  # Chiedi se visualizzare i dettagli di una specifica switch
  if pbConfirmMessage(_INTL("Vuoi visualizzare i dettagli di una switch specifica?"))
    # Crea i comandi del menu
    commands = custom_switches.keys
    commands.push("Esci")
    
    # Mostra il menu per scegliere la switch
    command = pbShowCommands(nil, commands, -1)
    
    # Esci se l'utente annulla o sceglie Esci
    return if command < 0 || command >= commands.length - 1
    
    # Ottieni il nome della switch selezionata
    selected_switch = commands[command]
    
    # Mostra i dettagli della switch selezionata
    showCustomSwitchDetails(current_map, selected_switch, custom_switches[selected_switch])
  end
end

# Metodo per cercare switch personalizzate per nome
def pbSearchCustomSwitches
  # Chiedi il termine di ricerca
  search_term = pbMessageFreeText(_INTL("Inserisci il termine di ricerca:"), "", false, 30)
  
  # Verifica che sia stato inserito un termine valido
  if search_term == "" || search_term.nil?
    pbMessage(_INTL("Termine di ricerca non valido. Ricerca annullata."))
    return
  end
  
  # Converti il termine in minuscolo per una ricerca case-insensitive
  search_term = search_term.downcase
  
  # Prepara i risultati
  results = {}
  total_matches = 0
  
  # Ottieni tutte le switch personalizzate
  all_switches = $self_switch_manager.get_all_switches
  
  # Cerca nelle switch
  all_switches.each do |map_id, switches|
    map_matches = {}
    
    switches.each do |switch_name, event_ids|
      if switch_name.downcase.include?(search_term)
        map_matches[switch_name] = event_ids
        total_matches += 1
      end
    end
    
    # Aggiungi le corrispondenze trovate per questa mappa
    results[map_id] = map_matches if map_matches.any?
  end
  
  # Mostra i risultati
  if total_matches == 0
    pbMessage(_INTL("Nessuna switch trovata contenente '{1}'.", search_term))
    return
  end
  
  # Mostra il conteggio totale
  pbMessage(_INTL("Trovate {1} switch contenenti '{2}'.", total_matches, search_term))
  
  # Crea comandi per visualizzare i risultati per mappa
  commands = []
  map_ids = []
  
  results.each do |map_id, matches|
    # Ottieni il nome della mappa, se possibile
    map_name = ""
    mapinfos = load_data("Data/MapInfos.rxdata") rescue nil
    if mapinfos && mapinfos[map_id]
      map_name = mapinfos[map_id].name
    end
    
    # Aggiungi alla lista dei comandi
    map_text = map_name.empty? ? "Mappa #{map_id}" : "#{map_id}: #{map_name}"
    commands.push("#{map_text} (#{matches.size} switch)")
    map_ids.push(map_id)
  end
  
  commands.push("Esci")
  
  # Mostra il menu per scegliere la mappa
  loop do
    command = pbShowCommands(nil, commands, -1)
    
    # Esci se l'utente annulla o sceglie Esci
    break if command < 0 || command >= commands.length - 1
    
    # Visualizza le switch nella mappa selezionata
    selected_map_id = map_ids[command]
    showSearchResultsForMap(selected_map_id, results[selected_map_id], search_term)
  end
end

# Metodo ausiliario per mostrare i risultati di ricerca per una mappa
def showSearchResultsForMap(map_id, switches, search_term)
  # Crea i comandi del menu
  commands = switches.keys.map { |switch_name| "Switch: #{switch_name}" }
  commands.push("Esci")
  
  # Mostra il menu per scegliere la switch
  command = pbShowCommands(nil, commands, -1)
  
  # Esci se l'utente annulla o sceglie Esci
  return if command < 0 || command >= commands.length - 1
  
  # Ottieni il nome della switch selezionata
  selected_switch = switches.keys[command]
  
  # Mostra i dettagli della switch selezionata
  showCustomSwitchDetails(map_id, selected_switch, switches[selected_switch])
  
  # Chiedi se vuole gestire questa switch
  if pbConfirmMessage(_INTL("Vuoi gestire questa switch?"))
    manageCustomSwitch(map_id, selected_switch, switches[selected_switch])
  end
end

# Metodo per gestire condizioni speciali per una switch personalizzata
def pbManageSpecialConditions(map_id, switch_name, event_ids)
  puts "[DEBUG] Gestione condizioni speciali per la switch '#{switch_name}' nella mappa #{map_id}"
  
  # Lista dei tipi di condizioni disponibili
  condition_types = [
    "Attivazione automatica (timer)",
    "Attivazione basata su variabile",
    "Attivazione basata su switch di gioco",
    "Attivazione basata su item nell'inventario",
    "Rimuovi condizioni speciali",
    "Esci"
  ]
  
  # Mostra il menu per la selezione del tipo di condizione
  command = pbShowCommands(nil, condition_types, -1)
  
  # Esci se l'utente annulla o sceglie Esci
  return if command < 0 || command >= condition_types.length - 1
  
  case command
  when 0 # Timer
    pbSetTimerCondition(map_id, switch_name, event_ids)
  when 1 # Variabile
    pbSetVariableCondition(map_id, switch_name, event_ids)
  when 2 # Switch di gioco
    pbSetGameSwitchCondition(map_id, switch_name, event_ids)
  when 3 # Item nell'inventario
    pbSetInventoryCondition(map_id, switch_name, event_ids)
  when 4 # Rimuovi condizioni
    pbRemoveSpecialConditions(map_id, switch_name, event_ids)
  end
end

# Metodo per impostare una condizione timer
def pbSetTimerCondition(map_id, switch_name, event_ids)
  # Chiedi il tempo in secondi
  time_text = pbMessageFreeText(_INTL("Inserisci il tempo in secondi:"), "", false, 10, "^[0-9]+$")
  return if time_text.empty?
  
  time_seconds = time_text.to_i
  if time_seconds <= 0
    pbMessage(_INTL("Tempo non valido. Deve essere un numero positivo."))
    return
  end
  
  # Chiedi se attivare o disattivare la switch
  action = pbShowCommands(nil, ["Attiva la switch", "Disattiva la switch", "Annulla"], -1)
  return if action < 0 || action > 1
  
  # Salva la condizione nel gioco (sarà necessario implementare un gestore per questo)
  new_state = (action == 0) # true per attivazione, false per disattivazione
  
  # Per ogni evento collegato alla switch
  event_ids.each do |event_id|
    # Crea un chiave univoca per la condizione
    condition_key = "timer:#{map_id}:#{event_id}:#{switch_name}"
    
    # Salva la condizione nelle variabili globali (temporaneo)
    # In una implementazione completa, queste dovrebbero essere memorizzate in un oggetto persistente
    $game_variables[999] ||= {}
    $game_variables[999][condition_key] = {
      type: "timer",
      seconds: time_seconds,
      new_state: new_state,
      start_time: Time.now.to_i
    }
    
    # Notifica
    state_text = new_state ? "attivata" : "disattivata"
    puts "[DEBUG] Condizione timer impostata: La switch '#{switch_name}' sarà #{state_text} dopo #{time_seconds} secondi"
  end
  
  pbMessage(_INTL("La condizione timer è stata impostata. La switch sarà {1} dopo {2} secondi.", 
              new_state ? "attivata" : "disattivata", time_seconds))
end

# Metodo per impostare una condizione basata su variabile
def pbSetVariableCondition(map_id, switch_name, event_ids)
  # Chiedi l'ID della variabile
  var_id_text = pbMessageFreeText(_INTL("Inserisci l'ID della variabile:"), "", false, 5, "^[0-9]+$")
  return if var_id_text.empty?
  
  var_id = var_id_text.to_i
  if var_id <= 0
    pbMessage(_INTL("ID variabile non valido. Deve essere un numero positivo."))
    return
  end
  
  # Chiedi il valore di confronto
  value_text = pbMessageFreeText(_INTL("Inserisci il valore di confronto:"), "", false, 10)
  return if value_text.empty?
  
  value = value_text.to_i
  
  # Chiedi il tipo di confronto
  comparison_types = ["Uguale a (=)", "Maggiore di (>)", "Minore di (<)", "Maggiore o uguale (>=)", "Minore o uguale (<=)", "Diverso da (!=)"]
  comparison_type = pbShowCommands(nil, comparison_types, -1)
  return if comparison_type < 0
  
  # Chiedi se attivare o disattivare la switch
  action = pbShowCommands(nil, ["Attiva la switch", "Disattiva la switch", "Annulla"], -1)
  return if action < 0 || action > 1
  
  # Salva la condizione
  new_state = (action == 0)
  
  # Per ogni evento collegato alla switch
  event_ids.each do |event_id|
    # Crea una chiave univoca per la condizione
    condition_key = "variable:#{map_id}:#{event_id}:#{switch_name}"
    
    # Salva la condizione nelle variabili globali (temporaneo)
    $game_variables[999] ||= {}
    $game_variables[999][condition_key] = {
      type: "variable",
      var_id: var_id,
      value: value,
      comparison_type: comparison_type,
      new_state: new_state
    }
    
    # Notifica
    puts "[DEBUG] Condizione variabile impostata per la switch '#{switch_name}'"
  end
  
  # Messaggio di conferma
  comparison_symbol = ["=", ">", "<", ">=", "<=", "!="][comparison_type]
  pbMessage(_INTL("La condizione variabile è stata impostata. La switch sarà {1} quando la variabile {2} {3} {4}.", 
              new_state ? "attivata" : "disattivata", var_id, comparison_symbol, value))
end

# Metodo per impostare una condizione basata su switch di gioco
def pbSetGameSwitchCondition(map_id, switch_name, event_ids)
  # Chiedi l'ID della switch di gioco
  switch_id_text = pbMessageFreeText(_INTL("Inserisci l'ID della switch di gioco:"), "", false, 5, "^[0-9]+$")
  return if switch_id_text.empty?
  
  switch_id = switch_id_text.to_i
  if switch_id <= 0
    pbMessage(_INTL("ID switch non valido. Deve essere un numero positivo."))
    return
  end
  
  # Chiedi quando attivare la condizione
  trigger_on = pbShowCommands(nil, ["Quando la switch di gioco è ON", "Quando la switch di gioco è OFF", "Annulla"], -1)
  return if trigger_on < 0 || trigger_on > 1
  
  # Chiedi cosa fare con la switch personalizzata
  action = pbShowCommands(nil, ["Attiva la switch personalizzata", "Disattiva la switch personalizzata", "Annulla"], -1)
  return if action < 0 || action > 1
  
  # Salva la condizione
  trigger_state = (trigger_on == 0) # true se la condizione è attivata quando la switch di gioco è ON
  new_state = (action == 0) # true per attivazione, false per disattivazione
  
  # Per ogni evento collegato alla switch
  event_ids.each do |event_id|
    # Crea una chiave univoca per la condizione
    condition_key = "gameswitch:#{map_id}:#{event_id}:#{switch_name}"
    
    # Salva la condizione nelle variabili globali (temporaneo)
    $game_variables[999] ||= {}
    $game_variables[999][condition_key] = {
      type: "gameswitch",
      switch_id: switch_id,
      trigger_state: trigger_state,
      new_state: new_state
    }
    
    # Notifica
    puts "[DEBUG] Condizione switch di gioco impostata per la switch personalizzata '#{switch_name}'"
  end
  
  # Messaggio di conferma
  trigger_text = trigger_state ? "ON" : "OFF"
  action_text = new_state ? "attivata" : "disattivata"
  pbMessage(_INTL("La condizione è stata impostata. La switch personalizzata sarà {1} quando la switch di gioco {2} è {3}.", 
              action_text, switch_id, trigger_text))
end

# Metodo per impostare una condizione basata su item nell'inventario
def pbSetInventoryCondition(map_id, switch_name, event_ids)
  # Genera la lista degli item disponibili (esempio semplificato)
  items = []
  for i in 1..PBItems.maxValue
    next if !PBItems.getName(i) || PBItems.getName(i).empty?
    items.push([i, PBItems.getName(i)])
  end
  
  if items.empty?
    pbMessage(_INTL("Nessun item disponibile."))
    return
  end
  
  # Crea un menu con i nomi degli item
  commands = items.map { |item| item[1] }
  commands.push("Annulla")
  
  # Mostra il menu per selezionare l'item
  item_index = pbShowCommands(nil, commands, -1)
  return if item_index < 0 || item_index >= items.length
  
  selected_item_id = items[item_index][0]
  selected_item_name = items[item_index][1]
  
  # Chiedi la quantità di item richiesta
  quantity_text = pbMessageFreeText(_INTL("Inserisci la quantità richiesta:"), "1", false, 5, "^[0-9]+$")
  return if quantity_text.empty?
  
  quantity = quantity_text.to_i
  if quantity <= 0
    pbMessage(_INTL("Quantità non valida. Deve essere un numero positivo."))
    return
  end
  
  # Chiedi quando attivare la condizione
  comparison_types = ["Almeno (>=)", "Esattamente (=)", "Al massimo (<=)"]
  comparison_type = pbShowCommands(nil, comparison_types, -1)
  return if comparison_type < 0
  
  # Chiedi cosa fare con la switch personalizzata
  action = pbShowCommands(nil, ["Attiva la switch personalizzata", "Disattiva la switch personalizzata", "Annulla"], -1)
  return if action < 0 || action > 1
  
  # Salva la condizione
  new_state = (action == 0)
  
  # Per ogni evento collegato alla switch
  event_ids.each do |event_id|
    # Crea una chiave univoca per la condizione
    condition_key = "inventory:#{map_id}:#{event_id}:#{switch_name}"
    
    # Salva la condizione nelle variabili globali (temporaneo)
    $game_variables[999] ||= {}
    $game_variables[999][condition_key] = {
      type: "inventory",
      item_id: selected_item_id,
      quantity: quantity,
      comparison_type: comparison_type,
      new_state: new_state
    }
    
    # Notifica
    puts "[DEBUG] Condizione inventario impostata per la switch personalizzata '#{switch_name}'"
  end
  
  # Messaggio di conferma
  comparison_symbol = [">=", "=", "<="][comparison_type]
  pbMessage(_INTL("La condizione è stata impostata. La switch personalizzata sarà {1} quando la quantità di {2} nell'inventario è {3} {4}.", 
              new_state ? "attivata" : "disattivata", selected_item_name, comparison_symbol, quantity))
end

# Metodo per rimuovere le condizioni speciali
def pbRemoveSpecialConditions(map_id, switch_name, event_ids)
  # Per ogni evento collegato alla switch
  removed = 0
  
  event_ids.each do |event_id|
    # Cerca tutte le condizioni per questa switch
    $game_variables[999] ||= {}
    conditions = []
    
    # Cerca le chiavi che contengono questa combinazione mappa-evento-switch
    $game_variables[999].each_key do |key|
      if key.include?("#{map_id}:#{event_id}:#{switch_name}")
        conditions << key
      end
    end
    
    # Se non ci sono condizioni
    if conditions.empty?
      next
    end
    
    # Rimuovi tutte le condizioni
    conditions.each do |key|
      $game_variables[999].delete(key)
      removed += 1
    end
  end
  
  # Notifica
  if removed > 0
    pbMessage(_INTL("Sono state rimosse {1} condizioni speciali.", removed))
  else
    pbMessage(_INTL("Non ci sono condizioni speciali da rimuovere."))
  end
end

# Metodo per visualizzare le condizioni speciali attive per una switch
def pbShowSpecialConditions(map_id, switch_name, event_ids)
  # Inizializza il conteggio
  total_conditions = 0
  condition_details = []
  
  # Cerca le condizioni per questa switch
  event_ids.each do |event_id|
    # Cerca tutte le chiavi che contengono questa combinazione mappa-evento-switch
    $game_variables[999] ||= {}
    
    $game_variables[999].each do |key, condition|
      next unless key.include?("#{map_id}:#{event_id}:#{switch_name}")
      next unless condition.is_a?(Hash)
      
      # Incrementa il contatore
      total_conditions += 1
      
      # Ottieni i dettagli in base al tipo di condizione
      case condition[:type]
      when "timer"
        # Calcola il tempo rimanente
        elapsed = Time.now.to_i - condition[:start_time]
        remaining = [condition[:seconds] - elapsed, 0].max
        
        # Formatta l'informazione
        state = condition[:new_state] ? "attivata" : "disattivata"
        condition_details << "Timer: La switch sarà #{state} tra #{remaining} secondi"
      
      when "variable"
        # Ottieni il valore attuale
        current = $game_variables[condition[:var_id]] || 0
        
        # Converti il tipo di confronto in simbolo
        comparison_symbol = ["=", ">", "<", ">=", "<=", "!="][condition[:comparison_type]]
        
        # Formatta l'informazione
        state = condition[:new_state] ? "attivata" : "disattivata"
        condition_details << "Variabile: La switch sarà #{state} quando var #{condition[:var_id]} #{comparison_symbol} #{condition[:value]}" +
                            " (attuale: #{current})"
      
      when "gameswitch"
        # Ottieni lo stato attuale
        current = $game_switches[condition[:switch_id]] ? "ON" : "OFF"
        expected = condition[:trigger_state] ? "ON" : "OFF"
        
        # Formatta l'informazione
        state = condition[:new_state] ? "attivata" : "disattivata"
        condition_details << "Switch: La switch sarà #{state} quando switch #{condition[:switch_id]} = #{expected}" +
                            " (attuale: #{current})"
      
      when "inventory"
        # Ottieni la quantità attuale
        current = $PokemonBag.pbQuantity(condition[:item_id]) || 0
        
        # Converti il tipo di confronto in simbolo
        comparison_symbol = [">=", "=", "<="][condition[:comparison_type]]
        
        # Ottieni il nome dell'item
        item_name = PBItems.getName(condition[:item_id])
        
        # Formatta l'informazione
        state = condition[:new_state] ? "attivata" : "disattivata"
        condition_details << "Inventario: La switch sarà #{state} quando #{item_name} #{comparison_symbol} #{condition[:quantity]}" +
                            " (attuale: #{current})"
      end
    end
  end
  
  # Mostra i risultati
  if total_conditions == 0
    pbMessage(_INTL("Non ci sono condizioni speciali attive per questa switch."))
    return
  end
  
  # Mostra ogni condizione
  pbMessage(_INTL("Ci sono {1} condizioni speciali attive:", total_conditions))
  
  condition_details.each do |detail|
    pbMessage(detail)
  end
end 