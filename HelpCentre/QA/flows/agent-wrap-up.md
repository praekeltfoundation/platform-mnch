# Agent wrap up

This flow follows is meant to be run manually by the helpcentre agent, directly after they ended the interaction with the user.

If run it cancels the scheduled flow 'Scheduled Query Rating', as we'll ask those questions in this flow.

## Contact fields

* `nav_bypass`, This is a mechanism to bypass the main menu and send the user straight to a sub section

## Flow results

* `callback_requested`, Get set to `yes` once the user requests a callback
* `operator_resolved_query`, Gets set to either `yes` or `no` depending on whether the operator was able to resolve the query or not

## Connections to other stacks

* `HelpCentre: Intro to HelpCentre`
* `HC: Scheduled - Callback follow up`

## Global variables

The following variable(s) are set in the `settings` global dictionary

* `contentrepo_qa_token` used to auth api calls

## Content dependencies

* `mnch_onboarding_error_handling_button`
* `plat_help_query_successful`
* `plat_help_agent_helpful_response`
* `plat_help_agent_unsuccessful_response`
* `plat_help_call_back_response`
* `plat_help_call_back_confirmation`
* `plat_help_agent_call_back_number_confirmation`
* `plat_help_agent_call_back_number_update`
* `plat_help_agent_contact_number_save`
* `plat_help_bot_to_agent_handover_waiting_room`

# Init and FetchError messages

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "aiw")
# interaction_timeout(60)

card FetchError, then: CheckForNavBypass do
  # Fetch and store the error message, so that we don't need to do it for every error card

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_button/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  button_error_text = page.body.messages[0].text
end

card CheckForNavBypass when contact.navbypass == "BotToAgentHandoverWaitingRoom",
  then: BotToAgentHandoverWait do
  log("Bypassing Main Menu - Goto BotToAgentHandoverWaitingRoom")
  update_contact(navbypass: "")
end

card CheckForNavBypass when contact.navbypass == "UnresolvedWhatNext", then: UnresolvedWhatNext do
  log("Bypassing Main Menu - Goto UnresolvedWhatNext")
  update_contact(navbypass: "")
end

card CheckForNavBypass when contact.navbypass == "AgentHelpfulResponse",
  then: AgentHelpfulResponse do
  log("Bypassing Main Menu - Goto AgentHelpfulResponse")
  update_contact(navbypass: "")
end

card CheckForNavBypass when contact.navbypass == "UseAnotherNumber",
  then: UseAnotherNumber do
  log("Bypassing Main Menu - Goto UseAnotherNumber")
  update_contact(navbypass: "")
end

card CheckForNavBypass, then: CheckResolution do
  log("Going to CheckResolution")
end

card GotoMainMenu do
  log("Going to Main Menu")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

card GotoSearchMyHealth do
  log("Going to SearchMyHealth")
  update_contact(navbypass: "SearchMyHealth")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

```

# Check Resolution

<!-- { section: "577e1f65-2430-4ceb-a9b2-5f20c771ea4d", x: 0, y: 0} -->

```stack
card CheckResolution, then: CheckResolutionError do
  cancel_scheduled_stacks("dbf8e71b-d2bb-4c08-829c-925d53752bbf")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_query_successful/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    AgentHelpfulResponse: "@button_labels[0]",
    UnresolvedWhatNext: "@button_labels[1]"
  ) do
    text("@msg")
  end
end

