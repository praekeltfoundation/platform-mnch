<!-- { section: "32c8bc6b-7ac9-47b6-b461-fa225e05e2ca", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "t_profile")

```

# Onboarding: Profile

This is the user profile where a user can change answers to questions and domains.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `language` , this stack allows the user to select their language.
* `name`, this stack sets the user's name
* `love_and_relationships`, a boolean that is set to true if the user selects this domain
* `pregnancy_information`, a boolean that is set to true if the user selects this domain
* `baby_and_child`, a boolean that is set to true if the user selects this domain
* `well_being`, a boolean that is set to true if the user selects this domain
* `family_planning`, a boolean that is set to true if the user selects this domain
* `info_for_health_professionals`, a boolean that is set to true if the user selects this domain
* `year_of_birth`, the year the user was born in
* `province`, the province the user calls home
* `area_type`, the user's area type
* `gender`, This stack sets the gender field for the user. If the user selects `im_pregnant` as their status below it defaults to `female`, otherwise it lets them set it to `male`, `female` or `other`.
* `edd`, Expected Due Date, gets set after we have the EDD month and day provided by the user.
* `other_children`, How many other children this user has.
* `occupational_role`, the type of nurse that they are e.g. `Enrolled Nurse`, `Enrolled Nursing Auxillary`, `Registered Nurse`, `Advanced Practice Nurse`, `Public Health Nurse`, `Midwife`, `Psyciatric Nurse`, `Other`
* `facility_type`, the type of facility they work in, e.g. `District Hospital`, `Regional Hospital`, `Academic Hospital`, `Clinic`, `Comminity Health Clinic`, `Satellite Clinic`, `Other`
* `professional_support`, whether the user receives professional support or not

## Flow results

None.

## Connections to other stacks

This stack runs other stacks if there is information that needs capturing.

* `Pregnancy Profile`
* `Generic Profile`
* `HCW Profile`

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: YourProfile do
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
        ["slug", "mnch_onboarding_name_error"]
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

  name_error_text = page.body.body.text.value.message

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_unrecognised_year"]
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

  unrecognised_year = page.body.body.text.value.message

  # It seems that you can't do this calc in the when statement, so have to do it ahead of time
  min_yob = year(now()) - 150
end

```

## Your Profile

```stack
card YourProfile, then: YourProfileError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_your_profile"]
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

  option =
    list("Choose",
      BasicInfo: "@list_items[0]",
      PersonalInfo: "@list_items[1]",
      PregnancyInfo: "@list_items[2]",
      EmploymentInfo: "@list_items[3]",
      DailyLife: "@list_items[4]",
      YourInterests: "@list_items[5]",
      MainMenu: "@list_items[6]"
    ) do
      text("@message.message")
    end
end

card YourProfileError, then: YourProfileError do
  option =
    list("Choose",
      BasicInfo: "@list_items[0]",
      PersonalInfo: "@list_items[1]",
      PregnancyInfo: "@list_items[2]",
      EmploymentInfo: "@list_items[3]",
      DailyLife: "@list_items[4]",
      YourInterests: "@list_items[5]",
      MainMenu: "@list_items[6]"
    ) do
      text("@list_error_text")
    end
end

```

## BasicInfo

```stack
card BasicInfo, then: BasicInfoError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_basic_info"]
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
  display_message = message.message

  name =
    if len("@contact.name") > 0 do
      "@contact.name"
    else
      "Please provide"
    end

  display_message = substitute(display_message, "{username}", "@name")

  year_of_birth =
    if len("@contact.year_of_birth") > 0 do
      "@contact.year_of_birth"
    else
      "Please provide"
    end

  display_message = substitute(display_message, "{year_of_birth}", "@year_of_birth")

  gender =
    if len("@contact.gender") > 0 do
      proper("@contact.gender")
    else
      "Please choose"
    end

  display_message = substitute(display_message, "{gender}", "@gender")

  province =
    if len("@contact.province") > 0 do
      proper("@contact.province")
    else
      "Please choose"
    end

  display_message = substitute(display_message, "{province}", "@province")

  area_type =
    if len("@contact.area_type") > 0 do
      proper("@contact.area_type")
    else
      "Please choose"
    end

  display_message = substitute(display_message, "{area_type}", "@area_type")
  display_message = substitute(display_message, "{language}", "@contact.language")
  list_items = map(message.list_items, & &1.value)

  option =
    list("Choose",
      Name: "@list_items[0]",
      YearOfBirth: "@list_items[1]",
      Gender: "@list_items[2]",
      Province: "@list_items[3]",
      AreaType: "@list_items[4]",
      LanguageOptions: "@list_items[5]",
      BackToProfile: "@list_items[6]"
    ) do
      text("@display_message")
    end
end

card BasicInfoError, then: BasicInfoError do
  option =
    list("Choose",
      Name: "@list_items[0]",
      YearOfBirth: "@list_items[1]",
      Gender: "@list_items[2]",
      Province: "@list_items[3]",
      AreaType: "@list_items[4]",
      LanguageOptions: "@list_items[5]",
      BackToProfile: "@list_items[6]"
    ) do
      text("@list_error_text")
    end
end

```

