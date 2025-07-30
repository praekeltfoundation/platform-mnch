<!-- { section: "d032bc4c-282f-422e-bff6-1d83897b82a5", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "optin")

```

```stack
card FetchError, then: OptInReminder do
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

# Opt In Reminder

<!-- { section: "a68fcad6-6fd1-4506-8bd0-b6218c2c155e", x: 0, y: 0} -->

```stack
card OptInReminder, then: DisplayOptInReminder do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_opt_in_reminder/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.title)
end

# Text only
card DisplayOptInReminder when contact.data_preference == "text only",
  then: DisplayOptInReminderError do
  buttons(
    OptInYes: "@button_labels[0]",
    OptInNo: "@button_labels[1]"
  ) do
    text("@message.text")
  end
end

# Display with image
card DisplayOptInReminder, then: DisplayOptInReminderError do
  image_id = content_data.body.messages[0].image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    OptInYes: "@button_labels[0]",
    OptInNo: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.text")
  end
end

card DisplayOptInReminderError, then: DisplayOptInReminderError do
  buttons(
    OptInYes: "@button_labels[0]",
    OptInNo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

# Opt In No

```stack
card OptInNo do
  update_contact(opted_in: "false")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_opt_in_no/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  text("@message.text")
end

```

# Opt In Yes

```stack
card OptInYes do
  update_contact(opted_in: "true")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_opt_in_yes/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  loading_message = substitute(message.text, "{@username}", "@contact.name")
  text("@loading_message")
end

```