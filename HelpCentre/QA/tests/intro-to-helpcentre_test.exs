defmodule IntroToHelpCentreTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.FlowStep
  alias FlowTester.WebhookHandler.Generic

  defp flow_path(flow_name), do: Path.join([__DIR__, "..", "flows_json", flow_name <> ".json"])

  def setup_fake_cms(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    agent_greeting = %ContentPage{
      slug: "mnch_onboarding_error_handling_button",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You1 are now chatting with {operator_name}"}
      ]
    }

    help_centre_first = %ContentPage{
      slug: "plat_help_welcome_help_centre_first",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Welcome to the [MyHealth] Help Centre*",
          buttons: [
            %Btn.Next{title: "Emergency help"},
            %Btn.Next{title: "Search MyHealth"},
            %Btn.Next{title: "Tech support"}
          ]
        }
      ]
    }

    help_centre_returning = %ContentPage{
      slug: "plat_help_welcome_help_centre_returning",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Welcome back to the Help Centre*",
          buttons: [
            %Btn.Next{title: "Emergency help"},
            %Btn.Next{title: "Search MyHealth"},
            %Btn.Next{title: "Tech support"}
          ]
        }
      ]
    }

    medical_emergency = %ContentPage{
      slug: "plat_help_medical_emergency",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "If you're in a health emergency, please contact emergency services",
          buttons: [
            %Btn.Next{title: "Emergency Numbers"},
            %Btn.Next{title: "Search MyHealth"},
            %Btn.Next{title: "Talk to health agent"}
          ]
        }
      ]
    }

    emergency_contact_numbers = %ContentPage{
      slug: "plat_help_emergency_contact_numbers",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Emergency contact numbers*",
          buttons: [
            %Btn.Next{title: "Help centre 📞"},
            %Btn.Next{title: "Emergency Numbers"},
            %Btn.Next{title: "Go to main menu"}
          ]
        }
      ]
    }

    search_myhealth_prompt = %ContentPage{
      slug: "plat_help_search_myhealth_prompt",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "Let's find you the information you need.
"}
      ]
    }

    technical_issue_prompt = %ContentPage{
      slug: "plat_help_technical_issue_prompt",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You4 are now chatting with {operator_name}"}
      ]
    }

    invalid_media_catch_all = %ContentPage{
      slug: "plat_help_invalid_media_catch_all",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You5 are now chatting with {operator_name}"}
      ]
    }

    general_catch_all = %ContentPage{
      slug: "plat_help_general_catch_all",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You6 are now chatting with {operator_name}"}
      ]
    }

    medical_emergency_secondary = %ContentPage{
      slug: "plat_help_medical_emergency_secondary",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You7 are now chatting with {operator_name}"}
      ]
    }

    faqs_topics_list = %ContentPage{
      slug: "plat_help_faqs_topics_list",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You8 are now chatting with {operator_name}"}
      ]
    }

    faqs_topics_list_error = %ContentPage{
      slug: "plat_help_faqs_topics_list_error",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You9 are now chatting with {operator_name}"}
      ]
    }

    faq_topic_content = %ContentPage{
      slug: "plat_help_faq_topic_content",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You99 are now chatting with {operator_name}"}
      ]
    }

    acknowledgement_positive = %ContentPage{
      slug: "plat_help_acknowledgement_positive_",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You999 are now chatting with {operator_name}"}
      ]
    }

    acknowledgement_negative = %ContentPage{
      slug: "plat_help_acknowledgement_negative_",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You99999 are now chatting with {operator_name}"}
      ]
    }

    help_desk_entry_offline = %ContentPage{
      slug: "plat_help_help_desk_entry_offline",
      title: "Agent greeting",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "👨You9999999 are now chatting with {operator_name}"}
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               agent_greeting,
               help_centre_first,
               help_centre_returning,
               medical_emergency,
               emergency_contact_numbers,
               search_myhealth_prompt,
               technical_issue_prompt,
               invalid_media_catch_all,
               general_catch_all,
               medical_emergency_secondary,
               faqs_topics_list,
               faqs_topics_list_error,
               faq_topic_content,
               acknowledgement_positive,
               acknowledgement_negative,
               help_desk_entry_offline
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

    # IO.puts(inspect(body))
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
      flow_path("intro-to-helpcentre")
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

  test "main menu", %{flow: flow} do
    FlowTester.start(flow)
    |> receive_message(%{
      text: "*{MyHealth} Main Menu*\n\nTap the ‘Menu’ button to make your selection." <> _,
      list:
        {"Menu",
         [
           {"Your health guide 🔒", "Your health guide 🔒"},
           {"View topics for you 📚", "View topics for you 📚"},
           {"Chat to a nurse 🧑🏾‍⚕️", "Chat to a nurse 🧑🏾‍⚕️"},
           {"Your profile ({0%}) 👤", "Your profile ({0%}) 👤"},
           {"Manage updates 🔔", "Manage updates 🔔"},
           {"Manage data 🖼️", "Manage data 🖼️"},
           {"Help centre 📞", "Help centre 📞"},
           {"Take a tour 🚌", "Take a tour 🚌"},
           {"About and Privacy policy ℹ️", "About and Privacy policy ℹ️"},
           {"Talk to a counsellor", "Talk to a counsellor"}
         ]}
    })
  end

  test "new to helpcentre", %{flow: flow} do
    flow
    |> FlowTester.set_contact_properties(%{"returning_help_centre_user" => ""})
    |> FlowTester.start()
    |> receive_message(%{
      text: "*{MyHealth} Main Menu*\n\nTap the ‘Menu’ button to make your selection." <> _,
      list:
        {"Menu",
         [
           {"Your health guide 🔒", "Your health guide 🔒"},
           {"View topics for you 📚", "View topics for you 📚"},
           {"Chat to a nurse 🧑🏾‍⚕️", "Chat to a nurse 🧑🏾‍⚕️"},
           {"Your profile ({0%}) 👤", "Your profile ({0%}) 👤"},
           {"Manage updates 🔔", "Manage updates 🔔"},
           {"Manage data 🖼️", "Manage data 🖼️"},
           {"Help centre 📞", "Help centre 📞"},
           {"Take a tour 🚌", "Take a tour 🚌"},
           {"About and Privacy policy ℹ️", "About and Privacy policy ℹ️"},
           {"Talk to a counsellor", "Talk to a counsellor"}
         ]}
    })
    |> FlowTester.send(button_label: "Help centre 📞")
    |> receive_message(%{
      text: "*Welcome to the [MyHealth] Help Centre*" <> _
    })
  end

  test "returning to helpcentre", %{flow: flow} do
    flow
    |> FlowTester.set_contact_properties(%{"returning_help_centre_user" => "true"})
    |> FlowTester.start()
    |> receive_message(%{
      text: "*{MyHealth} Main Menu*\n\nTap the ‘Menu’ button to make your selection." <> _
    })
    |> FlowTester.send(button_label: "Help centre 📞")
    |> receive_message(%{
      text: "*Welcome back to the Help Centre*" <> _
    })
  end

  describe "Emergency Help:" do
    test "emergency numbers", %{flow: flow} do
      FlowTester.start(flow)
      |> FlowTester.send(button_label: "Help centre 📞")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Emergency help")
      |> receive_message(%{
        text: "If you're in a health emergency, please contact emergency services" <> _
      })
      |> FlowTester.send(button_label: "Emergency Numbers")
      |> receive_message(%{
        text: "*Emergency contact numbers*" <> _
      })
    end

    # TODO: Implement this when flow_tester supports asserting on the running of a flow
    # test "talk to health agent" do
    #   setup_flow()
    #   |> FlowTester.start()
    #   |> FlowTester.send(button_label: "Help centre 📞")
    #   |> FlowTester.send(button_label: "Emergency help")
    #   |> FlowStep.clear_messages()
    #   |> FlowTester.send(button_label: "Talk to health agent")
    #   |> FlowTester
    #   |> receive_message(%{
    #     text: "*should be talk to agent*" <> _
    #   })
    # end
  end

  describe "Search MyHealth:" do
    defp setup_flow_search_myhealth(flow) do
      FlowTester.start(flow)
      |> FlowTester.send(button_label: "Help centre 📞")
      |> FlowTester.send(button_label: "Search MyHealth")
    end

    test "is help centre open", %{flow: flow} do
      # setup_flow_search_myhealth()

      FlowTester.start(flow)
      |> FlowTester.send(button_label: "Help centre 📞")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Search MyHealth")
      |> receive_message(%{
        text: "Let's find you the information you need" <> _
      })

      # |> FlowTester.send("My tummy hurts")
      # |> receive_message(%{
      #   text: "here" <> _
      # })
    end
  end
end
