<!-- { section: "e544152f-bf53-4d7c-ae1b-c84314772219", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "profile")

```

# Onboarding: Pt 2 - Profile Pregnancy Health

This is the main onboarding flow that users interact with during onboarding. They are directed here to complete their profile for pregnancy health if they are pregnant, have a partner who is pregnant, or are curious about the content.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `gender`, This stack sets the gender field for the user. If the user selects `im_pregnant` as their status below it defaults to `female`, otherwise it lets them set it to `male`, `female` or `other`.
* `edd`, Expected Due Date, gets set after we have the EDD month and day provided by the user.
* `other_children`, How many other children this user has.

## Flow results

* `pregnancy_status`, One of `im_pregnant`, `partner_pregnant` or `curious`
* `profile_completion`, How much of the profile they have completed e.g. 0%, 50%, 100%
* `pregnancy_sentiment`, How they are feeling about their pregnancy. This result applies only to users that have selected `im_pregnant` as their above status.

## Connections to other stacks

* The Profile Classifier stack directs users to this stack if they select the Pregnancy Health option

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                   |
| ----------------- |-----------------------------------------|
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

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
* Just curious

```stack
card Question1 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_qa_01"]
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
      Curious: "@button_labels[2]"
    ) do
      text("@message.message")
    end
end

card ImPregnant, then: PregnantEDDMonth do
  update_contact(gender: "female")
  update_contact(pregnancy_status: "@status")
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
        ["slug", "mnch_onboarding_pregnancy_qa_02"]
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
        ["slug", "mnch_onboarding_edd_unknown"]
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

Asks the user to enter the EDD day

```stack
card PregnantEDDDay, then: ValidateEDDDay do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_qa_03"]
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
        ["slug", "mnch_onboarding_confirm_edd"],
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
  edd_date_full_str = datevalue(edd_date_full, "%Y-%m-%d")
  log("EDD Saved as @edd_date_full_str")
  update_contact(edd: "@edd_date_full_str")
end

card ContinueEDDBranch when status == "im_pregnant", then: PregnantFeeling do
  # TODO: Confirm (SxD to confirm with DS and MERL) whether it's ok for us to skip the Other Children question in this flow as its part of the Personal Questions
  log("User is pregnant. Navigating to Feelings question.")
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
        ["slug", "mnch_onboarding_pregnancy_qa_04"]
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
  list_items = map(message.list_items, & &1.value)

  children =
    list("Other children",
      Children0: "@list_items[0]",
      Children1: "@list_items[1]",
      Children2: "@list_items[2]",
      Children3: "@list_items[3]",
      Children4: "@list_items[4]"
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
        ["slug", "mnch_onboarding_pregnancy_qa_05"]
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
  list_items = map(message.list_items, & &1.value)

  feeling =
    list("I'm feeling",
      SaveFeeling: "@list_items[0]",
      SaveFeeling: "@list_items[1]",
      SaveFeeling: "@list_items[2]",
      SaveFeeling: "@list_items[3]",
      SaveFeeling: "@list_items[4]"
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
        ["slug", "mnch_onboarding_pregnancy_content_00"]
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
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(Loading1: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

# Text only
card PregnancyContentBranch when @contact.data_preference == "text only" do
  buttons(Loading1: "@button_labels[0]") do
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
        ["slug", "mnch_onboarding_loading_01"]
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
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

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
        ["slug", "mnch_onboarding_loading_02"]
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
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
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
card TopicsStart do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_topics_01"]
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

card ArticleTopic do
  buttons(
    ProfileProgress50: "Complete Profile",
    ArticleFeedback: "Rate this article",
    TopicsStart: "Choose another topic"
  ) do
    text("TODO: Get the article content and display it here")
  end
end

```

## Article feedback

