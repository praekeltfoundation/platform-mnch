<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                           |
| ----------------- |---------------------------------|
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

```stack
card FetchError, then: OptInReminder do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

```

# Opt In Reminder

<!-- { section: "a68fcad6-6fd1-4506-8bd0-b6218c2c155e", x: 0, y: 0} -->

```stack
card OptInReminder, then: DisplayOptInReminder do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_opt_in_reminder"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayOptInReminder when contact.data_preference == "text only",
  then: DisplayOptInReminderError do
  buttons(
    OptInYes: "@button_labels[0]",
    OptInNo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayOptInReminder, then: DisplayOptInReminderError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  buttons(
    OptInYes: "@button_labels[0]",
    OptInNo: "@button_labels[1]"
  ) do
    text("@message.message")
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
card OptInNo, then: OptInNoError do
  update_contact(opted_in: "no")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_opt_in_no"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(MainMenu: "@button_labels[0]") do
    text("@message.message")
  end
end

card OptInNoError, then: OptInNoError do
  buttons(MainMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card MainMenu do
  # TODO add main menu id, this is just a placeholder id
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

```

# Opt In Yes

```stack
card OptInYes, then: OptInYesError do
  update_contact(opted_in: "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_opt_in_yes"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(MainMenu: "@button_labels[0]") do
    text("@message.message")
  end
end

card OptInYesError, then: OptInYesError do
  buttons(MainMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```