card CheckResolutionError, then: CheckResolutionError do
  buttons(
    AgentHelpfulResponse: "@button_labels[0]",
    UnresolvedWhatNext: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Agent Helpful Response

```stack
card AgentHelpfulResponse do
  write_result("operator_resolved_query", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_agent_helpful_response/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  agent_helful_msg = page.body.messages[0].text
  text("@agent_helful_msg")
end

```

# Unresolved what next

```stack
card UnresolvedWhatNext, then: WhatNextError do
  write_result("operator_resolved_query", "no")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_agent_unsuccessful_response/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  what_next_msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    CallMeBack: "@button_labels[0]",
    GotoSearchMyHealth: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@what_next_msg")
  end
end

card WhatNextError, then: WhatNextError do
  buttons(
    CallMeBack: "@button_labels[0]",
    GotoSearchMyHealth: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Call me back

```stack
card CallMeBack, then: CallMeBackError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_call_back_response/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    CallMeBackConfirm: "@button_labels[0]",
    GotoMainMenu: "@button_labels[1]"
  ) do
    text("@msg")
  end
end

card CallMeBackConfirm, then: ChooseNumberToCall do
  write_result("callback_requested", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_call_back_confirmation/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  msg = page.body.messages[0].text
  text("@msg")
end

card CallMeBackError, then: CallMeBackError do
  buttons(
    CallMeBackConfirm: "@button_labels[0]",
    GotoMainMenu: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Choose number to call

```stack
card ChooseNumberToCall, then: ChooseNumberToCallError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_agent_call_back_number_confirmation/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  choose_number_msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    UseThisNumber: "@button_labels[0]",
    UseAnotherNumber: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@choose_number_msg")
  end
end

card UseThisNumber, then: BotToAgentHandoverWait do
  log("UseThisNumber")
end

card ChooseNumberToCallError, then: ChooseNumberToCallError do
  buttons(
    UseThisNumber: "@button_labels[0]",
    UseAnotherNumber: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Use another number

```stack
card UseAnotherNumber, then: ValidateAlternateNumber do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_agent_call_back_number_update/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  update_number_msg = page.body.messages[0].text

  cancel_scheduled_stacks("36ec8712-99c2-453c-b6cb-fbe9f7cf4bae")

  log(
    "Cancelling previously scheduled stack `HC: Scheduled - Callback follow up - 36ec8712-99c2-453c-b6cb-fbe9f7cf4bae`"
  )

  schedule_stack("36ec8712-99c2-453c-b6cb-fbe9f7cf4bae", in: 900)

  log(
    "Scheduled stack `HC: Scheduled - Callback follow up - 36ec8712-99c2-453c-b6cb-fbe9f7cf4bae` to run in 15 minutes"
  )

  preferred_callback_number =
    ask("@update_number_msg")
end

card ValidateAlternateNumber, then: ConfirmSaveAlternateNumber do
  text("TODO: ValidateAlternateNumber")
end

```

## Confirm saving of alternate number

```stack
card ConfirmSaveAlternateNumber, then: ConfirmSaveAlternateNumberError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_agent_contact_number_save/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  save_number_msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    SaveAlternateNumber: "@button_labels[0]",
    BotToAgentHandoverWait: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@save_number_msg")
  end
end

card SaveAlternateNumber, then: BotToAgentHandoverWait do
  update_contact(preferred_callback_number: "@preferred_callback_number")
end

card ConfirmSaveAlternateNumberError, then: ConfirmSaveAlternateNumberError do
  buttons(
    SaveAlternateNumber: "@button_labels[0]",
    BotToAgentHandoverWait: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Bot to agent handover waiting room

```stack
card BotToAgentHandoverWait do
  cancel_scheduled_stacks("69557475-02fa-4d44-a091-277f3cb5908b")

  log(
    "Cancelling previously scheduled stack `HC: Scheduled - Callback confirmation - 69557475-02fa-4d44-a091-277f3cb5908b`"
  )

  schedule_stack("69557475-02fa-4d44-a091-277f3cb5908b", in: 120)

  log(
    "Scheduled stack `HC: Scheduled - Callback confirmation - 69557475-02fa-4d44-a091-277f3cb5908b` to run in 2 minutes"
  )

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_bot_to_agent_handover_waiting_room/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  handover_msg = page.body.messages[0].text
  text("@handover_msg")
end

```