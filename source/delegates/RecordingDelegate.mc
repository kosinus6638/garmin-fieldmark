import Toybox.Lang;
import Toybox.WatchUi;

class RecordingDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        // M1: exit via back button allowed; stop-confirm dialog added in M5
        return false;
    }
}
