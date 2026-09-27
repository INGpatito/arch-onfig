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
├── victus-fan-profile.py         # Daemon de ventiladores (performance=MAX, balanced=AUTO)
├── omen-blackarch-toggle.sh      # Activa/desactiva modo BlackArch aislado (pide contraseña)
├── omen-blackarch-build.sh       # Construye el rootfs de BlackArch
├── omen-blackarch-env.sh         # Lanza shell interactiva en BlackArch
├── omen-blackarch-standalone.sh  # Modo standalone
├── omen-blackarch-wallpaper-cycle.sh
├── omen-hotspot-toggle.sh        # Crea/apaga Hotspot WiFi
├── omen-low-resource-toggle.sh   # Modo bajos recursos (mata Caelestia, lanza Waybar)
└── omen-scrcpy.sh                # Proyecta teléfono Android (USB/WiFi/Tailscale)

etc/pam.d/
├── hyprlock      # Login con Google Authenticator (contraseña dinámica TOTP)
├── swaylock      # Mismo para swaylock
├── quickshell    # Mismo para quickshell
├── qs            # Alias de quickshell
└── greetd        # Pantalla de login del sistema

system/
├── install-victus-fan-sync.sh    # Instala el daemon de ventiladores como servicio systemd
└── uninstall-victus-fan-sync.sh  # Desinstala el servicio
```

## Características

- **🔒 Login con Google Authenticator** — Contraseña dinámica TOTP en hyprlock/swaylock/greetd vía PAM
- **🌀 Control de ventiladores** — `victus-fan-profile.py` escucha D-Bus de `power-profiles-daemon`:
  - Perfil `performance` → ventiladores al **MAX (100%)**
  - Perfil `balanced` / `power-saver` → ventiladores en **AUTO (BIOS)**
- **🟢 Modo BlackArch** — Sistema aislado en contenedor `systemd-nspawn` con tema visual propio
- **⌨️ Atajos personalizados** — Ver `hypr-user.conf` o `hypr-user.lua`

## Instalación

```bash
git clone https://github.com/INGpatito/arch-onfig.git
cd arch-onfig

# Configs de caelestia
cp -r .config/caelestia/* ~/.config/caelestia/

# Scripts personales
cp .local/bin/* ~/.local/bin/
chmod +x ~/.local/bin/omen-* ~/.local/bin/victus-fan-profile.py

# PAM (requiere sudo) - habilita Google Authenticator en el lockscreen
sudo cp etc/pam.d/* /etc/pam.d/

# Servicio de ventiladores (requiere sudo)
sudo bash system/install-victus-fan-sync.sh
```

> ⚠️ **IMPORTANTE:** El archivo `~/.google_authenticator` (la clave secreta TOTP) NO está en este repo por seguridad. Debes generarlo en el nuevo sistema con `google-authenticator`.

## Dependencias notables

- [Caelestia](https://github.com/caelestia-dots/shell) — Shell de Hyprland
- `libpam-google-authenticator` — Login con TOTP
- `power-profiles-daemon` — Gestión de perfiles de energía
- `python-gobject` — Para el daemon de ventiladores
- `foot` — Emulador de terminal
- `grim` + `slurp` + `swappy` — Capturas de pantalla
- `scrcpy` — Proyección de pantalla Android
- `systemd-nspawn` — Contenedor para BlackArch
