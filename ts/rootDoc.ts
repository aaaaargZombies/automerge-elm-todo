import { type Repo, type AutomergeUrl } from "@automerge/vanillajs";

export type RootDocument = {
  taskLists: AutomergeUrl[];
};

const ROOT_DOC_URL_KEY = "root-doc-url";

export const getOrCreateRoot = (repo: Repo): AutomergeUrl => {
  // Check if we already have a root document
  const existingUrl = localStorage.getItem(ROOT_DOC_URL_KEY);
  if (existingUrl) {
    return existingUrl as AutomergeUrl;
  }

  // Otherwise create one and (synchronously) store it
  const root = repo.create<RootDocument>({ taskLists: [] });
  localStorage.setItem(ROOT_DOC_URL_KEY, root.url);
  return root.url;
};
