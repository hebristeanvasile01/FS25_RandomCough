# FS25 Random Cough

A Farming Simulator 25 mod. Your farmer coughs from time to time, at a random moment.

## Features

- Separate cough sounds for male and female characters, picked automatically from your character
- A cough every 3 to 10 minutes (real time), in the cab and on foot
- No menu and no setup
- Multiplayer supported: every player hears their own cough
- Languages: English, German

## Settings

The interval and the female model detection are at the top of `scripts/RandomCough.lua`.
Volume per voice is in `xml/sounds.xml` (`volumeScale`).

Console commands (open the console with the `~` key):

- `rcCough [male|female]` plays a cough now
- `rcCoughGender [auto|male|female]` forces the voice
- `rcCoughInterval [minMinutes] [maxMinutes]` changes the time between coughs

The detected character model is written to `log.txt` as `[RandomCough] Character model ...`.

## Installation

Download the mod from ModHub / KingMods, or zip the repository contents so that `modDesc.xml` is at the root of the archive, and name it `FS25_RandomCough.zip`. Put it in `Documents/My Games/FarmingSimulator2025/mods`.

## Credits

Author: FS Modding.
