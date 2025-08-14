defmodule ScheduledTopicsNoResponseFollowupTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.WebhookHandler.Generic
  alias HelpCentre.QA.Helpers
  alias FlowTester.Message.TextTransform

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The various index pages aren't in the content sheet, so we need to add them manually.
    indices = [
      %Index{title: "Help centre", slug: "help-centre-index"},
      %Index{title: "Onboarding", slug: "onboarding-index"}
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

  def aaq_add_feedback(env, _ctx) do
    body = %{"add_feedback_response" => "Some things"}
    %Tesla.Env{env | status: 200, body: body}
  end

  defp setup_fake_aaq(step, ctx) do
    gen_pid = start_link_supervised!(Generic, id: :fake_aaq)

    Generic.add_handler(
      gen_pid,
      "/api/v1/inbound/feedback",
      &aaq_add_feedback(&1, ctx)
    )

    WH.set_adapter(step, "https://hub.qa.momconnect.co.za/", Generic.wh_adapter(gen_pid))
  end

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("scheduled-topics-no-response-followup")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.add_message_text_transform(
        TextTransform.normalise_newlines(trim_trailing_spaces: true)
      )
      |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
      |> setup_fake_aaq(ctx)
      |> set_config()

    %{flow: flow}
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

  setup [:setup_flow]

  describe "scheduled topics no response followup:" do
    test "initial message", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"aaq_metadata" => "{}"})
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "🤖 Hello again!\r\n\r\nI see you haven't replied.\r\n\r\n👇🏽 Was the information I recommended helpful?",
        buttons: button_labels(["Yes 👍🏽", "No 👎🏽"])
      })
    end

    test "clicked yes", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{
        "aaq_metadata" => "{}"
      })
      |> FlowTester.start()
      |> receive_message(%{
        text: "🤖 Hello again!\r\n\r\nI see you haven't replied.\r\n\r\n" <> _,
        buttons: button_labels(["Yes 👍🏽", "No 👎🏽"])
      })
      |> FlowTester.send(button_label: "Yes 👍🏽")
      |> receive_message(%{
        text:
          "I'm happy to hear that.\r\n\r\nWhat would you like to see now?" <>
            _,
        buttons: button_labels(["Back to topics list", "Help Centre menu", "Main menu"])
      })
    end

    test "click no", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{
        "aaq_metadata" => "{}"
      })
      |> FlowTester.start()
      |> receive_message(%{
        text: "🤖 Hello again!\r\n\r\nI see you haven't replied.\r\n\r\n" <> _,
        buttons: button_labels(["Yes 👍🏽", "No 👎🏽"])
      })
      |> FlowTester.send(button_label: "No 👎🏽")
      |> receive_message(%{
        text: "That's unfortunate. Let's try again!"
      })

      # TODO: Leaving this code commented out for now for debugging purposes
      |> FlowTester.handle_child_flow("7b50f9f4-b6cf-424b-8893-8fef6d0f489b", fn step ->
        # IO.puts(inspect(FlowTester.FlowStep.get_vars(step), pretty: true))
        # Set contact properties here
        step
      end)
    end
  end
end
