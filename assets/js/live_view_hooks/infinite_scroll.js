export default {
  mounted() {
    this.el.addEventListener("scroll", () => {
      const scrollPercent = this.el.scrollTop / (this.el.scrollHeight - this.el.clientHeight) * 100;
      if (scrollPercent > 80) {
        this.pushEvent("load-more");
      }
    })
  }
}
