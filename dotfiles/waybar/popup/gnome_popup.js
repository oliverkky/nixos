#!/usr/bin/gjs

imports.gi.versions.Gtk = "4.0";
imports.gi.versions.Adw = "1";

const ByteArray = imports.byteArray;
const System = imports.system;
const { Gtk, Gio, GLib, Adw, Gdk } = imports.gi;

if (ARGV[0] === "--check") {
  System.exit(0);
}

Adw.init();

const MODE = ARGV[0] || "quick-settings";
const STICKY = GLib.getenv("WAYBAR_GNOME_POPUP_STICKY") === "1";
const CONFIG_ROOT =
  GLib.getenv("XDG_CONFIG_HOME") ||
  GLib.build_filenamev([GLib.getenv("HOME"), ".config"]);
const WAYBAR_DIR = GLib.build_filenamev([CONFIG_ROOT, "waybar"]);
const POPUP_DIR = GLib.build_filenamev([WAYBAR_DIR, "popup"]);
const ACTION_SCRIPT = `${POPUP_DIR}/action.sh`;
const STATE_SCRIPT = `${POPUP_DIR}/state.sh`;
const CSS_FILE = `${WAYBAR_DIR}/style/popup.css`;
const ANIMATE_OPEN = GLib.getenv("WAYBAR_GNOME_POPUP_ANIMATE") !== "0";

let windowRef = null;
let refreshSource = null;
let readyForAutoClose = false;
let monthOffset = 0;
let expandedSection = null;
let quickWidgets = {};
let clockWidgets = {};

const weekDayLabels = ["M", "T", "W", "T", "F", "S", "S"];

function runShell(command) {
  try {
    const [, stdout] = GLib.spawn_command_line_sync(command);
    return ByteArray.toString(stdout).trim();
  } catch (error) {
    return "";
  }
}

function runAction(action, arg = null) {
  const command =
    arg === null
      ? `${ACTION_SCRIPT} ${GLib.shell_quote(action)}`
      : `${ACTION_SCRIPT} ${GLib.shell_quote(action)} ${GLib.shell_quote(arg)}`;
  GLib.spawn_command_line_async(command);
}

function readQuickState() {
  const output = runShell(`${STATE_SCRIPT} quick-settings`);
  if (!output) {
    return {
      volume: 50,
      muted: false,
      network: {
        label: "Offline",
        detail: "Not connected",
        kind: "offline",
        connected: false,
      },
      bluetooth: {
        enabled: false,
        connected: false,
        detail: "Off",
        device: "",
      },
      power: { mode: "balanced", label: "Balanced" },
      nightLight: false,
      darkStyle: false,
      doNotDisturb: false,
    };
  }

  try {
    return JSON.parse(output);
  } catch (error) {
    return {
      volume: 50,
      muted: false,
      network: {
        label: "Offline",
        detail: "Not connected",
        kind: "offline",
        connected: false,
      },
      bluetooth: {
        enabled: false,
        connected: false,
        detail: "Off",
        device: "",
      },
      power: { mode: "balanced", label: "Balanced" },
      nightLight: false,
      darkStyle: false,
      doNotDisturb: false,
    };
  }
}

function loadCss() {
  const provider = new Gtk.CssProvider();
  provider.load_from_path(CSS_FILE);
  Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default(),
    provider,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
  );
}

function addClasses(widget, classes) {
  for (const cssClass of classes) {
    if (cssClass) {
      widget.add_css_class(cssClass);
    }
  }
  return widget;
}

function initialWindowSize(mode, width, height) {
  if (!ANIMATE_OPEN) {
    return [width, height];
  }

  return mode === "clock" ? [168, 30] : [126, 30];
}

function setPopupChild(win, child) {
  if (!ANIMATE_OPEN) {
    win.set_child(child);
    return;
  }

  const revealer = new Gtk.Revealer({
    transition_type: Gtk.RevealerTransitionType.SLIDE_DOWN,
    transition_duration: 220,
    reveal_child: false,
  });

  revealer.set_child(child);
  win.set_child(revealer);

  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 90, () => {
    revealer.set_reveal_child(true);
    return GLib.SOURCE_REMOVE;
  });
}

function makeLabel(text, classes = [], xalign = 0) {
  const label = new Gtk.Label({ label: text, xalign, wrap: true });
  addClasses(label, classes);
  return label;
}

