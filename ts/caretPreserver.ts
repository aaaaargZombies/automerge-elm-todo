const template = document.createElement("template");
template.innerHTML = `<input type='text'/>`;

// TODO: types are a bit of a mess

export class CaretPreserver extends HTMLElement {
  private inputNode: HTMLInputElement;

  static get observedAttributes() {
    return ["value", "style", "placeholder"];
  }

  constructor() {
    super();

    this.attachShadow({
      mode: "open",
    });
    this.shadowRoot!.appendChild(template.content.cloneNode(true));

    // Cache the value of the inputNode
    this.inputNode =
      this.shadowRoot!.querySelector("input") ||
      document.createElement("input");

    for (let i = 0; i < this.attributes.length; i++) {
      this.inputNode.setAttribute(
        this.attributes[i]!.nodeName,
        this.attributes[i]!.nodeValue || "",
      );
      this.removeAttribute(this.attributes[i]!.nodeName);
    }
  }

  connectedCallback() {}

  get value() {
    return this.inputNode.value;
  }

  attributeChangedCallback(name: string, oldValue: string, newValue: string) {
    if (oldValue !== newValue) {
      if (name === "value") {
        const caretPositionBefore = this.inputNode.selectionStart;
        this.inputNode.value = newValue;
        const caretPositionAfter = this.inputNode.selectionStart;
        if (caretPositionBefore != caretPositionAfter) {
          console.log(
            `Restoring caret position from ${caretPositionAfter} to ${caretPositionBefore}`,
          );
          this.inputNode.setSelectionRange(
            caretPositionBefore,
            caretPositionBefore,
          );
        }
      } else {
        // TODO - Remove redundant key-value pairs and remove
        //        styles from "this"
        this.inputNode.setAttribute(name, newValue);
      }
    }
  }
}
