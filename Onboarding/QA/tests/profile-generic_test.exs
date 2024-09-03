defmodule ProfileGenericTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

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

    progress_30_generic = %ContentPage{
      slug: "mnch_onboarding_profile_progress_30_generic",
      title: "Profile_progress_30_generic",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Your profile is already 30% complete!\n\n🟩🟩🟩⬜⬜⬜⬜⬜ \n\n👤 Basic information {basic_info_count}\n➡️ Personal information {personal_info_count}\n⬜ Daily life {daily_life_count}\n\n👇🏽 Let’s move on to personal information.",
          buttons: [
            %Btn.Next{title: "Continue"},
            %Btn.Next{title: "Why?"}
          ]
        }
      ]
    }

    progress_100_generic = %ContentPage{
      slug: "mnch_onboarding_profile_progress_100_generic",
      title: "Profile_progress_100_generic",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete! 🎉 🌟\r\n\r\nYou can always edit it or provide more info. \r\n\r\n*Name:* {name}\r\n*Basic info:* {basic_info_count}\r\n*Personal info:* {personal_info_count}\r\n*Get important messages:* {get_important_messages}\r\n\r\n👇🏾 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "Explore health guide"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Go to main menu"}
          ]
        }
      ]
    }

    why_personal_info_1 = %ContentPage{
      slug: "mnch_onboarding_why_personal_info_1",
      title: "Why_personal_info_1",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "ℹ️ Our team of experts has put together loads of health information for you. To quickly get a selection of the info that is valuable to you, share more information about yourself.\n\nReady to share?",
          buttons: [
            %Btn.Next{title: "Yes, let's go"},
            %Btn.Next{title: "Not right now"}
          ]
        }
      ]
    }

    remind_later = %ContentPage{
      slug: "mnch_onboarding_remind_later",
      title: "Remind_later",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*All good. I’ll check in with you about this another time.* 🗓️\r\n\r\nFor now, I recommend having a look at some of the most popular topics on {MyHealth}.\r\n\r\n👇🏽 What do you want to do now?",
          buttons: [
            %Btn.Next{title: "See popular topics"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_pg,
               progress_30_generic,
               progress_100_generic,
               why_personal_info_1,
               remind_later
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

    flow_path("profile-generic")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
  end

  describe "profile generic" do
    test "30% complete" do
      setup_flow()
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
    end

    test "30% complete -> why -> let's go" do
      setup_flow()
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Why?")
      |> receive_message(%{
        text: "ℹ️ Our team of experts has put together" <> _,
        buttons: button_labels(["Yes, let's go", "Not right now"])
      })
      |> FlowTester.send(button_label: "Yes, let's go")
      |> Helpers.handle_personal_info_flow()
      |> Helpers.handle_daily_life_flow()
      |> Helpers.handle_opt_in_reminder_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "30% complete -> why -> not right now" do
      setup_flow()
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Why?")
      |> receive_message(%{
        text: "ℹ️ Our team of experts has put together" <> _,
        buttons: button_labels(["Yes, let's go", "Not right now"])
      })
      |> FlowTester.send(button_label: "Not right now")
      |> receive_message(%{
        text: "*All good. I’ll check in with you about this another time.* 🗓️" <> _,
        buttons: button_labels(["See popular topics"])
      })
    end

    test "100% complete - all complete" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"name" => "Severus"})
      |> FlowTester.set_contact_properties(%{"opted_in" => "true"})
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "rural", gender: "male")
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Continue")
      |> Helpers.handle_personal_info_flow(relationship_status: "single", education: "degree", socio_economic: "i get by", other_children: "0")
      |> Helpers.handle_daily_life_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "*Name:* Severus")
        assert String.contains?(msg.text, "*Basic info:* ✅")
        assert String.contains?(msg.text, "*Personal info:* ✅")
        assert String.contains?(msg.text, "*Get important messages:* ✅")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "100% complete - incomplete basic info" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"name" => "Severus"})
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Continue")
      |> Helpers.handle_personal_info_flow()
      |> Helpers.handle_daily_life_flow()
      |> Helpers.handle_opt_in_reminder_flow()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "*Name:* Severus")
        assert String.contains?(msg.text, "*Basic info:* 3/4")
        assert String.contains?(msg.text, "*Personal info:* 0/4")
        assert String.contains?(msg.text, "*Get important messages:* ❌")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end
  end


end
