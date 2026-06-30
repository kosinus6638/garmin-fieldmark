import Toybox.Lang;
import Toybox.WatchUi;

class RecordingDelegate extends WatchUi.BehaviorDelegate {

    private var _controller as MappingController;

    function initialize(controller as MappingController) {
        BehaviorDelegate.initialize();
        _controller = controller;
    }

    // START / ENTER → mark a point. M3 uses a single category "A";
    // multi-category button mapping arrives in M5/M6.
    function onSelect() as Boolean {
        _controller.markPoint("A");
        return true;
    }

    // BACK → stop + save the activity, then let the app exit.
    function onBack() as Boolean {
        _controller.stopAndSave();
        return false;
    }
}
