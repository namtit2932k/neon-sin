# NEON SIN

A 2D side-scrolling game developed with **Godot Engine**.

This project is created as a game development learning project, focusing on gameplay programming, character movement, combat, UI/HUD, enemy and boss systems, and overall game design.

## 🎮 Features

* 2D side-scrolling gameplay with movement, jump, run and dash
* Combat system with hit feedback (knockback, control stun, death)
* Boss AI (detection, chase, attack with cooldown) and boss HP bar
* Stamina and HP systems with player HUD
* Main menu with animated background
* Pause menu (resume / settings / quit / main menu)
* Settings screen (Music / SFX / Voice volume, saved to file)
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
│   ├── menu/             # Main menu, pause, settings scenes
│   ├── player/           # Player scene
│   └── ui/               # HUD, boss HUD
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

* [x] Player movement, jump, run and dash
* [x] Stamina and HP systems with player HUD
* [x] Player combat, damage / hit system and death system
* [x] Boss AI with HP bar
* [x] Main menu with animated background
* [x] Pause menu (Escape) and settings screen shared by both menus
* [x] Audio system: looping music, attack voice and hit SFX

### In Progress

* [ ] Level design
* [ ] Checkpoint system
* [ ] Game progression
* [ ] Visual effects (VFX)
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
| Dash (tap) | `Shift` |
| Run (hold) | `Shift` |
| Attack | `J` |
| Pause / resume (in level) | `Escape` |

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
