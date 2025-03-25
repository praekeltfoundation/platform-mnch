```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "explore")

```

## Fetch button and list error messages

```stack
card FetchError, then: Checkpoint do
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

## Check Point

```stack
card Checkpoint, then: FetchTourCard01 do
  log("Go to FetchTourCard01")
  update_contact(checkpoint: "tour")
end

```

# Tour Card 01

<!-- { section: "9c39594f-a978-44ef-bc17-92aac05357f4", x: 0, y: 0} -->

```stack
card FetchTourCard01, then: DisplayTourCard01 do
  # TODO to schedule the reengagement message

  write_result("guided_tour_started", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_tour_card_01"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayTourCard01 when contact.data_preference == "text only",
  then: DisplayTourCard01Error do
  buttons(FetchTourCard02: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayTourCard01, then: DisplayTourCard01Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FetchTourCard02: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayTourCard01Error, then: DisplayTourCard01Error do
  buttons(FetchTourCard02: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

# Tour Card 02

```stack
card FetchTourCard02, then: DisplayTourCard02 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_tour_card_02"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayTourCard02 when contact.data_preference == "text only",
  then: DisplayTourCard02Error do
  buttons(FetchTourCard03: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard02, then: DisplayTourCard02Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FetchTourCard03: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayTourCard02Error, then: DisplayTourCard02Error do
  buttons(FetchTourCard03: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

# Tour Card 03

```stack
card FetchTourCard03, then: DisplayTourCard03 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_tour_card_03"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayTourCard03 when contact.data_preference == "text only",
  then: DisplayTourCard03Error do
  buttons(FetchTourCard04: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard03, then: DisplayTourCard03Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FetchTourCard04: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayTourCard03Error, then: DisplayTourCard03Error do
  buttons(FetchTourCard04: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

# Tour Card 04

```stack
card FetchTourCard04, then: DisplayTourCard04 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_tour_card_04"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayTourCard04 when contact.data_preference == "text only",
  then: DisplayTourCard04Error do
  buttons(FetchTourCard05: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard04, then: DisplayTourCard04Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FetchTourCard05: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayTourCard04Error, then: DisplayTourCard04Error do
  buttons(FetchTourCard05: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

# Tour Card 05

```stack
card FetchTourCard05, then: DisplayTourCard05 do
  write_result("guided_tour_completed", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_tour_card_05"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayTourCard05 when contact.data_preference == "text only",
  then: DisplayTourCard05Error do
  buttons(FetchGuidedTourMenu: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard05, then: DisplayTourCard05Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FetchGuidedTourMenu: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayTourCard05Error, then: DisplayTourCard05Error do
  buttons(FetchGuidedTourMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

# Guided Tour Menu

```stack
card FetchGuidedTourMenu, then: DisplayGuidedTourMenu do
  write_result("guided_tour_menu", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_guided_tour_menu"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
  log("@button_labels")
end

card DisplayGuidedTourMenu, then: DisplayGuidedTourMenuError do
  buttons(
    CreateProfiles: "@button_labels[0]",
    SpeakToAgent: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayGuidedTourMenuError, then: DisplayGuidedTourMenuError do
  buttons(
    CreateProfiles: "@button_labels[0]",
    SpeakToAgent: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card CreateProfiles do
  # Profile Classifier
  run_stack("c77efa62-1c9d-4ace-ae7a-4585e4e929d1")
end

card SpeakToAgent do
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

```