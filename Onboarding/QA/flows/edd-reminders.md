## EDD Reminder

This is the EDD Reminder flow that gets triggered if the user selects that the EDD month is unknown.

This flow is scheduled to be run 5 days later, so it must start with a template message as per WA requirements.

## Contact fields

* `edd`, saves the EDD if the user chooses to update it

## Flow results

* `edd`, saves the EDD if the user chooses to update it

## Connections to other stacks

The user can navigate to either of these options at the end of this flow. (Currently both of these are placeholders that navigate the user to the Profile Pregnancy Health Flow)

* Main Menu
* Health Guide

## Auth

The token for ContentRepo is stored in a global dictionary.

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_edd_reminder`, The EDD reminder message. The message isn't actually used as it's part of the template, but we need the button text saved as part of the message.
* `mnch_onboarding_edd_got_it`, The message the user sees if they tap on the Got it button in the EDD reminder
* `mnch_onboarding_edd_month`, A message asking the user for the EDD month
* `mnch_onboarding_edd_unknown`, A message stressing the importance of knowing the EDD
* `mnch_onboarding_edd_day`, A message asking the user for the EDD day
* `mnch_onboarding_edd_confirmed`, A message confirming the EDD
* `mnch_onboarding_edd_do_it_later`, A message that gets displayed if the user says they'll fill in the EDD later

## Error messages

* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons
* `mnch_onboarding_error_handling_list_message`, for when a user sends in a message when we're expecting them to press one of the list options
* `mnch_onboarding_unrecognised_number`, for when a user sends in a message that contains a number that doesn't match our validation

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "eddreminder")

```

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: GetLocaleCodes do
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

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_list_message"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_list_message/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  list_error_text = page.body.messages[0].text

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_unrecognised_number/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  unrecognised_number_text = page.body.messages[0].text
end

card GetLocaleCodes when contact.language = "por", then: EDDReminder do
  cms_locale = "pt"
  template_locale = "pt_PT"
end

card GetLocaleCodes, then: EDDReminder do
  cms_locale = "en"
  template_locale = "en_US"
end

