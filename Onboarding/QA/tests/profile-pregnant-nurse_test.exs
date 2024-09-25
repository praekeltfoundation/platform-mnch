defmodule ProfilePregnantNurseTest do
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

    pregnant_nurse_20 = %ContentPage{
      slug: "mnch_onboarding_pregnant_nurse_20",
      title: "Pregnant_nurse_20",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 20% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete profile"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Explore health guide"}
          ]
        }
      ]
    }

    pregnant_nurse_40 = %ContentPage{
      slug: "mnch_onboarding_pregnant_nurse_40",
      title: "Pregnant_nurse_40",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 40% complete! 🎉\r\n\r\n🤰🏽 Pregnancy info {pregnancy_info_count}\r\n🏥 Employment information {employment_info_count}\r\n➡️ Basic information {basic_info_count}\r\n⬜ Personal information {personal_info_count}\r\n⬜ Daily life {daily_life_count}\r\n\r\n👇🏾 Let’s move on to some basic information.",
          buttons: [
            %Btn.Next{title: "Continue"}
          ]
        }
      ]
    }

    pregnant_nurse_60 = %ContentPage{
      slug: "mnch_onboarding_pregnant_nurse_60",
      title: "Pregnant_nurse_60",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thanks for sharing!\r\n\r\nNow is your chance to tell me more about yourself. This allows me to give you information that is helpful to *you.*\r\n\r\n🟩🟩🟩🟩🟩⬜⬜⬜\r\n\r\nYour profile is already 60% complete! 🎉\r\n🤰🏽 Pregnancy info {pregnancy_info_count}\r\n🏥 Employment information {employment_info_count}\r\n👤 Basic information {basic_info_count}\r\n➡️ Personal information {personal_info_count}\r\n⬜ Daily life {daily_life_count}\r\n\r\n👇🏾 Let’s move on to some personal information.",
          buttons: [
            %Btn.Next{title: "Continue ➡️"},
            %Btn.Next{title: "Why should I?"}
          ]
        }
      ]
    }

    pregnant_nurse_80 = %ContentPage{
      slug: "mnch_onboarding_pregnant_nurse_80",
      title: "Pregnant_nurse_80",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩⬜⬜\r\n\r\n🤰🏽 Pregnancy info {pregnancy_info_count}\r\n🏥 Employment information {employment_info_count}\r\n👤 Basic information {basic_info_count}\r\n🗝️ Personal information {personal_info_count}\r\n➡️ Daily life {daily_life_count}\r\n\r\nYour profile is already 80% there – now is a good time to take 5 minutes and complete it! ⭐\r\n\r\n👇🏽 What would you like to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete it!"},
            %Btn.Next{title: "Remind me later"}
          ]
        }
      ]
    }

    pregnant_nurse_100 = %ContentPage{
      slug: "mnch_onboarding_pregnant_nurse_100",
      title: "Pregnant_nurse_100",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\n🤰🏽 Pregnancy info {pregnancy_info_count}\r\n🏥 Employment information {employment_info_count}\r\n👤 Basic information {basic_info_count}\r\n🗝️ Personal information {personal_info_count}\r\n☀️ Daily life {daily_life_count}\r\n\r\nYour profile is 100% complete! 🎉 🌟 ⭐\r\n\r\nYou can always edit it or provide more info.\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "Explore health guide"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Go to main menu 📘"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_pg,
               pregnant_nurse_20,
               pregnant_nurse_40,
               pregnant_nurse_60,
               pregnant_nurse_80,
               pregnant_nurse_100,
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

    Helpers.flow_path("profile-pregnant-nurse")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
  end

  defp init_pregnancy_info(context) do
    context |> FlowTester.set_contact_properties(%{"pregnancy_status" => "im_pregnant", "edd" => "24/04/2026", "pregnancy_sentiment" => "excited"})
  end

  describe "profile pregnant nurse" do
    test "100% complete" do
      setup_flow()
      |> init_pregnancy_info()
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> contact_matches(%{"profile_completion" => "20%", "checkpoint" => "pregnant_nurse_profile_20"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 20% complete!" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_profile_hcw_flow(occupational_role: "EN", facility_type: "Clinic", professional_support: "sometimes")
      |> contact_matches(%{"profile_completion" => "40%", "checkpoint" => "pregnant_nurse_profile_40"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Employment information 3/3")
        assert String.contains?(msg.text, "Basic information 0/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 40% complete! 🎉" <> _,
        buttons: button_labels(["Continue"])
      })
      |> FlowTester.send(button_label: "Continue")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1998", province: "prov_1", area_type: "rural", gender: "female")
      |> contact_matches(%{"profile_completion" => "60%", "checkpoint" => "pregnant_nurse_profile_60"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Employment information 3/3")
        assert String.contains?(msg.text, "Basic information 4/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Thanks for sharing!\r\n\r\nNow is your chance to tell me more about yourself." <> _,
        buttons: button_labels(["Continue ➡️", "Why should I?"])
      })
      |> FlowTester.send(button_label: "Continue ➡️")
      |> Helpers.handle_personal_info_flow(relationship_status: "married", education: "school", socio_economic: "", other_children: "1")
      |> contact_matches(%{"profile_completion" => "80%", "checkpoint" => "pregnant_nurse_profile_80"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Employment information 3/3")
        assert String.contains?(msg.text, "Basic information 4/4")
        assert String.contains?(msg.text, "Personal information 3/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩⬜⬜" <> _,
        buttons: button_labels(["➡️ Complete it!", "Remind me later"])
      })
      |> FlowTester.send(button_label: "➡️ Complete it!")
      |> Helpers.handle_daily_life_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Employment information 3/3")
        assert String.contains?(msg.text, "Basic information 4/4")
        assert String.contains?(msg.text, "Personal information 3/4")
        assert String.contains?(msg.text, "Daily life 1/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu 📘"])
      })

    end
  end
end
