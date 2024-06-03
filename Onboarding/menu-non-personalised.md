<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                          |
| ----------------- |--------------------------------|
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

```stack
card FetchError, then: NonPersonalisedMenu do
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

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_list_message"]
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

  list_error_text = page.body.body.text.value.message

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_unrecognised_number"]
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

  unrecognised_number_text = page.body.body.text.value.message
end

```

## Non Personalised Menu

<!-- { section: "f47f874b-b644-48ec-80ec-aa8f5cf523e4", x: 0, y: 0} -->

```stack
card NonPersonalisedMenu, then: DisplayNonPersonalisedMenu do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_non_personalised_menu"]
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

  profile_completion =
    if is_nil_or_empty(contact.profile_completion), do: "0%", else: contact.profile_completion

  loading_message = substitute(message.message, "{0%}", profile_completion)
  menu_items = map(message.list_items, & &1.value)
end

card DisplayNonPersonalisedMenu, then: DisplayNonPersonalisedMenuError do
  selected_topic =
    list("Select option",
      HealthGuide: "@menu_items[0]",
      ViewTopics: "@menu_items[1]",
      HelpCentre: "@menu_items[2]",
      Profile: "@menu_items[3]",
      ManageUpdate: "@menu_items[4]",
      ManageUserData: "@menu_items[5]",
      TakeATour: "@menu_items[6]",
      About: "@menu_items[7]"
    ) do
      text("@loading_message")
    end
end

card DisplayNonPersonalisedMenuError, then: DisplayNonPersonalisedMenuError do
  selected_topic =
    list("Select option",
      HealthGuide: "@menu_items[0]",
      ViewTopics: "@menu_items[1]",
      HelpCentre: "@menu_items[2]",
      Profile: "@menu_items[3]",
      ManageUpdate: "@menu_items[4]",
      ManageUserData: "@menu_items[5]",
      TakeATour: "@menu_items[6]",
      About: "@menu_items[7]"
    ) do
      text("@list_error_text")
    end
end

card HealthGuide when is_nil_or_empty(contact.profile_completion), then: PromptZero do
  update_contact(topic: "@selected_topic")
end

card HealthGuide, then: PromptPartial do
  update_contact(topic: "@selected_topic")
end

card ViewTopics, then: LibraryTopics do
  update_contact(topic: "@selected_topic")
end

card HelpCentre, then: GoToTakeATour do
  update_contact(topic: "@selected_topic")
end

card Profile, then: YourProfile do
  update_contact(topic: "@selected_topic")
end

card ManageUpdate, then: ManageUpdates do
  update_contact(topic: "@selected_topic")
end

card ManageUserData, then: DataSettings do
  update_contact(topic: "@selected_topic")
end

card TakeATour, then: GoToTakeATour do
  update_contact(topic: "@selected_topic")
end

card About, then: AboutPrivacy do
  update_contact(topic: "@selected_topic")
end

```

## Zero Profile

```stack
card PromptZero, then: DisplayPromptZero do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_personalisation_prompt_zero"]
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

card DisplayPromptZero, then: DisplayPromptZeroError do
  buttons(
    DomainShowcase: "@button_labels[0]",
    NonPersonalisedMenu: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayPromptZeroError, then: DisplayPromptZeroError do
  buttons(
    DomainShowcase: "@button_labels[0]",
    NonPersonalisedMenu: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

```stack
card DomainShowcase do
  log("DomainShowcase")
end

```

## Prompt Partial Profile

```stack
card PromptPartial, then: DisplayPromptPartial do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_personalisation_prompt_partial"]
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
  loading_message = substitute(message.message, "{@username}", "@contact.name")
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayPromptPartial, then: DisplayPromptPartialError do
  buttons(
    CheckPoint: "@button_labels[0]",
    NonPersonalisedMenu: "@button_labels[1]"
  ) do
    text("@loading_message")
  end
end

