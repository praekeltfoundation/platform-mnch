defmodule ProfileGenericTest do
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

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("profile-generic")}

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

  describe "profile generic" do
    test "30% complete", %{flow: flow} do
      flow
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

    test "30% complete -> why -> let's go", %{flow: flow} do
      flow
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

    test "30% complete -> why -> not right now", %{flow: flow} do
      flow
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

    test "100% complete - all complete", %{flow: flow} do
      flow
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

    test "100% complete - incomplete basic info", %{flow: flow} do
      flow
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
