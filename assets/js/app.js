// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/game_of_life";
import topbar from "../vendor/topbar";

let Hooks = {};

Hooks.ScreenSize = {
  mounted() {
    this.pushDimensions();
    window.addEventListener("resize", () => this.pushDimensions());
  },
  pushDimensions() {
    this.pushEvent("screen_size", {
      width: window.innerWidth,
      height: window.innerHeight,
    });
  },
};

Hooks.BoardDropzone = {
  mounted() {
    let painting = false;
    let painted = new Set();
    let dragging = false;

    const cellCoords = (e) => {
      const rect = this.el.getBoundingClientRect();
      const cols = Number(this.el.dataset.cols);
      const rows = Number(this.el.dataset.rows);
      const j = Math.floor((e.clientX - rect.left) / (rect.width / cols));
      const i = Math.floor((e.clientY - rect.top) / (rect.height / rows));
      if (i < 0 || j < 0 || i >= rows || j >= cols) return null;
      return { i, j };
    };

    const paintCell = (e) => {
      const cell = cellCoords(e);
      if (!cell) return;
      const key = `${cell.i},${cell.j}`;
      if (painted.has(key)) return;
      painted.add(key);

      // optimistic local update — find the td and mark it dark immediately
      const cols = Number(this.el.dataset.cols);
      const tds = this.el.querySelectorAll("td");
      const td = tds[cell.i * cols + cell.j];
      if (td) {
        td.classList.remove("board-cell-light");
        td.classList.add("board-cell-dark");
      }
    };

    const endStroke = () => {
      if (!painting) return;
      painting = false;
      if (painted.size > 0) {
        const cells = Array.from(painted).map((k) => {
          const [i, j] = k.split(",").map(Number);
          return { i, j };
        });
        this.pushEvent("paint", { cells });
      }
      painted = new Set();
    };

    this.el.addEventListener("mousedown", (e) => {
      if (e.button !== 0 || dragging) return;
      painting = true;
      paintCell(e);
    });

    this.el.addEventListener("mousemove", (e) => {
      if (painting) paintCell(e);
    });

    this.el.addEventListener("mouseup", endStroke);
    this.el.addEventListener("mouseleave", endStroke);

    this.el.addEventListener("dragstart", () => { dragging = true; painting = false; painted = new Set(); });
    this.el.addEventListener("dragend", () => { dragging = false; });

    this.el.addEventListener("dragover", (e) => {
      e.preventDefault();
      this.el.classList.add("drag-over");
      e.dataTransfer.dropEffect = "copy";
    });

    this.el.addEventListener("dragleave", () => {
      this.el.classList.remove("drag-over");
    });

    this.el.addEventListener("drop", (e) => {
      e.preventDefault();
      this.el.classList.remove("drag-over");

      const pattern = JSON.parse(e.dataTransfer.getData("application/json"));
      const cell = cellCoords(e);
      if (!cell) return;

      this.pushEvent("drop_pattern", { i: cell.i, j: cell.j, pattern });
    });
  }
}

Hooks.Pattern = {
  mounted() {
    this.el.addEventListener("dragstart", (e) => {
      e.dataTransfer.effectAllowed = "copy";

      e.dataTransfer.setData(
        "application/json",
        this.el.dataset.pattern
      );
    });
  }
}



const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks, ...Hooks },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}
