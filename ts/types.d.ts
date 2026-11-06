declare module "*.elm" {
  namespace Elm {
    namespace Main {
      interface App {
        ports: {
          outgoing: {
            subscribe(callback: (data: Outgoing) => void): void;
          };
          incoming: {
            send(data: Incomming): void;
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

type Outgoing =
  | { tag: "ADD_TODO"; data: null }
  | { tag: "GET_TODOS"; data: string }
  | { tag: "MARK_TODO"; data: number }
  | { tag: "RENAME_TODO"; data: { id: number; name: string } };

type Incomming =
  | { tag: "HANDLE_CHANGED"; data: string }
  | { tag: "SYNCHED_TODOS"; data: readonly Todo[] };

interface Window {
  repo: import("@automerge/vanillajs").Repo;
}

type Todo = { done: boolean; name: string };
