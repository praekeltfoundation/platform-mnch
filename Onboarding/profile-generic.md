<!-- { section: "5eb07fbf-ec80-4696-bcd2-5bdc43eb1947", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "generic")

```

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                            |
| ----------------- |----------------------------------|
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

```stack
card FetchError, then: ProfileProgressGeneric do
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

## Get User Profile Progress

```stack
card ProfileProgressGeneric when contact.profile_progress = "10%",
  then: ProfileProgress10Generic do
  log("Profile progress is 10%")
end

card ProfileProgressGeneric when contact.profile_progress = "30%",
  then: ProfileProgress30Generic do
  log("Profile progress is 30%")
end

card ProfileProgressGeneric when contact.profile_progress = "75%",
  then: ProfileProgress75Generic do
  log("Profile progress is 75%")
end

card ProfileProgressGeneric, then: ProfileProgress100Generic do
  log("Profile progress is 100%")
end

```

## Profile Progress 30 Generic

<!-- { section: "37ea7b8b-35d8-4111-a77d-46aa852604b4", x: 0, y: 0} -->

```stack
card ProfileProgress30Generic, then: DisplayProfileProgress30Generic do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_30_generic"]
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

card DisplayProfileProgress30Generic, then: DisplayProfileProgress30GenericError do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    WhyPersonalInfo1: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayProfileProgress30GenericError, then: DisplayProfileProgress30GenericError do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    WhyPersonalInfo1: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Why Personal Info 1

```stack
card WhyPersonalInfo1, then: DisplayWhyPersonalInfo1 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_why_personal_info_1"]
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

card DisplayWhyPersonalInfo1, then: DisplayWhyPersonalInfo1Error do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    LowProfileCompletion: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayWhyPersonalInfo1Error, then: DisplayWhyPersonalInfo1Error do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    LowProfileCompletion: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Profile Progress 100 Generic

```stack
card ProfileProgress100Generic, then: DisplayProfileProgress100Generic do
  text("ProfileProgress100Generic")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100_generic"]
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
card DisplayProfileProgress100Generic when contact.data_preference == "text only",
  then: DisplayProfileProgress100GenericError do
  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayProfileProgress100Generic, then: DisplayProfileProgress100GenericError do
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
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card DisplayProfileProgress100GenericError, then: DisplayProfileProgress100GenericError do
  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Profile Progress 75 Generic

```stack
card ProfileProgress75Generic, then: DisplayProfileProgress75Generic do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_75_generic"]
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
card DisplayProfileProgress75Generic when contact.data_preference == "text only",
  then: DisplayProfileProgress75GenericError do
  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayProfileProgress75Generic, then: DisplayProfileProgress75GenericError do
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
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card DisplayProfileProgress75GenericError, then: DisplayProfileProgress75GenericError do
  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Profile Progress 10 Generic

```stack
card ProfileProgress10Generic, then: DisplayProfileProgress10Generic do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_10_generic"]
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
card DisplayProfileProgress10Generic when contact.data_preference == "text only",
  then: DisplayProfileProgress10GenericError do
  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayProfileProgress10Generic, then: DisplayProfileProgress10GenericError do
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
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card DisplayProfileProgress10GenericError, then: DisplayProfileProgress10GenericError do
  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## TODO These are the Placeholders

```stack
card MainMenu do
  text("Main menu goes here")
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

card HealthGuide do
  text("Health guide goes here")
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

card BrowsableContent do
  text("Browsable content goes here")
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

card PersonalProfileQuestions do
  text("Personal profile questions goes here")
  run_stack("61a880e4-cf7b-47c5-a047-60802aaa7975")
end

card LowProfileCompletion do
  text("low profile completion goes here")
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

```