# Scheduled - Callback confirmation

This flow follows up with the user, whether they received the callback they requested, and whether the agent was able to help them

## Contact fields

* `nav_bypass`, This is a mechanism to bypass the main menu and send the user straight to a sub section

## Flow results

* `callback_completed`, Get set to `yes` or `no` depending on the user's answers

## Connections to other stacks

* `HelpCentre: Intro to HelpCentre` The user gets sent there if they click `main menu` or `see topics`

## Global variables

The following variable(s) are set in the `settings` global dictionary

* `contentrepo_qa_token` auth for API calls to CMS

## Content dependencies

* `mnch_onboarding_error_handling_button`
* `plat_help_call_back_confirmation_scheduled`
* `plat_help_call_back_confirmation_yes`
* `plat_help_call_back_confirmation_no`

# Init

```stack
card FetchError, then: CallbackConfirmation do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

card GotoMainMenu do
  log("Going to Main Menu")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

card GotoTopicsForYou do
  log("Going to GotoTopicsForYou")
  update_contact(navbypass: "TopicsForYou")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

card GotoCallback do
  log("Going to GotoCallback")
  update_contact(navbypass: "BotToAgentHandoverWaitingRoom")
  run_stack("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
end

```

# Callback Confirmation

<!-- { section: "a920eafa-71aa-4fdf-aa16-dcc10f8770f3", x: 0, y: 0} -->

```stack
card CallbackConfirmation, then: CallbackConfirmationError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_call_back_confirmation_scheduled"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  callback_conf_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    CallbackConfirmationYes: "@button_labels[0]",
    CallbackConfirmationNo: "@button_labels[1]"
  ) do
    text("@callback_conf_msg")
  end
end

card CallbackConfirmationError, then: CallbackConfirmationError do
  buttons(
    CallbackConfirmationYes: "@button_labels[0]",
    CallbackConfirmationNo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

# Callback Confirmation Yes

```stack
card CallbackConfirmationYes, then: CallbackConfirmationYesError do
  write_result("callback_completed", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_call_back_confirmation_yes"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  conf_yes_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    AgentHelpfulResponse: "@button_labels[0]",
    CallbackNotHelpful: "@button_labels[1]"
  ) do
    text("@conf_yes_msg")
  end
end

card CallbackNotHelpful, then: CallbackConfirmationNo do
  write_result("callback_helpful", "no")
end

card CallbackConfirmationYesError, then: CallbackConfirmationYesError do
  buttons(
    AgentHelpfulResponse: "@button_labels[0]",
    CallbackNotHelpful: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

# Callback Confirmation No

```stack
card CallbackConfirmationNo do
  write_result("callback_completed", "no")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_call_back_confirmation_no"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  callback_conf_no = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    GotoCallback: "@button_labels[0]",
    GotoTopicsForYou: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@callback_conf_no")
  end
end

card CallbackConfirmationNoError, then: CallbackConfirmationNoError do
  buttons(
    GotoCallback: "@button_labels[0]",
    GotoTopicsForYou: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

# Was Agent Helpful

```stack
card AgentHelpfulResponse do
  write_result("callback_helpful", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_agent_helpful_response"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  agent_helpful_msg = page.body.body.text.value.message

  text("@agent_helpful_msg")
end

```