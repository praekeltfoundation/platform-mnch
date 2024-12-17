defmodule FormsTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    assert :ok = FakeCMS.add_pages(wh_pid, [
      %Index{slug: "home", title: "Home"},
      %ContentPage{
        slug: "high-result",
        title: "High result",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "High result message"
          }
        ]
      },
      %ContentPage{
        slug: "medium-result",
        title: "Medium result",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "Medium result message"
          }
        ]
      },
      %ContentPage{
        slug: "low-result",
        title: "Low result",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "Low result message"
          }
        ]
      },
      %ContentPage{
        slug: "skip-high-result",
        title: "Skip result",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "Skip high result message"
          }
        ]
      }
    ])

    assert :ok = FakeCMS.add_form(wh_pid, %Forms.Form{
      id: 1,
      title: "Test Form",
      slug: "dma-form",
      generic_error: "Please choose an option that matches your answer",
      locale: "en",
      version: "v1.0",
      tags: ["dma_form"],
      high_result_page: "high-result",
      high_inflection: 50.0,
      medium_result_page: "medium-result",
      medium_inflection: 30.0,
      low_result_page: "low-result",
      skip_threshold: 1.0,
      skip_high_result_page: "skip-high-result",
      questions: [
        %Forms.IntegerQuestion{
          question: "Input a number",
          explainer: "Explainer 1",
          error: "Oh no",
          semantic_id: "forms-integer",
          min: 0,
          max: 10
        },
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

  describe "DMA Form" do
    test "First question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "Input a number",
      })
      |> FlowTester.send("1")
      |> results_match([
        %{name: "version", value: "v1.0"},
        %{name: "started", value: "dma_form", label: "@v_start"},
        %{name: "locale", value: "en"},
        %{name: "question_num", value: 0, label: "@result_tag"},
        %{name: "question", value: "Input a number", label: "@result_tag"},
        %{name: "question_id", value: "1", label: "@result_tag"},
        %{name: "min", value: 0, label: "@result_tag"},
        %{name: "max", value: 10, label: "@result_tag"},
        %{name: "end", value: "dma-form", label: "@slug_end"},
        %{name: "risk", value: "low", label: "@result_tag"},
        %{name: "score", value: 0, label: "@result_tag"},
        %{name: "max_score", value: 0, label: "@result_tag"},
      ])
    end
  end
end
