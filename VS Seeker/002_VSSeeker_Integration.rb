#===============================================================================
# VS Seeker Integration - Pokémon Essentials v20.1
#===============================================================================
# Integrazione del VS Seeker con i sistemi di gioco esistenti
# Gestisce movimento giocatore e battaglie allenatori
#===============================================================================

#===============================================================================
# Integrazione con il Movimento del Giocatore
#===============================================================================

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

#===============================================================================
# Integrazione con le Battaglie Allenatori
#===============================================================================

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
# Integrazione con Eventi del Gioco
#===============================================================================

# Hook per quando il gioco viene salvato
Events.onSave += proc { |sender, e|
  $vs_seeker.save_data if $vs_seeker
}

# Hook per quando il gioco viene caricato
Events.onLoad += proc { |sender, e|
  if $vs_seeker
    $vs_seeker.load_data
  else
    # Reinizializza se necessario
    $vs_seeker = VSSeeker.new
    $vs_seeker.load_data
  end
}

# Hook per quando si cambia mappa
Events.onMapChange += proc { |sender, e|
  # Aggiorna la mappa se necessario per riflettere i cambiamenti delle switch
  if $vs_seeker && $game_map
    $game_map.need_refresh = true
  end
}

#===============================================================================
# Gestione Persistenza Dati
#===============================================================================

class PokemonSave
  alias vs_seeker_pbSave pbSave
  def pbSave(safesave = false)
    # Salva i dati del VS Seeker prima del salvataggio
    $vs_seeker.save_data if $vs_seeker
    
    # Esegui il salvataggio originale
    vs_seeker_pbSave(safesave)
  end
end

class PokemonLoad
  alias vs_seeker_pbLoad pbLoad
  def pbLoad(*args)
    # Esegui il caricamento originale
    result = vs_seeker_pbLoad(*args)
    
    # Carica i dati del VS Seeker dopo il caricamento
    if $vs_seeker
      $vs_seeker.load_data
    else
      $vs_seeker = VSSeeker.new
      $vs_seeker.load_data
    end
    
    return result
  end
end

#===============================================================================
# Compatibilità con Switch Personalizzate
#===============================================================================

# Estende la classe Game_Event per supportare le switch degli allenatori
class Game_Event
  alias vs_seeker_conditions_met? conditions_met?
  def conditions_met?(page)
    # Controlla le condizioni originali
    return false unless vs_seeker_conditions_met?(page)
    
    # Se questo evento è un allenatore tracciato dal VS Seeker
    if $vs_seeker && $vs_seeker.defeated_trainers[$game_map.map_id]
      trainer_data = $vs_seeker.defeated_trainers[$game_map.map_id][@id]
      
      if trainer_data
        # Se l'allenatore è disponibile per una rivincita, mostra l'evento
        # Se non è disponibile, nascondi l'evento (a meno che non sia la prima volta)
        switch_name = "TRAINER_#{@id}"
        key = [$game_map.map_id, @id, switch_name]
        
        # Se l'allenatore è stato sconfitto ma non è ancora disponibile
        if $game_self_switches[key] && !trainer_data[:available]
          # Nascondi l'evento se la pagina non ha condizioni specifiche per la rivincita
          return false unless page_has_rematch_conditions?(page)
        end
      end
    end
    
    return true
  end
  
  # Controlla se una pagina ha condizioni specifiche per la rivincita
  def page_has_rematch_conditions?(page)
    # Cerca nei commenti della pagina per indicazioni di rivincita
    page.list.each do |command|
      if command.code == 108 || command.code == 408 # Comment
        comment = command.parameters[0]
        if comment =~ /rematch|rivincita|vs.?seeker/i
          return true
        end
      end
    end
    
    false
  end
end

#===============================================================================
# Debug e Monitoraggio
#===============================================================================

# Comando per monitorare l'integrazione del VS Seeker
def pbVSSeekerIntegrationTest
  return unless $vs_seeker
  
  tests = []
  
  # Test 1: Integrazione movimento
  tests << "Movimento giocatore: #{Game_Player.method_defined?(:vs_seeker_move_generic) ? '✓' : '✗'}"
  
  # Test 2: Integrazione battaglie
  tests << "Battaglie allenatori: #{BattleCreationHelperMethods.method_defined?(:vs_seeker_pbTrainerBattle) ? '✓' : '✗'}"
  
  # Test 3: Eventi di gioco
  event_hooks = 0
  event_hooks += 1 if Events.respond_to?(:onSave)
  event_hooks += 1 if Events.respond_to?(:onLoad)
  event_hooks += 1 if Events.respond_to?(:onMapChange)
  tests << "Eventi di gioco: #{event_hooks}/3 hook attivi"
  
  # Test 4: Persistenza dati
  tests << "Salvataggio dati: #{PokemonSave.method_defined?(:vs_seeker_pbSave) ? '✓' : '✗'}"
  tests << "Caricamento dati: #{PokemonLoad.method_defined?(:vs_seeker_pbLoad) ? '✓' : '✗'}"
  
  # Test 5: Switch personalizzate
  tests << "Switch personalizzate: #{Game_Event.method_defined?(:vs_seeker_conditions_met?) ? '✓' : '✗'}"
  
  # Mostra i risultati
  message = "Test Integrazione VS Seeker:\n\n"
  tests.each { |test| message += "#{test}\n" }
  
  pbMessage(message)
end