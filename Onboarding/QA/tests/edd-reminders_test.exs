defmodule EDDRemindersTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.Message.TextTransform

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    # TODO: This should have qa_mode set, but the flows still need to be updated to include the return_drafts parameter
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The index page isn't in the content sheet, so we need to add it manually.
    indices = [%Index{title: "Onboarding", slug: "test-onboarding"}]
    assert :ok = FakeCMS.add_pages(wh_pid, indices)

    # These options are common to all CSV imports below.
    import_opts = [
      existing_pages: indices,
      field_transform: fn s ->
        s
        |> String.replace(~r/\r?\r\n$/, "")
        |> String.replace("{username}", "{@username}")
        # TODO: Fix this in FakeCMS
        |> String.replace("\u200D", "")

        # These transforms are specific to these tests
      end
    ]
    # The onboarding.csv content file contains a page that references a Whatsapp Template.
    # We don't support importing of templates yet, so for now we add it manually  
    FakeCMS.add_template(wh_pid, %WATemplate{
      id: "1",
      slug: "mnch_onboarding_edd_reminder",
      category: "MARKETING",
      image: nil,
      message: "This is a test message",
      buttons: [],
      example_values: [],
      submission_status: "",
      submission_name: "",
      submission_result: ""
    })


    # The content for these tests.
    assert :ok = Helpers.import_content_csv(wh_pid, "onboarding", import_opts)

    # TODO: CSV import doesn't currently support languages, so we manually add these two Portuguese pages for tests
    edd_reminder_pt = %ContentPage{
      slug: "mnch_onboarding_edd_reminder",
      title: "EDD Reminder pt",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Olá {username}\r\n\r\nSua próxima visita antenatal está chegando logo, não esqueça de perguntar ao profissional de saúde sua data de parto prevista 👩🏽\r\n\r\nVocê pode atualizar a data de parto na configuração, encontrada no menu principal.",
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
            %Btn.Next{title: "Ver menu principal"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(
               wh_pid,
               [
                 %Index{slug: "test", title: "test"},
                 edd_reminder_pt,
                 got_it_pt
               ],
               "pt"
             )

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
      |> FlowTester.add_message_text_transform(
        TextTransform.normalise_newlines(trim_trailing_spaces: true)
      )
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

    full_edd =
      Calendar.strftime(Enum.at(months, 1), "%Y") <>
        "-" <> "#{edd_month}" <> "-#{selected_edd_day}"

    edd_confirmation_text =
      "I’ve updated your baby’s estimated due date to: #{full_edd}\r\n\r\nWell done on taking care of yours and baby’s health!"

    {list_of_months, edd_confirmation_text, full_edd}
  end

  describe "EDD Reminder" do
    # @describetag skip: "TODO: Implement support for Template CSV import etc"
    @tag :thisone
    test "Got it", %{flow: flow} do
      flow
     
      |> FlowTester.start()
      |> receive_message(%{
        # text: "[DEBUG]\r\nTemplate edd_reminder_2041 sent with language en_US.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url"  <> _,
        text:
          "[DEBUG]\r\nTemplate @submission_name sent with language en_US.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url\r\n\r\nThe buttons represented here are not necessarily the same as the ones in the real template. Please double check the template buttons when running the flow in a real-world scenario." <>
            _,
        buttons: [
          {"edd_got_it", "edd_got_it"},
          {"edd_month", "edd_month"},
          {"eddr_unknown", "eddr_unknown"}
        ]
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Well done on taking care of you and baby’s health 🫶🏽",
        buttons: button_labels(["See main menu"])
      })
    end

    test "Got it (pt)", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"language" => "por"})
      |> FlowTester.start()
      |> receive_message(%{
        # text: "[DEBUG]\r\nTemplate edd_reminder_2041_pt sent with language pt_PT.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url"  <> _,
        text:
          "[DEBUG]\r\nTemplate @submission_name sent with language pt_PT.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url" <>
            _,
        buttons: [
          {"edd_got_it", "edd_got_it"},
          {"edd_month", "edd_month"},
          {"eddr_unknown", "eddr_unknown"}
        ]
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Bem feito por você e pelo seu bebê!",
        buttons: button_labels(["Ver menu principal"])
      })
    end

    test "Got it text only", %{flow: flow} do
      flow
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{
        # text: "[DEBUG]\r\nTemplate edd_reminder_2041 sent with language en_US.\r\nBody parameters: [@name]\r\n\r\nThe buttons represented"  <> _,
        text:
          "[DEBUG]\r\nTemplate @submission_name sent with language en_US.\r\nBody parameters: [@name]\r\n\r\nThe buttons represented here are not necessarily the same as the ones in the real template. Please double check the template buttons when running the flow in a real-world scenario." <>
            _,
        buttons: [
          {"edd_got_it", "edd_got_it"},
          {"edd_month", "edd_month"},
          {"eddr_unknown", "eddr_unknown"}
        ]
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Well done on taking care of you and baby’s health 🫶🏽",
        buttons: button_labels(["See main menu"])
      })
    end

    # TODO: Figure out why this doesn't work - it probably has something to do with the fact that we're sending a template
    # test "Got it error", %{flow: flow} do
    #   flow
    #   |> FlowTester.start()
    #   |> receive_message(%{
    #     text: "[DEBUG]\r\nTemplate edd_reminder_2041 sent with language en_US.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url"  <> _,
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
        # text: "[DEBUG]\r\nTemplate edd_reminder_2041 sent with language en_US.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url"  <> _,
        text:
          "[DEBUG]\r\nTemplate @submission_name sent with language en_US.\r\nBody parameters: [@name]\r\nMedia link: @image_data.body.meta.download_url\r\n\r\nThe buttons represented here are not necessarily the same as the ones in the real template. Please double check the template buttons when running the flow in a real-world scenario." <>
            _,
        buttons: [
          {"edd_got_it", "edd_got_it"},
          {"edd_month", "edd_month"},
          {"eddr_unknown", "eddr_unknown"}
        ]
      })
      |> FlowTester.send("edd_got_it")
      |> receive_message(%{
        text: "Well done on taking care of you and baby’s health 🫶🏽",
        buttons: button_labels(["See main menu"])
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
        text:
          "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic visit 🧑🏾⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "EDD Unknown error", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{
        text:
          "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic visit 🧑🏾⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
      |> FlowTester.send("Nope")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
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
        buttons: button_labels(["See main menu", "Go to health guide"])
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
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["See main menu", "Go to health guide"])
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
        buttons: button_labels(["See main menu", "Go to health guide"])
      })
      |> FlowTester.send(button_label: "See main menu")
      |> Helpers.handle_profile_pregnancy_health_flow()
      |> flow_finished()
    end

    @tag :temptest
    test "I'll do this later -> go to health guide", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("eddr_unknown")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{
        text: "Ok! We'll remind you again in a while.\r\n\r\n👇🏽 What would you like to do now?",
        buttons: button_labels(["See main menu", "Go to health guide"])
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
        text:
          "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        # list: {"Month", ^list_of_months}
        # TODO: Fix this so it works regardless of current month
        list:
          {"Month",
           [
             {"@datevalue(this_month, \"%B\")", "August"},
             {"@datevalue(this_month_plus_one, \"%B\")", "September"},
             {"@datevalue(this_month_plus_two, \"%B\")", "October"},
             {"@datevalue(this_month_plus_three, \"%B\")", "November"},
             {"@datevalue(this_month_plus_four, \"%B\")", "December"},
             {"@datevalue(this_month_plus_five, \"%B\")", "January"},
             {"@datevalue(this_month_plus_six, \"%B\")", "February"},
             {"@datevalue(this_month_plus_seven, \"%B\")", "March"},
             {"@datevalue(this_month_plus_eight, \"%B\")", "April"},
             {"I don't know", "I don't know"}
           ]}
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
        text:
          "*It's important to know the due date* 🗓️\r\n\r\nThere are 2 ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the 1st day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic visit 🧑🏾⚕️\r\n\r\nYou can update the expected due date in Settings, found in the main menu.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
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
        text:
          "On what *day* of the month are you expecting the baby to be born?\r\n\r\nType in a number between 1 and 31.\r\n\r\nIf you don't know, reply `Skip`"
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
        # text:  ^edd_confirmation_text,
        text:
          "I’ve updated your baby’s estimated due date to: 2025-09-25\r\n\r\nWell done on taking care of yours and baby’s health 🫶🏽"
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
      # TODO: Fix the assertion to get the correct end day for the month
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 30."
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
      # TODO: Fix the assertion to get the correct end day for the month
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 30."
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
      # TODO: Fix the assertion to get the correct end day for the month
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 30."
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
        text:
          "I’ve updated your baby’s estimated due date to: 2023-02-29\r\n\r\nWell done on taking care of yours and baby’s health 🫶🏽",
        # text: ^edd_confirmation_text,
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
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 29."
      })
    end

    test "edd day then long month 31 is valid", %{flow: flow} do
      # January
      fake_time = ~U[2023-01-01 00:00:00Z]
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
        text:
          "I’ve updated your baby’s estimated due date to: 2023-01-31\r\n\r\nWell done on taking care of yours and baby’s health 🫶🏽",
        # text: ^edd_confirmation_text,
        buttons: button_labels(["See main menu"])
      })
    end

    test "edd day then long month 32 is invalid", %{flow: flow} do
      # January
      fake_time = ~U[2024-01-01 00:00:00Z]
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
      # TODO: Fix the assertion to get the correct end day for the month
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
    end

    test "edd day then short month 30 is valid", %{flow: flow} do
      # April
      fake_time = ~U[2024-04-01 00:00:00Z]
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
        # text: ^edd_confirmation_text,
        text:
          "I’ve updated your baby’s estimated due date to: 2024-04-30\r\n\r\nWell done on taking care of yours and baby’s health 🫶🏽",
        buttons: button_labels(["See main menu"])
      })
    end

    test "edd day then short month 31 is invalid", %{flow: flow} do
      # April
      fake_time = ~U[2024-04-01 00:00:00Z]
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
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 30."
      })
    end
  end
end
