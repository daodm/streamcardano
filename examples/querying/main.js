/* ~\~ language=JavaScript filename=main.js */
import { Elm } from "./src/Main.elm";
import styles from "./src/main.css";

const key = import.meta.env.VITE_STREAMCARDANO_KEY;
const host = import.meta.env.VITE_STREAMCARDANO_HOST;
const flags = { host: host, key: key };

let app = Elm.Main.init({ flags: flags });
import { setupPorts } from "./src/ports";

setupPorts(app, `https://${host}/api/v1/sse`, key);
