# Reminder

A reminder message that gets sent 23 hours after a user hasn't accepted the Privacy Policy.

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: Reminder do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

```

<!-- { section: "3e991636-f6d9-436c-a5dd-2fe3296a9359", x: 0, y: 0} -->

```stack
card Reminder, then: ReminderError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_1"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    PrivacyPolicy: "@button_labels[0]",
    RemindTomorrow: "@button_labels[1]",
    RemindNo: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card ReminderError, then: ReminderError do
  buttons(
    PrivacyPolicy: "@button_labels[0]",
    RemindTomorrow: "@button_labels[1]",
    RemindNo: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card PrivacyPolicy do
  # Go to the Intro & Welcome
  log("Starting intro & welcome stack")
  run_stack("5e59aafb-fc30-41f9-b268-6268173b2aff")
end

card RemindNo do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_no"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  text("@message.message")
end

card RemindTomorrow do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_tomorrow"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  text("@message.message")
  # Cancel any previous scheduled instance of this stack
  cancel_scheduled_stacks("ce992f8b-49d8-4876-8bfd-a62b6482206d")
  schedule_stack("ce992f8b-49d8-4876-8bfd-a62b6482206d", in: 60 * 60 * 23)
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `reminder`, whatsapp message with 3 buttons
* `reminder_no`, whatsapp message
* `reminder_tomorrow`, whatsapp message