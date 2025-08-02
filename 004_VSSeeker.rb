#===============================================================================
# VS Seeker Plugin for Pokémon Essentials v20.1
#===============================================================================
# Permette di ri-sfidare allenatori già sconfitti dopo aver camminato 100 passi
# Utilizza il sistema Unlimited Self Switches per tracciare gli allenatori
#===============================================================================

class VSSeeker
  # Inizializza il VS Seeker
  def initialize
    @step_counter = 0
    @last_step_count = $stats&.steps_taken || 0
    @defeated_trainers = {} # {map_id => {event_id => {name, last_defeat_steps, available}}}
    @debug_mode = false
    
    puts "[VS SEEKER] Sistema inizializzato" if @debug_mode
  end
  
  # Aggiorna il contatore dei passi
  def update_step_counter
    return unless $stats
    
    current_steps = $stats.steps_taken
    
    # Se il contatore dei passi è aumentato
    if current_steps > @last_step_count
      steps_taken = current_steps - @last_step_count
      @step_counter += steps_taken
      @last_step_count = current_steps
      
      puts "[VS SEEKER] Passi: +#{steps_taken} (Totale: #{@step_counter})" if @debug_mode
      
      # Controlla se dobbiamo riattivare degli allenatori
      check_trainer_availability if @step_counter >= 100
    end
  end
  
  # Registra un allenatore come sconfitto
  def register_defeated_trainer(map_id, event_id, trainer_name)
    @defeated_trainers[map_id] ||= {}
    
    current_steps = $stats&.steps_taken || 0
    
    @defeated_trainers[map_id][event_id] = {
      name: trainer_name,
      last_defeat_steps: current_steps,
      available: false
    }
    
    # Imposta la switch personalizzata per questo allenatore
    switch_name = "TRAINER_#{event_id}"
    key = [map_id, event_id, switch_name]
    $game_self_switches[key] = true # true = sconfitto
    
    puts "[VS SEEKER] Allenatore registrato: #{trainer_name} (Mappa #{map_id}, Evento #{event_id})" if @debug_mode
    
    # Aggiorna la mappa se necessario
    if $game_map && $game_map.map_id == map_id
      $game_map.need_refresh = true
    end
  end
  
  # Controlla la disponibilità degli allenatori dopo 100 passi
  def check_trainer_availability
    return if @defeated_trainers.empty?
    
    current_steps = $stats&.steps_taken || 0
    reactivated_count = 0
    
    @defeated_trainers.each do |map_id, trainers|
      trainers.each do |event_id, trainer_data|
        # Controlla se sono passati abbastanza passi (100)
        steps_since_defeat = current_steps - trainer_data[:last_defeat_steps]
        
        if steps_since_defeat >= 100 && !trainer_data[:available]
          # Riattiva l'allenatore
          trainer_data[:available] = true
          reactivated_count += 1
          
          puts "[VS SEEKER] Allenatore riattivato: #{trainer_data[:name]} (#{steps_since_defeat} passi)" if @debug_mode
        end
      end
    end
    
    # Reset del contatore dopo aver controllato
    @step_counter = 0 if @step_counter >= 100
    
    # Notifica al giocatore se ci sono allenatori disponibili
    if reactivated_count > 0
      pbMessage(_INTL("Il VS Seeker ha rilevato {1} allenatore{2} disponibile{2} per una rivincita!", 
                     reactivated_count, reactivated_count == 1 ? "" : "i"))
    end
  end
  
  # Ottiene tutti gli allenatori disponibili per la rivincita
  def get_available_trainers(map_id = nil)
    available = []
    
    target_maps = map_id ? [map_id] : @defeated_trainers.keys
    
    target_maps.each do |m_id|
      next unless @defeated_trainers[m_id]
      
      @defeated_trainers[m_id].each do |event_id, trainer_data|
        if trainer_data[:available]
          available << {
            map_id: m_id,
            event_id: event_id,
            name: trainer_data[:name],
            steps_since_defeat: ($stats&.steps_taken || 0) - trainer_data[:last_defeat_steps]
          }
        end
      end
    end
    
    available
  end
  
  # Ottiene tutti gli allenatori sconfitti (disponibili e non)
  def get_all_defeated_trainers(map_id = nil)
    all_trainers = []
    
    target_maps = map_id ? [map_id] : @defeated_trainers.keys
    
    target_maps.each do |m_id|
      next unless @defeated_trainers[m_id]
      
      @defeated_trainers[m_id].each do |event_id, trainer_data|
        current_steps = $stats&.steps_taken || 0
        steps_since_defeat = current_steps - trainer_data[:last_defeat_steps]
        steps_remaining = [100 - steps_since_defeat, 0].max
        
        all_trainers << {
          map_id: m_id,
          event_id: event_id,
          name: trainer_data[:name],
          available: trainer_data[:available],
          steps_since_defeat: steps_since_defeat,
          steps_remaining: steps_remaining
        }
      end
    end
    
    all_trainers
  end
  
  # Rimuove la disponibilità di un allenatore dopo averlo sfidato
  def mark_trainer_challenged(map_id, event_id)
    return unless @defeated_trainers[map_id] && @defeated_trainers[map_id][event_id]
    
    current_steps = $stats&.steps_taken || 0
    @defeated_trainers[map_id][event_id][:last_defeat_steps] = current_steps
    @defeated_trainers[map_id][event_id][:available] = false
    
    puts "[VS SEEKER] Allenatore sfidato nuovamente: #{@defeated_trainers[map_id][event_id][:name]}" if @debug_mode
  end
  
  # Attiva/disattiva la modalità debug
  def set_debug_mode(enabled)
    @debug_mode = enabled
    puts "[VS SEEKER] Debug #{enabled ? 'attivato' : 'disattivato'}"
  end
  
  # Ottiene statistiche del VS Seeker
  def get_stats
    total_defeated = 0
    total_available = 0
    
    @defeated_trainers.each do |map_id, trainers|
      total_defeated += trainers.size
      trainers.each do |event_id, trainer_data|
        total_available += 1 if trainer_data[:available]
      end
    end
    
    {
      step_counter: @step_counter,
      total_defeated: total_defeated,
      available_now: total_available,
      maps_with_trainers: @defeated_trainers.keys.size
    }
  end
  
  # Forza la riattivazione di tutti gli allenatori (per debug)
  def force_reactivate_all
    reactivated = 0
    
    @defeated_trainers.each do |map_id, trainers|
      trainers.each do |event_id, trainer_data|
        unless trainer_data[:available]
          trainer_data[:available] = true
          reactivated += 1
        end
      end
    end
    
    puts "[VS SEEKER] Forzata riattivazione di #{reactivated} allenatori"
    reactivated
  end
  
  # Resetta tutti i dati del VS Seeker
  def reset_all_data
    @defeated_trainers.clear
    @step_counter = 0
    @last_step_count = $stats&.steps_taken || 0
    
    # Rimuovi anche tutte le switch degli allenatori
    $game_self_switches.keys.each do |key|
      if key[2].to_s.start_with?("TRAINER_")
        $game_self_switches[key] = nil
      end
    end
    
    puts "[VS SEEKER] Tutti i dati sono stati resettati"
  end