```

## EDD Reminder

<!-- { section: "6053de2e-cff0-4e46-9682-b623e3b3e36e", x: 0, y: 0} -->

```stack
card EDDReminder, then: DisplayEDDReminder do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_reminder/",
      query: [
        ["channel", "whatsapp"],
        ["locale", "@cms_locale"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  whatsapp_template_name = content_data.body.body.whatsapp_template_name
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayEDDReminder when contact.data_preference == "text only",
  then: DisplayEDDReminderError do
  send_message_template(
    "@whatsapp_template_name",
    "@template_locale",
    ["@contact.name"],
    buttons: [EDDGotIt, EDDMonth, EDDRUnknown]
  )
end

# Display with image
card DisplayEDDReminder, then: DisplayEDDReminderError do
  image_id = content_data.body.messages[0].image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  send_message_template(
    "@whatsapp_template_name",
    "@template_locale",
    ["@contact.name"],
    image: "@image_data.body.meta.download_url",
    buttons: [EDDGotIt, EDDMonth, EDDRUnknown]
  )
end

card DisplayEDDReminderError, then: DisplayEDDReminderError do
  buttons(
    EDDGotIt: "@button_labels[0]",
    EDDMonth: "@button_labels[1]",
    EDDRUnknown: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## EDD Got It

```stack
card EDDGotIt, "@button_labels[0]", then: DisplayEDDGotIt do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_got_it/",
      query: [
        ["channel", "whatsapp"],
        ["locale", "@cms_locale"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayEDDGotIt, then: DisplayEDDGotItError do
  buttons(MainMenu: "@button_labels[0]") do
    text("@message.text")
  end
end

card DisplayEDDGotItError, then: DisplayEDDGotItError do
  buttons(MainMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## EDD Month

```stack
card EDDMonth, "@button_labels[1]", then: EDDMonthError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_month/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  edd_month = ""
  this_month = now()

  this_month_plus_one = edate(this_month, 1)
  this_month_plus_two = edate(this_month, 2)
  this_month_plus_three = edate(this_month, 3)
  this_month_plus_four = edate(this_month, 4)
  this_month_plus_five = edate(this_month, 5)
  this_month_plus_six = edate(this_month, 6)
  this_month_plus_seven = edate(this_month, 7)
  this_month_plus_eight = edate(this_month, 8)

  list("Month", [
    ThisMonth,
    ThisMonthPlusOne,
    ThisMonthPlusTwo,
    ThisMonthPlusThree,
    ThisMonthPlusFour,
    ThisMonthPlusFive,
    ThisMonthPlusSix,
    ThisMonthPlusSeven,
    ThisMonthPlusEight,
    EDDMonthUnknown
  ]) do
    text("@page.body.messages[0].text")
  end
end

card EDDMonthError, then: EDDMonthError do
  list("Month", [
    ThisMonth,
    ThisMonthPlusOne,
    ThisMonthPlusTwo,
    ThisMonthPlusThree,
    ThisMonthPlusFour,
    ThisMonthPlusFive,
    ThisMonthPlusSix,
    ThisMonthPlusSeven,
    ThisMonthPlusEight,
    EDDMonthUnknown
  ]) do
    text("@list_error_text")
  end
end

card ThisMonth, "@datevalue(this_month, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month)
  edd_date_year = year(this_month)
end

card ThisMonthPlusOne, "@datevalue(this_month_plus_one, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_one)
  edd_date_year = year(this_month_plus_one)
end

card ThisMonthPlusTwo, "@datevalue(this_month_plus_two, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_two)
  edd_date_year = year(this_month_plus_two)
end

card ThisMonthPlusThree, "@datevalue(this_month_plus_three, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_three)
  edd_date_year = year(this_month_plus_three)
end

card ThisMonthPlusFour, "@datevalue(this_month_plus_four, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_four)
  edd_date_year = year(this_month_plus_four)
end

card ThisMonthPlusFive, "@datevalue(this_month_plus_five, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_five)
  edd_date_year = year(this_month_plus_five)
end

card ThisMonthPlusSix, "@datevalue(this_month_plus_six, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_six)
  edd_date_year = year(this_month_plus_six)
end

card ThisMonthPlusSeven, "@datevalue(this_month_plus_seven, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_seven)
  edd_date_year = year(this_month_plus_seven)
end

card ThisMonthPlusEight, "@datevalue(this_month_plus_eight, \"%B\")", then: EDDDay do
  edd_date_month = month(this_month_plus_eight)
  edd_date_year = year(this_month_plus_eight)
end

card EDDMonthUnknown, "I don't know", then: EDDMonthUnknownError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_unknown/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["channel", "whatsapp"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    EDDMonth: "@button_labels[0]",
    EDDLater: "@button_labels[1]"
  ) do
    text("@page.body.messages[0].text")
  end
end

card EDDMonthUnknownError, then: EDDMonthUnknownError do
  buttons(
    EDDMonth: "@button_labels[0]",
    EDDLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## EDD Day

```stack
card EDDDay, then: ValidateEDDDay do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_day/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["channel", "whatsapp"]]
    )

  long_months = [1, 3, 5, 7, 8, 10, 12]
  short_months = [4, 6, 9, 11]
  #  February  
  max_date = 29
  max_date = if has_member(long_months, edd_date_month), do: 31, else: max_date
  max_date = if has_member(short_months, edd_date_month), do: 30, else: max_date
  log("max day @max_date, edd date month @edd_date_month")
  edd_day = ask("@page.body.messages[0].text")
end

card ValidateEDDDay when not has_pattern("@edd_day", "^\d+$"),
  then: EDDDayNumberError do
  log("Non-integer edd day number")
end

card ValidateEDDDay when edd_day < 1, then: EDDDayNumberError do
  log("Edd day number lower than first day of month")
end

card ValidateEDDDay when edd_day > max_date,
  then: EDDDayNumberError do
  log("Edd day number higher than max date")
end

card ValidateEDDDay, then: SaveEDDAndContinue do
  log("Default validate EDD Day")
end

card EDDDayNumberError, then: ValidateEDDDay do
  message = substitute(unrecognised_number_text, "{minimum}", "1")
  message = substitute(message, "{maximum}", "@max_date")
  edd_day = ask("@message")
end

```

## Save EDD

```stack
card SaveEDDAndContinue, then: EDDConfirm do
  edd_date_full = date(edd_date_year, edd_date_month, edd_day)

  edd_date_full_str = datevalue(edd_date_full, "%Y-%m-%d")
  log("EDD Saved as @edd_date_full_str")
  update_contact(edd: "@edd_date_full_str")
  write_result("edd", "@edd_date_full_str")
end

```

## EDD Confirm

```stack
card EDDConfirm, then: DisplayEDDConfirm do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_confirmed/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  loading_message = substitute(message.message, "[edd]", "@edd_date_full_str")
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayEDDConfirm, then: DisplayEDDConfirmError do
  buttons(MainMenu: "@button_labels[0]") do
    text("@loading_message")
  end
end

card DisplayEDDConfirmError, then: DisplayEDDConfirmError do
  buttons(MainMenu: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## EDD Unknown

```stack
card EDDRUnknown, "@button_labels[2]", then: DisplayEDDUnknown do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_unknown/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayEDDUnknown when contact.data_preference == "text only",
  then: DisplayEDDUnknownError do
  buttons(
    EDDMonth: "@button_labels[0]",
    EDDLater: "@button_labels[1]"
  ) do
    text("@message.text")
  end
end

# Display with image
card DisplayEDDUnknown, then: DisplayEDDUnknownError do
  image_id = content_data.body.messages[0].image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    EDDMonth: "@button_labels[0]",
    EDDLater: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.text")
  end
end

card DisplayEDDUnknownError, then: DisplayEDDUnknownError do
  buttons(
    EDDMonth: "@button_labels[0]",
    EDDLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## EDD Do It Later

```stack
card EDDLater, then: DisplayEDDLater do

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_edd_do_it_later/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayEDDLater, then: DisplayEDDLaterError do
  buttons(
    MainMenu: "@button_labels[0]",
    HealthGuide: "@button_labels[1]"
  ) do
    text("@message.text")
  end
end

card DisplayEDDLaterError, then: DisplayEDDLaterError do
  buttons(
    MainMenu: "@button_labels[0]",
    HealthGuide: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

# TODO these are the placeholders

```stack
card MainMenu do
  text("Main menu goes here")
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

card HealthGuide do
  text("Health guide goes here")
  run_stack("f582feb5-8605-4509-8279-ec17202b42a6")
end

```