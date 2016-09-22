defmodule Cowsay do

  def handle_text(text, user) do
    if String.contains?(text, "<@#{user}>") do
      case get_fortune(user, text) do
        {:ok, text} ->
          cowsay(text)
        _ ->
          nil
      end
    end
  end

  def get_fortune(user, text) do
    user_fortune = "<@#{user}> fortune"
    case text do
      ^user_fortune ->
        {fortune, _} = System.cmd "fortune", []
        {:ok, fortune}
      _ ->
        [_ | fortune] = String.split(text, " ")
        {:ok, "#{Enum.join(fortune, " ")}"}
    end
  end

  def cowsay(s) do
    # cow_options = ["-b", "-d", "-g", "-p", "-s", "-t", "-w", "-y"]
    # cow_option = Enum.random(cow_options)

    {cow_string, _} = System.cmd "cowsay", [s]
    {:ok, "```\n#{cow_string}\n```"}
  end

end
