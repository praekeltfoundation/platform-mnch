deps = [{:flow_tester, path: Path.join([__DIR__, "flow_tester"]), env: :dev}]
Mix.install(deps, config_path: :flow_tester, lockfile: :flow_tester)
ExUnit.start()

defmodule OnboardingBasicProfileQuestionsTest do
  use FlowTester.Case

  alias ContentRepoWebhookHandler, as: FakeCR

  defp flow_path(flow_name), do: Path.join([__DIR__, "json", flow_name <> ".json"])

  def setup_fake_contentrepo(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCR, %FakeCR.Config{auth_token: auth_token}})
    # Add some content.
    error_pg_button = %ContentPage{
      slug: "mnch_onboarding_error_handling_button",
      title: "error",
      parent: "test",
      wa_messages: [%WAMsg{message: "This is the error."}]
    }

    error_pg_list = %ContentPage{
      slug: "mnch_onboarding_error_handling_list_message",
      title: "error",
      parent: "test",
      wa_messages: [%WAMsg{message: "This is the error."}]
    }

    error_pg_year = %ContentPage{
      slug: "mnch_onboarding_unrecognised_year",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "Sorry, I didn’t get that – let's try again.\n\n👇🏽 Please reply with a specific year, like 2008 or 1998."
        }
      ]
    }

    mnch_onboarding_q_age = %ContentPage{
      slug: "mnch_onboarding_q_age",
      title: "Q_age",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "If there are any questions you don’t want to answer right now, reply `Skip`\n\n👤 *What year were you born in?*"
        }
      ]
    }

    mnch_onboarding_q_province = %ContentPage{
      slug: "mnch_onboarding_q_province",
      title: "Q_province",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Which province do you call home?*",
          list_items: [
            %ListItem{value: "{province_name_01}"},
            %ListItem{value: "{province_name_02}"},
            %ListItem{value: "{province_name_03}"},
            %ListItem{value: "{province_name_04}"},
            %ListItem{value: "{province_name_05}"},
            %ListItem{value: "{province_name_06}"},
            %ListItem{value: "{province_name_07}"},
            %ListItem{value: "Why do you ask?"}
          ]
        }
      ]
    }

    mnch_onboarding_q_area_type = %ContentPage{
      slug: "mnch_onboarding_q_area_type",
      title: "Q_area_type",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
          buttons: [
            %NextBtn{title: "Big town/City"},
            %NextBtn{title: "Countryside/Village"}
          ]
        }
      ]
    }

    mnch_onboarding_q_gender = %ContentPage{
      slug: "mnch_onboarding_q_gender",
      title: "Q_gender",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *What gender do you identify as?*",
          buttons: [
            %NextBtn{title: "Male"},
            %NextBtn{title: "Female"},
            %NextBtn{title: "Other"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCR.add_pages(wh_pid, [
               %Index{slug: "pages", title: "Pages"},
               %Index{slug: "test", title: "test"},
               error_pg_button,
               error_pg_list,
               error_pg_year,
               mnch_onboarding_q_age,
               mnch_onboarding_q_province,
               mnch_onboarding_q_area_type,
               mnch_onboarding_q_gender
             ])

    # Return the adapter.
    FakeCR.adapter(wh_pid)
  end

  defp setup_flow() do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")

    flow_path("onboarding_p2")
    |> FlowTester.from_json!()
    |> FlowTester.set_wh_adapter(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/",
      setup_fake_contentrepo(auth_token)
    )
    # |> FlowTester.allow_wh_http("https://content-repo-api-qa.prk-k8s.prd-p6t.org/")
    |> FlowTester.set_config(%{"contentrepo_token" => auth_token})
  end

  test "Onboarding p2 Basic Profile Questions" do
    setup_flow()

    # The flow starts with a question about the year of birth.
    |> FlowTester.start_flow!()
    |> block_matches(%{
      name: "year_of_birth",
      type: "MobilePrimitives.OpenResponse"
    })
    |> receive_messages([
      %{
        text:
          "If there are any questions you don’t want to answer right now, reply `Skip`\n\n👤 *What year were you born in?*"
      }
    ])

    # A non-numeric year is rejected.
    |> FlowTester.continue_flow!("NotAYear")
    |> block_matches(%{
      name: "year_of_birth",
      type: "MobilePrimitives.OpenResponse"
    })
    |> contact_matches(%{"year_of_birth" => ""})
    |> receive_messages([
      %{
        text:
          "Sorry, I didn’t get that – let's try again.\n\n👇🏽 Please reply with a specific year, like 2008 or 1998."
      }
    ])

    # A numeric year is accepted and stored in the contact, after which we ask
    # about the province.
    |> FlowTester.continue_flow!("1999")
    |> block_matches(%{
      name: "province",
      type: "Io.Turn.DynamicSelectOneResponse"
    })
    |> contact_matches(%{"year_of_birth" => "1999", "province" => ""})
    |> receive_messages([
      %{
        text: "👤 *Which province do you call home?*",
        list_header: "Province",
        list_items: [
          ["{province_name_01}", "{province_name_01}"],
          ["{province_name_02}", "{province_name_02}"],
          ["{province_name_03}", "{province_name_03}"],
          ["{province_name_04}", "{province_name_04}"],
          ["{province_name_05}", "{province_name_05}"],
          ["{province_name_06}", "{province_name_06}"],
          ["{province_name_07}", "{province_name_07}"],
          ["Why do you ask?", "Why do you ask?"]
        ]
      }
    ])

    # The selected province is stored in the contact, after which we ask about
    # the area type.
    |> FlowTester.continue_flow!(button_label: "{province_name_06}")
    |> block_matches(%{
      name: "area_type",
      type: "MobilePrimitives.SelectOneResponse"
    })
    |> contact_matches(%{"province" => "{province_name_06}", "area_type" => ""})
    |> receive_messages([
      %{
        text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
        list_header: nil,
        list_items: [
          ["@button_labels[0]", "Big town/City"],
          ["@button_labels[1]", "Countryside/Village"]
        ]
      }
    ])

    # The selected area type is stored in the contact, after which we ask about
    # gender if we don't already have that on the contact.
    |> FlowTester.continue_flow!(button_label: "Big town/City")
    |> block_matches(%{
      name: "gender",
      type: "MobilePrimitives.SelectOneResponse"
    })
    |> contact_matches(%{"area_type" => "big town / city", "gender" => ""})
    |> receive_messages([
      %{
        text: "👤 *What gender do you identify as?*",
        list_header: nil,
        list_items: [
          ["@button_labels[0]", "Male"],
          ["@button_labels[1]", "Female"],
          ["@button_labels[2]", "Other"]
        ]
      }
    ])

    # The selected gender is stored in the contact, after which the flow ends.
    |> FlowTester.continue_flow!(button_label: "Male")
    |> contact_matches(%{"gender" => "male"})
    |> flow_ends()
  end

  test "Skip gender if already provided" do
    setup_flow()
    |> FlowTester.set_contact_fields(%{"gender" => "male"})
    |> FlowTester.start_flow!()
    |> FlowTester.continue_flow!("1999")
    |> FlowTester.continue_flow!(button_label: "{province_name_06}")
    |> FlowTester.continue_flow!(button_label: "Big town/City")
    |> flow_ends()
  end
end
