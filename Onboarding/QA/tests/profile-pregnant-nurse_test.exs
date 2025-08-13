defmodule ProfilePregnantNurseTest do
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

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("profile-pregnant-nurse")}

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

  defp init_pregnancy_info(context) do
    context |> FlowTester.set_contact_properties(%{"pregnancy_status" => "im_pregnant", "edd" => "24/04/2026", "pregnancy_sentiment" => "excited"})
  end

  describe "profile pregnant nurse" do
    test "100% complete", %{flow: flow} do
      flow
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
