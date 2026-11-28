import "~/css/style.css";
import { Elm } from "~/elm/Main.elm";
import {
  Repo,
  BroadcastChannelNetworkAdapter,
  IndexedDBStorageAdapter,
  isValidAutomergeUrl,
  DocHandle,
  type AutomergeUrl,
} from "@automerge/vanillajs";
import { CaretPreserver } from "./caretPreserver";
import * as RootDoc from "./rootDoc";

declare global {
  interface Window {
    repo: Repo;
    handle: DocHandle<RootDoc.RootDocument>;
  }
}

window.customElements.define("caret-preserver", CaretPreserver);

const repo = new Repo({
  network: [new BroadcastChannelNetworkAdapter()],
  storage: new IndexedDBStorageAdapter(),
});

window.repo = repo;
const rootDocUrl = RootDoc.getOrCreateRoot(repo);
window.handle = await repo.find(rootDocUrl);

const urls = window.handle.doc()?.taskLists ?? [];

const results = await Promise.all(
  urls.map(async (url) => {
    const handle = await repo.find<Todos>(url).catch(() => null);
    return handle ? ([url, handle] as const) : null;
  }),
);

const todoLists = new Map<string, DocHandle<Todos>>(
  results.filter((entry) => entry !== null),
);

const newHandle = () =>
  repo.create<Todos>({
    title: `tasks-${Date.now()}`,
    items: [{ done: false, name: "this is the init value" }],
  });

// NOTE:: does this make sense to return the url not the handle
// shouldn't I be trying to get the handle from the Map first?
const getOrCreateHandle = async (url: string): Promise<AutomergeUrl> => {
  if (isValidAutomergeUrl(url)) {
    const handle = await repo.find<Todos>(url).catch((_) => newHandle());
    todoLists.set(handle.url, handle);
    return handle.url;
  } else {
    const handle = newHandle();
    todoLists.set(handle.url, handle);
    return handle.url;
  }
};

const app = Elm.Main.init({
  node: document.querySelector("#elm-app"),
  flags: [...todoLists.entries()].map(([k, v]) => [k, v.doc()!]),
});

if (app.ports && app.ports.outgoing) {
  app.ports.outgoing.subscribe(async ({ tag, data }) => {
    switch (tag) {
      case "ADD_TODO_LIST":
        (async () => {
          const handle = todoLists.get(await getOrCreateHandle(""));

          window.handle.change(({ taskLists }) => {
            taskLists.push(handle!.url);
          });

          handle!.on("change", (_event) => {
            app.ports.incoming.send({
              tag: "SYNCHED_TODOS",
              data: [handle!.url, handle!.doc()!],
            });
          });

          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: [handle!.url, handle!.doc()!],
          });
        })();

        break;

      case "GET_TODOS":
        (async () => {
          const handle = todoLists.get(await getOrCreateHandle(data));

          handle!.on("change", (_event) => {
            app.ports.incoming.send({
              tag: "SYNCHED_TODOS",
              data: [handle!.url, handle!.doc()!],
            });
          });

          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: [handle!.url, handle!.doc()!],
          });
          if (handle!.url === data) {
            app.ports.incoming.send({
              tag: "SYNCHED_TODOS",
              data: [handle!.url, handle!.doc()!],
            });
          } else {
            app.ports.incoming.send({
              tag: "HANDLE_CHANGED",
              data: handle!.url,
            });
          }
        })();

        break;

      case "ADD_TODO":
        (async () => {
          const handle = todoLists.get(await getOrCreateHandle(data));
          handle!.change((doc) => doc.items.unshift({ done: false, name: "" }));
        })();
        break;

      case "MARK_TODO":
        (async () => {
          const handle = todoLists.get(await getOrCreateHandle(data.url));

          handle!.change((doc) => {
            if (doc.items[data.id]) {
              doc.items[data.id]!.done = !doc.items[data.id]!.done;
            }
          });
        })();
        break;
      case "RENAME_TODO":
        (async () => {
          const handle = todoLists.get(await getOrCreateHandle(data.url));

          handle!.change((doc) => {
            if (handle!.url === data.url) {
              app.ports.incoming.send({
                tag: "SYNCHED_TODOS",
                data: [handle!.url, handle!.doc()!],
              });
            } else {
              app.ports.incoming.send({
                tag: "HANDLE_CHANGED",
                data: handle!.url,
              });
            }
            const { id, name } = data;
            if (doc.items[id]) {
              doc.items[id].name = name;
            }
          });
        })();
        break;

      default:
        never(tag);
        break;
    }
  });
}

const never = (_: never) => {};
