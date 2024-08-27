defmodule ScheduledCallbackConfirmationTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  # alias FlowTester.FlowStep
  defp flow_path(flow_name), do: Path.join([__DIR__, "..", "flows_json", flow_name <> ".json"])

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  # defp real_or_fake_cms(step, base_url, auth_token, :fake),
  #   do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))
  defp set_config(step) do
    step
    |> FlowTester.set_global_dict("settings", %{
      "working_hours_start_hour" => "6",
      "working_hours_end_hour" => "19",
      "working_hours_start_day" => "2",
      "working_hours_end_day" => "6"
    })
  end

  defp setup_flow() do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow_path("scheduled-callback-confirmation")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
    |> set_config()
  end

  # This lets us have cleaner button/list assertions.
  def indexed_list(var, labels) do
    Enum.with_index(labels, fn lbl, idx -> {"@#{var}[#{idx}]", lbl} end)
  end

  # The common case for buttons.
  defmacro button_labels(labels) do
    quote do: unquote(indexed_list("button_labels", labels))
  end

  # The common case for lists.
  defmacro list_items(labels) do
    quote do: unquote(indexed_list("list_items", labels))
  end

  # test "get greeting" do
  #   setup_flow()
  #   |> FlowTester.start()

  #   |> receive_message(%{
  #     text: "*{MyHealth} Main Menu*\n\nTap the ‘Menu’ button to make your selection." <> _,
  #     list: {"Menu", [
  #       {"Your health guide 🔒", "Your health guide 🔒"},
  #       {"View topics for you 📚", "View topics for you 📚"},
  #       {"Chat to a nurse 🧑🏾‍⚕️", "Chat to a nurse 🧑🏾‍⚕️"},
  #       {"Your profile ({0%}) 👤", "Your profile ({0%}) 👤"},
  #       {"Manage updates 🔔", "Manage updates 🔔"},
  #       {"Manage data 🖼️", "Manage data 🖼️"},
  #       {"Help centre 📞", "Help centre 📞"},
  #       {"Take a tour 🚌", "Take a tour 🚌"},
  #       {"About and Privacy policy ℹ️", "About and Privacy policy ℹ️"},
  #       {"Talk to a counsellor", "Talk to a counsellor"}
  #   ]}
  #   })

  # end
end
