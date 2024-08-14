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
      |> FlowTester.set_contact_properties(%{"year_of_birth" => "1988", "province" => "Western Cape", "area_type" => "", "gender" => "male"})
      |> FlowTester.set_contact_properties(%{}) # Personal Information
      |> FlowTester.set_contact_properties(%{}) # Daily Life
      |> FlowTester.start()
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Basic information 3/4")
        step
      end.()
      |> receive_message(%{
        text: "Your profile is already 30% complete" <> _,
        buttons: button_labels(["Continue", "Why?"])
      })
    end
  end


end
