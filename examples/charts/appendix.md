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
@use '@carbon/styles/scss/reset';
@use '@carbon/styles/scss/type';
@use '@carbon/styles/scss/themes';
@use '@carbon/styles/scss/theme' with (
  $theme: themes.$g10
);
@use '@carbon/styles/scss/components/menu-button';
@use '@carbon/styles/scss/components/menu';
@use '@carbon/styles/scss/components/ui-shell';
@use '@carbon/styles/scss/components/notification';
// @use '@carbon/styles';
@use '@carbon/styles/scss/grid';

// Emit the flex-grid styles
@include grid.flex-grid();

.container {
    margin-left: 0;
    margin-top: 4rem;
    min-height: calc(100vh - 48px);
    position: relative;
    transition: .25s ease;
    width: 100%;
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

