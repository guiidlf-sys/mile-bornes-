# Mille Bornes — Roblox

Une adaptation du jeu de cartes français **Mille Bornes** pour Roblox, jouable en multijoueur (2 à 4 joueurs), avec le moteur de règles complet côté serveur : cartes Bornes, Attaques (Accident, Panne d'essence, Crevaison, Limite de vitesse, Stop), Parades, cartes Coup Fourré, et système de score.

## Structure du projet

Le code est organisé pour être synchronisé dans Roblox Studio avec [Rojo](https://rojo.space/) :

```
default.project.json
src/
  ReplicatedStorage/Shared/   -- code partagé client/serveur
    CardData.luau              -- catalogue des 106 cartes + construction du deck
    GameConstants.luau         -- règles paramétrables (distance cible, tailles de main, etc.)
    Remotes.luau                -- RemoteEvents partagés
  ServerScriptService/         -- logique serveur (autoritaire)
    Main.server.luau
    Modules/
      GameManager.luau          -- lobby, ready-check, routage réseau
      Match.luau                 -- moteur de règles d'une partie
      Shuffle.luau                -- mélange Fisher-Yates
  StarterPlayer/StarterPlayerScripts/  -- interface client
    Main.client.luau
    UI/
      Theme.luau
      Widgets.luau
      LobbyUI.luau
      GameUI.luau
```

## Ouvrir le projet dans Roblox Studio

1. Installez [Rojo](https://rojo.space/docs/installation/) (extension VS Code ou binaire CLI, et le plugin Roblox Studio correspondant).
2. Depuis la racine du dépôt, lancez le serveur Rojo :
   ```
   rojo serve
   ```
3. Dans Roblox Studio, ouvrez le plugin Rojo et cliquez sur **Connect** pour synchroniser `default.project.json` dans un nouveau lieu (place).
4. Lancez un test multijoueur via **Test > Start** avec plusieurs clients (au moins 2) pour jouer une partie complète.

## Règles implémentées

- Pioche automatique en début de tour, main limitée à 6 cartes.
- Cartes Bornes (25/50/75/100/200 km), objectif 1000 km exact (impossible de dépasser).
- Attaques : Accident, Panne d'essence, Crevaison, Limite de vitesse (50 km/carte max), Stop — jouables uniquement si la cible est en mesure de les recevoir.
- Parades : Réparations, Essence, Roue de secours, Fin de limite, Bornes (Roulez).
- 4 cartes Sécurité (As du volant, Réservoir increvable, Increvable, Priorité), donnant l'immunité correspondante et un tour supplémentaire dès qu'elles sont jouées.
- **Coup Fourré** : si vous avez la carte Sécurité correspondante en main au moment où une attaque vous touche, une fenêtre de réponse s'ouvre (8 s) pour riposter immédiatement, avec bonus de 300 points et tour supplémentaire.
- Score final : distance parcourue + 300 (partie terminée) + 100 par sécurité (+300 si les 4) + 500 (manche sèche, si tous les adversaires sont restés à 0 km) + bonus des Coups Fourrés.
- Lobby avec système "Prêt" et décompte de 10 s avant le début de la partie (2 à 4 joueurs).

## Idées d'évolution

- Extension 1000 + 200 km avec cartes bonus.
- IA / bots pour jouer en solo.
- Historique de scores persistant (DataStore).
- Animations de cartes et effets sonores.