function clearBox(box) {
  let child = box.get_first_child();
  while (child) {
    const next = child.get_next_sibling();
    box.remove(child);
    child = next;
  }
}

function makeIconButton(icon, onClick) {
  const button = new Gtk.Button();
  addClasses(button, ["icon-circle"]);
  button.set_child(makeLabel(icon, ["popup-title"], 0.5));
  button.connect("clicked", () => onClick());
  return button;
}

function buildQuickButton(icon, title, subtitle, active, onClick) {
  const button = new Gtk.Button();
  addClasses(button, ["quick-button", active ? "active" : "inactive"]);

  const row = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 10,
  });
  row.append(makeLabel(icon, ["popup-title"], 0.5));

  const text = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 0,
    hexpand: true,
  });
  text.append(makeLabel(title, ["section-title"]));
  if (subtitle) {
    text.append(makeLabel(subtitle, ["section-subtitle"]));
  }
  row.append(text);
  row.append(makeLabel("›", ["popup-title"], 1));
  button.set_child(row);
  button.connect("clicked", () => onClick());
  return button;
}

function buildToggleButton(icon, title, active, onClick) {
  const button = new Gtk.Button();
  addClasses(button, [
    "quick-button",
    active ? "active" : "inactive",
    !active ? "dim" : "",
  ]);
  const row = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 10,
  });
  row.append(makeLabel(icon, ["popup-title"], 0.5));
  row.append(makeLabel(title, ["section-title"]));
  button.set_child(row);
  button.connect("clicked", () => onClick());
  return button;
}

function buildExpandCard(state) {
  const card = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 10,
  });
  addClasses(card, ["expand-card"]);

  if (expandedSection === "network") {
    card.append(
      makeLabel(
        state.network.label === "Wired" ? "Wired Connections" : "Network",
        ["popup-title"],
      ),
    );
    card.append(makeLabel(state.network.detail, ["section-title"]));
    const settings = new Gtk.Button({ label: "Network Settings" });
    addClasses(settings, ["mini-button"]);
    settings.connect("clicked", () => runAction("network-settings"));
    card.append(settings);
  } else if (expandedSection === "bluetooth") {
    card.append(makeLabel("Bluetooth", ["popup-title"]));
    card.append(
      makeLabel(
        state.bluetooth.device || state.bluetooth.detail || "No devices",
        ["section-title"],
      ),
    );
    const settings = new Gtk.Button({ label: "Bluetooth Settings" });
    addClasses(settings, ["mini-button"]);
    settings.connect("clicked", () => runAction("bluetooth-settings"));
    card.append(settings);
  } else if (expandedSection === "power") {
    card.append(makeLabel("Power Mode", ["popup-title"]));
    for (const [mode, label] of [
      ["performance", "Performance"],
      ["balanced", "Balanced"],
      ["power-saver", "Power Saver"],
    ]) {
      const button = new Gtk.Button();
      addClasses(button, ["mini-button"]);
      const row = new Gtk.Box({
        orientation: Gtk.Orientation.HORIZONTAL,
        spacing: 10,
      });
      row.append(
        makeLabel(
          state.power.mode === mode ? "✓" : " ",
          ["section-title"],
          0.5,
        ),
      );
      row.append(makeLabel(label, ["section-title"]));
      button.set_child(row);
      button.connect("clicked", () => {
        runAction("set-power-mode", mode);
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
          populateQuickSettings();
          return GLib.SOURCE_REMOVE;
        });
      });
      card.append(button);
    }
    const settings = new Gtk.Button({ label: "Power Settings" });
    addClasses(settings, ["mini-button"]);
    settings.connect("clicked", () => runAction("power-settings"));
    card.append(settings);
  }

  return card;
}

