class TMDojo
{
    bool recording = false;
    MemoryBuffer membuff = MemoryBuffer(0);

    int prevRaceTime = -6666;
    int currentRaceTime = -6666;
    int latestRecordedTime = -6666;
    CTrackManiaNetwork@ network;


    // Player info
    string playerName;
    string playerLogin;
    string webId;

    // Idle detection
    vec3 latestPlayerPosition;
    int numSamePositions = 0;

    // Server status
    bool serverAvailable = false;
    bool checkingServer = false;

    // Session
    int checkSessionIdCount = 0;
    int maxCheckSessionId = 60;

    string pluginAuthUrl = "";

    bool pluginAuthed = false;
    bool isAuthenticating = false;
    bool authWindowOpened = false;

    TMDojo() {
        auto app = GetApp();
        @network = cast<CTrackManiaNetwork>(app.Network);
        startnew(Api::checkServer);
    }

    void FillBuffer(CSceneVehicleVis@ vis, CSmScriptPlayer@ sm_script) {
        int gazAndBrake = 0;
        int gazPedal = vis.AsyncState.InputGasPedal > 0 ? 1 : 0;
        int isBraking = vis.AsyncState.InputBrakePedal > 0 ? 2 : 0;

        gazAndBrake |= gazPedal;
        gazAndBrake |= isBraking;

        membuff.Write(g_dojo.currentRaceTime);

        membuff.Write(vis.AsyncState.Position.x);
        membuff.Write(vis.AsyncState.Position.y);
        membuff.Write(vis.AsyncState.Position.z);

        membuff.Write(vis.AsyncState.WorldVel.x);
        membuff.Write(vis.AsyncState.WorldVel.y);
        membuff.Write(vis.AsyncState.WorldVel.z);

        membuff.Write(vis.AsyncState.FrontSpeed * 3.6f);

        membuff.Write(vis.AsyncState.InputSteer);
        membuff.Write(vis.AsyncState.FLSteerAngle);

        membuff.Write(gazAndBrake);

        membuff.Write(Vehicle::GetRPM(vis.AsyncState));
        membuff.Write(vis.AsyncState.CurGear);

        membuff.Write(vis.AsyncState.Up.x);
        membuff.Write(vis.AsyncState.Up.y);
        membuff.Write(vis.AsyncState.Up.z);

        membuff.Write(vis.AsyncState.Dir.x);
        membuff.Write(vis.AsyncState.Dir.y);
        membuff.Write(vis.AsyncState.Dir.z);

        uint8 fLGroundContactMaterial = vis.AsyncState.FLGroundContactMaterial;
        membuff.Write(fLGroundContactMaterial);
        membuff.Write(vis.AsyncState.FLSlipCoef);
        membuff.Write(vis.AsyncState.FLDamperLen);

        uint8 fRGroundContactMaterial = vis.AsyncState.FRGroundContactMaterial;
        membuff.Write(fRGroundContactMaterial);
        membuff.Write(vis.AsyncState.FRSlipCoef);
        membuff.Write(vis.AsyncState.FRDamperLen);

        uint8 rLGroundContactMaterial = vis.AsyncState.RLGroundContactMaterial;
        membuff.Write(rLGroundContactMaterial);
        membuff.Write(vis.AsyncState.RLSlipCoef);
        membuff.Write(vis.AsyncState.RLDamperLen);

        uint8 rRGroundContactMaterial = vis.AsyncState.RRGroundContactMaterial;
        membuff.Write(rRGroundContactMaterial);
        membuff.Write(vis.AsyncState.RRSlipCoef);
        membuff.Write(vis.AsyncState.RRDamperLen);
    }

    void Render()
	{
		auto app = GetApp();

		auto sceneVis = app.GameScene;
		if (sceneVis is null || app.Editor != null) {
			return;
		}

        if (app.CurrentPlayground == null || app.CurrentPlayground.GameTerminals.get_Length() == 0 || app.CurrentPlayground.GameTerminals[0].GUIPlayer == null) {
            return;
        }

        CSmScriptPlayer@ sm_script = cast<CSmPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer).ScriptAPI;
        CGamePlaygroundUIConfig@ uiConfig = app.CurrentPlayground.UIConfigs[0];
        CGameCtnChallenge@ rootMap = app.RootMap;

        if (sm_script == null) {
            return;
        }

        CSceneVehicleVis@ vis = null;

		auto player = Player::GetViewingPlayer();
		if (player !is null && player.User.Name.Contains(network.PlayerInfo.Name)) {
			@vis = Vehicle::GetVis(sceneVis, player);
		}

		if (vis is null) {
			return;
		}

		uint entityId = Dev::GetOffsetUint32(vis, 0);
		if ((entityId & 0xFF000000) == 0x04000000) {
			return;
		}

