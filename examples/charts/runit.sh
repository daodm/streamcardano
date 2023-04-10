# ~\~ language=Bash filename=runit.sh
# ~\~ begin <<appendix.md|runit.sh>>[init]
# ~\~ begin <<README.md|runit>>[init]
npm i
npm i -D vite-plugin-elm
# ~\~ end
# ~\~ begin <<README.md|runit>>[1]
yes | npx elm init
yes | npx elm install elm/http
yes | npx elm install elm/json
yes | npx elm install krisajenkins/remotedata
yarn add @microsoft/fetch-event-source
yarn add @carbon/styles
yes | npx elm install elm/json
yes | npx elm install NoRedInk/elm-json-decode-pipeline
npm i -D elm-test 
yes | npx elm-test init
rm tests/Example.elm
yes | npx elm install elm/time
yes | npx elm install rtfeldman/elm-iso8601-date-strings
npm install --save @carbon/charts d3
# ~\~ end
# ~\~ end