## Name

```stack
card Name, then: NameValidation do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_name"]
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
  name = ask("@message.message")
end

card NameValidation when has_number("@name") == true or len("@name") > 20, then: NameValidation do
  name = ask("@name_error_text")
end

card NameValidation, then: BasicInfo do
  update_contact(name: "@name")
end

```

## Age

```stack
card YearOfBirth, then: ValidateYearOfBirth do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_age"]
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

  year_of_birth = ask("@message.message")
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

card ValidateYearOfBirth when isnumber(year_of_birth), then: BasicInfo do
  update_contact(year_of_birth: "@year_of_birth")
  log("Valid YoB. Navigating to BasicInfo.")
end

card ValidateYearOfBirth, then: YearOfBirthError do
  log("Invalid input for Year of Birth")
end

card YearOfBirthError, then: YearOfBirthError do
  year_of_birth = ask("@unrecognised_year")
end

```

## Gender

```stack
card Gender, then: GenderError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_gender"]
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

  gender =
    buttons(Male: "@button_labels[0]", Female: "@button_labels[1]", Other: "@button_labels[2]") do
      text("@message.message")
    end
end

card Male, then: BasicInfo do
  log("Updating gender to male")
  update_contact(gender: "male")
end

card Female, then: BasicInfo do
  log("Updating gender to female")
  update_contact(gender: "female")
end

card Other, then: BasicInfo do
  log("Updating gender to other")
  update_contact(gender: "other")
end

card GenderError, then: GenderError do
  buttons(Male: "@button_labels[0]", Female: "@button_labels[1]", Other: "@button_labels[2]") do
    text("@button_error_message")
  end
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

  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card ProvinceSelected when "@province" == "Skip this question", then: BasicInfo do
  log("Skipping province selection")
end

card ProvinceSelected when "@province" == "Why do you ask?", then: ProvinceError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_province_why"]
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

  province =
    list("Province", ProvinceSelected, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card ProvinceSelected, then: BasicInfo do
  log("updating province to @province")
  update_contact(province: "@province")
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

  area_type =
    buttons(Urban: "@button_labels[0]", Rural: "@button_labels[1]") do
      text("@message.message")
    end
end

card AreaTypeError, then: AreaTypeError do
  buttons(Urban: "@button_labels[0]", Rural: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card Urban, then: BasicInfo do
  update_contact(area_type: "big town / city")
end

card Rural, then: BasicInfo do
  update_contact(area_type: "countryside / village")
end

```

## Language

```stack
card LanguageOptions, then: LanguageOptionsError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_languages"]
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

  language =
    list("Languages",
      Language1: "@list_items[0]",
      Language2: "@list_items[1]",
      Language3: "@list_items[2]",
      Language4: "@list_items[3]",
      Language5: "@list_items[4]",
      Language6: "@list_items[5]"
    ) do
      text("@message.message")
    end
end

card LanguageOptionsError, then: LanguageOptionsError do
  language =
    list("Languages",
      Language1: "@list_items[0]",
      Language2: "@list_items[1]",
      Language3: "@list_items[2]",
      Language4: "@list_items[3]",
      Language5: "@list_items[4]",
      Language6: "@list_items[5]"
    ) do
      text("@list_error_text")
    end
end

card Language1, then: LanguageConfirmation do
  # English
  selected_language = "English"
  update_contact(language: "eng")
end

card Language2, then: LanguageConfirmation do
  # French
  selected_language = "Français"
  update_contact(language: "fra")
end

card Language3, then: LanguageConfirmation do
  # Portuguese
  selected_language = "Português"
  update_contact(language: "por")
end

card Language4, then: LanguageConfirmation do
  # Arabic
  selected_language = "عربي"
  update_contact(language: "ara")
end

card Language5, then: LanguageConfirmation do
  # Spanish
  selected_language = "Español"
  update_contact(language: "spa")
end

card Language6, then: LanguageConfirmation do
  # Chinese
  selected_language = "中国人"
  update_contact(language: "zho")
end

card LanguageConfirmation, then: LanguageConfirmationError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_language_updated"]
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
  message_text = substitute(message.message, "{language selection}", "@selected_language")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(OkThanks: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@message_text")
  end
end

card LanguageConfirmationError, then: LanguageConfirmationError do
  buttons(OkThanks: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card OkThanks do
  then(BasicInfo)
end

```

