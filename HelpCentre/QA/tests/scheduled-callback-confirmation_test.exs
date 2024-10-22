defmodule ScheduledCallbackConfirmationTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias HelpCentre.QA.Helpers

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    error_pg = %ContentPage{
      slug: "mnch_onboarding_error_handling_button",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button."
        }
      ]
    }

    call_back_confirmation_scheduled = %ContentPage{
      slug: "plat_help_call_back_confirmation_scheduled",
      title: "Callback Confirmation Scheduled",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Hi there \r\n\r\nYou requested a call-back a few minutes ago. \r\n\r\nDid you receive the call?",
          buttons: [
            %Btn.Next{title: "Yes"},
            %Btn.Next{title: "No"}
          ]
        }
      ]
    }

    call_back_confirmation_yes = %ContentPage{
      slug: "plat_help_call_back_confirmation_yes",
      title: "Call back confirmation yes",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thats great to hear. Was the [health agent] able to help you?",
          buttons: [
            %Btn.Next{title: "Yes"},
            %Btn.Next{title: "No"},
            %Btn.Next{title: "Main menu"}
          ]
        }
      ]
    }

    call_back_confirmation_no = %ContentPage{
      slug: "plat_help_call_back_confirmation_no",
      title: "Call back confirmation no",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Thanks for letting me know. This feedback will be used to improve the [My Health] service.\r\n\r\nIf you have anything urgent to discuss, go to the nearest health facility and speak to a health worker.\r\n\r\nIf you'd like, you can request another call from a [health agent], or have a look at topics that might interest you. \r\n\r\n👇🏽 What do you want to do?",
          buttons: [
            %Btn.Next{title: "Call me back"},
            %Btn.Next{title: "See topics"},
            %Btn.Next{title: "Main menu"}
          ]
        }
      ]
    }

    agent_helpful_response = %ContentPage{
      slug: "plat_help_agent_helpful_response",
      title: "Agent helpful respone",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Please take care of yourself and if you need more information, reply {help} anytime to get the info you need."
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_pg,
               call_back_confirmation_scheduled,
               call_back_confirmation_yes,
               call_back_confirmation_no,
               agent_helpful_response
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
      "working_hours_start_hour" => "5",
      "working_hours_end_hour" => "19",
      "working_hours_start_day" => "2",
      "working_hours_end_day" => "6"
    })
  end

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("scheduled-callback-confirmation")}

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

  describe "callback confirmation scheduled" do
    test "callback confirmation", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there \r\n\r\nYou requested a call-back a few minutes ago. \r\n\r\nDid you receive the call?",
        buttons: button_labels(["Yes", "No"])
      })
    end

    test "confirm yes", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there \r\n\r\nYou requested a call-back a few minutes ago. \r\n\r\nDid you receive the call?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "Thats great to hear. Was the [health agent] able to help you?" <> _
      })
    end

    test "confirm yes and yes", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there \r\n\r\nYou requested a call-back a few minutes ago. \r\n\r\nDid you receive the call?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "Thats great to hear. Was the [health agent] able to help you?" <> _
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text:
          "Please take care of yourself and if you need more information, reply {help} anytime to get the info you need." <>
            _
      })
      |> flow_finished()
    end

    test "confirm yes and no", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there \r\n\r\nYou requested a call-back a few minutes ago. \r\n\r\nDid you receive the call?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "Thats great to hear. Was the [health agent] able to help you?" <> _
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Thanks for letting me know. This feedback will be used to improve the [My Health] service." <>
            _
      })
    end

    test "confirm no", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Hi there \r\n\r\nYou requested a call-back a few minutes ago. \r\n\r\nDid you receive the call?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "Thanks for letting me know. This feedback will be used to improve the [My Health] service." <>
            _
      })
    end
  end
end
