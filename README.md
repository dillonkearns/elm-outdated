# elm-outdated

Find outdated Elm dependencies. Supports both applications and packages.

Inspired by and building on the work of [gyzerok/elm-outdated](https://github.com/gyzerok/elm-outdated), which supported applications but not Elm packages.

## Usage

Run it directly in any Elm project directory:

```bash
npx elm-outdated
```

Or run it as an [elm-pages script](https://elm-pages.com):

```bash
npx elm-pages@latest run https://github.com/dillonkearns/elm-outdated/blob/main/script/src/ElmOutdated.elm
```

## What does it do?

`elm-outdated` reads your `elm.json`, checks the Elm package registry, and reports which dependencies have newer versions available. It only shows outdated packages — if everything is up to date, you'll see "All packages are up to date!"

This tool checks for outdated packages but does not update them. For updating dependencies, [elm-json](https://github.com/zwilias/elm-json) is the best tool for the job.

## Output

### Applications

- Current — the exact version pinned in your `elm.json`
- Wanted — the latest version available without a major (breaking) bump
- Latest — the absolute latest version available
![Screenshot_2026-02-13_at_10 18 44_PM](https://github.com/user-attachments/assets/4b823d94-2ae4-4e6b-90d3-9a43713072c7)


### Packages

- Current — the version range constraint from your `elm.json`
- Wanted — the latest version it is able to resolve to within that range
- Latest — the absolute latest version available
<img width="1203" height="93" alt="Screenshot_2026-02-13_at_10 31 44_PM" src="https://github.com/user-attachments/assets/133f6baf-71e5-4ff3-9e76-cb2e6b9c7ecd" />


### Color coding

When running in a color-capable terminal:

- Yellow package name — a minor/patch update is available within your constraint (Wanted > Current)
- Red package name — a major version bump is available beyond your constraint (Latest > Wanted)

Color output respects the [`NO_COLOR`](https://no-color.org/) and `FORCE_COLOR` environment variables.
