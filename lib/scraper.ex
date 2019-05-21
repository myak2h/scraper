defmodule Scraper do
  use GenServer
  require Logger

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  def handle_call(:get_tab, _from, %{tabs: tabs, server: server} = state) do
    case {length(tabs), tabs |> Enum.find(&(&1.locked == false))} do
      {x, _} when x == 0 ->
        {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

        page = List.first(pages)

        {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(page)

        tab = %{page: page, locked: true, pid: page_pid}

        {:reply, tab, %{state | tabs: tabs ++ [tab]}}

      {x, _} when x > 0 and x < 5 ->
        {:ok, page} = ChromeRemoteInterface.Session.new_page(server)

        {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(page)

        tab = %{page: page, locked: true, pid: page_pid}

        {:reply, tab, %{state | tabs: tabs ++ [tab]}}

      {_, nil} ->
        {:reply, nil, state}

      {_, tab} ->
        tab = %{tab | locked: true}

        tabs =
          state.tabs
          |> Enum.map(fn t ->
            if t.pid == tab.pid do
              tab
            else
              t
            end
          end)

        {:reply, tab, %{state | tabs: tabs}}
    end
  end

  def handle_call(:get_results, _from, %{results: results} = state) do
    {:reply, results, state}
  end

  def handle_cast(
        {:scrap, %{url: url, tab: tab}},
        state
      ) do
    ChromeRemoteInterface.RPC.Page.enable(tab.pid)
    ChromeRemoteInterface.PageSession.subscribe(tab.pid, "Page.loadEventFired")
    ChromeRemoteInterface.RPC.Page.navigate(tab.pid, %{url: url})

    receive do
      {:chrome_remote_interface, "Page.loadEventFired", _message} ->
        ChromeRemoteInterface.PageSession.unsubscribe(tab.pid, "Page.loadEventFired")

        {:ok, %{"result" => %{"root" => %{"nodeId" => root_node_id}}}} =
          ChromeRemoteInterface.RPC.DOM.getDocument(tab.pid)

        result = Scraper.Helper.get_product_detail(tab.pid, root_node_id)

        tabs =
          state.tabs
          |> Enum.map(fn t ->
            if t.pid == tab.pid do
              %{t | locked: false}
            else
              t
            end
          end)

        {:noreply, %{state | results: state.results ++ [result], tabs: tabs}}
    end
  end

  def start_link(urls: urls) do
    server = ChromeRemoteInterface.Session.new()

    {:ok, pid} =
      GenServer.start_link(__MODULE__, %{tabs: [], results: [], server: server}, name: __MODULE__)

    urls
    |> Enum.each(fn url ->
      tab = get_tab()

      GenServer.cast(
        __MODULE__,
        {:scrap, %{url: url, tab: tab}}
      )
    end)

    IO.inspect(GenServer.call(__MODULE__, :get_results))

    {:ok, pid}
  end

  defp get_tab() do
    case GenServer.call(__MODULE__, :get_tab) do
      nil -> get_tab()
      tab -> tab
    end
  end
end
