defmodule Scraper.Helper do
  def get_product_detail(pid, root_node_id) do
    title_task = Task.async(fn -> get_title(pid, root_node_id) end)
    rating_task = Task.async(fn -> get_rating(pid, root_node_id) end)
    review_task = Task.async(fn -> get_review(pid, root_node_id) end)
    price_task = Task.async(fn -> get_price(pid, root_node_id) end)
    image_urls_task = Task.async(fn -> get_image_urls(pid, root_node_id) end)

    %{
      title: Task.await(title_task),
      rating: Task.await(rating_task),
      review: Task.await(review_task),
      price: Task.await(price_task),
      image_urls: Task.await(image_urls_task)
    }
  end

  defp get_title(page_pid, root_node_id) do
    case ChromeRemoteInterface.RPC.DOM.querySelector(page_pid, %{
           selector: ".js-product-name",
           nodeId: root_node_id
         }) do
      {:ok, %{"result" => %{"nodeId" => node_id}}} ->
        {:ok, %{"result" => %{"outerHTML" => html}}} =
          ChromeRemoteInterface.RPC.DOM.getOuterHTML(page_pid, %{nodeId: node_id})

        html |> Floki.text() |> String.trim()

      _ ->
        "unavailable"
    end
  end

  defp get_rating(page_pid, root_node_id) do
    case ChromeRemoteInterface.RPC.DOM.querySelector(page_pid, %{
           selector: "div.product-page--title-links meter",
           nodeId: root_node_id
         }) do
      {:ok, %{"result" => %{"nodeId" => node_id}}} ->
        {:ok, %{"result" => %{"outerHTML" => html}}} =
          ChromeRemoteInterface.RPC.DOM.getOuterHTML(page_pid, %{nodeId: node_id})

        html |> Floki.text() |> String.trim()

      _ ->
        "unavailable"
    end
  end

  defp get_review(page_pid, root_node_id) do
    case ChromeRemoteInterface.RPC.DOM.querySelector(page_pid, %{
           selector: "div.product-page--title-links a.review-rating__reviews-link",
           nodeId: root_node_id
         }) do
      {:ok, %{"result" => %{"nodeId" => node_id}}} ->
        {:ok, %{"result" => %{"outerHTML" => html}}} =
          ChromeRemoteInterface.RPC.DOM.getOuterHTML(page_pid, %{nodeId: node_id})

        html |> Floki.text() |> String.trim()

      _ ->
        "unavailable"
    end
  end

  defp get_price(page_pid, root_node_id) do
    case ChromeRemoteInterface.RPC.DOM.querySelector(page_pid, %{
           selector: "div.product-order .sales-price__current",
           nodeId: root_node_id
         }) do
      {:ok, %{"result" => %{"nodeId" => node_id}}} ->
        case ChromeRemoteInterface.RPC.DOM.getOuterHTML(page_pid, %{nodeId: node_id}) do
          {:ok, %{"result" => %{"outerHTML" => html}}} ->
            html |> Floki.text() |> String.trim()

          _ ->
            "unavailable"
        end

      _ ->
        "unavailable"
    end
  end

  defp get_image_urls(page_pid, root_node_id) do
    case ChromeRemoteInterface.RPC.DOM.querySelectorAll(page_pid, %{
           selector: "img.product-media-gallery__item-image",
           nodeId: root_node_id
         }) do
      {:ok, %{"result" => %{"nodeIds" => node_ids}}} ->
        node_ids
        |> Enum.map(fn node_id ->
          case ChromeRemoteInterface.RPC.DOM.getAttributes(page_pid, %{nodeId: node_id}) do
            {:ok, %{"result" => %{"attributes" => attributes}}} ->
              attributes
              |> Enum.find(&String.starts_with?(&1, "https://image.coolblue.nl"))

            _ ->
              nil
          end
        end)
        |> Enum.filter(&(&1 != nil))

      _ ->
        "unavailable"
    end
  end
end
