# CoolblueScraper

- scrapper for products in www.coolblue.nl 

## Testing 
```elixir
mix deps.get
```
set urls in priv/test.exs
```elixir
mix run priv/test
```

or do 

```elixir
iex -S mix
```
and then

```elixir
url = [ list of urls ]
Scraper.start_link(urls: urls)
```

