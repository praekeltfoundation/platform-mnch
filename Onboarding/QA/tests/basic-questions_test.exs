defmodule BasicQuestionsTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

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
          message: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send."
        }
      ]
    }

    error_year = %ContentPage{
      slug: "mnch_onboarding_unrecognised_year",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
        }
      ]
    }

    age = %ContentPage{
      slug: "mnch_onboarding_q_age",
      title: "Age",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
        }
      ]
    }

    province = %ContentPage{
      slug: "mnch_onboarding_q_province",
      title: "Province",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Which province do you call home?*",
          list_items: [
            %ListItem.Next{title: "{province_name_01}"},
            %ListItem.Next{title: "{province_name_02}"},
            %ListItem.Next{title: "{province_name_03}"},
            %ListItem.Next{title: "{province_name_04}"},
            %ListItem.Next{title: "{province_name_05}"},
            %ListItem.Next{title: "{province_name_06}"},
            %ListItem.Next{title: "{province_name_07}"},
            %ListItem.Next{title: "Why do you ask?"},
          ]
        }
      ]
    }

    province_why = %ContentPage{
      slug: "mnch_onboarding_q_province_why",
      title: "Province_why",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Knowing your province helps me find you relevant services when you need them.\r\n\r\n👤 *So, which province do you live in?*",
          list_items: [
            %ListItem.Next{title: "{province_name_01}"},
            %ListItem.Next{title: "{province_name_02}"},
            %ListItem.Next{title: "{province_name_03}"},
            %ListItem.Next{title: "{province_name_04}"},
            %ListItem.Next{title: "{province_name_05}"},
            %ListItem.Next{title: "{province_name_06}"},
            %ListItem.Next{title: "{province_name_07}"},
            %ListItem.Next{title: "Skip this question"},
          ]
        }
      ]
    }

    area_type = %ContentPage{
      slug: "mnch_onboarding_q_area_type",
      title: "Area_type",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
          buttons: [
            %Btn.Next{title: "Big town/City"},
            %Btn.Next{title: "Countryside/Village"}
          ]
        }
      ]
    }

    gender = %ContentPage{
      slug: "mnch_onboarding_q_gender",
      title: "Gender",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *What gender do you identify as?*",
          buttons: [
            %Btn.Next{title: "Male"},
            %Btn.Next{title: "Female"},
            %Btn.Next{title: "Other"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_button,
               error_list,
               error_year,
               age,
               province,
               province_why,
               area_type,
               gender
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("basic-questions")}

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

  describe "Basic questions" do
    test "correct YoB", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> contact_matches(%{"year_of_birth" => "1988"})
    end

    test "skip age question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> contact_matches(%{"year_of_birth" => ""})
    end

    test "validate YoB less than now", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("8001")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is a number", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("2blue")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is 4 digits", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("41945")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is greater than min", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1850")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is not a string", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("blue")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "YoB error then province", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("blue")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
      |> FlowTester.send("1988")
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> contact_matches(%{"year_of_birth" => "1988"})
    end

    test "Province then why", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "Knowing your province helps me find you relevant services when you need them.\r\n\r\n👤 *So, which province do you live in?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Skip this question", "Skip this question"}]}
      })
      |> contact_matches(%{"province" => ""})
    end

    test "Province then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> contact_matches(%{"province" => ""})
    end

    test "skip province question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => ""})
    end

    test "Province then area", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
    end

    test "Area then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
    end

    test "skip area question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => ""})
    end

    test "Area (Urban) then gender", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Big town/City")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "big town / city"})
    end

    test "Area (Rural) then gender", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
    end

    test "Gender already set -> end of flow", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"gender" => "female"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> flow_finished()
    end

    test "Gender to gender error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "Skip gender question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send("skip")
      |> contact_matches(%{"gender" => ""})
      |> flow_finished()
    end

    test "Gender Male", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send(button_label: "Male")
      |> contact_matches(%{"gender" => "male"})
      |> flow_finished()
    end

    test "Gender Female", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send(button_label: "Female")
      |> contact_matches(%{"gender" => "female"})
      |> flow_finished()
    end

    test "Gender Other", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*",
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send(button_label: "Other")
      |> contact_matches(%{"gender" => "other"})
      |> flow_finished()
    end
  end
end
