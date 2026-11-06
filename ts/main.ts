import "~/css/style.css";
import { Elm } from "~/elm/Main.elm";
import {
  Repo,
  BroadcastChannelNetworkAdapter,
  IndexedDBStorageAdapter,
  isValidAutomergeUrl,
  DocHandle,
} from "@automerge/vanillajs";

const repo = new Repo({
  network: [new BroadcastChannelNetworkAdapter()],
  storage: new IndexedDBStorageAdapter(),
});

window.repo = repo;

// TODO: need to get rid of this useless assignment
let handle = repo.create<{ todos: Todo[] }>({
  todos: [{ done: false, name: "this is the init value" }],
});

const newHandle = () =>
  repo.create<{ todos: Todo[] }>({
    todos: [{ done: false, name: "this is the init value" }],
  });

const getOrCreateHandle = async (
  url: String,
): Promise<DocHandle<{ todos: Todo[] }>> => {
  if (isValidAutomergeUrl(url)) {
    return repo.find<{ todos: Todo[] }>(url).catch((_) => newHandle());
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
      case "GET_TODOS":
        handle = await getOrCreateHandle(data);

        handle.on("change", (evt) => {
          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: evt.doc?.todos || [],
          });
        });

        if (handle.url === data) {
          app.ports.incoming.send({
            tag: "SYNCHED_TODOS",
            data: handle.doc()?.todos || [],
          });
        } else {
          app.ports.incoming.send({
            tag: "HANDLE_CHANGED",
            data: handle.url,
          });
        }
        break;

      case "ADD_TODO":
        handle.change((doc) => doc.todos.unshift({ done: false, name: "" }));
        break;

      case "MARK_TODO":
        handle.change((doc) => {
          if (doc.todos[data]) {
            doc.todos[data].done = !doc.todos[data].done;
          }
        });
        break;
      case "RENAME_TODO":
        handle.change((doc) => {
          const { id, name } = data;
          if (doc.todos[id]) {
            doc.todos[id].name = name;
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
