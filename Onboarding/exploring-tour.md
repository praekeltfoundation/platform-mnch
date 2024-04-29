<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                     |
| ----------------- |-------------------------------------------|
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

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
card DisplayTourCard01 when contact.data_preference == "text only" do
  buttons(FetchTourCard02: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayTourCard01 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  buttons(FetchTourCard02: "@button_labels[0]") do
    text("@message.message")
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

card DisplayTourCard02 when contact.data_preference == "text only" do
  buttons(FetchTourCard03: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard02 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  buttons(FetchTourCard03: "@button_labels[0]") do
    text("@message.message")
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

card DisplayTourCard03 when contact.data_preference == "text only" do
  buttons(FetchTourCard04: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard03 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  buttons(FetchTourCard04: "@button_labels[0]") do
    text("@message.message")
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

card DisplayTourCard04 when contact.data_preference == "text only" do
  buttons(FetchTourCard05: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard04 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  buttons(FetchTourCard05: "@button_labels[0]") do
    text("@message.message")
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
        ["slug", "mnch_onboarding_tour_card_06"]
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

card DisplayTourCard05 when contact.data_preference == "text only" do
  buttons(FetchGuidedTourMenu: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayTourCard05 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  buttons(FetchGuidedTourMenu: "@button_labels[0]") do
    text("@message.message")
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
  log("@button_labels")
end

card DisplayGuidedTourMenu do
  buttons(
    CreateProfiles: "@button_labels[0]",
    SpeakToAgent: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card CreateProfiles do
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

card SpeakToAgent do
  run_stack("ea366b74-df7b-41ed-a479-7d501435d38e")
end

```