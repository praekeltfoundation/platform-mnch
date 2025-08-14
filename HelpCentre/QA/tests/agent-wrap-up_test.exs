defmodule AgentWrapUpTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias HelpCentre.QA.Helpers
  alias FlowTester.Message.TextTransform

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The various index pages aren't in the content sheet, so we need to add them manually.
    indices = [
      %Index{title: "Help centre", slug: "help-centre-index"},
      %Index{title: "Onboarding", slug: "onboarding-index"},
    ]
    
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

    # Error messages are in a separate sheet.
    assert :ok = Helpers.import_content_csv(wh_pid, "error-messages", existing_pages: indices)

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

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("agent-wrap-up")}

  defp setup_flow(%{init_flow: init_flow}) do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.add_message_text_transform(
        TextTransform.normalise_newlines(trim_trailing_spaces: true)
      )
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

  describe "Agent wrap up:" do
    test "query resolved", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
    end

    test "query resolved yes", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text:
          "Please take care of yourself and if you need more information, reply {help} anytime to get the info you need."
      })
    end

    test "query resolved no", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Sorry to hear that.\r\n\r\nI would love to assist you with your problem, let’s try again.\r\n\r\nWhat would you like to do next?👇🏾"
      })
    end

    test "query unresolved call me back", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Sorry to hear that.\r\n\r\nI would love to assist you with your problem, let’s try again.\r\n\r\nWhat would you like to do next?👇🏾"
      })
      |> FlowTester.send(button_label: "Call me back")
      |> receive_message(%{
        text:
          "You can use our counsellor call back function to speak to a trained counsellor. If you opt for this, a counsellor will call you back and it usually takes around 5 minutes.\r\n\r\nWhat would you like to do?"
      })
    end

    test "call_back_number_confirmation", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Sorry to hear that.\r\n\r\nI would love to assist you with your problem, let’s try again.\r\n\r\nWhat would you like to do next?👇🏾"
      })
      |> FlowTester.send(button_label: "Call me back")
      |> receive_message(%{
        text:
          "You can use our counsellor call back function to speak to a trained counsellor. If you opt for this, a counsellor will call you back and it usually takes around 5 minutes.\r\n\r\nWhat would you like to do?"
      })
      |> FlowTester.send(button_label: "Call me back")
      |> receive_messages([
        %{
          text:
            "A trained counsellor/nurse will call you back.\r\n\r\nThey’ll be able to talk to you about any health related queries you might have. Try and clearly explain your concerns and they will gladly assist."
        },
        %{
          text:
            "Should a counsellor call you on the WhatsApp number you are currently using to chat?"
        }
      ])
    end
  end
end
