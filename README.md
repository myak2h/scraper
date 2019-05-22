# CoolblueScraper

- scrapper for products in www.coolblue.nl 

## Testing 
```elixir
mix deps.get
```
set urls in priv/test.exs and then
```elixir
mix run priv/test.exs
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