```stack
card ArticleFeedback do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_feedback"]
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
    ArticleFeedbackYes: "@button_labels[0]",
    ArticleFeedbackNo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ArticleFeedbackYes when contact.opted_in == "" or contact.opted_in == "no",
  then: CompleteProfile do
  # TODO: Run the Opt-In reminder journey (to be developed)
  # TODO: Save article feedback
end

card ArticleFeedbackYes, then: CompleteProfile do
  # TODO: Save article feedback
end

card ArticleFeedbackNo do
  # TODO: Save article feedback
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_content_feedback_no"]
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
    CompleteProfile: "@button_labels[0]",
    ProfileProgress50: "@button_labels[1]",
    ProfileProgress50: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

```

## Profile Progress 50%

```stack
card ProfileProgress50 do
  write_result("profile_completion", "50%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_50"]
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
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    ExploreHealthGuide: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

```

## Complete Profile

```stack
card CompleteProfile, then: ProfileProgress75 do
  # TODO: Kick off Basic Profile Questions
  log("TODO: Kick off Basic Profile Questions")
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

## Profile Progess 75%

```stack
card ProfileProgress75 do
  write_result("profile_completion", "75%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_75"]
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

  buttons(ContinueProfileCompletion: "@button_labels[0]") do
    text("@message.message")
  end
end

card ContinueProfileCompletion, then: ProfileProgress100 do
  # TODO: Kick off Personal Profile Questions
  # TODO: Kick off LOC Assessment
  log("TODO: Kick off Personal Profile Questions")
  log("TODO: Kick off LOC Assessment")
end

```

## Profile Progress 100%

```stack
card ProfileProgress100 do
  write_result("profile_completion", "100%")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100"]
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
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    TopicsForYou: "@button_labels[2]"
  ) do
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
  update_contact(pregnancy_status: "@status")
end

card PartnerPregnantGender do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_secondary_04"]
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

## Partner Loading 01 Secondary

```stack
card Loading01Secondary, then: DisplayLoading01Secondary do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_01_secondary"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayLoading01Secondary when contact.data_preference == "text only" do
  buttons(Loading02Secondary: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayLoading01Secondary do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(Loading02Secondary: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayLoading02Secondary when contact.data_preference == "text only" do
  buttons(ContentIntro: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayLoading02Secondary do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(ContentIntro: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
  menu_items = map(message.list_items, & &1.value)
end

# #TODO Content

# Text only
card DisplayContentIntro when contact.data_preference == "text only" do
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
card DisplayContentIntro do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  image("@image_data.body.meta.download_url")

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

card Other, then: ContentFeedback do
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# TODO Content

# Text only
card DisplayArticleTopic01Secondary when contact.data_preference == "text only" do
  buttons(
    ProfileProgress50: "@button_labels[0]",
    ContentFeedback: "@button_labels[1]",
    ContentIntro: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayArticleTopic01Secondary do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(
    ProfileProgress50: "@button_labels[0]",
    ContentFeedback: "@button_labels[1]",
    ContentIntro: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayContentFeedback do
  buttons(
    ReminderOptIn: "@button_labels[0]",
    ContentFeedbackNo: "@button_labels[1]"
  ) do
    text("@message.message")
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
        ["slug", "mnch_onboarding_curious_content_feedback"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayContentFeedbackNo do
  buttons(
    SecondaryOnboarding: "@button_labels[0]",
    ProfileProgress50: "@button_labels[1]",
    ProfileProgress50: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card SecondaryOnboarding do
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

```

## Partner Reminder Opt In

```stack
card ReminderOptIn
     when @contact.opted_in == false or
            @contact.opted_in == "false" or
            is_nil_or_empty(@contact.opted_in),
     then: DisplayReminderOptIn do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_opt_in"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayReminderOptIn do
  buttons(
    ReminderOptInYes: "@button_labels[0]",
    ReminderOptInNo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ReminderOptIn, then: ProfileProgress50 do
  text("@contact.opted_in")
  log("Already opted in")
end

```

## Partner Reminder Opt In Yes

```stack
card ReminderOptInYes, then: ProfileProgress50 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_opt_in_yes"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value

  text("@message.message")
end

```

## Partner Reminder Opt In No

```stack
card ReminderOptInNo, then: ProfileProgress50 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reminder_opt_in_no"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value

  text("@message.message")
end

```

## Curious 01

