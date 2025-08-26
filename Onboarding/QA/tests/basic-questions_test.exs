defmodule BasicQuestionsTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.Message.TextTransform

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The various index pages aren't in the content sheet, so we need to add them manually.
    indices = [
      # %Index{title: "Help centre", slug: "help-centre-index"},
      %Index{title: "Onboarding", slug: "onboarding-index"}
    ]

    assert :ok = FakeCMS.add_pages(wh_pid, indices)

    # These options are common to all CSV imports below.
    import_opts = [
      existing_pages: indices,
      field_transform: fn s ->
        s
        |> String.replace(~r/\r?\n$/, "")
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
    assert :ok =
             Helpers.import_content_csv(
               wh_pid,
               "onboarding",
               import_opts
             )

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("basic-questions")}

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

  describe "Basic questions" do
    test "correct YoB", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> contact_matches(%{"year_of_birth" => "1988"})
    end

    test "skip age question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> contact_matches(%{"year_of_birth" => ""})
    end

    test "validate YoB less than now", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("8001")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is a number", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("2blue")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is 4 digits", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("41945")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is greater than min", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1850")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    test "validate YoB is not a string", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("blue")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
    end

    @tag :testyob
    test "YoB error then province", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("blue")
      |> contact_matches(%{"year_of_birth" => ""})
      |> receive_message(%{
        text:
          "Sorry, I didn’t get that – let's try again.\r\n\r\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      })
      |> FlowTester.send("1988")
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> contact_matches(%{"year_of_birth" => "1988"})
    end

    test "Province then why", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("Why do you ask?")
      |> receive_message(%{
        text:
          "Knowing your province helps me find you relevant services when you need them.\r\n\r\n👤 *So, which province do you live in?*",
        # text: "I don't understand your reply. Please try that again. \r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Province", []}
      })
      |> contact_matches(%{"province" => ""})
    end

    test "Province then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> contact_matches(%{"province" => ""})
    end

    test "skip province question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => ""})
    end

    test "Province then area", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
    end

    test "Area then error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
    end

    test "skip area question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send("skip")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => ""})
    end

    test "Area (Urban) then gender", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        # text: "I don't understand your reply. Please try that again. \r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Big town/City")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "big town / city"})
    end

    test "Area (Rural) then gender", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
    end

    test "Gender already set -> end of flow", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"gender" => "female"})
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
        # list: {"Province", [{"{province_name_01}", "{province_name_01}"}, {"{province_name_02}", "{province_name_02}"}, {"{province_name_03}", "{province_name_03}"}, {"{province_name_04}", "{province_name_04}"}, {"{province_name_05}", "{province_name_05}"}, {"{province_name_06}", "{province_name_06}"}, {"{province_name_07}", "{province_name_07}"}, {"Why do you ask?", "Why do you ask?"}]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> flow_finished()
    end

    test "Gender to gender error", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text:
          "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "Skip gender question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send("skip")
      |> contact_matches(%{"gender" => ""})
      |> flow_finished()
    end

    test "Gender Male", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send(button_label: "Male")
      |> contact_matches(%{"gender" => "male"})
      |> flow_finished()
    end

    test "Gender Female", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send(button_label: "Female")
      |> contact_matches(%{"gender" => "female"})
      |> flow_finished()
    end

    test "Gender Other", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *What year were you born in?*"
      })
      |> FlowTester.send("1988")
      |> contact_matches(%{"year_of_birth" => "1988"})
      |> receive_message(%{
        text: "👤 *Which province do you call home?*",
        list:
          {"Province",
           [
             {"{province_name_01}", "{province_name_01}"},
             {"{province_name_02}", "{province_name_02}"},
             {"{province_name_03}", "{province_name_03}"},
             {"{province_name_04}", "{province_name_04}"},
             {"{province_name_05}", "{province_name_05}"},
             {"{province_name_06}", "{province_name_06}"},
             {"{province_name_07}", "{province_name_07}"},
             {"Why do you ask?", "Why do you ask?"}
           ]}
      })
      |> FlowTester.send("{province_name_01}")
      |> receive_message(%{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        buttons: button_labels(["Big town/City", "Countryside/Village"])
      })
      |> contact_matches(%{"province" => "{province_name_01}"})
      |> FlowTester.send(button_label: "Countryside/Village")
      |> receive_message(%{
        text: "👤 *What gender do you identify as?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> contact_matches(%{"area_type" => "countryside / village"})
      |> FlowTester.send(button_label: "Other")
      |> contact_matches(%{"gender" => "other"})
      |> flow_finished()
    end
  end
end
