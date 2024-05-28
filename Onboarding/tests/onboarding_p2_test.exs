deps = [{:flow_tester, path: Path.join([__DIR__, "flow_tester"]), env: :dev}]
Mix.install(deps, config_path: :flow_tester, lockfile: :flow_tester)
ExUnit.start()

defmodule BrowsableFaqsTest do
  use FlowTester.Case

  defp flow_path(flow_name), do: Path.join([__DIR__, "flows", flow_name <> ".json"])

  def setup_fake_contentrepo(auth_token) do
    # Start the handler.
    # {:ok, wh_pid} = start_supervised({ContentRepoWebhookHandler, {auth_token}})
    wh_pid = start_link_supervised!({ContentRepoWebhookHandler, {auth_token}})
    # Add some content.
    error_pg_button = %ContentPage{
      slug: "mnch_onboarding_error_handling_button", title: "error",  parent_slug: "test",
      wa_messages: [%WAMsg{message: "This is the error."}]
    }
    error_pg_list = %ContentPage{
      slug: "mnch_onboarding_error_handling_list_message", title: "error",  parent_slug: "test",
      wa_messages: [%WAMsg{message: "This is the error."}]
    }
    error_pg_year = %ContentPage{
      slug: "mnch_onboarding_unrecognised_year", title: "error",  parent_slug: "test",
      wa_messages: [%WAMsg{message: "Error, What year were you born in?"}]
    }
    mnch_onboarding_q_age = %ContentPage{
      slug: "mnch_onboarding_q_age", title: "Q_age", parent_slug: "test",
      wa_messages: [
        %WAMsg{
          message: "What year were you born in?"
        }
      ]
    }
    mnch_onboarding_q_province_why = %ContentPage{
      slug: "mnch_onboarding_q_province_why", title: "Q_province", parent_slug: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 Which province do you call home?"
        }
      ]
    }
    assert :ok = ContentRepoWebhookHandler.add_pages(wh_pid, [
      %Index{slug: "pages", title: "Pages"},
      %Index{slug: "test", title: "test"},
      error_pg_button,
      error_pg_list,
      error_pg_year,
      mnch_onboarding_q_age,
      mnch_onboarding_q_province_why,
    ])
    # Return the adapter.
    ContentRepoWebhookHandler.adapter(wh_pid)
  end

  test "onboarding p1 high level example" do
    auth_token = "f8d2e55d693bf360531a04335007698ad5da21a6"

    flow_start =
      flow_path("onboarding_p2")
      |> FlowTester.from_json!()
      # |> FlowTester.set_wh_adapter(
      #   "https://content-repo-api-qa.prk-k8s.prd-p6t.org/",
      #   setup_fake_contentrepo(auth_token)
      # )
      |> FlowTester.allow_wh_http("https://content-repo-api-qa.prk-k8s.prd-p6t.org/")
      |> FlowTester.set_config(%{"contentrepo_token" => auth_token})

    flow_start
    |> FlowTester.run_until_next_input!()
    |> block_matches(%{
      name: "year_of_birth",
      type: "MobilePrimitives.OpenResponse",
    })
    |> receive_messages([%{
      text: "If there are any questions you don’t want to answer right now, reply `Skip`\n\n👤 *What year were you born in?*" ,
    }])
    |> waiting_for_input(true)
    |> FlowTester.run_until_next_input!("NotAYear")
    |> block_matches(%{
      name: "year_of_birth",
      type: "MobilePrimitives.OpenResponse",
    })
    |> receive_messages([%{
      text: "Sorry, I didn’t get that – let's try again.\n\n👇🏽 Please reply with a specific year, like 2008 or 1998." ,
    }])
    |> waiting_for_input(true)
    |> FlowTester.run_until_next_input!("1999")
    |> block_matches(%{
      name: "province",
      type: "Io.Turn.DynamicSelectOneResponse",
    })
    |> receive_messages([%{
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
      ],
    }])
    |> waiting_for_input(true)
    |> FlowTester.run_until_next_input!("{province_name_06}")
    |> block_matches(%{
      name: "area_type",
      type: "MobilePrimitives.SelectOneResponse",
    })
    |> receive_messages([%{
      text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
      list_header: nil,
      list_items: [
        ["Big town/City", "Big town/City"],
        ["Countryside/Village", "Countryside/Village"]
      ],
    }])
    |> waiting_for_input(true)
    |> FlowTester.run_until_next_input!("urban")
    |> block_matches(%{
      name: "gender",
      type: "MobilePrimitives.SelectOneResponse",
    })
    # |> receive_messages([%{
    #   text: "👤 *Do you live in a big town or city, or in the countryside or a small village?*",
    #   list_header: nil,
    #   list_items: [
    #     ["Big town/City", "Big town/City"],
    #     ["Countryside/Village", "Countryside/Village"]
    #   ],
    # }])
    # |> FlowTester.run_until_end!("1")
    # |> flow_ends()
  end
end
