defmodule IntroHumanAgentTest do
  use FlowTester.Case
  alias FlowTester.WebhookHandler, as: WH
  # alias FlowTester.FlowStep
  defp flow_path(flow_name), do: Path.join([__DIR__, "..", "flows_json", flow_name <> ".json"])

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.
    emergency = %ContentPage{
      slug: "plat_help_route_to_operator_emergency",
      title: "Route to operator emergency",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "We will let the helpdesk know that this is an emergency situation"}
      ]
    }

    search_myhealth = %ContentPage{
      slug: "plat_help_route_to_operator_search_myhealth",
      title: "Route to operator Search MyHealth",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "You searched for {xxx}"}
      ]
    }

    tech_support = %ContentPage{
      slug: "plat_help_route_to_operator_tech_support",
      title: "Route to operator Tech support",
      parent: "test",
      wa_messages: [
        %WAMsg{message: "You searched for {xxx}"}
      ]
    }

    failed_attempts = %ContentPage{
      slug: "plat_help_route_to_operator_failed_attempts",
      title: "Route to operator failed attempts",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message:
            "It seems that the bot has been unable to assist you so we will be routing you to a human helpdesk operator to try to resolve your issue"
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               emergency,
               tech_support,
               failed_attempts,
               search_myhealth
             ])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp set_config(step) do
    step
    |> FlowTester.set_global_dict("settings", %{
      "working_hours_start_hour" => "5",
      "working_hours_end_hour" => "19",
      "working_hours_start_day" => "2",
      "working_hours_end_day" => "6"
    })
  end

  defp setup_flow() do
    # When talking to real contentrepo, get the auth token from the CMS_AUTH_TOKEN envvar.
    auth_token = System.get_env("CMS_AUTH_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow_path("intro-human-agent")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("settings", %{"contentrepo_qa_token" => auth_token})
    |> set_config()
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

  describe "get pre handover message:" do
    test "emergency" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "emergency"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "We will let the helpdesk know that this is an emergency situation" <> _
      })
    end

    test "search myhealth" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "search_myhealth"})
      |> FlowTester.set_contact_properties(%{
        "route_to_operator_search_text" => "mock search myhealth query"
      })
      |> FlowTester.start()
      |> receive_message(%{
        text: "You searched for 'mock search myhealth query'" <> _
      })
    end

    test "tech support" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "tech_support"})
      |> FlowTester.set_contact_properties(%{
        "route_to_operator_search_text" => "mock tech support query"
      })
      |> FlowTester.start()
      |> receive_message(%{
        text: "You searched for 'mock tech support query'" <> _
      })
    end

    test "failed attempts" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"route_to_operator_origin" => "failed_attempts"})
      |> FlowTester.start()
      |> receive_message(%{
        text:
          "It seems that the bot has been unable to assist you so we will be routing you to a human helpdesk operator to try to resolve your issue" <>
            _
      })
    end
  end
end
