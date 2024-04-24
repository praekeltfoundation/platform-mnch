# Onboarding: Pt 2 - Profile Pregnancy Health

This is the main onboarding flow that users interact with during onboarding. They are directed here to complete their profile for pregnancy health if they are pregnant, have a partner who is pregnant, or are curios about the content.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `gender`, this stack sets the gender field for the user

## Flow results

## Connections to other stacks

* The Profile Classifier stack directs users to this stack if they select the Pregnancy Health option

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxx |

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: Question1 do
  # Fetch and store the error message, so that we don't need to do it for every error card

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "button-error"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

```

## Question 1

This is the first Profile question. This one applies to all flows, and from here there is branching dependent on the answer. Answers can be:

* I'm pregnant
* Partner is pregnant
* Just curios

```stack
card Question1 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pregnancy_qa_01"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  status =
    buttons(
      ImPregnant: "@button_labels[0]",
      PartnerPregnant: "@button_labels[1]",
      Curios: "@button_labels[2]"
    ) do
      text("@message.message")
    end
end

card ImPregnant, then: PregnantEDDMonth do
  update_contact(gender: "female")
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
card PregnantEDDMonth do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pregnancy_qa_02"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
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
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-month-error"]
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

card EDDMonthUnknown, "I don't know" do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd_unknown"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    PregnantEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    text("@page.body.body.text.value.message")
  end
end

card EDDMonthUnknownBranch when status == "im_pregnant" do
  # TODO: Go to Profile Progress 50
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

```stack
card PregnantEDDDay, then: ValidateEDDDay do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pregnancy_qa_03"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
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

card EDDDayNumberError, then: EDDConfirmation do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edd-day-number-error"],
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ],
      query: [["whatsapp", "true"]]
    )

  edd_day = ask("@page.body.body.text.value.message")
end

```

## EDD Confirmation

```stack
card EDDConfirmation, then: SaveEDDAndContinue do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "confirm_edd"],
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
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

```

## SaveEDDAndContinue

```stack
card SaveEDDAndContinue, then: ContinueEDDBranch do
  edd_date_full_str = datevalue(edd_date_full, "%Y/%m/%d")
  log("EDD Saved as @edd_date_full_str")
  update_contact(edd: "@edd_date_full_str")
end

card ContinueEDDBranch when status == "im_pregnant", then: OtherChildren do
  log("User is pregnant. Navigating to Other Children question.")
end

card ContinueEDDBranch when status == "partner_pregnant", then: PartnerPregnantGender do
  log("User's partner is pregnant. Navigating to gender identification question.")
end

card ContinueEDDBranch do
  log("ContinueEDDBranch: How did we get here and what do we do now? Status: @status.")
end

```

## Question 4 - Other Children

This flow is used by both the `I'm pregnant` and `Partner pregnant` options, but branch to different questions after this question is answered.

```stack
card OtherChildren do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pregnancy_qa_04"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  list_items = map(message.list_items[0], & &1.value.value)

  children =
    list("Other children",
      Children0: "list_item[0]",
      Children1: "list_item[1]",
      Children2: "list_item[2]",
      Children3: "list_item[3]",
      Children4: "list_item[4]"
    ) do
      text("@message.message")
    end
end

card Children0 when status == "im_pregnant", then: PregnantFeeling do
  update_contact(other_children: "0")
end

card Children1 when status == "im_pregnant", then: PregnantFeeling do
  update_contact(other_children: "1")
end

card Children2 when status == "im_pregnant", then: PregnantFeeling do
  update_contact(other_children: "2")
end

card Children3 when status == "im_pregnant", then: PregnantFeeling do
  update_contact(other_children: "3+")
end

card Children4 when status == "im_pregnant", then: PregnantFeeling do
  update_contact(other_children: "skip")
end

card Children0 when status == "partner_pregnant", then: PregnancyContentStart do
  update_contact(other_children: "0")
end

card Children1 when status == "partner_pregnant", then: PregnancyContentStart do
  update_contact(other_children: "1")
end

card Children2 when status == "partner_pregnant", then: PregnancyContentStart do
  update_contact(other_children: "2")
end

card Children3 when status == "partner_pregnant", then: PregnancyContentStart do
  update_contact(other_children: "3+")
end

card Children4 when status == "partner_pregnant", then: PregnancyContentStart do
  update_contact(other_children: "skip")
end

card Children0 do
  log("Children0: How did we get here and what do we do now?")
end

card Children1 do
  log("Children1: How did we get here and what do we do now?")
end

card Children2 do
  log("Children2: How did we get here and what do we do now?")
end

card Children3 do
  log("Children3: How did we get here and what do we do now?")
end

card Children4 do
  log("Children4: How did we get here and what do we do now?")
end

```

