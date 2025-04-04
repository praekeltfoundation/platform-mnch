defmodule ExploringTourTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add an image.
    image = %Image{id: 1, title: "Test image", download_url: "https://example.org/image.jpeg"}
    assert :ok = FakeCMS.add_images(wh_pid, [image])

    # The index page isn't in the content sheet, so we need to add it manually.
    index = %Index{title: "Onboarding", slug: "test"}
    assert :ok = FakeCMS.add_pages(wh_pid, [index])

    # Error messages are in a separate sheet.
    assert :ok = Helpers.import_content_csv(wh_pid, "error-messages", existing_pages: [index])

    # The content for these tests.
    assert :ok = Helpers.import_content_csv(
                   wh_pid,
                   "exploring-tour",
                   existing_pages: [index],
                   field_transform: fn s ->
                     s
                     |> String.replace(~r/\r?\n$/, "")
                   end
                 )
    # Some other pages also have an image attachment.
    [
      "mnch_onboarding_tour_card_01",
      "mnch_onboarding_tour_card_02",
      "mnch_onboarding_tour_card_03",
      "mnch_onboarding_tour_card_04",
      "mnch_onboarding_tour_card_05",
    ]
    |> Enum.each(&FakeCMS.add_img_to_page(wh_pid, &1, 0, image.id))

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("exploring-tour")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
    %{flow: flow}
  end

  setup [:setup_flow]

  describe "Exploring Tour" do
    test "card 1", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> results_match([
        %{name: "guided_tour_started", value: "yes"},
      ])
      |> receive_message(%{
        text: "Great, let's talk about what {MyHealth} has to offer you.\r\n\r\n🟩⬜⬜⬜⬜\r\n\r\n*Information from the experts*\r\n\r\n24/7 access to health information right here on WhatsApp.",
        buttons: button_labels(["Next"]),
      })
    end

    test "card 2", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜\r\n\r\n*Important reminders*\r\n\r\nHealth-related reminders, specific to you, when you need them.",
        buttons: button_labels(["Next"]),
      })
    end

    test "card 3", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{
        text: "🟩🟩🟩⬜⬜\r\n\r\n*Help in a hurry*\r\n\r\nContact numbers and resources for emergencies.",
        buttons: button_labels(["Next"]),
      })
    end

    test "card 4", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜\r\n\r\n*Someone to talk to*\r\n\r\nExperts ready to help you with your health concerns.",
        buttons: button_labels(["Next"]),
      })
    end

    test "card 5", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> results_match([
        %{name: "guided_tour_started", value: "yes"},
        %{name: "guided_tour_completed", value: "yes"},
      ])
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩\r\n\r\n*Progress tracking*\r\n\r\nWhether it's your stress levels or pregnancy, I'll keep track of things.",
        buttons: button_labels(["Got it!"]),
      })
    end

    test "Guided tour menu", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Got it!")
      |> results_match([
        %{name: "guided_tour_started", value: "yes"},
        %{name: "guided_tour_completed", value: "yes"},
        %{name: "guided_tour_menu", value: "yes"},
      ])
      |> receive_message(%{
        text: "I hope you've now got a good idea of what {service name} can do.\r\n\r\nAt this point, most people choose to create their profile. The more info you give me, the more control you have!\r\n\r\n👇🏽 What do you want to do?",
        buttons: button_labels(["Create a profile 👤", "Go to help desk"]),
      })
    end

    test "Go to help desk", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Next")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Got it!")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Go to help desk")
      |> Helpers.handle_non_personalised_menu_flow()
      |> flow_finished()
    end
  end
end
