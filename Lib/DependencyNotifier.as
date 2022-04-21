namespace DependencyNotifier {

    bool shownPlayerStateNotification = false;

    void NotifyMissingPlayerStateDependency() {
#if !DEPENDENCY_PLAYERSTATE
        if (!shownPlayerStateNotification) {
            print("TMDojo did not find optional 'PlayerState' plugin dependency");
            UI::ShowNotification(
                "TMDojo",
                "We've noticed you don't have the 'PlayerState' plugin installed!\n\n" + 
                    "If you want to record CP/sector times, please install it.\nThen reload this plugin or restart the script engine.\n\n" + 
                    "F3 → Plugin Manager → Open manager → Search for 'PlayerState'", 
                WARNING_COLOR,
                20000
            );
            shownPlayerStateNotification = true;
        }
#else
        if (shownPlayerStateNotification) {
            print("TMDojo found optional 'PlayerState' plugin dependency, now recording sector times!");
            UI::ShowNotification(
                "TMDojo",
                "Successfully installed 'PlayerState' plugin!\n\n" + 
                    "CP/sector times will now be recorded!.",
                SUCCESS_COLOR
            );
            shownPlayerStateNotification = false;
        }
#endif
    }

}