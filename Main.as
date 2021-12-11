TMDojo@ g_dojo;

void Main() {
    @g_dojo = TMDojo();
    print("TMDojo_v2 Init");
}

void Render() {
    if (g_dojo !is null && Enabled) {
		g_dojo.Render();
	}
}

void RenderInterface() {
    if (g_dojo.authWindowOpened) {
        renderAuthWindow();
    }
    if (DebugOverlayEnabled) {
        renderDebugOverlay();
    }
}