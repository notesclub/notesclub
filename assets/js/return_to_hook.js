export const ReturnToHook = {
  mounted() {
    const csrf = document
      .querySelector("meta[name='csrf-token']")
      .getAttribute("content");

    window.addEventListener("phx:page-loading-stop", (e) => {
      // Only care about LiveView navigations
      if (e.detail.kind === "patch" || e.detail.kind === "redirect") {
        const path = window.location.pathname + window.location.search;
        fetch("/_return_to", {
          method: "POST",
          headers: {
            "x-csrf-token": csrf,
            "content-type": "application/x-www-form-urlencoded",
          },
          body: `path=${encodeURIComponent(path)}`,
        });
      }
    });
  },
};
