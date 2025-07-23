<!-- { section: "edb26c8a-ba94-4612-a8b1-532f5c603c70", x: -840, y: -552} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "ihaf")

```

<!-- { section: "86c62233-e433-4d7f-980c-a45054386bf5", x: -312, y: -552} -->

```stack
card ScheduleQueryRating, then: BranchOrigin do
  cancel_scheduled_stacks("dbf8e71b-d2bb-4c08-829c-925d53752bbf")
  log("Cancelling previously scheduled stack `dbf8e71b-d2bb-4c08-829c-925d53752bbf`")
  schedule_stack("dbf8e71b-d2bb-4c08-829c-925d53752bbf", in: 900)
  log("Scheduled stack `dbf8e71b-d2bb-4c08-829c-925d53752bbf` to run in 2 minutes")
end

```

<!-- { section: "babb9dd9-952e-42d5-95b4-2332fc5b832c", x: 336, y: -576} -->

```stack
card BranchOrigin, "BranchOrigin", code_generator: "CONDITIONALS" do
  then(RTOEmergency when has_only_phrase(contact.route_to_operator_origin, "emergency"))

  then(
    RTOSearchMyHealth
    when has_only_phrase(contact.route_to_operator_origin, "search_myhealth")
  )

  then(RTOTechSupport when has_only_phrase(contact.route_to_operator_origin, "tech_support"))

  then(
    RTOFailedAttempts
    when has_only_phrase(contact.route_to_operator_origin, "failed_attempts")
  )

  then(RESERVED_DEFAULT_CARD)
end

```

<!-- { section: "1cf71da1-b3d7-4f72-9338-f3f0b9d3b0a4", x: 1608, y: -552} -->

```stack
card HANDOVER_STARTS_1, "HANDOVER_STARTS_1", code_generator: "HANDOVER_STARTS" do
  send_content("b334e46e-73dd-36a1-a366-7a3fa4d691a4", true)
  then(HANDOVER_HOLD_81536c)
end

card HANDOVER_HOLD_81536c, "HANDOVER_HOLD_81536c", code_generator: "HANDOVER_HOLD" do
  send_content("6a04986a-edbc-0e6d-525a-0b19a7237705")
  add_label("Requested help")
end

```

<!-- { section: "760c9b47-a5ee-4abf-8323-bc747cc79d31", x: 1176, y: -528} -->

All these code blocks go to HANDOVER_STARTS_1

<!-- { section: "5de01d7d-ceb1-43c3-82d3-2ff46b5d5e11", x: -864, y: -1224} -->

# Notes

Please expand this note to view the full notes on this flow, or you can scroll through by hovering over it

## Contact fields

* `route_to_operator_origin`, this field keeps track of where the user came from, before being handed over to the agent

## Flow results

* `route_to_operator`, Get set to `yes` before the user gets sent to the operator

## Connections to other stacks

* `HelpCentre: Scheduled - Query rating` we schedule this before doing the handover, to re-engage if the operator fails to run the wrap up flow after the call

## Global variables

The following variable(s) are set in the `settings` global dictionary

* `contentrepo_qa_token` used to authenticate the API calls pulling content from CMS

## Content dependencies

The following 4 pieces of content is needed, to show the user a message before handover, depending on where they came from

* `plat_help_route_to_operator_emergency`,
* `plat_help_route_to_operator_search_myhealth`,
* `plat_help_route_to_operator_tech_support`,
* `plat_help_route_to_operator_emergency`,

<!-- { section: "318089d3-89e1-4d72-97e5-a2b1b14a32f5", x: 792, y: -1056} -->

```stack
card RTOEmergency, then: HANDOVER_STARTS_1 do
  update_contact(route_to_operator_origin: "")
  write_result("route_to_operator", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_route_to_operator_emergency/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text

  text("@msg")
end

```

<!-- { section: "02ebcbd2-c2fc-4b94-9a3a-72ab13cad462", x: 792, y: -720} -->

```stack
card RTOSearchMyHealth, then: HANDOVER_STARTS_1 do
  update_contact(route_to_operator_origin: "")
  write_result("route_to_operator", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_route_to_operator_search_myhealth/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text
  substituted_msg = substitute(msg, "{xxx}", "'@contact.route_to_operator_search_text'")

  text("@substituted_msg")
end

```

<!-- { section: "307f9ea2-9234-4120-9e0c-493f03d057f1", x: 792, y: -384} -->

```stack
card RTOTechSupport, then: HANDOVER_STARTS_1 do
  update_contact(route_to_operator_origin: "")
  write_result("route_to_operator", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_route_to_operator_tech_support/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text
  substituted_msg = substitute(msg, "{xxx}", "'@contact.route_to_operator_search_text'")

  text("@substituted_msg")
end

```

<!-- { section: "55d5c1d4-2cf0-4280-8240-970729b447ab", x: 792, y: -72} -->

```stack
card RTOFailedAttempts, then: HANDOVER_STARTS_1 do
  update_contact(route_to_operator_origin: "")
  write_result("route_to_operator", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_route_to_operator_failed_attempts/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text
  text("@msg")
end

```

<!-- { section: "e0d16026-c9a2-4573-8e94-cabe04e0d1d7", x: -1000, y: 0} -->

```stack
card RESERVED_DEFAULT_CARD, "RESERVED_DEFAULT_CARD", code_generator: "RESERVED_DEFAULT_CARD" do
  # RESERVED_DEFAULT_CARD
end

```