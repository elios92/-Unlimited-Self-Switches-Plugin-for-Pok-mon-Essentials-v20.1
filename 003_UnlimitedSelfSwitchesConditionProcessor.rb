#===============================================================================
# Processore delle Condizioni per Switch Personalizzate
#===============================================================================
# Questo file contiene il sistema automatico che controlla e attiva le 
# condizioni speciali impostate per le switch personalizzate.
# Include gestione di timer, variabili, switch di gioco e inventario.
#===============================================================================

class ConditionProcessor
  # Inizializza il processore delle condizioni
  def initialize
    @last_check_time = Time.now.to_i
    @check_interval = 1 # Controlla ogni secondo
    @active_conditions = {}
    @debug_mode = false
    
    puts "[DEBUG] ConditionProcessor inizializzato" if @debug_mode
  end
  
  # Metodo principale per processare tutte le condizioni
  def process_conditions
    current_time = Time.now.to_i
    
    # Controlla solo se è passato abbastanza tempo dall'ultimo controllo
    return unless current_time - @last_check_time >= @check_interval
    
    @last_check_time = current_time
    
    # Ottieni tutte le condizioni attive
    conditions = get_all_conditions
    return if conditions.empty?
    
    puts "[DEBUG] Processando #{conditions.size} condizioni..." if @debug_mode
    
    # Processa ogni condizione
    conditions.each do |condition_key, condition_data|
      process_single_condition(condition_key, condition_data, current_time)
    end
  end
  
  # Ottiene tutte le condizioni attive dal sistema
  def get_all_conditions
    return {} unless $game_variables[999].is_a?(Hash)
    $game_variables[999]
  end
  
  # Processa una singola condizione
  def process_single_condition(condition_key, condition_data, current_time)
    return unless condition_data.is_a?(Hash)
    return unless condition_data[:type]
    
    # Estrai i dati dalla chiave della condizione
    key_parts = condition_key.split(':')
    return if key_parts.length < 4
    
    condition_type = key_parts[0]
    map_id = key_parts[1].to_i
    event_id = key_parts[2].to_i
    switch_name = key_parts[3]
    
    puts "[DEBUG] Processando condizione #{condition_type} per switch '#{switch_name}'" if @debug_mode
    
    # Processa in base al tipo di condizione
    case condition_data[:type]
    when "timer"
      process_timer_condition(condition_key, condition_data, map_id, event_id, switch_name, current_time)
    when "variable"
      process_variable_condition(condition_key, condition_data, map_id, event_id, switch_name)
    when "gameswitch"
      process_gameswitch_condition(condition_key, condition_data, map_id, event_id, switch_name)
    when "inventory"
      process_inventory_condition(condition_key, condition_data, map_id, event_id, switch_name)
    else
      puts "[WARNING] Tipo di condizione sconosciuto: #{condition_data[:type]}"
    end
  end
  
  # Processa le condizioni timer
  def process_timer_condition(condition_key, condition_data, map_id, event_id, switch_name, current_time)
    start_time = condition_data[:start_time]
    duration = condition_data[:seconds]
    new_state = condition_data[:new_state]
    
    # Controlla se il timer è scaduto
    elapsed_time = current_time - start_time
    
    if elapsed_time >= duration
      # Il timer è scaduto, attiva la switch
      switch_key = [map_id, event_id, switch_name]
      old_state = $game_self_switches[switch_key] || false
      
      # Cambia lo stato solo se è diverso
      if old_state != new_state
        $game_self_switches[switch_key] = new_state
        
        # Log dell'attivazione
        state_text = new_state ? "ATTIVATA" : "DISATTIVATA"
        puts "[CONDITION] Timer scaduto: Switch '#{switch_name}' (Evento #{event_id}) #{state_text}"
        
        # Aggiorna la mappa se necessario
        if $game_map && $game_map.map_id == map_id
          $game_map.need_refresh = true
        end
        
        # Notifica al giocatore se è nella stessa mappa
        if $game_map && $game_map.map_id == map_id
          pbMessage(_INTL("La switch '#{switch_name}' è stata #{new_state ? 'attivata' : 'disattivata'} automaticamente."))
        end
      end
      
      # Rimuovi la condizione completata
      remove_condition(condition_key)
      puts "[DEBUG] Condizione timer rimossa: #{condition_key}" if @debug_mode
    else
      # Timer ancora attivo, mostra il tempo rimanente se in debug
      remaining = duration - elapsed_time
      puts "[DEBUG] Timer per '#{switch_name}': #{remaining} secondi rimanenti" if @debug_mode
    end
  end
  
  # Processa le condizioni basate su variabili
  def process_variable_condition(condition_key, condition_data, map_id, event_id, switch_name)
    var_id = condition_data[:var_id]
    target_value = condition_data[:value]
    comparison_type = condition_data[:comparison_type]
    new_state = condition_data[:new_state]
    
    # Ottieni il valore attuale della variabile
    current_value = $game_variables[var_id] || 0
    
    # Controlla se la condizione è soddisfatta
    condition_met = false
    
    case comparison_type
    when 0 # Uguale a (=)
      condition_met = (current_value == target_value)
    when 1 # Maggiore di (>)
      condition_met = (current_value > target_value)
    when 2 # Minore di (<)
      condition_met = (current_value < target_value)
    when 3 # Maggiore o uguale (>=)
      condition_met = (current_value >= target_value)
    when 4 # Minore o uguale (<=)
      condition_met = (current_value <= target_value)
    when 5 # Diverso da (!=)
      condition_met = (current_value != target_value)
    end
    
    puts "[DEBUG] Variabile #{var_id}: #{current_value} vs #{target_value}, condizione: #{condition_met}" if @debug_mode
    
    # Se la condizione è soddisfatta, aggiorna la switch
    if condition_met
      switch_key = [map_id, event_id, switch_name]
      old_state = $game_self_switches[switch_key] || false
      
      # Cambia lo stato solo se è diverso
      if old_state != new_state
        $game_self_switches[switch_key] = new_state
        
        # Log dell'attivazione
        state_text = new_state ? "ATTIVATA" : "DISATTIVATA"
        comparison_symbols = ["=", ">", "<", ">=", "<=", "!="]
        puts "[CONDITION] Variabile soddisfatta: Switch '#{switch_name}' #{state_text} (Var #{var_id} #{comparison_symbols[comparison_type]} #{target_value})"
        
        # Aggiorna la mappa se necessario
        if $game_map && $game_map.map_id == map_id
          $game_map.need_refresh = true
        end
        
        # Notifica al giocatore se è nella stessa mappa
        if $game_map && $game_map.map_id == map_id
          pbMessage(_INTL("La switch '#{switch_name}' è stata #{new_state ? 'attivata' : 'disattivata'} automaticamente."))
        end
      end
      
      # Rimuovi la condizione completata (opzionale - potresti volerla mantenere attiva)
      # remove_condition(condition_key)
    end
  end
  
  # Processa le condizioni basate su switch di gioco
  def process_gameswitch_condition(condition_key, condition_data, map_id, event_id, switch_name)
    switch_id = condition_data[:switch_id]
    trigger_state = condition_data[:trigger_state]
    new_state = condition_data[:new_state]
    
    # Ottieni lo stato attuale della switch di gioco
    current_switch_state = $game_switches[switch_id] || false
    
    puts "[DEBUG] Switch di gioco #{switch_id}: #{current_switch_state}, trigger su: #{trigger_state}" if @debug_mode
    
    # Controlla se la condizione è soddisfatta
    if current_switch_state == trigger_state
      switch_key = [map_id, event_id, switch_name]
      old_state = $game_self_switches[switch_key] || false
      
      # Cambia lo stato solo se è diverso
      if old_state != new_state
        $game_self_switches[switch_key] = new_state
        
        # Log dell'attivazione
        state_text = new_state ? "ATTIVATA" : "DISATTIVATA"
        trigger_text = trigger_state ? "ON" : "OFF"
        puts "[CONDITION] Switch di gioco soddisfatta: Switch '#{switch_name}' #{state_text} (Switch #{switch_id} = #{trigger_text})"
        
        # Aggiorna la mappa se necessario
        if $game_map && $game_map.map_id == map_id
          $game_map.need_refresh = true
        end
        
        # Notifica al giocatore se è nella stessa mappa
        if $game_map && $game_map.map_id == map_id
          pbMessage(_INTL("La switch '#{switch_name}' è stata #{new_state ? 'attivata' : 'disattivata'} automaticamente."))
        end
      end
    end
  end
  
  # Processa le condizioni basate sull'inventario
  def process_inventory_condition(condition_key, condition_data, map_id, event_id, switch_name)
    item_id = condition_data[:item_id]
    target_quantity = condition_data[:quantity]
    comparison_type = condition_data[:comparison_type]
    new_state = condition_data[:new_state]
    
    # Ottieni la quantità attuale dell'item nell'inventario
    current_quantity = 0
    if defined?($PokemonBag) && $PokemonBag
      current_quantity = $PokemonBag.pbQuantity(item_id) || 0
    end
    
    # Controlla se la condizione è soddisfatta
    condition_met = false
    
    case comparison_type
    when 0 # Almeno (>=)
      condition_met = (current_quantity >= target_quantity)
    when 1 # Esattamente (=)
      condition_met = (current_quantity == target_quantity)
    when 2 # Al massimo (<=)
      condition_met = (current_quantity <= target_quantity)
    end
    
    puts "[DEBUG] Item #{item_id}: #{current_quantity} vs #{target_quantity}, condizione: #{condition_met}" if @debug_mode
    
    # Se la condizione è soddisfatta, aggiorna la switch
    if condition_met
      switch_key = [map_id, event_id, switch_name]
      old_state = $game_self_switches[switch_key] || false
      
      # Cambia lo stato solo se è diverso
      if old_state != new_state
        $game_self_switches[switch_key] = new_state
        
        # Log dell'attivazione
        state_text = new_state ? "ATTIVATA" : "DISATTIVATA"
        comparison_symbols = [">=", "=", "<="]
        item_name = defined?(PBItems) ? PBItems.getName(item_id) : "Item #{item_id}"
        puts "[CONDITION] Inventario soddisfatto: Switch '#{switch_name}' #{state_text} (#{item_name} #{comparison_symbols[comparison_type]} #{target_quantity})"
        
        # Aggiorna la mappa se necessario
        if $game_map && $game_map.map_id == map_id
          $game_map.need_refresh = true
        end
        
        # Notifica al giocatore se è nella stessa mappa
        if $game_map && $game_map.map_id == map_id
          pbMessage(_INTL("La switch '#{switch_name}' è stata #{new_state ? 'attivata' : 'disattivata'} automaticamente."))
        end
      end
    end
  end
  
  # Rimuove una condizione completata
  def remove_condition(condition_key)
    return unless $game_variables[999].is_a?(Hash)
    $game_variables[999].delete(condition_key)
    puts "[DEBUG] Condizione rimossa: #{condition_key}" if @debug_mode
  end
  
  # Attiva/disattiva la modalità debug
  def set_debug_mode(enabled)
    @debug_mode = enabled
    puts "[DEBUG] Modalità debug #{enabled ? 'attivata' : 'disattivata'}"
  end
  
  # Ottiene statistiche sulle condizioni attive
  def get_condition_stats
    conditions = get_all_conditions
    stats = {
      total: conditions.size,
      timer: 0,
      variable: 0,
      gameswitch: 0,
      inventory: 0
    }
    
    conditions.each do |key, data|
      next unless data.is_a?(Hash) && data[:type]
      
      case data[:type]
      when "timer"
        stats[:timer] += 1
      when "variable"
        stats[:variable] += 1
      when "gameswitch"
        stats[:gameswitch] += 1
      when "inventory"
        stats[:inventory] += 1
      end
    end
    
    stats
  end
  
  # Pulisce le condizioni scadute o non valide
  def cleanup_invalid_conditions
    return unless $game_variables[999].is_a?(Hash)
    
    removed_count = 0
    current_time = Time.now.to_i
    
    $game_variables[999].keys.each do |key|
      condition = $game_variables[999][key]
      next unless condition.is_a?(Hash)
      
      # Rimuovi condizioni timer scadute da molto tempo (più di 1 ora)
      if condition[:type] == "timer"
        elapsed = current_time - (condition[:start_time] || 0)
        if elapsed > (condition[:seconds] || 0) + 3600 # 1 ora di buffer
          $game_variables[999].delete(key)
          removed_count += 1
          puts "[CLEANUP] Rimossa condizione timer scaduta: #{key}" if @debug_mode
        end
      end
      
      # Rimuovi condizioni con dati mancanti
      if condition[:type].nil? || condition[:new_state].nil?
        $game_variables[999].delete(key)
        removed_count += 1
        puts "[CLEANUP] Rimossa condizione non valida: #{key}" if @debug_mode
      end
    end
    
    puts "[CLEANUP] Rimosse #{removed_count} condizioni non valide" if removed_count > 0
    removed_count
  end
