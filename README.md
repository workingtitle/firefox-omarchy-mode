# Firefox Omarchy Mode

Makes Firefox look like it belongs in Omarchy. Tabs, toolbar, address bar,
menus and sidebar take the colors of your active Omarchy theme and follow along
whenever you switch themes.

![Firefox in Omarchy mode](preview.png)

- **Theme colors** from the current theme's `colors.toml`, in light and dark themes
- **Square corners** on tabs, address bar, buttons, menus and panels
- **No close button** in the tab strip. You close windows with your Hyprland keybinding.
- **Flush tabs** with no space around them, or compact tabs with 1px

Every feature can be switched off on its own.

## How the bar icon works

The icon only shows up while Firefox is **not** in Omarchy mode:

| Icon    | Meaning                                                              |
|---------|----------------------------------------------------------------------|
| visible | Omarchy mode is not enabled yet: click it and enable it              |
| visible | Firefox is running with the old look: restart Firefox                |
| hidden  | Firefox is in Omarchy mode, and the plugin syncs in the background   |

Firefox reads its interface stylesheet only at startup. After every theme
switch or settings change, the icon comes back until you restart Firefox.

## Install

```bash
omarchy plugin add https://github.com/workingtitle/firefox-omarchy-mode.git --enable
```

Then click the Firefox icon in the bar, choose **Enable Omarchy mode**, and
restart Firefox.

Installing the plugin changes nothing in Firefox. Firefox is only modified once
you click **Enable Omarchy mode**.

## Settings

The switches are in the panel. They also appear in the widget's bar settings,
and the values are stored in `~/.config/omarchy/shell.json`.

| Setting             | Default | Effect                                                   |
|---------------------|---------|----------------------------------------------------------|
| `colors`            | `true`  | Use the Omarchy theme colors in the browser UI           |
| `squareCorners`     | `true`  | Square corners on tabs, address bar, buttons and menus   |
| `hideWindowButtons` | `true`  | Hide the close (and minimize/maximize) button in the tab strip |
| `tabSpacing`        | `flush` | `flush`: no space around tabs, a little more room inside; `compact`: 1px above and below; `default`: Firefox's spacing |

## What it changes

For every profile listed in Firefox's `profiles.ini` (native and Flatpak
Firefox), the plugin writes three files:

| File                       | Change                                                     |
|----------------------------|------------------------------------------------------------|
| `chrome/omarchy-mode.css`  | Generated stylesheet, rewritten on every theme change      |
| `chrome/userChrome.css`    | One `@import` line at the top; your own rules stay intact  |
| `user.js`                  | Enables `toolkit.legacyUserProfileCustomizations.stylesheets` |

Every line the plugin adds carries the marker `omarchy-firefox-mode`, so it can
remove exactly what it added. The plugin never uses the network or root privileges, and
it only writes to your Firefox profiles and `~/.local/state/omarchy-firefox-mode/`.

## Turning it off and uninstalling

While Firefox is in Omarchy mode, the icon is hidden, so turn the mode off from
a terminal:

```bash
~/.config/omarchy/plugins/io.github.workingtitle.firefox-omarchy-mode/firefox-omarchy-mode disable
```

Restart Firefox, and it looks like stock Firefox again. `disable` deletes
`omarchy-mode.css` and removes only the marked lines from `userChrome.css` and
`user.js`. It deletes each of those files only if nothing else is left in it.
Firefox keeps the stylesheet preference in `prefs.js`. It does nothing without a
stylesheet, and you can reset it in `about:config`.

To uninstall, run `disable` **first**, because `omarchy plugin remove` cannot
run any cleanup code:

```bash
~/.config/omarchy/plugins/io.github.workingtitle.firefox-omarchy-mode/firefox-omarchy-mode disable
omarchy plugin remove io.github.workingtitle.firefox-omarchy-mode
```

## Command line

The helper script also works on its own. For example, you can call it from an
Omarchy hook:

```bash
firefox-omarchy-mode status     # JSON status, used by the bar widget
firefox-omarchy-mode enable     # opt in and apply
firefox-omarchy-mode sync       # re-apply if enabled (no-op when nothing changed)
firefox-omarchy-mode disable    # remove everything again

# enable and sync accept:
#   --colors on|off  --corners square|rounded
#   --window-buttons show|hide  --tabs flush|compact|default
```

Options you pass are remembered for later runs without options. While the bar
widget is running, its settings take precedence.

## Troubleshooting

- **The icon does not go away.** Quit Firefox completely, including every
  window, and start it again. Firefox loads its stylesheet only at startup.
- **Firefox looks partly default after a Firefox update.** `userChrome.css` is
  not an official Firefox API, and Mozilla sometimes renames internal
  variables. Firefox still works. Update the plugin with
  `omarchy plugin update io.github.workingtitle.firefox-omarchy-mode`, or open
  an issue.
- **A profile is not themed.** Only profiles listed in `profiles.ini` are
  picked up. `firefox-omarchy-mode status` lists them.
- **Overriding a rule.** The plugin's rules use `!important`. To override one
  in your own `userChrome.css`, which comes after the `@import`, mark your rule
  `!important` as well.

## Requirements

- Omarchy with the Quickshell-based bar
- Firefox 155 or newer (native or Flatpak)
- `jq` and `flock`, both part of a standard Omarchy install

## License

[MIT](LICENSE)
