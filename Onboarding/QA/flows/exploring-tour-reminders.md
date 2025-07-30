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

# Reminders

<!-- { section: "fa72e364-2a58-4731-9b27-2179875eaa57", x: 0, y: 0} -->

```stack
card Reminder, then: ReminderError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_reminder_secondary/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  buttons(
    CreateProfiles: "@button_labels[0]",
    RemindLater: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.text")
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
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

card RemindLater, then: RemindLaterError do
  # TODO need to fix button navigation 
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_reminder_later_2/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  buttons(
    CreateProfiles: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@message.text")
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
  # TODO this is a placeholder
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

```