<!-- { section: "e544152f-bf53-4d7c-ae1b-c84314772219", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "profile")

```

# Onboarding: Profile Pregnancy Health

This is the main onboarding flow that users interact with during onboarding. They are directed here to complete their profile for pregnancy health if they are pregnant, have a partner who is pregnant, or are curious about the content.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `gender`, This stack sets the gender field for the user. If the user selects `im_pregnant` as their status below it defaults to `female`, otherwise it lets them set it to `male`, `female` or `other`.
* `edd`, Expected Due Date, gets set after we have the EDD month and day provided by the user.
* `other_children`, How many other children this user has.
* `checkpoint`, the checkpoint for where we are in onboarding. One of `basic_pregnancy_profile`, `pregnant_mom_profile`, `pregnancy_basic_info`, `pregnancy_personal_info`, `pregnancy_daily_life_info`

## Flow results

* `pregnancy_status`, One of `im_pregnant`, `partner_pregnant` or `curious`
* `profile_completion`, How much of the profile they have completed e.g. 0%, 25%, 50%, 100%
* `pregnancy_sentiment`, How they are feeling about their pregnancy. This result applies only to users that have selected `im_pregnant` as their above status.

## Connections to other stacks

* The Profile Classifier stack directs users to this stack if they select the Pregnancy Health option

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: Checkpoint do
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

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_list_message"]
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

  list_error_text = page.body.body.text.value.message

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_unrecognised_number"]
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

  unrecognised_number_text = page.body.body.text.value.message
end

```

## Check Points

Here we check the checkpoints and forward the user to the correct point depending on where they left off.

```stack
card Checkpoint
     when contact.checkpoint == "pregnant_mom_profile" and
            contact.profile_completion == "0%",
     then: PregnantEDDMonth do
  log("Go to PregnantEDDMonth")
end

card Checkpoint
     when contact.checkpoint == "pregnant_mom_profile" and contact.profile_completion == "25%",
     then: ProfileProgress25 do
  log("Go to ProfileProgress25")
end

card Checkpoint
     when contact.checkpoint == "pregnant_mom_profile" and contact.profile_completion == "50%",
     then: ProfileProgress50 do
  log("Go to ProfileProgress50")
end

card Checkpoint
     when contact.checkpoint == "pregnant_mom_profile" and contact.profile_completion == "100%",
     then: ProfileProgress100 do
  log("Go to ProfileProgress100")
end

card Checkpoint
     when contact.checkpoint == "partner_of_pregnant_mom_profile" and
            contact.profile_completion == "0%",
     then: PartnerPregnant do
  log("Go to PartnerPregnant")
end

card Checkpoint
     when contact.checkpoint == "partner_of_pregnant_mom_profile" and
            contact.profile_completion == "25%",
     then: ProfileProgress25Secondary do
  log("Go to ProfileProgress25")
end

card Checkpoint
     when contact.checkpoint == "partner_of_pregnant_mom_profile" and
            contact.profile_completion == "50%",
     then: ProfileProgress50 do
  log("Go to ProfileProgress50")
end

card Checkpoint
     when contact.checkpoint == "partner_of_pregnant_mom_profile" and
            contact.profile_completion == "100%",
     then: ProfileProgress100 do
  log("Go to ProfileProgress100")
end

card Checkpoint
     when contact.checkpoint == "curious_pregnancy_profile" and
            contact.profile_completion == "0%",
     then: Curious do
  log("Go to Curious")
end

card Checkpoint
     when contact.checkpoint == "curious_pregnancy_profile" and
            contact.profile_completion == "25%",
     then: ProfileProgress25Secondary2 do
  # TODO used placeholder
  log("Go to ProfileProgress25")
end

card Checkpoint
     when contact.checkpoint == "curious_pregnancy_profile" and
            contact.profile_completion == "50%",
     then: ProfileProgress50 do
  log("Go to ProfileProgress50")
end

card Checkpoint
     when contact.checkpoint == "curious_pregnancy_profile" and
            contact.profile_completion == "100%",
     then: ProfileProgress100 do
  log("Go to ProfileProgress100")
end

card Checkpoint when contact.checkpoint == "pregnancy_basic_info", then: CompleteProfile do
  log("Go to Basic Profile Questions")
end

card Checkpoint
     when contact.checkpoint == "pregnancy_personal_info",
     then: ContinueProfileCompletion do
  log("Go to Personal Profile Question")
end

card Checkpoint
     when contact.checkpoint == "pregnancy_daily_life_info",
     then: PregnancyDailyLifeInfo do
  log("Go to Pregnancy Daily Life Info")
end

card Checkpoint, then: Question1 do
  log("Go to Question1")
  update_contact(checkpoint: "basic_pregnancy_profile")
end

```

## Question 1

This is the first Profile question. This one applies to all flows, and from here there is branching dependent on the answer. Answers can be:

* I'm pregnant
* Partner is pregnant
* Just curious

```stack
card Question1, then: Question1Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_qa_01"]
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
  button_labels = map(message.buttons, & &1.value.title)

  status =
    buttons(
      ImPregnant: "@button_labels[0]",
      PartnerPregnant: "@button_labels[1]",
      Curious: "@button_labels[2]"
    ) do
      text("@message.message")
    end
end

card Question1Error, then: Question1Error do
  status =
    buttons(
      ImPregnant: "@button_labels[0]",
      PartnerPregnant: "@button_labels[1]",
      Curious: "@button_labels[2]"
    ) do
      text("@button_error_text")
    end
end

card ImPregnant, then: PregnantEDDMonth do
  update_contact(gender: "female")
  update_contact(pregnancy_status: "@status")
  update_contact(checkpoint: "pregnant_mom_profile")
  update_contact(profile_completion: "0%")
  write_result("pregnancy_status", status)
  write_result("profile_completion", "0%")
end

```

# I'm pregnant

This is the set of questions and content for the user if they select that they are pregnant.

## Question 2 - EDD Month

Asks the user to select the month that the baby is expected  to be born.

Presents the user with a list of 9 months to select from, starting from the current month, up to this month +8. Also provides an option if the month is unknown

```stack
card PregnantEDDMonth, then: EDDMonthError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_qa_02"]
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

card ThisMonth, "@datevalue(this_month, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month)
  edd_date_year = year(this_month)
end

card ThisMonthPlusOne, "@datevalue(this_month_plus_one, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_one)
  edd_date_year = year(this_month_plus_one)
end

card ThisMonthPlusTwo, "@datevalue(this_month_plus_two, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_two)
  edd_date_year = year(this_month_plus_two)
end

card ThisMonthPlusThree, "@datevalue(this_month_plus_three, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_three)
  edd_date_year = year(this_month_plus_three)
end

card ThisMonthPlusFour, "@datevalue(this_month_plus_four, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_four)
  edd_date_year = year(this_month_plus_four)
end

card ThisMonthPlusFive, "@datevalue(this_month_plus_five, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_five)
  edd_date_year = year(this_month_plus_five)
end

card ThisMonthPlusSix, "@datevalue(this_month_plus_six, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_six)
  edd_date_year = year(this_month_plus_six)
end

card ThisMonthPlusSeven, "@datevalue(this_month_plus_seven, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_seven)
  edd_date_year = year(this_month_plus_seven)
end

card ThisMonthPlusEight, "@datevalue(this_month_plus_eight, \"%B\")", then: PregnantEDDDay do
  edd_date_month = month(this_month_plus_eight)
  edd_date_year = year(this_month_plus_eight)
end

card EDDMonthUnknown, "I don't know", then: DisplayEDDMonthUnknown do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_edd_unknown_1"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayEDDMonthUnknown when contact.data_preference == "text only",
  then: EDDMonthUnknownError do
  buttons(
    PregnantEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Show image
card DisplayEDDMonthUnknown, then: EDDMonthUnknownError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    PregnantEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card EDDMonthUnknownError, then: EDDMonthUnknownError do
  buttons(
    PregnantEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card EDDMonthUnknownBranch when status == "im_pregnant", then: ProfileProgress25 do
  schedule_stack("15c9127a-2e90-4b99-a41b-25e2a39d453f", at: datetime_add(now(), 5, "D"))
  log("EDD month unknown, navigating to profile progess 50%")
end

card EDDMonthUnknownBranch when status == "partner_pregnant", then: PartnerPregnantGender do
  log("EDD month unknown, navigating to PartnerPregnantGender")
end

card EDDMonthUnknownBranch do
  log("EDDMonthUnknownBranch: How did we get here and what do we do now?")
end

```

