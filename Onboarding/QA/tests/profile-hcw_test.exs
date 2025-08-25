defmodule ProfileHCWTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.Message.TextTransform
  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
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

    # The content for these tests.
    assert :ok = Helpers.import_content_csv(wh_pid, "onboarding", import_opts)

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("profile-hcw")}

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
        list:
          {"Role",
           [
             {"EN", "EN"},
             {"ENA", "ENA"},
             {"RN", "RN"},
             {"APN", "APN"},
             {"Public Health Nurse", "Public Health Nurse"},
             {"Midwife", "Midwife"},
             {"Psychiatric nurse", "Psychiatric nurse"},
             {"Other", "Other"}
           ]}
      })
      |> FlowTester.send(button_label: "EN")
      |> contact_matches(%{"occupational_role" => "en"})
      |> receive_message(%{
        text: "🏥 *What kind of healthcare facility do you work in?*" <> _,
        list:
          {"Facility",
           [
             {"Level 1", "Level 1"},
             {"Level 2", "Level 2"},
             {"Level 3", "Level 3"},
             {"Clinic", "Clinic"},
             {"CHC", "CHC"},
             {"Satellite Clinic", "Satellite Clinic"},
             {"Other", "Other"}
           ]}
      })
      |> FlowTester.send(button_label: "Level 1")
      |> contact_matches(%{"facility_type" => "level 1"})
      |> receive_message(%{
        text: "🏥 *Do you feel supported in the workplace?*" <> _,
        buttons: [
          {"Yes, always", "Yes, always"},
          {"Sometimes", "Sometimes"},
          {"No, never", "No, never"}
        ]
      })
      |> FlowTester.send(button_label: "Sometimes")
      |> contact_matches(%{"professional_support" => "sometimes"})
      |> (fn step ->
            [msg] = step.messages
            assert String.contains?(msg.text, "🏥 Employment information 3/3")
            assert String.contains?(msg.text, "➡️ Basic information 0/4")
            assert String.contains?(msg.text, "⬜ Personal information 0/4")
            assert String.contains?(msg.text, "⬜ Daily life 0/5")
            step
          end).()
      |> receive_message(%{
        text: "Thanks for sharing!\r\n\r\nNow is your chance to tell me more about yourself" <> _,
        buttons: button_labels(["Sure, let's go ➡️", "Why?"])
      })
      |> FlowTester.send(button_label: "Sure, let's go ➡️")
      |> Helpers.handle_basic_profile_flow()
      |> (fn step ->
            [msg] = step.messages
            assert String.contains?(msg.text, "🏥 Employment information 3/3")
            assert String.contains?(msg.text, "👤 Basic information 3/4")
            assert String.contains?(msg.text, "➡️ Personal information 0/4")
            assert String.contains?(msg.text, "⬜ Daily life 0/5")
            step
          end).()
      |> receive_message(%{
        text: "Your profile is already 50% complete!" <> _,
        buttons: button_labels(["Let's go"])
      })
      |> FlowTester.send(button_label: "Let's go")
      |> Helpers.handle_personal_info_flow(
        relationship_status: "single",
        education: "degree",
        socio_economic: "i get by",
        other_children: "0"
      )
      |> (fn step ->
            [msg] = step.messages
            assert String.contains?(msg.text, "🏥 Employment information 3/3")
            assert String.contains?(msg.text, "👤 Basic information 3/4")
            assert String.contains?(msg.text, "🗝️ Personal information 4/4")
            assert String.contains?(msg.text, "➡️ Daily life 0/5")
            step
          end).()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩⬜⬜\r\n" <> _,
        buttons: button_labels(["➡️ Complete it!", "Remind me later"])
      })
      |> FlowTester.send(button_label: "➡️ Complete it!")
      |> Helpers.handle_daily_life_flow()
      |> (fn step ->
            [msg] = step.messages
            assert String.contains?(msg.text, "🏥 Employment information 3/3")
            assert String.contains?(msg.text, "👤 Basic information 3/4")
            assert String.contains?(msg.text, "🗝️ Personal information 4/4")
            assert String.contains?(msg.text, "☀️ Daily life 1/5")
            step
          end).()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end
  end
end
