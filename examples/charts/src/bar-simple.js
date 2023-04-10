import chartStyles from "@carbon/charts/styles.css";
import { StackedBarChart } from "@carbon/charts";

export class BarSimple extends HTMLElement {
  constructor() {
    // Always call super first in constructor
    super();


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

    // write element functionality in here
    this.attachShadow({ mode: "open" });
    const wrapper = document.createElement("div");


    const style = document.createElement("style");
    style.textContent = chartStyles

    new StackedBarChart(wrapper, {
      data: stackedBarData,
      options: stackedBarOptions,
    });

   this.shadowRoot.append(style, wrapper);
  }
}

