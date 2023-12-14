# Onboarding: Pt 2 - Pregnancy Detail

This is the second flow that users interact with during Onboarding

This flow is about capturing the details of a pregnancy, asking for the day and month to form an Expected Due Date (EDD).

The content for this flow, except for navigation items and validation errors at this stage,  is stored in ContentRepo.  The flow uses the ContentRepo API to fetch content, referencing it by slug.

## This stack updates the following contact fields

* `onboarding_part_2`,  gets set to `incomplete` at the start of this stack, and `complete` at the end
* `edd`, Expectede Due Date, gets set at the end of this stack after we have the EDD month and day provided by the user


## Connections to other stacks

* If the user chooses to add more children, we send them to `Onboarding: Pt 4 - Babies Info`
* If the user selects `Not Now` at the end, we run the stack `Reminders: Schedule Onboarding Re-engagement Msg #1`

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxx |

# Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: HealthGuideSetupMaternal do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "button-error"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  button_error_text = "Button error: @page.body.body.text.value.message"
  update_contact(onboarding_part_2: "incomplete")
end

```

# Health Guide Setup - Maternal

```stack
card HealthGuideSetupMaternal, then: HealthGuideSetupMaternalError do
  update_contact(onboarding_part_2: "incomplete")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "health-guide-setup-maternal"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    EDDMonth: "@button_labels[0]",
    NotNow: "@button_labels[1]",
    Skip: "@button_labels[2]"
  ) do
    text("@page.body.body.text.value.message")
  end
end

card HealthGuideSetupMaternalError, then: HealthGuideSetupMaternal do
  buttons(
    EDDMonth: "@button_labels[0]",
    NotNow: "@button_labels[1]",
    Skip: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

# EDD Month

Asks the user to select the month that the baby is expected  to be born.

Presents the user with a list of 9 months to select from, starting from the current month, up to this month +8. Also provides an option if the month is unknown

<!-- { section: "32d45c54-1f17-4912-a555-2fa9ebe5d4d1", x: 0, y: 0} -->

```stack
card EDDMonth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-month"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
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
    text("@page.body.body.text.value.message")
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
  log("This is ThisMonthPlusTwo")
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

```

# EDD Month Number Error

Shows if month entered is not valid

```stack
card EDDMonthNumberError, then: EDDMonth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-month-number-error"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  text("@page.body.body.text.value.message")
end

```

# EDD Month Unknown

```stack
card EDDMonthUnknown, "I don't know" do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-month-unknown"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    EDDMonth: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@page.body.body.text.value.message")
  end
end

```

# EDD Day

```stack
card EDDDay, then: ValidateEDDDay do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-day"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  edd_day = ask("@page.body.body.text.value.message")
end

card ValidateEDDDay when not has_pattern("@edd_day", "^\d+$"),
  then: EDDDayNumberError do
  log("Non-integer edd day number")
end

card ValidateEDDDay when edd_day < 1, then: EDDDayNumberError do
  log("Edd day number lower than list index")
end

card ValidateEDDDay when edd_day > 31,
  then: EDDDayNumberError do
  log("Edd day number higher than list index")
end

card ValidateEDDDay, then: EDDConfirmation do
  log("Default validate EDD Day")
end

```

# EDD Day Number Error

Shown when the edd day provided is not an integer, or not within range.

```stack
card EDDDayNumberError, then: EDDConfirmation do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-day-number-error"],
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  edd_day = ask("@page.body.body.text.value.message")
end

```

# EDD Confirmation

```stack
card EDDConfirmation, then: SaveEDDAndContinue do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-confirmation"],
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  edd_date_full = date(edd_date_year, edd_date_month, edd_day)
  edd_date_full_str = datevalue(edd_date_full, "%Y-%m-%d")
  text("TODO ask Rudi about this date formatting issue - @edd_date_full_str")
  question = substitute("@page.body.body.text.value.message", "{{edd}}", "@edd_date_full_str")

  buttons(
    SaveEDDAndContinue: "Yes it is correct",
    EDDMonth: "Change date"
  ) do
    text("@question")
  end
end

```

# SaveEDDAndContinue

Sends the user to the next part of the onboarding flow.

```stack
card SaveEDDAndContinue do
  update_contact(onboarding_part_2: "complete")
  update_contact(edd: "@edd_date_full_str")
  log("EDD Saved as @edd_date_full_str")

  # SBM: Schedule pregnancy
  run_stack("e323943a-b48e-495d-b0e2-e9349c58f854")
  # Go to onboarding part 3
  run_stack("404dd56e-59ef-4002-b9b9-9956743b22a9")
end

```

## TODO

Temporary TODO card to route to when we haven't created the destination yet

```stack
card NotNow, then: TODO do
  # SBM: Schedule reminder
  log("User clicked NotNow")
  run_stack("b93ddac0-5a3d-42a1-af01-5bbc865ef389")
end

card Skip, then: TODO do
  log("User clicked Skip")
  update_contact(onboarding_part_2: "incomplete")
end

card MainMenu, then: TODO do
  log("Go to the main menu, still to be implemented")
end

card TODO do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["whatsapp", "true"],
        ["slug", "todo"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  text("@page.body.body.text.value.message")
end

```

# Content Dependencies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

## Message Content Slugs

* `health-guide-setup-maternal` , Intro message with 3 buttons, `Get Started`, `Learn more` and `Skip`
* `edd-month` , Message asking the used to select an EDD month, from a list of 9 options starting from the current month, and ending at `currentMonth+8`
* `edd-unknown`, Message expressing the importance of knowing the Expected Due Date (EDD).  Presents user with two buttons, `Go back` and `Main menu`
* `edd-day` , Message, asking for the user to input the Edd Day
* `edd-confirm` , Message with two buttons

## Error Message Slugs

TODO: Should we have all the error messages and acknowledgement messages here, or document them more "locally" to the code sections that use them below?

* `xxx` , xx
* `xxxxx` , xx