<!-- { section: "6ccb73e1-e909-4a46-b571-16e4bcb28565", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "npm")

```

```stack
card FetchError, then: NonPersonalisedMenu do
  # Fetch and store the error message, so that we don't need to do it for every error card
  log("Non Personalised Menu")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_button/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  button_error_text = page.body.messages[0].text

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_list_message/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  list_error_text = page.body.messages[0].text
end

```

## Non Personalised Menu

<!-- { section: "f47f874b-b644-48ec-80ec-aa8f5cf523e4", x: 0, y: 0} -->

```stack
card NonPersonalisedMenu, then: DisplayNonPersonalisedMenu do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_non_personalised_menu/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]

  profile_completion =
    if is_nil_or_empty(contact.profile_completion), do: "0%", else: contact.profile_completion

  loading_message = substitute(message.text, "{profile_completion}", profile_completion)
  menu_items = map(message.list_items, & &1.title)
end

card DisplayNonPersonalisedMenu, then: DisplayNonPersonalisedMenuError do
  selected_topic =
    list("Menu",
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
    list("Menu",
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

card HelpCentre, then: GoToHelpCentre do
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
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_personalisation_prompt_zero/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.title)
end

card DisplayPromptZero, then: DisplayPromptZeroError do
  buttons(
    DomainShowcase: "@button_labels[0]",
    NonPersonalisedMenu: "@button_labels[1]"
  ) do
    text("@message.text")
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

## TODO: Domain Show Case

```stack
card DomainShowcase do
  log("DomainShowcase")
  text("DomainShowcase goes here")
end

```

## Prompt Partial Profile

```stack
card PromptPartial, then: DisplayPromptPartial do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_personalisation_prompt_partial/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]

  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name

  loading_message = substitute(message.text, "{username}", "@name")
  button_labels = map(message.buttons, & &1.title)
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
card CheckPoint
     when has_any_phrase(contact.checkpoint, [
            "pregnant_mom_profile",
            "partner_of_pregnant_mom_profile",
            "curious_pregnancy_profile"
          ]),
     then: ProfilePregnancyHealth do
  log("Check Point go to ProfilePregnancyHealth")
end

card CheckPoint when contact.checkpoint == "generic_basic_info", then: GenericProfile do
  log("Check Point go to GenericProfile")
end

card CheckPoint when contact.checkpoint == "hcw_profile", then: HCWProfile do
  log("Check Point go to HCWProfile")
end

card CheckPoint when contact.checkpoint == "basic_pregnancy_profile", then: PregnantNurseProfile do
  log("Check Point go to PregnantNurseProfile")
end

card CheckPoint, then: ProfilePregnancyHealth do
  log("Check Point default to ProfilePregnancyHealth")
end

```

## Profile Pregnancy Health

```stack
card ProfilePregnancyHealth do
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

```

## Generic Profile

```stack
card GenericProfile do
  run_stack("718e6b27-d818-40cf-8a7b-50c17bd236ba")
end

```

## HCW Profile

```stack
card HCWProfile do
  run_stack("9aa596d3-40f0-4349-8322-e44d1fd1d127")
end

```

## Pregnant Nurse Profile

```stack
card PregnantNurseProfile do
  text("PregnantNurseProfile")
  run_stack("1ed10e1b-f812-4730-8ec5-3f46088c41c7")
end

```

## View topics for you

```stack
card LibraryTopics, then: DisplayLibraryTopics do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_library/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  menu_items = map(message.list_items, & &1.title)
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
      NonPersonalisedMenu: "@menu_items[6]"
    ) do
      text("@message.text")
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
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_manage_updates/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  menu_items = map(message.list_items, & &1.title)
end

card DisplayManageUpdates, then: DisplayManageUpdatesError do
  selected_topic =
    list("Manage",
      PregnancyInfo: "@menu_items[0]",
      BabyChildHealth: "@menu_items[1]",
      WellBeing: "@menu_items[2]",
      LoveRelationship: "@menu_items[3]",
      FamilyPlanning: "@menu_items[4]",
      HealthWorkers: "@menu_items[5]",
      NonPersonalisedMenu: "@menu_items[6]"
    ) do
      text("@message.text")
    end
end

card DisplayManageUpdatesError, then: DisplayManageUpdatesError do
  selected_topic =
    list("Manage",
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
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_data_settings/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.title)
end

card DisplayDataSettings, then: DisplayDataSettingsError do
  buttons(
    AllData: "@button_labels[0]",
    TextAndImages: "@button_labels[1]",
    TextOnly: "@button_labels[2]"
  ) do
    text("@message.text")
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
  log("All")
  update_contact(data_preference: "all")
end

card TextAndImages, then: DataPreferencesConfirmation do
  log("text and images")
  update_contact(data_preference: "text and images")
end

card TextOnly, then: DataPreferencesConfirmation do
  log("text only")
  update_contact(data_preference: "text only")
end

```

## Data Preferences Confirm

```stack
card DataPreferencesConfirmation, then: DisplayDataPreferencesConfirmation do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_data_preferences_confirmation/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]

  loading_message =
    substitute(
      message.message,
      "{data_preference}",
      "@contact.data_preference"
    )

  button_labels = map(message.buttons, & &1.title)
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
card GoToHelpCentre, then: NonPersonalisedMenu do
  log("Help Centre")
  text("Help Centre placeholder")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

```

## Your Profile

```stack
card YourProfile do
  log("Your Progile")
  run_stack("90d3135d-6c0c-43c2-b2a8-a099d63639bf")
end

```

## Take A Tour

```stack
card GoToTakeATour do
  log("Take a tour")
  run_stack("359b3ff4-796d-4b80-91a6-15532c7bdb90")
end

```

## About and Privacy Policy

```stack
card AboutPrivacy, then: DisplayAboutPrivacy do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_about_privacy/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.title)
end

card DisplayAboutPrivacy, then: DisplayAboutPrivacyError do
  doc_id = message.document

  doc_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/documents/@doc_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(NonPersonalisedMenu: "@button_labels[0]") do
    document("@doc_data.body.meta.download_url")
    text("@message.text")
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