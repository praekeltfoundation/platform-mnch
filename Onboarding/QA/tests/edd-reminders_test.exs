defmodule EDDRemindersTest do
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

    error_number = %ContentPage{
      slug: "mnch_onboarding_unrecognised_number",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
        }
      ]
    }

    edd_reminder = %ContentPage{
      slug: "mnch_onboarding_edd_reminder",
      title: "EDD Reminder",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Hey {username}\r\n\r\nYour next antenatal visit is coming up soon, don’t forget to ask the health worker to confirm your expected due date 👩🏽‍⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
          buttons: [
            %Btn.Next{title: "Got it!"},
            %Btn.Next{title: "Update due date"},
            %Btn.Next{title: "How to calculate it"}
          ]
        }
      ],
      whatsapp_template_name: "edd_reminder_2041"
    }

    got_it = %ContentPage{
      slug: "mnch_onboarding_edd_got_it",
      title: "Got it",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Well done on taking care of you and baby’s health!",
          buttons: [
            %Btn.Next{title: "See main menu"},
          ]
        }
      ]
    }

    edd_reminder_pt = %ContentPage{
      slug: "mnch_onboarding_edd_reminder",
      title: "EDD Reminder pt",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Olá {username}\r\n\r\nSua próxima visita antenatal está chegando logo, não esqueça de perguntar ao profissional de saúde sua data de parto prevista 👩🏽\r\n\r\nVocê pode atualizar a data de parto na configuração, encontrada no menu principal.",
          buttons: [
            %Btn.Next{title: "Entendi!"},
            %Btn.Next{title: "Atualizar data de parto"},
            %Btn.Next{title: "Como calcular"}
          ]
        }
      ],
      whatsapp_template_name: "edd_reminder_2041_pt"
    }

    got_it_pt = %ContentPage{
      slug: "mnch_onboarding_edd_got_it",
      title: "Got it pt",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Bem feito por você e pelo seu bebê!",
          buttons: [
            %Btn.Next{title: "Ver menu principal"},
          ]
        }
      ]
    }

    edd_month = %ContentPage{
      slug: "mnch_onboarding_edd_month",
      title: "EDD Month",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Great.\r\n\r\n👇🏽 Which month are you expecting your baby to be born?"
        }
      ]
    }

    edd_day = %ContentPage{
      slug: "mnch_onboarding_edd_day",
      title: "EDD Day",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "On what *day* of the month are you expecting the baby to be born?\r\n\r\nType in a number between 1 and 31.\r\n\r\nIf you don't know, reply `Skip`"
        }
      ]
    }

    edd_confirmed = %ContentPage{
      slug: "mnch_onboarding_edd_confirmed",
      title: "EDD Confirmed",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I’ve updated your baby’s estimated due date to: [edd]\r\n\r\nWell done on taking care of yours and baby’s health!",
          buttons: [
            %Btn.Next{title: "See main menu"}
          ]
        }
      ]
    }

    edd_unknown = %ContentPage{
      slug: "mnch_onboarding_edd_unknown",
      title: "EDD_unknown_1",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
          buttons: [
            %Btn.Next{title: "Update due date"},
            %Btn.Next{title: "I’ll do this later"},
          ]
        }
      ]
    }

    do_it_later = %ContentPage{
      slug: "mnch_onboarding_edd_do_it_later",
      title: "EDD Do it later",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Ok! We'll remind you again in a while.\r\n\r\n👇🏽 What would you like to do now?",
          buttons: [
            %Btn.Next{title: "See main menu"},
            %Btn.Next{title: "Go to health guide"},
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_button,
               error_list,
               error_number,
               edd_reminder,
               got_it,
               edd_month,
               edd_day,
               edd_confirmed,
               edd_unknown,
               do_it_later
             ], "en")

      assert :ok =
              FakeCMS.add_pages(wh_pid, [
                %Index{slug: "test", title: "test"},
                edd_reminder_pt,
                got_it_pt
              ], "pt")

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("edd-reminders")}

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

  defp get_months(this_month \\ DateTime.utc_now()) do
    [
      this_month,
      Date.shift(this_month, month: 1),
      Date.shift(this_month, month: 2),
      Date.shift(this_month, month: 3),
      Date.shift(this_month, month: 4),
      Date.shift(this_month, month: 5),
      Date.shift(this_month, month: 6),
      Date.shift(this_month, month: 7),
      Date.shift(this_month, month: 8)
    ]

  end

  defp get_month_words(months) do
    [
      Calendar.strftime(Enum.at(months, 0), "%B"),
      Calendar.strftime(Enum.at(months, 1), "%B"),
      Calendar.strftime(Enum.at(months, 2), "%B"),
      Calendar.strftime(Enum.at(months, 3), "%B"),
      Calendar.strftime(Enum.at(months, 4), "%B"),
      Calendar.strftime(Enum.at(months, 5), "%B"),
      Calendar.strftime(Enum.at(months, 6), "%B"),
      Calendar.strftime(Enum.at(months, 7), "%B"),
      Calendar.strftime(Enum.at(months, 8), "%B")
    ]
  end

  defp get_edd(months, month_words, selected_edd_day \\ 25, selected_edd_month \\ 1) do
    list_of_months = [
      {"@datevalue(this_month, \"%B\")", "#{Enum.at(month_words, 0)}"},
      {"@datevalue(this_month_plus_one, \"%B\")", "#{Enum.at(month_words, 1)}"},
      {"@datevalue(this_month_plus_two, \"%B\")", "#{Enum.at(month_words, 2)}"},
      {"@datevalue(this_month_plus_three, \"%B\")", "#{Enum.at(month_words, 3)}"},
      {"@datevalue(this_month_plus_four, \"%B\")", "#{Enum.at(month_words, 4)}"},
      {"@datevalue(this_month_plus_five, \"%B\")", "#{Enum.at(month_words, 5)}"},
      {"@datevalue(this_month_plus_six, \"%B\")", "#{Enum.at(month_words, 6)}"},
      {"@datevalue(this_month_plus_seven, \"%B\")", "#{Enum.at(month_words, 7)}"},
      {"@datevalue(this_month_plus_eight, \"%B\")", "#{Enum.at(month_words, 8)}"},
      {"I don't know", "I don't know"}
    ]

    edd_month = String.pad_leading("#{Enum.at(months, selected_edd_month).month}", 2, "0")
    full_edd = Calendar.strftime(Enum.at(months, 1), "%Y") <> "-" <> "#{edd_month}" <> "-#{selected_edd_day}"

    edd_confirmation_text = "I’ve updated your baby’s estimated due date to: #{full_edd}\r\n\r\nWell done on taking care of yours and baby’s health!"

    {list_of_months, edd_confirmation_text, full_edd}
  end

  describe "EDD Reminder" do
    test "Got it", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "[DEBUG]\nTemplate edd_reminder_2041 sent with language en_US.\nBody parameters: [@name]\nMedia link: @image_data.body.meta.download_url"  <> _,
        buttons: [{"edd_got_it", "edd_got_it"}, {"edd_month", "edd_month"}, {"eddr_unknown", "eddr_unknown"}],
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Well done on taking care of you and baby’s health!",
        buttons: button_labels(["See main menu"]),
      })
    end

    test "Got it (pt)", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"language" => "por"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "[DEBUG]\nTemplate edd_reminder_2041_pt sent with language pt_PT.\nBody parameters: [@name]\nMedia link: @image_data.body.meta.download_url"  <> _,
        buttons: [{"edd_got_it", "edd_got_it"}, {"edd_month", "edd_month"}, {"eddr_unknown", "eddr_unknown"}],
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Bem feito por você e pelo seu bebê!",
        buttons: button_labels(["Ver menu principal"]),
      })
    end

    test "Got it text only", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "[DEBUG]\nTemplate edd_reminder_2041 sent with language en_US.\nBody parameters: [@name]\r\n\r\nThe buttons represented"  <> _,
        buttons: [{"edd_got_it", "edd_got_it"}, {"edd_month", "edd_month"}, {"eddr_unknown", "eddr_unknown"}],
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Well done on taking care of you and baby’s health!",
        buttons: button_labels(["See main menu"]),
      })
    end

    # TODO: Figure out why this doesn't work - it probably has something to do with the fact that we're sending a template
    # test "Got it error", %{flow: flow} do
    #   flow
    #   |> FlowTester.start()
    #   |> receive_message(%{
    #     text: "[DEBUG]\nTemplate edd_reminder_2041 sent with language en_US.\nBody parameters: [@name]\nMedia link: @image_data.body.meta.download_url"  <> _,
    #     buttons: [{"edd_got_it", "edd_got_it"}, {"edd_month", "edd_month"}, {"eddr_unknown", "eddr_unknown"}],
    #   })
    #   |> FlowTester.send(button_label: "nope")
    #   |> receive_message(%{
    #     text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
    #     buttons: [{"edd_got_it", "edd_got_it"}, {"edd_month", "edd_month"}, {"eddr_unknown", "eddr_unknown"}],
    #   })
    # end

    test "Got it -> Main menu", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "[DEBUG]\nTemplate edd_reminder_2041 sent with language en_US.\nBody parameters: [@name]\nMedia link: @image_data.body.meta.download_url"  <> _,
        buttons: [{"edd_got_it", "edd_got_it"}, {"edd_month", "edd_month"}, {"eddr_unknown", "eddr_unknown"}],
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Well done on taking care of you and baby’s health!",
        buttons: button_labels(["See main menu"]),
      })
      |> FlowTester.send(button_label: "See main menu")
      |> Helpers.handle_profile_pregnancy_health_flow()
      |> flow_finished()
    end

    test "EDD Unknown", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
        buttons: button_labels(["Update due date", "I’ll do this later"]),
      })
    end

    test "EDD Unknown error", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
        buttons: button_labels(["Update due date", "I’ll do this later"]),
      })
      |> FlowTester.send("Nope")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Update due date", "I’ll do this later"]),
      })
    end

    test "EDD Unknown -> I'll do this later", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{
        text: "Ok! We'll remind you again in a while.\r\n\r\n👇🏽 What would you like to do now?",
        buttons: button_labels(["See main menu", "Go to health guide"]),
      })
    end

    test "EDD Unknown -> Update due date", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Update due date")
      |> receive_message(%{
        text: "Great.\r\n\r\n👇🏽 Which month are you expecting your baby to be born?",
        list: {"Month", ^list_of_months}
      })
    end

    test "I'll do this later error", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{})
      |> FlowTester.send("Nope")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["See main menu", "Go to health guide"]),
      })
    end

    test "I'll do this later -> main menu", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{
        text: "Ok! We'll remind you again in a while.\r\n\r\n👇🏽 What would you like to do now?",
        buttons: button_labels(["See main menu", "Go to health guide"]),
      })
      |> FlowTester.send(button_label: "See main menu")
      |> Helpers.handle_profile_pregnancy_health_flow()
      |> flow_finished()
    end

    test "I'll do this later -> go to health guide", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{
        text: "Ok! We'll remind you again in a while.\r\n\r\n👇🏽 What would you like to do now?",
        buttons: button_labels(["See main menu", "Go to health guide"]),
      })
      |> FlowTester.send(button_label: "Go to health guide")
      |> Helpers.handle_profile_pregnancy_health_flow()
      |> flow_finished()
    end

    test "edd month", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{
        text: "Great.\r\n\r\n👇🏽 Which month are you expecting your baby to be born?",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month -> edd unknown", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1
      month = elem(Enum.at(list_of_months, last_month), 0)

      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
        buttons: button_labels(["Update due date", "I’ll do this later"]),
      })
    end

    test "edd month -> edd day", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 2), 0)

      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{
        text: "On what *day* of the month are you expecting the baby to be born?\r\n\r\nType in a number between 1 and 31.\r\n\r\nIf you don't know, reply `Skip`",
      })
    end

    test "edd day -> confirmed", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{
        text:  ^edd_confirmation_text,
      })
      |> contact_matches(%{"edd" => ^full_edd})
      |> result_matches(%{name: "edd", value: ^full_edd})
    end

    test "edd confirmed -> main menu", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "See main menu")
      |> Helpers.handle_profile_pregnancy_health_flow()
      |> flow_finished()
    end

    ## EDD Calculator Validation
    test "edd day then not number error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then not a day error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("0")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then above max day error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then feb 29 is valid", %{flow: flow} do
      fake_time = ~U[2023-02-28 00:00:00Z]
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 29, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("29")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["See main menu"])
      })
    end

    test "edd day then feb 30 is not valid", %{flow: flow} do
      fake_time = ~U[2023-02-28 00:00:00Z]
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("30")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then long month 31 is valid", %{flow: flow} do
      fake_time = ~U[2023-01-01 00:00:00Z] # January
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 31, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("31")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["See main menu"])
      })
    end

    test "edd day then long month 32 is invalid", %{flow: flow} do
      fake_time = ~U[2024-01-01 00:00:00Z] # January
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then short month 30 is valid", %{flow: flow} do
      fake_time = ~U[2024-04-01 00:00:00Z] # April
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 30, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("30")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["See main menu"])
      })
    end

    test "edd day then short month 31 is invalid", %{flow: flow} do
      fake_time = ~U[2024-04-01 00:00:00Z] # April
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("edd_month")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("31")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end
  end
end
