defmodule DMAFormTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.FlowStep

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

    assert :ok = FakeCMS.add_form(wh_pid, %Forms.Form{
      id: 1,
      title: "DMA Form",
      slug: "mnch_onboarding_dma_form",
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
        %Forms.CategoricalQuestion{
          question: "Thanks, {{name}}\r\n\r\nNow please share your view on these statements so that you can get the best support from [MyHealth] for your needs.\r\n\r\nTo skip any question, reply: Skip\r\n\r\nHere’s the first statement:\r\n\r\n👤 *I am confident that I can do things to avoid health issues or reduce my symptoms.*",
          explainer: "TEST: Explainer text",
          error: "Oh no",
          semantic_id: "dma-do-things",
          answers: [%Forms.Answer{
            answer: "Strongly disagree",
            score: 2.0,
            semantic_id: "dma_form_01_strongly_disagree"
            },
            %Forms.Answer{
              answer: "Disagree",
              score: 1.0,
              semantic_id: "dma_form_01_disagree"
            },
            %Forms.Answer{
              answer: "Neutral",
              score: 0.0,
              semantic_id: "dma_form_01_neutral"
            },
            %Forms.Answer{
              answer: "Agree",
              score: 1.0,
              semantic_id: "dma_form_01_agree"
            },
            %Forms.Answer{
              answer: "Strongly agree",
              score: 2.0,
              semantic_id: "dma_form_01_strongly_agree"
            }
          ]
        },
        %Forms.CategoricalQuestion{
          question: "Thanks for sharing. How about this one?\r\n\r\n👤 *I am confident that I know when I need to get medical care and when I can handle a health issue by myself.*",
          explainer: "Why",
          error: "Oh no",
          semantic_id: "dma-medical-care",
          answers: [%Forms.Answer{
            answer: "Strongly disagree",
            score: 2.0,
            semantic_id: "dma_form_02_strongly_disagree"
            },
            %Forms.Answer{
              answer: "Disagree",
              score: 1.0,
              semantic_id: "dma_form_02_disagree"
            },
            %Forms.Answer{
              answer: "Neutral",
              score: 0.0,
              semantic_id: "dma_form_02_neutral"
            },
            %Forms.Answer{
              answer: "Agree",
              score: 1.0,
              semantic_id: "dma_form_02_agree"
            },
            %Forms.Answer{
              answer: "Strongly agree",
              score: 2.0,
              semantic_id: "dma_form_02_strongly_agree"
            }
          ]
        },
        %Forms.CategoricalQuestion{
          question: "Here’s a next one:\r\n\r\n👤*I am confident that I can tell a health worker the worries I have, even when they don't ask.*",
          explainer: "Why",
          error: "Oh no",
          semantic_id: "dma-sharing",
          answers: [%Forms.Answer{
            answer: "Strongly disagree",
            score: 2.0,
            semantic_id: "dma_form_03_strongly_disagree"
            },
            %Forms.Answer{
              answer: "Disagree",
              score: 1.0,
              semantic_id: "dma_form_03_disagree"
            },
            %Forms.Answer{
              answer: "Neutral",
              score: 0.0,
              semantic_id: "dma_form_03_neutral"
            },
            %Forms.Answer{
              answer: "Agree",
              score: 1.0,
              semantic_id: "dma_form_03_agree"
            },
            %Forms.Answer{
              answer: "Strongly agree",
              score: 2.0,
              semantic_id: "dma_form_03_strongly_agree"
            }
          ]
        },
        %Forms.CategoricalQuestion{
          question: "Here’s a next one:\r\n\r\n👤 *I am confident that I can stick to any medical advice from a health worker.*",
          explainer: "Why",
          error: "Oh no",
          semantic_id: "dma-medical-advice",
          answers: [%Forms.Answer{
            answer: "Strongly disagree",
            score: 2.0,
            semantic_id: "dma_form_04_strongly_disagree"
            },
            %Forms.Answer{
              answer: "Disagree",
              score: 1.0,
              semantic_id: "dma_form_04_disagree"
            },
            %Forms.Answer{
              answer: "Neutral",
              score: 0.0,
              semantic_id: "dma_form_04_neutral"
            },
            %Forms.Answer{
              answer: "Agree",
              score: 1.0,
              semantic_id: "dma_form_04_agree"
            },
            %Forms.Answer{
              answer: "Strongly agree",
              score: 2.0,
              semantic_id: "dma_form_04_strongly_agree"
            }
          ]
        },
        %Forms.CategoricalQuestion{
          question: "Last statement!\r\n\r\n👤 *I am confident that I can find solutions when I have to deal with a new health issue.*",
          explainer: "Why",
          error: "Oh no",
          semantic_id: "dma-find-solutions",
          answers: [%Forms.Answer{
            answer: "Strongly disagree",
            score: 2.0,
            semantic_id: "dma_form_05_strongly_disagree"
            },
            %Forms.Answer{
              answer: "Disagree",
              score: 1.0,
              semantic_id: "dma_form_05_disagree"
            },
            %Forms.Answer{
              answer: "Neutral",
              score: 0.0,
              semantic_id: "dma_form_05_neutral"
            },
            %Forms.Answer{
              answer: "Agree",
              score: 1.0,
              semantic_id: "dma_form_05_agree"
            },
            %Forms.Answer{
              answer: "Strongly agree",
              score: 2.0,
              semantic_id: "dma_form_05_strongly_agree"
            }
          ]
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
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
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
      |> FlowTester.set_contact_properties(%{"name" => "Stitch"})
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "Thanks, Stitch\r\n\r\nNow please share your view on these statements so that you can get the best support from [MyHealth] for your needs.\r\n\r\nTo skip any question, reply: Skip\r\n\r\nHere’s the first statement:\r\n\r\n👤 *I am confident that I can do things to avoid health issues or reduce my symptoms.*",
        list: {"Select option", [{"Strongly disagree", "Strongly disagree"}, {"Disagree", "Disagree"}, {"Neutral", "Neutral"}, {"Agree", "Agree"}, {"Strongly agree", "Strongly agree"}]}
      })
      |> results_match([
        %{name: "version", value: "v1.0"},
        %{name: "started", value: "mnch_onboarding_dma_form", label: "@v_start"},
        %{name: "locale", value: "en"}
      ])
    end

    test "First question then explainer", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"name" => "Stitch"})
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("explain")
      |> receive_messages([
        %{text: "*Explainer:* TEST: Explainer text"},
        %{
          text: "Thanks, Stitch\r\n\r\nNow please share your view on these statements so that you can get the best support from [MyHealth] for your needs.\r\n\r\nTo skip any question, reply: Skip\r\n\r\nHere’s the first statement:\r\n\r\n👤 *I am confident that I can do things to avoid health issues or reduce my symptoms.*",
          list: {"Select option", [{"Strongly disagree", "Strongly disagree"}, {"Disagree", "Disagree"}, {"Neutral", "Neutral"}, {"Agree", "Agree"}, {"Strongly agree", "Strongly agree"}]}
      }])
    end

    test "First question then second question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"name" => "Stitch"})
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send("Strongly disagree")
      |> results_match([
        %{name: "version", value: "v1.0"},
        %{name: "started", value: "mnch_onboarding_dma_form", label: "@v_start"},
        %{name: "locale", value: "en"},
        %{name: "question_num", value: 1, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_01_strongly_disagree", label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_01" => "Strongly disagree"
      })
      |> receive_message(%{
        text: "Thanks for sharing. How about this one?\r\n\r\n👤 *I am confident that I know when I need to get medical care and when I can handle a health issue by myself.*",
        list: {"Select option", [{"Strongly disagree", "Strongly disagree"}, {"Disagree", "Disagree"}, {"Neutral", "Neutral"}, {"Agree", "Agree"}, {"Strongly agree", "Strongly agree"}]}
      })
    end

    test "Second question then third question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_contact_properties(%{"name" => "Stitch"})
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Strongly disagree")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Disagree")
      |> results_match([
        %{name: "question_num", value: 2, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_02_disagree", label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_02" => "Disagree"
      })
      |> receive_message(%{
        text: "Here’s a next one:\r\n\r\n👤*I am confident that I can tell a health worker the worries I have, even when they don't ask.*",
        list: {"Select option", [{"Strongly disagree", "Strongly disagree"}, {"Disagree", "Disagree"}, {"Neutral", "Neutral"}, {"Agree", "Agree"}, {"Strongly agree", "Strongly agree"}]}
      })
    end

    test "Third question then fourth question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Strongly disagree")
      |> FlowTester.send("Disagree")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Neutral")
      |> results_match([
        %{name: "question_num", value: 3, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_03_neutral", label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_03" => "Neutral"
      })
      |> receive_message(%{
        text: "Here’s a next one:\r\n\r\n👤 *I am confident that I can stick to any medical advice from a health worker.*",
        list: {"Select option", [{"Strongly disagree", "Strongly disagree"}, {"Disagree", "Disagree"}, {"Neutral", "Neutral"}, {"Agree", "Agree"}, {"Strongly agree", "Strongly agree"}]}
      })
    end

    test "Fourth question then fifth question", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Strongly disagree")
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Neutral")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Agree")
      |> results_match([
        %{name: "question_num", value: 4, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_04_agree", label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_04" => "Agree"
      })
      |> receive_message(%{
        text: "Last statement!\r\n\r\n👤 *I am confident that I can find solutions when I have to deal with a new health issue.*",
        list: {"Select option", [{"Strongly disagree", "Strongly disagree"}, {"Disagree", "Disagree"}, {"Neutral", "Neutral"}, {"Agree", "Agree"}, {"Strongly agree", "Strongly agree"}]}
      })
    end

    test "High result page", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Strongly disagree")
      |> FlowTester.send("Strongly disagree")
      |> FlowTester.send("Strongly disagree")
      |> FlowTester.send("Strongly disagree")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Strongly disagree")
      |> results_match([
        %{name: "question_num", value: 5, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_05_strongly_disagree", label: "@result_tag"},
        %{name: "end", value: "mnch_onboarding_dma_form", label: "@slug_end"},
        %{name: "risk", value: "high", label: "@result_tag"},
        %{name: "score", value: 10.0, label: "@result_tag"},
        %{name: "max_score", value: 10.0, label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_05" => "Strongly disagree"
      })
      |> receive_message(%{
        text: "*Thank you for completing this*\r\n\r\nYou seem comfortable and confident making decisions about your health.\r\n\r\nKeep on doing what you’re doing! 🤩",
      })
    end

    test "Medium result page", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Neutral")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Neutral")
      |> results_match([
        %{name: "question_num", value: 5, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_05_neutral", label: "@result_tag"},
        %{name: "end", value: "mnch_onboarding_dma_form", label: "@slug_end"},
        %{name: "risk", value: "high", label: "@result_tag"},
        %{name: "score", value: 3.0, label: "@result_tag"},
        %{name: "max_score", value: 10.0, label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_05" => "Neutral"
      })
      |> receive_message(%{
        text: "*Thank you for completing this*\r\n\r\nYou seem comfortable and confident making decisions about your health.\r\n\r\nKeep on doing what you’re doing! 🤩",
      })
    end

    test "Low result page", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Neutral")
      |> FlowTester.send("Neutral")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Neutral")
      |> results_match([
        %{name: "question_num", value: 5, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_05_neutral", label: "@result_tag"},
        %{name: "end", value: "mnch_onboarding_dma_form", label: "@slug_end"},
        %{name: "risk", value: "high", label: "@result_tag"},
        %{name: "score", value: 2.0, label: "@result_tag"},
        %{name: "max_score", value: 10.0, label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_05" => "Neutral"
      })
      |> receive_message(%{
        text: "*Thank you for completing this*\r\n\r\nYou seem comfortable and confident making decisions about your health.\r\n\r\nKeep on doing what you’re doing! 🤩",
      })
    end

    test "Skip result page", %{flow: flow} do
      flow
      |> Helpers.init_contact_fields()
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "dma_form"})
      |> FlowTester.start()
      |> FlowTester.send("Disagree")
      |> FlowTester.send("Skip")
      |> FlowTester.send("Neutral")
      |> FlowTester.send("Neutral")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Neutral")
      |> results_match([
        %{name: "question_num", value: 5, label: "@result_tag"},
        %{name: "question_id", value: "dma_form_05_neutral", label: "@result_tag"},
        %{name: "end", value: "mnch_onboarding_dma_form", label: "@slug_end"},
        %{name: "risk", value: "skip_high", label: "@result_tag"},
        %{name: "score", value: 1.0, label: "@result_tag"},
        %{name: "max_score", value: 8.0, label: "@result_tag"},
      ])
      |> contact_matches(%{
        "dma_05" => "Neutral"
      })
      |> receive_message(%{
        text: "You are seeing this message because you skipped an answer.",
      })
    end
  end
end
# FWB-FormsIssue
