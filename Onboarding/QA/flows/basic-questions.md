```stack
trigger(on: "MESSAGE RECEIVED")
when has_any_phrase(event.message.text.body, ["basic"])

```

## Basic Profile Questions

These are the basic profile questions.

## Contact fields

* `year_of_birth`, the year the user was born in
* `province`, the province the user calls home
* `area_type`, the user's area type
* `gender`, the user's gender

## Flow results

## Connections to other stacks

These questions are reused in each of the profile sections. The Gender question will be skiped in this flow if the gender is already set, which it is if the user selects `I'm Pregnant` where we then set the user to `female`.

* Profile Pregnancy Health
* Generic Profile
* HCW Profile

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "82f2c129-5b43-4c31-9431-8d68181b7345", x: 0, y: 0} -->

```stack
card FetchError, then: YearOfBirth do
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
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_unrecognised_year/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  unrecognised_year = page.body.messages[0].text

  # It seems that you can't do this calc in the when statement, so have to do it ahead of time
  min_yob = year(now()) - 150
end

```

## Age

Asks the user their year of birth

```stack
card YearOfBirth, then: ValidateYearOfBirth do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_q_age/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0].message

  year_of_birth = ask("@message")
end

card ValidateYearOfBirth
     when has_only_phrase(lower("@year_of_birth"), "skip"),
     then: Province do
  log("Skipping Age")
end

card ValidateYearOfBirth when year_of_birth > year(now()), then: YearOfBirthError do
  log("Yaer is greater than this year")
end

card ValidateYearOfBirth when isnumber(year_of_birth) != true, then: YearOfBirthError do
  log("Is not a number")
end

card ValidateYearOfBirth when len("@year_of_birth") != 4, then: YearOfBirthError do
  log("Year is less then 4 digits")
end

card ValidateYearOfBirth when year_of_birth < min_yob, then: YearOfBirthError do
  log("Year is less then minimum year")
end

card ValidateYearOfBirth when isstring(year_of_birth), then: YearOfBirthError do
  log("Is a string")
  log("Invalid input for Year of Birth")
end

card ValidateYearOfBirth when isnumber(year_of_birth), then: Province do
  update_contact(year_of_birth: "@year_of_birth")
  log("Valid YoB. Navigating to Province.")
end

card ValidateYearOfBirth, then: Province do
  update_contact(year_of_birth: "@year_of_birth")
  log("Valid YoB. Navigating to Province.")
end

card YearOfBirthError, then: ValidateYearOfBirth do
  log("YearOfBirthError")
  year_of_birth = ask("@unrecognised_year")
end

```

## Province

```stack
card Province, then: ProvinceError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_q_province/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  list_items = map(message.list_items, & &1.value)

  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@message.text")
    end
end

card ProvinceSelected when "@province" == "Skip this question", then: AreaType do
  log("Skipping province selection")
end

card ProvinceSelected when "@province" == "Why do you ask?", then: ProvinceError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_q_province_why/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  list_items = map(message.list_items, & &1.value)

  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@message.text")
    end
end

card ProvinceSelected, then: AreaType do
  log("updating province to province1 @province")
  update_contact(province: "@province")
end

card ProvinceError when lower("@province") == "skip", then: AreaType do
  log("Skipping province")
end

card ProvinceError, then: ProvinceError do
  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

```

## Area Type

```stack
card AreaType, then: AreaTypeError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_q_area_type/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)

  area_type =
    buttons(Urban: "@button_labels[0]", Rural: "@button_labels[1]") do
      text("@message.text")
    end
end

card AreaTypeError when lower("@area_type") == "skip", then: Gender do
  log("Skipping AreaType")
end

card AreaTypeError, then: AreaTypeError do
  buttons(Urban: "@button_labels[0]", Rural: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card Urban, then: Gender do
  update_contact(area_type: "big town / city")
end

card Rural, then: Gender do
  update_contact(area_type: "countryside / village")
end

```

## Gender

```stack
card Gender when len("@contact.gender") > 0 do
  log("Gender already set to @contact.gender")
end

card Gender, then: GenderError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_q_gender/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)

  gender =
    buttons(Male: "@button_labels[0]", Female: "@button_labels[1]", Other: "@button_labels[2]") do
      text("@message.text")
    end
end

card Male do
  log("Updating gender to male")
  update_contact(gender: "male")
end

card Female do
  log("Updating gender to female")
  update_contact(gender: "female")
end

card Other do
  log("Updating gender to other")
  update_contact(gender: "other")
end

card GenderError when lower("@gender") == "skip" do
  log("Skipping gender")
end

card GenderError, then: GenderError do
  buttons(Male: "@button_labels[0]", Female: "@button_labels[1]", Other: "@button_labels[2]") do
    text("@button_error_text")
  end
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_q_age` , whatsapp message asking for age
* `mnch_onboarding_q_province` , whatsapp message with up to 10 options
* `mnch_onboarding_q_province_why`, whatsapp message with up to 10 options
* `mnch_onboarding_q_area_type`, whatsapp message with two buttons
* `mnch_onboarding_q_gender`, whatsapp message with three buttons

## Error messages

* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons
* `mnch_onboarding_error_handling_list_message`, for when a user sends in a message when we're expecting them to press one of the list items
* `mnch_onboarding_unrecognised_year`, for when the user sends in an invalid year