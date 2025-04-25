import mermaid from "mermaid";

export default {
  mounted() {
    this.renderMermaidDiagrams();
  },
  updated() {
    this.renderMermaidDiagrams();
  },
  renderMermaidDiagrams() {
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: 'loose',
      theme: 'default'
    });

    const mermaidElements = this.el.getElementsByClassName("mermaid");
    Array.from(mermaidElements).forEach((element) => {
      try {
        const graphDefinition = element.textContent.trim();
        const graphId = element.id || `mermaid-${Math.random().toString(36).substr(2, 9)}`;

        mermaid.render(graphId, graphDefinition)
          .then(({ svg }) => {
            element.innerHTML = svg;
          })
          .catch((error) => {
            console.error('Mermaid rendering error:', error);
            element.innerHTML = `<div class="error">Error rendering Mermaid diagram: ${error.message}</div>`;
          });
      } catch (error) {
        console.error('Mermaid initialization error:', error);
        element.innerHTML = `<div class="error">Error initializing Mermaid diagram: ${error.message}</div>`;
      }
    });
  }
}
