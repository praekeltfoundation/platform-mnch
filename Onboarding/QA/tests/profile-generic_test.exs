deps = [{:flow_tester, path: Path.join([__DIR__, "..", "..", "..", "flow_tester"]), env: :dev}]
Mix.install(deps, config_path: :flow_tester, lockfile: :flow_tester)
ExUnit.start()

defmodule ProfileGenericTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  defp flow_path(flow_name), do: Path.join([__DIR__, "..","flows", flow_name <> ".json"])

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  #defp real_or_fake_cms(step, base_url, auth_token, :fake),
  #  do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp setup_flow() do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    flow_path("profile-generic")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
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

  describe "profile generic" do
    test "30% complete" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"year_of_birth" => "1988", "province" => "Western Cape", "area_type" => "", "gender" => "male"}) # Basic Information
      |> FlowTester.set_contact_properties(%{"relationship_status" => "", "education" => "", "socio_economic" => "", "other_children" => ""}) # Personal Information
      |> FlowTester.set_contact_properties(%{}) # Daily Life
      |> FlowTester.start()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
    end

    test "30% complete -> why" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"year_of_birth" => "1988", "province" => "Western Cape", "area_type" => "", "gender" => "male"}) # Basic Information
      |> FlowTester.set_contact_properties(%{"relationship_status" => "", "education" => "", "socio_economic" => "", "other_children" => ""}) # Personal Information
      |> FlowTester.set_contact_properties(%{}) # Daily Life
      |> FlowTester.start()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Why?")
      |> receive_message(%{
        text: "ℹ️ Our team of experts has put together" <> _,
        buttons: button_labels(["Yes, let's go", "Not right now"])
      })
    end

    test "100% complete - all complete" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"year_of_birth" => "1988", "province" => "Western Cape", "area_type" => "something", "gender" => "male"}) # Basic Information
      |> FlowTester.set_contact_properties(%{"relationship_status" => "married", "education" => "degree", "socio_economic" => "something", "other_children" => "0"}) # Personal Information
      |> FlowTester.set_contact_properties(%{"name" => "Severus"})
      |> FlowTester.set_contact_properties(%{"opted_in" => "true"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Continue")
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "*Name:* Severus")
        assert String.contains?(msg.text, "*Basic info:* ✅")
        assert String.contains?(msg.text, "*Personal info:* ✅")
        assert String.contains?(msg.text, "*Get important messages:* ✅")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\n\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "100% complete - incomplete basic info" do
      setup_flow()
      |> FlowTester.set_contact_properties(%{"year_of_birth" => "1988", "province" => "Western Cape", "area_type" => "", "gender" => "male"}) # Basic Information
      |> FlowTester.set_contact_properties(%{"relationship_status" => "", "education" => "", "socio_economic" => "", "other_children" => ""}) # Personal Information
      |> FlowTester.set_contact_properties(%{}) # Daily Life
      |> FlowTester.set_contact_properties(%{"name" => "Severus"})
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
      |> FlowTester.send(button_label: "Continue")
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "*Name:* Severus")
        assert String.contains?(msg.text, "*Basic info:* 3/4")
        assert String.contains?(msg.text, "*Personal info:* 0/4")
        assert String.contains?(msg.text, "*Get important messages:* ❌")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\n\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end
  end


end
