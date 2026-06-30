import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class RecordingView extends WatchUi.View {

    private var _lastInfo as Position.Info?;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _lastInfo = null;
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        // Start continuous GPS; callback fires on each position update.
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));

        // Tick once per second so clock / battery stay current even without a fix.
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
    }

    function onHide() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onPosition(info as Position.Info) as Void {
        _lastInfo = info;
        WatchUi.requestUpdate();
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    // Map the Position quality enum to a short German label.
    private function qualityLabel(info as Position.Info?) as String {
        if (info == null || info.accuracy == null) {
            return "Kein GPS";
        }
        switch (info.accuracy) {
            case Position.QUALITY_GOOD:        return "Gut";
            case Position.QUALITY_USABLE:      return "Brauchbar";
            case Position.QUALITY_POOR:        return "Schlecht";
            case Position.QUALITY_LAST_KNOWN:  return "Veraltet";
            default:                           return "Kein GPS";
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // --- Status line: time + battery ---
        var clockTime = System.getClockTime();
        var timeStr = clockTime.hour.format("%02d") + ":" + clockTime.min.format("%02d");
        var battStr = System.getSystemStats().battery.format("%d") + "%";

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 18, Graphics.FONT_TINY, timeStr + "   " + battStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- GPS quality ---
        var hasFix = _lastInfo != null
                     && _lastInfo.accuracy != null
                     && _lastInfo.accuracy >= Position.QUALITY_USABLE;

        dc.setColor(hasFix ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 - 30, Graphics.FONT_SMALL, "GPS: " + qualityLabel(_lastInfo),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- Coordinates (only once we have a usable fix) ---
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (hasFix) {
            var deg = _lastInfo.position.toDegrees();
            var latStr = (deg[0] as Double).format("%.5f");
            var lonStr = (deg[1] as Double).format("%.5f");
            dc.drawText(w / 2, h / 2 + 5, Graphics.FONT_TINY, latStr,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(w / 2, h / 2 + 30, Graphics.FONT_TINY, lonStr,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2 + 15, Graphics.FONT_TINY, "Warte auf Fix...",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
