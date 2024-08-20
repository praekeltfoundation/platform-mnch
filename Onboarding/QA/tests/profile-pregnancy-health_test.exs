defmodule ProfilePregnancyHealthTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  defp flow_path(flow_name), do: Path.join([__DIR__, "..","flows", flow_name <> ".json"])

  def setup_fake_cms(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    error_pg = %ContentPage{
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
          message: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button."
        }
      ]
    }

    error_number = %ContentPage{
      slug: "mnch_onboarding_unrecognised_number",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button."
        }
      ]
    }

    question_01 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_01",
      title: "Pregnancy_QA_01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I've got a *lot* of information on pregnancy! 💡\r\n\r\nTake 2 minutes to answer a few questions so I can find the right info for you.\r\n\r\nIf there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Why are you interested in pregnancy info?*",
          buttons: [
            %Btn.Next{title: "I'm pregnant"},
            %Btn.Next{title: "Partner is pregnant"},
            %Btn.Next{title: "Just curious"}
          ]
        }
      ]
    }

    question_02 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_02",
      title: "Pregnancy_QA_02",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Which month are you expecting your baby to be born?*"
        }
      ]
    }

    question_03 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_03",
      title: "Pregnancy_QA_03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *On what day of the month are you expecting the baby to be born?*\n\nType in a number between 1 and 31. ",
          buttons: []
        }
      ]
    }

    confirm_edd = %ContentPage{
      slug: "mnch_onboarding_confirm_edd",
      title: "Confirm_EDD",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thank you! Just confirming your estimated due date 🗓️\r\n\r\nAre you expecting the baby on *{dd} {month_name} {yyyy}*?",
          buttons: [
            %Btn.Next{title: "Yes, that's right"},
            %Btn.Next{title: "Pick another date"},
          ]
        }
      ]
    }

    question_05 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_05",
      title: "Pregnancy_QA_05",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thank you! \n\n👤 *How are you feeling about this pregnancy?*",
          list_items: [
            %ListItem{value: "Excited"},
            %ListItem{value: "Happy"},
            %ListItem{value: "Worried"},
            %ListItem{value: "Scared"},
            %ListItem{value: "Other"},
          ]
        }
      ]
    }

    content_00 = %ContentPage{
      slug: "mnch_sentiment_excited_happy_third",
      title: "excited_happy_third",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ]
        }
      ]
    }

    loading_01 = %ContentPage{
      slug: "mnch_onboarding_loading_01",
      title: "Loading_01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
          buttons: [
            %Btn.Next{title: "Okay"},
          ]
        }
      ]
    }

    loading_02 = %ContentPage{
      slug: "mnch_facts_factoid_1_trimester_3",
      title: "factoid_1_trimester_3",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ]
        }
      ]
    }

    loading_03 = %ContentPage{
      slug: "mnch_facts_factoid_2_trimester_3",
      title: "factoid_2_trimester_3",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰🏽",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ]
        }
      ]
    }

    topics = %ContentPage{
      slug: "mnch_onboarding_topics_01",
      title: "Topics_01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list_items: [
            %ListItem{value: "item 1"},
            %ListItem{value: "item 2"},
            %ListItem{value: "item 3"},
            %ListItem{value: "item 4"},
            %ListItem{value: "Show me other topics"},
          ]
        }
      ]
    }

    progress_25 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_25",
      title: "Profile_progress_25",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete profile"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Explore health guide"}

          ]
        }
      ]
    }

    progress_50 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_50",
      title: "Profile_progress_50",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete! 🎉\r\n\r\n🤰🏽 Pregnancy info {pregnancy_info_count}\r\n👤 Basic information {basic_info_count}\r\n➡️ Personal information {personal_info_count}\r\n⬜ Daily life {daily_life_count}\r\n\r\n👇🏾 Let’s move on to personal information.",
          buttons: [
            %Btn.Next{title: "Continue"}

          ]
        }
      ]
    }

    progress_100 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_100",
      title: "Profile_progress_100",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete! 🎉 🌟\r\n\r\nYou can always edit it or provide more info.\r\n*Profile name:* {name}\r\n*Baby due date:* {edd}\r\n*Profile questions:* {profile_questions}\r\n*Get important messages:* {get_important_messages}\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "Explore health guide"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Go to main menu"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_pg,
               error_list,
               error_number,
               question_01,
               question_02,
               question_03,
               confirm_edd,
               question_05,
               content_00,
               loading_01,
               loading_02,
               loading_03,
               topics,
               progress_25,
               progress_50,
               progress_100,
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp setup_flow() do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow_path("profile-pregnancy-health")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
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

  describe "profile pregnancy health" do
    test "50% complete" do
      this_month = DateTime.utc_now()

      this_month_plus_one = Date.shift(this_month, month: 1)
      this_month_plus_two = Date.shift(this_month, month: 2)
      this_month_plus_three = Date.shift(this_month, month: 3)
      this_month_plus_four = Date.shift(this_month, month: 4)
      this_month_plus_five = Date.shift(this_month, month: 5)
      this_month_plus_six = Date.shift(this_month, month: 6)
      this_month_plus_seven = Date.shift(this_month, month: 7)
      this_month_plus_eight = Date.shift(this_month, month: 8)

      this_month_word = Calendar.strftime(this_month, "%B")
      this_month_plus_one_word = Calendar.strftime(this_month_plus_one, "%B")
      this_month_plus_two_word = Calendar.strftime(this_month_plus_two, "%B")
      this_month_plus_three_word = Calendar.strftime(this_month_plus_three, "%B")
      this_month_plus_four_word = Calendar.strftime(this_month_plus_four, "%B")
      this_month_plus_five_word = Calendar.strftime(this_month_plus_five, "%B")
      this_month_plus_six_word = Calendar.strftime(this_month_plus_six, "%B")
      this_month_plus_seven_word = Calendar.strftime(this_month_plus_seven, "%B")
      this_month_plus_eight_word = Calendar.strftime(this_month_plus_eight, "%B")

      list_of_months = [
        {"@datevalue(this_month, \"%B\")", "#{this_month_word}"},
        {"@datevalue(this_month_plus_one, \"%B\")", "#{this_month_plus_one_word}"},
        {"@datevalue(this_month_plus_two, \"%B\")", "#{this_month_plus_two_word}"},
        {"@datevalue(this_month_plus_three, \"%B\")", "#{this_month_plus_three_word}"},
        {"@datevalue(this_month_plus_four, \"%B\")", "#{this_month_plus_four_word}"},
        {"@datevalue(this_month_plus_five, \"%B\")", "#{this_month_plus_five_word}"},
        {"@datevalue(this_month_plus_six, \"%B\")", "#{this_month_plus_six_word}"},
        {"@datevalue(this_month_plus_seven, \"%B\")", "#{this_month_plus_seven_word}"},
        {"@datevalue(this_month_plus_eight, \"%B\")", "#{this_month_plus_eight_word}"},
        {"I don't know", "I don't know"}
      ]

      edd_confirmation_text = "Thank you! Just confirming your estimated due date 🗓️\r\n\r\nAre you expecting the baby on *25 #{this_month_plus_one_word} #{Calendar.strftime(this_month_plus_one, "%Y")}*?"

      edd_month = String.pad_leading("#{this_month_plus_one.month}", 2, "0")
      full_edd = Calendar.strftime(this_month_plus_one, "%Y") <> "-" <> "#{edd_month}" <> "-25"

      setup_flow()
      |> FlowTester.set_contact_properties(%{"pregnancy_status" => "", "checkpoint" => "", "profile_completion" => "", "edd" => "", "pregnancy_sentiment" => ""}) # Pregnancy Information
      |> FlowTester.set_contact_properties(%{"year_of_birth" => "1988", "province" => "Western Cape", "area_type" => ""}) # Basic Information
      |> FlowTester.set_contact_properties(%{"relationship_status" => "", "education" => "", "socio_economic" => "", "other_children" => ""}) # Personal Information
      |> FlowTester.set_contact_properties(%{}) # Daily Life
      |> FlowTester.set_contact_properties(%{"gender" => "", "name" => "Lily"})
      |> FlowTester.set_contact_properties(%{"opted_in" => "true"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "I've got a *lot* of information on pregnancy" <> _,
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
      |> FlowTester.send(button_label: this_month_plus_one_word)
      |> receive_message(%{
        text: "👤 *On what day of the month are you expecting the baby to be born?*\n\nType in a number between 1 and 31." <> _
      })
      |> FlowTester.send("25")
      |> receive_message(%{
        text: edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.send(button_label: "Yes, that's right")
      |> contact_matches(%{"edd" => ^full_edd})
      |> receive_message(%{
        text: "Thank you! \n\n👤 *How are you feeling about this pregnancy?*" <> _,
        list: {"I'm feeling", [{"Excited", "Excited"}, {"Happy", "Happy"}, {"Worried", "Worried"}, {"Scared", "Scared"}, {"Other", "Other"}]}
      })
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!" <> _,
        buttons: button_labels(["Let's check it out"])
      })
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳" <> _,
        buttons: button_labels(["Okay"])
      })
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!" <> _,
        buttons: button_labels(["Awesome"])
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰" <> _,
        buttons: button_labels(["Awesome"])
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you" <> _,
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]}
      })
      |> FlowTester.send("item 1")
      |> receive_message(%{
        text: "TODO: Get the article content and display it here" <> _,
        buttons: [{"Complete Profile", "Complete Profile"}, {"Rate this article", "Rate this article"}, {"Choose another topic", "Choose another topic"}]
      })
      |> FlowTester.send(button_label: "Complete Profile")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> contact_matches(%{"profile_completion" => "50%"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
      |> FlowTester.send(button_label: "Continue")
      |> contact_matches(%{"profile_completion" => "100%"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "*Profile name:* Lily")
        assert String.contains?(msg.text, "*Baby due date:* #{full_edd}")
        assert String.contains?(msg.text, "*Profile questions:* 6/11")
        assert String.contains?(msg.text, "*Get important messages:* ✅")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end
  end
end
