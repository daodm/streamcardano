# Executable Script

```{.sh file=runit.sh}
<<runit>>
```
# 
```{.html file=index.html}
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>StreamCardano Charts</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/main.js"></script>
  </body>
</html>
```

# Default styles

```{.css file=src/main.scss}
@use '@carbon/styles/scss/components/ui-shell';
@use '@carbon/styles/scss/components/menu';
@use '@carbon/styles/scss/components/notification';
@use '@carbon/styles/scss/components/tabs';
@use '@carbon/styles/scss/grid';
@use '@carbon/styles/scss/layer';

@use '@carbon/styles/scss/reset';
@use '@carbon/styles/scss/type';
@use '@carbon/themes/scss/themes' as *;
@use '@carbon/themes';

:root {
  @include themes.theme($g90);
}

[data-carbon-theme='g10'] {
  @include themes.theme($g10);
}

[data-carbon-theme='g90'] {
  @include themes.theme($g90);
}

[data-carbon-theme='g100'] {
  @include themes.theme($g100);
}


// Emit the flex-grid styles
@include grid.flex-grid();

.main{
    margin-left: 0;
    margin-top: 3rem;
    min-height: calc(100vh - 48px);
    position: relative;
    transition: .25s ease;
    width: 100%;

    .header {
        height: 20rem;
        background-color: #000;
        color: #fff;
        height: 16rem;
        width: 100%;
        .title {
            padding-top: 4rem;
        }
        .notification {
            padding-top: 1rem;
        }
    }

    .tabs {
        /* background: var(--cds-layer-accent); */
        background: #000;
        padding-bottom: 1rem;

        .cds--grid {
            padding-right: 1rem;
            padding-left: 1rem;
        }

        .cds--tabs__nav-item {
        }
        .cds--tabs__nav-item--selected {
        }
    }

    .body {
        padding-top: 2rem;
    }
}
```

# Ports

```{.js file=src/ports.js}
import { fetchEventSource } from "@microsoft/fetch-event-source";

const fetchData = async (sseEndpoint, key, app) => {
  await fetchEventSource(
    sseEndpoint,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        Accept: "text/event-stream",
        "Content-Type": "text/plain;charset=utf-8",
      },
      // body: "WITH dats AS (SELECT datum.tx_id, datum.value FROM datum, tx_out WHERE datum.tx_id=tx_out.tx_id) SELECT * FROM dats ORDER BY tx_id DESC LIMIT 1",
      body: "SELECT block_no,hash,tx_count from block order by id desc LIMIT 1",
      onopen(res) {
        /**
         * @name 200 Status Code means a successful connection was made with the server
         * @name 400 Status Code means Bad Request and there is something wrong with the HTTP request
         * @name 500 Status Code means Internal Server Error a generic error
         * that indicates the server encountered an unexpected condition and can’t fulfill the request.
         * @name 429 Status Code means Too many requests. The server responds with this code
         * when the user has sent too many requests in the given time and has exceeded the rate limit.
         */
        if (res.ok && res.status === 200) {
          console.log("Connection made ", res);
        } else if (
          res.status >= 400 &&
          res.status < 500 &&
          res.status !== 429
        ) {
          console.log("Client side error ", res);
        }
      },
      onmessage(event) {
          <<portsNewBlockReceiver>>
      },
      onclose() {
        console.log("Connection closed by the server");
      },
      onerror(err) {
        console.log("There was an error from server", err);
      },
    }
  );
};

export function setupPorts(app, sseEndpoint, key) {
    <<portsLitenNewBlocks>>
}
```

