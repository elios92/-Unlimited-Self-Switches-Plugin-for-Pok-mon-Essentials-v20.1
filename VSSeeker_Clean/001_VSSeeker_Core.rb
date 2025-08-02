#===============================================================================
# VS Seeker Core System - Pokémon Essentials v20.1
#===============================================================================
# Sistema principale per ri-sfidare allenatori già sconfitti
# Riattivazione dopo 100 passi del giocatore
#===============================================================================

class VSSeeker
  attr_reader :step_counter, :defeated_trainers
  
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
  
  # Salva i dati del VS Seeker (per persistenza)
  def save_data
    data = {
      step_counter: @step_counter,
      last_step_count: @last_step_count,
      defeated_trainers: @defeated_trainers,
      version: "1.0"
    }
    
    # Salva in una variabile globale per la persistenza
    $game_variables[998] = data
    puts "[VS SEEKER] Dati salvati" if @debug_mode
  end
  
  # Carica i dati del VS Seeker (per persistenza)
  def load_data
    return unless $game_variables[998].is_a?(Hash)
    
    data = $game_variables[998]
    @step_counter = data[:step_counter] || 0
    @last_step_count = data[:last_step_count] || ($stats&.steps_taken || 0)
    @defeated_trainers = data[:defeated_trainers] || {}
    
    puts "[VS SEEKER] Dati caricati (#{@defeated_trainers.values.map(&:size).sum} allenatori)" if @debug_mode
  end
end

#===============================================================================
# Inizializzazione Sistema VS Seeker
#===============================================================================

# Inizializza il VS Seeker globale
$vs_seeker = VSSeeker.new

# Carica i dati salvati se disponibili
$vs_seeker.load_data if $vs_seeker

# Salva automaticamente i dati periodicamente
Events.onStepTaken += proc { |sender, e|
  $vs_seeker.save_data if $vs_seeker && rand(50) == 0 # Salva casualmente ogni ~50 passi
}