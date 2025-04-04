<!-- { section: "e335b0ad-9a0c-47ac-a750-61806ef44305", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "pmenu")

```

<!-- { section: "6ccb73e1-e909-4a46-b571-16e4bcb28565", x: 500, y: 48} -->

```stack
card FetchError, then: PersonalisedMenu do
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

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_list_message"]
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

  list_error_text = page.body.body.text.value.message
end

```

## Personalised Menu

<!-- { section: "f47f874b-b644-48ec-80ec-aa8f5cf523e4", x: 0, y: 0} -->

```stack
card PersonalisedMenu, then: DisplayPersonalisedMenu do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_main_menu_personalised"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  menu_items = map(message.list_items, & &1.value)
end

card DisplayPersonalisedMenu, then: DisplayPersonalisedMenuError do
  selected_topic =
    list("Menu",
      HealthGuide: "@menu_items[0]",
      ViewTopics: "@menu_items[1]",
      HelpCentre: "@menu_items[2]",
      Profile: "@menu_items[3]",
      ManageUpdate: "@menu_items[4]",
      ManageData: "@menu_items[5]",
      TakeATour: "@menu_items[6]",
      About: "@menu_items[7]"
    ) do
      text("@message.message")
    end
end

card DisplayPersonalisedMenuError, then: DisplayPersonalisedMenuError do
  selected_topic =
    list("Menu",
      HealthGuide: "@menu_items[0]",
      ViewTopics: "@menu_items[1]",
      HelpCentre: "@menu_items[2]",
      Profile: "@menu_items[3]",
      ManageUpdate: "@menu_items[4]",
      ManageData: "@menu_items[5]",
      TakeATour: "@menu_items[6]",
      About: "@menu_items[7]"
    ) do
      text("@list_error_text")
    end
end

card HealthGuide, then: HealthGuideGeneric do
  update_contact(topic: "@selected_topic")
end

card ViewTopics, then: LibraryTopics do
  update_contact(topic: "@selected_topic")
end

card HelpCentre, then: GoToHelpCentre do
  update_contact(topic: "@selected_topic")
end

card Profile, then: YourProfile do
  update_contact(topic: "@selected_topic")
end

card ManageUpdate, then: ManageUpdates do
  update_contact(topic: "@selected_topic")
end

card ManageData, then: DataSettings do
  update_contact(topic: "@selected_topic")
end

card TakeATour, then: GoToTakeATour do
  update_contact(topic: "@selected_topic")
end

card About, then: AboutPrivacy do
  update_contact(topic: "@selected_topic")
end

```

## Health Guide Generic

```stack
card HealthGuideGeneric, then: DisplayHealthGuideGeneric do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_health_guide_generic"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  menu_items = map(message.list_items, & &1.value)
end

card DisplayHealthGuideGeneric, then: DisplayHealthGuideGenericError do
  selected_topic =
    list("Choose",
      CheckUp: "@menu_items[0]",
      TakeQuiz: "@menu_items[1]",
      Challenge: "@menu_items[2]",
      Practise: "@menu_items[3]",
      Generic1: "@menu_items[4]",
      Generic2: "@menu_items[5]",
      Generic2: "@menu_items[6]",
      PersonalisedMenu: "@menu_items[7]"
    ) do
      text("@message.message")
    end
end

card DisplayHealthGuideGenericError, then: DisplayHealthGuideGenericError do
  selected_topic =
    list("Choose",
      CheckUp: "@menu_items[0]",
      TakeQuiz: "@menu_items[1]",
      Challenge: "@menu_items[2]",
      Practise: "@menu_items[3]",
      Generic1: "@menu_items[4]",
      Generic2: "@menu_items[5]",
      Generic3: "@menu_items[6]",
      PersonalisedMenu: "@menu_items[7]"
    ) do
      text("@list_error_text")
    end
end

card CheckUp, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card TakeQuiz, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Challenge, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Practise, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Generic1, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Generic2, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Generic3, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

