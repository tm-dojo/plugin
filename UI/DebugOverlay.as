void renderDebugOverlay() {
    UI::SetNextWindowContentSize(780, 230);
    UI::Begin("TMDojo Debug", DebugOverlayEnabled);


    UI::Columns(2);

    UI::Text("Recording: " + g_dojo.recording);
    UI::Text("CurrentRaceTime: " + g_dojo.currentRaceTime);
    UI::Text("LatestRecordedTime: " + g_dojo.latestRecordedTime);
    UI::Text("Buffer Size (bytes): " + g_dojo.membuff.GetSize());

    CSceneVehicleVisState@ visState = VehicleState::ViewingPlayerState();

    if (@visState != null) {
        UI::NextColumn();

        UI::Text("Position.x: " + visState.Position.x);
        UI::Text("Position.y: " + visState.Position.y);
        UI::Text("Position.z: " + visState.Position.z);

        UI::Text("WorldVel.x: " + visState.WorldVel.x);
        UI::Text("WorldVel.y: " + visState.WorldVel.y);
        UI::Text("WorldVel.z: " + visState.WorldVel.z);

        UI::Text("Speed: " + (visState.FrontSpeed * 3.6f));

        UI::Text("InputSteer: " + visState.InputSteer);

        UI::Text("WheelAngle: " + visState.FLSteerAngle);
        
        UI::Text("InputGasPedal: " + visState.InputGasPedal); 
        UI::Text("InputBrakePedal: " + visState.InputBrakePedal);

        UI::Text("EngineCurGear: " + visState.CurGear);
        UI::Text("EngineRpm: " + VehicleState::GetRPM(visState));

        UI::Text("Up.x: " + visState.Up.x);
        UI::Text("Up.y: " + visState.Up.y);
        UI::Text("Up.z: " + visState.Up.z);

        UI::Text("Dir.x: " + visState.Dir.x);
        UI::Text("Dir.y: " + visState.Dir.y);
        UI::Text("Dir.z: " + visState.Dir.z);

        UI::Text("FLGroundContactMaterial: " + visState.FLGroundContactMaterial);
        UI::Text("FRGroundContactMaterial: " + visState.FRGroundContactMaterial);
        UI::Text("RLGroundContactMaterial: " + visState.RLGroundContactMaterial);
        UI::Text("RRGroundContactMaterial: " + visState.RRGroundContactMaterial);
        
        UI::Text("FLSlipCoef: " + visState.FLSlipCoef);
        UI::Text("FRSlipCoef: " + visState.FRSlipCoef);
        UI::Text("RLSlipCoef: " + visState.RLSlipCoef);
        UI::Text("RRSlipCoef: " + visState.RRSlipCoef);

        UI::Text("FLDamperLen: " + visState.FLDamperLen);
        UI::Text("FRDamperLen: " + visState.FRDamperLen);
        UI::Text("RLDamperLen: " + visState.RLDamperLen);
        UI::Text("RRDamperLen: " + visState.RRDamperLen);
    }

    UI::End();
}