## Question 3 - EDD Day

Asks the user to enter the EDD day

```stack
card PregnantEDDDay, then: ValidateEDDDay do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_qa_03"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  long_months = [1, 3, 5, 7, 8, 10, 12]
  short_months = [4, 6, 9, 11]
  #  February  
  max_date = 29
  max_date = if has_member(long_months, edd_date_month), do: 31, else: max_date
  max_date = if has_member(short_months, edd_date_month), do: 30, else: max_date
  log("max day @max_date, edd date month @edd_date_month")
  edd_day = ask("@page.body.body.text.value.message")
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

card ValidateEDDDay, then: EDDConfirmation do
  log("Default validate EDD Day")
end

card EDDDayNumberError, then: ValidateEDDDay do
  message = substitute(unrecognised_number_text, "{minimum}", "1")
  message = substitute(message, "{maximum}", "@max_date")
  edd_day = ask("@message")
end

```

## EDD Confirmation

```stack
card EDDConfirmation, then: PregnantEDDConfirmationError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_confirm_edd"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  edd_date_full = date(edd_date_year, edd_date_month, edd_day)
  month_name = datevalue(edd_date_full, "%B")
  question = substitute("@page.body.body.text.value.message", "{dd}", "@edd_day")
  question = substitute("@question", "{month_name}", "@month_name")
  question = substitute("@question", "{yyyy}", "@edd_date_year")

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    SaveEDDAndContinue: "@button_labels[0]",
    PregnantEDDMonth: "@button_labels[1]"
  ) do
    text("@question")
  end
end

card PregnantEDDConfirmationError, then: PregnantEDDConfirmationError do
  buttons(
    SaveEDDAndContinue: "@button_labels[0]",
    PregnantEDDMonth: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## SaveEDDAndContinue

```stack
card SaveEDDAndContinue, then: ContinueEDDBranch do
  edd_date_full_str = datevalue(edd_date_full, "%Y-%m-%d")
  log("EDD Saved as @edd_date_full_str")
  update_contact(edd: "@edd_date_full_str")
  write_result("edd", "@edd_date_full_str")
end

card ContinueEDDBranch when contact.pregnancy_status == "im_pregnant", then: PregnantFeeling do
  log("User is pregnant. Navigating to Feelings question.")
end

card ContinueEDDBranch when contact.pregnancy_status == "partner_pregnant",
  then: PartnerPregnantGender do
  log("User's partner is pregnant. Navigating to gender identification question.")
end

card ContinueEDDBranch do
  log("ContinueEDDBranch: How did we get here and what do we do now? Status: @status.")
end

