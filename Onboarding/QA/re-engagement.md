<!-- { section: "97ca43be-ba28-49df-98f1-4207014d0d65", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "engage")

```

<!-- { section: "9a4ecd16-1072-4929-8f8f-5f1c63cdd452", x: 0, y: 0} -->

```stack
card FetchError, then: DropOffRedirect do
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

## Drop Off Redirect And Schedule Reminder

```stack
card DropOffRedirect when contact.reengagement_message == "1st message", then: DropOff2ndReminder do
  log("To send 2nd message")
  # cancel any scheduled stacks for this journey
  cancel_scheduled_stacks("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d")
  schedule_stack("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d", in: 23 * 60 * 60)
end

card DropOffRedirect when contact.reengagement_message == "2nd message", then: DropOff3rdReminder do
  log("To send 3rd message")
end

card DropOffRedirect when contact.reengagement_message == "remind me", then: ReminderRequest do
  log("Remind me tomorrow message")
end

card DropOffRedirect, then: DropOff1stReminder do
  log("To send 1st message")
  # cancel any scheduled stacks for this journey
  cancel_scheduled_stacks("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d")
  schedule_stack("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d", in: 22 * 60 * 60)
end

```

## 1 Hour Reminder

```stack
card DropOff1stReminder, then: DisplayDropOff1stReminder do
  update_contact(reengagement_message: "1st message")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_drop_off_1h_later"]
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
  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayDropOff1stReminder, then: DisplayDropOff1stReminderError do
  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@loading_message")
  end
end

card DisplayDropOff1stReminderError, then: DisplayDropOff1stReminderError do
  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Second Reminder

```stack
card DropOff2ndReminder, then: DisplayDropOff2ndReminder do
  update_contact(reengagement_message: "2nd message")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_drop_off_2nd_reminder"]
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
  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayDropOff2ndReminder, then: DisplayDropOff2ndReminderError do
  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@loading_message")
  end
end

card DisplayDropOff2ndReminderError, then: DisplayDropOff2ndReminderError do
  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Third Drop Off

```stack
card DropOff3rdReminder, then: DisplayDropOff3rdReminder do
  update_contact(reengagement_message: "3rd message")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_drop_off_3rd_reminder"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayDropOff3rdReminder when contact.data_preference == "text only",
  then: DropOff3rdReminderError do
  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@loading_message")
  end
end

# Show image
card DisplayDropOff3rdReminder, then: DropOff3rdReminderError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card DropOff3rdReminderError, then: DropOff3rdReminderError do
  buttons(
    DropOffGoTo: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Remind Me Tomorrow

```stack
card ReminderRequest, then: DisplayReminderRequest do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_requested"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value

  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayReminderRequest when contact.data_preference == "text only",
  then: ReminderRequestError do
  buttons(
    SaveReengagement: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@loading_message")
  end
end

# Show image
card DisplayReminderRequest, then: ReminderRequestError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    SaveReengagement: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card ReminderRequestError, then: ReminderRequestError do
  buttons(
    SaveReengagement: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Go To Where User Dropped Off

```stack
card SaveReengagement, then: DropOff1stReminder do
  write_result("reengaged_point", "@contact.reengagement_message")
end

card DropOffGoTo
     when has_any_phrase(contact.checkpoint, [
            "generic_basic_info",
            "generic_personal_info",
            "generic_daily_life_info"
          ]),
     then: ProfileGeneric do
  log("Go to ProfileGeneric")
end

card DropOffGoTo when has_beginning(contact.checkpoint, "hcw"), then: HCWProfile do
  log("Go to PersonalProfile")
end

card DropOffGoTo when has_beginning(contact.checkpoint, "pregnant_nurse"),
  then: PregnantNurseQuestions do
  log("Go to PregnantNurseQuestions")
end

card DropOffGoTo when contact.checkpoint == "tour", then: ExploringTour do
  log("Go to Exploring Tour")
end

card DropOffGoTo when contact.checkpoint == "profile_classifier", then: ProfileClassifier do
  log("Go to Profile Classifier")
end

card DropOffGoTo
     when contact.checkpoint == "intro_welcome" or is_nil_or_empty(contact.checkpoint),
     then: IntroAndWelcome do
  log("Go to Intro and Welcome")
end

card DropOffGoTo, then: PregnancyQuestions do
  log("Go to PregnancyQuestions")
end

```

## Remind me tomorrow

Will resend a reminder after 23 hours

```stack
card RemindMe, then: ReminderMeMessage do
  update_contact(reengagement_message: "remind me")
  # cancel any scheduled stacks for this journey
  cancel_scheduled_stacks("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d")
  schedule_stack("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d", in: 23 * 60 * 60)
end

```

## Remind Me Tomorrow Message

```stack
card ReminderMeMessage do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_response_remind_me"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value

  text("@message.message")
end

```

## Pregnancy Questions

```stack
card PregnancyQuestions do
  log("Pregnancy Questions")
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

```

## Pregnant Nurse Questions

```stack
card PregnantNurseQuestions do
  log("Pregnant Nurse Questions")
  run_stack("406cd221-3e6d-41cb-bc1e-cec65d412fb8")
end

```

## Profile Generic

```stack
card ProfileGeneric do
  log("Profile Generic")
  run_stack("51701b44-bcca-486e-9c99-bf3545a8ba2d")
end

```

## HCW Profile

```stack
card HCWProfile do
  log("Personal Profile")
  run_stack("38cca9df-21a1-4edc-9c13-5724904ca3c3")
end

```

## Exploring Tour

```stack
card ExploringTour do
  log("Exploring Tour")
  run_stack("4288d6a9-23c9-4fc6-95b7-c675a6254ea5")
end

```

## Profile Classifier

```stack
card ProfileClassifier do
  log("Profile Classifier")
  run_stack("bd590c1e-7a06-49ed-b3a1-623cf94e8644")
end

```

## Intro and Welcome

```stack
card IntroAndWelcome do
  log("Intro and Welcome")
  run_stack("5e59aafb-fc30-41f9-b268-6268173b2aff")
end

```

## Placeholder Form

```stack
card LOCAssessment do
  log("Placeholder Form")
  run_stack("690a9ffd-db6d-42df-ad8f-a1e5b469a099")
end

```