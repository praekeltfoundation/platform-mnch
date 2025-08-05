defmodule AgentGreetingTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias HelpCentre.QA.Helpers

  import HelpCentre.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The index page isn't in the content sheet, so we need to add it manually.
    index = %Index{title: "Help centre", slug: "test"}
    assert :ok = FakeCMS.add_pages(wh_pid, [index])

    # The content for these tests.
    assert :ok = Helpers.import_content_csv(
                   wh_pid,
                   "help-centre",
                   existing_pages: [index],
                   field_transform: fn s ->
                     s
                     |> String.replace(~r/\r?\n$/, "")
                   end
                 )

    # # Add some content.
    # agent_greeting = %ContentPage{
    #   slug: "plat_help_agent_greeting",
    #   title: "Agent greeting",
    #   parent: "test",
    #   wa_messages: [
    #     %WAMsg{message: "👨You are now chatting with {operator_name}"}
    #   ]
    # }

    # assert :ok =
    #          FakeCMS.add_pages(wh_pid, [
    #            %Index{slug: "test", title: "test"},
    #            agent_greeting
    #          ])

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

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("agent-greeting")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
      |> Helpers.setup_fake_turn(ctx)
      |> set_config()

    %{flow: flow}
  end

  setup [:setup_flow]

  test "get greeting for assigned agent", %{flow: flow} do
    FlowTester.start(flow)
    |> receive_message(%{
      text: "👨You are now chatting with Test Operator" <> _
    })
  end

  @tag chat_assigned_to: nil
  test "get greeting for no agent assigned", %{flow: flow} do
    FlowTester.start(flow)
    |> receive_message(%{
      text: "👨You are now chatting with a MomConnect operator" <> _
    })
  end
end
