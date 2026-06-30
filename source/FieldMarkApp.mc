import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FieldMarkApp extends Application.AppBase {

    private var _controller as MappingController?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        _controller = new MappingController();
        _controller.start();
    }

    function onStop(state as Lang.Dictionary?) as Void {
        // Backup save in case the view/delegate didn't run stopAndSave (idempotent).
        if (_controller != null) {
            _controller.stopAndSave();
            _controller = null;
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new RecordingView(_controller), new RecordingDelegate(_controller)];
    }
}
