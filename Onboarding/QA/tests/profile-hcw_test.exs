defmodule ProfileHCWTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

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
          message: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button."
        }
      ]
    }

    nurse_check = %ContentPage{
      slug: "mnch_onboarding_nursecheck",
      title: "NurseCheck",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Great! We have *lots* of interesting info for nurses.\r\n*Are you working as a nurse at the moment, or are you just curious?*",
          buttons: [
            %Btn.Next{title: "I am a nurse"},
            %Btn.Next{title: "Just curious"}
          ]
        }
      ]
    }

    occupational_role = %ContentPage{
      slug: "mnch_onboarding_occupational_role",
      title: "Occupational_role",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🏥 *What title best describes the type of nurse you are?*\r\n\r\n• Enrolled Nurse (EN)\r\n• Enrolled Nursing Auxiliary (ENA)\r\n• Registered Nurse (RN)\r\n• Advanced Practice Nurse (APN)\r\n• Public Health Nurse\r\n• Midwife\r\n• Psychiatric Nurse\r\n• Other",
          list_items: [
            %ListItem.Next{title: "EN"},
            %ListItem.Next{title: "ENA"},
            %ListItem.Next{title: "RN"},
            %ListItem.Next{title: "APN"},
            %ListItem.Next{title: "Public Health Nurse"},
            %ListItem.Next{title: "Midwife"},
            %ListItem.Next{title: "Psychiatric nurse"},
            %ListItem.Next{title: "Other"},
          ]
        }
      ]
    }

    facility_type = %ContentPage{
      slug: "mnch_onboarding_facility_type",
      title: "Facility_type",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🏥 *What kind of healthcare facility do you work in?*\r\n\r\n• Level 1 - District Hospital\r\n• Level 2 - Regional Hospital\r\n• Level 3 - Academic Hospital\r\n• Clinic\r\n• Community Health Clinic (CHC)\r\n• Satellite Clinic\r\n• Other",
          list_items: [
            %ListItem.Next{title: "Level 1"},
            %ListItem.Next{title: "Level 2"},
            %ListItem.Next{title: "Level 3"},
            %ListItem.Next{title: "Clinic"},
            %ListItem.Next{title: "CHC"},
            %ListItem.Next{title: "Satellite Clinic"},
            %ListItem.Next{title: "Other"},
          ]
        }
      ]
    }

    workplace_support = %ContentPage{
      slug: "mnch_onboarding_professional_support",
      title: "Professional_support",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🏥 *Do you feel supported in the workplace?*",
          buttons: [
            %Btn.Next{title: "Yes, always"},
            %Btn.Next{title: "Sometimes"},
            %Btn.Next{title: "No, never"}
          ]
        }
      ]
    }

    progress_25 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_25_hcw",
      title: "Profile_progress_25_hcw",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thanks for sharing! \r\n\r\nNow is your chance to tell me more about yourself, so I give you information that is valuable to *you.*\r\n\r\n🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\n🏥 Employment information {employment_info_count}\r\n➡️ Basic information {basic_info_count}\r\n⬜ Personal information {personal_info_count}\r\n⬜ Daily life {daily_life_count}\r\n\r\n👇🏾  Are you ready to answer a few questions?",
          buttons: [
            %Btn.Next{title: "Sure, let's go ➡️"},
            %Btn.Next{title: "Why?"}
          ]
        }
      ]
    }

    progress_50 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_50_hcw",
      title: "Profile_progress_50_hcw",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Your profile is already 50% complete!\r\n\r\n🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\n🏥 Employment information {employment_info_count}\r\n👤 Basic information {basic_info_count}\r\n➡️ Personal information {personal_info_count}\r\n⬜ Daily life {daily_life_count}\r\n\r\n\r\n👇🏽 Let’s move on to personal information.",
          buttons: [
            %Btn.Next{title: "Let's go"}
          ]
        }
      ]
    }

    progress_75 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_75_hcw",
      title: "Profile_progress_75_hcw",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩⬜⬜ \r\n\r\n🏥 Employment information {employment_info_count}\r\n👤 Basic information {basic_info_count}\r\n🗝️ Personal information {personal_info_count}\r\n➡️ Daily life {daily_life_count}\r\n\r\nYour profile is already 75% there – now is a good time to take 5 minutes and complete it! ⭐\r\n\r\n👇🏽 What would you like to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete it!"},
            %Btn.Next{title: "Remind me later"}
          ]
        }
      ]
    }

    progress_100 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_100_hcw",
      title: "Profile_progress_100_hcw",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩🟩🟩 \r\n\r\n🏥 Employment information {employment_info_count}\r\n👤 Basic information {basic_info_count}\r\n🗝️ Personal information {personal_info_count}\r\n☀️ Daily life {daily_life_count}\r\nYour profile is 100% complete! 🎉 🌟 ⭐\r\n\r\nYou can always edit it or provide more info in `Menu -> Profile`\r\n\r\n👇🏽 What do you want to do next?",
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
               nurse_check,
               occupational_role,
               facility_type,
               workplace_support,
               progress_25,
               progress_50,
               progress_75,
               progress_100
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("profile-hcw")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
    %{flow: flow}
  end

  setup [:setup_flow]

  describe "profile hcw" do
    test "100% complete", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> contact_matches(%{"profile_completion" => "0%", "checkpoint" => "hcw_profile_0"})
      |> receive_message(%{
        text: "Great! We have *lots* of interesting info for nurses." <> _,
        buttons: button_labels(["I am a nurse", "Just curious"])
      })
      |> FlowTester.send(button_label: "I am a nurse")
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`" <> _,
        list: {"Role", [{"EN", "EN"}, {"ENA", "ENA"}, {"RN", "RN"}, {"APN", "APN"}, {"Public Health Nurse", "Public Health Nurse"},{"Midwife", "Midwife"},{"Psychiatric nurse", "Psychiatric nurse"},{"Other", "Other"}]}
      })
      |> FlowTester.send(button_label: "EN")
      |> contact_matches(%{"occupational_role" => "en"})
      |> receive_message(%{
        text: "🏥 *What kind of healthcare facility do you work in?*" <> _,
        list: {"Facility", [{"Level 1", "Level 1"}, {"Level 2", "Level 2"}, {"Level 3", "Level 3"}, {"Clinic", "Clinic"}, {"CHC", "CHC"},{"Satellite Clinic", "Satellite Clinic"},{"Other", "Other"}]}
      })
      |> FlowTester.send(button_label: "Level 1")
      |> contact_matches(%{"facility_type" => "level 1"})
      |> receive_message(%{
        text: "🏥 *Do you feel supported in the workplace?*" <> _,
        buttons: [{"Yes, always", "Yes, always"}, {"Sometimes", "Sometimes"}, {"No, never", "No, never"}]
      })
      |> FlowTester.send(button_label: "Sometimes")
      |> contact_matches(%{"professional_support" => "sometimes"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "🏥 Employment information 3/3")
        assert String.contains?(msg.text, "➡️ Basic information 0/4")
        assert String.contains?(msg.text, "⬜ Personal information 0/4")
        assert String.contains?(msg.text, "⬜ Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Thanks for sharing! \r\n\r\nNow is your chance to tell me more about yourself" <> _,
        buttons: button_labels(["Sure, let's go ➡️", "Why?"])
      })
      |> FlowTester.send(button_label: "Sure, let's go ➡️")
      |> Helpers.handle_basic_profile_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "🏥 Employment information 3/3")
        assert String.contains?(msg.text, "👤 Basic information 3/4")
        assert String.contains?(msg.text, "➡️ Personal information 0/4")
        assert String.contains?(msg.text, "⬜ Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 50% complete!" <> _,
        buttons: button_labels(["Let's go"])
      })
      |> FlowTester.send(button_label: "Let's go")
      |> Helpers.handle_personal_info_flow(relationship_status: "single", education: "degree", socio_economic: "i get by", other_children: "0")
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "🏥 Employment information 3/3")
        assert String.contains?(msg.text, "👤 Basic information 3/4")
        assert String.contains?(msg.text, "🗝️ Personal information 4/4")
        assert String.contains?(msg.text, "➡️ Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩⬜⬜ " <> _,
        buttons: button_labels(["➡️ Complete it!", "Remind me later"])
      })
      |> FlowTester.send(button_label: "➡️ Complete it!")
      |> Helpers.handle_daily_life_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "🏥 Employment information 3/3")
        assert String.contains?(msg.text, "👤 Basic information 3/4")
        assert String.contains?(msg.text, "🗝️ Personal information 4/4")
        assert String.contains?(msg.text, "☀️ Daily life 1/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩 " <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end
  end
end
