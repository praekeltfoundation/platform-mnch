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

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "82f2c129-5b43-4c31-9431-8d68181b7345", x: 0, y: 0} -->

```stack
card FetchError, then: YearOfBirth do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
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

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_list_message"]
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

  list_error_text = page.body.body.text.value.message

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_unrecognised_year"]
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

  unrecognised_year = page.body.body.text.value.message

  # It seems that you can't do this calc in the when statement, so have to do it ahead of time
  min_yob = year(now()) - 150
end

```

## Age

Asks the user their year of birth

```stack
card YearOfBirth, then: ValidateYearOfBirth do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_age"]
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

  year_of_birth = ask("@message.message")
end

card ValidateYearOfBirth
     when has_only_phrase(lower("@year_of_birth"), "skip"),
     then: Province do
  log("Skipping Age")
end

card ValidateYearOfBirth when year_of_birth > year(now()), then: ValidateYearOfBirth do
  year_of_birth = ask("@unrecognised_year")
end

card ValidateYearOfBirth when isnumber(year_of_birth) != true, then: ValidateYearOfBirth do
  year_of_birth = ask("@unrecognised_year")
end

card ValidateYearOfBirth when len("@year_of_birth") != 4, then: ValidateYearOfBirth do
  year_of_birth = ask("@unrecognised_year")
end

card ValidateYearOfBirth when year_of_birth < min_yob, then: ValidateYearOfBirth do
  year_of_birth = ask("@unrecognised_year")
end

card ValidateYearOfBirth when isnumber(year_of_birth), then: Province do
  update_contact(year_of_birth: "@year_of_birth")
  log("Valid YoB. Navigating to Province.")
end

card ValidateYearOfBirth, then: YearOfBirthError do
  log("Invalid input for Year of Birth")
end

card YearOfBirthError, then: YearOfBirthError do
  year_of_birth = ask("@unrecognised_year")
end

```

## Province

```stack
card Province, then: ProvinceError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_province"]
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

  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card ProvinceSelected when "@province" == "Skip this question", then: AreaType do
  log("Skipping province selection")
end

card ProvinceSelected when "@province" == "Why do you ask?", then: ProvinceError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_province_why"]
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

  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@message.message")
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
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_area_type"]
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

  area_type =
    buttons(Urban: "@button_labels[0]", Rural: "@button_labels[1]") do
      text("@message.message")
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
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_gender"]
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

  gender =
    buttons(Male: "@button_labels[0]", Female: "@button_labels[1]", Other: "@button_labels[2]") do
      text("@message.message")
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
    text("@button_error_message")
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