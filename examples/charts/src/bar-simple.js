import chartStyles from "@carbon/charts/styles.css";
import { StackedBarChart, AreaChart } from "@carbon/charts";

export class BarSimple extends HTMLElement {
  constructor() {
    super();
    this._chart = null
    this._data = null
  }

  connectedCallback () {
    // first  check if the property is set
    let data = this._data
    let title = this.getAttribute('title')
    this.createChart(title, data)
  }

  createChart (title, data) {
    const stackedBarData = []
    const stackedBarOptions = {
      title: title, 
      axes: {
	left: {
	  mapsTo: 'value',
	},
	bottom: {
          title: 'Blocks',
	  mapsTo: 'group',
	  scaleType: 'labels',
	},
      },
      height: "400px",
    };

    this.attachShadow({ mode: "open" });
    const wrapper = document.createElement("div");

    const style = document.createElement("style");
    style.textContent = chartStyles

    this._chart = new StackedBarChart(wrapper, {
      data: data,
      options: stackedBarOptions,
    });

    this.shadowRoot.append(style, wrapper);

  }
  
  set chartData (newValue) {
    this._data = newValue
  }

  get chartData () {
    return this._data
  }

  disconnectCallback () {}
}

export class AreaBounded extends HTMLElement {
  constructor() {
    super();
    this._chart = null
    this._data = null
  }

  connectedCallback () {
    // first  check if the property is set
    let data = this._data
    let title = this.getAttribute('title')
    this.createChart(title, data)
  }

  createChart (title, data) {
    const options = {
      title: title, 
      axes: {
	bottom: {
	  mapsTo: 'date',
	  scaleType: 'time',
	},
	left: {
	  mapsTo: 'value',
          scaleType: 'linear',
	},
      },
      height: "400px",
    };

    this.attachShadow({ mode: "open" });
    const wrapper = document.createElement("div");

    const style = document.createElement("style");
    style.textContent = chartStyles

    this._chart = new AreaChart(wrapper, {
      data: data,
      options: options,
    });

    this.shadowRoot.append(style, wrapper);

  }
  
  set chartData (newValue) {
    this._data = newValue
  }

  get chartData () {
    return this._data
  }

  disconnectCallback () {}
}
