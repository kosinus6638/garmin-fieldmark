import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

// Owns the recording session, the latest GPS info, and the point counter.
// Shared between RecordingView (display) and RecordingDelegate (input).
class MappingController {

    private var _session as ActivityRecording.Session?;
    private var _catField as FitContributor.Field?;
    private var _info as Position.Info?;
    private var _count as Number;
    private var _lastMarkOk as Boolean?;   // null = nothing marked yet (for transient UI hint)

    function initialize() {
        _session = null;
        _catField = null;
        _info = null;
        _count = 0;
        _lastMarkOk = null;
    }

    // Begin GPS + recording. Safe to call once at app start.
    function start() as Void {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));

        if (_session == null) {
            _session = ActivityRecording.createSession({
                :name => "FieldMark",
                :sport => Activity.SPORT_GENERIC,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            // Lap-scoped developer field: each marked point becomes a lap carrying its category.
            _catField = _session.createField(
                "category", 0, FitContributor.DATA_TYPE_STRING,
                { :mesgType => FitContributor.MESG_TYPE_LAP, :count => 16 }
            );
            _catField.setData("");   // leading/trailing laps stay empty → ignored by parser
            _session.start();
        }
    }

    function onPosition(info as Position.Info) as Void {
        _info = info;
        WatchUi.requestUpdate();
    }

    function getInfo() as Position.Info? { return _info; }
    function getCount() as Number { return _count; }
    function getLastMarkOk() as Boolean? { return _lastMarkOk; }

    // Strict GPS gate: only a usable-or-better fix counts.
    function hasFix() as Boolean {
        return _info != null
            && _info.accuracy != null
            && _info.accuracy >= Position.QUALITY_USABLE;
    }

    // Mark one point with the given category. Returns false (and rejects) without a fix.
    function markPoint(category as String) as Boolean {
        if (!hasFix() || _session == null || _catField == null) {
            _lastMarkOk = false;
            vibeReject();
            WatchUi.requestUpdate();
            return false;
        }
        _catField.setData(category);   // applies to the currently open lap
        _session.addLap();             // closes the lap with this category, opens a new one
        _catField.setData("");         // new open lap empty until the next mark
        _count++;
        _lastMarkOk = true;
        vibeOk();
        WatchUi.requestUpdate();
        return true;
    }

    // Stop GPS + finalize and save the FIT file (lands in GARMIN/Activity/).
    function stopAndSave() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if (_session != null) {
            if (_session.isRecording()) {
                _session.stop();
            }
            _session.save();
            _session = null;
            _catField = null;
        }
    }

    private function vibeOk() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, 200)]);
        }
    }

    private function vibeReject() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(75, 100),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(75, 100)
            ]);
        }
    }
}
