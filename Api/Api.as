namespace Api {
    void checkServer() {
        g_dojo.checkingServer = true;
        g_dojo.playerName = g_dojo.network.PlayerInfo.Name;
        g_dojo.playerLogin = g_dojo.network.PlayerInfo.Login;
        g_dojo.webId = g_dojo.network.PlayerInfo.WebServicesUserId;
        Net::HttpRequest@ auth = Net::HttpGet(ApiUrl + "/auth?name=" + g_dojo.playerName + "&login=" + g_dojo.playerLogin + "&webid=" + g_dojo.webId + "&sessionId=" + SessionId);
        while (!auth.Finished()) {
            yield();
            sleep(50);
        }
        if (auth.String().get_Length() > 0) {
            Json::Value json = Json::Parse(auth.String());

            if (json.GetType() != Json::Type::Null) {
                print("HasKey authUrl: " + json.HasKey("authURL"));
                print("HasKey authSuccess: " + json.HasKey("authSuccess"));

                if (json.HasKey("authURL")) {
                    try {
                        g_dojo.pluginAuthUrl = json["authURL"];
                        ClientCode = json["clientCode"];
                        SessionId = "";
                        UI::ShowNotification("TMDojo", "Plugin needs authentication!");
                    } catch {
                        error("checkServer json error");
                    }
                }
                if (json.HasKey("authSuccess")) {
                    g_dojo.pluginAuthed = true;
                    UI::ShowNotification("TMDojo", "Plugin is authenticated!", SUCCESS_COLOR);
                }
            } else {
                UI::ShowNotification("TMDojo", "checkServer() Error: Json response is null", ERROR_COLOR);
            }
            
            g_dojo.serverAvailable = true;
        } else {
            g_dojo.serverAvailable = false;
        }
        g_dojo.checkingServer = false;
    }

    void logout() {
        string logoutBody = "{\"sessionId\":\"" + SessionId + "\"}";
        Net::HttpRequest@ req = Net::HttpPost(ApiUrl + "/logout", logoutBody, "application/json");
        while (!req.Finished()) {
            yield();
            sleep(50);
        }
        
        int status = req.ResponseCode();
        if (status == 200) {
            UI::ShowNotification("TMDojo", "Plugin logged out!", SUCCESS_COLOR);
            SessionId = "";
            g_dojo.pluginAuthed = false;
            checkServer();
        } else {
            UI::ShowNotification("TMDojo", "Failed to logout, please try again!", ERROR_COLOR);
        }
    }

    void authenticatePlugin() {
        OpenBrowserURL(g_dojo.pluginAuthUrl);
        startnew(getPluginAuth);
    }

    void getPluginAuth() {
        g_dojo.isAuthenticating = true;
        while (g_dojo.checkSessionIdCount < MAX_CHECK_SESSION_ID) {
            sleep(1000);
            g_dojo.checkSessionIdCount++;
            Net::HttpRequest@ auth = Net::HttpGet(ApiUrl + "/auth/pluginSecret?clientCode=" + ClientCode);
            while (!auth.Finished()) {
                yield();
                sleep(50);
            }
            try {
                Json::Value json = Json::Parse(auth.String());
                SessionId = json["sessionId"];
                UI::ShowNotification("TMDojo", "Plugin is authenticated!", SUCCESS_COLOR, 10000);
                g_dojo.pluginAuthed = true;
                ClientCode = "";
                break;
            } catch {
                
            }
        }
        g_dojo.isAuthenticating = false;
        if (g_dojo.checkSessionIdCount >= MAX_CHECK_SESSION_ID) {
            UI::ShowNotification("TMDojo", "Plugin authentication took too long, please try again", ERROR_COLOR, 10000);
            g_dojo.checkSessionIdCount = 0;
        }
    }

    void PostRecordedData(ref @handle) {
        g_dojo.recording = false;

        if (!g_dojo.serverAvailable || !Enabled) {
            g_dojo.latestRecordedTime = -6666;
            g_dojo.membuff.Resize(0);
            return;
        }

        FinishHandle @fh = cast<FinishHandle>(handle);
        bool finished = fh.finished;
        CSmScriptPlayer@ sm_script = fh.sm_script;
        CGamePlaygroundUIConfig@ uiConfig = fh.uiConfig;
        CGameCtnChallenge@ rootMap = fh.rootMap;
        CTrackManiaNetwork@ network = fh.network;
        int endRaceTime = fh.endRaceTime;

        if (g_dojo.membuff.GetSize() < 10000) {
            print("[TMDojo]: Not saving file, too little data");
            g_dojo.membuff.Resize(0);
            g_dojo.latestRecordedTime = -6666;
            g_dojo.currentRaceTime = -6666;
            g_dojo.recording = false;
            return;
        }
        if (!OnlySaveFinished || finished) {
            print("[TMDojo]: Saving game data (size: " + g_dojo.membuff.GetSize() / 1024 + " kB)");
            g_dojo.membuff.Seek(0);
            string mapNameClean = Regex::Replace(rootMap.MapInfo.NameForUi, "\\$([0-9a-fA-F]{1,3}|[iIoOnNmMwWsSzZtTgG<>]|[lLhHpP](\\[[^\\]]+\\])?)", "").Replace(" ", "%20");
            string reqUrl = ApiUrl + "/replays" +
                                "?mapName=" + Net::UrlEncode(mapNameClean) +
                                "&mapUId=" + rootMap.MapInfo.MapUid +
                                "&authorName=" + rootMap.MapInfo.AuthorNickName +
                                "&playerName=" + network.PlayerInfo.Name +
                                "&playerLogin=" + network.PlayerInfo.Login +
                                "&webId=" + network.PlayerInfo.WebServicesUserId +
                                "&endRaceTime=" + endRaceTime +
                                "&raceFinished=" + (finished ? "1" : "0");
            // build up request instance
            Net::HttpRequest req;
            req.Method = Net::HttpMethod::Post;
            req.Url = reqUrl;
            req.Body = g_dojo.membuff.ReadToBase64(g_dojo.membuff.GetSize());
            dictionary@ Headers = dictionary();
            Headers["Authorization"] = "dojo " + SessionId;
            Headers["Content-Type"] = "application/octet-stream";
            @req.Headers = Headers;
            req.Start();
            while (!req.Finished()) {
                yield();
            }

            // Handle error status codes
            int status = req.ResponseCode();
            if (status == 401) {
                UI::ShowNotification("TMDojo", "Upload failed. Not authorized, please log in if you are not logged in.", ERROR_COLOR);
            } else if (status != 200) {
                UI::ShowNotification("TMDojo", "Upload failed, status code: " + status, ERROR_COLOR);
            } else {
                UI::ShowNotification("TMDojo", "Uploaded replay successfully!", SUCCESS_COLOR);
            }
        }
        g_dojo.recording = false;
        g_dojo.latestRecordedTime = -6666;
        g_dojo.currentRaceTime = -6666;
        g_dojo.membuff.Resize(0);
    }
}
