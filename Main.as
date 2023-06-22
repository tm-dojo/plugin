TMDojo@ g_dojo;

void Main() {
    @g_dojo = TMDojo();
    print("TMDojo v" + g_dojo.version + " Init ");
}

void Update(float dt) {
    if (g_dojo !is null && Enabled) {
		g_dojo.Update(dt);
	}
    
    // DependencyNotifier::NotifyMissingPlayerStateDependency();
}

void RenderInterface() {
    if (g_dojo.authWindowOpened) {
        renderAuthWindow();
    }
    if (DebugOverlayEnabled) {
        renderDebugOverlay();
    }
}