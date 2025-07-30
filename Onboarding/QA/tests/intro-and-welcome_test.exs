defmodule IntroAndWelcomeTest do
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
    index = %Index{title: "Onboarding", slug: "test"}
    assert :ok = FakeCMS.add_pages(wh_pid, [index])

    # Error messages are in a separate sheet.
    assert :ok = Helpers.import_content_csv(wh_pid, "error-messages", existing_pages: [index])

    # The content for these tests.
    assert :ok = Helpers.import_content_csv(
                   wh_pid,
                   "intro-and-welcome",
                   existing_pages: [index],
                   field_transform: fn s ->
                     s
                     |> String.replace(~r/\r?\n$/, "")
                     |> String.replace("{language_selection}", "{language selection}")
                     |> String.replace("{option_choice}", "{option choice}")
                   end
                 )

    assert :ok = FakeCMS.add_document(wh_pid, %Document{id: 1, title: "Privacy Policy"})

    # Docs aren't included in the imports, so we need to attach this one manually.
    assert :ok = FakeCMS.add_doc_to_page(wh_pid, "mnch_onboarding_pp_document", 0, 1)

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("intro-and-welcome")}

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

  describe "Intro and Welcome" do
    test "Branch: Opt in", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"privacy_policy_accepted" => "yes", "opted_in" => false})
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
    end

    test "Branch: User intent", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"privacy_policy_accepted" => "yes", "opted_in" => true})
      |> FlowTester.start()
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
    end

    test "Branch: Privacy Policy", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"privacy_policy_accepted" => "no", "opted_in" => false})
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"]),
        document: "media.fake.url/Privacy-Policy.pdf"
      })
    end

    test "Welcome message then change my language", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
    end

    test "Welcome message then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Get started", "Change my language"])
      })
    end

    test "Welcome message then continue with current set language", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"language" => "pt"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "pt"})
    end

    test "Welcome message then continue with default language", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
    end

    test "Change my language then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
    end

    test "Change my language then English", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[0]")
      # |> FlowTester.send(button_label: "English")
      |> receive_message(%{
        text: "Your language has been updated to English.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "eng"})
    end

    test "Change my language then French", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[1]")
      |> receive_message(%{
        text: "Your language has been updated to Français.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "fra"})
    end

    test "Change my language then Português", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[2]")
      |> receive_message(%{
        text: "Your language has been updated to Português.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "por"})
    end

    test "Change my language then Arabic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[3]")
      |> receive_message(%{
        text: "Your language has been updated to عربي.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "ara"})
    end

    test "Change my language then Spanish", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[4]")
      |> receive_message(%{
        text: "Your language has been updated to Español.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "spa"})
    end

    test "Change my language then Chinese", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[5]")
      |> receive_message(%{
        text: "Your language has been updated to 中国人.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "zho"})
    end

    test "Language confirmation then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[0]")
      |> receive_message(%{
        text: "Your language has been updated to English.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
    end

    test "Language confirmation then welcome", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list: {"Languages", list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[0]")
      |> receive_message(%{
        text: "Your language has been updated to English.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Ok, thanks")
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
    end

    test "Privacy policy then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => ""})
    end

    test "Privacy policy then yes", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
    end

    test "Privacy policy then no", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "No, I don’t accept")
      |> receive_message(%{
        text: "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
    end

    test "Privacy policy then no then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "No, I don’t accept")
      |> receive_message(%{
        text: "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["See privacy policy", "Another button needed here"])
      })
    end

    test "Privacy policy then no then see policy", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "No, I don’t accept")
      |> receive_message(%{
        text: "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
      |> FlowTester.send(button_label: "See privacy policy")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      # TODO: Add a test to see that the scheduled stack has been scheduled
    end

    test "Privacy policy then read a summary", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text: "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
    end

    test "Privacy policy then read a summary then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text: "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "No"])
      })
    end

    test "Privacy policy then read a summary then yes", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text: "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
    end

    test "Privacy policy then read a summary then no", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text: "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text: "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
    end

    test "Opt in then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
    end

    test "Opt in accepted", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
    end

    test "Opt in declined", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Decide later")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "false"})
    end

    test "User intent error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
    end

    test "User intent create profile", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Create a profile 👤")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "create profile"})
    end

    test "User intent explore", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
    end

    test "User intent speak to agent", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Go to help desk")
      |> contact_matches(%{"intent" => "get health advice"})
      |> Helpers.handle_non_personalised_menu_flow()
      |> flow_finished()
    end

    test "Data preferences then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send("Falalalalaaaa")
      |> contact_matches(%{"data_preference" => ""})
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
    end

    test "Data preferences all then data preference selected", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{
        text: "Got it 👍🏽\r\n\r\nI'll share all for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preferences text and images then data preference selected", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "Text & images")
      |> contact_matches(%{"data_preference" => "text and images"})
      |> receive_message(%{
        text: "Got it 👍🏽\r\n\r\nI'll share text and images for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preferences text only then data preference selected", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "Text only")
      |> contact_matches(%{"data_preference" => "text only"})
      |> receive_message(%{
        text: "Got it 👍🏽\r\n\r\nI'll share text only for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preference selected then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{
        text: "Got it 👍🏽\r\n\r\nI'll share all for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preference selected then create profile", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Create a profile 👤")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "create profile"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{
        text: "Got it 👍🏽\r\n\r\nI'll share all for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
      |> FlowTester.send(button_label: "That's great!")
      |> Helpers.handle_profile_classifier_flow()
      |> flow_finished()
    end

    test "Data preference selected then explore", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text: "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text: "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text: "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text: "You can *choose* how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{
        text: "Got it 👍🏽\r\n\r\nI'll share all for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
      |> FlowTester.send(button_label: "That's great!")
      |> Helpers.handle_explore_flow()
      |> flow_finished()
    end
  end
end
