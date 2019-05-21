defmodule Scraper do
  use GenServer

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  def init(state), do: {:ok, state}

  def handle_cast({:scrap, %{url: url, server: server, first_page_pid: first_page_pid}}, state) do
    IO.inspect(url)

    {:ok, %{"id" => _, "result" => %{"targetId" => tab_id}}} =
      ChromeRemoteInterface.RPC.Target.createTarget(first_page_pid, %{url: url})

    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)
    new_page = pages |> Enum.find(&(&1["id"] == tab_id))

    {:ok, new_page_pid} = ChromeRemoteInterface.PageSession.start_link(new_page)

    {:ok, %{"id" => _, "result" => %{"root" => %{"nodeId" => node_id}}}} =
      ChromeRemoteInterface.RPC.DOM.getDocument(new_page_pid)

    IO.inspect("node_id")
    IO.inspect(node_id)

    IO.inspect(
      ChromeRemoteInterface.RPC.DOM.querySelectorAll(new_page_pid, %{
        selector: ".js-product-name",
        nodeId: node_id
      })
    )

    # {:ok, %{"id" => _, "result" => %{"nodeId" => title_node_id}}} =
    #   ChromeRemoteInterface.RPC.DOM.querySelectorAll(new_page_pid, %{
    #     selector: ".js-product-name",
    #     nodeId: node_id
    #   })

    # IO.inspect("title_node_id")

    # {:ok,
    #  %{
    #    "id" => _,
    #    "result" => %{
    #      "outerHTML" => title_html
    #    }
    #  }} = ChromeRemoteInterface.RPC.DOM.getOuterHTML(new_page_pid, %{nodeId: title_node_id})

    # IO.inspect(title_html)

    {:noreply, state}
  end

  def start_link(state) do
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: __MODULE__)
    scrap(state)
    {:ok, pid}
  end

  defp scrap(urls: urls) do
    server = ChromeRemoteInterface.Session.new()
    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)
    first_page = pages |> List.first()
    {:ok, first_page_pid} = ChromeRemoteInterface.PageSession.start_link(first_page)

    urls
    |> Enum.each(fn url ->
      GenServer.cast(
        __MODULE__,
        {:scrap, %{url: url, server: server, first_page_pid: first_page_pid}}
      )
    end)
  end
end