function populateQuickSettings() {
  const state = readQuickState();

  quickWidgets.volumeLabel.set_label(state.muted ? "󰝟" : "󰕾");
  quickWidgets.volumeScale.set_value(state.volume);

  clearBox(quickWidgets.gridTop);
  quickWidgets.gridTop.append(
    buildQuickButton(
      "󰈀",
      state.network.label,
      state.network.detail,
      state.network.connected,
      () => {
        expandedSection = expandedSection === "network" ? null : "network";
        populateQuickSettings();
      },
    ),
  );
  quickWidgets.gridTop.append(
    buildQuickButton(
      "󰂯",
      "Bluetooth",
      state.bluetooth.detail,
      state.bluetooth.enabled,
      () => {
        expandedSection = expandedSection === "bluetooth" ? null : "bluetooth";
        populateQuickSettings();
      },
    ),
  );

  clearBox(quickWidgets.gridMiddle);
  quickWidgets.gridMiddle.append(
    buildQuickButton("󰓅", "Power Mode", state.power.label, true, () => {
      expandedSection = expandedSection === "power" ? null : "power";
      populateQuickSettings();
    }),
  );
  quickWidgets.gridMiddle.append(
    buildToggleButton("󰌵", "Night Light", state.nightLight, () => {
      runAction("toggle-night-light");
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
        populateQuickSettings();
        return GLib.SOURCE_REMOVE;
      });
    }),
  );

  clearBox(quickWidgets.expandArea);
  if (expandedSection) {
    quickWidgets.expandArea.append(buildExpandCard(state));
    quickWidgets.expandRevealer.set_reveal_child(true);
  } else {
    quickWidgets.expandRevealer.set_reveal_child(false);
  }

  clearBox(quickWidgets.gridBottom);
  quickWidgets.gridBottom.append(
    buildToggleButton("󰃚", "Dark Style", state.darkStyle, () => {
      runAction("toggle-dark-style");
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
        populateQuickSettings();
        return GLib.SOURCE_REMOVE;
      });
    }),
  );
  quickWidgets.gridBottom.append(
    buildToggleButton("󰂛", "Do Not Disturb", state.doNotDisturb, () => {
      runAction("toggle-dnd");
      GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => {
        populateQuickSettings();
        return GLib.SOURCE_REMOVE;
      });
    }),
  );
}

function createQuickSettingsWindow(app) {
  const [initialWidth, initialHeight] = initialWindowSize(
    "quick-settings",
    360,
    520,
  );
  const win = new Gtk.ApplicationWindow({
    application: app,
    title: "Waybar GNOME Quick Settings",
    default_width: initialWidth,
    default_height: initialHeight,
    decorated: false,
    resizable: false,
  });
  win.add_css_class("popup-window");

  const root = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 12,
    margin_top: 16,
    margin_bottom: 16,
    margin_start: 16,
    margin_end: 16,
  });

  const top = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 8,
  });
  top.add_css_class("top-actions");
  top.append(makeIconButton("󰹑", () => runAction("screenshot")));
  top.append(makeIconButton("󰒓", () => runAction("system-settings")));
  top.append(new Gtk.Box({ hexpand: true }));
  top.append(makeIconButton("󰌾", () => runAction("lock")));
  top.append(makeIconButton("󰐥", () => runAction("power-menu")));
  root.append(top);

  const volumeCard = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 12,
  });
  addClasses(volumeCard, ["volume-card"]);
  quickWidgets.volumeLabel = makeLabel("󰕾", ["popup-title"], 0.5);
  quickWidgets.volumeScale = new Gtk.Scale({
    orientation: Gtk.Orientation.HORIZONTAL,
    draw_value: false,
    hexpand: true,
    adjustment: new Gtk.Adjustment({
      lower: 0,
      upper: 100,
      value: 50,
      step_increment: 1,
      page_increment: 5,
    }),
  });
  quickWidgets.volumeScale.connect("value-changed", (widget) =>
    runAction("volume", String(Math.round(widget.get_value()))),
  );
  volumeCard.append(quickWidgets.volumeLabel);
  volumeCard.append(quickWidgets.volumeScale);
  volumeCard.append(makeIconButton("›", () => runAction("sound-settings")));
  root.append(volumeCard);

  quickWidgets.gridTop = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 10,
    homogeneous: true,
  });
  quickWidgets.expandRevealer = new Gtk.Revealer({
    transition_type: Gtk.RevealerTransitionType.SLIDE_DOWN,
  });
  quickWidgets.expandArea = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 0,
  });
  quickWidgets.expandRevealer.set_child(quickWidgets.expandArea);
  quickWidgets.gridMiddle = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 10,
    homogeneous: true,
  });
  quickWidgets.gridBottom = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 10,
    homogeneous: true,
  });

  root.append(quickWidgets.gridTop);
  root.append(quickWidgets.expandRevealer);
  root.append(quickWidgets.gridMiddle);
  root.append(quickWidgets.gridBottom);

  setPopupChild(win, root);
  populateQuickSettings();
  return win;
}

