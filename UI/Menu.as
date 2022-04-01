void RenderMenu()
{
    string menuTitle = "";
    if (g_dojo.checkingServer) {
        menuTitle = ORANGE + Icons::Wifi + "\\$z TMDojo";
    } else {
        menuTitle = (g_dojo.serverAvailable ? GREEN : RED) + Icons::Wifi + "\\$z TMDojo";
    }

    if (UI::BeginMenu(menuTitle)) {
		if (UI::MenuItem(Enabled ? "Turn OFF" : "Turn ON", "", false, true)) {
            Enabled = !Enabled;
            if (Enabled) {
                startnew(Api::checkServerWaitForValidWebId);
            }
		}

        string otherApi = ApiUrl == LOCAL_API ? REMOTE_API : LOCAL_API;
        string otherUi = ApiUrl == LOCAL_API ? REMOTE_UI : LOCAL_UI;
        if (DevMode && UI::MenuItem("Switch to " + otherApi + " " + otherUi , "", false, true)) {
            ApiUrl = otherApi;
            UiUrl = otherUi;
            startnew(Api::checkServerWaitForValidWebId);
		}

        if (UI::MenuItem(OverlayEnabled ? "[X]  Overlay" : "[  ]  Overlay", "", false, true)) {
            OverlayEnabled = !OverlayEnabled;
		}

        if (DevMode && UI::MenuItem(DebugOverlayEnabled ? "[X]  Debug Overlay" : "[  ]  Debug Overlay", "", false, true)) {
            DebugOverlayEnabled = !DebugOverlayEnabled;
		}

        if (UI::MenuItem(OnlySaveFinished ? "[X]  Save finished runs only" : "[  ]  Save finished runs only", "", false, true)) {
            OnlySaveFinished = !OnlySaveFinished;
		}

        if (!g_dojo.serverAvailable && !g_dojo.checkingServer) {
            if (UI::MenuItem("Check server", "", false, true)) {
                startnew(Api::checkServerWaitForValidWebId);
            }
        }

        if (g_dojo.pluginAuthed) {
            if (UI::MenuItem(GREEN + Icons::Plug + " Plugin Authenticated")) {
                g_dojo.authWindowOpened = true;
            }
            if (UI::MenuItem(ORANGE + Icons::SignOut + " Logout")) {
               startnew(Api::logout);
            }
        } else {
            if (UI::MenuItem(ORANGE + Icons::Plug + " Authenticate Plugin")) {
                g_dojo.authWindowOpened = true;
            }
        }

		UI::EndMenu();
	}
}