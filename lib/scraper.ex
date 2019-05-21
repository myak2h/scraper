defmodule Scraper do
  use GenServer
  require Logger

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  def handle_call(:get_finished_tabs, _from, %{tabs: tabs} = state) do
    {:reply, Enum.find(tabs, &(&1.finished == true)), state}
  end

  def handle_call(:get_results, _from, %{results: results} = state) do
    {:reply, results, state}
  end

  def handle_cast({:add_tab, tab}, state) do
    {:noreply, %{state | tabs: state.tabs ++ [tab]}}
  end

  def handle_cast({:add_result, result}, state) do
    {:noreply, %{state | results: state.results ++ [result]}}
  end

  def handle_cast(
        {:scrap, %{url: url, tab: tab}},
        state
      ) do
    ChromeRemoteInterface.RPC.Page.navigate(tab.pid, %{url: url})

    title_task = Task.async(fn -> get_title(tab.pid) end)

    title = Task.await(title_task)

    tabs =
      state.tabs
      |> Enum.map(fn t ->
        if t == tab do
          %{t | finished: true}
        end
      end)

    {:noreply, %{results: state.results ++ [%{title: title}], tabs: tabs}}
  end

  def start_link(urls: urls) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{tabs: [], results: []}, name: __MODULE__)

    scrap(urls)
    {:ok, pid}
  end

  defp scrap(urls) do
    server = ChromeRemoteInterface.Session.new()

    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

    first_page = pages |> List.first()

    {:ok, first_page_pid} = ChromeRemoteInterface.PageSession.start_link(first_page)

    urls
    |> Enum.each(fn url ->
      tab = get_tab(server, first_page_pid)

      GenServer.cast(
        __MODULE__,
        {:scrap, %{url: url, tab: tab}}
      )
    end)

    IO.inspect(GenServer.call(__MODULE__, :get_results))
  end

  defp get_title(page_pid) do
    {:ok, doc} = ChromeRemoteInterface.RPC.DOM.getDocument(page_pid)
    node_id = doc["result"]["root"]["nodeId"]

    case ChromeRemoteInterface.RPC.DOM.querySelector(page_pid, %{
           selector: ".js-product-name",
           nodeId: node_id
         }) do
      {:ok, %{"result" => %{"nodeId" => title_node_id}}} when title_node_id != 0 ->
        {:ok, %{"result" => %{"outerHTML" => title_html}}} =
          ChromeRemoteInterface.RPC.DOM.getOuterHTML(page_pid, %{nodeId: title_node_id})

        Floki.text(title_html)

      _ ->
        get_title(page_pid)
    end
  end

  defp get_tab(server, first_page_pid) do
    case GenServer.call(__MODULE__, :get_finished_tabs) do
      nil ->
        {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

        case length(pages) <= 5 do
          true ->
            {:ok, %{"result" => %{"targetId" => target_id}}} =
              ChromeRemoteInterface.RPC.Target.createTarget(first_page_pid, %{url: "about:blank"})

            {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

            page = pages |> Enum.find(&(&1["id"] == target_id))

            {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(page)

            tab = %{page: page, finished: false, pid: page_pid}

            GenServer.cast(
              __MODULE__,
              {:add_tab, tab}
            )

            tab

          false ->
            get_tab(server, first_page_pid)
        end

      tab ->
        tab
    end
  end
end
