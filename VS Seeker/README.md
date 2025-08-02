# VS Seeker Plugin for Pokémon Essentials v20.1

## 📋 Descrizione

Il **VS Seeker** è un plugin che permette ai giocatori di ri-sfidare gli allenatori già sconfitti dopo aver camminato **100 passi**. Il sistema traccia automaticamente tutti gli allenatori battuti e li riattiva quando sono soddisfatte le condizioni.

## ✨ Caratteristiche Principali

- 🚶 **Riattivazione automatica** dopo 100 passi
- 📍 **Tracciamento posizione** degli allenatori sconfitti
- 🎯 **Teletrasporto** diretto agli allenatori disponibili
- 💾 **Salvataggio automatico** dei dati
- 🔧 **Strumenti di debug** completi
- 🎮 **Item utilizzabile** dall'inventario
- 🔗 **Integrazione** con Unlimited Self Switches

## 📁 Struttura File

- `001_VSSeeker_Core.rb` - Sistema principale e classe VSSeeker
- `002_VSSeeker_Integration.rb` - Integrazione con sistemi di gioco
- `003_VSSeeker_Interface.rb` - Interfacce utente e menu
- `004_VSSeeker_Debug.rb` - Strumenti di debug e diagnostica
- `meta.txt` - Metadati del plugin

## 🚀 Installazione

1. **Prerequisiti**: Installa prima il plugin "Unlimited Self Switches"
2. **Copia la cartella**: Metti l'intera cartella "VS Seeker" nella directory `Plugins`
3. **Riavvia il gioco**: Il plugin si attiverà automaticamente

## 📖 Come Funziona

### Meccanica Base
1. **Sconfiggi un allenatore** → Viene registrato automaticamente
2. **Cammina 100 passi** → L'allenatore diventa disponibile per rivincita
3. **Usa il VS Seeker** → Trova e sfida gli allenatori disponibili

### Utilizzo dell'Item
```ruby
# L'item VS Seeker può essere usato da:
# - Inventario (UseFromBag)
# - Campo di gioco (UseInField)
pbUseVSSeeker
```

### Comandi Principali
```ruby
# Menu principale VS Seeker
pbVSSeekerMenu

# Debug e diagnostica
pbVSSeekerDebug          # Menu debug completo
pbVSSeekerDebug("stats") # Solo statistiche
pbVSSeekerDebug("test")  # Test completo sistema
```

## 🎮 Interfaccia Utente

### Menu Principale
- **Allenatori disponibili**: Lista degli allenatori pronti per rivincita
- **Tutti gli allenatori**: Panoramica completa con tempi rimanenti
- **Statistiche**: Informazioni dettagliate sul sistema

### Funzionalità Avanzate
- **Teletrasporto automatico** agli allenatori
- **Notifiche** quando gli allenatori diventano disponibili
- **Interfaccia grafica** migliorata con statistiche in tempo reale

## 🔧 Configurazione

### Variabili Utilizzate
- `$game_variables[998]` - Dati persistenti VS Seeker
- `$game_variables[999]` - Condizioni speciali (Unlimited Self Switches)

### Switch Personalizzate
Il sistema crea automaticamente switch con formato:
- `TRAINER_[event_id]` - Traccia lo stato di ogni allenatore

## 🐛 Debug e Diagnostica

### Menu Debug Completo
```ruby
pbVSSeekerDebug # Apre il menu completo con:
```

- **Statistiche e Status**: Informazioni dettagliate sistema
- **Test Completo**: Verifica tutte le funzionalità
- **Test Integrazione**: Controlla collegamenti con altri sistemi
- **Simulazione Battaglia**: Testa la registrazione allenatori
- **Diagnostica Avanzata**: Controlli performance e memoria
- **Controlli Integrità**: Rileva e ripara dati corrotti
- **Reset e Pulizia**: Strumenti di manutenzione

### Test Automatici
Il sistema include test per:
- ✅ Inizializzazione corretta
- ✅ Conteggio passi funzionante
- ✅ Registrazione allenatori
- ✅ Sistema disponibilità
- ✅ Persistenza dati
- ✅ Integrazione switch

## 📊 Monitoraggio

### Statistiche Disponibili
- Contatore passi corrente (0-100)
- Numero allenatori sconfitti totali
- Allenatori disponibili per rivincita
- Mappe con allenatori tracciati
- Uso memoria stimato

### Log di Debug
Attivabile con:
```ruby
$vs_seeker.set_debug_mode(true)
```

## 🔄 Integrazione

### Con Unlimited Self Switches
- Utilizza le switch personalizzate per tracciare gli stati
- Compatibile con tutte le funzionalità esistenti

### Con Sistema di Battaglia
- Hook automatici su `pbTrainerBattle`
- Registrazione automatica allenatori sconfitti
- Supporto per tutti i tipi di allenatore

### Con Salvataggio/Caricamento
- Salvataggio automatico periodico
- Caricamento automatico all'avvio
- Backup di sicurezza dei dati

## ⚡ Performance

### Ottimizzazioni
- Controllo passi solo quando necessario
- Salvataggio dati ogni ~50 passi casuali
- Cache delle informazioni mappe
- Pulizia automatica dati corrotti

### Limiti Consigliati
- **< 100 allenatori**: Performance ottimale
- **< 500 allenatori**: Performance buona
- **> 500 allenatori**: Possibili rallentamenti

## 🛠️ Personalizzazione

### Modifica Numero Passi
Nel file `001_VSSeeker_Core.rb`, cambia:
```ruby
check_trainer_availability if @step_counter >= 100  # Cambia 100
```

### Modifica Notifiche
Nel file `003_VSSeeker_Interface.rb`:
```ruby
pbMessage(_INTL("Il VS Seeker ha rilevato..."))  # Personalizza messaggio
```

## 🚨 Risoluzione Problemi

### Problemi Comuni

**VS Seeker non funziona**
```ruby
pbVSSeekerDebug("test")  # Esegui test completo
```

**Allenatori non vengono tracciati**
```ruby
pbVSSeekerIntegrationTest  # Verifica integrazione
```

**Dati corrotti**
```ruby
pbVSSeekerIntegrityCheck  # Controlla e ripara
```

**Performance lente**
```ruby
pbVSSeekerDebug("stats")  # Controlla uso memoria
```

### Reset Completo
```ruby
$vs_seeker.reset_all_data  # Reset totale (ATTENZIONE!)
```

## 📝 Note Tecniche

- **Compatibilità**: Pokémon Essentials v20.1
- **Dipendenze**: Unlimited Self Switches Plugin
- **Memoria**: ~200 byte per allenatore tracciato
- **Salvataggio**: Automatico in `$game_variables[998]`

## 🤝 Supporto

Per problemi o domande:
1. Controlla i log di debug
2. Esegui i test automatici
3. Verifica l'integrità dei dati
4. Consulta questo README

## 📊 Versione

- **Versione**: 1.0
- **Data**: 2024
- **Autori**: elios92, assistant
- **Licenza**: Per uso con Pokémon Essentials