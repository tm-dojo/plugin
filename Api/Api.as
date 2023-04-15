namespace Api {

    void fetchAccessTokenAsync() {
        if (AccessToken != "") {
            print("Access token already set, skipping authentication.");
            return;
        }   

        // Start the task to get the token from Openplanet
        print("Getting token from Openplanet");
        Auth::PluginAuthTask@ tokenTask = Auth::GetToken();

        // Wait until the task has finished
        while (!tokenTask.Finished()) {
            yield();
        }

        // Take the token
        string token = tokenTask.Token();
        trace("Token: \"" + token + "\"");

        // Send it to the shoutbox server
        Net::HttpRequest@ req = Net::HttpPost(
            ApiUrl + "/auth/login/plugin" + "?pluginVersion=" + g_dojo.version,
            "token=" + Net::UrlEncode(token)
        );
        while (!req.Finished()) {
            yield();
        }
        
        if (req.ResponseCode() != 200 && req.ResponseCode() != 201) {
            error("Unable to authenticate, http error " + req.ResponseCode());
            return;
        }

        // Parse the server response
        Json::Value json = Json::Parse(req.String());

        // Keep track of our information, including a secret that we can use to authenticate ourselves with the shoutbox server
        // g_accountID = js["account_id"];
        // g_displayName = js["display_name"];
        AccessToken = json["access_token"];
    }
    
    // Workaround method for checkServer to ensure checkServer is only called when webId and playerLogin are not the equal
    void authenticatePluginWaitForValidWebId() {
        while (g_dojo.network.PlayerInfo.Login == g_dojo.network.PlayerInfo.WebServicesUserId) {
            sleep(50);
            yield();
        }

        startnew(Api::authenticatePlugin);
    }

    void authenticatePlugin() {
        g_dojo.checkingServer = true;

        g_dojo.playerName = g_dojo.network.PlayerInfo.Name;
        g_dojo.playerLogin = g_dojo.network.PlayerInfo.Login;
        g_dojo.webId = g_dojo.network.PlayerInfo.WebServicesUserId;

        fetchAccessTokenAsync();

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = ApiUrl + "/auth/me" + "?pluginVersion=" + g_dojo.version;
        req.Headers["Authorization"] = "Bearer " + AccessToken;
        req.Start();

        print("Starting /auth/me request...");
        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() == 200) {
            g_dojo.pluginAuthed = true;
            print("Plugin authenticated!");
            
            // Parse server response and display welcome message
            Json::Value json = Json::Parse(req.String());
            string playerName = json["playerName"];
            UI::ShowNotification("TMDojo", "Plugin authenticated!\n\nWelcome, " + playerName + "!", SUCCESS_COLOR);
        } else {
            g_dojo.pluginAuthed = false;
            UI::ShowNotification("TMDojo", "Plugin authentication failed. Error code: " + req.ResponseCode(), ERROR_COLOR);
            print("Plugin authentication failed, status code: " + req.ResponseCode());
        }

        g_dojo.serverAvailable = req.String().Length > 0;

        g_dojo.checkingServer = false;
    }

    void logout() {
        // Setup logout request
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = ApiUrl + "/auth/logout" + "?pluginVersion=" + g_dojo.version;
        req.Headers["Authorization"] = "Bearer " + AccessToken;
        req.Start();

        // Wait until the request has finished
        while (!req.Finished()) {
            yield();
        }
        
        // Notify user if logout failed
        int status = req.ResponseCode();
        if (status != 200 && status != 201) {
            UI::ShowNotification("TMDojo", "Failed to logout, please try again!", ERROR_COLOR);
            return;
        }

        // Notify user of logout and update fields
        UI::ShowNotification("TMDojo", "Plugin logged out!", SUCCESS_COLOR);
        AccessToken = "";
        g_dojo.pluginAuthed = false;
    }

    // Parse list of uint values as a string joined by a comma delimiter
    // [1,2,3,4,5] -> "1,2,3,4,5"
    string SectorTimesToString(array<uint> times) {
        string result = "";
        for (uint i = 0; i < times.Length; i++) {
            result += times[i] + "";
            if (i < times.Length - 1) {
                result += ",";
            }
        }
        return result;
    }

    void PostRecordedData(ref @handle) {

        // Copy databuffer so TMDojo can keep recording with a clean state
        g_dojo.membuff.Seek(0);
        string dataBase64 = g_dojo.membuff.ReadToBase64(g_dojo.membuff.GetSize());
        uint64 bufferSize = g_dojo.membuff.GetSize();

        g_dojo.Reset();

        // Abort if server isn't available
        if (!g_dojo.serverAvailable) {
            print("[TMDojo]: Abort upload, server not available");
            return;
        }

        // Abort if plugin is disabled
        if (!Enabled) {
            print("[TMDojo]: Abort upload, plugin disabled");
            return;
        } 
        
        // Abort save if buffer is too small
        if (bufferSize < 10000) {
            print("[TMDojo]: Not saving file, too little data");
            return;
        }

        FinishHandle @fh = cast<FinishHandle>(handle);

        // Abort save if replays contains respawns and settings is enabled to not upload replays with respawns
        if (!SaveReplaysWithRespawns && fh.respawns > 0) {
            print("[TMDojo]: Not saving file, replay contains respawns");
            return;
        }
       
        // Setup variables for upload
        bool finished = fh.finished;
        CSmScriptPlayer@ smScript = fh.smScript;
        CGamePlaygroundUIConfig@ uiConfig = fh.uiConfig;
        CGameCtnChallenge@ rootMap = fh.rootMap;
        CTrackManiaNetwork@ network = fh.network;
        int endRaceTime = fh.endRaceTime;
        array<uint> sectorTimes = fh.sectorTimes;

        print("[TMDojo]: Saving game data (size: " + bufferSize / 1024 + " kB)");

        // Setup request URL
        string mapNameClean = Regex::Replace(rootMap.MapInfo.NameForUi, "\\$([0-9a-fA-F]{1,3}|[iIoOnNmMwWsSzZtTgG<>]|[lLhHpP](\\[[^\\]]+\\])?)", "").Replace(" ", "%20");
        string reqUrl = ApiUrl + "/replays" +
                            "?mapName=" + Net::UrlEncode(mapNameClean) +
                            "&mapUId=" + rootMap.MapInfo.MapUid +
                            "&authorName=" + rootMap.MapInfo.AuthorNickName +
                            "&playerName=" + network.PlayerInfo.Name +
                            "&playerLogin=" + network.PlayerInfo.Login +
                            "&webId=" + network.PlayerInfo.WebServicesUserId +
                            "&endRaceTime=" + endRaceTime +
                            "&raceFinished=" + (finished ? "1" : "0") +
                            "&pluginVersion=" + g_dojo.version;
        
        // If sector times are available, add them to the request URL
        if (sectorTimes.Length > 0) {
            reqUrl += "&sectorTimes=" + SectorTimesToString(sectorTimes);
        }

        // Build request instance
        Net::HttpRequest req;
        req.Method = Net::HttpMethod::Post;
        req.Url = reqUrl;

        // Set body to base64 encoded memory buffer
        req.Body = dataBase64;

        // Build headers
        dictionary@ Headers = dictionary();
        Headers["Authorization"] = "Bearer " + AccessToken;
        Headers["Content-Type"] = "application/octet-stream";
        @req.Headers = Headers;

        // Start and wait until request is finished
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
}
