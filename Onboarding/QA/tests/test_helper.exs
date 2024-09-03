defmodule Onboarding.QA.Helpers do

  def init_contact_fields(context) do
    context
    |> init_base()
    |> init_intro()
    |> init_basic_info()
    |> init_personal_info()
    |> init_daily_life()
    |> init_hcw_info()
  end

  # Technically this should be all the profile fields in Turn, but we can fill them in as we go along
  defp init_base(context) do
    context |> FlowTester.set_contact_properties(%{"profile_completion" => "", "checkpoint" => ""})
  end

  # The contact fields that get filled in the intro flow
  defp init_intro(context) do
    context |> FlowTester.set_contact_properties(%{"language" => "eng", "opted_in" => "false", "intent" => "create profile", "data_preference" => "all"})
  end

  # The contact fields that get filled in the basic info flow
  defp init_basic_info(context) do
    context |> FlowTester.set_contact_properties(%{"year_of_birth" => "", "province" => "", "area_type" => "", "gender" => ""})
  end

  # The contact fields that get filled in the personal info flow
  defp init_personal_info(context) do
    context |> FlowTester.set_contact_properties(%{"relationship_status" => "", "education" => "", "socio_economic" => "", "other_children" => ""})
  end

  # The contact fields that get filled in the DMA Form flow
  defp init_daily_life(context) do
    context |> FlowTester.set_contact_properties(%{"dma_01" => "", "dma_02" => "", "dma_03" => "", "dma_04" => "", "dma_05" => ""})
  end

  # The contact fields that get filled in the HCW Profile flow
  defp init_hcw_info(context) do
    context |> FlowTester.set_contact_properties(%{"occupational_role" => "", "facility_type" => "", "professional_support" => ""})
  end

  def basic_profile_flow_uuid(), do: "26e0c9e4-6547-4e3f-b9f4-e37c11962b6d"

  def personal_info_uuid(), do: "61a880e4-cf7b-47c5-a047-60802aaa7975"

  def daily_life_uuid(), do: "690a9ffd-db6d-42df-ad8f-a1e5b469a099"

  def opt_in_reminder_uuid(), do: "537e4867-eb26-482d-96eb-d4783828c622"

  def profile_hcw_uuid(), do: "38cca9df-21a1-4edc-9c13-5724904ca3c3"

  def handle_basic_profile_flow(step, opts \\ []), do: FlowTester.handle_child_flow(step, basic_profile_flow_uuid(), fn step ->
    FlowTester.set_contact_properties(step, %{
      "year_of_birth" => Keyword.get(opts, :year_of_birth, "1988"),
      "province" => Keyword.get(opts, :province, "Western Cape"),
      "area_type" => Keyword.get(opts, :area_type, ""),
      "gender" => Keyword.get(opts, :gender, "male")})
  end)

  def handle_personal_info_flow(step, opts \\ []),
    do: FlowTester.handle_child_flow(step, personal_info_uuid(), fn step ->
    FlowTester.set_contact_properties(step, %{
      "relationship_status" => Keyword.get(opts, :relationship_status, ""),
      "education" => Keyword.get(opts, :education, ""),
      "socio_economic" => Keyword.get(opts, :socio_economic, ""),
      "other_children" => Keyword.get(opts, :other_children, "")
      })
  end
    )

  def handle_daily_life_flow(step, opts \\ []), do: FlowTester.handle_child_flow(step, daily_life_uuid(), fn step ->
    FlowTester.set_contact_properties(step, %{
      "dma_01" => Keyword.get(opts, :dma_01, "answer"),
      "dma_02" => Keyword.get(opts, :dma_02, ""),
      "dma_03" => Keyword.get(opts, :dma_03, ""),
      "dma_04" => Keyword.get(opts, :dma_04, ""),
      "dma_05" => Keyword.get(opts, :dma_05, "")})
  end)

  def handle_opt_in_reminder_flow(step), do: FlowTester.handle_child_flow(step, opt_in_reminder_uuid())

  def handle_profile_hcw_flow(step, opts \\ []), do: FlowTester.handle_child_flow(step, profile_hcw_uuid(), fn step ->
    FlowTester.set_contact_properties(step, %{
      "occupational_role" => Keyword.get(opts, :occupational_role, ""),
      "facility_type" => Keyword.get(opts, :facility_type, ""),
      "professional_support" => Keyword.get(opts, :professional_support, "")})
  end)

  defmodule Macros do
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
  end

end