end

#===============================================================================
# Integrazione con il Sistema di Gioco
#===============================================================================

# Inizializza il VS Seeker globale
$vs_seeker = VSSeeker.new

# Integrazione con il movimento del giocatore
class Game_Player
  alias vs_seeker_move_generic move_generic
  def move_generic(direction, turn_enabled = true)
    result = vs_seeker_move_generic(direction, turn_enabled)
    
    # Aggiorna il VS Seeker ad ogni passo
    if result && $vs_seeker
      $vs_seeker.update_step_counter
    end
    
    return result
  end
end

# Integrazione con le battaglie allenatori
module BattleCreationHelperMethods
  alias vs_seeker_pbTrainerBattle pbTrainerBattle
  def pbTrainerBattle(trainer_or_id, *args)
    # Salva le informazioni prima della battaglia
    trainer_info = nil
    
    if trainer_or_id.is_a?(NPCTrainer)
      trainer_info = {
        name: trainer_or_id.name,
        full_name: trainer_or_id.full_name
      }
    elsif trainer_or_id.is_a?(Symbol)
      trainer_data = GameData::Trainer.get(trainer_or_id)
      trainer_info = {
        name: trainer_data.name,
        full_name: trainer_data.full_name
      }
    end
    
    # Esegui la battaglia originale
    result = vs_seeker_pbTrainerBattle(trainer_or_id, *args)
    
    # Se la battaglia è stata vinta e abbiamo le informazioni dell'allenatore
    if result && trainer_info && $vs_seeker && $game_map
      # Trova l'evento corrente (assumendo che sia l'allenatore)
      current_event_id = get_current_trainer_event_id
      
      if current_event_id
        $vs_seeker.register_defeated_trainer(
          $game_map.map_id,
          current_event_id,
          trainer_info[:full_name] || trainer_info[:name]
        )
      end
    end
    
    return result
  end
  
  # Metodo ausiliario per trovare l'ID dell'evento allenatore corrente
  def get_current_trainer_event_id
    return nil unless $game_map && $game_map.events
    
    # Cerca negli eventi della mappa corrente quello che ha appena attivato una battaglia
    # Questo è un approccio semplificato - potrebbe essere necessario raffinarlo
    player_x = $game_player.x
    player_y = $game_player.y
    
    $game_map.events.each do |event_id, event|
      # Controlla se l'evento è vicino al giocatore (entro 2 tile)
      distance = (event.x - player_x).abs + (event.y - player_y).abs
      if distance <= 2
        # Controlla se l'evento contiene comandi di battaglia allenatore
        event.list.each do |command|
          if command.code == 301 # Battle command
            return event_id
          end
        end
      end
    end
    
    nil
  end
end

#===============================================================================
# Comandi e Interfacce del VS Seeker
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
# Comandi di Debug per il VS Seeker
#===============================================================================

# Debug del VS Seeker
def pbVSSeekerDebug(action = nil)
  return unless $vs_seeker
  
  case action
  when "stats", "status", nil
    stats = $vs_seeker.get_stats
    message = "VS Seeker Debug:\n"
    message += "Contatore passi: #{stats[:step_counter]}/100\n"
    message += "Allenatori sconfitti: #{stats[:total_defeated]}\n"
    message += "Disponibili ora: #{stats[:available_now]}\n"
    message += "Mappe coinvolte: #{stats[:maps_with_trainers]}"
    pbMessage(message)
    
  when "enable_debug", "debug_on"
    $vs_seeker.set_debug_mode(true)
    pbMessage("Debug VS Seeker attivato.")
    
  when "disable_debug", "debug_off"
    $vs_seeker.set_debug_mode(false)
    pbMessage("Debug VS Seeker disattivato.")
    
  when "force_reactivate", "reactivate_all"
    count = $vs_seeker.force_reactivate_all
    pbMessage("Riattivati #{count} allenatori.")
    
  when "reset", "reset_all"
    if pbConfirmMessage("Sei sicuro di voler resettare tutti i dati del VS Seeker?")
      $vs_seeker.reset_all_data
      pbMessage("Dati VS Seeker resettati.")
    end
    
  else
    pbMessage("Comandi disponibili: stats, debug_on, debug_off, reactivate_all, reset")
  end
end