card DisplayPromptPartialError, then: DisplayPromptPartialError do
  buttons(
    CheckPoint: "@button_labels[0]",
    NonPersonalisedMenu: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Check Point

```stack
card CheckPoint do
  log("Check Point")
end

```

## View topics for you

```stack
card LibraryTopics, then: DisplayLibraryTopics do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_library"]
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
  menu_items = map(message.list_items, & &1.value)
end

card DisplayLibraryTopics, then: DisplayLibraryTopicsError do
  selected_topic =
    list("Select option",
      LoveRelationship: "@menu_items[0]",
      PregnancyInfo: "@menu_items[1]",
      BabyChildHealth: "@menu_items[2]",
      WellBeing: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthProfessional: "@menu_items[5]",
      NonPersonalisedMenu: "@menu_items[6]"
    ) do
      text("@message.message")
    end
end

card DisplayLibraryTopicsError, then: DisplayLibraryTopicsError do
  selected_topic =
    list("Select option",
      LoveRelationship: "@menu_items[0]",
      PregnancyInfo: "@menu_items[1]",
      BabyChildHealth: "@menu_items[2]",
      WellBeing: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthProfessional: "@menu_items[5]",
      NonPersonalisedMenu: "@menu_items[6]"
    ) do
      text("@list_error_text")
    end
end

card LoveRelationship, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card PregnancyInfo, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card BabyChildHealth, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card WellBeing, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card FamilyPlanning, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card HealthProfessional, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

```

## Manage Updates

```stack
card ManageUpdates, then: DisplayManageUpdates do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_manage_updates"]
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
  menu_items = map(message.list_items, & &1.value)
end

card DisplayManageUpdates, then: DisplayManageUpdatesError do
  selected_topic =
    list("Select option",
      PregnancyInfo: "@menu_items[0]",
      BabyChildHealth: "@menu_items[1]",
      WellBeing: "@menu_items[2]",
      LoveRelationship: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthWorkers: "@menu_items[5]",
      NonPersonalisedMenu: "@menu_items[6]"
    ) do
      text("@message.message")
    end
end

card DisplayManageUpdatesError, then: DisplayManageUpdatesError do
  selected_topic =
    list("Select option",
      PregnancyInfo: "@menu_items[0]",
      BabyChildHealth: "@menu_items[1]",
      WellBeing: "@menu_items[2]",
      LoveRelationship: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthWorkers: "@menu_items[5]",
      NonPersonalisedMenu: "@menu_items[6]"
    ) do
      text("@list_error_text")
    end
end

card PregnancyInfo, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card BabyChildHealth, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card WellBeing, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card LoveRelationship, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card FamilyPlanning, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card HealthWorkers, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

```

## Data Settings

```stack
card DataSettings, then: DisplayDataSettings do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_data_settings"]
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
  loading_message = substitute(message.message, "{@username}", "@contact.name")
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayDataSettings, then: DisplayDataSettingsError do
  buttons(
    AllData: "@button_labels[0]",
    TextAndImages: "@button_labels[1]",
    TextOnly: "@button_labels[2]"
  ) do
    text("@loading_message")
  end
end

card DisplayDataSettingsError, then: DisplayDataSettingsError do
  buttons(
    AllData: "@button_labels[0]",
    TextAndImages: "@button_labels[1]",
    TextOnly: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card AllData, then: DataPreferencesConfirmation do
  log("@preference")
  update_contact(data_preference: "all")
end

card TextAndImages, then: DataPreferencesConfirmation do
  log("@preference")
  update_contact(data_preference: "text and images")
end

card TextOnly, then: DataPreferencesConfirmation do
  log("@preference")
  update_contact(data_preference: "text only")
end

```

## Data Preferences Confirm

```stack
card DataPreferencesConfirmation, then: DisplayDataPreferencesConfirmation do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_data_preferences_confirmation"]
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

  loading_message =
    substitute(
      message.message,
      "{Text only/ Text & images/ Text, images, audio & video}",
      "@contact.data_preference"
    )

  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayDataPreferencesConfirmation, then: DisplayDataPreferencesConfirmationError do
  buttons(NonPersonalisedMenu: "@button_labels[0]") do
    text("@loading_message")
  end
end

card DisplayDataPreferencesConfirmationError, then: DisplayDataPreferencesConfirmationError do
  buttons(NonPersonalisedMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Help Centre

```stack
card HelpCentre do
  log("Help Centre")
  run_stack("ea366b74-df7b-41ed-a479-7d501435d38e")
end

```

## Your Profile

```stack
card YourProfile do
  log("Your Progile")
  run_stack("1f551cbc-db57-41d3-b5ee-dc6c77b3030b")
end

```

## Take A Tour

```stack
card GoToTakeATour do
  log("Take a tour")
  run_stack("4288d6a9-23c9-4fc6-95b7-c675a6254ea5")
end

```

## About and Privacy Policy

```stack
card AboutPrivacy, then: DisplayAboutPrivacy do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_about_privacy"]
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

card DisplayAboutPrivacy, then: DisplayAboutPrivacyError do
  doc_id = message.document

  doc_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/documents/@doc_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  document("@doc_data.body.meta.download_url")

  buttons(NonPersonalisedMenu: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayAboutPrivacyError, then: DisplayAboutPrivacyError do
  buttons(NonPersonalisedMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## TODO: Article Topics

```stack
card ArticleTopic01Secondary do
  log("Placeholder")
end

```