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
        init(options: {
          node: HTMLElement | null;
          flags: [string, Todos][];
        }): App;
      }
    }
  }

  export const Elm: {
    Main: Elm.Main.Init;
  };
}

type Outgoing =
  | { tag: "ADD_TODO_LIST"; data: null }
  | { tag: "ADD_TODO"; data: string }
  | { tag: "GET_TODOS"; data: string }
  | { tag: "MARK_TODO"; data: { url: string; id: number } }
  | { tag: "RENAME_TODO"; data: { url: string; id: number; name: string } };

type Incomming =
  | { tag: "HANDLE_CHANGED"; data: string }
  | { tag: "SYNCHED_TODOS"; data: [string, Todos] };

type Todo = { done: boolean; name: string };

type Todos = {
  title: string;
  items: Todo[];
};