```

## Question 5 - How are you feeling about this pregnancy

```stack
card PregnantFeeling, then: PregnantFeelingError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_qa_05"]
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
  list_items = map(message.list_items, & &1.value)

  feeling =
    list("I'm feeling", SaveFeeling, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card PregnantFeelingError, then: PregnantFeelingError do
  feeling =
    list("I'm feeling", SaveFeeling, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card SaveFeeling, then: CalculateWeekOfPregnancy do
  log("Writing @feeling to pregnancy_sentiment")
  write_result("pregnancy_sentiment", feeling)
  update_contact(pregnancy_sentiment: "@feeling")
end

```

## Pregnancy content

Branch showing image depending on the data preference

```stack
card PregnancyContentStart, then: PregnancyContentBranch do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_content_00"]
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
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card PregnancyContentBranch when contact.data_preference == "text only",
  then: PregnancyContentBranchError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Show image
card PregnancyContentBranch, then: PregnancyContentBranchError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card PregnancyContentBranchError, then: PregnancyContentBranchError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Calculate pregnancy weeks and get trimester

```stack
card CalculateWeekOfPregnancy, then: GetTrimester do
  exp_year = if month(now()) > edd_date_month, do: year(now()) + 1, else: year(now())
  exp_date = date(exp_year, edd_date_month, 1)
  week_of_conception = datetime_add(exp_date, -40, "W")

  current_date = now()
  current_year = year(current_date)
  current_month = month(current_date)
  current_day = day(current_date)

  given_date = week_of_conception
  given_year = year(given_date)
  given_month = month(given_date)
  given_day = day(given_date)

  year_diff = (current_year - given_year) * 365.25
  month_diff = (current_month - given_month) * 30.4
  day_diff = current_day - given_day

  log("""
  year_diff @year_diff
  month_diff @month_diff
  day_diff @day_diff
  """)

  pregnancy_in_weeks = (month_diff + year_diff + day_diff) / 7
  pregnancy_in_weeks = split("@pregnancy_in_weeks", ".")[0]

  log("@pregnancy_in_weeks")
end

card GetTrimester when pregnancy_in_weeks <= 12, then: LoadingGoTo do
  trimester = 1
  log("1st trimester")
end

card GetTrimester when pregnancy_in_weeks > 13 and pregnancy_in_weeks <= 27, then: LoadingGoTo do
  trimester = 2
  log("2nd trimester")
end

card GetTrimester, then: LoadingGoTo do
  trimester = 3
  log("3rd trimester")
end

card LoadingGoTo when status = "im_pregnant",
  then: GoToSentiment do
  log("I'm pregnant")
end

card LoadingGoTo, then: LoadingFactoid do
  log("Partner or Curious")
end

card GoToSentiment when has_any_phrase("@feeling", ["happy", "excited"]) and trimester == 1,
  then: SentimentExcitedHappyFirst do
  log("Happy or excited on 1st trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["happy", "excited"]) and trimester == 2,
  then: SentimentExcitedHappySecond do
  log("Happy or excited on 2nd trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["happy", "excited"]) and trimester == 3,
  then: SentimentExcitedHappyThird do
  log("Happy or excited on 3rd trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["scared", "worried"]) and trimester == 1,
  then: SentimentScaredWorriedFirst do
  log("scared or worried on 1st trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["scared", "worried"]) and trimester == 2,
  then: SentimentScaredWorriedSecond do
  log("scared or worried on 2nd trimesster")
end

card GoToSentiment when has_any_phrase("@feeling", ["scared", "worried"]) and trimester == 3,
  then: SentimentScaredWorriedThird do
  log("scared or worried on 3rd trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["other"]) and trimester == 1,
  then: SentimentOtherFirst do
  log("Other on 1st trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["other"]) and trimester == 2,
  then: SentimentOtherSecond do
  log("Other on 2nd trimester")
end

card GoToSentiment when has_any_phrase("@feeling", ["other"]) and trimester == 3,
  then: SentimentOtherThird do
  log("other on 3rd trimester")
end

card GoToSentiment, then: SentimentOtherFirst do
  # Defaults it to other first trimester - to be confirm
  log("No matching feelings @feeling or trimester @trimester")
end

```

## Loading 1

Branch showing image depending on the data preference

```stack
card Loading1, then: Loading1Branch do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_01"]
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
  loading_message = substitute(message.message, "{@username}", "@contact.name")
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Loading1Branch when contact.data_preference == "text only", then: Loading1BranchError do
  buttons(LoadingFactoid: "@button_labels[0]") do
    text("@loading_message")
  end
end

# Show image
card Loading1Branch, then: Loading1BranchError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(LoadingFactoid: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card Loading1BranchError, then: Loading1BranchError do
  buttons(LoadingFactoid: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Loading Facts

```stack
card LoadingFactoid when trimester == 1, then: FactsFactoid1Trimester1 do
  log("Load factoid for 1st trimester")
end

card LoadingFactoid when trimester == 2, then: FactsFactoid1Trimester2 do
  log("Load factoid for 2nd trimester")
end

card LoadingFactoid when trimester == 3, then: FactsFactoid1Trimester3 do
  log("Load factoid for 3rd trimester")
end

card LoadingFactoid, then: CalculateWeekOfPregnancy do
  log("Doesn't have trimester yet it's a partner")
end

```

## Topics

The list of topics is randomised according to the priority and trimester. Should we want to do this in stacks, it is possible with some effort. The basic algorithm is

### 1. Get the trimester

We need the trimester so that we can search by trimester and priority.

To get the trimester we first need the pregnancy in weeks. We can get that by using the code that AloVida has already been so kind to write. See the CalculateWeekOfPregnancy card [here](https://github.com/praekeltfoundation/Alovida-Stacks/blob/main/QA/Onboarding%20-%20Pregnancy.txt)

### 2. Search by priority and trimester tags

```
page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/?tag=priority&tag=trimester_@trimester",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )
```

### 3. Exclude any that have been viewed

We can look at the WHO code to see how they excluded viewed items.

### 4. If there are less than 4 items, do another search by trimester only

```
page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/?tag=trimester_@trimester",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )
```

### 5. Exclude any that have been viewed

### 6. Select a random p number of items where p is 4 - list_len, and add it to the list

You can use this code as a reference to select a random p number of items

```
card SelectRandomPAndAddToList do
  l = ["a", "b", "c", "d", "e", "f", "g", "h"]
  final = ["z"]
  p = 4 - count(final)
  # Get 10 random numbers between 1 and the length of the list of items that you have, basically 10 random indexes
  rands = map(1..10, &rand_between(1, count(l)-1))
  # Make the indexes unique
  urands = uniq(rands)
  # Make a list of lists, where every sublist size is maximum p (i.e. 4 or less) 
  indexes = chunk_every(urands, p)

  # Get the items using the first sublist above as array indexes
  items = map(indexes[0], & (l[&1]))

  # Append the items to your final list
  finalfinal = append(final, items)

  text("@indexes[0]")
  text("@items")
  text("@finalfinal")
end
```

### 7. Display the list

```stack
card TopicsStart, then: DisplayTopicStart do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_topics_01"]
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
end

card DisplayTopicStart when contact.data_preference == "text only", then: TopicsStartError do
  # TODO: Use the DS recommender to find the 4 items in this list to recommend
  # We can look at Browsable FAQs to see how to implement this dynamic list
  # https://github.com/praekeltfoundation/contentrepo-base-flow/blob/main/Browsable%20FAQs/browsable_faqs.md
  list("Choose a Topic",
    ArticleTopic: "item 1",
    ArticleTopic: "item 2",
    ArticleTopic: "item 3",
    ArticleTopic: "item 4",
    ArticleFeedbackNo: "Show me other topics"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayTopicStart, then: TopicsStartError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  selected_topic =
    list("Choose a Topic",
      ArticleTopic: "item 1",
      ArticleTopic: "item 2",
      ArticleTopic: "item 3",
      ArticleTopic: "item 4",
      ArticleFeedbackNo: "Show me other topics"
    ) do
      text("@message.message")
    end
end

card TopicsStartError, then: TopicsStartError do
  list("Choose a Topic",
    ArticleTopic: "item 1",
    ArticleTopic: "item 2",
    ArticleTopic: "item 3",
    ArticleTopic: "item 4",
    ArticleFeedbackNo: "Show me other topics"
  ) do
    text("@list_error_text")
  end
end

card ArticleTopic, then: ArticleTopicError do
  buttons(
    HealthProfessionals: "Complete Profile",
    ArticleFeedback: "Rate this article",
    TopicsStart: "Choose another topic"
  ) do
    text("TODO: Get the article content and display it here")
  end
end

card ArticleTopicError, then: ArticleTopicError do
  buttons(
    HealthProfessionals: "Complete Profile",
    ArticleFeedback: "Rate this article",
    TopicsStart: "Choose another topic"
  ) do
    text("@button_error_text")
  end
end

```

## Article feedback

```stack
card ArticleFeedback, then: ArticleFeedbackError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_feedback"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    ArticleFeedbackYes: "@button_labels[0]",
    ArticleFeedbackNo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ArticleFeedbackError, then: ArticleFeedbackError do
  buttons(
    ArticleFeedbackYes: "@button_labels[0]",
    ArticleFeedbackNo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card ArticleFeedbackYes, then: MomReminderOptIn do
  log("Go to opt-in check")
end

card ArticleFeedbackNo, then: ArticleFeedbackNoError do
  # TODO: Save article feedback
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_feedback_no"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    CompleteProfile: "@button_labels[0]",
    MomReminderOptIn: "@button_labels[1]",
    MomReminderOptIn: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card ArticleFeedbackNoError, then: ArticleFeedbackNoError do
  buttons(
    CompleteProfile: "@button_labels[0]",
    MomReminderOptIn: "@button_labels[1]",
    MomReminderOptIn: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Pregnant Mom Opt-In

```stack
card MomReminderOptIn
     when contact.opted_in == false or
            is_nil_or_empty(contact.opted_in),
     then: HealthProfessionals do
  log("haven't opted in")
  run_stack("537e4867-eb26-482d-96eb-d4783828c622")
end

card MomReminderOptIn, then: HealthProfessionals do
  log("Already opted in")
end

```

## Pregnant Mom Who Is Health Professional

```stack
card HealthProfessionals when contact.info_for_health_professionals == true do
  log("Go to Pregnant nurse")
  run_stack("406cd221-3e6d-41cb-bc1e-cec65d412fb8")
end

card HealthProfessionals, then: ProfileProgress25 do
  log("Info for Health Professionals not added")
end

```

## Profile Progress 25%

```stack
card ProfileProgress25, then: DisplayProfileProgress25 do
  write_result("profile_completion", "25%")
  update_contact(profile_completion: "25%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_25"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayProfileProgress25 when contact.data_preference == "text only",
  then: ProfileProgress25Error do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Show image
card DisplayProfileProgress25, then: ProfileProgress25Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card ProfileProgress25Error, then: ProfileProgress25Error do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Partner Profile Progress 25% Secondary

```stack
card ProfileProgress25Secondary, then: DisplayProfileProgress25Secondary do
  write_result("profile_completion", "25%")
  update_contact(profile_completion: "25%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_25_secondary"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayProfileProgress25Secondary when contact.data_preference == "text only",
  then: ProfileProgress25SecondaryError do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Show image
card DisplayProfileProgress25Secondary, then: ProfileProgress25SecondaryError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card ProfileProgress25SecondaryError, then: ProfileProgress25SecondaryError do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Curious Profile Progress 25% Secondary 2

```stack
card ProfileProgress25Secondary2, then: DisplayProfileProgress25Secondary2 do
  write_result("profile_completion", "25%")
  update_contact(profile_completion: "25%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_25_secondary_"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayProfileProgress25Secondary2 when contact.data_preference == "text only",
  then: ProfileProgress25Secondary2Error do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Show image
card DisplayProfileProgress25Secondary2, then: ProfileProgress25Secondary2Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card ProfileProgress25Secondary2Error, then: ProfileProgress25Secondary2Error do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Complete Profile

```stack
card CompleteProfile, then: ProfileProgress50 do
  # Kick off Basic Profile Questions
  log("Running Basic Profile Questions")
  update_contact(checkpoint: "pregnancy_basic_info")
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

```

## Topics for you

This will be developed as part of a new Activity

```stack
card TopicsForYou, then: TODO do
  log("TopicsForYou to be developed as part of a new activity")
end

```

## Explore health guide

This will be developed as part of a new Activity

```stack
card ExploreHealthGuide, then: TODO do
  log("ExploreHealthGuide to be developed as part of a new activity")
end

```

## Main Menu

```stack
card MainMenu do
  run_stack("21b892d6-685c-458e-adae-304ece46022a")
end

```

## Profile Progess 50%

```stack
card ProfileProgress50, then: ProfileProgress50Error do
  write_result("profile_completion", "50%")
  update_contact(profile_completion: "50%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_50"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value

  pregnancy_questions_answers = [
    contact.pregnancy_status,
    contact.edd,
    contact.pregnancy_sentiment
  ]

  pregnancy_questions_answers_count = count(pregnancy_questions_answers)

  pregnancy_questions_list =
    filter(
      pregnancy_questions_answers,
      &(is_nil_or_empty(&1) == false)
    )

  pregnancy_questions_count = count(pregnancy_questions_list)

  pregnancy_questions_value = "@pregnancy_questions_count/@pregnancy_questions_answers_count"

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

  basic_questions_value = "@basic_questions_count/@basic_questions_answers_count"

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

  progress_message = substitute(message.message, "{basic_info_count}", "@basic_questions_value")

  progress_message =
    substitute(progress_message, "{personal_info_count}", "@personal_questions_value")

  progress_message =
    substitute(progress_message, "{pregnancy_info_count}", "@pregnancy_questions_value")

  progress_message = substitute(progress_message, "{daily_life_count}", "@dma_questions_value")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(ContinueProfileCompletion: "@button_labels[0]") do
    text("@progress_message")
  end
end

card ProfileProgress50Error, then: ProfileProgress50Error do
  buttons(ContinueProfileCompletion: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card ContinueProfileCompletion, then: PregnancyDailyLifeInfo do
  update_contact(checkpoint: "pregnancy_personal_info")
  log("Personal Profile Questions")
  run_stack("61a880e4-cf7b-47c5-a047-60802aaa7975")
end

card PregnancyDailyLifeInfo, then: ProfileProgress100 do
  update_contact(checkpoint: "pregnancy_daily_life_info")
  log("Placeholder Form")
  run_stack("690a9ffd-db6d-42df-ad8f-a1e5b469a099")
end

```

## Profile Progress 100%

```stack
card ProfileProgress100, then: DisplayProfileProgress100 do
  write_result("profile_completion", "100%")
  update_contact(profile_completion: "100%")
  cancel_scheduled_stacks("b11c7c9c-7f02-42c1-9f54-785f7ac5ef0d")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  name = if is_nil_or_empty(contact.name), do: "None", else: contact.name

  opted_in =
    if(contact.opted_in == false or is_nil_or_empty(contact.opted_in), do: "❌", else: "✅")

  pregnancy_questions_answers = [
    contact.pregnancy_status,
    contact.edd,
    contact.pregnancy_sentiment
  ]

  pregnancy_questions_answers_count = count(pregnancy_questions_answers)

  pregnancy_questions_list =
    filter(
      pregnancy_questions_answers,
      &has_text(&1)
    )

  pregnancy_questions_count = count(pregnancy_questions_list)

  pregnancy_questions_value = "@pregnancy_questions_count/@pregnancy_questions_answers_count"

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
      &(&1 != "")
    )

  basic_questions_count = count(basic_questions_list)

  basic_questions_value = "@basic_questions_count/@basic_questions_answers_count"

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
      &(&1 != "")
    )

  personal_questions_count = count(personal_questions_list)

  questions_count = basic_questions_count + personal_questions_count + pregnancy_questions_count

  answers_count =
    basic_questions_answers_count + personal_questions_answers_count +
      pregnancy_questions_answers_count

  edd_string = if is_nil_or_empty("@contact.edd"), do: "Unknown", else: "@contact.edd"

  loading_message = substitute(message.message, "{name}", "@name")
  loading_message = substitute(loading_message, "{edd}", "@edd_string")

  loading_message =
    substitute(loading_message, "{profile_questions}", "@questions_count/@answers_count")

  loading_message = substitute(loading_message, "{get_important_messages}", "@opted_in")
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayProfileProgress100 when contact.data_preference == "text only",
  then: ProfileProgress100Error do
  buttons(
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@loading_message")
  end
end

# Display with image
card DisplayProfileProgress100, then: ProfileProgress100Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card ProfileProgress100Error, then: ProfileProgress100Error do
  buttons(
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Sentiment Other First

```stack
card SentimentOtherFirst, then: DisplaySentimentOtherFirst do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_other_first"]
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

# Text only
card DisplaySentimentOtherFirst when contact.data_preference == "text only",
  then: DisplaySentimentOtherFirstError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentOtherFirst, then: DisplaySentimentOtherFirstError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentOtherFirstError, then: DisplaySentimentOtherFirstError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Other Second

```stack
card SentimentOtherSecond, then: DisplaySentimentOtherSecond do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_other_second"]
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

# Text only
card DisplaySentimentOtherSecond when contact.data_preference == "text only",
  then: DisplaySentimentOtherSecondError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentOtherSecond, then: DisplaySentimentOtherSecondError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentOtherSecondError, then: DisplaySentimentOtherSecondError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Other Third

```stack
card SentimentOtherThird, then: DisplaySentimentOtherThird do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_other_third"]
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

# Text only
card DisplaySentimentOtherThird when contact.data_preference == "text only",
  then: DisplaySentimentOtherThirdError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentOtherThird, then: DisplaySentimentOtherThirdError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentOtherThirdError, then: DisplaySentimentOtherThirdError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Scared Worried First

```stack
card SentimentScaredWorriedFirst, then: DisplaySentimentScaredWorriedFirst do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_scared_worried_first"]
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

# Text only
card DisplaySentimentScaredWorriedFirst when contact.data_preference == "text only",
  then: DisplaySentimentScaredWorriedFirstError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentScaredWorriedFirst, then: DisplaySentimentScaredWorriedFirstError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentScaredWorriedFirstError, then: DisplaySentimentScaredWorriedFirstError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Scared Worried Second

```stack
card SentimentScaredWorriedSecond, then: DisplaySentimentScaredWorriedSecond do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_scared_worried_second"]
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

# Text only
card DisplaySentimentScaredWorriedSecond when contact.data_preference == "text only",
  then: DisplaySentimentScaredWorriedSecondError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentScaredWorriedSecond, then: DisplaySentimentScaredWorriedSecondError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentScaredWorriedSecondError, then: DisplaySentimentScaredWorriedSecondError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Scared Worried Third

```stack
card SentimentScaredWorriedThird, then: DisplaySentimentScaredWorriedThird do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_scared_worried_third"]
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

# Text only
card DisplaySentimentScaredWorriedThird when contact.data_preference == "text only",
  then: DisplaySentimentScaredWorriedThirdError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentScaredWorriedThird, then: DisplaySentimentScaredWorriedThirdError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentScaredWorriedThirdError, then: DisplaySentimentScaredWorriedThirdError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Excited Happy First

```stack
card SentimentExcitedHappyFirst, then: DisplaySentimentExcitedHappyFirst do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_excited_happy_first"]
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

# Text only
card DisplaySentimentExcitedHappyFirst when contact.data_preference == "text only",
  then: DisplaySentimentExcitedHappyFirstError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentExcitedHappyFirst, then: DisplaySentimentExcitedHappyFirstError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentExcitedHappyFirstError, then: DisplaySentimentExcitedHappyFirstError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Excited Happy Second

```stack
card SentimentExcitedHappySecond, then: DisplaySentimentExcitedHappySecond do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_excited_happy_second"]
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

# Text only
card DisplaySentimentExcitedHappySecond when contact.data_preference == "text only",
  then: DisplaySentimentExcitedHappySecondError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentExcitedHappySecond, then: DisplaySentimentExcitedHappySecondError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentExcitedHappySecondError, then: DisplaySentimentExcitedHappySecondError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Sentiment Excited Happy Third

```stack
card SentimentExcitedHappyThird, then: DisplaySentimentExcitedHappyThird do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_sentiment_excited_happy_third"]
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

# Text only
card DisplaySentimentExcitedHappyThird when contact.data_preference == "text only",
  then: DisplaySentimentExcitedHappyThirdError do
  buttons(Loading1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplaySentimentExcitedHappyThird, then: DisplaySentimentExcitedHappyThirdError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplaySentimentExcitedHappyThirdError, then: DisplaySentimentExcitedHappyThirdError do
  buttons(Loading1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Facts Factoid 1 Trimester 1

```stack
card FactsFactoid1Trimester1, then: DisplayFactsFactoid1Trimester1 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_facts_factoid_1_trimester_1"]
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

# Text only
card DisplayFactsFactoid1Trimester1 when contact.data_preference == "text only",
  then: DisplayFactsFactoid1Trimester1Error do
  buttons(FactsFactoid2Trimester1: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayFactsFactoid1Trimester1, then: DisplayFactsFactoid1Trimester1Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FactsFactoid2Trimester1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayFactsFactoid1Trimester1Error, then: DisplayFactsFactoid1Trimester1Error do
  buttons(FactsFactoid2Trimester1: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Facts Factoid 1 Trimester 2

```stack
card FactsFactoid1Trimester2, then: DisplayFactsFactoid1Trimester2 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_facts_factoid_1_trimester_2"]
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

# Text only
card DisplayFactsFactoid1Trimester2 when contact.data_preference == "text only",
  then: DisplayFactsFactoid1Trimester2Error do
  buttons(FactsFactoid2Trimester2: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayFactsFactoid1Trimester2, then: DisplayFactsFactoid1Trimester2Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FactsFactoid2Trimester2: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayFactsFactoid1Trimester2Error, then: DisplayFactsFactoid1Trimester2Error do
  buttons(FactsFactoid2Trimester2: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Facts Factoid 1 Trimester 3

```stack
card FactsFactoid1Trimester3, then: DisplayFactsFactoid1Trimester3 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_facts_factoid_1_trimester_3"]
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

# Text only
card DisplayFactsFactoid1Trimester3 when contact.data_preference == "text only",
  then: DisplayFactsFactoid1Trimester3Error do
  buttons(FactsFactoid2Trimester3: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayFactsFactoid1Trimester3, then: DisplayFactsFactoid1Trimester3Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FactsFactoid2Trimester3: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayFactsFactoid1Trimester3Error, then: DisplayFactsFactoid1Trimester3Error do
  buttons(FactsFactoid2Trimester3: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Facts Factoid 2 Trimester 1

```stack
card FactsFactoid2Trimester1, then: DisplayFactsFactoid2Trimester1 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_facts_factoid_2_trimester_1"]
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

# Text only
card DisplayFactsFactoid2Trimester1 when contact.data_preference == "text only",
  then: DisplayFactsFactoid2Trimester1Error do
  buttons(FactoidTrimester1GoToNext: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayFactsFactoid2Trimester1, then: DisplayFactsFactoid2Trimester1Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FactoidTrimester1GoToNext: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayFactsFactoid2Trimester1Error, then: DisplayFactsFactoid2Trimester1Error do
  buttons(FactoidTrimester1GoToNext: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card FactoidTrimester1GoToNext when status = "partner_pregnant", then: ContentIntro do
  log("Go to partener content intro")
end

card FactoidTrimester1GoToNext when status = "curious", then: CuriousContentIntro do
  log("Go to curious content intro")
end

card FactoidTrimester1GoToNext, then: TopicsStart do
  log("Go to im pregnant content intro")
end

```

## Facts Factoid 2 Trimester 2

```stack
card FactsFactoid2Trimester2, then: DisplayFactsFactoid2Trimester2 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_facts_factoid_2_trimester_2"]
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

# Text only
card DisplayFactsFactoid2Trimester2 when contact.data_preference == "text only",
  then: DisplayFactsFactoid2Trimester2Error do
  buttons(FactoidTrimester2GoToNext: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayFactsFactoid2Trimester2, then: DisplayFactsFactoid2Trimester2Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FactoidTrimester2GoToNext: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayFactsFactoid2Trimester2Error, then: DisplayFactsFactoid2Trimester2Error do
  buttons(FactoidTrimester2GoToNext: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card FactoidTrimester2GoToNext when status = "partner_pregnant", then: ContentIntro do
  log("Go to partener content intro")
end

card FactoidTrimester2GoToNext when status = "curious", then: CuriousContentIntro do
  log("Go to curious content intro")
end

card FactoidTrimester2GoToNext, then: TopicsStart do
  log("Go to im pregnant content intro")
end

```

## Facts Factoid 2 Trimester 3

```stack
card FactsFactoid2Trimester3, then: DisplayFactsFactoid2Trimester3 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_facts_factoid_2_trimester_3"]
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

# Text only
card DisplayFactsFactoid2Trimester3 when contact.data_preference == "text only",
  then: DisplayFactsFactoid2Trimester3Error do
  buttons(FactoidTrimester3GoToNext: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayFactsFactoid2Trimester3, then: DisplayFactsFactoid2Trimester3Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(FactoidTrimester3GoToNext: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayFactsFactoid2Trimester3Error, then: DisplayFactsFactoid2Trimester3Error do
  buttons(FactoidTrimester3GoToNext: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card FactoidTrimester3GoToNext when status = "partner_pregnant", then: ContentIntro do
  log("Go to partener content intro")
end

card FactoidTrimester3GoToNext when status = "curious", then: CuriousContentIntro do
  log("Go to curious content intro")
end

card FactoidTrimester3GoToNext, then: TopicsStart do
  log("Go to im pregnant content intro")
end

```

## My partner is pregnant

This flow first starts off with the same EDD calculator as the `I'm pregnant` option, then branches to a different series of questions.

```stack
card PartnerPregnant, then: PartnerEDDMonth do
  write_result("pregnancy_status", "@status")
  write_result("profile_completion", "0%")
  update_contact(profile_completion: "0%")
  update_contact(pregnancy_status: "@status")
  update_contact(checkpoint: "partner_of_pregnant_mom_profile")
end

card PartnerPregnantGender, then: PartnerPregnantGenderError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_secondary_04"]
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
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    PartnerGenderMale: "@button_labels[0]",
    PartnerGenderFemale: "@button_labels[1]",
    PartnerGenderOther: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card PartnerPregnantGenderError, then: PartnerPregnantGenderError do
  buttons(
    PartnerGenderMale: "@button_labels[0]",
    PartnerGenderFemale: "@button_labels[1]",
    PartnerGenderOther: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card PartnerGenderMale, then: Loading01Secondary do
  update_contact(gender: "male")
end

card PartnerGenderFemale, then: Loading01Secondary do
  update_contact(gender: "female")
end

card PartnerGenderOther, then: Loading01Secondary do
  update_contact(gender: "other")
end

```

## Partner EDD Month

```stack
card PartnerEDDMonth, then: PartnerEDDMonthError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_secondary_02"]
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
    PartnerEDDMonthUnknown
  ]) do
    text("@page.body.body.text.value.message")
  end
end

card PartnerEDDMonthError, then: PartnerEDDMonthError do
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
    PartnerEDDMonthUnknown
  ]) do
    text("@list_error_text")
  end
end

card ThisMonth, "@datevalue(this_month, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month)
  edd_date_year = year(this_month)
end

card ThisMonthPlusOne, "@datevalue(this_month_plus_one, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_one)
  edd_date_year = year(this_month_plus_one)
end

card ThisMonthPlusTwo, "@datevalue(this_month_plus_two, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_two)
  edd_date_year = year(this_month_plus_two)
end

card ThisMonthPlusThree, "@datevalue(this_month_plus_three, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_three)
  edd_date_year = year(this_month_plus_three)
end

card ThisMonthPlusFour, "@datevalue(this_month_plus_four, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_four)
  edd_date_year = year(this_month_plus_four)
end

card ThisMonthPlusFive, "@datevalue(this_month_plus_five, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_five)
  edd_date_year = year(this_month_plus_five)
end

card ThisMonthPlusSix, "@datevalue(this_month_plus_six, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_six)
  edd_date_year = year(this_month_plus_six)
end

card ThisMonthPlusSeven, "@datevalue(this_month_plus_seven, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_seven)
  edd_date_year = year(this_month_plus_seven)
end

card ThisMonthPlusEight, "@datevalue(this_month_plus_eight, \"%B\")", then: PartnerEDDDay do
  edd_date_month = month(this_month_plus_eight)
  edd_date_year = year(this_month_plus_eight)
end

card PartnerEDDMonthUnknown, "I don't know", then: DisplayPartnerEDDMonthUnknown do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_edd_unknown_secondary"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayPartnerEDDMonthUnknown when contact.data_preference == "text only",
  then: PartnerEDDMonthUnknownError do
  buttons(
    PartnerEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Show image
card DisplayPartnerEDDMonthUnknown, then: PartnerEDDMonthUnknownError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    PartnerEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card PartnerEDDMonthUnknownError, then: PartnerEDDMonthUnknownError do
  buttons(
    PartnerEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Partner EDD Day

```stack
card PartnerEDDDay, then: PartnerValidateEDDDay do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_secondary_03"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  long_months = [1, 3, 5, 7, 8, 10, 12]
  short_months = [4, 6, 9, 11]
  #  February  
  max_date = 29
  max_date = if has_member(long_months, edd_date_month), do: 31, else: max_date
  max_date = if has_member(short_months, edd_date_month), do: 30, else: max_date
  log("max day @max_date, edd date month @edd_date_month")
  edd_day = ask("@page.body.body.text.value.message")
end

card PartnerValidateEDDDay when not has_pattern("@edd_day", "^\d+$"),
  then: PartnerEDDDayNumberError do
  log("Non-integer edd day number")
end

card PartnerValidateEDDDay when edd_day < 1, then: PartnerEDDDayNumberError do
  log("Edd day number lower than first day of month")
end

card PartnerValidateEDDDay when edd_day > max_date,
  then: PartnerEDDDayNumberError do
  log("Edd day number higher than max date")
end

card PartnerValidateEDDDay, then: PartnerEDDConfirmation do
  log("Default validate EDD Day")
end

card PartnerEDDDayNumberError, then: PartnerValidateEDDDay do
  message = substitute(unrecognised_number_text, "{minimum}", "1")
  message = substitute(message, "{maximum}", "@max_date")
  edd_day = ask("@message")
end

```

## Partner EDD Confirmation

```stack
card PartnerEDDConfirmation, then: PartnerEDDConfirmationError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_confirm_edd"],
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  edd_date_full = date(edd_date_year, edd_date_month, edd_day)
  month_name = datevalue(edd_date_full, "%B")
  question = substitute("@page.body.body.text.value.message", "{dd}", "@edd_day")
  question = substitute("@question", "{month_name}", "@month_name")
  question = substitute("@question", "{yyyy}", "@edd_date_year")

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    SavePartnerEDD: "@button_labels[0]",
    PartnerEDDMonth: "@button_labels[1]"
  ) do
    text("@question")
  end
end

card PartnerEDDConfirmationError, then: PartnerEDDConfirmationError do
  buttons(
    SavePartnerEDD: "@button_labels[0]",
    PartnerEDDMonth: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Partner Save EDD

```stack
card SavePartnerEDD, then: PartnerPregnantGender do
  edd_date_full_str = datevalue(edd_date_full, "%Y-%m-%d")
  log("EDD Saved as @edd_date_full_str")
  update_contact(edd: "@edd_date_full_str")
  write_result("edd", "@edd_date_full_str")
end

```

## Partner Loading 01 Secondary

```stack
card Loading01Secondary, then: Loading01SecondaryGoTo do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_01_secondary"]
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
  loading_message = substitute(message.message, "{@username}", "@contact.name")
  button_labels = map(message.buttons, & &1.value.title)
end

card Loading01SecondaryGoTo when is_nil_or_empty(edd_date_full),
  then: DisplayLoading01SecondaryNoEDD do
  log("No partner EDD")
end

card Loading01SecondaryGoTo, then: DisplayLoading01Secondary do
  log("Has partner EDD")
end

# Text only
card DisplayLoading01Secondary when contact.data_preference == "text only",
  then: DisplayLoading01SecondaryError do
  buttons(CalculateWeekOfPregnancy: "@button_labels[0]") do
    text("@loading_message")
  end
end

# Display with image
card DisplayLoading01Secondary, then: DisplayLoading01SecondaryError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(CalculateWeekOfPregnancy: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card DisplayLoading01SecondaryError, then: DisplayLoading01SecondaryError do
  buttons(CalculateWeekOfPregnancy: "@button_labels[0]") do
    text("@button_error_text")
  end
end

# Text only
card DisplayLoading01SecondaryNoEDD when contact.data_preference == "text only",
  then: DisplayLoading01SecondaryNoEDDError do
  buttons(Loading02Secondary: "@button_labels[0]") do
    text("@loading_message")
  end
end

# Display with image
card DisplayLoading01SecondaryNoEDD, then: DisplayLoading01SecondaryNoEDDError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Loading02Secondary: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card DisplayLoading01SecondaryNoEDDError, then: DisplayLoading01SecondaryNoEDDError do
  buttons(Loading02Secondary: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Partner Loading 02 Secondary

```stack
card Loading02Secondary, then: DisplayLoading02Secondary do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_02_secondary"]
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

# Text only
card DisplayLoading02Secondary when contact.data_preference == "text only",
  then: DisplayLoading02SecondaryError do
  buttons(ContentIntro: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayLoading02Secondary, then: DisplayLoading02SecondaryError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(ContentIntro: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayLoading02SecondaryError, then: DisplayLoading02SecondaryError do
  buttons(ContentIntro: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Partner Content Intro

```stack
card ContentIntro, then: DisplayContentIntro do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_intro"]
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
  menu_items = map(message.list_items, & &1.value)
end

# #TODO Content

# Text only
card DisplayContentIntro when contact.data_preference == "text only",
  then: DisplayContentIntroError do
  selected_topic =
    list("Select option",
      Topic1: "@menu_items[0]",
      Topic2: "@menu_items[1]",
      Topic3: "@menu_items[2]",
      Topic4: "@menu_items[3]",
      Other: "@menu_items[4]"
    ) do
      text("@message.message")
    end
end

# Display with image
card DisplayContentIntro, then: DisplayContentIntroError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  selected_topic =
    list("Select option",
      Topic1: "@menu_items[0]",
      Topic2: "@menu_items[1]",
      Topic3: "@menu_items[2]",
      Topic4: "@menu_items[3]",
      Other: "@menu_items[4]"
    ) do
      image("@image_data.body.meta.download_url")
      text("@message.message")
    end
end

card DisplayContentIntroError, then: DisplayContentIntroError do
  selected_topic =
    list("Select option",
      Topic1: "@menu_items[0]",
      Topic2: "@menu_items[1]",
      Topic3: "@menu_items[2]",
      Topic4: "@menu_items[3]",
      Other: "@menu_items[4]"
    ) do
      text("@list_error_text")
    end
end

card Topic1, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Topic2, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Topic3, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Topic4, then: ArticleTopic01Secondary do
  update_contact(topic: "@selected_topic")
end

card Other, then: ContentFeedbackNo do
  update_contact(topic: "@selected_topic")
end

```

## Partner Article Topic 01 Secondary

```stack
card ArticleTopic01Secondary, then: DisplayArticleTopic01Secondary do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_article_topic_01_secondary"]
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

# TODO Content

# Text only
card DisplayArticleTopic01Secondary when contact.data_preference == "text only",
  then: DisplayArticleTopic01SecondaryError do
  buttons(
    HealthProfessionalsSecondary: "@button_labels[0]",
    ContentFeedback: "@button_labels[1]",
    ContentIntro: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayArticleTopic01Secondary, then: DisplayArticleTopic01SecondaryError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    HealthProfessionalsSecondary: "@button_labels[0]",
    ContentFeedback: "@button_labels[1]",
    ContentIntro: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayArticleTopic01SecondaryError, then: DisplayArticleTopic01SecondaryError do
  buttons(
    HealthProfessionalsSecondary: "@button_labels[0]",
    ContentFeedback: "@button_labels[1]",
    ContentIntro: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Partner Content Feedback

```stack
card ContentFeedback, then: DisplayContentFeedback do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_feedback"]
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

card DisplayContentFeedback, then: DisplayContentFeedbackError do
  buttons(
    ReminderOptIn: "@button_labels[0]",
    ContentFeedbackNo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayContentFeedbackError, then: DisplayContentFeedbackError do
  buttons(
    ReminderOptIn: "@button_labels[0]",
    ContentFeedbackNo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Partner Content Feedback No

```stack
card ContentFeedbackNo, then: DisplayContentFeedbackNo do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_feedback_no"]
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

card DisplayContentFeedbackNo, then: DisplayContentFeedbackNoError do
  buttons(
    SecondaryOnboarding: "@button_labels[0]",
    ProfileProgress25Secondary: "@button_labels[1]",
    ProfileProgress25Secondary: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card DisplayContentFeedbackNoError, then: DisplayContentFeedbackNoError do
  buttons(
    SecondaryOnboarding: "@button_labels[0]",
    ProfileProgress25Secondary: "@button_labels[1]",
    ProfileProgress25Secondary: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card SecondaryOnboarding, then: ProfileProgress50 do
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

```

## Partner Reminder Opt In

```stack
card ReminderOptIn
     when contact.opted_in == false or
            is_nil_or_empty(contact.opted_in),
     then: DisplayReminderOptIn do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_opt_in"]
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

card DisplayReminderOptIn, then: DisplayReminderOptInError do
  buttons(
    ReminderOptInYes: "@button_labels[0]",
    ReminderOptInNo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayReminderOptInError, then: DisplayReminderOptInError do
  buttons(
    ReminderOptInYes: "@button_labels[0]",
    ReminderOptInNo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card ReminderOptIn, then: HealthProfessionalsSecondary do
  log("Already opted in")
end

```

## Partner Reminder Opt In Yes

```stack
card ReminderOptInYes, then: HealthProfessionalsSecondary do
  update_contact(opted_in: "true")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_opt_in_yes"]
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
  loading_message = substitute(message.message, "{@username}", "@contact.name")
  text("@loading_message")
end

```

## Partner Reminder Opt In No

```stack
card ReminderOptInNo, then: HealthProfessionalsSecondary do
  update_contact(opted_in: "false")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_opt_in_no"]
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

  text("@message.message")
end

```

## Health Professional Information

```stack
card HealthProfessionalsSecondary when contact.info_for_health_professionals == true do
  log("Go to Pregnant nurse")
  run_stack("406cd221-3e6d-41cb-bc1e-cec65d412fb8")
end

card HealthProfessionalsSecondary, then: ProfileProgress25Secondary do
  log("Info for Health Professionals not added")
end

```

## Curious 01

```stack
card Curious, then(Curious01) do
  update_contact(checkpoint: "curious_pregnancy_profile")
  update_contact(profile_completion: "0%")
  write_result("profile_completion", "0%")
end

card Curious01, then: DisplayCurious do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_01"]
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

card DisplayCurious, then: DisplayCuriousError do
  gender =
    buttons(
      MaleGender: "@button_labels[0]",
      FemaleGender: "@button_labels[1]",
      OtherGender: "@button_labels[2]"
    ) do
      text("@message.message")
    end
end

card DisplayCuriousError, then: DisplayCuriousError do
  gender =
    buttons(
      MaleGender: "@button_labels[0]",
      FemaleGender: "@button_labels[1]",
      OtherGender: "@button_labels[2]"
    ) do
      text("@button_error_text")
    end
end

card MaleGender, then: Curious02 do
  update_contact(gender: "male")
end

card FemaleGender, then: Curious02 do
  update_contact(gender: "female")
end

card OtherGender, then: Curious02 do
  update_contact(gender: "other")
end

```

## Curious 02

```stack
card Curious02, then: DisplayCurious02 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_02"]
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
  menu_items = map(message.list_items, & &1.value)
end

card DisplayCurious02, then: DisplayCurious02Error do
  selected_child =
    list("Other children",
      Children0: "@menu_items[0]",
      Children1: "@menu_items[1]",
      Children2: "@menu_items[2]",
      Children3: "@menu_items[3]",
      Children4: "@menu_items[4]"
    ) do
      text("@message.message")
    end
end

card DisplayCurious02Error, then: DisplayCurious02Error do
  selected_child =
    list("Other children",
      Children0: "@menu_items[0]",
      Children1: "@menu_items[1]",
      Children2: "@menu_items[2]",
      Children3: "@menu_items[3]",
      Children4: "@menu_items[4]"
    ) do
      text("@list_error_text")
    end
end

card Children0 when status == "curious", then: Curious03 do
  update_contact(other_children: "0")
end

card Children1 when status == "curious", then: Curious03 do
  update_contact(other_children: "1")
end

card Children2 when status == "curious", then: Curious03 do
  update_contact(other_children: "2")
end

card Children3 when status == "curious", then: Curious03 do
  update_contact(other_children: "3+")
end

card Children4 when status == "curious", then: Curious03 do
  update_contact(other_children: "skip")
end

```

## Curious 03

```stack
card Curious03, then: DisplayCurious03 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_03"]
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
  menu_items = map(message.list_items, & &1.value)
end

card DisplayCurious03, then: DisplayCurious03Error do
  selected_topic =
    list("Select option",
      FirstTrimester: "@menu_items[0]",
      SecondTrimester: "@menu_items[1]",
      ThirdTrimester: "@menu_items[2]",
      GeneralInfo: "@menu_items[3]",
      SkipQuestion: "@menu_items[4]"
    ) do
      text("@message.message")
    end
end

card DisplayCurious03Error, then: DisplayCurious03Error do
  selected_topic =
    list("Select option",
      FirstTrimester: "@menu_items[0]",
      SecondTrimester: "@menu_items[1]",
      ThirdTrimester: "@menu_items[2]",
      GeneralInfo: "@menu_items[3]",
      SkipQuestion: "@menu_items[4]"
    ) do
      text("@list_error_text")
    end
end

card FirstTrimester, then: LoadingComponent01 do
  write_result("pregnancy_stage_interest", "First trimester")
end

card SecondTrimester, then: LoadingComponent01 do
  write_result("pregnancy_stage_interest", "Second trimester")
end

card ThirdTrimester, then: LoadingComponent01 do
  write_result("pregnancy_stage_interest", "Third trimester")
end

card GeneralInfo, then: LoadingComponent01 do
  write_result("pregnancy_stage_interest", "General pregnancy info")
end

card SkipQuestion, then: CuriousContentFeedback do
  write_result("pregnancy_stage_interest", "Skip this question")
end

```

## Loading Component 01

```stack
card LoadingComponent01, then: DisplayLoadingComponent01 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_component_01"]
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
  loading_message = substitute(message.message, "{@username}", "@contact.name")
  button_labels = map(message.buttons, & &1.value.title)
end

# TODO display facts 
# Text only
card DisplayLoadingComponent01 when contact.data_preference == "text only",
  then: DisplayLoadingComponent01Error do
  buttons(LoadingComponentGoTo: "@button_labels[0]") do
    text("@loading_message")
  end
end

# Display with image
card DisplayLoadingComponent01, then: DisplayLoadingComponent01Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(LoadingComponentGoTo: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@loading_message")
  end
end

card DisplayLoadingComponent01Error, then: DisplayLoadingComponent01Error do
  buttons(LoadingComponentGoTo: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card LoadingComponentGoTo when selected_topic = "first_trimester", then: FactsFactoid1Trimester1 do
  log("First trimester topic")
end

card LoadingComponentGoTo when selected_topic = "second_trimester", then: FactsFactoid1Trimester2 do
  log("Second trimester topic")
end

card LoadingComponentGoTo when selected_topic = "third_trimester", then: FactsFactoid1Trimester3 do
  log("Third trimester topic")
end

card LoadingComponentGoTo when selected_topic = "general_info", then: LoadingComponent02 do
  log("General pregnancy topic")
end

card LoadingComponentGoTo, then: CuriousContentIntro do
  log("Skip topic @selected_topic")
end

```

```stack
card LoadingComponent02, then: DisplayLoadingComponent02 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_component_02"]
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

# TODO Content

# Text only
card DisplayLoadingComponent02 when contact.data_preference == "text only",
  then: DisplayLoadingComponent02Error do
  buttons(CuriousContentIntro: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayLoadingComponent02, then: DisplayLoadingComponent02Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(CuriousContentIntro: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayLoadingComponent02Error, then: DisplayLoadingComponent02Error do
  buttons(CuriousContentIntro: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Curious Content Intro

```stack
card CuriousContentIntro, then: DisplayCuriousContentIntro do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_content_intro"]
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
  menu_items = map(message.list_items, & &1.value)
end

# #TODO Content

# Text only
card DisplayCuriousContentIntro when contact.data_preference == "text only",
  then: DisplayCuriousContentIntroError do
  selected_topic =
    list("Choose a topic",
      ArticleTopic01: "@menu_items[0]",
      ArticleTopic01: "@menu_items[1]",
      ArticleTopic01: "@menu_items[2]",
      ArticleTopic01: "@menu_items[3]",
      CuriousContentFeedback: "@menu_items[4]"
    ) do
      text("@message.message")
    end
end

# Display with image
card DisplayCuriousContentIntro, then: DisplayCuriousContentIntroError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

  selected_topic =
    list("Choose a topic",
      ArticleTopic01: "@menu_items[0]",
      ArticleTopic01: "@menu_items[1]",
      ArticleTopic01: "@menu_items[2]",
      ArticleTopic01: "@menu_items[3]",
      CuriousContentFeedback: "@menu_items[4]"
    ) do
      text("@message.message")
    end
end

card DisplayCuriousContentIntroError, then: DisplayCuriousContentIntroError do
  selected_topic =
    list("Choose a topic",
      ArticleTopic01: "@menu_items[0]",
      ArticleTopic01: "@menu_items[1]",
      ArticleTopic01: "@menu_items[2]",
      ArticleTopic01: "@menu_items[3]",
      CuriousContentFeedback: "@menu_items[4]"
    ) do
      text("@list_error_text")
    end
end

```

## Curious Article Topic 01

```stack
card ArticleTopic01, then: DisplayArticleTopic01 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_article_topic_01"]
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

# TODO Content

# Text only
card DisplayArticleTopic01 when contact.data_preference == "text only",
  then: DisplayArticleTopic01Error do
  buttons(
    HealthProfessionalsSecondary2: "@button_labels[0]",
    CuriousContent05: "@button_labels[1]",
    CuriousContentIntro: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayArticleTopic01, then: DisplayArticleTopic01Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    HealthProfessionalsSecondary2: "@button_labels[0]",
    CuriousContent05: "@button_labels[1]",
    CuriousContentIntro: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card DisplayArticleTopic01Error, then: DisplayArticleTopic01Error do
  buttons(
    HealthProfessionalsSecondary2: "@button_labels[0]",
    CuriousContent05: "@button_labels[1]",
    CuriousContentIntro: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Curious Content 05

```stack
card CuriousContent05, then: DisplayCuriousContent05 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_content_05"]
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

card DisplayCuriousContent05, then: DisplayCuriousContent05Error do
  buttons(
    CuriousReminderOptIn: "@button_labels[0]",
    CuriousContentFeedback: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card DisplayCuriousContent05Error, then: DisplayCuriousContent05Error do
  buttons(
    CuriousReminderOptIn: "@button_labels[0]",
    CuriousContentFeedback: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Curious Content Feedback

```stack
card CuriousContentFeedback, then: DisplayCuriousContentFeedback do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_content_feedback"]
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

card DisplayCuriousContentFeedback, then: DisplayCuriousContentFeedbackError do
  buttons(
    BaseProfile: "@button_labels[0]",
    ProfileProgress25Secondary2: "@button_labels[1]",
    ProfileProgress25Secondary2: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card DisplayCuriousContentFeedbackError, then: DisplayCuriousContentFeedbackError do
  buttons(
    BaseProfile: "@button_labels[0]",
    ProfileProgress25Secondary2: "@button_labels[1]",
    ProfileProgress25Secondary2: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card BaseProfile, then: ProfileProgress50 do
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

```

## Curious Reminder Opt In

```stack
card CuriousReminderOptIn
     when contact.opted_in == false or
            is_nil_or_empty(contact.opted_in),
     then: HealthProfessionalsSecondary2 do
  log("haven't opted in")
  run_stack("537e4867-eb26-482d-96eb-d4783828c622")
end

card CuriousReminderOptIn, then: HealthProfessionalsSecondary2 do
  log("Already opted in")
end

```

## Health Professional Secondary 2

```stack
card HealthProfessionalsSecondary2 when contact.info_for_health_professionals == true do
  log("Go to Pregnant nurse")
  run_stack("406cd221-3e6d-41cb-bc1e-cec65d412fb8")
end

card HealthProfessionalsSecondary2, then: ProfileProgress25Secondary2 do
  log("Info for Health Professionals not added")
end

```

## TODO

Temporary TODO card for routes we haven't implemented

```stack
card TODO do
  text("TODO")
end

```