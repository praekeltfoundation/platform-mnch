defmodule ScheduledCallbackfollowupTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  # alias FlowTester.FlowStep
  defp flow_path(flow_name), do: Path.join([__DIR__, "..", "flows_json", flow_name <> ".json"])

  def setup_fake_cms(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    call_back_follow_up = %ContentPage{
      slug: "plat_help_call_back_follow_up",
      title: "Callback Confirmation Scheduled",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Hi there\n\nYou requested a call back. Do you still want to speak to a counsellor?",
          buttons: [
            %Btn.Next{title: "Yes please"},
            %Btn.Next{title: "No thanks"},
            %Btn.Next{title: "Main menu"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               call_back_follow_up
             ])

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

    flow_path("scheduled-callback-followup")
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

  describe "scheduled callback followup" do
    test "initial message" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there\n\nYou requested a call back. Do you still want to speak to a counsellor?",
        buttons: button_labels(["Yes please", "No thanks", "Main menu"])
      })
    end

    test "click yes please" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there\n\nYou requested a call back. Do you still want to speak to a counsellor?",
        buttons: button_labels(["Yes please", "No thanks", "Main menu"])
      })
      |> FlowTester.send(button_label: "Yes please")
      |> FlowTester.handle_child_flow("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
      |> flow_finished()
    end

    test "click no thanks" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there\n\nYou requested a call back. Do you still want to speak to a counsellor?",
        buttons: button_labels(["Yes please", "No thanks", "Main menu"])
      })
      |> FlowTester.send(button_label: "No thanks")
      |> FlowTester.handle_child_flow("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
      |> flow_finished()
    end

    test "click main menu" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there\n\nYou requested a call back. Do you still want to speak to a counsellor?",
        buttons: button_labels(["Yes please", "No thanks", "Main menu"])
      })
      |> FlowTester.send(button_label: "Main menu")
      |> FlowTester.handle_child_flow("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
      |> flow_finished()
    end
  end
end
