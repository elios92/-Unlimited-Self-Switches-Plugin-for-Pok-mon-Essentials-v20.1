#===============================================================================
# VS Seeker Interface - Pokémon Essentials v20.1
#===============================================================================
# Interfacce utente e menu per il VS Seeker
# Include item utilizzabile e menu di gestione
#===============================================================================

#===============================================================================
# Menu Principale VS Seeker
#===============================================================================

# Mostra l'interfaccia principale del VS Seeker
def pbVSSeekerMenu
  return unless $vs_seeker
  
  stats = $vs_seeker.get_stats
  
  # Se non ci sono allenatori sconfitti
  if stats[:total_defeated] == 0
    pbMessage(_INTL("Non hai ancora sconfitto nessun allenatore."))
    return
  end
  
  # Menu principale
  commands = [
    "Allenatori disponibili (#{stats[:available_now]})",
    "Tutti gli allenatori sconfitti (#{stats[:total_defeated]})",
    "Statistiche VS Seeker",
    "Esci"
  ]
  
  command = pbShowCommands(nil, commands, -1)
  
  case command
  when 0 # Allenatori disponibili
    pbShowAvailableTrainers
  when 1 # Tutti gli allenatori
    pbShowAllDefeatedTrainers
  when 2 # Statistiche
    pbShowVSSeekerStats
  end
end

#===============================================================================
# Visualizzazione Allenatori
#===============================================================================

# Mostra gli allenatori disponibili per la rivincita
def pbShowAvailableTrainers
  available_trainers = $vs_seeker.get_available_trainers
  
  if available_trainers.empty?
    pbMessage(_INTL("Nessun allenatore è attualmente disponibile per una rivincita."))
    pbMessage(_INTL("Cammina ancora un po' per riattivare gli allenatori sconfitti!"))
    return
  end
  
  # Crea i comandi per gli allenatori disponibili
  commands = available_trainers.map do |trainer|
    map_name = get_map_name(trainer[:map_id])
    "#{trainer[:name]} (#{map_name})"
  end
  commands.push("Esci")
  
  # Mostra il menu di selezione
  command = pbShowCommands(nil, commands, -1)
  
  # Se l'utente ha selezionato un allenatore
  if command >= 0 && command < available_trainers.size
    selected_trainer = available_trainers[command]
    pbShowTrainerDetails(selected_trainer)
  end
end

# Mostra tutti gli allenatori sconfitti
def pbShowAllDefeatedTrainers
  all_trainers = $vs_seeker.get_all_defeated_trainers
  
  if all_trainers.empty?
    pbMessage(_INTL("Non hai ancora sconfitto nessun allenatore."))
    return
  end
  
  # Raggruppa per disponibilità
  available = all_trainers.select { |t| t[:available] }
  unavailable = all_trainers.select { |t| !t[:available] }
  
  message = _INTL("Allenatori sconfitti:\n\n")
  
  if available.any?
    message += _INTL("DISPONIBILI PER RIVINCITA:\n")
    available.each do |trainer|
      map_name = get_map_name(trainer[:map_id])
      message += _INTL("• {1} ({2})\n", trainer[:name], map_name)
    end
    message += "\n"
  end
  
  if unavailable.any?
    message += _INTL("NON ANCORA DISPONIBILI:\n")
    unavailable.each do |trainer|
      map_name = get_map_name(trainer[:map_id])
      remaining = trainer[:steps_remaining]
      message += _INTL("• {1} ({2}) - {3} passi rimanenti\n", 
                      trainer[:name], map_name, remaining)
    end
  end
  
  pbMessage(message)
end

# Mostra le statistiche del VS Seeker
def pbShowVSSeekerStats
  stats = $vs_seeker.get_stats
  
  message = _INTL("Statistiche VS Seeker:\n\n")
  message += _INTL("Passi dal ultimo controllo: {1}/100\n", stats[:step_counter])
  message += _INTL("Allenatori sconfitti totali: {1}\n", stats[:total_defeated])
  message += _INTL("Allenatori disponibili ora: {1}\n", stats[:available_now])
  message += _INTL("Mappe con allenatori: {1}\n", stats[:maps_with_trainers])
  
  pbMessage(message)
end

# Mostra i dettagli di un allenatore specifico
def pbShowTrainerDetails(trainer)
  map_name = get_map_name(trainer[:map_id])
  
  message = _INTL("Allenatore: {1}\n", trainer[:name])
  message += _INTL("Posizione: {1}\n", map_name)
  message += _INTL("Passi dalla sconfitta: {1}\n", trainer[:steps_since_defeat])
  message += _INTL("\nVuoi andare a sfidare questo allenatore?")
  
  if pbConfirmMessage(message)
    pbGoToTrainer(trainer[:map_id], trainer[:event_id])
  end
