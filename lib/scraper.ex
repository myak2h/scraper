defmodule Scraper do
  use GenServer
  require Logger

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:get_tab, _from, %{tabs: tabs} = state) do
    free_tab = tabs |> Enum.find(& &1.free)

    case free_tab do
      nil ->
        {:reply, nil, state}

      tab ->
        tab = %{tab | free: false}

        tabs =
          tabs
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

  @impl true
  def handle_cast(
        {:add_tab, id},
        %{server: server, tabs: tabs} = state
      ) do
    page =
      case id do
        1 ->
          {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)
          List.first(pages)

        _ ->
          {:ok, page} = ChromeRemoteInterface.Session.new_page(server)
          page
      end

    {:ok, pid} = ChromeRemoteInterface.PageSession.start_link(page)

    ChromeRemoteInterface.RPC.Page.enable(pid)

    tab = %{id: id, free: true, pid: pid}

    {:noreply, %{state | tabs: tabs ++ [tab]}}
  end

  @impl true
  def handle_cast({:free_tab, tab}, %{tabs: tabs} = state) do
    tab = %{tab | free: true}

    tabs =
      tabs
      |> Enum.map(fn t ->
        if t.pid == tab.pid do
          tab
        else
          t
        end
      end)

    {:noreply, %{state | tabs: tabs}}
  end

  def start_link(urls: urls) do
    server = ChromeRemoteInterface.Session.new()

    {:ok, pid} =
      GenServer.start_link(__MODULE__, %{tabs: [], results: [], server: server}, name: __MODULE__)

    add_tabs()

    IO.inspect(%{
      products:
        urls
        |> Enum.map(fn url ->
          Task.async(fn -> scrap(url) end)
        end)
        |> Enum.map(&Task.await(&1, :infinity))
    })

    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

    pages
    |> Enum.each(&ChromeRemoteInterface.Session.close_page(server, &1["id"]))
  end

  defp scrap(url) do
    case GenServer.call(__MODULE__, :get_tab, :infinity) do
      nil ->
        scrap(url)

      tab ->
        ChromeRemoteInterface.RPC.Page.enable(tab.pid)
        ChromeRemoteInterface.PageSession.subscribe(tab.pid, "Page.loadEventFired")
        ChromeRemoteInterface.RPC.Page.navigate(tab.pid, %{url: url})

        receive do
          {:chrome_remote_interface, "Page.loadEventFired", _message} ->
            ChromeRemoteInterface.PageSession.unsubscribe(tab.pid, "Page.loadEventFired")

            {:ok, %{"result" => %{"root" => %{"nodeId" => root_node_id}}}} =
              ChromeRemoteInterface.RPC.DOM.getDocument(tab.pid)

            result = Scraper.Helper.get_product_detail(tab.pid, root_node_id)
            GenServer.cast(__MODULE__, {:free_tab, tab})
            result
        end
    end
  end

  defp add_tabs(n \\ 5) do
    1..n
    |> Enum.each(&GenServer.cast(__MODULE__, {:add_tab, &1}))
  end
end
