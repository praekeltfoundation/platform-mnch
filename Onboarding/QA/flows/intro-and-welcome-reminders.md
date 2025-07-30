# Reminder

A reminder message that gets sent 23 hours after a user hasn't accepted the Privacy Policy.

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: Reminder do
  # Fetch and store the error message, so that we don't need to do it for every error card

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_button/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  button_error_text = page.body.messages[0].text
end

```

<!-- { section: "3e991636-f6d9-436c-a5dd-2fe3296a9359", x: 0, y: 0} -->

```stack
card Reminder, then: ReminderError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_reminder_1/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  buttons(
    PrivacyPolicy: "@button_labels[0]",
    RemindTomorrow: "@button_labels[1]",
    RemindNo: "@button_labels[2]"
  ) do
    text("@message.text")
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
  run_stack("e2203073-f8b3-45f4-b19d-4079d5af368a")
end

card RemindNo do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_reminder_no/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  text("@message.text")
end

card RemindTomorrow do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_reminder_tomorrow/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  text("@message.text")
  # Cancel any previous scheduled instance of this stack
  cancel_scheduled_stacks("8407c748-140f-43fa-b5f4-b5652e07f484")
  schedule_stack("8407c748-140f-43fa-b5f4-b5652e07f484", in: 60 * 60 * 23)
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `reminder`, whatsapp message with 3 buttons
* `reminder_no`, whatsapp message
* `reminder_tomorrow`, whatsapp message