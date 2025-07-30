<!-- { section: "97ca43be-ba28-49df-98f1-4207014d0d65", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "engage")

```

<!-- { section: "9a4ecd16-1072-4929-8f8f-5f1c63cdd452", x: 0, y: 0} -->

```stack
card FetchError, then: DropOffRedirect do
  # Fetch and store the error message, so that we don't need to do it for every error card
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_button/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  button_error_text = page.body.messages[0].text
end

```

## Drop Off Redirect And Schedule Reminder

```stack
card DropOffRedirect when contact.reengagement_message == "1st message", then: DropOff2ndReminder do
  log("To send 2nd message")
  # cancel any scheduled stacks for this journey
  cancel_scheduled_stacks("689e019d-beb5-4ba2-8c04-f4663a67ab81")
  schedule_stack("689e019d-beb5-4ba2-8c04-f4663a67ab81", in: 23 * 60 * 60)
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
  cancel_scheduled_stacks("689e019d-beb5-4ba2-8c04-f4663a67ab81")
  schedule_stack("689e019d-beb5-4ba2-8c04-f4663a67ab81", in: 22 * 60 * 60)
end

```

## 1 Hour Reminder

```stack
card DropOff1stReminder, then: DisplayDropOff1stReminder do
  update_contact(reengagement_message: "1st message")

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_drop_off_1h_later/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.title)
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

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_drop_off_2nd_reminder/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.title)
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

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_drop_off_3rd_reminder/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.title)
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
  image_id = page.body.messages[0].image

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
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_reminder_requested/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]

  name = if is_nil_or_empty(contact.name), do: "there", else: contact.name
  loading_message = substitute(message.message, "{username}", "@name")
  button_labels = map(message.buttons, & &1.title)
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
  image_id = page.body.messages[0].image

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
  cancel_scheduled_stacks("689e019d-beb5-4ba2-8c04-f4663a67ab81")
  schedule_stack("689e019d-beb5-4ba2-8c04-f4663a67ab81", in: 23 * 60 * 60)
end

```

## Remind Me Tomorrow Message

```stack
card ReminderMeMessage do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_response_remind_me/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]

  text("@message.text")
end

```

## Pregnancy Questions

```stack
card PregnancyQuestions do
  log("Pregnancy Questions")
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

```

## Pregnant Nurse Questions

```stack
card PregnantNurseQuestions do
  log("Pregnant Nurse Questions")
  run_stack("1ed10e1b-f812-4730-8ec5-3f46088c41c7")
end

```

## Profile Generic

```stack
card ProfileGeneric do
  log("Profile Generic")
  run_stack("718e6b27-d818-40cf-8a7b-50c17bd236ba")
end

```

## HCW Profile

```stack
card HCWProfile do
  log("Personal Profile")
  run_stack("9aa596d3-40f0-4349-8322-e44d1fd1d127")
end

```

## Exploring Tour

```stack
card ExploringTour do
  log("Exploring Tour")
  run_stack("359b3ff4-796d-4b80-91a6-15532c7bdb90")
end

```

## Profile Classifier

```stack
card ProfileClassifier do
  log("Profile Classifier")
  run_stack("c77efa62-1c9d-4ace-ae7a-4585e4e929d1")
end

```

## Intro and Welcome

```stack
card IntroAndWelcome do
  log("Intro and Welcome")
  run_stack("e2203073-f8b3-45f4-b19d-4079d5af368a")
end

```

## Placeholder Form

```stack
card LOCAssessment do
  log("Placeholder Form")
  run_stack("9bd8c27a-d08e-4c9e-8623-b4007373437e")
end

```