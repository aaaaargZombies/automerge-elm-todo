# Elm Automerge experiment

Working throughthe [automerge tutorial](https://automerge.org/docs/tutorial/) to see how it integrates with elm instead of react.

## Development

### Prerequisites

- [nix](https://nix.dev/) can be installed with [Determinate Nix Installer](https://determinate.systems/nix-installer/) for Linux, MacOs and WSL

### Setup & install instructions

- `nix develop` will place you into a bash environment with system dependencies
  - install node dependancies with `npm install`
  - install elm dependancies with `prep-elm-home` - this is patched to use [`lydell/elm-safe-virtual-dom`](https://github.com/lydell/elm-safe-virtual-dom/)
  - `npm run dev` to start a dev server on [http://localhost:5173](http://localhost:5173)
  - If you add new Elm dependancies run `elm2nix lock`, this creates hashes needed for the production build
  - pre-commit hooks are set up to format, test code and ensure elm deps are added to a lock file

### Build

- `nix build` generate a production build in `result/share/`

### Testing

We're using [vitest](https://vitest.dev/) for Typescript. These tests can be colocated with the code they are testing and run using

```sh
npm run test:ts
```

We're using [elm-test-rs](https://github.com/mpizenberg/elm-test-rs) to run [elm tests](https://github.com/elm-explorations/test/). Tests for Elm code must live in `./tests` and can be run using

```sh
elm-test-rs
```

### Code & configs

#### This site is built with `Elm` and bundled by `Vite` and `elm2nix`

- [Elm's official homepage](https://elm-lang.org/)
- [Elm Package docs](https://package.elm-lang.org/)
- [Vite's official documentation.](https://vitejs.dev/)
- [Vite static asset handling](https://package.elm-lang.org/packages/hmsk/elm-vite-plugin-helper/latest/)
- [dwayne/elm2nix repo](https://github.com/dwayne/elm2nix)

#### What it's for

- `flake.nix` manages production builds and development environment
- `elm.json` for elm packages used for site
- `package.json` for node scripts and packages
- `package-lock.json` for current versions of node packages
- `vite.config.ts` for build config
- `tests/*` contains test files
- `elm/*` contains app Elm source files
- `ts/*` contains app Typescript source files
- `css/*` contains app CSS source files
- `nix/*` contains Nix code for building the Elm app and patching the virtual dom
