void renderAuthWindow() {
    UI::SetNextWindowContentSize(780, 230);
    UI::Begin("TMDojo Plugin Authentication", g_dojo.authWindowOpened);
    if (!g_dojo.pluginAuthed) {
        UI::Text(ORANGE + "Not authenticated");
        UI::Text("");
        UI::Text("In order to upload your replays to TMDojo, you need to tell us who you are.");
        UI::Text("Please click the \"Authenticate Plugin\" button below - it will open a browser window for you to log into your Ubisoft account.");
        UI::Text("Don't worry: This only gives us access to your accountID and your name!");
        UI::Text("");
        UI::Text("Once you've clicked the button, you have one minute to log in.");
        UI::Text("If it takes a bit longer, you can just press the button again (if you're already logged in, it's just gonna take a second).");
        UI::Text("");
        if (!g_dojo.isAuthenticating && UI::Button("Authenticate Plugin")) {
            Api::authenticatePluginWithBrowser();
        }
        if (g_dojo.isAuthenticating) {
            UI::Text("Awaiting authentication, " + (MAX_CHECK_SESSION_ID - g_dojo.checkSessionIdCount) + " seconds remaining");
        }
    } else {
        UI::Text(GREEN + "Plugin authed!");
        UI::Text("");
        UI::Text("Welcome " + g_dojo.playerName + ", you can now upload replays to the TMDojo!");
        UI::Text("");

        if (UI::Button("My profile")) {
            OpenBrowserURL(UiUrl + "/users/" + g_dojo.webId);
        }
    }
    UI::End();
}