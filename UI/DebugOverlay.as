void renderDebugOverlay() {
    UI::SetNextWindowContentSize(780, 230);
    UI::Begin("TMDojo Debug", DebugOverlayEnabled);


    UI::Columns(2);

    UI::Text("Recording: " + g_dojo.recording);
    UI::Text("CurrentRaceTime: " + g_dojo.currentRaceTime);
    UI::Text("LatestRecordedTime: " + g_dojo.latestRecordedTime);
    UI::Text("Buffer Size (bytes): " + g_dojo.membuff.GetSize());

    CSceneVehicleVis@ vis = null;

    auto app = GetApp();

    auto sceneVis = app.GameScene;
    if (@sceneVis != null && @app.Editor == null) {
        if (@app.CurrentPlayground != null && app.CurrentPlayground.GameTerminals.get_Length() > 0 && @app.CurrentPlayground.GameTerminals[0].GUIPlayer != null) {
            auto player = Player::GetViewingPlayer();
            if (player !is null && player.User.Name.Contains(g_dojo.network.PlayerInfo.Name)) {
                @vis = Vehicle::GetVis(sceneVis, player);
            }
        }
    }

    if (@vis != null) {
        UI::NextColumn();

        UI::Text("Position.x: " + vis.AsyncState.Position.x);
        UI::Text("Position.y: " + vis.AsyncState.Position.y);
        UI::Text("Position.z: " + vis.AsyncState.Position.z);

        UI::Text("WorldVel.x: " + vis.AsyncState.WorldVel.x);
        UI::Text("WorldVel.y: " + vis.AsyncState.WorldVel.y);
        UI::Text("WorldVel.z: " + vis.AsyncState.WorldVel.z);

        UI::Text("Speed: " + (vis.AsyncState.FrontSpeed * 3.6f));

        UI::Text("InputSteer: " + vis.AsyncState.InputSteer);

        UI::Text("WheelAngle: " + vis.AsyncState.FLSteerAngle);
        
        UI::Text("InputGasPedal: " + vis.AsyncState.InputGasPedal); 
        UI::Text("InputBrakePedal: " + vis.AsyncState.InputBrakePedal);

        UI::Text("EngineCurGear: " + vis.AsyncState.CurGear);
        UI::Text("EngineRpm: " + Vehicle::GetRPM(vis.AsyncState));

        UI::Text("Up.x: " + vis.AsyncState.Up.x);
        UI::Text("Up.y: " + vis.AsyncState.Up.y);
        UI::Text("Up.z: " + vis.AsyncState.Up.z);

        UI::Text("Dir.x: " + vis.AsyncState.Dir.x);
        UI::Text("Dir.y: " + vis.AsyncState.Dir.y);
        UI::Text("Dir.z: " + vis.AsyncState.Dir.z);

        UI::Text("FLGroundContactMaterial: " + vis.AsyncState.FLGroundContactMaterial);
        UI::Text("FRGroundContactMaterial: " + vis.AsyncState.FRGroundContactMaterial);
        UI::Text("RLGroundContactMaterial: " + vis.AsyncState.RLGroundContactMaterial);
        UI::Text("RRGroundContactMaterial: " + vis.AsyncState.RRGroundContactMaterial);
        
        UI::Text("FLSlipCoef: " + vis.AsyncState.FLSlipCoef);
        UI::Text("FRSlipCoef: " + vis.AsyncState.FRSlipCoef);
        UI::Text("RLSlipCoef: " + vis.AsyncState.RLSlipCoef);
        UI::Text("RRSlipCoef: " + vis.AsyncState.RRSlipCoef);

        UI::Text("FLDamperLen: " + vis.AsyncState.FLDamperLen);
        UI::Text("FRDamperLen: " + vis.AsyncState.FRDamperLen);
        UI::Text("RLDamperLen: " + vis.AsyncState.RLDamperLen);
        UI::Text("RRDamperLen: " + vis.AsyncState.RRDamperLen);
    }

    UI::End();
}