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
            case Cowsay.handle_text(text, user) do
              {:ok, text} ->
                say(socket, channel, text)
              _ ->
                nil
            end
          _ ->
            nil
        end
      {:ping, ""} ->
        socket |> Socket.Web.send({:pong, ""})
    end

    converse(socket, user)
  end

  def say(socket, channel, text) do
    id = :rand.uniform(65000)
    body = encode(%{id: id, type: "message", channel: channel, text: text})

    IO.puts "send: #{body}"
    socket |> (Socket.Web.send! { :text, body })
  end
end