## Back to Profile

```stack
card BackToProfile do
  then(YourProfile)
end

```

## PersonalInfo

```stack
card PersonalInfo, then: PersonalInfoError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_personal_info"]
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
  display_message = message.message

  education =
    if len("@contact.education") > 0 do
      proper("@contact.education")
    else
      "Please select"
    end

  display_message = substitute(display_message, "{education}", "@education")

  relationship_status =
    if len("@contact.relationship_status") > 0 do
      proper("@contact.relationship_status")
    else
      "Please choose"
    end

  display_message = substitute(display_message, "{relationship_status}", "@relationship_status")

  finances =
    if len("@contact.socio_economic") > 0 do
      proper("@contact.socio_economic")
    else
      "Please select"
    end

  display_message = substitute(display_message, "{finances}", "@finances")
  list_items = map(message.list_items, & &1.value)

  option =
    list("Choose",
      Education: "@list_items[0]",
      Relationship: "@list_items[1]",
      Finances: "@list_items[2]",
      BackToProfile: "@list_items[3]"
    ) do
      text("@display_message")
    end
end

card PersonalInfoError, then: PersonalInfoError do
  option =
    list("Choose",
      Education: "@list_items[0]",
      Relationship: "@list_items[1]",
      Finances: "@list_items[2]",
      BackToProfile: "@list_items[3]"
    ) do
      text("@list_error_text")
    end
end

```

## Education

```stack
card Education, then: EducationError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_education"]
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

  education =
    list("Education", EducationResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card EducationError when has_phrase(lower("@education"), "skip"), then: PersonalInfo do
  log("Skipping relationship status")
end

card EducationError, then: EducationError do
  education =
    list("Education", EducationResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card EducationResponse when has_phrase(lower("@education"), "skip"), then: PersonalInfo do
  log("Skipping education")
end

card EducationResponse, then: PersonalInfo do
  education = lower("@education")
  log("Updating education to @education")
  update_contact(education: "@education")
end

```

## Relationship Status

```stack
card Relationship, then: RelationshipError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_relationshipstatus"]
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

  relationship_status =
    buttons(RelationshipResponse, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card RelationshipError when has_phrase(lower("@relationship_status"), "skip"), then: PersonalInfo do
  log("Skipping relationship status")
end

card RelationshipError, then: RelationshipError do
  relationship_status =
    buttons(RelationshipResponse, map(button_labels, &[&1, &1])) do
      text("@button_error_text")
    end
end

card RelationshipResponse, then: PersonalInfo do
  relationship_status = lower("@relationship_status")
  log("Updating relationship_status to @relationship_status")
  update_contact(relationship_status: "@relationship_status")
end

```

## Finances

```stack
card Finances, then: FinancesError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_socioeconomic"]
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

  socio_economic =
    buttons(FinancesResponse, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card FinancesError when has_phrase(lower("@socio_economic"), "skip"), then: PersonalInfo do
  log("Skipping socio economic")
end

card FinancesError, then: FinancesError do
  socio_economic =
    buttons(FinancesResponse, map(button_labels, &[&1, &1])) do
      text("@button_error_text")
    end
end

card FinancesResponse, then: PersonalInfo do
  socio_economic = lower("@socio_economic")
  log("Updating socio economic to @socio_economic")
  update_contact(socio_economic: "@socio_economic")
end

```

## PregnancyInfo