```

## TODO

```stack
card DomainShowcase do
  log("DomainShowcase")
  text("DomainShowcase goes here")
end

```

## View topics for you

```stack
card LibraryTopics, then: DisplayLibraryTopics do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_library"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  menu_items = map(message.list_items, & &1.value)
end

card DisplayLibraryTopics, then: DisplayLibraryTopicsError do
  selected_topic =
    list("Choose",
      LoveRelationship: "@menu_items[0]",
      PregnancyInfo: "@menu_items[1]",
      BabyChildHealth: "@menu_items[2]",
      WellBeing: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthProfessional: "@menu_items[5]",
      PersonalisedMenu: "@menu_items[6]"
    ) do
      text("@message.message")
    end
end

card DisplayLibraryTopicsError, then: DisplayLibraryTopicsError do
  selected_topic =
    list("Choose",
      LoveRelationship: "@menu_items[0]",
      PregnancyInfo: "@menu_items[1]",
      BabyChildHealth: "@menu_items[2]",
      WellBeing: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthProfessional: "@menu_items[5]",
      PersonalisedMenu: "@menu_items[6]"
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_manage_updates"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  menu_items = map(message.list_items, & &1.value)
end

card DisplayManageUpdates, then: DisplayManageUpdatesError do
  selected_topic =
    list("Choose",
      PregnancyInfo: "@menu_items[0]",
      BabyChildHealth: "@menu_items[1]",
      WellBeing: "@menu_items[2]",
      LoveRelationship: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthWorkers: "@menu_items[5]",
      PersonalisedMenu: "@menu_items[6]"
    ) do
      text("@message.message")
    end
end

card DisplayManageUpdatesError, then: DisplayManageUpdatesError do
  selected_topic =
    list("Choose",
      PregnancyInfo: "@menu_items[0]",
      BabyChildHealth: "@menu_items[1]",
      WellBeing: "@menu_items[2]",
      LoveRelationship: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthWorkers: "@menu_items[5]",
      PersonalisedMenu: "@menu_items[6]"
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_data_settings"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayDataSettings, then: DisplayDataSettingsError do
  buttons(
    AllData: "@button_labels[0]",
    TextAndImages: "@button_labels[1]",
    TextOnly: "@button_labels[2]"
  ) do
    text("@message.message")
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_data_preferences_confirmation"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value

  loading_message =
    substitute(
      message.message,
      "{data_preference}",
      "@contact.data_preference"
    )

  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayDataPreferencesConfirmation, then: DisplayDataPreferencesConfirmationError do
  buttons(PersonalisedMenu: "@button_labels[0]") do
    text("@loading_message")
  end
end

card DisplayDataPreferencesConfirmationError, then: DisplayDataPreferencesConfirmationError do
  buttons(PersonalisedMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Help Centre

```stack
card GoToHelpCentre, then: PersonalisedMenu do
  log("Help Centre")
  # run_stack("ea366b74-df7b-41ed-a479-7d501435d38e")
end

```

## Your Profile

```stack
card YourProfile do
  log("Your Profile")
  run_stack("f085a8b1-5e73-408d-bcc2-9487d0512085")
end

```

## Take A Tour

```stack
card GoToTakeATour do
  log("Take a tour")
  run_stack("160ac3f4-ab18-4610-bbab-c003f79e1197")
end

```

## About and Privacy Policy

```stack
card AboutPrivacy, then: DisplayAboutPrivacy do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_about_privacy"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayAboutPrivacy, then: DisplayAboutPrivacyError do
  doc_id = message.document

  doc_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/documents/@doc_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(PersonalisedMenu: "@button_labels[0]") do
    document("@doc_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayAboutPrivacyError, then: DisplayAboutPrivacyError do
  buttons(PersonalisedMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## TODO: Article Topics

```stack
card ArticleTopic01Secondary do
  log("Placeholder")
  text("Article topics")
end

```