end

#===============================================================================
# Navigazione e Teletrasporto
#===============================================================================

# Porta il giocatore da un allenatore specifico
def pbGoToTrainer(map_id, event_id)
  # Se siamo già nella mappa giusta
  if $game_map && $game_map.map_id == map_id
    event = $game_map.events[event_id]
    if event
      # Sposta il giocatore vicino all'evento
      $game_player.moveto(event.x, event.y + 1)
      pbMessage(_INTL("Eccolo! L'allenatore è proprio qui!"))
    else
      pbMessage(_INTL("Non riesco a trovare l'allenatore in questa posizione."))
    end
  else
    # Dobbiamo cambiare mappa
    pbMessage(_INTL("L'allenatore si trova in un'altra area."))
    
    if pbConfirmMessage(_INTL("Vuoi essere teletrasportato lì?"))
      # Teletrasporta alla mappa
      $game_temp.player_new_map_id = map_id
      $game_temp.player_new_x = $game_map.events[event_id]&.x || 10
      $game_temp.player_new_y = ($game_map.events[event_id]&.y || 10) + 1
      $game_temp.player_new_direction = 8 # Facing up
      $scene.transfer_player
      
      pbMessage(_INTL("Sei stato teletrasportato dall'allenatore!"))
    end
  end
end

# Metodo ausiliario per ottenere il nome di una mappa
def get_map_name(map_id)
  begin
    mapinfos = load_data("Data/MapInfos.rxdata")
    return mapinfos[map_id]&.name || "Mappa #{map_id}"
  rescue
    return "Mappa #{map_id}"
  end
end

#===============================================================================
# Item VS Seeker
#===============================================================================

# Definizione dell'item VS Seeker
ItemHandlers::UseFromBag.add(:VSSEEKER, proc { |item|
  next pbUseVSSeeker
})

ItemHandlers::UseInField.add(:VSSEEKER, proc { |item|
  next pbUseVSSeeker
})

# Funzione per usare il VS Seeker
def pbUseVSSeeker
  # Controlla se il VS Seeker è disponibile
  unless $vs_seeker
    pbMessage(_INTL("Il VS Seeker non è funzionante."))
    return false
  end
  
  # Controlla se ci sono allenatori sconfitti
  stats = $vs_seeker.get_stats
  if stats[:total_defeated] == 0
    pbMessage(_INTL("Non hai ancora sconfitto nessun allenatore."))
    pbMessage(_INTL("Il VS Seeker non rileva alcun segnale..."))
    return true
  end
  
  # Animazione di utilizzo del VS Seeker
  pbMessage(_INTL("\\me[VS Seeker]Hai usato il VS Seeker!"))
  pbWait(20)
  
  # Controlla allenatori disponibili
  available_trainers = $vs_seeker.get_available_trainers
  
  if available_trainers.empty?
    remaining_steps = 100 - stats[:step_counter]
    pbMessage(_INTL("Nessun allenatore è pronto per una rivincita."))
    pbMessage(_INTL("Cammina ancora {1} passi per riattivare gli allenatori!", remaining_steps)) if remaining_steps > 0
  else
    pbMessage(_INTL("Il VS Seeker ha rilevato {1} allenatore{2} pronto{2} per una rivincita!", 
                   available_trainers.size, available_trainers.size == 1 ? "" : "i"))
    
    # Chiedi se aprire il menu
    if pbConfirmMessage(_INTL("Vuoi vedere la lista degli allenatori disponibili?"))
      pbVSSeekerMenu
    end
  end
  
  return true
end

#===============================================================================
# Interfaccia Avanzata con Grafica
#===============================================================================

