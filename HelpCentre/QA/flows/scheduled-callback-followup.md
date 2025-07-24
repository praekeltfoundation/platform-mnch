# Scheduled - Callback follow up

This flow is a re-engagement reminder, used when a user has requested a callback on an alternate number, but did not input the number when asked for it.

It asks the user if they still want a callback, and provides an option to goto the main menu

## Contact fields

* `nav_bypass`, This is a mechanism to bypass the main menu and send the user straight to a sub section

## Flow results

* `counsellor_alt_num_follow_up`, Get set to the relevant value, depending on what the user clicks on

## Connections to other stacks

* This is a scheduled stack, which gets scheduled from within `HelpCentre: Agent Wrap-up`
* If the user clicks main menu, we send them to `HelpCentre: Intro to HelpCentre`
* If the user clicks either yes or no, we send them back to `HelpCentre: Agent Wrap-up`

## Global variables

The following variable(s) are set in the `settings` global dictionary

* `contentrepo_qa_token` used to auth api calls

## Content dependencies

* `mnch_onboarding_error_handling_button`
* `plat_help_call_back_follow_up`

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "cbfu")

card FetchError, then: CallbackFollowup do
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

card GotoMainMenu do
  log("GotoMainMenu")
  write_result("counsellor_alt_num_follow_up", "main_menu")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

card GotoCallback do
  log("Going to GotoCallback")
  write_result("counsellor_alt_num_follow_up", "yes")
  update_contact(navbypass: "UseAnotherNumber")
  run_stack("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
end

card GotoAgentHelpfulResponse do
  log("Going to GotoAgentHelpfulResponse")
  write_result("counsellor_alt_num_follow_up", "no")
  update_contact(navbypass: "AgentHelpfulResponse")
  run_stack("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
end

```

<!-- { section: "9af0e671-6ba5-4686-85e2-731ddd01ad85", x: 0, y: 0} -->

```stack
card CallbackFollowup, then: CallbackFollowupError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_call_back_follow_up/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  callback_followup_msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    GotoCallback: "@button_labels[0]",
    GotoAgentHelpfulResponse: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@callback_followup_msg")
  end
end

card CallbackFollowupError, then: CallbackFollowupError do
  buttons(
    GotoCallback: "@button_labels[0]",
    GotoAgentHelpfulResponse: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```