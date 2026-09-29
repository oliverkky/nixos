import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Model.js" as Model
import "State.js" as State

// Functions and handlers cross-reference sibling ids; muted for the linter.
// qmllint disable unqualified

// Screen-time tracker: accrues focused time per app into per-day records.
// Persisted as { "<YYYY-MM-DD>": { total, apps } }; 60s commits bound
// crash loss. Transitions live in State.js; this file owns timers,
// disk I/O, processes and bindings.
Item {
    id: root

    // Passed explicitly; QML JS modules don't share imports.
    readonly property var stateModel: Model

    readonly property string home: Quickshell.env("HOME")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"
    readonly property string dataDir: dataHome + "/oliver-quickshell/screen-time"
    readonly property string historyPath: dataDir + "/history.json"
    // Shared process env (HOME for ~ expansion). Typed var so the
    // Map-vs-Hash literal inference stays in one audited place.
    readonly property var procEnv: ({
            "HOME": home
        })
    readonly property string resolverPath: {
        var u = Qt.resolvedUrl("resolve_app.py").toString();
        return u.startsWith("file://") ? u.slice(7) : u;
    }

    // Terminals report the window class; resolve the pty foreground instead.
    // Wayland terminals report either a short binary name or a reverse-DNS
    // app id, depending on the desktop file they ship. Ghostty, Kitty and
    // WezTerm all use reverse-DNS under Hyprland, so matching short names
    // alone leaves them tracked as ordinary apps and skips the resolver that
    // attributes their time to the command being run.
    readonly property var terminalAppIds: ["foot", "alacritty", "kitty", "ghostty", "wezterm", "konsole", "gnome-terminal", "tilix", "xfce4-terminal", "termite", "st", "com.mitchellh.ghostty", "net.kovidgoyal.kitty", "org.wezfurlong.wezterm", "org.gnome.terminal", "org.gnome.console", "org.kde.konsole", "com.raggesilver.blackbox", "dev.warp.warp", "io.elementary.terminal"]

    // App-detail window in days; the panel raises it to the visible
    // week trend's floor, so wide graphs stay fully detailed. Days that
    // age past it roll their totals into the perpetual per-day archive.
    property int keepDays: 365
    function setKeepDays(days) {
        var n = Math.floor(Number(days));
        if (!isFinite(n) || n < 7 || n > 730)
            return;
        if (n === root.keepDays)
            return;
        root.keepDays = n;
        root.persist();
    }

    // A tick later than this means the loop froze: suspend or clock jump.
    readonly property int suspendGapMs: 30 * 1000
    property double lastTick: 0

    // Live state: always REPLACED, never mutated, so bindings fire.
    property string todayKey: Model.dayKey(new Date())
    property var today: Model.newDay()
    // Disk mirror; root.today is the source of truth.
    property var days: ({})
    // Pre-archive monthly lumps; never overlaps the day archive.
    property var months: ({})
    // Per-day archive keeping retro facts past the raw window.
    property var years: ({})

    property string activeApp: ""
    property double activeStart: 0
    // Raw compositor appId; activeApp is the resolved name.
    property string rawApp: ""
    property string resolveForApp: ""
    property bool resolveInFlight: false
    // Generation tokens stop stale terminal resolves misattributing.
    property int resolveGeneration: 0
    property int resolveSpawnGen: 0
    property bool ready: false
    property bool startupPhase: true
    property bool sessionLocked: false
    property bool sessionIdle: false

    property int dailyGoalHours: 0
    property var goalLog: []
    property int weekCount: 12
    property bool barCompact: false
    property string ignoredAppsText: ""
    property string appAliasesText: ""

    // ---- Public read API for the UI ----------------------------------------
    readonly property string barLabel: today ? Model.fmt(today.total) : ""
    readonly property bool hasActivity: today && today.total > 0

    function setDailyGoalHours(hours) {
        var next = Model.parseDailyGoalHours(hours);
        root.dailyGoalHours = next;
        root.goalLog = Model.logGoalChange(root.goalLog, root.todayKey, next);
        root.persistSettings();
    }

    function setWeekCount(count) {
        root.weekCount = Model.parseWeekCount(count);
        root.setKeepDays(Math.max(Model.APP_DETAIL_DAYS, Model.minKeepDays(root.weekCount)));
        root.persistSettings();
    }

    function setBarCompact(compact) {
        root.barCompact = compact === true;
        root.persistSettings();
    }

    function setIgnoredApps(text) {
        root.ignoredAppsText = String(text || "");
        root.setTrackingPrefs(root.ignoredAppsText, root.appAliasesText);
        root.persistSettings();
    }

    function setAppAliases(text) {
        root.appAliasesText = String(text || "");
        root.setTrackingPrefs(root.ignoredAppsText, root.appAliasesText);
        root.persistSettings();
    }

    function persistSettings() {
        if (root.startupPhase)
            return;
        historyAdapter.settings = {
            dailyGoalHours: root.dailyGoalHours,
            goalLog: root.goalLog,
            weekCount: root.weekCount,
            barCompact: root.barCompact,
            ignoredApps: root.ignoredAppsText,
            appAliases: root.appAliasesText
        };
    }

    function appList() {
        return Model.appList(root.today);
    }
    function fmt(ms) {
        return Model.fmt(ms);
    }
    function relativeDayLabel(key) {
        return Model.relativeDayLabel(key, root.todayKey);
    }

    // ---- State transition helpers ------------------------------------------
    // Spread a State.js patch onto live props so bindings fire.
    function applyState(patch) {
        if (!patch)
            return;
        if (patch.today !== undefined)
            root.today = patch.today;
        if (patch.days !== undefined)
            root.days = patch.days;
        if (patch.todayKey !== undefined)
            root.todayKey = patch.todayKey;
        if (patch.activeApp !== undefined)
            root.activeApp = patch.activeApp;
        if (patch.activeStart !== undefined)
            root.activeStart = patch.activeStart;
        if (patch.lastTick !== undefined)
            root.lastTick = patch.lastTick;
        if (patch.resolveInFlight !== undefined)
            root.resolveInFlight = patch.resolveInFlight;
    }

    // ---- Tracking ----------------------------------------------------------

    function isTerminal(appId) {
        return appId && root.terminalAppIds.indexOf(appId.toLowerCase()) !== -1;
    }

    // steam_app_<id> resolves to the game title via local manifests.
    function isSteamApp(appId) {
        return appId && appId.toLowerCase().indexOf("steam_app_") === 0;
    }

    // User tracking prefs pushed from the panel (settings live in the bar
    // widget; the service itself has no settings handle). Normalized on
    // write so readers compare lowercase keys only.
    property var ignoredApps: []
    property var appAliases: ({})
    function setTrackingPrefs(ignored, aliases) {
        var nextAliases = Model.parseAppAliases(aliases);
        // Refolding is idempotent, so a serialize compare is enough to
        // notice a changed map without tracking the previous object.
        var refold = Model.serializeAliases(nextAliases) !== Model.serializeAliases(root.appAliases);
        root.ignoredApps = Model.parseIgnoredApps(ignored);
        root.appAliases = nextAliases;
        if (refold)
            root.refoldToday();
        // An app ignored mid-focus stops accruing now, not at the next
        // focus switch.
        if (root.ready && root.activeApp && Model.isIgnoredApp(root.activeApp, root.ignoredApps)) {
            var now = Date.now();
            applyState(State.closeActiveBucket(root, root.activeApp, root.activeStart, now, root.todayKey, root.suspendGapMs, root.lastTick));
            root.activeApp = "";
            root.activeStart = 0;
            root.persist();
        }
    }

    // Fold today's stored time through an alias map: adding zen=browser
    // mid-day moves today's earlier zen time onto browser and renames
    // the live bucket, so the rest of the day accrues there. Removing
    // an alias unfolds with the inverse map, restoring the original
    // name for today and the future. Past days are untouched. No-op
    // when nothing resolves elsewhere (startup, repeated pushes).
    // Defaults to the live map when the caller passes none.
    function refoldToday(aliases) {
        if (!root.ready)
            return;
        var map = aliases || root.appAliases;
        var now = Date.now();
        var previous = root.activeApp;
        // Bill in-flight time to the old name first so no seconds leak.
        if (previous)
            root.commitElapsed(now);
        var folded = Model.refoldDay(root.today, map);
        if (folded !== root.today) {
            root.today = folded;
            var nd = Object.assign({}, root.days);
            nd[root.todayKey] = root.today;
            root.days = nd;
        }
        if (previous) {
            var renamed = Model.resolveAppName(previous, map);
            if (renamed !== previous)
                root.activeApp = renamed;
            root.activeStart = now;
        }
        root.persist();
    }

    // Screensaver/portal windows open no bucket.
    function shouldTrack(appId) {
        if (!appId)
            return false;
        var id = String(appId).toLowerCase();
        if (id.indexOf("xdg-desktop-portal") === 0)
            return false;
        if (Model.isIgnoredApp(appId, root.ignoredApps))
            return false;
        return true;
    }

    function switchActive() {
        // Pre-ready focus events open unguarded buckets (and defeat the
        // lastTick baseline); the load handlers call back once ready.
        if (!root.ready)
            return;
        var now = Date.now();
        applyState(State.closeActiveBucket(root, root.activeApp, root.activeStart, now, root.todayKey, root.suspendGapMs, root.lastTick));
        root.persist();
        var tl = ToplevelManager.activeToplevel;
        var app = tl && tl.appId ? tl.appId : "";
        root.rawApp = app;
        root.resolveInFlight = false;
        // Paused sessions keep the bucket closed.
        // Toplevel events still fire under lock; reopening here would
        // accrue straight through the pause.
        if (root.sessionLocked || root.sessionIdle) {
            root.activeApp = "";
            root.activeStart = 0;
            return;
        }
        if (app && !root.shouldTrack(app)) {
            root.activeApp = "";
            root.activeStart = 0;
            return;
        }
        if (app && (root.isTerminal(app) || root.isSteamApp(app))) {
            root.activeApp = "";
            root.activeStart = 0;
            root.beginResolve();
        } else {
            root.activeApp = Model.resolveAppName(app, root.appAliases);
            root.activeStart = app ? now : 0;
        }
    }

    // Re-resolve the focused terminal; a new request invalidates the running one.
    function beginResolve() {
        root.resolveForApp = root.rawApp;
        root.resolveInFlight = true;
        root.resolveGeneration++;
        if (!resolverProc.running) {
            root.resolveSpawnGen = root.resolveGeneration;
            resolverProc.running = true;
        }
    }

    // Refreshes terminals whose foreground changed mid-focus.
    function applyResolvedApp(name) {
        // Paused: drop the result so an in-flight resolver landing mid-lock
        // cannot reopen a bucket. Unlock re-resolves via switchActive().
        if (root.sessionLocked || root.sessionIdle) {
            root.resolveInFlight = false;
            root.resolveForApp = "";
            return;
        }
        var patch = State.applyResolvedApp(root, name, root.resolveForApp, root.todayKey, root.suspendGapMs, root.lastTick);
        // Always clear, even on no-op, so refresh isn't watchdog-gated.
        root.resolveInFlight = false;
        applyState(patch);
        if (patch)
            root.persist();
    }

    // Fold the in-flight bucket in; a crash loses at most one interval.
    function commitElapsed(now) {
        if (!root.ready || !root.activeApp || !root.activeStart)
            return;
        applyState(State.commitElapsed(root, root.activeApp, root.activeStart, now, root.todayKey, root.suspendGapMs, root.lastTick));
    }

    function rolloverIfNeeded() {
        var key = Model.dayKey(new Date());
        var now = Date.now();
        // One transition owns midnight (close+carry+reopen); no ordering slip.
        var patch = State.advanceRollover(root, now, key, root.suspendGapMs, root.lastTick);
        if (!patch)
            return;
        applyState(patch);
        root.persist();
    }

    // Zeroes today only: live day plus its history mirror. Archives
    // (months/years) are untouched; the focused app keeps running with
    // activeStart rebased so the next commit bills from now, not from
    // before the reset.
    function resetToday() {
        if (!root.ready)
            return;
        var now = Date.now();
        root.today = Model.newDay();
        var nd = Object.assign({}, root.days);
        nd[root.todayKey] = root.today;
        root.days = nd;
        if (root.activeApp)
            root.activeStart = now;
        root.lastTick = now;
        root.persist();
    }

    // Wipes ALL history: live day, day mirror, month lumps and the per-day
    // archive. Irreversible: no backup is kept, and the file is overwritten
    // on the next save. The focused app keeps running with activeStart
    // rebased so cleared time can't come back.
    function resetAll() {
        if (!root.ready)
            return;
        var now = Date.now();
        root.today = Model.newDay();
        root.days = {};
        root.months = {};
        root.years = {};
        // persist() only syncs days (and years when pruned), never months:
        // clear the adapters outright so stale lumps can't come back.
        historyAdapter.months = {};
        historyAdapter.years = {};
        if (root.activeApp)
            root.activeStart = now;
        root.lastTick = now;
        root.persist();
    }

    // ---- Persistence -------------------------------------------------------

    // Fold today into a fresh mirror object so the adapter notifier fires.
    // Writes wait while the corrupt-file backup runs.
    property bool backupPending: false
    function persist() {
        if (root.startupPhase || root.backupPending)
            return;
        var merged = Object.assign({}, root.days);
        merged[root.todayKey] = root.today;
        // Pruned days roll into the per-day archive; months lumps stay untouched.
        var ret = Model.applyRetention(merged, root.years, root.todayKey, root.keepDays);
        if (ret.pruned) {
            root.years = ret.years;
            historyAdapter.years = ret.years;
        }
        root.days = ret.days;
        historyAdapter.days = ret.days;
    }

    // Failure streak; any scheduled save resets it.
    property int saveFailCount: 0

    function scheduleSave() {
        if (root.startupPhase || root.backupPending)
            return;
        // Start, never restart: continuous focus flapping must not defer
        // the write indefinitely past the crash window.
        if (!saveTimer.running)
            saveTimer.start();
    }

    function onHistoryLoaded() {
        // Non-object sections are discarded with a single warning.
        var clean = Model.sanitizeHistory(historyAdapter.days, historyAdapter.months, historyAdapter.years);
        if (clean.days !== historyAdapter.days || clean.months !== historyAdapter.months || clean.years !== historyAdapter.years)
            console.warn("screen-time: history.json has malformed sections; ignoring them");
        var d = clean.days;
        var m = clean.months;
        // Load-time drops feed the archive too.
        var ret = Model.applyRetention(d, clean.years, Model.dayKey(new Date()), root.keepDays);
        if (ret.pruned)
            historyAdapter.years = ret.years;
        var y = ret.years;
        var kept = ret.days;
        root.months = m;
        root.days = kept;
        root.years = y;
        if (!root.ready) {
            var settings = historyAdapter.settings && typeof historyAdapter.settings === "object" ? historyAdapter.settings : {};
            root.dailyGoalHours = Model.parseDailyGoalHours(settings.dailyGoalHours);
            root.goalLog = Model.parseGoalLog(settings.goalLog);
            root.weekCount = Model.parseWeekCount(settings.weekCount);
            root.barCompact = settings.barCompact === true;
            root.keepDays = Math.max(Model.APP_DETAIL_DAYS, Model.minKeepDays(root.weekCount));
            root.ignoredAppsText = typeof settings.ignoredApps === "string" ? settings.ignoredApps : "";
            root.appAliasesText = typeof settings.appAliases === "string" ? settings.appAliases : "";
            root.setTrackingPrefs(root.ignoredAppsText, root.appAliasesText);
            root.todayKey = Model.dayKey(new Date());
            var prev = d[root.todayKey];
            root.today = prev && typeof prev === "object" ? {
                total: prev.total || 0,
                apps: Object.assign({}, prev.apps || {})
            } : Model.newDay();
            root.ready = true;
            root.startupPhase = false;
            root.lastTick = Date.now();
            root.switchActive();
        } else {
            // Retry keeps the live bucket; refresh the mirror only.
            var nd = Object.assign({}, root.days);
            nd[root.todayKey] = root.today;
            root.days = nd;
        }
    }

    function onHistoryLoadFailed() {
        // Corrupt files are preserved aside; tracking starts empty immediately.
        console.warn("screen-time: history load failed, starting empty");
        if (!root.backupAttempted) {
            root.backupAttempted = true;
            root.backupPending = true;
            backupProc.running = true;
        }
        if (!root.ready) {
            root.days = {};
            root.todayKey = Model.dayKey(new Date());
            root.ready = true;
            root.startupPhase = false;
            root.lastTick = Date.now();
            root.switchActive();
        }
    }

    FileView {
        id: historyFile
        path: root.historyPath
        printErrors: true
        atomicWrites: true
        onAdapterUpdated: {
            // Fresh data resets the failure streak.
            root.saveFailCount = 0;
            root.scheduleSave();
        }
        onLoaded: root.onHistoryLoaded()
        onLoadFailed: root.onHistoryLoadFailed()
        onSaveFailed: function (error) {
            // Retry with capped backoff; suspend after 6 straight failures.
            root.saveFailCount++;
            if (root.saveFailCount > 6) {
                console.warn("screen-time: history save failed (" + FileViewError.toString(error) + "), suspending retries until next change");
                return;
            }
            var delay = Math.min(1500 * Math.pow(2, root.saveFailCount - 1), 60000);
            console.warn("screen-time: history save failed (" + FileViewError.toString(error) + "), retrying in " + delay + "ms");
            saveRetryTimer.interval = delay;
            saveRetryTimer.restart();
        }

        // FileViewAdapter is C++-only in Quickshell: complete at runtime,
        // incomplete to the linter. Muted via the ini (UnresolvedType/
        // TypeError) instead of a scoped directive, because that directive
        // name is unknown to qmllint 6.4.
        JsonAdapter {
            id: historyAdapter
            property var days: ({})
            property var months: ({})
            property var years: ({})
            property var settings: ({})
        }
    }

    // QProcess::ExitStatus never loads into lint; handlers take no args.
    // Muted via the ini (BadSignalHandler/Parameters), see .qmllint.ini.
    Process {
        id: ensureDirProc
        environment: root.procEnv
        command: ["bash", "-c", "mkdir -p \"$1\"; f=\"$1/history.json\"; [[ -f \"$f\" ]] || printf '{}\\n' > \"$f\"", "bash", root.dataDir]
        onExited: historyFile.reload()
    }

    // Polls for missed focus events; real switches are event-driven.
    Timer {
        id: reconcileTimer
        interval: 2000
        repeat: true
        running: root.ready
        onTriggered: {
            var tl = ToplevelManager.activeToplevel;
            var app = tl && tl.appId ? tl.appId : "";
            if (app !== root.rawApp)
                root.switchActive();
        }
    }

    // Move aside non-empty files that fail to parse. The validity check
    // uses python3 when present, but the move itself never depends on
    // it: without python an unreadable file is still preserved aside
    // instead of being overwritten on the next save.
    property bool backupAttempted: false
    Process {
        id: backupProc
        environment: root.procEnv
        command: ["bash", "-c", "f=\"$1/history.json\"; if [[ -s \"$f\" ]]; then if command -v python3 >/dev/null 2>&1 && python3 -c 'import json,sys; json.load(open(sys.argv[1]))' \"$f\" 2>/dev/null; then :; else mv -f \"$f\" \"$f.corrupt-$(date +%s)\"; fi; fi", "bash", root.dataDir]
        onExited: {
            // Unblock writes; queued state persists on the next tick.
            root.backupPending = false;
            root.persist();
        }
    }

    // Foreground can change without compositor notice; re-resolve live.
    Timer {
        id: terminalRefreshTimer
        interval: 5000
        repeat: true
        running: root.ready && root.isTerminal(root.rawApp) && !root.resolveInFlight
        onTriggered: root.beginResolve()
    }

    // Kill hung resolvers so refresh can start a fresh process.
    // No generation bump needed: every switchActive clears
    // resolveInFlight, and beginResolve re-syncs the tokens, so a late
    // exit only ever matches a live run of the same terminal.
    Timer {
        id: resolveWatchdog
        interval: 10000
        repeat: false
        running: root.resolveInFlight
        onTriggered: {
            root.resolveInFlight = false;
            if (resolverProc.running)
                resolverProc.running = false;
        }
    }

    // Empty stdout falls back to rawApp; stderr is logged so breakage is visible.
    // sh wrapper: missing python3 still exits 0 instead of stalling to watchdog.
    Process {
        id: resolverProc
        command: ["sh", "-c", "command -v python3 >/dev/null 2>&1 && exec python3 \"$1\" || exit 0", "sh", root.resolverPath]
        stdout: StdioCollector {
            id: resolverOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: resolverErr
            waitForEnd: true
        }
        onExited: {
            var err = resolverErr.text.trim();
            if (err)
                console.warn("screen-time: resolver stderr:", err);
            root.applyResolvedApp(resolverOut.text.trim());
        }
    }

    // ---- Session pause ------------------------------------------------------
    // logind is the session authority used by hypridle and hyprlock. Polling
    // both hints keeps lock and compositor-idle time out of the accounting.
    readonly property bool sessionPaused: root.sessionLocked || root.sessionIdle
    property bool resumePending: false

    function setSessionState(locked, idle) {
        var wasPaused = root.sessionPaused;
        root.sessionLocked = locked === true;
        root.sessionIdle = idle === true;
        var paused = root.sessionPaused;
        if (paused === wasPaused)
            return;
        if (paused) {
            root.resumePending = false;
            resumeTimer.stop();
            root.resolveInFlight = false;
            root.resolveForApp = "";
            var now = Date.now();
            root.applyState(State.closeActiveBucket(root, root.activeApp, root.activeStart, now, root.todayKey, root.suspendGapMs, root.lastTick));
            root.persist();
            return;
        }
        root.resumePending = true;
        resumeTimer.restart();
    }

    function applyResume() {
        if (!root.resumePending || root.sessionPaused)
            return;
        root.resumePending = false;
        root.lastTick = Date.now();
        root.switchActive();
    }

    Timer {
        id: resumeTimer
        interval: 500
        repeat: false
        onTriggered: root.applyResume()
    }

    Process {
        id: sessionStateReader
        command: ["loginctl", "show-session", "self", "--property=LockedHint", "--property=IdleHint"]
        stdout: StdioCollector {
            onStreamFinished: {
                var locked = /(?:^|\\n)LockedHint=yes(?:\\n|$)/.test(this.text);
                var idle = /(?:^|\\n)IdleHint=yes(?:\\n|$)/.test(this.text);
                root.setSessionState(locked, idle);
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.ready
        triggeredOnStart: true
        onTriggered: {
            if (!sessionStateReader.running)
                sessionStateReader.running = true;
        }
    }

    // Fresh baseline resolves suspends down to ~30s.
    Timer {
        id: heartbeatTimer
        interval: 5000
        repeat: true
        running: root.ready
        onTriggered: {
            var now = Date.now();
            if (State.isSuspendGap(now, root.lastTick, root.suspendGapMs)) {
                applyState(State.closeActiveBucket(root, root.activeApp, root.activeStart, now, root.todayKey, root.suspendGapMs, root.lastTick));
                // Roll past midnight before reopening, or wake seconds land on yesterday.
                root.rolloverIfNeeded();
                root.persist();
                root.switchActive();
            } else {
                root.rolloverIfNeeded();
                root.commitElapsed(now);
                root.persist();
            }
            root.lastTick = now;
        }
    }

    Timer {
        id: commitTimer
        interval: 60000
        repeat: true
        running: root.ready
        onTriggered: {
            var now = Date.now();
            root.rolloverIfNeeded();
            root.commitElapsed(now);
            root.persist();
            root.lastTick = now;
        }
    }

    Timer {
        id: saveTimer
        interval: 1500
        repeat: false
        onTriggered: historyFile.writeAdapter()
    }

    // Save-retry driver (backoff computed in onSaveFailed).
    Timer {
        id: saveRetryTimer
        repeat: false
        onTriggered: historyFile.writeAdapter()
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            root.switchActive();
        }
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }
}
