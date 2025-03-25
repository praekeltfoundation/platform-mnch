<!-- { section: "5eb07fbf-ec80-4696-bcd2-5bdc43eb1947", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "generic")

```

```stack
card FetchError, then: CheckPointRedirect do
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
  run_stack("74bd3d95-2aec-4174-ad32-926952c795ca")
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
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_30_generic"]
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

  basic_questions_answers = [
    contact.gender,
    contact.year_of_birth,
    contact.province,
    contact.area_type
  ]

  basic_questions_list =
    filter(
      basic_questions_answers,
      &(is_nil_or_empty(&1) == false)
    )

  basic_questions_answers_count = count(basic_questions_answers)

  basic_questions_count = count(basic_questions_list)

  basic_questions_value = "@basic_questions_count/@basic_questions_answers_count"

  personal_questions_answers = [
    contact.relationship_status,
    contact.education,
    contact.socio_economic,
    contact.other_children
  ]

  personal_questions_list =
    filter(
      personal_questions_answers,
      &(is_nil_or_empty(&1) == false)
    )

  personal_questions_answers_count = count(personal_questions_answers)

  personal_questions_count = count(personal_questions_list)

  personal_questions_value = "@personal_questions_count/@personal_questions_answers_count"

  dma_questions_answers = [
    contact.dma_01,
    contact.dma_02,
    contact.dma_03,
    contact.dma_04,
    contact.dma_05
  ]

  dma_questions_list =
    filter(
      dma_questions_answers,
      &(is_nil_or_empty(&1) == false)
    )

  dma_questions_answers_count = count(dma_questions_answers)

  dma_questions_count = count(dma_questions_list)

  dma_questions_value = "@dma_questions_count/@dma_questions_answers_count"

  message = content_data.body.body.text.value
  message_text = substitute(message.message, "{basic_info_count}", "@basic_questions_value")
  message_text = substitute(message_text, "{personal_info_count}", "@personal_questions_value")
  message_text = substitute(message_text, "{daily_life_count}", "@dma_questions_value")
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayProfileProgress30Generic, then: DisplayProfileProgress30GenericError do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    WhyPersonalInfo1: "@button_labels[1]"
  ) do
    text("@message_text")
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
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_remind_later"]
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
  cancel_scheduled_stacks("689e019d-beb5-4ba2-8c04-f4663a67ab81")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100_generic"]
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
  name = if is_nil_or_empty(contact.name), do: "None", else: contact.name

  basic_questions_answers = [
    contact.gender,
    contact.year_of_birth,
    contact.province,
    contact.area_type
  ]

  basic_questions_answers_count = count(basic_questions_answers)

  basic_questions_list =
    filter(
      basic_questions_answers,
      &(is_nil_or_empty(&1) == false)
    )

  basic_questions_count = count(basic_questions_list)

  basic_questions_value =
    if(basic_questions_answers_count == basic_questions_count,
      do: "✅",
      else: "@basic_questions_count/@basic_questions_answers_count"
    )

  personal_questions_answers = [
    contact.relationship_status,
    contact.education,
    contact.socio_economic,
    contact.other_children
  ]

  personal_questions_answers_count = count(personal_questions_answers)

  personal_questions_list =
    filter(
      personal_questions_answers,
      &(is_nil_or_empty(&1) == false)
    )

  personal_questions_count = count(personal_questions_list)

  personal_questions_value =
    if(personal_questions_answers_count == personal_questions_count,
      do: "✅",
      else: "@personal_questions_count/@personal_questions_answers_count"
    )

  opted_in =
    if(contact.opted_in == false or is_nil_or_empty(contact.opted_in), do: "❌", else: "✅")

  loading_message = substitute(message.message, "{name}", "@name")
  loading_message = substitute(loading_message, "{basic_info_count}", "@basic_questions_value")

  loading_message =
    substitute(loading_message, "{personal_info_count}", "@personal_questions_value")

  loading_message = substitute(loading_message, "{get_important_messages}", "@opted_in")
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
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
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
  run_stack("e1e033d4-897a-4c9b-9eea-2411458c3c4c")
end

```

## Placeholder Form

```stack
card LOCAssessment, then: OptInReminder do
  log("Placeholder Form")
  run_stack("9bd8c27a-d08e-4c9e-8623-b4007373437e")
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
  run_stack("f36d4d47-9cc7-4202-a73f-db6f03e478cd")
end

card OptInReminder, then: ProfileProgress100Generic do
  log("User Opted in")
end

```

## View Topics For You

```stack
card ViewTopics do
  log("View topics content goes here")
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

```

## Main Menu

```stack
card MainMenu do
  log("Go to main menu")
  run_stack("fb98bb9d-60a6-47a1-a474-bb0f45b80030")
end

```

## TODO These are the Placeholders

```stack
card HealthGuide do
  log("Health guide goes here")
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

card BrowsableContent do
  log("Browsable content goes here")
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

```