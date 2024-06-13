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
    SaveReengagement: "@button_labels[0]",
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
    SaveReengagement: "@button_labels[0]",
    RemindMe: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card DropOff3rdReminderError, then: DropOff3rdReminderError do
  buttons(
    SaveReengagement: "@button_labels[0]",
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

### TODO This is a place holder

```stack
card SaveReengagement, then: DropOff1stReminder do
  write_result("reengaged_point", contact.reengagement_message)
end

card DropOffGoTo when contact.checkpoint == "generic_basic_info", then: BasicProfile do
  log("Go to BasicProfile")
end

card DropOffGoTo when contact.checkpoint == "generic_personal_info", then: PersonalProfile do
  log("Go to PersonalProfile")
end

card DropOffGoTo when contact.checkpoint == "generic_daily_life_info", then: LOCAssessment do
  log("Go to LOCAssessment")
end

card DropOffGoTo when contact.checkpoint == "pregnant_nurse_profile", then: NurseQuestions do
  log("Go to NurseQuestions")
end

card DropOffGoTo, then: PregnancyQuestions do
  log("Go to PregnancyQuestions")
end

```

## Remind me tomorrow

Will resend a reminder after 23 hours

```stack
card RemindMe do
  update_contact(reengagement_message: "remind me")
  # cancel any scheduled stacks for this journey
  cancel_scheduled_stacks("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d")
  schedule_stack("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d", in: 23 * 60 * 60)
end

```

## Pregnancy Questions

```stack
card PregnancyQuestions do
  log("Pregnancy Questions")
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

```

## Nurse Questions

```stack
card NurseQuestions do
  log("Nurse Questions")
  run_stack("38cca9df-21a1-4edc-9c13-5724904ca3c3")
end

```

## Basic Profile

```stack
card BasicProfile do
  log("Basic Profile")
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

```

## Personal Profile

```stack
card PersonalProfile do
  log("Personal Profile")
  run_stack("61a880e4-cf7b-47c5-a047-60802aaa7975")
end

```

## LOC Assessment

```stack
card LOCAssessment do
  log("Loc Assessment")
  # run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

```