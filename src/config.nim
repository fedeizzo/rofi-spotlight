import tables

const defaultNoMatch*: Table[string, string] = {
  "google": "xdg-open 'https://www.google.com/search?q=",
  "duck": "xdg-open 'https://www.duckduckgo.com/?q="
}.toTable