```stack
card PregnancyInfo when contact.pregnancy_status == "curious", then: PregnancyInfoError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_info_curious"]
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
  display_message = message.message

  role = "Just curious"
  display_message = substitute(display_message, "{role}", "@role")

  # We don't store the trimester so calculate it
  edd = contact.edd
  edd_date_month = month(edd)

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

  pregnancy_in_weeks = (month_diff + year_diff + day_diff) / 7
  pregnancy_in_weeks = split("@pregnancy_in_weeks", ".")[0]

  trimester = 0

  trimester =
    if pregnancy_in_weeks <= 12 do
      1
    else
      trimester
    end

  trimester =
    if pregnancy_in_weeks > 12 and pregnancy_in_weeks < 27 do
      2
    else
      trimester
    end

  trimester =
    if pregnancy_in_weeks >= 27 do
      3
    else
      trimester
    end

  display_message = substitute(display_message, "{trimester}", "@trimester")

  number_of_children =
    if len("@contact.other_children") > 0 do
      "@contact.other_children"
    else
      "Please share"
    end

  display_message = substitute(display_message, "{number_of_children}", "@number_of_children")

  list_items = map(message.list_items, & &1.value)

  option =
    list("Choose",
      MyRole: "@list_items[0]",
      Trimester: "@list_items[1]",
      Children: "@list_items[2]",
      BackToProfile: "@list_items[3]"
    ) do
      text("@display_message")
    end
end

card PregnancyInfo, then: PregnancyInfoError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnancy_info_moms_partners"]
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
  display_message = message.message

  role =
    if "@contact.pregnancy_status" == "im_pregnant" do
      "Pregnant"
    else
      "Partner is pregnant"
    end

  display_message = substitute(display_message, "{role}", "@role")

  edd =
    if len("@contact.edd") > 0 do
      "@contact.edd"
    else
      "Please select"
    end

  display_message = substitute(display_message, "{edd}", "@edd")

  number_of_children =
    if len("@contact.other_children") > 0 do
      "@contact.other_children"
    else
      "Please share"
    end

  display_message = substitute(display_message, "{number_of_children}", "@number_of_children")

  pregnancy_sentiment =
    if len("@contact.pregnancy_sentiment") > 0 do
      proper("@contact.pregnancy_sentiment")
    else
      "Please share"
    end

  display_message = substitute(display_message, "{feeling}", "@pregnancy_sentiment")

  list_items = map(message.list_items, & &1.value)

  option =
    list("Choose",
      MyRole: "@list_items[0]",
      PregnantEDDMonth: "@list_items[1]",
      Children: "@list_items[2]",
      Feeling: "@list_items[3]",
      BackToProfile: "@list_items[4]"
    ) do
      text("@display_message")
    end
end

card PregnancyInfoError, then: PregnancyInfoError do
  option =
    list("Choose",
      MyRole: "@list_items[0]",
      PregnantEDDMonth: "@list_items[1]",
      Children: "@list_items[2]",
      Feeling: "@list_items[3]",
      BackToProfile: "@list_items[4]"
    ) do
      text("@list_error_text")
    end
end

card PregnancyInfoError when contact.pregnancy_status == "curious", then: PregnancyInfoError do
  option =
    list("Choose",
      MyRole: "@list_items[0]",
      Trimester: "@list_items[1]",
      Children: "@list_items[2]",
      BackToProfile: "@list_items[3]"
    ) do
      text("@list_error_text")
    end
end

```

## My Role

```stack
card MyRole, then: MyRoleError do
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

card MyRoleError, then: MyRoleError do
  status =
    buttons(
      ImPregnant: "@button_labels[0]",
      PartnerPregnant: "@button_labels[1]",
      Curious: "@button_labels[2]"
    ) do
      text("@button_error_text")
    end
end

card ImPregnant, then: PregnancyInfo do
  update_contact(gender: "female")
  log("Updating pregnancy_status to @status")
  update_contact(pregnancy_status: "@status")
end

card PartnerPregnant, then: PregnancyInfo do
  log("Updating pregnancy_status to @status")
  update_contact(pregnancy_status: "@status")
end

card Curious, then: PregnancyInfo do
  log("Updating pregnancy_status to @status")
  update_contact(pregnancy_status: "@status")
end

```

## EDD

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

card EDDMonthUnknown, "I don't know" do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_edd_unknown"]
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
    PregnantEDDMonth: "@button_labels[0]",
    EDDMonthUnknownBranch: "@button_labels[1]"
  ) do
    text("@page.body.body.text.value.message")
  end
end

card EDDMonthUnknownBranch, then: PregnancyInfo do
  log("EDD month unknown, going back to PregnancyInfo")
end

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

card EDDConfirmation, then: SaveEDDAndContinue do
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
    SaveEDDAndContinue: "@button_labels[0]",
    PregnantEDDMonth: "@button_labels[1]"
  ) do
    text("@question")
  end
end

card SaveEDDAndContinue, then: PregnancyInfo do
  edd_date_full_str = datevalue(edd_date_full, "%Y-%m-%d")
  log("EDD Saved as @edd_date_full_str")
  update_contact(edd: "@edd_date_full_str")
  write_result("edd", edd_date_full_str)
