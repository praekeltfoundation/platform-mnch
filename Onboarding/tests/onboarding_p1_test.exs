deps = [{:flow_tester, path: Path.join([__DIR__, "flow_tester"]), env: :dev}]
Mix.install(deps, config_path: :flow_tester, lockfile: :flow_tester)
ExUnit.start()

defmodule BrowsableFaqsTest do
  use FlowTester.Case

  alias ContentRepoWebhookHandler, as: FakeCR

  defp flow_path(flow_name), do: Path.join([__DIR__, "json", flow_name <> ".json"])

  def setup_fake_contentrepo(auth_token) do
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCR, %FakeCR.Config{auth_token: auth_token}})
    # Add some content.
    error_pg = %ContentPage{
      slug: "error", title: "error",  parent: "test",
      wa_messages: [%WAMsg{message: "This is the error."}]
    }
    welcome_pg = %ContentPage{
      slug: "mnch_onboarding_welcome", title: "Welcome", parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Welcome to {MyHealth}*",
          buttons: [
            %NextBtn{title: "Getstarted"},
            %NextBtn{title: "Change my language"},
          ]
        }
      ]
    }
    pp_pg = %ContentPage{
      slug: "mnch_onboarding_pp_document", title: "Privacy Policy", parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Your information is safe and won't be shared* 🔒",
          buttons: [
            %NextBtn{title: "Yes, I accept ✅"},
            %NextBtn{title: "No, I don't accept"},
            %NextBtn{title: "Read a summary"},
          ]
        }
      ]
    }
    assert :ok = FakeCR.add_pages(wh_pid, [
      %Index{slug: "pages", title: "Pages"},
      %Index{slug: "test", title: "test"},
      error_pg,
      welcome_pg,
      pp_pg
    ])
    # Return the adapter.
    FakeCR.adapter(wh_pid)
  end

  test "Onboarding p1 Intro & Welcome" do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")

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
      list_items: [["@button_labels[0]", "Getstarted"], ["@button_labels[1]", "Change my language"]]
    }])

    |> FlowTester.run_until_next_input!(button_label: "Getstarted")
    # |> FlowTester.run_until_next_input!(button_index: 0)
    |> block_matches(%{
      name: "privacy_policy",
      type: "MobilePrimitives.SelectOneResponse",
    })
    |> receive_messages([%{
      text: "*Your information is safe and won't be shared* 🔒",
      list_items: [
        ["@button_labels[0]", "Yes, I accept ✅"],
        ["@button_labels[1]", "No, I don't accept"],
        ["@button_labels[2]", "Read a summary"]
      ]
    }])

    # TODO: Continue until we reach the end.
    assert false
  end

end
