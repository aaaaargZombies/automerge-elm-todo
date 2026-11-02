import "~/css/style.css";
import { Elm } from "~/elm/Main.elm";
import {
  Repo,
  BroadcastChannelNetworkAdapter,
  IndexedDBStorageAdapter,
} from "@automerge/vanillajs";

const repo = new Repo({
  network: [new BroadcastChannelNetworkAdapter()],
  storage: new IndexedDBStorageAdapter(),
});

window.repo = repo;

const app = Elm.Main.init({
  node: document.querySelector("#elm-app"),
});

if (app.ports && app.ports.outgoing) {
  app.ports.outgoing.subscribe(async ({ tag, data }) => {
    switch (tag) {
      case "COUNT":
        console.log(data);
        break;

      default:
        never(tag);
        break;
    }
  });
}

const never = (_: never) => {};
