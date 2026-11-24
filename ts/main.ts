import "~/css/style.css";
import { Elm } from "~/elm/Main.elm";
import {
  Repo,
  BroadcastChannelNetworkAdapter,
  IndexedDBStorageAdapter,
  isValidAutomergeUrl,
  DocHandle,
} from "@automerge/vanillajs";
import { CaretPreserver } from "./caretPreserver";
import type { RootDocument } from "./rootDoc";

declare global {
  interface Window {
    repo: Repo;
    handle: DocHandle<RootDocument>;
  }
}

window.customElements.define("caret-preserver", CaretPreserver);

const repo = new Repo({
  network: [new BroadcastChannelNetworkAdapter()],
  storage: new IndexedDBStorageAdapter(),
});

window.repo = repo;

const newHandle = () =>
  repo.create<Todos>({
    title: `tasks-${Date.now()}`,
    items: [{ done: false, name: "this is the init value" }],
  });

// TODO: need to get rid of this useless assignment
// only there so types are happy
let handle = newHandle();

const getOrCreateHandle = async (url: String): Promise<DocHandle<Todos>> => {
  if (isValidAutomergeUrl(url)) {
    return repo.find<Todos>(url).catch((_) => newHandle());
  } else {
    return newHandle();
  }
};

const app = Elm.Main.init({
  node: document.querySelector("#elm-app"),
});

if (app.ports && app.ports.outgoing) {
  app.ports.outgoing.subscribe(async ({ tag, data }) => {
    switch (tag) {
      case "ADD_TODO_LIST":
        handle = await getOrCreateHandle("");

        handle.on("change", (_event) => {
          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: [handle.url, handle.doc()!],
          });
        });

        app.ports.incoming.send({
          tag: "SYNCHED_TODOS",
          data: [handle.url, handle.doc()!],
        });
        break;

      case "GET_TODOS":
        handle = await getOrCreateHandle(data);

        handle.on("change", (_event) => {
          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: [handle.url, handle.doc()!],
          });
        });

        if (handle.url === data) {
          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: [handle.url, handle.doc()!],
          });
        } else {
          app.ports.incoming.send({
            tag: "HANDLE_CHANGED",
            data: handle.url,
          });
        }
        break;

      case "ADD_TODO":
        handle.change((doc) => doc.items.unshift({ done: false, name: "" }));
        break;

      case "MARK_TODO":
        handle.change((doc) => {
          if (doc.items[data]) {
            doc.items[data].done = !doc.items[data].done;
          }
        });
        break;
      case "RENAME_TODO":
        handle.change((doc) => {
          const { id, name } = data;
          if (doc.items[id]) {
            doc.items[id].name = name;
          }
        });
        break;

      default:
        never(tag);
        break;
    }
  });
}

const never = (_: never) => {};
