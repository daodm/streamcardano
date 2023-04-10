/* ~\~ language=JavaScript filename=main.js */
/* ~\~ begin <<README.md|main.js>>[init] */
import { Elm } from "./src/Main.elm";
import styles from "./src/main.scss";
import { setupPorts } from "./src/ports";
import "@carbon/styles/css/styles.css";

import "@carbon/charts/styles.css";
import { StackedBarChart } from "@carbon/charts";

const chartHolder = document.getElementById("my-bar-chart");

const stackedBarData = [
  { group: 'Qty', value: 65000 },
  { group: 'More', value: 29123 },
  { group: 'Sold', value: 35213 },
  { group: 'Restocking', value: 51213 },
  { group: 'Misc', value: 16932 },

];

const stackedBarOptions = {
	title: 'Vertical simple bar (discrete)',
	axes: {
		left: {
			mapsTo: 'value',
		},
		bottom: {
			mapsTo: 'group',
			scaleType: 'labels',
		},
	},

};

// initialize the chart
new StackedBarChart(chartHolder, {
  data: stackedBarData,
  options: stackedBarOptions,
});

const key = import.meta.env.VITE_STREAMCARDANO_KEY;
const host = import.meta.env.VITE_STREAMCARDANO_HOST;
const flags = { key: key, host: host };

// let app = Elm.Main.init({ flags: flags });
// setupPorts(app, `https://${host}/api/v1/sse`, key);

/* ~\~ end */
