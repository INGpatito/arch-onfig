# arch-onfig

Mis configuraciones personales para **Arch Linux** con [Caelestia](https://github.com/caelestia-dots) + Hyprland.

## Estructura

```
.config/caelestia/
├── hypr-user.conf        # Keybinds y reglas de ventana personales
├── hypr-user.lua         # Mismo contenido en formato Lua (caelestia hl)
├── hypr-vars.conf        # Variables de Hyprland
├── hypr-vars.lua         # Variables en Lua
├── shell.json            # Configuración del shell de Caelestia (apariencia, widgets)
├── cli.json              # Configuración de la CLI de Caelestia
├── user-config.fish      # Config personal de Fish shell
└── monitors/             # Config de shell por monitor
    ├── eDP-1/
    ├── HDMI-A-1/
    └── WAYLAND-1/

.local/bin/
└── omen-*.sh             # Scripts personales del sistema (BlackArch, hotspot, scrcpy, etc.)
```

## Instalación

Clonar y copiar a sus ubicaciones correspondientes:

```bash
git clone https://github.com/INGpatito/arch-onfig.git
cd arch-onfig

# Configs de caelestia
cp -r .config/caelestia/* ~/.config/caelestia/

# Scripts personales
cp .local/bin/omen-* ~/.local/bin/
chmod +x ~/.local/bin/omen-*
```

## Dependencias notables

- [Caelestia](https://github.com/caelestia-dots/shell) — Shell de Hyprland
- `foot` — Emulador de terminal
- `grim` + `slurp` + `swappy` — Capturas de pantalla
- `scrcpy` — Proyección de pantalla Android
- `qalculate-gtk` — Calculadora