## Question 5 - How are you feeling about this pregnancy

```stack
card PregnantFeeling do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pregnancy_qa_05"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  list_items = map(message.list_items[0], & &1.value.value)

  feeling =
    list("I'm feeling",
      SaveFeeling: "list_item[0]",
      SaveFeeling: "list_item[1]",
      SaveFeeling: "list_item[2]",
      SaveFeeling: "list_item[3]",
      SaveFeeling: "list_item[4]"
    ) do
      text("@message.message")
    end
end

card SaveFeeling, then: PregnancyContentStart do
  log("Writing @feeling to pregnancy_sentiment")
  write_result("pregnancy_sentiment", feeling)
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
        ["slug", "pregnancy_content_00"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Show image
card PregnancyContentBranch do
  image(
    "https://prk-content-repo-qa-public.s3.af-south-1.amazonaws.com/images/Pregnancy_content_00.original.png"
  )

  buttons(Loading2: "@button_labels[0]") do
    text("@message.message")
  end
end

# Text only
card PregnancyContentBranch when @contact.data_preference == "text only" do
  buttons(Loading2: "@button_labels[0]") do
    text("@message.message")
  end
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
        ["slug", "loading_01"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  message = substitute(message.message, "{@username}", "@contact.profile_name")
  button_labels = map(message.buttons, & &1.value.title)
end

# Show image
card Loading1Branch do
  image(
    "https://prk-content-repo-qa-public.s3.af-south-1.amazonaws.com/images/Loading_01.original.png"
  )

  buttons(Loading2: "@button_labels[0]") do
    text("@message.message")
  end
end

# Text only
card Loading1Branch when @contact.data_preference == "text only" do
  buttons(Loading2: "@button_labels[0]") do
    text("@message.message")
  end
end

```

## Loading 2

Branch showing image depending on the data preference

```stack
card Loading2, then: Loading2Branch do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "loading_02"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Show image
card Loading2Branch do
  image(
    "https://prk-content-repo-qa-public.s3.af-south-1.amazonaws.com/images/Loading_02.original.png"
  )

  buttons(TopicsStart: "@button_labels[0]") do
    text("@message.message")
  end
end

# Text only
card Loading2Branch when @contact.data_preference == "text only" do
  buttons(TopicsStart: "@button_labels[0]") do
    text("@message.message")
  end
end

```

## Topics start

```stack
card TopicsStart do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "topics_01"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(Loading2: "@button_labels[0]") do
    text("@message.message")
  end
end

```

## My partner is pregnant

This flow first starts off with the same EDD calculator as the `I'm pregnant` option, then branches to a different series of questions.

```stack
card PartnerPregnant, then: PregnantEDDMonth do
  write_result("pregnancy_status", status)
  write_result("profile_completion", "0%")
end

card PartnerPregnantGender do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "secondary_04"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
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

card PartnerGenderMale, then: OtherChildren do
  update_contact(gender: "male")
end

card PartnerGenderFemale, then: OtherChildren do
  update_contact(gender: "female")
end

card PartnerGenderOther, then: OtherChildren do
  update_contact(gender: "other")
end

```

## Curios

```stack
card Curios do
  write_result("pregnancy_status", status)
  write_result("profile_completion", "0%")
end

```