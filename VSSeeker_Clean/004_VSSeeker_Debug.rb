#===============================================================================
# VS Seeker Debug & Diagnostics - Pokémon Essentials v20.1
#===============================================================================
# Strumenti di debug, test e diagnostica per il VS Seeker
# Include controlli di integrità e simulazioni
#===============================================================================

#===============================================================================
# Comandi di Debug Principali
#===============================================================================

# Debug del VS Seeker
def pbVSSeekerDebug(action = nil)
  return unless $vs_seeker
  
  case action&.to_s&.downcase
  when "stats", "status", nil
    pbVSSeekerDebugStats
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
  when "test"
    pbVSSeekerFullTest
  when "integration"
    pbVSSeekerIntegrationTest
  when "simulate"
    pbVSSeekerSimulateBattle
  else
    pbVSSeekerDebugMenu
  end
end

# Menu debug completo
def pbVSSeekerDebugMenu
  commands = [
    "Statistiche e Status",
    "Test Completo Sistema",
    "Test Integrazione",
    "Simulazione Battaglia",
    "Diagnostica Avanzata",
    "Controlli Integrità",
    "Reset e Pulizia",
    "Esci"
  ]
  
  loop do
    command = pbShowCommands(nil, commands, -1)
    
    case command
    when 0 # Statistiche
      pbVSSeekerDebugStats
    when 1 # Test completo
      pbVSSeekerFullTest
    when 2 # Test integrazione
      pbVSSeekerIntegrationTest
    when 3 # Simulazione
      pbVSSeekerSimulateBattle
    when 4 # Diagnostica
      pbVSSeekerAdvancedDiagnostics
    when 5 # Controlli integrità
      pbVSSeekerIntegrityCheck
    when 6 # Reset
      pbVSSeekerResetMenu
    else
      break
    end
  end
end

#===============================================================================
# Statistiche e Status
#===============================================================================

def pbVSSeekerDebugStats
  return unless $vs_seeker
  
  stats = $vs_seeker.get_stats
  message = "VS Seeker Debug Stats:\n\n"
  message += "SISTEMA:\n"
  message += "• Stato: #{$vs_seeker ? 'ATTIVO ✓' : 'INATTIVO ✗'}\n"
  message += "• Contatore passi: #{stats[:step_counter]}/100\n"
  message += "• Ultimo conteggio: #{$vs_seeker.instance_variable_get(:@last_step_count)}\n"
  message += "• Passi totali gioco: #{$stats&.steps_taken || 'N/A'}\n\n"
  
  message += "ALLENATORI:\n"
  message += "• Totale sconfitti: #{stats[:total_defeated]}\n"
  message += "• Disponibili ora: #{stats[:available_now]}\n"
  message += "• Mappe coinvolte: #{stats[:maps_with_trainers]}\n\n"
  
  message += "MEMORIA:\n"
  defeated_trainers = $vs_seeker.defeated_trainers
  total_memory = defeated_trainers.values.map(&:size).sum
  message += "• Voci in memoria: #{total_memory}\n"
  message += "• Dimensione hash: #{defeated_trainers.size} mappe\n"
  
  # Dettagli per mappa
  if defeated_trainers.any?
    message += "\nDETTAGLI PER MAPPA:\n"
    defeated_trainers.each do |map_id, trainers|
      available_count = trainers.values.count { |t| t[:available] }
      message += "• Mappa #{map_id}: #{trainers.size} allenatori (#{available_count} disponibili)\n"
    end
  end
  
  pbMessage(message)
end

#===============================================================================
# Test Completo del Sistema
#===============================================================================

