-- Hyprland key bindings shared by every Omarchy machine. install.sh links this
-- file as ~/.config/hypr/shared-bindings.lua. Each machine's own
-- ~/.config/hypr/bindings.lua loads it with require("hypr.shared-bindings")
-- before its machine-specific bindings, so those can override these.

-- Vim motions: Super+H/J/K/L move focus, and adding Shift swaps the focused
-- window with its neighbor, the same as Omarchy's Super+arrow keys. The
-- defaults these keys replace:
--   Super+L (cycle workspace layout): Super+Alt+L still cycles the layouts.
--   Super+J (toggle window split): moved to Super+Alt+J.
--   Super+K (keybindings menu): Omarchy menu > Learn > Keybindings.
-- Super+Ctrl+L locks the screen (Omarchy's default).
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.rebind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.rebind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.rebind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Scrolling layout: Super+[ and Super+] move the focused window toward that
-- side: into the neighboring column when it has a column to itself, or out
-- into a column of its own when it shares one.
o.bind("SUPER + code:34", "Move window into or out of left column", hl.dsp.layout("consume_or_expel prev"))
o.bind("SUPER + code:35", "Move window into or out of right column", hl.dsp.layout("consume_or_expel next"))
