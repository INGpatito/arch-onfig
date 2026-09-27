#!/usr/bin/env python3
import glob
import logging
import signal
import sys
from gi.repository import GLib, Gio

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

def get_pwm_enable_path():
    matches = glob.glob("/sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1_enable")
    if matches:
        return matches[0]
    return None

def set_fan_mode(profile_name):
    # Performance mode -> 0 (Max / Boost 100%)
    # Balanced / Power-saver -> 2 (Auto / BIOS controlled)
    target_value = "0" if profile_name == "performance" else "2"
    mode_label = "MAX (100%)" if target_value == "0" else "AUTO (BIOS)"
    
    path = get_pwm_enable_path()
    if not path:
        logging.error("No se encontró la ruta de control pwm1_enable de hp-wmi")
        return False

    try:
        with open(path, "w") as f:
            f.write(target_value)
        logging.info("Perfil '%s' -> Ventiladores configurados en %s", profile_name, mode_label)
        return True
    except PermissionError:
        logging.warning("Permiso denegado al escribir en %s. El servicio debe ejecutarse como root.", path)
        return False
    except Exception as e:
        logging.error("Error al escribir en %s: %s", path, e)
        return False

def on_properties_changed(connection, sender_name, object_path, interface_name, signal_name, parameters):
    if interface_name == "org.freedesktop.DBus.Properties" and signal_name == "PropertiesChanged":
        target_iface, changed_props, _ = parameters.unpack()
        if target_iface == "net.hadess.PowerProfiles":
            if "ActiveProfile" in changed_props:
                new_profile = changed_props["ActiveProfile"]
                set_fan_mode(new_profile)

def on_prepare_for_sleep(connection, sender_name, object_path, interface_name, signal_name, parameters, user_data):
    going_to_sleep, = parameters.unpack()
    if not going_to_sleep:
        proxy = user_data
        current_prop = proxy.get_cached_property("ActiveProfile")
        profile = current_prop.unpack() if current_prop else "balanced"
        logging.info("Reanudando de suspensión. Reaplicando perfil: %s", profile)
        set_fan_mode(profile)

def main():
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    
    proxy = Gio.DBusProxy.new_sync(
        bus,
        Gio.DBusProxyFlags.NONE,
        None,
        "net.hadess.PowerProfiles",
        "/net/hadess/PowerProfiles",
        "net.hadess.PowerProfiles",
        None
    )
    
    current_prop = proxy.get_cached_property("ActiveProfile")
    initial_profile = current_prop.unpack() if current_prop else "balanced"
    logging.info("Iniciando servicio victus-fan-profile...")
    logging.info("Perfil inicial detectado: %s", initial_profile)
    set_fan_mode(initial_profile)

    # Escuchar cambios de perfil (emitidos cuando Caelestia cambia de modo)
    bus.signal_subscribe(
        "net.hadess.PowerProfiles",
        "org.freedesktop.DBus.Properties",
        "PropertiesChanged",
        "/net/hadess/PowerProfiles",
        None,
        Gio.DBusSignalFlags.NONE,
        on_properties_changed
    )

    # Escuchar reanudación tras suspensión
    bus.signal_subscribe(
        "org.freedesktop.login1",
        "org.freedesktop.login1.Manager",
        "PrepareForSleep",
        "/org/freedesktop/login1",
        None,
        Gio.DBusSignalFlags.NONE,
        on_prepare_for_sleep,
        proxy
    )

    loop = GLib.MainLoop()

    def handle_shutdown(signum, frame):
        logging.info("Señal de apagado (%s). Restaurando ventiladores a AUTO...", signum)
        set_fan_mode("balanced")
        loop.quit()

    signal.signal(signal.SIGTERM, handle_shutdown)
    signal.signal(signal.SIGINT, handle_shutdown)

    try:
        loop.run()
    except (KeyboardInterrupt, SystemExit):
        handle_shutdown(0, None)

if __name__ == "__main__":
    main()