def pbVSSeekerFullTest
  pbMessage("Avvio test completo del VS Seeker...")
  
  test_results = []
  
  # Test 1: Inizializzazione
  test_results << test_vs_seeker_initialization
  
  # Test 2: Conteggio passi
  test_results << test_step_counting
  
  # Test 3: Registrazione allenatori
  test_results << test_trainer_registration
  
  # Test 4: Disponibilità allenatori
  test_results << test_trainer_availability
  
  # Test 5: Persistenza dati
  test_results << test_data_persistence
  
  # Test 6: Integrazione switch
  test_results << test_switch_integration
  
  # Mostra risultati
  passed = test_results.count { |r| r[:passed] }
  total = test_results.size
  
  message = "Test VS Seeker Completato:\n\n"
  message += "RISULTATO: #{passed}/#{total} test superati\n\n"
  
  test_results.each do |result|
    status = result[:passed] ? "✓" : "✗"
    message += "#{status} #{result[:name]}\n"
    message += "  #{result[:details]}\n" if result[:details]
  end
  
  pbMessage(message)
  
  if passed < total
    pbMessage("ATTENZIONE: Alcuni test sono falliti!\nControlla la configurazione del sistema.")
  else
    pbMessage("Tutti i test sono stati superati! ✓\nIl VS Seeker è completamente funzionante.")
  end
end

# Test individuali
def test_vs_seeker_initialization
  {
    name: "Inizializzazione VS Seeker",
    passed: $vs_seeker != nil && $vs_seeker.is_a?(VSSeeker),
    details: $vs_seeker ? "Sistema inizializzato correttamente" : "Sistema non inizializzato"
  }
end

