<!-- { section: "e335b0ad-9a0c-47ac-a750-61806ef44305", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "tourr")

```

```stack
card FetchError, then: Reminder do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

```

# Reminders

<!-- { section: "fa72e364-2a58-4731-9b27-2179875eaa57", x: 0, y: 0} -->

```stack
card Reminder, then: ReminderError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_secondary"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    CreateProfiles: "@button_labels[0]",
    RemindLater: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card ReminderError, then: ReminderError do
  buttons(
    CreateProfiles: "@button_labels[0]",
    RemindLater: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card CreateProfiles do
  run_stack("e1f6a4d6-f245-4203-aed5-6577bbd4d96a")
end

card RemindLater, then: RemindLaterError do
  # TODO need to fix button navigation 
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_later_2"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    CreateProfiles: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card RemindLaterError, then: RemindLaterError do
  buttons(
    CreateProfiles: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card MainMenu do
  run_stack("d02746ff-a3e2-4153-99ff-cd01a941a00d")
end

```