deps = [{:flow_tester, path: Path.join([__DIR__, "flow_tester"]), env: :dev}]
Mix.install(deps, config_path: :flow_tester, lockfile: :flow_tester)
ExUnit.start()

defmodule BrowsableFaqsTest do
  use FlowTester.Case

  defp flow_path(flow_name), do: Path.join([__DIR__, "flows", flow_name <> ".json"])

  def setup_fake_contentrepo(auth_token) do
    # Start the handler.
    {:ok, wh_pid} = start_supervised({ContentRepoWebhookHandler, {auth_token}})
    # Add some content.
    error_pg = %ContentPage{
      slug: "error", title: "error",  parent_slug: "test",
      wa_messages: [%WAMsg{message: "This is the error."}]
    }
    welcome_pg = %ContentPage{
      slug: "mnch_onboarding_welcome", title: "Welcome", parent_slug: "test",
      wa_messages: [
        %WAMsg{
          message: "*Welcome to {MyHealth}*",
          buttons: [
            %Btn{title: "Getstarted"},
            %Btn{title: "Change my language"},
          ]
        }
      ]
    }
    pp_pg = %ContentPage{
      slug: "mnch_onboarding_pp_document", title: "Privacy Policy", parent_slug: "test",
      wa_messages: [
        %WAMsg{
          message: "*Your information is safe and won't be shared* 🔒",
          buttons: [
            %Btn{title: "Yes, I accept ✅"},
            %Btn{title: "No, I don't accept"},
            %Btn{title: "Read a summary"},
          ]
        }
      ]
    }
    assert :ok = ContentRepoWebhookHandler.add_pages(wh_pid, [
      %Index{slug: "pages", title: "Pages"},
      %Index{slug: "test", title: "test"},
      error_pg,
      welcome_pg,
      pp_pg
    ])
    # Return the adapter.
    ContentRepoWebhookHandler.adapter(wh_pid)
  end

  test "browsable_faqs high level example" do
    auth_token = "CRauthTOKEN123"

    flow_start =
      flow_path("onboarding_p1")
      |> FlowTester.from_json!()
      |> FlowTester.set_wh_adapter(
        "https://content-repo-api-qa.prk-k8s.prd-p6t.org/",
        setup_fake_contentrepo(auth_token)
      )
      # |> FlowTester.allow_wh_http("https://content-repo-api-qa.prk-k8s.prd-p6t.org/")
      |> FlowTester.set_config(%{"contentrepo_token" => auth_token})

    flow_start
    |> FlowTester.run_until_next_input!("hi")
    |> block_matches(%{
      name: "welcome_message",
      type: "MobilePrimitives.SelectOneResponse",
    })
    |> receive_messages([%{
      text: "*Welcome to {MyHealth}*",
      list_items: [["Getstarted", "Getstarted"], ["Change my language", "Change my language"]]
    }])
    |> FlowTester.run_until_next_input!("Getstarted")
    |> block_matches(%{
      name: "privacy_policy",
      type: "MobilePrimitives.SelectOneResponse",
    })
    # |> receive_messages([%{
    #   text: "*Welcome to {MyHealth}*",
    #   list_items: [["Get started", "Get started"], ["Change my language", "Change my language"]]
    # }])
  end

end
