defmodule AgentWrapUpTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  # alias FlowTester.FlowStep
  defp flow_path(flow_name), do: Path.join([__DIR__, "..", "flows_json", flow_name <> ".json"])

  def setup_fake_cms(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    query_successful = %ContentPage{
      slug: "plat_help_query_successful",
      title: "Query successful",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Was your query successfully resolved?",
          buttons: [
            %Btn.Next{title: "Yes"},
            %Btn.Next{title: "No"}
          ]
        }
      ]
    }

    agent_helpful_response = %ContentPage{
      slug: "plat_help_agent_helpful_response",
      title: "Query successful",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Please take care of yourself and if you need more information, reply {help} anytime to get the info you need."
        }
      ]
    }

    agent_unsuccessful_response = %ContentPage{
      slug: "plat_help_agent_unsuccessful_response",
      title: "Agent unsuccessful response",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Sorry to hear that.\n\nI would love to assist you with your problem, let’s try again.\n\nWhat would you like to do next?👇🏾",
          buttons: [
            %Btn.Next{title: "Call me back"},
            %Btn.Next{title: "Search MyHealth"},
            %Btn.Next{title: "Main menu"}
          ]
        }
      ]
    }

    call_back_response = %ContentPage{
      slug: "plat_help_call_back_response",
      title: "Call back response",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "You can use our counsellor call back function to speak to a trained counsellor. If you opt for this, a counsellor will call you back and it usually takes around 5 minutes.\n\nWhat would you like to do?",
          buttons: [
            %Btn.Next{title: "Call me back"},
            %Btn.Next{title: "Main menu"}
          ]
        }
      ]
    }

    call_back_confirmation = %ContentPage{
      slug: "plat_help_call_back_confirmation",
      title: "Call back confirmation",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "A trained counsellor/nurse will call you back.\n\nThey’ll be able to talk to you about any health related queries you might have. Try and clearly explain your concerns and they will gladly assist."
        }
      ]
    }

    call_back_number_confirmation = %ContentPage{
      slug: "plat_help_agent_call_back_number_confirmation",
      title: "Call back confirmation",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Should a counsellor call you on the WhatsApp number you are currently using to chat?",
          buttons: [
            %Btn.Next{title: "Use this number"},
            %Btn.Next{title: "Use different number"},
            %Btn.Next{title: "Main menu"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               query_successful,
               agent_helpful_response,
               agent_unsuccessful_response,
               call_back_response,
               call_back_confirmation,
               call_back_number_confirmation
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

    flow_path("agent-wrap-up")
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

  describe "Agent wrap up:" do
    test "query resolved" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
    end

    test "query resolved yes" do
      setup_flow()
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

    test "query resolved no" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Sorry to hear that.\n\nI would love to assist you with your problem, let’s try again.\n\nWhat would you like to do next?👇🏾"
      })
    end

    test "query unresolved call me back" do
      setup_flow()
      |> FlowTester.start()
      |> receive_message(%{
        text: "Was your query successfully resolved?"
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Sorry to hear that.\n\nI would love to assist you with your problem, let’s try again.\n\nWhat would you like to do next?👇🏾"
      })
      |> FlowTester.send(button_label: "Call me back")
      |> receive_message(%{
        text:
          "You can use our counsellor call back function to speak to a trained counsellor. If you opt for this, a counsellor will call you back and it usually takes around 5 minutes.\n\nWhat would you like to do?"
      })
    end

      test "call_back_number_confirmation" do
        setup_flow()
        |> FlowTester.start()
        |> receive_message(%{
          text:
            "Was your query successfully resolved?"
            })
            |> FlowTester.send(button_label: "No")
            |> receive_message(%{
              text: "Sorry to hear that.\n\nI would love to assist you with your problem, let’s try again.\n\nWhat would you like to do next?👇🏾"})
            |> FlowTester.send(button_label: "Call me back")
            |> receive_message(%{
              text: "You can use our counsellor call back function to speak to a trained counsellor. If you opt for this, a counsellor will call you back and it usually takes around 5 minutes.\n\nWhat would you like to do?"
              })
            |> FlowTester.send(button_label: "Call me back")
            |> receive_messages([%{
              text: "A trained counsellor/nurse will call you back.\n\nThey’ll be able to talk to you about any health related queries you might have. Try and clearly explain your concerns and they will gladly assist."
              },
              %{
                text: "Should a counsellor call you on the WhatsApp number you are currently using to chat?"
              }])

      end
  end
end