end

```

## Children

```stack
card Children, then: ChildrenError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_children"]
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

  children =
    list("Children", ChildrenResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card ChildrenError, then: ChildrenError do
  children =
    list("Children", ChildrenResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card ChildrenResponse when has_phrase(lower("@children"), "why") do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_children_why"]
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

  children =
    list("Children", ChildrenResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card ChildrenResponse, then: PregnancyInfo do
  children = lower("@children")
  log("Updating other_children to @children")
  update_contact(other_children: "@children")
end

```

## Feeling

```stack
card Feeling, then: FeelingError do
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

card FeelingError, then: FeelingError do
  feeling =
    list("I'm feeling", SaveFeeling, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card SaveFeeling, then: PregnancyInfo do
  log("Writing @feeling to pregnancy_sentiment")
  update_contact(pregnancy_sentiment: "@feeling")
end

```

## Trimester

```stack
card Trimester, then: TrimesterError do
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
  list_items = map(message.list_items, & &1.value)

  selected_trimester =
    list("Select option", TrimesterResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card TrimesterError, then: TrimesterError do
  selected_trimester =
    list("Select option", TrimesterResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card TrimesterResponse when has_phrase(lower("@selected_trimester"), "skip"), then: PregnancyInfo do
  log("Skipping trimester")
end

card TrimesterResponse, then: PregnancyInfo do
  selected_trimester = lower("@selected_trimester")
  log("Updating pregnancy_stage_interest to @selected_trimester")
  update_contact(pregnancy_stage_interest: "@selected_trimester")
end

```

## EmploymentInfo

```stack
card EmploymentInfo, then: EmploymentInfoError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_employment_info"]
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
  display_message = message.message

  occupational_role =
    if len("@contact.occupational_role") > 0 do
      proper("@contact.occupational_role")
    else
      "Please share"
    end

  substitute(display_message, "{occupational_role}", "@occupational_role")

  facility_type =
    if len("@contact.facility_type") > 0 do
      proper("@contact.facility_type")
    else
      "Please share"
    end

  substitute(display_message, "{facility_type}", "@facility_type")

  professional_support =
    if len("@contact.professional_support") > 0 do
      proper("@contact.professional_support")
    else
      "Please share"
    end

  substitute(display_message, "{professional_support}", "@professional_support")

  list_items = map(message.list_items, & &1.value)

  option =
    list("Choose",
      OccupationalRole: "@list_items[0]",
      FacilityType: "@list_items[1]",
      ProfessionalSupport: "@list_items[2]",
      BackToProfile: "@list_items[3]"
    ) do
      text("@display_message")
    end
end

card EmploymentInfoError, then: EmploymentInfoError do
  option =
    list("Choose",
      OccupationalRole: "@list_items[0]",
      FacilityType: "@list_items[1]",
      ProfessionalSupport: "@list_items[2]",
      BackToProfile: "@list_items[3]"
    ) do
      text("@list_error_text")
    end
end

```

## Role

```stack
card OccupationalRole, then: OccupationalRoleError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_occupational_role"]
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

  role =
    list("Role", OccupationalRoleResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card OccupationalRoleError, then: OccupationalRoleError do
  role =
    list("Role", OccupationalRoleResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card OccupationalRoleResponse when has_phrase(lower("@role"), "skip"), then: EmploymentInfo do
  log("Skipping occupational_role")
end

card OccupationalRoleResponse, then: EmploymentInfo do
  role = lower("@role")
  log("Updating occupational_role to @role")
  update_contact(occupational_role: "@role")
end

```

## Facility Type

```stack
card FacilityType, then: FacilityTypeError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_facility_type"]
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

  facility_type =
    list("Facility", FacilityTypeResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card FacilityTypeError, then: FacilityTypeError do
  facility_type =
    list("Facility", FacilityTypeResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card FacilityTypeResponse when has_phrase(lower("@facility_type"), "skip"),
  then: EmploymentInfo do
  log("Skipping facility_type")
end

card FacilityTypeResponse, then: EmploymentInfo do
  facility_type = lower("@facility_type")
  log("Updating facility_type to @facility_type")
  update_contact(facility_type: "@rofacility_typele")
end

```

## Professional Support

```stack
card ProfessionalSupport, then: ProfessionalSupportError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_professional_support"]
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

  professional_support =
    buttons(ProfessionalSupportResponse, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card ProfessionalSupportError, then: ProfessionalSupportError do
  professional_support =
    buttons(ProfessionalSupportResponse, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card ProfessionalSupportResponse, then: EmploymentInfo do
  professional_support = lower("@professional_support")
  log("Updating professional_support to @professional_support")
  update_contact(professional_support: "@professional_support")
end

```

## DailyLife

```stack
card DailyLife, then: DailyLifeError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_daily_life"]
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

  daily_life =
    list("Select", DailyLifeResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card DailyLifeError, then: DailyLifeError do
  daily_life =
    list("Select", DailyLifeResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card DailyLifeResponse do
  text("TODO: kick off @daily_life form")
end

```

## YourInterests

```stack
card YourInterests, then: YourInterestsError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_your_interests"]
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
  selected_topics = []
  unselected_topics = []

  pregnancy_health = "Pregnancy health"
  love_life = "Love & life"
  baby_child = "Baby & child"
  general_health = "General health"
  safe_sex = "Safe sex"
  info_for_nurses = "Info for nurses"

  selected_topics =
    if contact.pregnancy_information == true do
      append(selected_topics, "@pregnancy_health")
    else
      selected_topics
    end

  selected_topics =
    if contact.love_and_relationships == true do
      append(selected_topics, "@love_life")
    else
      selected_topics
    end

  selected_topics =
    if contact.baby_and_child == true do
      append(selected_topics, "@baby_child")
    else
      selected_topics
    end

  selected_topics =
    if contact.well_being == true do
      append(selected_topics, "@general_health")
    else
      selected_topics
    end

  selected_topics =
    if contact.family_planning == true do
      append(selected_topics, "@safe_sex")
    else
      selected_topics
    end

  selected_topics =
    if contact.info_for_health_professionals == true do
      append(selected_topics, "@info_for_nurses")
    else
      selected_topics
    end

  # unselected topics

  guard = contact.pregnancy_information == nil or contact.pregnancy_information == false

  unselected_topics =
    if guard == true do
      append(unselected_topics, "@pregnancy_health")
    else
      unselected_topics
    end

  guard = contact.love_and_relationships == nil or contact.love_and_relationships == false

  unselected_topics =
    if guard == true do
      append(unselected_topics, "@love_life")
    else
      unselected_topics
    end

  guard = contact.baby_and_child == nil or contact.baby_and_child == false

  unselected_topics =
    if guard == true do
      append(unselected_topics, "@baby_child")
    else
      unselected_topics
    end

  guard = contact.well_being == nil or contact.well_being == false

  unselected_topics =
    if guard == true do
      append(unselected_topics, "@general_health")
    else
      unselected_topics
    end

  guard = contact.family_planning == nil or contact.family_planning == false

  unselected_topics =
    if guard == true do
      append(unselected_topics, "@safe_sex")
    else
      unselected_topics
    end

  guard =
    contact.info_for_health_professionals == nil or contact.info_for_health_professionals == false

  unselected_topics =
    if guard == true do
      append(unselected_topics, "@info_for_nurses")
    else
      unselected_topics
    end

  message_topics = reduce(selected_topics, "", &concatenate(&2, &1, "@unichar(10)"))
  message_text = substitute("@message.message", "{topics}", "@message_topics")

  list_items = append(unselected_topics, list_items)

  interest =
    list("Add or remove", YourInterestsResponse, map(list_items, &[&1, &1])) do
      text("@message_text")
    end
end

card YourInterestsError, then: YourInterestsError do
  interest =
    list("Add or remove", YourInterestsResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card YourInterestsResponse when has_phrase(lower("@interest"), "back to my profile") do
  then(BackToProfile)
end

card YourInterestsResponse when has_phrase(lower("@interest"), "remove a topic"),
  then: YourInterestRemoveResponseError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_remove_topic"]
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
  list_items = append(selected_topics, list_items)

  interest =
    list("Select", YourInterestRemoveResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card YourInterestRemoveResponseError, then: YourInterestRemoveResponseError do
  interest =
    list("Select", YourInterestRemoveResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card YourInterestRemoveResponse when "@interest" == "@pregnancy_health", then: YourInterests do
  update_contact(pregnancy_information: "false")
end

card YourInterestRemoveResponse when "@interest" == "@love_life", then: YourInterests do
  update_contact(love_and_relationships: "false")
end

card YourInterestRemoveResponse when "@interest" == "@baby_child", then: YourInterests do
  update_contact(baby_and_child: "false")
end

card YourInterestRemoveResponse when "@interest" == "@general_health", then: YourInterests do
  update_contact(well_being: "false")
end

card YourInterestRemoveResponse when "@interest" == "@safe_sex", then: YourInterests do
  update_contact(family_planning: "false")
end

card YourInterestRemoveResponse when "@interest" == "@info_for_nurses", then: YourInterests do
  update_contact(info_for_health_professionals: "false")
end

card YourInterestRemoveResponse, then: YourInterests do
  log("Unknown interest @interest")
end

# When edd, sentiment and all the LOC questions have been answered 
# we assume that all the pregnancy info has been filled
card YourInterestsResponse
     when "@interest" == "@pregnancy_health" and
            has_text("@contact.edd") and
            has_text("@contact.pregnancy_sentiment") and
            has_text("@contact.loc_01") and
            has_text("@contact.loc_02") and
            has_text("@contact.loc_03") and
            has_text("@contact.loc_04") and
            has_text("@contact.loc_05"),
     then: AddProfileComplete do
  update_contact(pregnancy_information: "true")
end

card YourInterestsResponse
     when "@interest" == "@pregnancy_health",
     then: AddProfileIncomplete do
  update_contact(pregnancy_information: "true")
end

card YourInterestsResponse
     when "@interest" == "@love_life" and
            has_text("@contact.loc_01") and
            has_text("@contact.loc_02") and
            has_text("@contact.loc_03") and
            has_text("@contact.loc_04") and
            has_text("@contact.loc_05"),
     then: AddProfileComplete do
  update_contact(love_and_relationships: "true")
end

card YourInterestsResponse when "@interest" == "@love_life",
  then: AddProfileIncomplete do
  update_contact(love_and_relationships: "true")
end

card YourInterestsResponse
     when "@interest" == "@baby_child" and
            has_text("@contact.loc_01") and
            has_text("@contact.loc_02") and
            has_text("@contact.loc_03") and
            has_text("@contact.loc_04") and
            has_text("@contact.loc_05"),
     then: AddProfileComplete do
  update_contact(baby_and_child: "true")
end

card YourInterestsResponse when "@interest" == "@baby_child",
  then: AddProfileIncomplete do
  update_contact(baby_and_child: "true")
end

card YourInterestsResponse
     when "@interest" == "@general_health" and
            has_text("@contact.loc_01") and
            has_text("@contact.loc_02") and
            has_text("@contact.loc_03") and
            has_text("@contact.loc_04") and
            has_text("@contact.loc_05"),
     then: AddProfileComplete do
  update_contact(well_being: "true")
end

card YourInterestsResponse when "@interest" == "@general_health",
  then: AddProfileIncomplete do
  update_contact(well_being: "true")
end

card YourInterestsResponse
     when "@interest" == "@safe_sex" and
            has_text("@contact.loc_01") and
            has_text("@contact.loc_02") and
            has_text("@contact.loc_03") and
            has_text("@contact.loc_04") and
            has_text("@contact.loc_05"),
     then: AddProfileComplete do
  update_contact(family_planning: "true")
end

card YourInterestsResponse when "@interest" == "@safe_sex",
  then: AddProfileIncomplete do
  update_contact(family_planning: "true")
end

card YourInterestsResponse
     when "@interest" == "@info_for_nurses" and
            has_text("@contact.occupational_role") and
            has_text("@contact.facility_type") and
            has_text("@contact.professional_support") and
            has_text("@contact.loc_01") and
            has_text("@contact.loc_02") and
            has_text("@contact.loc_03") and
            has_text("@contact.loc_04") and
            has_text("@contact.loc_05"),
     then: AddProfileComplete do
  update_contact(info_for_health_professionals: "true")
end

card YourInterestsResponse when "@interest" == "@info_for_nurses",
  then: AddProfileIncomplete do
  update_contact(info_for_health_professionals: "true")
end

card YourInterestsResponse do
  log("YourInterestsResponse: Unknown interest @interest")
end

card AddProfileComplete, then: AddProfileCompleteError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_add_profile_complete"]
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
  display_message = message.message
  display_message = substitute(display_message, "{domain}", "@interest")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    BrowseTopic: "@button_labels[0]",
    BackToProfile: "@button_labels[1]"
  ) do
    text("@display_message")
  end
end

card AddProfileCompleteError, then: AddProfileCompleteError do
  buttons(
    BrowseTopic: "@button_labels[0]",
    BackToProfile: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card BrowseTopic when "@interest" == "@pregnancy_health" do
  text("TODO: BrowseTopic @interest")
end

card BrowseTopic when "@interest" == "@love_life" do
  text("TODO: BrowseTopic @interest")
end

card BrowseTopic when "@interest" == "@baby_child" do
  text("TODO: BrowseTopic @interest")
end

card BrowseTopic when "@interest" == "@general_health" do
  text("TODO: BrowseTopic @interest")
end

card BrowseTopic when "@interest" == "@safe_sex" do
  text("TODO: BrowseTopic @interest")
end

card BrowseTopic when "@interest" == "@info_for_nurses" do
  text("TODO: BrowseTopic @interest")
end

card BrowseTopic do
  log("BrowseTopic: Unknown interest @interest")
end

card AddProfileIncomplete, then: AddProfileIncompleteError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_add_profile_incomplete"]
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
  display_message = message.message
  display_message = substitute(display_message, "{domain}", "@interest")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    CompleteProfile: "@button_labels[0]",
    BrowseTopic: "@button_labels[1]",
    BackToProfile: "@button_labels[2]"
  ) do
    text("@display_message")
  end
end

card AddProfileIncompleteError, then: AddProfileIncompleteError do
  buttons(
    CompleteProfile: "@button_labels[0]",
    BrowseTopic: "@button_labels[1]",
    BackToProfile: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card CompleteProfile when "@interest" == "@pregnancy_health" do
  # Run Pregnancy Profile 
  run_stack("d5f5cfef-1961-4459-a9fe-205a1cabfdfb")
end

card CompleteProfile when "@interest" == "@love_life" do
  # Run Generic Profile
  run_stack("51701b44-bcca-486e-9c99-bf3545a8ba2d")
end

card CompleteProfile when "@interest" == "@baby_child" do
  # Run Generic Profile
  run_stack("51701b44-bcca-486e-9c99-bf3545a8ba2d")
end

card CompleteProfile when "@interest" == "@general_health" do
  # Run Generic Profile
  run_stack("51701b44-bcca-486e-9c99-bf3545a8ba2d")
end

card CompleteProfile when "@interest" == "@safe_sex" do
  # Run Generic Profile
  run_stack("51701b44-bcca-486e-9c99-bf3545a8ba2d")
end

card CompleteProfile when "@interest" == "@info_for_nurses" do
  # Run HCW Profile
  run_stack("38cca9df-21a1-4edc-9c13-5724904ca3c3")
end

card CompleteProfile do
  log("CompleteProfile: Unknown interest @interest")
end

```

## MainMenu

```stack
card MainMenu do
  text("TODO: Go to personalised or non-personalised menu")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_q_age` , whatsapp message asking for age
* `mnch_onboarding_q_province` , whatsapp message with up to 10 options
* `mnch_onboarding_q_province_why`, whatsapp message with up to 10 options
* `mnch_onboarding_q_area_type`, whatsapp message with two buttons
* `mnch_onboarding_q_gender`, whatsapp message with three buttons
* `mnch_onboarding_q_relationshipstatus`, whatsapp message with 3 buttons
* `mnch_onboarding_q_education` , whatsapp message a list of options
* `mnch_onboarding_q_socioeconomic` , whatsapp message with 3 buttons.
* `mnch_onboarding_children`, whatsapp message with a list of options
* `mnch_onboarding_children_why`, whatsapp message with 3 buttons, and a document
* `mnch_onboarding_pregnancy_qa_01`, whatsapp message with 3 buttons
* `mnch_onboarding_pregnancy_qa_02`, whatsapp message with 10 options
* `mnch_onboarding_pregnancy_qa_03`, whatsapp message
* `mnch_onboarding_pregnancy_qa_05`, whatsapp message with 5 list options
* `mnch_onboarding_edd_unknown`, whatsapp message with 2 buttons
* `mnch_onboarding_confirm_edd`, whatsapp message with 2 buttons,
* `mnch_onboarding_curious_03`, whatsapp message with 4 list options
* `mnch_onboarding_nursecheck` , whatsapp message asking whether the user is a nurse or not, with an attached image
* `mnch_onboarding_occupational_role` , whatsapp message asking what type of nurse they are
* `mnch_onboarding_facility_type` , whatsapp message asking what type of facility they work in
* `mnch_onboarding_professional_support` , whatsapp message asking whether they receive professional support or not

## Error messages

* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons
* `mnch_onboarding_error_handling_list_message`, for when a user sends in a message when we're expecting them to press one of the list items
* `mnch_onboarding_unrecognised_year`, for when the user sends in an invalid year