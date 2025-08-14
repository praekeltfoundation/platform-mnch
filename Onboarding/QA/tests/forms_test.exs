defmodule FormsTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.Message.TextTransform

  alias Onboarding.QA.Helpers

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

    # The content for these tests.
    assert :ok = Helpers.import_content_csv(wh_pid, "onboarding", import_opts)

    assert :ok =
             FakeCMS.add_form(wh_pid, %Forms.Form{
               id: 1,
               title: "Test Form",
               slug: "dma-form",
               generic_error: "Please choose an option that matches your answer",
               locale: "en",
               version: "v1.0",
               tags: ["dma_form"],
               high_result_page: "mnch_onboarding_dma_results_high",
               high_inflection: 5.0,
               medium_result_page: "mnch_onboarding_dma_results_medium",
               medium_inflection: 3.0,
               low_result_page: "mnch_onboarding_dma_results_low",
               skip_threshold: 1.0,
               skip_high_result_page: "mnch_onboarding_dma_skip-result",
               questions: [
                 %Forms.IntegerQuestion{
                   question:
                     "Thanks, {{name}}\r\n\r\nNow please share your view on these statements so that you can get the best support from [MyHealth] for your needs.\r\n\r\nTo skip any question, reply: Skip\r\n\r\nHere’s the first statement:\r\n\r\n👤 *I am confident that I can do things to avoid health issues or reduce my symptoms.*",
                   explainer: "TEST: Explainer text",
                   error: "Oh no",
                   semantic_id: "forms-integer",
                   min: 0,
                   max: 10
                 }
               ]
             })

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("dma-form")}

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

  describe "DMA Form" do
    @tag skip: "TODO: Implement support for Template CSV import etc"
    test "First question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "Thanks, \r\n\r\nNow please share your view on these statements so that you can get the best support from [MyHealth] for your needs.\r\n\r\nTo skip any question, reply: Skip\r\n\r\nHere’s the first statement:\r\n\r\n👤 *I am confident that I can do things to avoid health issues or reduce my symptoms.*"
      })
      |> FlowTester.send("1")
      |> results_match([
        %{name: "version", value: "v1.0"},
        %{name: "started", value: "dma-form", label: "@v_start"},
        %{name: "locale", value: "en"},
        %{name: "question_num", value: 0, label: "@result_tag"},
        %{name: "question", value: "Input a number", label: "@result_tag"},
        %{name: "question_id", value: "1", label: "@result_tag"},
        %{name: "min", value: 0, label: "@result_tag"},
        %{name: "max", value: 10, label: "@result_tag"},
        %{name: "end", value: "dma-form", label: "@slug_end"},
        %{name: "risk", value: "low", label: "@result_tag"},
        %{name: "score", value: 0, label: "@result_tag"},
        %{name: "max_score", value: 0, label: "@result_tag"}
      ])
    end
  end
end

# FWB-FormsIssue
