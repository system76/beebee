# BeeBee

[![BB-8](http://vignette2.wikia.nocookie.net/starwars/images/6/63/BB-8thumbsup.png/revision/latest/scale-to-width-down/220?cb=20160402062321)](http://starwars.wikia.com/wiki/BB-8)

## Requirements

BeeBee requires Elixir >= 1.10 and Redis >= 3.0.

## Setup

1. run `mix deps.get`
2. run `mix run --no-halt`
3. enjoy!

## Usage

BeeBee exposes two API endpoints, `POST /_add` and `GET /_stats`.

### `POST /_add`

**Accepts:**

```js
{
  "url": "https://github.com", // URL to be shortened
  "short_tag": "github" // OPTIONAL short tag
}
```

If a short tag is omitted, one will be randomly generated for you.

**Returns:**

```js
{
  "short_tag": "github" // Short tag now mapped to the provided URL
}
```

### `GET /_stats`

**Returns:**

```js
[
  {
    "short_tag": "github",
    "url": "https://github.com",
    "count": 0
  },
  // ...
]
```

Any other route will try and find a matching short tag, increment the count, and
return a 301 to the provided URL.

A 404 with an empty body will be returned for missing short tags
