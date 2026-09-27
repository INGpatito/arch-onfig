if hl then

-- Boot-time visual login via Caelestia lockscreen
hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 2 && caelestia shell lock lock")
    -- Idle daemon: controla DPMS y previene freeze de NVIDIA en idle
    hl.exec_cmd("pidof hypridle || hypridle")
end)
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))

-- ─── OMEN BlackArch System ────────────────────────────────────────────────────
local ba_toggle = hl.dsp.exec_cmd("foot --title \"BlackArch Mode Toggle\" --fullscreen ~/.local/bin/omen-blackarch-toggle.sh")
local ba_shell = hl.dsp.exec_cmd("foot --title \"BlackArch Shell\" ~/.local/bin/omen-blackarch-env.sh")

hl.bind("SUPER + XF86Launch2", ba_toggle)
hl.bind("SUPER + XF86Launch1", ba_toggle)
hl.bind("XF86Launch2", ba_shell)
hl.bind("XF86Launch1", ba_shell)

hl.window_rule({ match = { title = "BlackArch Mode Toggle" }, float = true, size = "900 600", center = true })
hl.window_rule({ match = { title = "BlackArch Shell" }, float = true, size = "1200 700", center = true })

hl.window_rule({ match = { class = "scrcpy" }, float = true, size = "380 800", center = true })

hl.bind("SUPER + ALT + KP_1", hl.dsp.exec_cmd("~/.local/bin/omen-scrcpy.sh"))
hl.bind("SUPER + ALT + KP_End", hl.dsp.exec_cmd("~/.local/bin/omen-scrcpy.sh"))

hl.bind("SUPER + ALT + KP_2", hl.dsp.exec_cmd("GDK_BACKEND=x11 mousepad --class=floating-notes"))
hl.bind("SUPER + ALT + KP_Down", hl.dsp.exec_cmd("GDK_BACKEND=x11 mousepad --class=floating-notes"))

hl.window_rule({ match = { class = "floating-notes" }, float = true, size = "800 600", center = true })

hl.bind("XF86Calculator", hl.dsp.exec_cmd("qalculate-gtk"))

hl.window_rule({ match = { class = "qalculate-gtk" }, float = true, size = "380 550", center = true })

hl.bind("SUPER + ALT + KP_3", hl.dsp.exec_cmd("xdg-open \"https://docs.google.com/document/\""))
hl.bind("SUPER + ALT + KP_Next", hl.dsp.exec_cmd("xdg-open \"https://docs.google.com/document/\""))
hl.bind("SUPER + ALT + KP_Page_Down", hl.dsp.exec_cmd("xdg-open \"https://docs.google.com/document/\""))

hl.bind("SUPER + ALT + KP_4", hl.dsp.exec_cmd("/home/pato/gentoo-kvm/boot_system.sh"))
hl.bind("SUPER + ALT + KP_Left", hl.dsp.exec_cmd("/home/pato/gentoo-kvm/boot_system.sh"))

hl.bind("SUPER + ALT + 6", hl.dsp.exec_cmd("/home/pato/freebsd-kvm/boot_system.sh"))
hl.bind("SUPER + ALT + KP_6", hl.dsp.exec_cmd("/home/pato/freebsd-kvm/boot_system.sh"))
hl.bind("SUPER + ALT + KP_Right", hl.dsp.exec_cmd("/home/pato/freebsd-kvm/boot_system.sh"))

hl.bind("SUPER + ALT + KP_Decimal", hl.dsp.exec_cmd("~/.local/bin/omen-hotspot-toggle.sh"))
hl.bind("SUPER + ALT + KP_Delete", hl.dsp.exec_cmd("~/.local/bin/omen-hotspot-toggle.sh"))

hl.bind("SUPER + y", hl.dsp.exec_cmd("foot -T \"Yazi\" /usr/bin/yazi"))
hl.bind("SUPER + ALT + KP_0", hl.dsp.exec_cmd("~/.local/bin/omen-low-resource-toggle.sh"))
hl.bind("SUPER + ALT + KP_Insert", hl.dsp.exec_cmd("~/.local/bin/omen-low-resource-toggle.sh"))

end