        if (this.checkingServer || !this.serverAvailable) {
            return;
        }

        auto playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);

        bool hudOff = false;

        if (app.CurrentPlayground !is null && app.CurrentPlayground.Interface !is null) {
            if (Dev::GetOffsetUint32(app.CurrentPlayground.Interface, 0x1C) == 0) {
                hudOff = true;
                if (playgroundScript == null) {
                    if (app.Network.PlaygroundClientScriptAPI != null) {
                        auto playgroundClientScriptAPI = cast<CGamePlaygroundClientScriptAPI>(app.Network.PlaygroundClientScriptAPI);
                        if (playgroundClientScriptAPI != null) {
                            g_dojo.currentRaceTime = playgroundClientScriptAPI.GameTime - player.ScriptAPI.StartTime;
                        }
                    }
                } else {
                    g_dojo.currentRaceTime = playgroundScript.Now - player.ScriptAPI.StartTime;
                }
            } else {
                g_dojo.currentRaceTime = sm_script.CurrentRaceTime;
            }
        }

        if (Enabled && OverlayEnabled && !hudOff) {     
            drawRecordingOverlay();
        }

        if (!recording && g_dojo.currentRaceTime > -50 && g_dojo.currentRaceTime < 0) {
            recording = true;
        }

        if (recording) {
            
            if (uiConfig.UISequence == 11) {
                // Finished track
                print("[TMDojo]: Finished");

                ref @fh = FinishHandle();
                cast<FinishHandle>(fh).finished = true;
                @cast<FinishHandle>(fh).rootMap = rootMap;
                @cast<FinishHandle>(fh).uiConfig = uiConfig;
                @cast<FinishHandle>(fh).sm_script = sm_script;
                @cast<FinishHandle>(fh).network = network;
                cast<FinishHandle>(fh).endRaceTime = latestRecordedTime;

                // https://github.com/GreepTheSheep/openplanet-mx-random special thanks to greep for getting accurate endRaceTime

                int endRaceTimeAccurate = -1;

                CSmArenaRulesMode@ PlaygroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);

                CGamePlayground@ GamePlayground = cast<CGamePlayground>(app.CurrentPlayground);
                if (PlaygroundScript !is null && GamePlayground.GameTerminals.get_Length() > 0) {
                    CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].ControlledPlayer);
                    if (GamePlayground.GameTerminals[0].UISequence_Current == CGameTerminal::ESGamePlaygroundUIConfig__EUISequence::Finish && player !is null) {
                        auto ghost = PlaygroundScript.Ghost_RetrieveFromPlayer(player.ScriptAPI);
                        if (ghost !is null) {
                            if (ghost.Result.Time > 0 && ghost.Result.Time < 4294967295) endRaceTimeAccurate = ghost.Result.Time;
                            PlaygroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                        } else endRaceTimeAccurate = -1;
                    } else endRaceTimeAccurate = -1;
                } else endRaceTimeAccurate = -1;

                if (endRaceTimeAccurate > 0) {
                    cast<FinishHandle>(fh).endRaceTime = endRaceTimeAccurate;
                }

                startnew(Api::PostRecordedData, fh);
            } else if (latestRecordedTime > 0 && g_dojo.currentRaceTime < 0) {
                // Give up
                print("[TMDojo]: Give up");

                ref @fh = FinishHandle();
                cast<FinishHandle>(fh).finished = false;
                @cast<FinishHandle>(fh).rootMap = rootMap;
                @cast<FinishHandle>(fh).uiConfig = uiConfig;
                @cast<FinishHandle>(fh).sm_script = sm_script;
                @cast<FinishHandle>(fh).network = network;
                cast<FinishHandle>(fh).endRaceTime = latestRecordedTime;
                startnew(Api::PostRecordedData, fh);
            } else {
                 // Record current data
                int timeSinceLastRecord = g_dojo.currentRaceTime - latestRecordedTime;
                if (timeSinceLastRecord > (1.0 / RECORDING_FPS) * 1000) {
                    // Keep track of the amount of samples for which the position did not changed, used to pause recording
                    if (Math::Abs(latestPlayerPosition.x - sm_script.Position.x) < 0.001 &&
                        Math::Abs(latestPlayerPosition.y - sm_script.Position.y) < 0.001 && 
                        Math::Abs(latestPlayerPosition.z - sm_script.Position.z) < 0.001 ) {
                        numSamePositions += 1;
                    } else {
                        numSamePositions = 0;
                    }
                    // Fill buffer if player has moved recently
                    if (numSamePositions < RECORDING_FPS) {
                        FillBuffer(vis, sm_script);
                        latestRecordedTime = g_dojo.currentRaceTime;
                    }

                    latestPlayerPosition = sm_script.Position;
                }
            }
        }
	}
}