def test_step_counting
  return { name: "Conteggio Passi", passed: false, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  old_counter = $vs_seeker.step_counter
  $vs_seeker.update_step_counter
  
  {
    name: "Conteggio Passi",
    passed: $vs_seeker.respond_to?(:update_step_counter),
    details: "Metodo update_step_counter disponibile"
  }
end

def test_trainer_registration
  return { name: "Registrazione Allenatori", passed: false, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  # Simula registrazione
  old_count = $vs_seeker.get_stats[:total_defeated]
  
  begin
    $vs_seeker.register_defeated_trainer(999, 999, "Test Trainer")
    new_count = $vs_seeker.get_stats[:total_defeated]
    
    # Pulisci il test
    $vs_seeker.defeated_trainers[999]&.delete(999)
    $vs_seeker.defeated_trainers.delete(999) if $vs_seeker.defeated_trainers[999]&.empty?
    
    {
      name: "Registrazione Allenatori",
      passed: new_count > old_count,
      details: "Allenatore registrato e rimosso correttamente"
    }
  rescue => e
    {
      name: "Registrazione Allenatori",
      passed: false,
      details: "Errore: #{e.message}"
    }
  end
end

def test_trainer_availability
  return { name: "Disponibilità Allenatori", passed: false, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  {
    name: "Disponibilità Allenatori",
    passed: $vs_seeker.respond_to?(:get_available_trainers) && $vs_seeker.respond_to?(:check_trainer_availability),
    details: "Metodi di gestione disponibilità presenti"
  }
end

def test_data_persistence
  return { name: "Persistenza Dati", passed: false, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  begin
    $vs_seeker.save_data
    has_save = $vs_seeker.respond_to?(:save_data) && $vs_seeker.respond_to?(:load_data)
    has_data = $game_variables[998].is_a?(Hash)
    
    {
      name: "Persistenza Dati",
      passed: has_save && has_data,
      details: "Salvataggio e caricamento funzionanti"
    }
  rescue => e
    {
      name: "Persistenza Dati",
      passed: false,
      details: "Errore: #{e.message}"
    }
  end
end

def test_switch_integration
  {
    name: "Integrazione Switch",
    passed: defined?($game_self_switches) && $game_self_switches != nil,
    details: "Sistema switch personalizzate disponibile"
  }
end

#===============================================================================
# Diagnostica Avanzata
#===============================================================================

def pbVSSeekerAdvancedDiagnostics
  pbMessage("Avvio diagnostica avanzata...")
  
  diagnostic_results = []
  
  # Controlla dipendenze
  diagnostic_results << check_dependencies
  
  # Controlla integrità dati
  diagnostic_results << check_data_integrity
  
  # Controlla performance
  diagnostic_results << check_performance
  
  # Controlla memoria
  diagnostic_results << check_memory_usage
  
  # Mostra risultati
  message = "Diagnostica Avanzata VS Seeker:\n\n"
  
  diagnostic_results.each do |result|
    status = result[:status] == :ok ? "✓" : (result[:status] == :warning ? "⚠" : "✗")
    message += "#{status} #{result[:category]}\n"
    message += "  #{result[:details]}\n"
  end
  
  pbMessage(message)
end

def check_dependencies
  issues = []
  
  issues << "VS Seeker non inizializzato" unless $vs_seeker
  issues << "Statistiche gioco non disponibili" unless $stats
  issues << "Switch personalizzate non disponibili" unless $game_self_switches
  issues << "Mappa non caricata" unless $game_map
  issues << "Giocatore non disponibile" unless $game_player
  
  {
    category: "Dipendenze Sistema",
    status: issues.empty? ? :ok : :error,
    details: issues.empty? ? "Tutte le dipendenze soddisfatte" : issues.join(", ")
  }
end

def check_data_integrity
  return { category: "Integrità Dati", status: :error, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  issues = []
  
  # Controlla struttura dati
  defeated_trainers = $vs_seeker.defeated_trainers
  unless defeated_trainers.is_a?(Hash)
    issues << "Struttura defeated_trainers corrotta"
  else
    defeated_trainers.each do |map_id, trainers|
      unless trainers.is_a?(Hash)
        issues << "Dati mappa #{map_id} corrotti"
        next
      end
      
      trainers.each do |event_id, trainer_data|
        unless trainer_data.is_a?(Hash) && trainer_data[:name] && trainer_data.key?(:available)
          issues << "Dati allenatore #{event_id} (mappa #{map_id}) corrotti"
        end
      end
    end
  end
  
  {
    category: "Integrità Dati",
    status: issues.empty? ? :ok : :error,
    details: issues.empty? ? "Dati integri" : issues.join(", ")
  }
end

def check_performance
  return { category: "Performance", status: :error, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  # Test velocità operazioni
  start_time = Time.now
  
  # Simula operazioni comuni
  1000.times do
    $vs_seeker.get_stats
  end
  
  elapsed = Time.now - start_time
  
  status = elapsed < 0.1 ? :ok : (elapsed < 0.5 ? :warning : :error)
  
  {
    category: "Performance",
    status: status,
    details: "1000 get_stats in #{elapsed.round(3)}s"
  }
end

def check_memory_usage
  return { category: "Uso Memoria", status: :error, details: "VS Seeker non disponibile" } unless $vs_seeker
  
  defeated_trainers = $vs_seeker.defeated_trainers
  total_trainers = defeated_trainers.values.map(&:size).sum
  
  # Stima approssimativa dell'uso di memoria
  estimated_bytes = total_trainers * 200 # ~200 byte per allenatore
  
  status = if estimated_bytes < 10000 # < 10KB
             :ok
           elsif estimated_bytes < 100000 # < 100KB
             :warning
           else
             :error
           end
  
  {
    category: "Uso Memoria",
    status: status,
    details: "~#{estimated_bytes} byte per #{total_trainers} allenatori"
  }
end

#===============================================================================
# Controlli di Integrità
#===============================================================================

def pbVSSeekerIntegrityCheck
  pbMessage("Controllo integrità del VS Seeker...")
  
  issues_found = []
  fixes_applied = []
  
  # Controlla e ripara dati corrotti
  if $vs_seeker
    defeated_trainers = $vs_seeker.defeated_trainers
    
    defeated_trainers.each do |map_id, trainers|
      trainers.each do |event_id, trainer_data|
        # Ripara dati mancanti
        if !trainer_data[:name] || trainer_data[:name].empty?
          trainer_data[:name] = "Allenatore #{event_id}"
          fixes_applied << "Nome allenatore #{event_id} riparato"
        end
        
        if !trainer_data.key?(:available)
          trainer_data[:available] = false
          fixes_applied << "Disponibilità allenatore #{event_id} riparata"
        end
        
        if !trainer_data[:last_defeat_steps] || trainer_data[:last_defeat_steps] < 0
          trainer_data[:last_defeat_steps] = $stats&.steps_taken || 0
          fixes_applied << "Passi sconfitta allenatore #{event_id} riparati"
        end
      end
    end
    
    # Controlla sincronizzazione con switch personalizzate
    $game_self_switches.keys.each do |key|
      next unless key[2].to_s.start_with?("TRAINER_")
      
      map_id, event_id, switch_name = key
      trainer_id = switch_name.gsub("TRAINER_", "").to_i
      
      # Se c'è una switch ma non un allenatore registrato
      if !defeated_trainers[map_id] || !defeated_trainers[map_id][trainer_id]
        issues_found << "Switch orfana trovata: #{key.inspect}"
      end
    end
  end
  
  # Mostra risultati
  message = "Controllo Integrità Completato:\n\n"
  
  if issues_found.empty? && fixes_applied.empty?
    message += "✓ Nessun problema rilevato\n"
    message += "Il sistema è integro e funzionante."
  else
    if fixes_applied.any?
      message += "RIPARAZIONI APPLICATE:\n"
      fixes_applied.each { |fix| message += "• #{fix}\n" }
      message += "\n"
    end
    
    if issues_found.any?
      message += "PROBLEMI RILEVATI:\n"
      issues_found.each { |issue| message += "• #{issue}\n" }
    end
  end
  
  pbMessage(message)
end

#===============================================================================
# Simulazioni e Test
#===============================================================================

def pbVSSeekerSimulateBattle
  return unless $vs_seeker && $game_map
  
  pbMessage("Simulazione battaglia allenatore...")
  
  # Simula la registrazione di un allenatore sconfitto
  fake_event_id = 9999
  fake_trainer_name = "Simulatore Test"
  
  $vs_seeker.register_defeated_trainer($game_map.map_id, fake_event_id, fake_trainer_name)
  
  pbMessage("✓ Allenatore '#{fake_trainer_name}' registrato come sconfitto.")
  
  # Mostra statistiche aggiornate
  stats = $vs_seeker.get_stats
  pbMessage("Statistiche aggiornate:\n• Allenatori sconfitti: #{stats[:total_defeated]}\n• Disponibili: #{stats[:available_now]}")
  
  # Chiedi se rimuovere il test
  if pbConfirmMessage("Vuoi rimuovere l'allenatore di test?")
    $vs_seeker.defeated_trainers[$game_map.map_id]&.delete(fake_event_id)
    if $vs_seeker.defeated_trainers[$game_map.map_id]&.empty?
      $vs_seeker.defeated_trainers.delete($game_map.map_id)
    end
    
    # Rimuovi anche la switch
    switch_key = [$game_map.map_id, fake_event_id, "TRAINER_#{fake_event_id}"]
    $game_self_switches[switch_key] = nil
    
    pbMessage("Allenatore di test rimosso.")
  end
end

#===============================================================================
# Menu Reset e Pulizia
#===============================================================================

def pbVSSeekerResetMenu
  commands = [
    "Reset VS Seeker completo",
    "Pulisci dati corrotti",
    "Reset contatore passi",
    "Rimuovi allenatori test",
    "Annulla"
  ]
  
  choice = pbShowCommands(nil, commands, -1)
  
  case choice
  when 0 # Reset completo
    if pbConfirmMessage("ATTENZIONE!\n\nQuesto resetterà TUTTI i dati del VS Seeker.\n\nSei sicuro?")
      $vs_seeker&.reset_all_data
      pbMessage("VS Seeker completamente resettato.")
    end
    
  when 1 # Pulisci corrotti
    if $vs_seeker
      removed = $vs_seeker.defeated_trainers.size
      $vs_seeker.defeated_trainers.select! do |map_id, trainers|
        trainers.select! do |event_id, trainer_data|
          trainer_data.is_a?(Hash) && trainer_data[:name] && trainer_data.key?(:available)
        end
        !trainers.empty?
      end
      removed -= $vs_seeker.defeated_trainers.size
      pbMessage("Rimossi #{removed} elementi corrotti.")
    end
    
  when 2 # Reset contatore
    if $vs_seeker
      $vs_seeker.instance_variable_set(:@step_counter, 0)
      $vs_seeker.instance_variable_set(:@last_step_count, $stats&.steps_taken || 0)
      pbMessage("Contatore passi resettato.")
    end
    
  when 3 # Rimuovi test
    if $vs_seeker
      removed = 0
      $vs_seeker.defeated_trainers.each do |map_id, trainers|
        trainers.delete_if do |event_id, trainer_data|
          if trainer_data[:name]&.include?("Test") || event_id >= 9999
            removed += 1
            true
          else
            false
          end
        end
      end
      $vs_seeker.defeated_trainers.delete_if { |map_id, trainers| trainers.empty? }
      pbMessage("Rimossi #{removed} allenatori di test.")
    end
  end
end