# Menu VS Seeker con interfaccia grafica migliorata
def pbVSSeekerMenuAdvanced
  return unless $vs_seeker
  
  # Ottieni i dati
  stats = $vs_seeker.get_stats
  available_trainers = $vs_seeker.get_available_trainers
  
  # Se non ci sono allenatori
  if stats[:total_defeated] == 0
    pbMessage(_INTL("Non hai ancora sconfitto nessun allenatore."))
    return
  end
  
  # Crea la finestra principale
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  
  # Finestra del titolo
  title_window = Window_UnformattedTextPokemon.new(_INTL("VS Seeker"))
  title_window.viewport = viewport
  title_window.width = Graphics.width
  title_window.height = 64
  title_window.x = 0
  title_window.y = 0
  
  # Finestra delle statistiche
  stats_text = _INTL("Passi: {1}/100 | Allenatori: {2} | Disponibili: {3}", 
                    stats[:step_counter], stats[:total_defeated], stats[:available_now])
  stats_window = Window_UnformattedTextPokemon.new(stats_text)
  stats_window.viewport = viewport
  stats_window.width = Graphics.width
  stats_window.height = 64
  stats_window.x = 0
  stats_window.y = Graphics.height - 64
  
  # Lista allenatori
  trainer_commands = []
  if available_trainers.any?
    trainer_commands += available_trainers.map { |t| "#{t[:name]} (#{get_map_name(t[:map_id])})" }
  else
    trainer_commands << _INTL("Nessun allenatore disponibile")
  end
  trainer_commands << _INTL("Esci")
  
  # Finestra comandi
  cmd_window = Window_CommandPokemonEx.new(trainer_commands)
  cmd_window.viewport = viewport
  cmd_window.width = Graphics.width
  cmd_window.height = Graphics.height - 128
  cmd_window.x = 0
  cmd_window.y = 64
  
  # Loop principale
  loop do
    Graphics.update
    Input.update
    cmd_window.update
    
    if Input.trigger?(Input::USE)
      if available_trainers.any? && cmd_window.index < available_trainers.size
        # Allenatore selezionato
        selected_trainer = available_trainers[cmd_window.index]
        break if pbShowTrainerDetailsAdvanced(selected_trainer, viewport)
      elsif cmd_window.index == trainer_commands.size - 1
        # Esci
        break
      end
    elsif Input.trigger?(Input::BACK)
      break
    end
  end
  
  # Pulizia
  title_window.dispose
  stats_window.dispose
  cmd_window.dispose
  viewport.dispose
end

# Mostra i dettagli dell'allenatore con interfaccia migliorata
def pbShowTrainerDetailsAdvanced(trainer, parent_viewport)
  # Crea viewport per i dettagli
  detail_viewport = Viewport.new(50, 50, Graphics.width - 100, Graphics.height - 100)
  detail_viewport.z = parent_viewport.z + 1
  
  # Finestra dettagli
  map_name = get_map_name(trainer[:map_id])
  details_text = _INTL("Allenatore: {1}\nPosizione: {2}\nPassi dalla sconfitta: {3}\n\nVuoi sfidare questo allenatore?", 
                      trainer[:name], map_name, trainer[:steps_since_defeat])
  
  details_window = Window_UnformattedTextPokemon.new(details_text)
  details_window.viewport = detail_viewport
  details_window.width = detail_viewport.rect.width
  details_window.height = detail_viewport.rect.height - 64
  
  # Comandi
  choice_commands = [_INTL("Vai dall'allenatore"), _INTL("Annulla")]
  choice_window = Window_CommandPokemonEx.new(choice_commands)
  choice_window.viewport = detail_viewport
  choice_window.width = detail_viewport.rect.width
  choice_window.height = 64
  choice_window.y = detail_viewport.rect.height - 64
  
  result = false
  
  # Loop scelta
  loop do
    Graphics.update
    Input.update
    choice_window.update
    
    if Input.trigger?(Input::USE)
      case choice_window.index
      when 0 # Vai dall'allenatore
        pbGoToTrainer(trainer[:map_id], trainer[:event_id])
        result = true
        break
      when 1 # Annulla
        break
      end
    elsif Input.trigger?(Input::BACK)
      break
    end
  end
  
  # Pulizia
  details_window.dispose
  choice_window.dispose
  detail_viewport.dispose
  
  return result
end

#===============================================================================
# Notifiche e Feedback Visivo
#===============================================================================

# Mostra una notifica quando gli allenatori diventano disponibili
def pbShowVSSeekerNotification(count)
  return if count <= 0
  
  # Crea una finestra di notifica temporanea
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  
  notification_text = _INTL("VS Seeker: {1} allenatore{2} disponibile{2}!", 
                           count, count == 1 ? "" : "i")
  
  notification_window = Window_UnformattedTextPokemon.new(notification_text)
  notification_window.viewport = viewport
  notification_window.width = Graphics.width - 100
  notification_window.height = 80
  notification_window.x = 50
  notification_window.y = 50
  
  # Mostra per 3 secondi
  timer = 0
  while timer < 180 # 3 secondi a 60 FPS
    Graphics.update
    timer += 1
    
    # Permetti di chiudere premendo un tasto
    if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
      break
    end
  end
  
  # Pulizia
  notification_window.dispose
  viewport.dispose
end

# Effetto sonoro per il VS Seeker
def pbPlayVSSeekerSound
  # Riproduci un suono caratteristico
  pbSEPlay("VS Seeker", 80) rescue pbSEPlay("Pkmn move learnt", 80)
end