# NEON SIN

A 2D side-scrolling game developed with **Godot Engine**.

This project is created as a game development learning project, focusing on gameplay programming, character movement, combat, UI/HUD, enemy and boss systems, and overall game design.

## 🎮 Features

* 2D side-scrolling gameplay
* Player movement and jumping
* Stamina system
* Player HP system
* Combat system
* Damage / hit system (get-hit animation, knockback, control stun)
* Death system (death animations, level restart, boss removal)
* Enemy system
* Boss system (detection, chase, attack with cooldown)
* Boss HP bar (connected and updating)
* Player HP / SP HUD
* Character UI
* Main menu with animated background
* Settings panel (music / SFX / voice volume, saved to file)
* Audio system (music, sound effects, voice channels)
* Pixel-art based visual style

## 🛠️ Built With

* **Godot Engine**
* **GDScript**
* 2D / CanvasLayer UI
* Pixel Art

## 📁 Project Structure 

```text
neon-sin/
├── art/                  # Sprites, UI assets, menu assets
├── audio/                # Music and sound effects
│   ├── music/
│   └── sfx/
├── scenes/
│   ├── enemies/          # Boss scene
│   ├── levels/           # Level scenes
│   ├── menu/             # Main menu scene
│   ├── player/           # Player scene
│   └── ui/               # HUD, boss HUD, menu UI
├── scripts/
│   ├── enemies/          # Boss AI
│   ├── levels/           # Level scripts
│   ├── player/           # Player controller
│   └── ui/               # Menu, HUD scripts
├── default_bus_layout.tres
├── project.godot
└── README.md
```

## 🎯 Current Development

The project is currently under development.

### Implemented

* [x] Basic player movement
* [x] Jumping
* [x] Stamina system
* [x] Player HP system
* [x] Player HUD
* [x] Boss HP bar
* [x] Basic UI system
* [x] Player combat
* [x] Boss AI (detect, chase, attack, cooldown)
* [x] Damage / hit system (get-hit animation + knockback)
* [x] Death system (player restart, boss removal)
* [x] Main menu (logo, start / settings / exit)
* [x] Settings with volume sliders (Music / SFX / Voice)
* [x] Background music (menu + level, looping)
* [x] Sound effects (attack voice, hit sound)
* [x] Escape to return to main menu

### In Progress

* [ ] Level design
* [ ] Checkpoint system
* [ ] Game progression
* [ ] Visual effects (VFX)
* [ ] Pause menu
* [ ] More enemies and boss variety

## 🚀 Running the Project

### Requirements

* Godot Engine 4.x

### Steps

1. Clone the repository:

```bash
git clone https://github.com/namtit2932k/neon-sin.git
```

2. Open **Godot Engine**.

3. Select **Import**.

4. Choose the project's `project.godot` file.

5. Press **F6** to run the current scene or **F5** to run the main project.

## 🎮 Controls

| Action | Key |
|---|---|
| Move left / right | `A` / `D` |
| Jump | `Space` |
| Run | `Shift` |
| Attack | `J` |
| Back to main menu (in level) | `Escape` |

## 🎨 Development Goals

The main goals of this project are:

* Learn and practice Godot Engine
* Improve gameplay programming skills
* Learn game systems design
* Practice UI/HUD implementation
* Build a complete playable prototype
* Create a portfolio project demonstrating game development skills

## 📌 Status

**In Development**

More gameplay systems, content, visual effects, and polish will be added as development continues.

## 📄 License

This project is currently intended for learning and portfolio purposes.
