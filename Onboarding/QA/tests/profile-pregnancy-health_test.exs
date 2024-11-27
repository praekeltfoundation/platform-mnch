defmodule ProfilePregnancyHealthTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.FlowStep
  alias FlowTester.Message.TextTransform

  alias Onboarding.QA.Helpers
  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS

    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add an image.
    image = %Image{id: 1, title: "Test image", download_url: "https://example.org/image.jpeg"}
    assert :ok = FakeCMS.add_images(wh_pid, [image])

    # The various index pages aren't in the content sheet, so we need to add them manually.
    indices = [
      %Index{title: "Onboarding", slug: "test-onboarding"},
      %Index{title: "Sentiment", slug: "test-sentiment"},
      %Index{title: "Facts", slug: "test-facts"},
    ]
    assert :ok = FakeCMS.add_pages(wh_pid, indices)

    # Error messages are in a separate sheet.
    assert :ok = Helpers.import_content_csv(wh_pid, "error-messages", existing_pages: indices)

    # These options are common to all CSV imports below.
    import_opts = [
      existing_pages: indices,
      field_transform: fn s ->
        s
        |> String.replace(~r/\r?\n$/, "")
        |> String.replace("{username}", "{@username}")
      end
    ]

    # The content for these tests.
    assert :ok = Helpers.import_content_csv(wh_pid, "profile-pregnancy-health", import_opts)

    # Some content is in the variations sheet, apparently. Also, all of these
    # pages have an image attachment.
    var_pages = Helpers.pages_from_content_csv("variations", import_opts)
    assert :ok = FakeCMS.add_pages(wh_pid, var_pages)

    var_pages
    |> Enum.each(&FakeCMS.add_img_to_page(wh_pid, &1.slug, 0, image.id))

    # Some other pages also have an image attachment.
    [
      "mnch_onboarding_loading_01",
      "mnch_onboarding_loading_02",
      "mnch_onboarding_loading_01_secondary",
      "mnch_onboarding_loading_02_secondary",
      "mnch_onboarding_loading_component_01",
      "mnch_onboarding_loading_component_02",
      "mnch_onboarding_topics_01",
      "mnch_onboarding_content_intro",
      "mnch_onboarding_curious_content_intro",
      "mnch_onboarding_profile_progress_25_secondary_"
    ]
    |> Enum.each(&FakeCMS.add_img_to_page(wh_pid, &1, 0, image.id))

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("profile-pregnancy-health")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
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

  defp init_pregnancy_info(context) do
    context |> FlowTester.set_contact_properties(%{"pregnancy_status" => "im_pregnant", "edd" => "24/04/2026", "pregnancy_sentiment" => "excited"})
  end

  defp init_contact_fields(context) do
    context |> FlowTester.set_contact_properties(%{"gender" => "", "name" => "Lily", "opted_in" => "true"})
  end

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

    edd_confirmation_text = "Thank you! Just confirming your estimated due date 🗓️\r\n\r\nAre you expecting the baby on *#{selected_edd_day} #{Enum.at(month_words, selected_edd_month)} #{Calendar.strftime(Enum.at(months, selected_edd_month), "%Y")}*?"

    edd_month = String.pad_leading("#{Enum.at(months, selected_edd_month).month}", 2, "0")
    full_edd = Calendar.strftime(Enum.at(months, selected_edd_month), "%Y") <> "-" <> "#{edd_month}" <> "-#{selected_edd_day}"

    {list_of_months, edd_confirmation_text, full_edd}
  end

  defp go_to_edd_month(context, pregnancy_status \\ "I'm pregnant") do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: pregnancy_status)
      |> FlowStep.clear_messages()
  end

  defp go_to_edd_day(context, month, pregnancy_status \\ "I'm pregnant") do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: pregnancy_status)
      |> FlowTester.send(month)
      |> FlowStep.clear_messages()
  end

  defp go_to_edd_confirm(context, month, pregnancy_status \\ "I'm pregnant") do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: pregnancy_status)
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowStep.clear_messages()
  end

  defp go_to_gender(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowStep.clear_messages()
  end

  defp go_to_feelings(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowStep.clear_messages()
  end

  defp go_to_loading_1(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowStep.clear_messages()
  end

  defp go_to_loading_1_partner(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send(button_label: "Female")
      |> FlowStep.clear_messages()
  end

  defp go_to_loading_1_partner_no_edd(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send(button_label: "I'll do it later")
      |> FlowTester.send(button_label: "Female")
      |> FlowStep.clear_messages()
  end

  defp go_to_loading_2_partner(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send(button_label: "I'll do it later")
      |> FlowTester.send(button_label: "Female")
      |> FlowTester.send(button_label: "Okay")
      |> FlowStep.clear_messages()
  end

  defp go_to_factoid_1(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowStep.clear_messages()
  end

  defp go_to_factoid_1_partner(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send(button_label: "Female")
      |> FlowTester.send(button_label: "Okay")
      |> FlowStep.clear_messages()
  end

  defp go_to_factoid_2(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowStep.clear_messages()
  end

  defp go_to_topics(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowStep.clear_messages()
  end

  defp go_to_content_intro_partner(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send(button_label: "Female")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowStep.clear_messages()
  end

  defp go_to_dummy_topic(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send("item 1")
      |> FlowStep.clear_messages()
  end

  defp go_to_rate_this_article(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send("item 1")
      |> FlowTester.send(button_label: "Rate this article")
      |> FlowStep.clear_messages()
  end

  defp go_to_more_info(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send("item 1")
      |> FlowTester.send(button_label: "Rate this article")
      |> FlowTester.send(button_label: "Not really")
      |> FlowStep.clear_messages()
  end

  defp go_to_25_percent(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send("item 1")
      |> FlowTester.send(button_label: "Complete Profile")
      |> FlowStep.clear_messages()
  end

  defp go_to_50_percent(context, month) do
    context
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> FlowTester.send(button_label: "I'm pregnant")
      |> FlowTester.send(month)
      |> FlowTester.send("25")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> FlowTester.send("Other")
      |> FlowTester.send(button_label: "Let's check it out")
      |> FlowTester.send(button_label: "Okay")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send(button_label: "Awesome")
      |> FlowTester.send("item 1")
      |> FlowTester.send(button_label: "Complete Profile")
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
      |> FlowStep.clear_messages()
  end

  describe "checkpoints" do
    test "pregnant mom 0%", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "pregnant mom 25%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "25%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "pregnant mom 50%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "50%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "pregnant mom 100%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "100%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "partner pregnant 0%", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "0%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*",
        list: {"Month", ^list_of_months}
      })
    end

    test "partner pregnant 25%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "25%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "partner pregnant 50%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "50%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "partner pregnant 100%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "100%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "curious 0%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "0%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "curious 25%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "25%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "curious 50%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "50%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "curious 100%", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "100%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "pregnancy_basic_info", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnancy_basic_info", "profile_completion" => ""})
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "pregnancy_personal_info", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnancy_personal_info", "profile_completion" => ""})
      |> FlowTester.start()
      |> Helpers.handle_personal_info_flow(relationship_status: "single", education: "degree", socio_economic: "i get by", other_children: "0")
      |> Helpers.handle_daily_life_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "pregnancy_daily_life_info", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnancy_daily_life_info", "profile_completion" => ""})
      |> FlowTester.start()
      |> Helpers.handle_daily_life_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "default", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "", "profile_completion" => ""})
      |> FlowTester.start()
      |> receive_message(%{
        text: "I've got a *lot* of information on pregnancy" <> _,
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
      |> contact_matches(%{"checkpoint" => "basic_pregnancy_profile"})
    end
  end

  describe "profile pregnancy health - pregnant" do
    test "question 1 error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{
        text: "I've got a *lot* of information on pregnancy! 💡\r\n\r\nTake 2 minutes to answer a few questions so I can find the right info for you.\r\n\r\nIf there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Why are you interested in pregnancy info?*",
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
    end

    test "question 1 - i'm pregnant", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> go_to_edd_month()
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then edd day", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 2), 0)

      flow
      |> go_to_edd_month()
      |> FlowTester.send(month)
      |> receive_message(%{
        text: "👤 *On what day of the month are you expecting the baby to be born?*\r\n\r\nType in a number between 1 and 31."
      })
    end

    test "edd month to edd month unknown", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month()
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are two ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the first day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update your expected due date at any time in `Settings`",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "edd month unknown error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month()
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "edd month unknown update", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month()
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Update due date")
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month edd month unknown later", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month()
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      # TODO: Add this test when we have a way to test for scheduling stacks
      #|> Helpers.handle_edd_reminder_flow()
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "edd day then confirm", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month)
      |> FlowTester.send("25")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd day then not number error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month)
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
    end

    test "edd day then not a day error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month)
      |> FlowTester.send("0")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
    end

    test "edd day then above max day error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month)
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
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
      |> go_to_edd_day(month)
      |> FlowTester.send("29")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then feb 30 is not valid", %{flow: flow} do
      fake_time = ~U[2023-02-28 00:00:00Z]
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month)
      |> FlowTester.send("30")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 29."
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then long month 31 is valid", %{flow: flow} do
      fake_time = ~U[2023-01-01 00:00:00Z] # January
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 31, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month)
      |> FlowTester.send("31")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then long month 32 is invalid", %{flow: flow} do
      fake_time = ~U[2024-01-01 00:00:00Z] # January
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month)
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then short month 30 is valid", %{flow: flow} do
      fake_time = ~U[2024-04-01 00:00:00Z] # April
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 30, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month)
      |> FlowTester.send("30")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then short month 31 is invalid", %{flow: flow} do
      fake_time = ~U[2024-04-01 00:00:00Z] # April
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month)
      |> FlowTester.send("31")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 30."
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd confirm then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_confirm(month)
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd confirm then pick another date", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_confirm(month)
      |> FlowTester.send(button_label: "Pick another date")
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd confirm then that's right", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_confirm(month)
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{
        text: "Thank you!\r\n\r\n👤 *How are you feeling about this pregnancy?*",
        list: {"I'm feeling", [{"Excited", "Excited"}, {"Happy", "Happy"}, {"Worried", "Worried"}, {"Scared", "Scared"}, {"Other", "Other"}]}
      })
    end

    test "feelings then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"I'm feeling", [{"Excited", "Excited"}, {"Happy", "Happy"}, {"Worried", "Worried"}, {"Scared", "Scared"}, {"Other", "Other"}]}
      })
    end

    test "feelings then scared 1st trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant – it’s a big life change*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then scared 1st trimester (text only)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant – it’s a big life change*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then scared 2nd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then scared 2nd trimester (text only)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then scared 3rd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s normal to feel this way about a pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then scared 3rd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s normal to feel this way about a pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then excited 1st trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations on your pregnancy*🤰🏾\r\n\r\nEven if you can't see your baby bump yet, there's a lot going on!\r\n\r\nYour baby is growing quickly and doing amazing things like developing a brain, heart, facial features, and even tiny feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 There's so much to look forward to!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then excited 1st trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations on your pregnancy*🤰🏾\r\n\r\nEven if you can't see your baby bump yet, there's a lot going on!\r\n\r\nYour baby is growing quickly and doing amazing things like developing a brain, heart, facial features, and even tiny feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 There's so much to look forward to!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then excited 2nd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 2nd trimester*🤰🏾\r\n\r\nInside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then excited 2nd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 2nd trimester*🤰🏾\r\n\r\nInside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then excited 3rd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!" <> _,
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then excited 3rd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!" <> _,
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then other 1st trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then other 1st trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then other 2nd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then other 2nd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then other 3rd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then other 3rd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "excited 1st trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "excited 2nd trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "exited 3rd trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "scared 1st trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "scared 2nd trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "scared 3rd trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "other 1st trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "other 2nd trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "other 3rd trimester then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "excited 1st trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "excited 1st trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "excited 2nd trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "excited 2nd trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "excited 3rd trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "excited 3rd trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "scared 1st trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "scared 1st trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "scared 2nd trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "scared 2nd trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "scared 3rd trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "scared 3rd trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "other 1st trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "other 1st trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "other 2nd trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "other 2nd trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "other 3rd trimester then loading 1 (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "other 3rd trimester then loading 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_feelings(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "loading 1 then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_loading_1(month)
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Okay"])
      })
    end

    test "loading 1 then factoid 1 1st trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_loading_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "loading 1 then factoid 1 1st trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_loading_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "loading 1 then factoid 1 2nd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_loading_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "loading 1 then factoid 1 2nd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_loading_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "loading 1 then factoid 1 3rd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> go_to_loading_1(month)
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!" <> _,
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "loading 1 then factoid 1 3rd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_loading_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!" <> _,
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 1 then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 1 then factoid 2 1st trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "factoid 1 then factoid 2 1st trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 1 then factoid 2 2nd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "factoid 1 then factoid 2 2nd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 1 then factoid 2 3rd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰" <> _,
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "factoid 1 then factoid 2 3rd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_1(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰" <> _,
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 2 then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 2 then topics 1st trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
      }])
    end

    test "factoid 2 then topics 1st trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "factoid 2 then topics 2nd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
      }])
    end

    test "factoid 2 then topics 2nd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "factoid 2 then topics 3rd trimester (all)", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 1)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
      }])
    end

    test "factoid 2 then topics 3rd trimester", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 1)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_2(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "topics then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_topics(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "topics then dummy topic", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_topics(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("item 1")
      |> receive_message(%{
        text: "TODO: Get the article content and display it here" <> _,
        buttons: [{"Complete Profile", "Complete Profile"}, {"Rate this article", "Rate this article"}, {"Choose another topic", "Choose another topic"}]
      })
    end

    test "dummy topic then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_dummy_topic(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: [{"Complete Profile", "Complete Profile"}, {"Rate this article", "Rate this article"}, {"Choose another topic", "Choose another topic"}]
      })
    end

    test "dummy topic then choose another topic", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_dummy_topic(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Choose another topic")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "dummy topic then rate this article", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_dummy_topic(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_rate_this_article(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then yes", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_rate_this_article(month)
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "rate this article then not really", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_rate_this_article(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{
        text: "Mmm maybe I need a bit more information about you...🤔\r\n\r\nWould you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
    end

    test "Not really then yes sure", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_more_info(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Yes, sure")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
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
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "not really then maybe later", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_more_info(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Maybe later")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "not really then no thanks", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_more_info(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "No thanks")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "dummy topic then complete profile", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_dummy_topic(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Complete Profile")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "25% then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_25_percent(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "25% complete then view topics", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_25_percent(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "View topics for you")
      |> receive_message(%{
        text: "TODO",
      })
      |> flow_finished()
    end

    test "25% complete then explore health guide", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_25_percent(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "Explore health guide")
      |> receive_message(%{
        text: "TODO",
      })
      |> flow_finished()
    end

    test "25% complete then complete profile", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_25_percent(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
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
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "50% complete then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_50_percent(month)
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Continue"])
      })
    end

    test "100% complete", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      flow
      |> go_to_50_percent(month)
      |> FlowTester.send(button_label: "Continue")
      |> Helpers.handle_personal_info_flow(relationship_status: "", education: "", socio_economic: "", other_children: "")
      |> Helpers.handle_daily_life_flow()
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

  describe "profile pregnancy health - partner pregnant" do
    test "question 1 - partner is pregnant", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> contact_matches(%{"gender" => "", "pregnancy_status" => "partner_pregnant", "checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      flow
      |> go_to_edd_month("Partner is pregnant")
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then edd day", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 2), 0)

      flow
      |> go_to_edd_month("Partner is pregnant")
      |> FlowTester.send(month)
      |> receive_message(%{
        text: "👤 *On what day of the month are you expecting the baby to be born?*\r\n\r\nType in a number between 1 and 31."
      })
    end

    test "edd month to edd month unknown", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month("Partner is pregnant")
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are two ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the first day of your partner's last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nA health worker should confirm this expected due date at your partner's next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update your expected due date at any time in ‘Settings’ ⭐",
        buttons: button_labels(["Update due date", "I'll do it later"])
      })
    end

    test "edd month unknown error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month("Partner is pregnant")
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Update due date", "I'll do it later"])
      })
    end

    test "edd month unknown update", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month("Partner is pregnant")
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Update due date")
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month edd month unknown later", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      flow
      |> go_to_edd_month("Partner is pregnant")
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'll do it later")
      # TODO: Add this test when we have a way to test for scheduling stacks
      #|> Helpers.handle_edd_reminder_flow()
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "edd day then confirm", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("25")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd day then not number error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
    end

    test "edd day then not a day error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("0")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
    end

    test "edd day then above max day error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
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
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("29")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then feb 30 is not valid", %{flow: flow} do
      fake_time = ~U[2023-02-28 00:00:00Z]
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("30")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 29."
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then long month 31 is valid", %{flow: flow} do
      fake_time = ~U[2023-01-01 00:00:00Z] # January
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 31, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("31")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then long month 32 is invalid", %{flow: flow} do
      fake_time = ~U[2024-01-01 00:00:00Z] # January
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 31."
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then short month 30 is valid", %{flow: flow} do
      fake_time = ~U[2024-04-01 00:00:00Z] # April
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words, 30, 0)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("30")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd day then short month 31 is invalid", %{flow: flow} do
      fake_time = ~U[2024-04-01 00:00:00Z] # April
      months = get_months(fake_time)
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      flow
      |> FlowTester.set_fake_time(fake_time)
      |> go_to_edd_day(month, "Partner is pregnant")
      |> FlowTester.send("31")
      |> receive_message(%{
        text: "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a number between 1 and 30."
      })
      |> FlowTester.clear_fake_time()
    end

    test "edd confirm then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_confirm(month, "Partner is pregnant")
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd confirm then pick another date", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_confirm(month, "Partner is pregnant")
      |> FlowTester.send(button_label: "Pick another date")
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd confirm then that's right", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_edd_confirm(month, "Partner is pregnant")
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "gender then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_gender(month)
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "gender then male", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_gender(month)
      |> FlowTester.send(button_label: "Male")
      |> contact_matches(%{"gender" => "male"})
      |> receive_message(%{
        text: "Thanks, Lily!\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"])
      })
    end

    test "gender then female", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_gender(month)
      |> FlowTester.send(button_label: "Female")
      |> contact_matches(%{"gender" => "female"})
      |> receive_message(%{
        text: "Thanks, Lily!\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"])
      })
    end

    test "loading 1 then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_loading_1_partner(month)
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Okay"])
      })
    end

    test "loading 1 then loading 2 no edd", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1
      month = elem(Enum.at(list_of_months, last_month), 0)

      flow
      |> go_to_loading_1_partner_no_edd(month)
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "{interesting facts for stage of pregnancy, specifically tailored to partner}",
        buttons: button_labels(["Got it"])
      })
    end

    test "loading 2 then error no edd", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      month = elem(Enum.at(list_of_months, last_month), 0)

      flow
      |> go_to_loading_2_partner(month)
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Got it"])
      })
    end

    test "loading 2 then content intro no edd", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1
      month = elem(Enum.at(list_of_months, last_month), 0)

      flow
      |> go_to_loading_2_partner(month)
      |> FlowTester.send(button_label: "Got it")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "loading 1 then factoid 1", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_loading_1_partner(month)
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 1 then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_1_partner(month)
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 1 then factoid 2 then content intro", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_factoid_1_partner(month)
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "content intro then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_content_intro_partner(month)
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "content intro then article topic", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> go_to_content_intro_partner(month)
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
    end

    test "article topic then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
    end

    test "article topic then complete", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "article topic then choose another topic", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Choose another topic")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "article topic then rate this article", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then no", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{
        text: "Mmm maybe I need a bit more information about you...🤔\r\n\r\nWould you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
    end

    test "content feedback no then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
    end

    test "rate this article then yes opted in", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "rate this article then yes not opted in", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "*Be a big support to your partner!* 🔔\r\n\r\nCan we send you notifications with weekly information that will help you manage your family’s health?",
        buttons: button_labels(["Yes, sign me up", "Maybe later"])
      })
    end

    test "rate this article then yes not opted in then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "*Be a big support to your partner!* 🔔\r\n\r\nCan we send you notifications with weekly information that will help you manage your family’s health?",
        buttons: button_labels(["Yes, sign me up", "Maybe later"])
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sign me up", "Maybe later"])
      })
    end

    test "rate this article then yes not opted in then yes", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, sign me up")
      |> receive_messages([
        %{
          text: "Great decision, Lily!\r\n\r\nThese messages are a great way to stay up to date and informed about your baby on the way 💛",
        },
        %{
          text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
          buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
        }])
    end

    test "rate this article then yes not opted in then later", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Maybe later")
      |> receive_messages([
        %{
          text: "Thousands of people have signed up to receive these messages – they're the best way to stay in control 🙌🏾\r\n\r\nYou can always change your update choice in `Settings`",
        },
        %{
          text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
          buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
        }])
    end

    test "25% complete then error", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "25% complete then complete profile", %{flow: flow} do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_basic_profile_flow()
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
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end
    # We don't have to test the rest because we've already done it in the I'm pregnant section
  end

  describe "profile pregnancy health - curious" do
    test "i'm curious - question 1", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "i'm curious - question 1 then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "i'm curious - question 1 then error then male", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send(button_label: "Male")
      |> contact_matches(%{"gender" => "male"})
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 1 then male", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send(button_label: "Male")
      |> contact_matches(%{"gender" => "male"})
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 1 then female", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send(button_label: "Female")
      |> contact_matches(%{"gender" => "female"})
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 1 then other", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send(button_label: "Other")
      |> contact_matches(%{"gender" => "other"})
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then error then 0", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[0]")
      |> contact_matches(%{"other_children" => "0"})
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then 0", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[0]")
      |> contact_matches(%{"other_children" => "0"})
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then 1", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[1]")
      |> contact_matches(%{"other_children" => "1"})
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then 2", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[2]")
      |> contact_matches(%{"other_children" => "2"})
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then 3+", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[3]")
      |> contact_matches(%{"other_children" => "3+"})
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 2 then skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{
        text: "👤 *Tell me, do you have any children?*",
        list: {"Other children", [{"@menu_items[0]", "No other children"}, {"@menu_items[1]", "Yes, one"}, {"@menu_items[2]", "Yes, two"}, {"@menu_items[3]", "Yes, more than two"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[4]")
      |> contact_matches(%{"other_children" => "skip"})
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 3 then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
    end

    test "i'm curious - question 3 then error then loading", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[0]")
      |> result_matches(%{name: "pregnancy_stage_interest", value: "First trimester"})
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "i'm curious - question 3 then 1st", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> result_matches(%{name: "pregnancy_stage_interest", value: "First trimester"})
    end

    test "i'm curious - question 3 then 2nd", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> result_matches(%{name: "pregnancy_stage_interest", value: "Second trimester"})
    end

    test "i'm curious - question 3 then 3rd", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> result_matches(%{name: "pregnancy_stage_interest", value: "Third trimester"})
    end

    test "i'm curious - question 3 then general", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[3]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> result_matches(%{name: "pregnancy_stage_interest", value: "General pregnancy info"})
    end

    test "i'm curious - question 3 then general (text only)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[3]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
      |> result_matches(%{name: "pregnancy_stage_interest", value: "General pregnancy info"})
    end
    test "i'm curious - question 3 then skip", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "👤 *Which stage of pregnancy are you most interested in?*",
        list: {"Select option", [{"@menu_items[0]", "First trimester"}, {"@menu_items[1]", "Second trimester"}, {"@menu_items[2]", "Third trimester"}, {"@menu_items[3]", "General pregnancy info"}, {"@menu_items[4]", "Skip this question"}]}
      })
      |> FlowTester.send("@menu_items[4]")
      |> receive_message(%{
        text: "Mmm. Maybe I need a bit more information about you...🤔\r\n\r\n👇🏽 Would you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
      |> result_matches(%{name: "pregnancy_stage_interest", value: "Skip this question"})
    end

    test "i'm curious - loading 1 then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[3]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Okay"]),
      })
    end

    test "i'm curious - loading 1 then error then ok", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Okay"]),
      })
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 1 then ok (first trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 1 then ok then error (first trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 (first trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 then error (first trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 then error then awesome (first trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end

    test "i'm curious - loading 2 then awesome (first trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end

    test "i'm curious - loading 2 then awesome (first trimester, text only)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
          image: nil
        })
    end

    test "i'm curious - loading 1 then ok (second trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 1 then ok then error (second trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 (second trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 then error (second trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 then error then awesome (second trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end

    test "i'm curious - loading 2 then awesome (second trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end

    test "i'm curious - loading 2 then awesome (second trimester, text only)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
          image: nil
        })
    end

    test "i'm curious - loading 1 then ok (third trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{
        text: "Thanks Lily\r\n\r\nGive me a moment while I set up your profile and find the best information for you...⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 1 then ok then error (third trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 (third trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰🏽",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 then error (third trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰🏽",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
    end

    test "i'm curious - loading 2 then error then awesome (third trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"]),
      })
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end

    test "i'm curious - loading 2 then awesome (third trimester)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end

    test "i'm curious - loading 2 then awesome (third trimester, text only)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
          image: nil
        })
    end

    test "i'm curious - article topic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help you challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your mood swings are severe or interfering with your daily life, consider seeking help.\r\n5. *Stay Patient and Kind to Yourself*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
    end

    test "i'm curious - show other topics", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[4]")
      |> receive_message(%{
        text: "Mmm. Maybe I need a bit more information about you...🤔\r\n\r\n👇🏽 Would you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
    end

    test "i'm curious - article topic complete profile", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "i'm curious - article topic rate this article", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"]),
      })
    end

    test "i'm curious - article topic rate this article yes (opted in)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "true"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"]),
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "i'm curious - article topic rate this article yes (opted out)", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"]),
      })
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "i'm curious - article topic rate this article error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"]),
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "Not really"]),
      })
    end

    test "i'm curious - article topic rate this article no", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"]),
      })
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{
        text: "Mmm. Maybe I need a bit more information about you...🤔\r\n\r\n👇🏽 Would you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
    end

    test "i'm curious - article feedback error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
    end

    test "i'm curious - article feedback error then yes", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
      |> FlowTester.send(button_label: "Yes, sure")
      |> Helpers.handle_basic_profile_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nYour profile is already 50% complete! 🎉\r\n\r\n🤰🏽 Pregnancy info 3/3\r\n👤 Basic information 3/4\r\n➡️ Personal information 1/4\r\n⬜ Daily life 0/5\r\n\r\n👇🏾 Let’s move on to personal information.",
        buttons: button_labels(["Continue"])
      })
    end

    test "i'm curious - article feedback error then maybe", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
      |> FlowTester.send(button_label: "Maybe later")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "i'm curious - article feedback error then no", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sure", "Maybe later", "No thanks"])
      })
      |> FlowTester.send(button_label: "No thanks")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "i'm curious - article topic choose another topic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Just curious")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Other")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[1]")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[2]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Choose another topic")
      |> receive_messages([
        %{
          image: "https://example.org/image.jpeg"
        },
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list: {"Choose a topic", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")},
        }])
    end
  end
end
