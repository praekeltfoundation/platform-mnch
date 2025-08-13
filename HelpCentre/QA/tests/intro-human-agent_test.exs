defmodule IntroHumanAgentTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.Message.TextTransform

  alias HelpCentre.QA.Helpers

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The index page isn't in the content sheet, so we need to add it manually.
    indices = [%Index{title: "Help centre", slug: "test-help-centre"}]
    assert :ok = FakeCMS.add_pages(wh_pid, indices)

    # These options are common to all CSV imports below.
    import_opts = [
      existing_pages: indices,
      field_transform: fn s ->
        s
        |> String.replace(~r/\r?\r\n$/, "")
        |> String.replace("{username}", "{@username}")
        # TODO: Fix this in FakeCMS
        |> String.replace("\u200D", "")
        # These transforms are specific to these tests
      end
    ]
    # The content for these tests.
    assert :ok = Helpers.import_content_csv(wh_pid, "help-centre", import_opts)


    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp set_config(step) do
    step
    |> FlowTester.set_global_dict("settings", %{
      "working_hours_start_hour" => "5",
      "working_hours_end_hour" => "19",
      "working_hours_start_day" => "2",
      "working_hours_end_day" => "6"
    })
  end

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("intro-human-agent")}

  defp setup_flow(%{init_flow: init_flow}) do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
      |> set_config()
    %{flow: flow}
  end

  setup [:setup_flow]

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

  describe "get pre handover message:" do
    test "emergency", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "emergency"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "We will let the helpdesk know that this is an emergency situation" <> _
      })
    end

    test "search myhealth", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "search_myhealth"})
      |> FlowTester.set_contact_properties(%{
        "route_to_operator_search_text" => "mock search myhealth query"
      })
      |> FlowTester.start()
      |> receive_message(%{
        text: "You searched for 'mock search myhealth query'" <> _
      })
    end

    test "tech support", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "tech_support"})
      |> FlowTester.set_contact_properties(%{
        "route_to_operator_search_text" => "mock tech support query"
      })
      |> FlowTester.start()
      |> receive_message(%{
        text: "You searched for 'mock tech support query'" <> _
      })
    end

    test "failed attempts", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "failed_attempts"})
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "It seems that the bot has been unable to assist you so we will be routing you to a human helpdesk operator to try to resolve your issue" <>
            _
      })
    end
  end
end
