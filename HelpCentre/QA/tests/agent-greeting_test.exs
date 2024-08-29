defmodule AgentGreetingTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.WebhookHandler.Generic
  # alias FlowTester.FlowStep, as: Step
  defp flow_path(flow_name), do: Path.join([__DIR__, "..", "flows_json", flow_name <> ".json"])

  def setup_fake_cms(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    agent_greeting = %ContentPage{
      slug: "plat_help_agent_greeting",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You are now chatting with {operator_name}"}
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               agent_greeting
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp turn_contacts_messages(env, ctx) do
    assigned_to =
      Map.get(ctx, :chat_assigned_to, %{
        "id" => "some-uuid",
        "name" => "Test Operator",
        "type" => "OPERATOR"
      })

    # IO.puts(inspect(assigned_to))
    body = %{
      "chat" => %{
        "owner" => "+27821234567",
        "state" => "OPEN",
        "uuid" => "some-uuid",
        "state_reason" => "Re-opened by inbound message.",
        "assigned_to" => assigned_to,
        "contact_uuid" => "some-uuid",
        "permalink" => "https://whatsapp-praekelt-cloud.turn.io/app/c/some-uuid"
      }
    }

    %Tesla.Env{env | status: 200, body: body}
  end

  defp setup_fake_turn(step, ctx) do
    gen_pid = start_link_supervised!(Generic)

    Generic.add_handler(
      gen_pid,
      ~r"/v1/contacts/[0-9]+/messages",
      &turn_contacts_messages(&1, ctx)
    )

    WH.set_adapter(step, "https://whatsapp-praekelt-cloud.turn.io/", Generic.wh_adapter(gen_pid))
  end

  defp set_config(step) do
    step
    |> FlowTester.set_global_dict("settings", %{
      "working_hours_start_hour" => "6",
      "working_hours_end_hour" => "19",
      "working_hours_start_day" => "2",
      "working_hours_end_day" => "6"
    })
  end

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      flow_path("agent-greeting")
      |> FlowTester.from_json!()
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
      |> setup_fake_turn(ctx)
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
      text: "👨You are now chatting with {a MomConnect operator}" <> _
    })
  end
end
