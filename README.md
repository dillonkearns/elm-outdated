# elm-outdated

Find outdated Elm dependencies. Supports both applications and packages.

Inspired by and building on the work of [gyzerok/elm-outdated](https://github.com/gyzerok/elm-outdated).

## Usage

Run it directly in any Elm project directory:

```bash
npx elm-outdated
```

Or run it as an [elm-pages script](https://elm-pages.com):

```bash
elm-pages run https://github.com/dillonkearns/elm-outdated/blob/main/script/src/ElmOutdated.elm
```

## What does it do?

`elm-outdated` reads your `elm.json`, checks the Elm package registry, and reports which dependencies have newer versions available. It only shows outdated packages — if everything is up to date, you'll see "All packages are up to date!"

This tool checks for outdated packages but does not update them. For updating dependencies, [elm-json](https://github.com/zwilias/elm-json) is the best tool for the job.

## Output

### Applications

For applications, **Current** is the exact version pinned in your `elm.json`, and **Wanted** is the latest version available without a major (breaking) bump:

```
Package            Current  Wanted  Latest
elm/json           1.1.3    1.1.4   1.1.4
some/long-package  1.0.0    1.1.0   2.0.0
```

### Packages

For packages, **Current** shows the version range constraint from your `elm.json`, and **Wanted** is the latest version it is able to resolve to within that range:

```
Package                              Current              Wanted  Latest
dillonkearns/elm-cli-options-parser  3.0.0 <= v < 4.0.0  3.2.0   4.0.0
```

### Column reference

| Column      | Description                                                   |
| ----------- | ------------------------------------------------------------- |
| **Current** | Your `elm.json` constraint (exact version or range)           |
| **Wanted**  | Latest version satisfying your constraint                     |
| **Latest**  | Absolute latest version available                             |

### Color coding

When running in a color-capable terminal:

- **Yellow** package name — a minor/patch update is available within your constraint (Wanted > Current)
- **Red** package name — a major version bump is available beyond your constraint (Latest > Wanted)

Color output respects the [`NO_COLOR`](https://no-color.org/) and `FORCE_COLOR` environment variables.

## Development

```bash
npm install
npm test
npm run build
```

