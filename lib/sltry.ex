defmodule SlTry do
  def init do
    api_key = System.get_env("API_KEY")

    [ws_url, user] = get_ws_info(api_key)
    IO.puts "url: #{ws_url}\nuser: #{user}"
    ws_connect(ws_url, user)
  end

  def ws_connect(ws_url, user) do
    [_, _, host | path] = String.split(ws_url, "/")

    path = "/" <> Enum.join(path, "/")
    IO.puts "host: #{host}\npath: #{path}"
    socket = Socket.Web.connect! host, secure: true, path: "/#{path}"

    case socket |> Socket.Web.recv! do
      {:text, "{\"type\":\"hello\"}"} ->
        IO.puts "Connection ok"
        say(socket, "C2D1382FQ", "Hi channel")
        converse(socket, user)
    end
  end

  defp encode(o) do
    encoded = Poison.Encoder.encode(o, [])
    "#{encoded}"
  end

  defp decode(s) do
    Poison.decode!(s)
  end

  def get_ws_info(api_key) do
    HTTPotion.start
    url = "https://slack.com/api/rtm.start?token=#{api_key}"

    response = HTTPotion.get(url)
    body = decode(response.body)
    url = body["url"]
    user = body["self"]["id"]

    [url, user]
  end

  def converse(socket, user) do
    case socket |> Socket.Web.recv! do
      {:text, message} ->
        IO.puts message
        body = decode(message)
        case body do
          %{"type" => "message", "channel" => channel, "user" => sender, "text" => text} ->
            handle_text(socket, channel, sender, text, user)
          _ ->
            nil
        end
      {:ping, ""} ->
        socket |> Socket.Web.send({:pong, ""})
    end

    converse(socket, user)
  end

  def handle_text(socket, channel, sender, text, user) do
    if String.contains?(text, "<@#{user}>") do
      if String.contains?(text, "Hi <@#{user}>") do
        say(socket, channel, "Hi <@#{sender}>")
      end
      if String.contains?(text, "fortune") do
        fortune = get_fortune(user, text)
        # if text == "<@#{user}> fortune" do
        #   {fortune, _} = System.cmd "fortune", []
        # else
        #   [_ | fortune] = String.split(text, "fortune")
        # end
        say(socket, channel, "```\n#{cowsay(fortune)}\n```")
      end
    end
  end

  def get_fortune(user, text) do
    user_fortune = "<@#{user}> fortune"
    case text do
      ^user_fortune ->
        {fortune, _} = System.cmd "fortune", []
        fortune
      _ ->
        [_ | fortune] = String.split(text, "fortune")
        "#{fortune}"
    end
  end

  def cowsay(s) do
    cow_options = ["-b", "-d", "-g", "-p", "-s", "-t", "-w", "-y"]
    cow_option = Enum.random(cow_options)

    {cow_string, _} = System.cmd "cowsay", [cow_option, s]
    cow_string
  end

  def say(socket, channel, text) do
    id = :rand.uniform(65000)
    body = encode(%{id: id, type: "message", channel: channel, text: text})

    IO.puts "send: #{body}"
    socket |> (Socket.Web.send! { :text, body })
  end
end
