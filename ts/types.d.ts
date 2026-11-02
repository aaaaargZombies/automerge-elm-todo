declare module "*.elm" {
  namespace Elm {
    namespace Main {
      interface App {
        ports: {
          outgoing: {
            subscribe(callback: (data: Outgoing) => void): void;
          };
        };
      }
      interface Init {
        init(options: { node: HTMLElement | null }): App;
      }
    }
  }

  export const Elm: {
    Main: Elm.Main.Init;
  };
}

type Outgoing = { tag: "COUNT"; data: number };

interface Window {
  repo: import("@automerge/vanillajs").Repo;
}
