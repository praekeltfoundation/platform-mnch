defmodule QuizBreastfeedingTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.FlowStep

  alias Onboarding.QA.Helpers

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})
    FakeCMS.add_images(wh_pid, [
      %Image{
        id: 1,
        download_url: "https://example.com/champion.jpg",
        title: "Breastfeeding quiz champion"
      },
      %Image{
        id: 2,
        download_url: "https://example.com/good.jpg",
        title: "Breastfeeding quiz good"
      },
      %Image{
        id: 3,
        download_url: "https://example.com/learner.jpg",
        title: "Breastfeeding quiz learner"
      },
    ])
    assert :ok = FakeCMS.add_pages(wh_pid, [
      %Index{slug: "home", title: "Home"},
      %ContentPage{
        slug: "breastfeeding-quiz-champion",
        title: "Breastfeeding Quiz Champion",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "*You are a champion!* 🏆\r\n\r\nYou got {score} out of {max_score} answers right. Well done!\r\n\r\nYou’ve earned your breastfeeding hero sticker.\r\n\r\nWhat do you want to explore next?",
            image: 1,
          }
        ]
      },
      %ContentPage{
        slug: "breastfeeding-quiz-good",
        title: "Breastfeeding Quiz Good",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "*Getting there*\r\n\r\nYou got {score} out of {max_score} answers right. Hopefully, you learnt some useful things about breastfeeding along the way.\r\n\r\nThanks for taking part. Here's a special breastfeeding sticker for you.\r\n\r\nWhat would you like to explore next?",
            image: 2,
          }
        ]
      },
      %ContentPage{
        slug: "breastfeeding-quiz-learner",
        title: "Breastfeeding Quiz Learner",
        parent: "home",
        wa_messages: [
          %WAMsg{
            message: "*Up for the challenge?*\r\n\r\nYou didn't get any answers correct this time. Hopefully you learnt some useful things about breastfeeding along the way.\r\n\r\nHere's a special breastfeeding sticker for you.\r\n\r\nWhat would you like to explore next?",
            image: 3,
          }
        ]
      }
    ])

    assert :ok = FakeCMS.add_form(wh_pid, %Forms.Form{
      id: 1,
      title: "Breastfeeding Quiz",
      slug: "breastfeeding-quiz",
      generic_error: "Sorry, I didn't understand that. Please click one of the buttons.",
      locale: "en",
      version: "1.0",
      tags: ["breastfeeding_quiz"],
      high_result_page: "breastfeeding-quiz-champion",
      high_inflection: 75.0,
      medium_result_page: "breastfeeding-quiz-good",
      medium_inflection: 25.0,
      low_result_page: "breastfeeding-quiz-learner",
      skip_threshold: 100.0,
      skip_high_result_page: nil,
      questions: [
        %Forms.CategoricalQuestion{
          question: "*Question 1*\r\n🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nWhat’s the best food for a baby from birth to 6 months?\r\n\r\n• Formula\r\n• Formula + breast milk\r\n• Breast milk only",
          explainer: "",
          error: "",
          semantic_id: "baby-food",
          answers: [
            %Forms.Answer{
              score: 0.0,
              answer: "Formula",
              response: "🤔\r\n\r\nActually, it's best to give your baby *only breast milk* from birth to 6 months if you can.\r\n\r\nBreast milk has everything your baby needs, and your body will make as much milk as she needs.\r\n\r\nIf you are struggling to breastfeed, speak to a health worker about what to try.\r\n\r\nLet's keep going ...",
              semantic_id: "formula"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "Formula+breast milk",
              response: "🤔\r\n\r\nActually, it's best to give your baby *only breast milk* from birth to 6 months if you can.\r\n\r\nBreast milk has everything your baby needs, and your body will make as much milk as she needs.\r\n\r\nIf you are struggling to breastfeed, speak to a health worker about what to try.\r\n\r\nLet's keep going ...",
              semantic_id: "formula-and-breast-milk"
            },
            %Forms.Answer{
              score: 1.0,
              answer: "Breast milk only",
              response: "*Yes!* ✅\r\n\r\nIt's best to give your baby only breast milk from birth to 6 months if you can.\r\n\r\nBreast milk has everything your baby needs, and your body will make as much milk as she needs.\r\n\r\nLet's keep going ...",
              semantic_id: "breast-milk-only"
            },
          ]
        },
        %Forms.CategoricalQuestion{
          question: "*Question 2*\r\n🟩🟩🟩🟩⬜⬜⬜⬜\r\n\r\nHow does breastfeeding help you as a mother?\r\n\r\n• It helps bonding with baby\r\n• It saves money\r\n• It helps you sleep better\r\n• It lowers your risk of depression\r\n• All of the above",
          explainer: "",
          error: "",
          semantic_id: "breastfeeding-help-mother",
          answers: [
            %Forms.Answer{
              score: 0.0,
              answer: "It helps bonding",
              response: "🤔 It's even better than that!\r\n\r\nBreastfeeding is great for moms for many practical and health reasons.\r\n\r\nIt helps mom:\r\n• bleed less after birth\r\n• bond with baby\r\n• save money and time\r\n• sleep better\r\n• lose pregnancy weight\r\n\r\nIt also lowers the risk of illnesses like:\r\n• depression\r\n• some cancers\r\n• heart disease\r\n• diabetes\r\n\r\nLet's keep going ...",
              semantic_id: "bonding"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "It can save money",
              response: "🤔 It's even better than that!\r\n\r\nBreastfeeding is great for moms for many practical and health reasons.\r\n\r\nIt helps mom:\r\n• bleed less after birth\r\n• bond with baby\r\n• save money and time\r\n• sleep better\r\n• lose pregnancy weight\r\n\r\nIt also lowers the risk of illnesses like:\r\n• depression\r\n• some cancers\r\n• heart disease\r\n• diabetes\r\n\r\nLet's keep going ...",
              semantic_id: "save-money"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "It helps sleep",
              response: "🤔 It's even better than that!\r\n\r\nBreastfeeding is great for moms for many practical and health reasons.\r\n\r\nIt helps mom:\r\n• bleed less after birth\r\n• bond with baby\r\n• save money and time\r\n• sleep better\r\n• lose pregnancy weight\r\n\r\nIt also lowers the risk of illnesses like:\r\n• depression\r\n• some cancers\r\n• heart disease\r\n• diabetes\r\n\r\nLet's keep going ...",
              semantic_id: "sleep"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "Depression risk",
              response: "🤔 It's even better than that!\r\n\r\nBreastfeeding is great for moms for many practical and health reasons.\r\n\r\nIt helps mom:\r\n• bleed less after birth\r\n• bond with baby\r\n• save money and time\r\n• sleep better\r\n• lose pregnancy weight\r\n\r\nIt also lowers the risk of illnesses like:\r\n• depression\r\n• some cancers\r\n• heart disease\r\n• diabetes\r\n\r\nLet's keep going ...",
              semantic_id: "depression-risk"
            },
            %Forms.Answer{
              score: 1.0,
              answer: "All of the above",
              response: "*Yes!* ✅\r\n\r\nBreastfeeding is great for moms for practical and health reasons.\r\n\r\nIt helps mom:\r\n• bleed less after birth\r\n• bond with baby\r\n• save money and time\r\n• sleep better\r\n• lose pregnancy weight\r\n\r\nIt also lowers the risk of illnesses like:\r\n• depression\r\n• some cancers\r\n• heart disease\r\n• diabetes\r\n\r\nLet's keep going ...",
              semantic_id: "all-of-the-above"
            }
          ]
        },
        %Forms.CategoricalQuestion{
          question: "*Question 3*\r\n🟩🟩🟩🟩🟩🟩⬜⬜\r\n\r\nHow does breastfeeding help a baby?\r\n\r\n• It boost baby's immune system\r\n• It gives a baby everything he needs\r\n• It's clean and safe\r\n• All of the above",
          explainer: "",
          error: "",
          semantic_id: "breastfeeding-baby",
          answers: [
            %Forms.Answer{
              score: 0.0,
              answer: "Immune boost",
              response: "*It's even better than that - all of these are true!* 🤔\r\n\r\nBreast milk gives a baby everything he needs, and it's available whenever he’s hungry.\r\n\r\nBreastfeeding strengthens the bond between the baby and the mother.\r\n\r\nBreast milk makes a baby's immune system stronger. This protects him against illness. It lowers the risk of:\r\n\r\n• infections\r\n• diarrhoea and vomiting\r\n• sudden infant death syndrome (SIDS)\r\n• obesity\r\n• heart disease as an adult\r\n\r\nWith breastfeeding, you don’t need to wash and sterilise bottles or boil water to make formula.\r\n\r\nTime for the last question ...",
              semantic_id: "immune-boost"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "Everything he needs",
              response: "*It's even better than that - all of these are true!* 🤔\r\n\r\nBreast milk gives a baby everything he needs, and it's available whenever he’s hungry.\r\n\r\nBreastfeeding strengthens the bond between the baby and the mother.\r\n\r\nBreast milk makes a baby's immune system stronger. This protects him against illness. It lowers the risk of:\r\n\r\n• infections\r\n• diarrhoea and vomiting\r\n• sudden infant death syndrome (SIDS)\r\n• obesity\r\n• heart disease as an adult\r\n\r\nWith breastfeeding, you don’t need to wash and sterilise bottles or boil water to make formula.\r\n\r\nTime for the last question ...",
              semantic_id: "everything-he-needs"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "It's clean and safe",
              response: "*It's even better than that - all of these are true!* 🤔\r\n\r\nBreast milk gives a baby everything he needs, and it's available whenever he’s hungry.\r\n\r\nBreastfeeding strengthens the bond between the baby and the mother.\r\n\r\nBreast milk makes a baby's immune system stronger. This protects him against illness. It lowers the risk of:\r\n\r\n• infections\r\n• diarrhoea and vomiting\r\n• sudden infant death syndrome (SIDS)\r\n• obesity\r\n• heart disease as an adult\r\n\r\nWith breastfeeding, you don’t need to wash and sterilise bottles or boil water to make formula.\r\n\r\nTime for the last question ...",
              semantic_id: "clean-and-safe"
            },
            %Forms.Answer{
              score: 1.0,
              answer: "All of the above",
              response: "*Yes, all of these benefits are true* ✅\r\n\r\nBreast milk gives a baby everything he needs, and it's available whenever he needs it.\r\n\r\nBreastfeeding strengthens the bond between the baby and the mother.\r\n\r\nBreast milk makes a baby's immune system stronger. This protects him against illness. It lowers the risk of:\r\n\r\n• infections\r\n• diarrhoea and vomiting\r\n• sudden infant death syndrome (SIDS)\r\n• obesity\r\n• heart disease as an adult\r\n\r\nWith breastfeeding, you don’t need to wash and sterilise bottles or boil water to make formula.\r\n\r\nLast question ...",
              semantic_id: "all-of-the-above"
            }
          ]
        },
        %Forms.CategoricalQuestion{
          question: "*Question 4*\r\n🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nHow often should you breastfeed your baby?\r\n\r\n• Whenever he is hungry\r\n• Every 4 hours\r\n• Every 2 hours",
          explainer: "",
          error: "",
          semantic_id: "how-often-breastfeed",
          answers: [
            %Forms.Answer{
              score: 1.0,
              answer: "When he is hungry",
              response: "*That's correct* ✅\r\n\r\nExperts around the world recommend that you breastfeed your baby whenever he is hungry. This is called demand feeding.\r\n\r\nWhen your baby is a newborn, feed him at least 8 times in 24 hours. As he gets older he will have bigger feeds less often.\r\n\r\nThe more your baby breastfeeds, the more milk you will make.\r\n\r\nAlmost all mothers produce enough milk so baby doesn't need anything else for the first 6 months of life.\r\n\r\nAnd that's it!",
              semantic_id: "when-he-is-hungry"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "Every 4 hours",
              response: "🤔\r\n\r\nIn fact, experts around the world recommend that you breastfeed your baby whenever he is hungry. This is called demand feeding.\r\n\r\nWhen your baby is a newborn, feed him at least 8 times in 24 hours. As he gets older he will have bigger feeds less often.\r\n\r\nThe more your baby breastfeeds, the more milk your body makes.\r\n\r\nAlmost all mothers make enough milk so that their baby doesn't need anything else for the first 6 months of life.\r\n\r\nAnd that's it!",
              semantic_id: "every-4-hours"
            },
            %Forms.Answer{
              score: 0.0,
              answer: "Every 2 hours",
              response: "🤔\r\n\r\nIn fact, experts around the world recommend that you breastfeed your baby whenever he is hungry. This is called demand feeding.\r\n\r\nWhen your baby is a newborn, feed him at least 8 times in 24 hours. As he gets older he will have bigger feeds less often.\r\n\r\nThe more your baby breastfeeds, the more milk your body makes.\r\n\r\nAlmost all mothers make enough milk so that their baby doesn't need anything else for the first 6 months of life.\r\n\r\nAnd that's it!",
              semantic_id: "every-2-hours"
            }
          ]
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

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("quiz-breastfeeding")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
      |> FlowTester.set_local_params("config", %{"assessment_tag" => "breastfeeding_quiz", "response_button_text" => "Next question"})
    %{flow: flow}
  end

  setup [:setup_flow]

  describe "Breastfeeding quiz" do
    test "First question", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> receive_message(%{
        text: "*Question 1*" <> _,
        buttons: [{"Formula", "Formula"}, {"Formula+breast milk", "Formula+breast milk"}, {"Breast milk only", "Breast milk only"}]
      })
      |> results_match([
        %{name: "version", value: "1.0"},
        %{name: "started", value: "breastfeeding_quiz", label: "@v_start"},
        %{name: "locale", value: "en"}
      ])
    end

    test "First question correct", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Breast milk only")
      |> receive_message(%{
        text: "*Yes!* ✅\r\n\r\nIt's best to give your baby only breast milk" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 0},
        %{name: "question_id", value: "breast-milk-only"},
      ])
    end

    test "First question incorrect", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Formula")
      |> receive_message(%{
        text: "🤔\r\n\r\nActually, it's best to give your baby *only breast milk*" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 0},
        %{name: "question_id", value: "formula"},
      ])
    end

    test "Second question", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Next question")
      |> receive_message(%{
        text: "*Question 2*" <> _,
        list: {"Select option", [{"It helps bonding", "It helps bonding"}, {"It can save money", "It can save money"}, {"It helps sleep", "It helps sleep"}, {"Depression risk", "Depression risk"}, {"All of the above", "All of the above"}]}
      })
      |> results_match([])
    end

    test "Second question correct", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("All of the above")
      |> receive_message(%{
        text: "*Yes!* ✅\r\n\r\nBreastfeeding is great for moms for practical" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 1},
        %{name: "question_id", value: "all-of-the-above"},
      ])
    end

    test "Second question incorrect", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("It helps bonding")
      |> receive_message(%{
        text: "🤔 It's even better than that!\r\n\r\nBreastfeeding is great for" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 1},
        %{name: "question_id", value: "bonding"},
      ])
    end

    test "Third question", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Next question")
      |> receive_message(%{
        text: "*Question 3*" <> _,
        list: {"Select option", [{"Immune boost", "Immune boost"}, {"Everything he needs", "Everything he needs"}, {"It's clean and safe", "It's clean and safe"}, {"All of the above", "All of the above"}]},
      })
      |> results_match([])
    end

    test "Third question correct", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("All of the above")
      |> receive_message(%{
        text: "*Yes, all of these benefits are true* ✅" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 2},
        %{name: "question_id", value: "all-of-the-above"},
      ])
    end

    test "Third question incorrect", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Immune boost")
      |> receive_message(%{
        text: "*It's even better than that - all of these are true!* 🤔" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 2},
        %{name: "question_id", value: "immune-boost"},
      ])
    end

    test "Fourth question", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Next question")
      |> receive_message(%{
        text: "*Question 4*" <> _,
        buttons: [{"When he is hungry", "When he is hungry"}, {"Every 4 hours", "Every 4 hours"}, {"Every 2 hours", "Every 2 hours"}]
      })
      |> results_match([])
    end

    test "Fourth question correct", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("When he is hungry")
      |> receive_message(%{
        text: "*That's correct* ✅" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 3},
        %{name: "question_id", value: "when-he-is-hungry"},
      ])
    end

    test "Fourth question incorrect", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Every 4 hours")
      |> receive_message(%{
        text: "🤔\r\n\r\nIn fact, experts around the world recommend that you" <> _,
        buttons: [{"@config.items.response_button_text", "Next question"}]
      })
      |> results_match([
        %{name: "question_num", value: 3},
        %{name: "question_id", value: "every-4-hours"},
      ])
    end

    test "Champion result", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Breast milk only")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowTester.send("When he is hungry")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Next question")
      |> receive_message(%{
        text: "*You are a champion!* 🏆\r\n\r\nYou got 4 out of 4 answers right." <> _,
        image: "https://example.com/champion.jpg"
      })
      |> results_match([
        %{name: "end", value: "breastfeeding-quiz"},
        %{name: "risk", value: "high"},
        %{name: "score", value: 4.0},
        %{name: "max_score", value: 4.0},
      ])
    end

    test "Good result", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("It helps bonding")
      |> FlowTester.send("Next question")
      |> FlowTester.send("All of the above")
      |> FlowTester.send("Next question")
      |> FlowTester.send("When he is hungry")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Next question")
      |> receive_message(%{
        text: "*Getting there*\r\n\r\nYou got 2 out of 4 answers right." <> _,
        image: "https://example.com/good.jpg"
      })
      |> results_match([
        %{name: "end", value: "breastfeeding-quiz"},
        %{name: "risk", value: "medium"},
        %{name: "score", value: 2.0},
        %{name: "max_score", value: 4.0},
      ])
    end

    test "Learner result", %{flow: flow} do
      flow
      |> FlowTester.start()
      |> FlowTester.send("Formula")
      |> FlowTester.send("Next question")
      |> FlowTester.send("It helps bonding")
      |> FlowTester.send("Next question")
      |> FlowTester.send("Immune boost")
      |> FlowTester.send("Next question")
      |> FlowTester.send("Every 4 hours")
      |> FlowStep.clear_messages()
      |> FlowStep.clear_results()
      |> FlowTester.send("Next question")
      |> receive_message(%{
        text: "*Up for the challenge?*\r\n\r\nYou didn't get any answers correct" <> _,
        image: "https://example.com/learner.jpg"
      })
      |> results_match([
        %{name: "end", value: "breastfeeding-quiz"},
        %{name: "risk", value: "low"},
        %{name: "score", value: +0.0},
        %{name: "max_score", value: 4.0},
      ])
    end
  end
end
