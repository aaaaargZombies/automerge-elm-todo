import "~/css/style.css";
import { Elm } from "~/elm/Main.elm";
import {
  Repo,
  BroadcastChannelNetworkAdapter,
  IndexedDBStorageAdapter,
} from "@automerge/vanillajs";

const repo = new Repo({
  // network: [new BroadcastChannelNetworkAdapter()],
  // storage: new IndexedDBStorageAdapter(),
});

window.repo = repo;

const handle = repo.create<{ todos: Todo[] }>({
  todos: [{ done: false, name: "this is the init value" }],
});

// temp for messing about in the console
window.handle = handle;

const app = Elm.Main.init({
  node: document.querySelector("#elm-app"),
});

if (app.ports && app.ports.outgoing) {
  app.ports.outgoing.subscribe(async ({ tag, data }) => {
    switch (tag) {
      case "GET_TODOS":
        console.log("TODOS PLEASE", handle.doc());
        app.ports.incoming.send({
          tag: "SYNCHED_TODOS",
          data: handle.doc()?.todos || [],
        });
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

handle.on("change", (evt) => {
  app.ports.incoming.send({
    tag: "SYNCHED_TODOS",
    data: evt.doc?.todos || [],
  });
});

const never = (_: never) => {};