```stack
card Curious, then: DisplayCurious do
  write_result("pregnancy_status", status)
  write_result("profile_completion", "0%")
  update_contact(pregnancy_status: "@status")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_01"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayCurious do
  gender =
    buttons(
      MaleGender: "@button_labels[0]",
      FemaleGender: "@button_labels[1]",
      OtherGender: "@button_labels[2]"
    ) do
      text("@message.message")
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
  write_result("pregnancy_status", status)
  write_result("profile_completion", "0%")
  update_contact(pregnancy_status: "@status")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_02"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
  menu_items = map(message.list_items, & &1.value)
end

card DisplayCurious02 do
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
  write_result("pregnancy_status", status)
  write_result("profile_completion", "0%")
  update_contact(pregnancy_status: "@status")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curious_03"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
  menu_items = map(message.list_items, & &1.value)
end

card DisplayCurious03 do
  selected_topic =
    list("Select option",
      Topic_1: "@menu_items[0]",
      Topic_2: "@menu_items[1]",
      Topic_3: "@menu_items[2]",
      Topic_4: "@menu_items[3]",
      OtherTopic: "@menu_items[4]"
    ) do
      text("@message.message")
    end
end

card Topic_1, then: LoadingComponent01 do
  update_contact(other_children: "0")
end

card Topic_2, then: LoadingComponent01 do
  update_contact(other_children: "1")
end

card Topic_3, then: LoadingComponent01 do
  update_contact(other_children: "2")
end

card Topic_4, then: LoadingComponent01 do
  update_contact(other_children: "3+")
end

card OtherTopic, then: CuriousContentFeedback do
  update_contact(other_children: "3+")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayLoadingComponent01 when contact.data_preference == "text only" do
  buttons(LoadingComponent02: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayLoadingComponent01 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(LoadingComponent02: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

```

## Loading Component 02

```stack
card LoadingComponent02, then: DisplayLoadingComponent02 do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_loading_component_02"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# TODO Content

# Text only
card DisplayLoadingComponent02 when contact.data_preference == "text only" do
  buttons(CuriousContentIntro: "@button_labels[0]") do
    text("@message.message")
  end
end

# Display with image
card DisplayLoadingComponent02 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(CuriousContentIntro: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
  menu_items = map(message.list_items, &[&1.value, &1.value])
end

# #TODO Content

# Text only
card DisplayCuriousContentIntro when contact.data_preference == "text only" do
  selected_topic =
    list("Choose a topic", ArticleTopic01, menu_items) do
      text("@message.message")
    end
end

# Display with image
card DisplayCuriousContentIntro do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  text("@image_data")
  image("@image_data.body.meta.download_url")

  selected_topic =
    list("Choose a topic", ArticleTopic01, menu_items) do
      text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# TODO Content

# Text only
card DisplayArticleTopic01 when contact.data_preference == "text only" do
  buttons(
    ProfileProgress50: "@button_labels[0]",
    CuriousContent05: "@button_labels[1]",
    CuriousContentIntro: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayArticleTopic01 do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(
    ProfileProgress50: "@button_labels[0]",
    CuriousContent05: "@button_labels[1]",
    CuriousContentIntro: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayCuriousContent05 do
  buttons(
    CuriousReminderOptIn: "@button_labels[0]",
    CuriousContentFeedback: "@button_labels[1]"
  ) do
    text("@message.message")
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
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayCuriousContentFeedback do
  buttons(
    BaseProfile: "@button_labels[0]",
    ProfileProgress50: "@button_labels[1]",
    ProfileProgress50: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card BaseProfile do
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

```

## Curious Reminder Opt In

```stack
card CuriousReminderOptIn
     when @contact.opted_in == false or
            @contact.opted_in == "false" or
            is_nil_or_empty(@contact.opted_in),
     then: ProfileProgress50 do
  log("haven't opted in")
  run_stack("537e4867-eb26-482d-96eb-d4783828c622")
end

card CuriousReminderOptIn, then: ProfileProgress50 do
  log("Already opted in")
end

```

## TODO

Temporary TODO card for routes we haven't implemented

```stack
card TODO do
  text("TODO")
end

```