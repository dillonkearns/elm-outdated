# elm-outdated-new

A rewrite of [elm-outdated](https://github.com/gyzerok/elm-outdated) as an [elm-pages](https://elm-pages.com) script, intended to support both applications and packages.

Inspired by and building on the work of [gyzerok/elm-outdated](https://github.com/gyzerok/elm-outdated).

## Usage

```bash
npm install
elm-pages run script/src/ElmOutdated.elm
```

The script reads `elm.json` in the current directory, fetches the Elm package registry, and reports which dependencies have newer versions available:

```
Package   Current  Wanted  Latest
elm/json  1.1.3    1.1.4   1.1.4
```

- **Current** -- the version in your `elm.json`
- **Wanted** -- the latest version with the same major version (safe to upgrade)
- **Latest** -- the absolute latest version available

Only outdated packages are shown. If everything is up to date, you'll see "All packages are up to date!"

## Running tests

```bash
npm test
```

