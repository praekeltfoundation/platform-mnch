defmodule IntroAndWelcomeTest do
  use FlowTester.Case

  alias FlowTester.MultiFlow
  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.Message.TextTransform

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    doc_priv_pol = %Document{
      id: 1,
      title: "Test document",
      download_url:
        "https://content-repo-api-qa.prk-k8s.prd-p6t.org/documents/17/privacy_policy.pdf"
    }

    assert :ok =
             FakeCMS.add_documents(wh_pid, [
               doc_priv_pol
             ])

    # The index page isn't in the content sheet, so we need to add it manually.
    indices = [%Index{title: "Onboarding", slug: "test-onboarding"}]
    assert :ok = FakeCMS.add_pages(wh_pid, indices)

    # These options are common to all CSV imports below.
    import_opts = [
      existing_pages: indices,
      field_transform: fn s ->
        s
        # These transforms are common to all CSV imports
        |> String.replace(~r/\r?\n$/, "")
        |> String.replace("{username}", "{@username}")
        # TODO: Fix this in FakeCMS
        |> String.replace("\u200D", "")
        # These transforms are specific to these tests
        |> String.replace("{language_selection}", "{language selection}")
        |> String.replace("{option_choice}", "{option choice}")
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

    # Docs aren't included in the imports, so we need to attach this one manually.
    FakeCMS.add_doc_to_page(wh_pid, "mnch_onboarding_pp_document", 0, doc_priv_pol.id)

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  # defp real_or_fake_cms(step, base_url, _auth_token, :real),
  #   do: WH.allow_http(step, base_url)

  # defp real_or_fake_cms(step, base_url, auth_token, :fake),
  #   do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp setup_flow(flow, fakecms_wh, mf_pid) do
    flow = flow
      |> WH.set_adapter("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", fakecms_wh)
      |> FlowTester.add_message_text_transform(
        TextTransform.normalise_newlines(trim_trailing_spaces: true)
      )
      |> FlowTester.set_global_dict("config", %{"contentrepo_token" => "CRauthTOKEN123"})

    {:ok, flow_uuid} = MultiFlow.add_flow(mf_pid, flow)

    flow_uuid
  end

  defp setup_multi_flow(_ctx) do
    fakecms_wh = setup_fake_cms("CRauthTOKEN123")

    mf_pid = start_link_supervised!({MultiFlow, nil})
    init_flow_uuid = setup_flow(Helpers.load_flow("intro-and-welcome"), fakecms_wh, mf_pid)

    exploring_tour_flow_uuid =
      setup_flow(Helpers.load_flow("exploring-tour"), fakecms_wh, mf_pid)

    profile_classifier_flow_uuid =
      setup_flow(Helpers.load_flow("profile-classifier"), fakecms_wh, mf_pid)

    non_personalise_menu_uuid =
      setup_flow(Helpers.load_flow("menu-non-personalised"), fakecms_wh, mf_pid)

    %{
      init_flow_uuid: init_flow_uuid,
      mf_pid: mf_pid,
      init_flow: MultiFlow.get_flow(mf_pid, init_flow_uuid),
      exploring_tour_flow_uuid: exploring_tour_flow_uuid,
      exploring_tour_flow: MultiFlow.get_flow(mf_pid, exploring_tour_flow_uuid),
      profile_classifier_flow_uuid: profile_classifier_flow_uuid,
      profile_classifier_flow: MultiFlow.get_flow(mf_pid, profile_classifier_flow_uuid),
      non_personalise_menu_uuid: non_personalise_menu_uuid,
      non_personalise_menu: MultiFlow.get_flow(mf_pid, non_personalise_menu_uuid)
    }
  end

  setup [:setup_multi_flow]

  # defp setup_flow(ctx) do
  #   # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
  #   auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
  #   kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

  #   flow =
  #     ctx.init_flow
  #     |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
  #     |> FlowTester.add_message_text_transform(
  #       TextTransform.normalise_newlines(trim_trailing_spaces: true)
  #     )
  #     |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})

  #   %{init_flow: init_flow}
  # end

  # setup [:setup_flow]

  describe "Intro and Welcome" do
    test "Branch: Opt in", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{
        "privacy_policy_accepted" => "yes",
        "opted_in" => false
      })
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
    end

    test "Branch: User intent", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{
        "privacy_policy_accepted" => "yes",
        "opted_in" => true
      })
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
    end

    test "Branch: Privacy Policy", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{
        "privacy_policy_accepted" => "no",
        "opted_in" => false
      })
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"]),
        document:
          "https://content-repo-api-qa.prk-k8s.prd-p6t.org/documents/17/privacy_policy.pdf"
      })
    end

    test "Welcome message then change my language", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
    end

    test "Welcome message then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Get started", "Change my language"])
      })
    end

    test "Welcome message then continue with current set language", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"language" => "pt"})
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "pt"})
    end

    test "Welcome message then continue with default language", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
    end

    test "Change my language then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
    end

    test "Change my language then English", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[0]")
      # |> FlowTester.send(button_label: "English")
      |> receive_message(%{
        text: "Your language has been updated to English.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "eng"})
    end

    test "Change my language then French", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[1]")
      |> receive_message(%{
        text: "Your language has been updated to Français.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "fra"})
    end

    test "Change my language then Português", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[2]")
      |> receive_message(%{
        text: "Your language has been updated to Português.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "por"})
    end

    test "Change my language then Arabic", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[3]")
      |> receive_message(%{
        text: "Your language has been updated to عربي.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "ara"})
    end

    test "Change my language then Spanish", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[4]")
      |> receive_message(%{
        text: "Your language has been updated to Español.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "spa"})
    end

    test "Change my language then Chinese", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[5]")
      |> receive_message(%{
        text: "Your language has been updated to 中国人.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "zho"})
    end

    test "Language confirmation then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[0]")
      |> receive_message(%{
        text: "Your language has been updated to English.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
    end

    test "Language confirmation then welcome", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Change my language")
      |> receive_message(%{
        text: "*Which language would you prefer?*\r\n\r\n👇🏽 Choose from the list below.",
        list:
          {"Languages",
           list_items(["English", "Français", "Português", "عربي", "Español", "中国人"])}
      })
      |> FlowTester.send("@list_items[0]")
      |> receive_message(%{
        text: "Your language has been updated to English.",
        buttons: button_labels(["Ok, thanks", "Choose another one"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Ok, thanks")
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
    end

    test "Privacy policy then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => ""})
    end

    test "Privacy policy then yes", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
    end

    test "Privacy policy then no", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "No, I don’t accept")
      |> receive_message(%{
        text:
          "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
    end

    test "Privacy policy then no then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "No, I don’t accept")
      |> receive_message(%{
        text:
          "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["See privacy policy", "Another button needed here"])
      })
    end

    test "Privacy policy then no then see policy", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "No, I don’t accept")
      |> receive_message(%{
        text:
          "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
      |> FlowTester.send(button_label: "See privacy policy")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })

      # TODO: Add a test to see that the scheduled stack has been scheduled
    end

    test "Privacy policy then read a summary", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text:
          "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
    end

    test "Privacy policy then read a summary then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text:
          "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "No"])
      })
    end

    test "Privacy policy then read a summary then yes", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text:
          "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
    end

    test "Privacy policy then read a summary then no", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Read a summary")
      |> receive_message(%{
        text:
          "*What’s in the privacy policy*\r\n\r\n*Privacy*\r\nWe keep your personal information safe and private.\r\n\r\n*Terms and conditions*\r\nThis service gives you health information and self-help tools. It is not a replacement for advice from a real-life health worker or doctor, and professionals should still be relied upon for medical concerns.\r\n\r\n👇🏽 Do you accept the privacy policy?",
        buttons: button_labels(["Yes", "No"])
      })
      |> FlowTester.send(button_label: "No")
      |> receive_message(%{
        text:
          "In order to use {MyHealth}, you need to accept the privacy policy.\r\n\r\n👇🏾 What do you want to do?",
        buttons: button_labels(["See privacy policy"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "no"})
    end

    test "Opt in then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
    end

    test "Opt in accepted", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
    end

    test "Opt in declined", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Decide later")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "false"})
    end

    test "User intent error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
    end

    test "User intent create profile", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Create a profile 👤")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "create profile"})
    end

    test "User intent explore", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
    end

    test "User intent speak to agent", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{})
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{})
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{})
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Go to help desk")
      |> contact_matches(%{"intent" => "get health advice"})
      |> receive_message(%{
        text: "*{MyHealth} main menu*\r\n\r\nTap `≡ Menu` to make your choice.\r\n\r\n*Get health advice*\r\n👩🏽⚕️ Your health guide\r\n📚 View topics for you\r\n📞 Help centre\r\n\r\n*Settings*\r\n👤 Your profile (0%)\r\n🔔 Manage updates\r\n📱 Manage data\r\n\r\n*{MyHealth} Service*\r\n🚌 Take a tour\r\nℹ️ About and privacy policy\r\n\r\nTo return here at any time, send in the word `menu`",
        list: {"Menu",
           list_items(["Health Guide", "View Topics", "Go to Help Center", "Profile", "Manage Updates", "Manage Data", "Take a Tour", "About this Service"], "menu_items")}
      })
    end

    test "Data preferences then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send("Falalalalaaaa")
      |> contact_matches(%{"data_preference" => ""})
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
    end

    test "Data preferences all then data preference selected", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{
        text:
          "Got it 👍🏽\r\n\r\nI'll share all for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preferences text and images then data preference selected", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "Text & images")
      |> contact_matches(%{"data_preference" => "text and images"})
      |> receive_message(%{
        text:
          "Got it 👍🏽\r\n\r\nI'll share text and images for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preferences text only then data preference selected", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "Text only")
      |> contact_matches(%{"data_preference" => "text only"})
      |> receive_message(%{
        text:
          "Got it 👍🏽\r\n\r\nI'll share text only for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preference selected then error", %{init_flow: init_flow} do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "*Welcome to {MyHealth}*\r\n\r\nGet free healthcare support for you and those you care for.\r\n\r\nOn this chatbot, you'll find personalised info, advice, and reminders.\r\n\r\n👇🏽 Let’s get started!",
        buttons: button_labels(["Get started", "Change my language"])
      })
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{
        text:
          "*Your information is safe and won't be shared* 🔒\r\n\r\nThe information you share is only used to give you personalised advice and information.\r\n\r\nRead the privacy policy attached and let me know if you accept it.",
        buttons: button_labels(["Yes, I accept ✅", "No, I don’t accept", "Read a summary"])
      })
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{
        text:
          "*Sometimes I'll need to send you important messages – like appointment reminders or urgent health news* 🔔\r\n\r\nYou can choose which types messages you want to receive later from your profile. It’s also easy to stop messages at any time.\r\n\r\n👇🏽 Can I send you these messages?",
        buttons: button_labels(["Yes ✅", "Decide later"])
      })
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{
        text:
          "Let's create your profile! The better I know you, the more I can do for you.\r\n\r\n*You have a few options:*\r\n\r\n• Create your profile and take control of {MyHealth}\r\n\r\n• Explore the service\r\n\r\n• Get assistance from an expert at the help desk\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Explore the service", "Go to help desk"])
      })
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{
        text:
          "Before we get started, you can choose how to receive the information I have for you. This is so you can manage your data costs 📱\r\n\r\nYou can choose:\r\n\r\n• Text, images, audio & video (All)\r\n\r\n• Text and images\r\n\r\n• Text only\r\n\r\n👇🏽 What would you like?",
        buttons: button_labels(["All", "Text & images", "Text only"])
      })
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{
        text:
          "Got it 👍🏽\r\n\r\nI'll share all for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["That's great!"])
      })
    end

    test "Data preference selected then create profile", %{
      init_flow: init_flow
    } do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{})
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{})
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{})
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Create a profile 👤")
      |> receive_message(%{})
      |> contact_matches(%{"intent" => "create profile"})
      |> FlowTester.send(button_label: "All")
      |> contact_matches(%{"data_preference" => "all"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "That's great!")
      |> receive_message(%{
        text:
          "What would you like me to call you?\r\n\r\nIf you don't want to answer this right now, reply `Skip`"
      })
      |> contact_matches(%{"checkpoint" => "profile_classifier"})
      |> results_match(
        [
          %{name: "intro_completed", value: "yes"},
          %{name: "profile_classifier_started", value: "yes"}
        ]
      )
    end

    test "Data preference selected then explore", %{
      init_flow: init_flow
    } do
      init_flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Get started")
      |> receive_message(%{})
      |> contact_matches(%{"language" => "eng"})
      |> FlowTester.send(button_label: "Yes, I accept ✅")
      |> receive_message(%{})
      |> contact_matches(%{"privacy_policy_accepted" => "yes"})
      |> FlowTester.send(button_label: "Yes ✅")
      |> receive_message(%{})
      |> contact_matches(%{"opted_in" => "true"})
      |> FlowTester.send(button_label: "Explore the service")
      |> receive_message(%{})
      |> contact_matches(%{"intent" => "explore"})
      |> FlowTester.send(button_label: "Text only")
      |> contact_matches(%{"data_preference" => "text only"})
      |> receive_message(%{
        text:
          "Got it 👍🏽\r\n\r\nI'll share text only for now.\r\n\r\nYou can change this at any time in `Settings`",
        buttons: button_labels(["That's great!"])
      })
      |> FlowTester.send(button_label: "That's great!")
      |> results_match([
        %{name: "intro_completed", value: "yes"},
        %{name: "guided_tour_started", value: "yes"}
      ])
      # Explore init_flow
      # Card 1
      |> receive_message(%{
        text:
          "Great, let's talk about what {MyHealth} has to offer you.\r\n\r\n🟩⬜⬜⬜⬜\r\n\r\n*Information from the experts*\r\n\r\n24/7 access to health information right here on WhatsApp.",
        buttons: button_labels(["Next"])
      })
    end
  end
end
