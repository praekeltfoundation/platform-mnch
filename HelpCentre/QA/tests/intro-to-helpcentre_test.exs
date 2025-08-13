defmodule IntroToHelpCentreTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  alias FlowTester.FlowStep
  alias FlowTester.WebhookHandler.Generic
  alias HelpCentre.QA.Helpers

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # The various index pages aren't in the content sheet, so we need to add them manually.
    indices = [
      %Index{title: "Help centre", slug: "help-centre-index"},
      %Index{title: "Onboarding", slug: "onboarding-index"},
    ]
    
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
    assert :ok = Helpers.import_content_csv(wh_pid, "help-centre", import_opts)

    # Error messages are in a separate sheet.
    assert :ok = Helpers.import_content_csv(wh_pid, "error-messages", existing_pages: indices)

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp aaq_inbound_check(env, _ctx) do
    body = %{
      "message" =>
        "*1* - Baby's first teeth\n*2* - Vaginal discharge in pregnancy\n*3* - Baby's growth - Developmental milestones\n*4* - Toothache in pregnancy\n*5* - Latching baby to the breast",
      "body" => %{
        "1" => %{
          "text" =>
            "*Swollen, tender gums are a sign that baby is teething*\r\n\r\nMost babies 👶🏽 begin to teethe between 4 and 7 months old, but some may start much later. You don't have to worry if your baby’s teeth come in a bit later. By around 3 years old, your child will have all of her baby teeth.  \r\n\r\n*Signs and symptoms of teething*\r\n\r\n- Swollen, tender gums,\r\n- Fussiness and crying,\r\n- A slightly raised temperature, \r\n- Lots of drool, which can cause a rash on the face,\r\n- Rubbing a cheek or pulling at an ear,\r\n- Bringing the hands to the mouth,\r\n- Changes in eating or sleeping patterns,\r\n- Or, if you are breastfeeding, your baby might start biting while nursing.\r\n\r\n*What to do*\r\n- Give baby a solid cold 🧊 teething ring or toy to chew on. \r\n- Rub your baby's gums with your clean finger ☝🏽.\r\n\r\n*Reasons to go to the clinic* 🏥\r\n- If baby's gums are bleeding,\r\n- If you see pus at the gums or a swelling of baby's face,\r\n- If your baby has a fever.",
          "id" => "12"
        },
        "2" => %{
          "text" =>
            "*Yes, unusual vaginal discharge can signal a problem*\r\n\r\nVaginal discharge may increase during pregnancy and is normally white, thin or thick without a strong smell. If the discharge is accompanied by itching and has a thick, cottage cheese-like consistency or appearance, it's not normal and needs treatment 🩺. \r\n\r\nLight spotting or bleeding🩸 can be normal. But if you experience heavy bleeding, cramps, or pain – then go straight to the clinic to be checked.\r\n\r\n*What to do*\r\n- Look at the colour of your discharge. It should be clear 💧 or milky white,\r\n- Smell the discharge. It should not have a bad smell 😤, \r\n- Bath regularly and wear clean cotton underwear 🩲.\r\n\r\n*Reasons to go to the clinic* 🏥\r\n- If your discharge is yellowish, greenish or thick and cheesy\r\n- When your vagina has a foul or fishy smell\r\n- If the inside of your vagina burns or itches\r\n- If it burns when you urinate\r\n- When sex is painful",
          "id" => "35"
        },
        "3" => %{
          "text" =>
            "*Developmental Milestones*\r\n \r\nMost babies are able to do the same things at about the same age. Some develop more quickly, while others reach some milestones more slowly. \r\n \r\nMonth 1\r\n• Makes eye contact\r\n• Reacts to mom’s voice and smiles\r\n \r\nMonth 2\r\n• Gives social smiles \r\n• Studies faces\r\n• Murmurs and giggles at sounds\r\n• Shows anger\r\n \r\nMonth 3\r\n• Smiles at you\r\n• Lifts arms up, hands wide open and moves legs\r\n \r\nMonth 4\r\n• Pushes up arms when on her tummy\r\n• Grabs objects\r\n• Enjoys playing and cries when disrupted\r\n \r\nMonth 6\r\n• Sits with support\r\n• Holds toy in one hand\r\n• Babbles\r\n• Puts everything in her mouth\r\n• Laughs out loud \r\n• Starts to hold a bottle \r\n• Shows likes and dislikes\r\n \r\nMonth 9\r\n• Responds when called\r\n• Sits without support\r\n• Crawls\r\n• Rolls\r\n• Pulls up to stand\r\n• Understands “yes” and “no”\r\n• Holds a bottle\r\n \r\nMonth 12\r\n• Walks around furniture sideways\r\n• Walks with feet apart & arms up\r\n• Looks for toys when out of sight\r\n• Pincer grasp and release if asked\r\n• Knows her name\r\n• Understands simple commands\r\n• Finger feeds",
          "id" => "183"
        },
        "4" => %{
          "text" =>
            "*Yes, pregnancy can cause toothache*\r\n\r\nAches and pains 💢 in the teeth or gums are common in pregnancy. Hormones soften your gums and increase the blood supply, which can lead to inflammation and swollen, bleeding gums (gingivitis).\r\n\r\nA build-up of mucus in the sinuses during nasal congestion or allergies like sinusitis 👃🏽, may cause pressure on the gums resulting in painful teeth.\r\n\r\n*What to do*\r\nPregnancy hormones reduce your body's natural ability to control the build-up of germs (plaque) on your teeth 🦷. Brush teeth *twice daily* to prevent gingivitis – or a serious gum disease called periodontitis.",
          "id" => "4"
        },
        "5" => %{
          "text" =>
            "*Latching baby to the breast*\r\n\r\nLatching is the way your baby grips the breast with his mouth.🤱🏽 It's important he latches correctly for successful breastfeeding. A good latch means baby gets enough milk out – without giving you sore or cracked nipples. \r\n\r\nTo latch your baby:\r\n- make sure he is facing you, \r\n- his head should be slightly tilted backwards and not turned to the side\r\n- his mouth should be open wide \r\n- you bring his head towards the breast. \r\n\r\nWhen latched, his lips should be curled outwards, with a good mouthful of your breast. Check that he has most of the dark area around your nipple in his mouth. \r\nIf you see his jaw moving up and down as he feeds, you know he has latched on well.\r\n\r\n*Tap the link below for:*\r\n- A video 📹 of baby latching onto the breast: \r\nhttps://www.youtube.com/watch?v=wjt-Ashodw8",
          "id" => "153"
        }
      },
      "feedback_secret_key" => "dummy_key",
      "inbound_secret_key" => "dummy_key=",
      "inbound_id" => "123",
      "next_page_url" => "/inbound/123/2?inbound_secret_key=dummy_key"
    }

    %Tesla.Env{env | status: 200, body: body}
  end

  def aaq_check_urgency(env, ctx) do
    urgency_score = Map.get(ctx, :aaq_urgency_score, "0.0")
    body = %{"urgency_score" => urgency_score}
    %Tesla.Env{env | status: 200, body: body}
  end

  defp setup_fake_aaq(step, ctx) do
    gen_pid = start_link_supervised!(Generic, id: :fake_aaq)

    Generic.add_handler(
      gen_pid,
      "/api/v1/inbound/check",
      &aaq_inbound_check(&1, ctx)
    )

    Generic.add_handler(
      gen_pid,
      "/api/v1/check-urgency",
      &aaq_check_urgency(&1, ctx)
    )

    WH.set_adapter(step, "https://hub.qa.momconnect.co.za/", Generic.wh_adapter(gen_pid))
  end

  defp set_config_helpdesk_open(step) do
    step
    |> FlowTester.set_global_dict("settings", %{
      "working_hours_start_hour" => "5",
      "working_hours_end_hour" => "19",
      "working_hours_start_day" => "2",
      "working_hours_end_day" => "6"
    })
  end

  defp set_config_helpdesk_closed(step) do
    step
    |> FlowTester.set_global_dict("settings", %{
      "working_hours_start_hour" => "0",
      "working_hours_end_hour" => "0",
      "working_hours_start_day" => "0",
      "working_hours_end_day" => "0"
    })
  end

  setup_all _ctx, do: %{init_flow: Helpers.load_flow("intro-to-helpcentre")}

  defp setup_flow(ctx) do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow =
      ctx.init_flow
      |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
      |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
      |> Helpers.setup_fake_turn(ctx)
      |> setup_fake_aaq(ctx)
      |> set_config_helpdesk_open()

    %{flow: flow}
  end

  # This lets us have cleaner button/list assertions.
  def indexed_list(var, labels) do
    Enum.with_index(labels, fn lbl, idx -> {"@#{var}[#{idx}]", lbl} end)
  end

  # The common case for buttons.
  defmacro button_labels(labels) do
    quote do: unquote(indexed_list("button_labels", labels))
  end

  # The common case for lists.
  defmacro list_items(labels) do
    quote do: unquote(indexed_list("list_items", labels))
  end

  setup [:setup_flow]

  test "new to helpcentre", %{flow: flow} do
    flow
    |> FlowTester.set_contact_properties(%{"returning_help_centre_user" => ""})
    |> FlowTester.start()
    |> receive_message(%{
      text: "*Welcome to the [MyHealth] Help Centre*" <> _
    })
  end

  test "returning to helpcentre", %{flow: flow} do
    flow
    |> FlowTester.set_contact_properties(%{"returning_help_centre_user" => "true"})
    |> FlowTester.start()
    |> receive_message(%{
      text: "*Welcome back to the Help Centre*" <> _
    })
  end

  describe "Emergency Help:" do
    test "emergency numbers", %{flow: flow} do
      FlowTester.start(flow)
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Emergency help")
      |> receive_message(%{
        text: "If you're in a health emergency, please contact emergency services" <> _
      })
      |> FlowTester.send(button_label: "Emergency Numbers")
      |> receive_message(%{
        text: "*Emergency contact numbers*" <> _
      })
    end

    test "talk to health agent while helpdesk during operating hours", %{flow: flow} do
      FlowTester.start(flow)
      |> FlowTester.send(button_label: "Emergency help")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Talk to health agent")
      |> FlowTester.handle_child_flow("8046066f-3cb1-43d6-ace0-850769bd13a3")
      |> flow_finished()
    end

    # TODO: Ask Rudi to help with setting up flag for open/closed helpdesk
    test "talk to health agent while helpdesk outside of operating hours", %{flow: flow} do
      flow = set_config_helpdesk_closed(flow)

      FlowTester.start(flow)
      |> FlowTester.send(button_label: "Emergency help")
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Talk to health agent")
      |> receive_message(%{
        text:
          "[Health agents] are available between [9am - 4pm on weekdays].\r\n\r\n👇🏽 You are welcome to browse the service by choosing an option below." <>
            _,
        buttons: button_labels(["Help Centre menu", "Topics for you", "Main menu"])
      })

      # |> flow_finished()
    end
  end

  describe "Search MyHealth:" do
    defp setup_flow_search_myhealth(flow) do
      FlowTester.start(flow)
      |> FlowStep.clear_messages()
      |> FlowTester.send(button_label: "Search MyHealth")
      |> receive_message(%{
        text: "Let's find you the information you need" <> _
      })
    end

    @tag aaq_urgency_score: "1.0"
    test "test inbound check urgent", %{flow: flow} do
      setup_flow_search_myhealth(flow)
      |> FlowTester.send("xyz")
      |> receive_message(%{
        text:
          "If you're in a health emergency, please contact emergency services or go to the nearest health facility immediately. \r\n\r\n👇🏽 What do you want to do?" <>
            _
      })
    end

    test "test inbound check not urgent", %{flow: flow} do
      setup_flow_search_myhealth(flow)
      |> FlowTester.send("My tummy hurts")
      |> receive_message(%{
        text:
          "🤖 Here are some topics you might find helpful.\r\n\r\n1. Baby's first teeth\n2. Vaginal discharge in pregnancy\n3. Baby's growth - Developmental milestones\n4. Toothache in pregnancy\n5. Latching baby to the breast\r\n6. None of these are helpful – speak to [health agent]\r\n\r\n👇🏽 Please reply with the number of your selection."
      })
    end
  end
end