function getWeekNumber(date) {
  const temp = new Date(
    Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()),
  );
  const day = temp.getUTCDay() || 7;
  temp.setUTCDate(temp.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(temp.getUTCFullYear(), 0, 1));
  return Math.ceil(((temp - yearStart) / 86400000 + 1) / 7);
}

function buildCalendarGrid() {
  const current = new Date();
  const monthDate = new Date(
    current.getFullYear(),
    current.getMonth() + monthOffset,
    1,
  );
  const grid = new Gtk.Grid({ column_spacing: 8, row_spacing: 8 });

  for (let i = 0; i < weekDayLabels.length; i++) {
    grid.attach(
      makeLabel(weekDayLabels[i], ["calendar-weekday"], 0.5),
      i + 1,
      0,
      1,
      1,
    );
  }

  const startDay = (monthDate.getDay() + 6) % 7;
  const daysInMonth = new Date(
    monthDate.getFullYear(),
    monthDate.getMonth() + 1,
    0,
  ).getDate();
  const daysInPrev = new Date(
    monthDate.getFullYear(),
    monthDate.getMonth(),
    0,
  ).getDate();
  let dayCounter = 1;
  let nextCounter = 1;

  for (let row = 0; row < 6; row++) {
    const weekDate = new Date(
      monthDate.getFullYear(),
      monthDate.getMonth(),
      1 - startDay + row * 7,
    );
    grid.attach(
      makeLabel(
        String(getWeekNumber(weekDate)),
        ["calendar-cell", "weeknum"],
        0.5,
      ),
      0,
      row + 1,
      1,
      1,
    );

    for (let col = 0; col < 7; col++) {
      const index = row * 7 + col;
      let number;
      let date;
      let outside = false;

      if (index < startDay) {
        number = daysInPrev - startDay + index + 1;
        date = new Date(
          monthDate.getFullYear(),
          monthDate.getMonth() - 1,
          number,
        );
        outside = true;
      } else if (dayCounter > daysInMonth) {
        number = nextCounter++;
        date = new Date(
          monthDate.getFullYear(),
          monthDate.getMonth() + 1,
          number,
        );
        outside = true;
      } else {
        number = dayCounter++;
        date = new Date(monthDate.getFullYear(), monthDate.getMonth(), number);
      }

      const label = makeLabel(String(number), ["calendar-cell"], 0.5);
      if (outside) {
        label.add_css_class("outside");
      }

      if (
        date.getDate() === current.getDate() &&
        date.getMonth() === current.getMonth() &&
        date.getFullYear() === current.getFullYear()
      ) {
        label.add_css_class("today");
      }

      grid.attach(label, col + 1, row + 1, 1, 1);
    }
  }

  return [monthDate, grid];
}

function populateClockWidgets() {
  const now = new Date();
  const [monthDate, calendarGrid] = buildCalendarGrid();

  clockWidgets.heading.set_label(
    `${now.toLocaleDateString(undefined, { weekday: "long" })}\n${now.getDate()} ${now.toLocaleDateString(undefined, { month: "long" })} ${now.getFullYear()}`,
  );
  clockWidgets.monthLabel.set_label(
    monthDate.toLocaleDateString(undefined, { month: "long" }),
  );

  clearBox(clockWidgets.calendarHolder);
  clockWidgets.calendarHolder.append(calendarGrid);
}

