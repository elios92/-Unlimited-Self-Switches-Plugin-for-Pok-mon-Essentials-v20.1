# Unlimited Self Switches Plugin for Pokémon Essentials v20.1

## 📋 Descrizione

Questo plugin estende il sistema di Self Switches standard di Pokémon Essentials (A, B, C, D) permettendo di creare un **numero illimitato** di switch personalizzate con nomi personalizzati.

## ✨ Caratteristiche Principali

- **Switch illimitate**: Crea switch con nomi personalizzati (max 10 caratteri)
- **Gestione avanzata**: Sistema completo di creazione, modifica, rinomina ed eliminazione
- **Condizioni speciali**: Timer, variabili, switch di gioco, inventario
- **Processore automatico**: Sistema che controlla e attiva le condizioni in tempo reale
- **Interfaccia utente**: Menu intuitivi per la gestione completa
- **Compatibilità**: Funziona insieme alle switch standard A, B, C, D

## 📁 Struttura File

- `UnlimitedSelfSwitches.rb` - Sistema principale e interprete comandi
- `001_UnlimitedSelfSwitches.rb` - Gestore delle switch e interfaccia utente
- `002_UnlimitedSelfSwitchesEvents.rb` - Gestione eventi e condizioni speciali
- `003_UnlimitedSelfSwitchesConditionProcessor.rb` - Processore automatico delle condizioni

## 🚀 Installazione

1. Copia tutti i file `.rb` nella cartella `Plugins` del tuo progetto Pokémon Essentials
2. Il plugin si attiverà automaticamente al prossimo avvio del gioco

## 📖 Come Usare

### Sintassi Base nei Commenti Eventi

```ruby
Switch: NOME_SWITCH = ON
Switch: NOME_SWITCH = OFF
```

### Comandi Principali

- `pbManageCustomSwitches` - Menu principale per gestire tutte le switch
- `pbConditionProcessorDebug` - Statistiche e debug del processore
- `pbCleanupConditions` - Pulisce condizioni non valide
- `pbForceConditionCheck` - Forza il controllo delle condizioni

### Tipi di Condizioni Speciali

1. **Timer**: Attiva/disattiva dopo un tempo specificato
2. **Variabili**: Basata sul valore di variabili di gioco
3. **Switch di Gioco**: Collegata a switch standard del gioco
4. **Inventario**: Basata sulla quantità di item posseduti

## 🛠️ Esempio Pratico

```ruby
# In un evento, nei commenti:
Switch: PORTA1 = ON

# Per gestire via script:
pbManageCustomSwitches

# Per debug:
pbConditionProcessorDebug(true)  # Attiva debug
pbConditionProcessorDebug(false) # Disattiva debug
pbConditionProcessorDebug        # Mostra statistiche
```

## 🔧 Configurazione Avanzata

Il sistema utilizza la variabile globale `$game_variables[999]` per memorizzare le condizioni speciali. Il processore controlla le condizioni ogni secondo automaticamente.

## 📊 Versione

- **Versione**: 1.1
- **Compatibilità**: Pokémon Essentials v20.1
- **Autori**: mej71, adattato da elios92 & assistant

## 🐛 Debug e Risoluzione Problemi

- Usa `pbConditionProcessorDebug` per monitorare le condizioni attive
- `pbCleanupConditions` rimuove condizioni corrotte o scadute
- I log di debug vengono mostrati nella console quando attivati

## 📝 Note Tecniche

- Le switch personalizzate sono memorizzate in `$game_self_switches`
- Il processore si integra automaticamente con `Scene_Map`
- Sistema di backup automatico per condizioni timer scadute
- Supporto completo per save/load del gioco
