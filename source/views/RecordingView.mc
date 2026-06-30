import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class RecordingView extends WatchUi.View {

    private var _controller as MappingController;
    private var _timer as Timer.Timer?;

    function initialize(controller as MappingController) {
        View.initialize();
        _controller = controller;
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        // Tick once per second so clock / battery stay current.
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 1000, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

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
        var info = _controller.getInfo();
        var hasFix = _controller.hasFix();
        dc.setColor(hasFix ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 48, Graphics.FONT_SMALL, "GPS: " + qualityLabel(info),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- Point counter ---
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_MEDIUM, _controller.getCount().format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 + 32, Graphics.FONT_TINY, "Punkte",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // --- Feedback / hint line ---
        var ok = _controller.getLastMarkOk();
        var msg;
        var col;
        if (ok == null) {
            msg = "START = Punkt";
            col = Graphics.COLOR_DK_GRAY;
        } else if (ok) {
            msg = "Gespeichert";
            col = Graphics.COLOR_GREEN;
        } else {
            msg = "Kein GPS-Fix!";
            col = Graphics.COLOR_RED;
        }
        dc.setColor(col, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 28, Graphics.FONT_TINY, msg,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
