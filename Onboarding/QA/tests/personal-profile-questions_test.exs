defmodule PersonalProfileQuestionsTest do
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

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("personal-profile-questions")}

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

  describe "Personal Profile questions" do
    test "relationship status error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> contact_matches(%{"relationship_status" => ""})
    end

    test "skip relationship status", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => ""})
    end

    test "relationship status then education", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
    end

    test "education error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"education" => ""})
    end

    test "skip education by typing", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => ""})
    end

    test "skip education by selection", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Skip this question")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => ""})
    end

    test "education then socio economic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
    end

    test "socio economic error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"socio_economic" => ""})
    end

    test "skip socio economic", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => ""})
    end

    test "socio economic then children", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send(button_label: "Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
    end

    test "children error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"other_children" => ""})
    end

    test "skip children", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("skip")
      |> contact_matches(%{"other_children" => ""})
      |> flow_finished()
    end

    test "children then why", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Skip this question", "Skip this question"}],}
      })
      |> contact_matches(%{"other_children" => ""})
    end

    test "children then why then skip by typing then finished", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Skip this question", "Skip this question"}],}
      })
      |> FlowTester.send("skip")
      |> contact_matches(%{"other_children" => ""})
      |> flow_finished()
    end

    test "children then why then skip by selection then finished", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text: "ℹ️ Children change our lives a lot! Our team of health experts works hard to find information and services that fit your needs.\r\n\r\n*How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Skip this question", "Skip this question"}],}
      })
      |> FlowTester.send("Skip this question")
      |> contact_matches(%{"other_children" => ""})
      |> flow_finished()
    end

    test "children then finished", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n🗝️ *What is your current relationship status?*",
        buttons: [{"Single", "Single"}, {"In a relationship", "In a relationship"}, {"It's complicated", "It's complicated"}],
      })
      |> FlowTester.send(button_label: "Single")
      |> receive_message(%{
        text: "🗝️ *What is your highest level of education?*",
        list: {"Education", [{"Primary school", "Primary school"}, {"High school", "High school"}, {"Diploma", "Diploma"}, {"Degree", "Degree"}, {"Master's degree", "Master's degree"}, {"Doctoral degree", "Doctoral degree"}, {"None", "None"}, {"Skip this question", "Skip this question"}]},
      })
      |> contact_matches(%{"relationship_status" => "single"})
      |> FlowTester.send("Diploma")
      |> receive_message(%{
        text: "🗝️ *How would you describe your personal finances when it comes to having enough money?*",
        buttons: [{"Comfortable", "Comfortable"}, {"I get by", "I get by"}, {"Money is an issue", "Money is an issue"}],
      })
      |> contact_matches(%{"education" => "diploma"})
      |> FlowTester.send("Comfortable")
      |> receive_message(%{
        text: "🗝️ *How many children do you have?*",
        list: {"Children", [{"None", "None"}, {1, "1"}, {2, "2"}, {3, "3"}, {"More than 3", "More than 3"}, {"Why do you ask?", "Why do you ask?"}],}
      })
      |> contact_matches(%{"socio_economic" => "comfortable"})
      |> FlowTester.send("1")
      |> contact_matches(%{"other_children" => "1"})
      |> flow_finished()
    end
  end
end
