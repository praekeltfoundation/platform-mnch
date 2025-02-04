<!-- { section: "e335b0ad-9a0c-47ac-a750-61806ef44305", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "genp")

```

<!-- { section: "5eb07fbf-ec80-4696-bcd2-5bdc43eb1947", x: 500, y: 48} -->

```stack
card FetchError, then: CheckPointRedirect do
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

## Redirect Check Point

```stack
card CheckPointRedirect
     when contact.profile_completion == "30%" and contact.checkpoint == "generic_basic_info",
     then: ProfileProgress30Generic do
  log("ProfileProgress30")
end

card CheckPointRedirect when contact.profile_completion == "100%", then: ProfileProgress100Generic do
  log("ProfileProgress100")
end

card CheckPointRedirect when contact.checkpoint == "generic_personal_info",
  then: PersonalProfileQuestions do
  log("PersonalProfileQuestions")
end

card CheckPointRedirect, then: BasicQuestions do
  log("Default to BasicQuestions")
end

```

## Basic Profile Questions

```stack
card BasicQuestions, then: ProfileProgress30Generic do
  log("Basic questions")
  update_contact(profile_type: "generic")
  update_contact(checkpoint: "generic_basic_info")
  run_stack("fe7139a4-60c5-4ced-ad82-daa43f483c37")
end

```

## Profile Progress 30 Generic

<!-- { section: "37ea7b8b-35d8-4111-a77d-46aa852604b4", x: 0, y: 0} -->

```stack
card ProfileProgress30Generic, then: DisplayProfileProgress30Generic do
  write_result("profile_completion", "30%")
  update_contact(profile_completion: "30%")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_30_generic"]
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_why_personal_info_1"]
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

card DisplayWhyPersonalInfo1, then: DisplayWhyPersonalInfo1Error do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    ReminderLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayWhyPersonalInfo1Error, then: DisplayWhyPersonalInfo1Error do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    ReminderLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Reminder Later

```stack
card ReminderLater, then: DisplayReminderLater do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_later"]
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

card DisplayReminderLater, then: DisplayReminderLaterError do
  buttons(ViewTopics: "@button_labels[0]") do
    text("@message.message")
  end
end

card DisplayReminderLaterError, then: DisplayReminderLaterError do
  buttons(ViewTopics: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Profile Progress 100 Generic

```stack
card ProfileProgress100Generic, then: DisplayProfileProgress100Generic do
  write_result("profile_completion", "100%")
  update_contact(profile_completion: "100%")
  # re engagement
  cancel_scheduled_stacks("78cca41f-d27d-4669-ae16-a785744047a1")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100_generic"]
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
  name = if is_nil_or_empty(contact.name), do: "None", else: contact.name

  loading_message = substitute(message.message, "{UserName, “None”}", "@name")
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
    text("@loading_message")
  end
end

# Display with image
card DisplayProfileProgress100Generic, then: DisplayProfileProgress100GenericError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    HealthGuide: "@button_labels[0]",
    BrowsableContent: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
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

## Personal Profile Questions

```stack
card PersonalProfileQuestions, then: LOCAssessment do
  log("Personal profile questions")
  update_contact(checkpoint: "generic_personal_info")
  run_stack("67e29cda-52a9-4eb4-9fc0-224c44585c8c")
end

```

## Placeholder Form

```stack
card LOCAssessment, then: OptInReminder do
  log("Placeholder Form")
  run_stack("b283e7c1-0a79-45ab-976c-5566d9ba06cd")
end

```

## Opt-in Reminder

If user not opted in

```stack
card OptInReminder
     when contact.opted_in == false or
            contact.opted_in == "false" or
            is_nil_or_empty(contact.opted_in),
     then: ProfileProgress100Generic do
  run_stack("3ef42a80-1039-4193-9ad3-4ff56b80de2e")
end

card OptInReminder, then: ProfileProgress100Generic do
  log("User Opted in")
end

```

## View Topics For You

```stack
card ViewTopics do
  log("View topics content goes here")
  # run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

```

## Main Menu

```stack
card MainMenu do
  log("Go to main menu")
  run_stack("75eada25-7a3e-4df8-a19c-39ace798427d")
end

```

## TODO These are the Placeholders

```stack
card HealthGuide do
  log("Health guide")
  # TODO
  run_stack("75eada25-7a3e-4df8-a19c-39ace798427d")
end

card BrowsableContent do
  log("Browsable content")
  # TODO
  run_stack("75eada25-7a3e-4df8-a19c-39ace798427d")
end

```