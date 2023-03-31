/* ~\~ language=JavaScript filename=main.js */
/* ~\~ begin <<README.md|main.js>>[init] */
import { Elm } from "./src/Main.elm";
import styles from "./src/main.css";
import { setupPorts } from "./src/ports";

const key = import.meta.env.VITE_STREAMCARDANO_KEY;
const host = import.meta.env.VITE_STREAMCARDANO_HOST;
const flags = { key: key, host: host };

let app = Elm.Main.init({ flags: flags });
setupPorts(app, `https://${host}/api/v1/sse`, key);

/* ~\~ end */