function buildClockWindow(app) {
  const [initialWidth, initialHeight] = initialWindowSize("clock", 800, 590);
  const win = new Gtk.ApplicationWindow({
    application: app,
    title: "Waybar GNOME Clock",
    default_width: initialWidth,
    default_height: initialHeight,
    decorated: false,
    resizable: false,
  });
  win.add_css_class("popup-window");

  const root = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 18,
    margin_top: 18,
    margin_bottom: 18,
    margin_start: 18,
    margin_end: 18,
  });

  const left = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 12,
    width_request: 320,
    vexpand: true,
  });
  const notificationCard = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 8,
    vexpand: true,
  });
  addClasses(notificationCard, ["notification-card"]);
  notificationCard.append(makeLabel("Notifications", ["popup-title"]));
  notificationCard.append(makeLabel("No notifications", ["section-title"]));
  notificationCard.append(
    makeLabel(
      "This mirrors the GNOME shell layout, but notification history is not connected here yet.",
      ["section-subtitle"],
    ),
  );
  left.append(notificationCard);
  const clearButton = new Gtk.Button({ label: "Clear" });
  addClasses(clearButton, ["clear-button"]);
  left.append(clearButton);

  const right = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 12,
    hexpand: true,
  });
  const now = new Date();
  clockWidgets.heading = makeLabel(
    `${now.toLocaleDateString(undefined, { weekday: "long" })}\n${now.getDate()} ${now.toLocaleDateString(undefined, { month: "long" })} ${now.getFullYear()}`,
    ["popup-heading"],
  );
  right.append(clockWidgets.heading);

  const calendarCard = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 12,
  });
  addClasses(calendarCard, ["text-card"]);
  const [monthDate, calendarGrid] = buildCalendarGrid();
  const calendarHeader = new Gtk.Box({
    orientation: Gtk.Orientation.HORIZONTAL,
    spacing: 10,
  });
  calendarHeader.append(
    makeIconButton("‹", () => {
      monthOffset -= 1;
      populateClockWidgets();
    }),
  );
  clockWidgets.monthLabel = makeLabel(
    monthDate.toLocaleDateString(undefined, { month: "long" }),
    ["month-title"],
    0.5,
  );
  clockWidgets.monthLabel.set_hexpand(true);
  calendarHeader.append(clockWidgets.monthLabel);
  calendarHeader.append(
    makeIconButton("›", () => {
      monthOffset += 1;
      populateClockWidgets();
    }),
  );
  calendarCard.append(calendarHeader);
  clockWidgets.calendarHolder = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 0,
  });
  clockWidgets.calendarHolder.append(calendarGrid);
  calendarCard.append(clockWidgets.calendarHolder);
  right.append(calendarCard);

  const todayCard = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 6,
  });
  addClasses(todayCard, ["text-card"]);
  todayCard.append(makeLabel("Today", ["section-subtitle"]));
  todayCard.append(
    makeLabel(now.toLocaleDateString(undefined, { weekday: "long" }), [
      "section-title",
    ]),
  );
  todayCard.append(makeLabel("Nothing scheduled", ["section-subtitle"]));
  right.append(todayCard);

  const worldClocks = new Gtk.Button({ label: "Add World Clocks..." });
  addClasses(worldClocks, ["text-card"]);
  right.append(worldClocks);

  const weatherCard = new Gtk.Box({
    orientation: Gtk.Orientation.VERTICAL,
    spacing: 6,
  });
  addClasses(weatherCard, ["weather-card"]);
  weatherCard.append(makeLabel("Weather", ["section-subtitle"]));
  weatherCard.append(makeLabel("Unavailable", ["section-title"]));
  weatherCard.append(
    makeLabel("Weather data is not hooked into this popup yet.", [
      "section-subtitle",
    ]),
  );
  right.append(weatherCard);

  root.append(left);
  root.append(right);
  setPopupChild(win, root);
  populateClockWidgets();
  return win;
}

function attachWindowBehavior(win, app) {
  const keyController = new Gtk.EventControllerKey();
  keyController.connect("key-pressed", (_, keyval) => {
    if (keyval === Gdk.KEY_Escape) {
      app.quit();
      return Gdk.EVENT_STOP;
    }
    return Gdk.EVENT_PROPAGATE;
  });
  win.add_controller(keyController);

  if (!STICKY) {
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
      readyForAutoClose = true;
      return GLib.SOURCE_REMOVE;
    });

    win.connect("notify::is-active", (widget) => {
      if (readyForAutoClose && !widget.is_active) {
        app.quit();
      }
    });
  }

  win.connect("close-request", () => {
    if (refreshSource !== null) {
      GLib.source_remove(refreshSource);
      refreshSource = null;
    }
    app.quit();
    return false;
  });
}

const app = new Adw.Application({
  application_id: `com.oliver.waybar.gnomepopup.${MODE}`,
  flags: Gio.ApplicationFlags.NON_UNIQUE,
});

app.connect("activate", () => {
  loadCss();

  if (windowRef) {
    windowRef.present();
    return;
  }

  windowRef =
    MODE === "clock" ? buildClockWindow(app) : createQuickSettingsWindow(app);
  attachWindowBehavior(windowRef, app);
  windowRef.present();

  if (MODE === "quick-settings") {
    refreshSource = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 3, () => {
      populateQuickSettings();
      return GLib.SOURCE_CONTINUE;
    });
  }
});

app.run([]);
