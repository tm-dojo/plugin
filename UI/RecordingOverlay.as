void drawRecordingOverlay() {
    int panelLeft = 10;
    int panelTop = 40;

    int panelWidth = g_dojo.recording ? 125 : 160;
    int panelHeight = 36;

    int topIncr = 18;

    // Rectangle
    nvg::BeginPath();
    nvg::RoundedRect(panelLeft, panelTop, panelWidth, panelHeight, 5);
    nvg::FillColor(vec4(0,0,0,0.5));
    nvg::Fill();
    nvg::ClosePath();

    // Define colors
    vec4 white = vec4(1, 1, 1, 1);
    vec4 gray = vec4(0.1, 0.1, 0.1, 1);
    vec4 red = vec4(0.95, 0.05, 0.05, 1);

    // Recording circle        
    int circleLeft = panelLeft + 18;
    int circleTop = panelTop + 18;
    nvg::BeginPath();        
    nvg::Circle(vec2(circleLeft, circleTop), 10);
    nvg::FillColor(g_dojo.recording ? red : gray);
    nvg::Fill();
    nvg::StrokeColor(gray);
    nvg::StrokeWidth(3);
    nvg::Stroke();
    nvg::ClosePath();

    // Recording text
    int textLeft = panelLeft + 38;
    int textTop = panelTop + 23;
    nvg::FillColor(g_dojo.recording ? red : white);
    nvg::FillColor(white);
    nvg::Text(textLeft, textTop, (g_dojo.recording ? "Recording" : "Not Recording"));
}