defmodule MenuNonPersonalisedTest do
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

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("menu-non-personalised")}

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

  describe "Menu non personalised" do
    test "Go to help desk", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Go to Help Center")
      |> contact_matches(%{"topic" => "help_centre"})
      |> Helpers.handle_help_center_flow()
    end
  end
end
