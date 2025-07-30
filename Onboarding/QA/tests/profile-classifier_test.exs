defmodule ProfileClassifierTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.FlowStep
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

    error_name = %ContentPage{
      slug: "mnch_onboarding_name_error",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I can *only accept names with letters* – no numbers or symbols.\r\n\r\nLet's try this again!\r\n\r\nWhat would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`"
        }
      ]
    }

    name = %ContentPage{
      slug: "mnch_onboarding_name_call",
      title: "Name",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "What would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`",
        }
      ]
    }

    name_skip = %ContentPage{
      slug: "mnch_onboarding_name_skip",
      title: "Name_skip",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Sure, we’ll skip that for now.",
          buttons: [
            %Btn.Next{title: "Go back"},
            %Btn.Next{title: "Got it"}
          ]
        }
      ]
    }

    domains_01 = %ContentPage{
      slug: "mnch_onboarding_domains_01",
      title: "Domains 01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Great to meet you, {@username}!\r\n\r\nI have tonnes of information on lots of different topics you can explore.\r\n\r\nBut I want to know what topics you're interested in adding to your profile.\r\n\r\nI have some suggestions for you to pick from...",
          buttons: [
            %Btn.Next{title: "Let's go"},
          ]
        }
      ]
    }

    domains_02 = %ContentPage{
      slug: "mnch_onboarding_domains_02",
      title: "Domains 02",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Love and relationships*\r\n\r\nEverything you need to know about finding love, having healthy relationships, getting out of bad relationships, and communicating better with your partner.",
          buttons: [
            %Btn.Next{title: "➕ Add this topic"},
            %Btn.Next{title: "Not interested"},
          ]
        }
      ]
    }

    domains_03 = %ContentPage{
      slug: "mnch_onboarding_domains_03",
      title: "Domains 03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Pregnancy information*\r\n\r\nWhat you need to know about having a happy and healthy pregnancy from your 1st month 'til your last.",
          buttons: [
            %Btn.Next{title: "➕ Add this topic"},
            %Btn.Next{title: "Not interested"},
          ]
        }
      ]
    }

    domains_04 = %ContentPage{
      slug: "mnch_onboarding_domains_04",
      title: "Domains 04",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Baby and child health*\r\n\r\nRaising a child is hard work but with the right information, support, tips and tricks, you can enjoy being a super parent!",
          buttons: [
            %Btn.Next{title: "➕ Add this topic"},
            %Btn.Next{title: "Not interested"},
          ]
        }
      ]
    }

    domains_05 = %ContentPage{
      slug: "mnch_onboarding_domains_05",
      title: "Domains 05",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Well-being*\r\n\r\nWhether you’re looking to add some mindfulness to your day, learn about the importance of looking after your mental health or finding ways to cope in difficult times, you'll find the right resource for you.",
          buttons: [
            %Btn.Next{title: "➕ Add this topic"},
            %Btn.Next{title: "Not interested"},
          ]
        }
      ]
    }

    domains_06 = %ContentPage{
      slug: "mnch_onboarding_domains_06",
      title: "Domains 06",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Family planning*\r\n\r\nYou have the power to decide if and when you want children and how many you want. You might want none. You might want lots! Know your options so that you can decide what's best for you.",
          buttons: [
            %Btn.Next{title: "➕ Add this topic"},
            %Btn.Next{title: "Not interested"},
          ]
        }
      ]
    }

    domains_07 = %ContentPage{
      slug: "mnch_onboarding_domains_07",
      title: "Domains 07",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Info for health professionals*\r\n\r\nAre you a nurse? Get support, information, tips and guides to boost your knowledge and skills.",
          buttons: [
            %Btn.Next{title: "➕ Add this topic"},
            %Btn.Next{title: "Not interested"},
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_button,
               error_name,
               name,
               name_skip,
               domains_01,
               domains_02,
               domains_03,
               domains_04,
               domains_05,
               domains_06,
               domains_07
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("profile-classifier")}

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

  describe "Profile Classifier" do
    test "name", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "What would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`",
      })
      |> contact_matches(%{"checkpoint" => "profile_classifier"})
      |> result_matches(%{name: "profile_classifier_started", value: "yes"})
    end

    test "name skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowStep.clear_messages()
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "Sure, we’ll skip that for now.",
        buttons: button_labels(["Go back", "Got it"])
      })
    end

    test "name skip then go back", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("skip")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Go back")
      |> receive_message(%{
        text: "What would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`",
      })
    end

    test "name skip then got it", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"name" => ""})
      |> FlowTester.start()
      |> FlowTester.send("skip")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Got it")
      |> receive_message(%{
        text: "Great to meet you!\r\n\r\nI have tonnes of information on lots of different topics you can explore.\r\n\r\nBut I want to know what topics you're interested in adding to your profile.\r\n\r\nI have some suggestions for you to pick from...",
      })
    end

    test "name skip then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("skip")
      |> FlowStep.clear_messages()
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Go back", "Got it"])
      })
    end

    test "name skip then error then go back", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("skip")
      |> FlowTester.send("falalalalaaaa")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Go back")
      |> receive_message(%{
        text: "What would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`",
      })
    end

    test "name validate no numbers", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowStep.clear_messages()
      |> FlowTester.send("1234")
      |> receive_message(%{
        text: "I can *only accept names with letters* – no numbers or symbols.\r\n\r\nLet's try this again!\r\n\r\nWhat would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`",
      })
    end

    test "name validate no numbers then skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("1234")
      |> FlowStep.clear_messages()
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "Sure, we’ll skip that for now.",
        buttons: button_labels(["Go back", "Got it"])
      })
    end

    test "name validate no numbers then correct", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("1234")
      |> FlowStep.clear_messages()
      |> FlowTester.send("Bond")
      |> contact_matches(%{"name" => "Bond"})
      |> receive_message(%{
        text: "Great to meet you, Bond!\r\n\r\nI have tonnes of information on lots of different topics you can explore.\r\n\r\nBut I want to know what topics you're interested in adding to your profile.\r\n\r\nI have some suggestions for you to pick from...",
        buttons: button_labels(["Let's go"])
      })
    end

    test "name validate length", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowStep.clear_messages()
      |> FlowTester.send("abcdefghijklmnopqrstu")
      |> receive_message(%{
        text: "I can *only accept names with letters* – no numbers or symbols.\r\n\r\nLet's try this again!\r\n\r\nWhat would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`",
      })
    end

    test "name entered", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowStep.clear_messages()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> receive_message(%{
        text: "Great to meet you, abcdefghijklmnopqrst!\r\n\r\nI have tonnes of information on lots of different topics you can explore.\r\n\r\nBut I want to know what topics you're interested in adding to your profile.\r\n\r\nI have some suggestions for you to pick from...",
        buttons: button_labels(["Let's go"])
      })
    end

    test "domain 2 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Let's go")
      |> receive_message(%{
        text: "*Love and relationships*\r\n\r\nEverything you need to know about finding love, having healthy relationships, getting out of bad relationships, and communicating better with your partner.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 2 add", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> contact_matches(%{"love_and_relationships" => "true"})
      |> receive_message(%{
        text: "*Pregnancy information*\r\n\r\nWhat you need to know about having a happy and healthy pregnancy from your 1st month 'til your last.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 2 skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"love_and_relationships" => "false"})
      |> receive_message(%{
        text: "*Pregnancy information*\r\n\r\nWhat you need to know about having a happy and healthy pregnancy from your 1st month 'til your last.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 3 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 3 add", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> contact_matches(%{"pregnancy_information" => "true"})
      |> receive_message(%{
        text: "*Baby and child health*\r\n\r\nRaising a child is hard work but with the right information, support, tips and tricks, you can enjoy being a super parent!",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 3 skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"pregnancy_information" => "false"})
      |> receive_message(%{
        text: "*Baby and child health*\r\n\r\nRaising a child is hard work but with the right information, support, tips and tricks, you can enjoy being a super parent!",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 4 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 4 add", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> contact_matches(%{"baby_and_child" => "true"})
      |> receive_message(%{
        text: "*Well-being*\r\n\r\nWhether you’re looking to add some mindfulness to your day, learn about the importance of looking after your mental health or finding ways to cope in difficult times, you'll find the right resource for you.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 4 skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"baby_and_child" => "false"})
      |> receive_message(%{
        text: "*Well-being*\r\n\r\nWhether you’re looking to add some mindfulness to your day, learn about the importance of looking after your mental health or finding ways to cope in difficult times, you'll find the right resource for you.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 5 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 5 add", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> contact_matches(%{"well_being" => "true"})
      |> receive_message(%{
        text: "*Family planning*\r\n\r\nYou have the power to decide if and when you want children and how many you want. You might want none. You might want lots! Know your options so that you can decide what's best for you.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 5 skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"well_being" => "false"})
      |> receive_message(%{
        text: "*Family planning*\r\n\r\nYou have the power to decide if and when you want children and how many you want. You might want none. You might want lots! Know your options so that you can decide what's best for you.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 6 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 6 add", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> contact_matches(%{"family_planning" => "true"})
      |> receive_message(%{
        text: "*Info for health professionals*\r\n\r\nAre you a nurse? Get support, information, tips and guides to boost your knowledge and skills.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 6 skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"family_planning" => "false"})
      |> receive_message(%{
        text: "*Info for health professionals*\r\n\r\nAre you a nurse? Get support, information, tips and guides to boost your knowledge and skills.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 7 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➕ Add this topic", "Not interested"])
      })
    end

    test "domain 7 add - go to HCW flow", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> contact_matches(%{"info_for_health_professionals" => "true"})
      |> Helpers.handle_profile_hcw_flow()
      |> flow_finished()
    end

    test "domain 7 skip - go to generic flow", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"info_for_health_professionals" => "false"})
      |> Helpers.handle_generic_profile_flow()
      |> flow_finished()
    end

    test "domain 7 skip - go to profile pregnancy health flow", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> FlowTester.send("abcdefghijklmnopqrst")
      |> contact_matches(%{"name" => "abcdefghijklmnopqrst"})
      |> FlowTester.send(button_label: "Let's go")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "➕ Add this topic")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowTester.send(button_label: "Not interested")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Not interested")
      |> contact_matches(%{"pregnancy_information" => "true"})
      |> Helpers.handle_profile_pregnancy_health_flow()
      |> flow_finished()
    end
  end
end
