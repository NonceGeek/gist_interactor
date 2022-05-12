defmodule GistInteractor.CLI do
  @moduledoc """
  Documentation for `GistInteractor.CLI`.
  Required `export GIST_ACCESS_TOKEN=<Your github personal access token>`
  If you want to create a public gist `export GIST_PUBLIC=true`
  Default it's a secret gist, enjoy it!

  gist_interactor list                                       # List all gists
  gist_interactor list  <gist_id>                            # List gist for gist_id
  gist_interactor delete <gist_id>                           # Delete a gist for gist_id
  gist_interactor create <des> <file> <content>              # Create a gist
  gist_interactor update <gist_id> <des> <file> <content>    # Update a gist for gist_id
  """

  @doc """
  List gists.

    ## Examples
        $./gist_interactor list e9a0d2aaee2b53978654061ae09733fc
        [
        %{
          "created_at" => "2022-05-12T16:35:40Z",
          "description" => "new_a",
          "files" => %{
            "a.log" => %{
              "content" => "dfdf",
              "filename" => "a.log",
              "language" => nil,
              "raw_url" => "https://gist.githubusercontent.com/yangcancai/e9a0d2aaee2b53978654061ae09733fc/raw/396add843365f628f32ce04946e890c926d6ceae/a.log",
              "size" => 4,
              "truncated" => false,
              "type" => "text/plain"
            },
            "new_a.erl" => %{
              "content" => "main()->ok.",
              "filename" => "new_a.erl",
              "language" => "Erlang",
              "raw_url" => "https://gist.githubusercontent.com/yangcancai/e9a0d2aaee2b53978654061ae09733fc/raw/ca21e536daf54fc7e62876ba58602d6e5dc96319/new_a.erl",
              "size" => 11,
              "truncated" => false,
              "type" => "text/plain"
            }
          },
          "id" => "e9a0d2aaee2b53978654061ae09733fc",
          "public" => false,
          "updated_at" => "2022-05-12T18:14:37Z"
        }
        ]
  """
  @github_api "https://api.github.com"
  #  curl  -H "Authorization: token ${ACCESS_TOKEN}"
  #            -H "Accept: application/vnd.github.v3+json"
  #            https://api.github.com/gists
  def main(["create", des, file, content]) do
    create(des, %{file => %{:content => content}})
  end

  def main(["update", gist_id, des, file, content]) do
    update(gist_id, des, %{file => %{:content => content}})
  end

  def main(["delete", gist_id]) do
    delete(gist_id)
  end

  def main(["list"]) do
    HTTPoison.get!(url("/gists"), headers())
    |> resp(:list)
  end

  def main(["list", gist_id]) do
    HTTPoison.get!(url("/gists/#{gist_id}"), headers())
    |> resp(:list)
  end

  def main(_args) do
    IO.puts("
Required `export GIST_ACCESS_TOKEN=<Your github personal access token>`
If you want to create a public gist `export GIST_PUBLIC=true`
Default it's a secret gist, enjoy it!

gist_interactor list                                       # List all gists
gist_interactor list  <gist_id>                            # List gist for gist_id
gist_interactor delete <gist_id>                           # Delete a gist for gist_id
gist_interactor create <des> <file> <content>              # Create a gist
gist_interactor update <gist_id> <des> <file> <content>    # Update a gist for gist_id
")
  end

  defp create(des, files) do
    HTTPoison.post!(url("/gists"), encode(des, files), headers())
    |> resp(:create)
  end

  defp update(gist_id, des, files) do
    HTTPoison.patch!(url("/gists/#{gist_id}"), encode(des, files), headers())
    |> resp(:update)
  end

  defp delete(gist_id) do
    HTTPoison.delete!(url("/gists/#{gist_id}"), headers())
    |> resp(:delete)
  end

  defp encode(des, files) do
    Jason.encode!(%{:description => des, :files => files, :public => public()})
  end

  defp resp(
         %HTTPoison.Response{
           body: body,
           status_code: 200
         },
         :list
       ) do
    rs =
      Jason.decode!(body)
      |> to_list
      |> Enum.map(fn data ->
        Map.take(data, ["id", "files", "public", "created_at", "updated_at", "description"])
      end)

    IO.inspect(rs)
    warn()
  end

  defp resp(
         %HTTPoison.Response{
           body: body,
           status_code: code
         },
         action
       )
       when code == 200 or code == 201 or (action == :delete and code == 204) do
    case action do
      :create ->
        %{"id" => id} = Jason.decode!(body)
        IO.puts("#{action} successed, id=#{id}")

      _ ->
        IO.puts("#{action} successed")
    end
  end

  defp resp(
         %HTTPoison.Response{
           status_code: code
         },
         action
       ) do
    IO.puts("#{action} failed ,status_code:#{code}")
    warn()
  end

  defp url(path) do
    "#{@github_api}#{path}"
  end

  defp to_list(data) when is_list(data), do: data

  defp to_list(data) do
    [data]
  end

  defp public() do
    case System.fetch_env("GIST_PUBLIC") do
      :error -> false
      {:ok, "false"} -> false
      {:ok, _} -> true
    end
  end

  defp headers() do
    case System.fetch_env("GIST_ACCESS_TOKEN") do
      :error ->
        [{"Accept", "application/vnd.github.v3+json"}]

      {:ok, token} ->
        [{"Authorization", "token #{token}"}, {"Accept", "application/vnd.github.v3+json"}]
    end
  end

  defp warn() do
    case System.fetch_env("GIST_ACCESS_TOKEN") do
      :error ->
        w = "Warning: didn't set GIST_ACCESS_TOKEN, Don't have write permission"
        IO.puts(IO.ANSI.format([:black_background, :yellow, w]))

      _ ->
        :ok
    end

    case System.fetch_env("GIST_PUBLIC") do
      :error ->
        w =
          "Warning: didn't set GIST_PUBLIC, All created and updated gists had been public to secret"

        IO.puts(IO.ANSI.format([:black_background, :yellow, w]))

      _ ->
        :ok
    end
  end
end
