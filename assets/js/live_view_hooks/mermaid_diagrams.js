import mermaid from "mermaid";

export default {
  mounted() {
    renderMermaidDiagrams();
  }
}

const renderMermaidDiagrams = () => {
  mermaid.initialize({ startOnLoad: false });
  let id = 0;
  // After every iteration of the loop we need to call getElementsByClassName again
  // because the previous iteration changed the DOM
  let codeEl;
  while (codeEl = document.getElementsByClassName("mermaid")[0]) {
    const preEl = codeEl.parentElement;
    const graphDefinition = codeEl.textContent;
    const graphEl = document.createElement("div");
    const graphId = "mermaid-graph-" + id++;
    mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
      graphEl.innerHTML = svgSource;
      bindListeners && bindListeners(graphEl);
      preEl.insertAdjacentElement("afterend", graphEl);
      preEl.remove();
    });
  }
}
