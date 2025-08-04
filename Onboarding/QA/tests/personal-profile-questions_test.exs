defmodule PersonalProfileQuestionsTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    error_button = %ContentPage{
      slug: "mnch_onboarding_error_handling_button",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button."
        }
      ]
    }

    error_list = %ContentPage{
      slug: "mnch_onboarding_error_handling_list_message",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply. Please try that again. \n\n👇🏽 Tap on the button below the message, choose your answer from the list, and send."
        }
      ]
    }

    relationship_status = %ContentPage{
      slug: "mnch_onboarding_q_relationshipstatus",
      title: "Relationsip Status",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
          buttons: [
            %Btn.Next{title: "Single"},
            %Btn.Next{title: "In a relationship"},
            %Btn.Next{title: "It's complicated"}
          ]
        }
      ]
    }

    education = %ContentPage{
      slug: "mnch_onboarding_q_education",
      title: "Education",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🗝️ *What is your highest level of education?*",
          list_items: [
            %ListItem.Next{title: "Primary school"},
            %ListItem.Next{title: "High school"},
            %ListItem.Next{title: "Diploma"},
            %ListItem.Next{title: "Degree"},
            %ListItem.Next{title: "Master's degree"},
            %ListItem.Next{title: "Doctoral degree"},
            %ListItem.Next{title: "None"},
            %ListItem.Next{title: "Skip this question"},
          ]
        }
      ]
    }

    socio_economic = %ContentPage{
      slug: "mnch_onboarding_q_socioeconomic",
      title: "Socio Economic",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
          buttons: [
            %Btn.Next{title: "Comfortable"},
            %Btn.Next{title: "I get by"},
            %Btn.Next{title: "Money is an issue"}
          ]
        }
      ]
    }

    children = %ContentPage{
      slug: "mnch_onboarding_children",
      title: "Children",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🗝️ *How many children do you have?*",
          list_items: [
            %ListItem.Next{title: "None"},
            %ListItem.Next{title: "1"},
            %ListItem.Next{title: "2"},
            %ListItem.Next{title: "3"},
            %ListItem.Next{title: "More than 3"},
            %ListItem.Next{title: "Why do you ask?"}
          ]
        }
      ]
    }

    children_why = %ContentPage{
      slug: "mnch_onboarding_children_why",
      title: "ChildrenWhy",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
          list_items: [
            %ListItem.Next{title: "None"},
            %ListItem.Next{title: "1"},
            %ListItem.Next{title: "2"},
            %ListItem.Next{title: "3"},
            %ListItem.Next{title: "More than 3"},
            %ListItem.Next{title: "Skip this question"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_button,
               error_list,
               relationship_status,
               education,
               socio_economic,
               children,
               children_why
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("personal-profile-questions")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
    %{flow: flow}
  end

  setup [:setup_flow]

  describe "Personal Profile questions" do
    test "relationship status error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> contact_matches(%{"relationship_status" => ""})
    end

    test "skip relationship status", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => ""})
    end

    test "relationship status then education", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
    end

    test "education error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again. \n\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"education" => ""})
    end

    test "skip education by typing", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => ""})
    end

    test "skip education by selection", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Skip this question")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => ""})
    end

    test "education then socio economic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
    end

    test "socio economic error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"socio_economic" => ""})
    end

    test "skip socio economic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => ""})
    end

    test "socio economic then children", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send(button_label: "Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
    end

    test "children error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again. \n\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"other_children" => ""})
    end

    test "skip children", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("skip")
      |> contact_matches(%{"other_children" => ""})
      |> flow_finished()
    end

    test "children then why", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Skip this question", "Skip this question"}],}
      })
      |> contact_matches(%{"other_children" => ""})
    end

    test "children then why then skip by typing then finished", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Skip this question", "Skip this question"}],}
      })
      |> FlowTester.send("skip")
      |> contact_matches(%{"other_children" => ""})
      |> flow_finished()
    end

    test "children then why then skip by selection then finished", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Skip this question", "Skip this question"}],}
      })
      |> FlowTester.send("Skip this question")
      |> contact_matches(%{"other_children" => ""})
      |> flow_finished()
    end

    test "children then finished", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("1")
      |> contact_matches(%{"other_children" => "1"})
      |> flow_finished()
    end
  end
end