end

#===============================================================================
# Integrazione con il Sistema di Gioco
#===============================================================================

# Inizializza il processore globale delle condizioni
$condition_processor = ConditionProcessor.new

# Alias del metodo update della Scene_Map per integrare il processore
class Scene_Map
  alias condition_processor_update update
  def update
    # Esegui l'update originale
    condition_processor_update
    
    # Processa le condizioni se il processore è disponibile
    if $condition_processor
      $condition_processor.process_conditions
    end
  end
end

# Comandi di debug per il processore delle condizioni
def pbConditionProcessorDebug(enable = nil)
  if $condition_processor
    if enable.nil?
      # Mostra lo stato attuale
      stats = $condition_processor.get_condition_stats
      message = "Processore Condizioni - Statistiche:\n"
      message += "Totale condizioni: #{stats[:total]}\n"
      message += "Timer: #{stats[:timer]}\n"
      message += "Variabili: #{stats[:variable]}\n"
      message += "Switch di gioco: #{stats[:gameswitch]}\n"
      message += "Inventario: #{stats[:inventory]}"
      pbMessage(message)
    else
      # Attiva/disattiva il debug
      $condition_processor.set_debug_mode(enable)
      pbMessage("Debug del processore #{enable ? 'attivato' : 'disattivato'}.")
    end
  else
    pbMessage("Processore delle condizioni non disponibile.")
  end
end

# Comando per pulire le condizioni non valide
def pbCleanupConditions
  if $condition_processor
    removed = $condition_processor.cleanup_invalid_conditions
    pbMessage("Rimosse #{removed} condizioni non valide.")
  else
    pbMessage("Processore delle condizioni non disponibile.")
  end
end

# Comando per forzare il controllo delle condizioni
def pbForceConditionCheck
  if $condition_processor
    $condition_processor.process_conditions
    pbMessage("Controllo forzato delle condizioni completato.")
  else
    pbMessage("Processore delle condizioni non disponibile.")
  end
end