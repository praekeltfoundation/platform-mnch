# Onboarding:Pt 3 - Mother Detail

This is the third flow that users interact with during Onboarding

This flow is about capturing the details about the mother.

The content for this flow, except for some navigation items at this stage,  is stored in ContentRepo.  The flow uses the ContentRepo API to fetch content, referencing it by slug.

A full list of required content can be found in the Content Depencies section at the bottom of this stack.

## This stack updates the following contact fields

* `onboarding_part_3`,  gets set to `incomplete` at the start of this stack, and `complete` at the end
* `user_sentiment`, set as per user selection from the list `Excited`, `Happy`, `Worried`, `Scared`, `Skip`
* `location_type`, set as per user selection from the list `Traditional/chiefdom`, `Urban/town`, `Farm/rural`, `I don't understand`, `Skip`
* `relationship_status`, set as per user selection from the list `Single`, `In A Relationship`, `Married`, `It's complicated`, `Skip`
* `year_of_birth`, Set to the year of birth provided by the user
* `education`, set as per user selection from the list `Primary school`, `High school`, `Diploma`, `Degree`, `Masters degree`, `Doctoral degree`, `None`, `Skip`
* `socioeconomic_status`,set as per user selection from the list `R0-R500`, `R501-R2500`, `R2501-R10000`, `R10001-R20000`, `R20001-R35000`, `More than R35000e`, `None`, `Skip`
* `social_support`, set based on user button press of `Yes` or `No`

## Connections to other stacks

* If the user chooses to add more children, we send them to this stack -  [Onboarding: Babies Info](https://whatsapp.who.turn.io/app/stacks/f4ceb1a6-44b5-49a4-8c0a-c395d0787059/404dd56e-59ef-4002-b9b9-9956743b22a9)

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

A generic button error message

<!-- { section: "32d45c54-1f17-4912-a555-2fa9ebe5d4d1", x: 0, y: 0} -->

```stack
# For testing, remove for production
interaction_timeout(60)

card FetchError, then: UserSentiment do
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
  update_contact(onboarding_part_3: "incomplete")
end

```

# User Sentiment

Message asking the user to select a Feeling from a list of options

```stack
card UserSentiment, then: UserSentimentError do
  update_contact(onboarding_part_3: "incomplete")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "user-sentiment"]
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

  user_sentiment =
    list("Feeling",
      Excited: "Excited",
      Happy: "Happy",
      Worried: "Worried",
      Scared: "Scared",
      SkipUserSentiment: "Skip"
    ) do
      text("@message.message")
    end
end

card UserSentimentError, then: UserSentimentError do
  user_sentiment =
    list("Feeling",
      Excited: "Excited",
      Happy: "Happy",
      Worried: "Worried",
      Scared: "Scared",
      SkipUserSentiment: "Skip 3"
    ) do
      text("@button_error_text")
    end
end

card Excited, then: Location do
  update_contact(user_sentiment: "Excited")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "acknowledgement-excited"]
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
  text("@message.message")
end

card Happy, then: Location do
  update_contact(user_sentiment: "Happy")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "acknowledgement-happy"]
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
  text("@message.message")
end

card Worried, then: Location do
  update_contact(user_sentiment: "Worried")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "acknowledgement-worried"]
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
  text("@message.message")
end

card Scared, then: Location do
  update_contact(user_sentiment: "Scared")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "acknowledgement-scared"]
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
  text("@message.message")
end

card SkipUserSentiment, then: Location do
  update_contact(user_sentiment: "Skip")
end

```

# Location

Message that asks the user to enter their Location Type from a list of options

```stack
card Location, then: LocationError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "location"]
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

  location =
    list("Location",
      TraditionalChiefdom: "Traditional/chiefdom",
      UrbanTown: "Urban/town",
      FarmRural: "Farm/rural",
      IDontUnderstand: "I don't understand",
      SkipLocation: "Skip"
    ) do
      text("@message.message")
    end
end

card LocationError, then: LocationError do
  location =
    list("Location",
      TraditionalChiefdom: "Tradional/chiefdom",
      UrbanTown: "Urban/town",
      FarmRural: "Farm/rural",
      IDontUnderstand: "I don't understand",
      SkipLocation: "Skip"
    ) do
      text("@button_error_text")
    end
end

card TraditionalChiefdom, then: RelationshipStatus do
  update_contact(location_type: "Traditional/chiefdom")
end

card UrbanTown, then: RelationshipStatus do
  update_contact(location_type: "Urban/town")
end

card FarmRural, then: RelationshipStatus do
  update_contact(location_type: "Farm/rural")
end

card IDontUnderstand, then: RelationshipStatus do
  update_contact(location_type: "I don't understand")
end

card SkipLocation, then: RelationshipStatus do
  update_contact(location_type: "Skip")
end

card ValidateLocation, then: LocationError do
  log("Invalid input for Location")
end

card LocationError do
  text("Invalid input for Location")
end

```

# Relationship status

Message that asks the user to enter their Relationship Status from a list of options

```stack
card RelationshipStatus, then: RelationshipStatusError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "relationship-status"]
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

  relationship_status =
    list("Relationship Status",
      Single: "Single",
      InARelationship: "In A Relationship",
      Married: "Married",
      ItsComplicated: "It's complicated",
      SkipRelationshipStatus: "Skip"
    ) do
      text("@message.message")
    end
end

card RelationshipStatusError, then: RelationshipStatusError do
  relationship_status =
    list("Relationship Status",
      Single: "Single",
      InARelationship: "In A Relationship",
      Married: "Married",
      ItsComplicated: "It's complicated",
      SkipRelationshipStatus: "Skip"
    ) do
      text("@button_error_text")
    end
end

card Single, then: YearOfBirth do
  update_contact(relationship_status: "Single")
end

card InARelationship, then: YearOfBirth do
  update_contact(relationship_status: "In a relationship")
end

card Married, then: YearOfBirth do
  update_contact(relationship_status: "Married")
end

card ItsComplicated, then: YearOfBirth do
  update_contact(relationship_status: "It's complicated")
end

card SkipRelationshipStatus, then: YearOfBirth do
  update_contact(relationship_status: "Skip")
end

```

# Year of birth

Message that asks the user to enter their Year of Birth as a 4 digit number

### TODO

There are some additional validation error messages here, we must either map these to existing ones, or get content for new messages

```stack
card YearOfBirth, then: ValidateYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "year-of-birth"]
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

  year_of_birth = ask("@message.message")
end

card ValidateYearOfBirth when year_of_birth > year(now()), then: ValidateYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "invalid-year"]
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
  year_of_birth = ask("@message.message")
end

card ValidateYearOfBirth when isnumber(year_of_birth) != true, then: ValidateYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "invalid-year"]
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
  year_of_birth = ask("@message.message")
end

card ValidateYearOfBirth when len("@year_of_birth") != 4, then: ValidateYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "invalid-year"]
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
  year_of_birth = ask("@message.message")
end

card ValidateYearOfBirth when isnumber(year_of_birth), then: YearOfBirthConfirmation do
  log("TODO: Validation valid! Moving on Not sure how to get rid of this text")
end

card ValidateYearOfBirth, then: YearOfBirthError do
  log("Invalid input for Year of Birth")
end

card YearOfBirthError, then: YearOfBirthError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "invalid-year"]
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
  year_of_birth = ask("@message.message")
end

```

# Confirm Year of Birth

Message that asks the user to enter their Year of Birth by clicking a Yes or No button

```stack
card YearOfBirthConfirmation, then: YearOfBirthConfirmationError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "confirm-year-of-birth"]
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
  message_text = substitute(message.message, "{{year-of-birth}}", "@year_of_birth")
  button_labels = map(message.buttons, & &1.value.title)
  # text("Button Labels = @button_labels[0], @button_labels[1]")

  buttons(YearOfBirthYes: "@button_labels[0]", YearOfBirthNo: "@button_labels[1]") do
    text("@message_text")
  end
end

card YearOfBirthConfirmationError, then: YearOfBirthConfirmationError do
  buttons(YearOfBirthYes: "@button_labels[0]", YearOfBirthNo: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card YearOfBirthYes, then: Education do
  update_contact(year_of_birth: "@year_of_birth")
end

card YearOfBirthNo, then: YearOfBirth do
  log("TODO: go back ")
end

```

# Education

Message that asks the user to enter their level of Education from a list of options

```stack
card Education, then: EducationError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "education"]
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

  education =
    list("Education",
      PrimarySchool: "Primary school",
      HighSchool: "High school",
      Diploma: "Diploma",
      Degree: "Degree",
      MastersDegree: "Masters degree",
      DoctoralDegree: "Doctoral degree",
      EducationNone: "None",
      SkipEducation: "Skip"
    ) do
      text("@message.message")
    end
end

card EducationError, then: EducationError do
  education =
    list("Education",
      PrimarySchool: "Primary school",
      HighSchool: "High school",
      Diploma: "Diploma",
      Degree: "Degree",
      MastersDegree: "Masters degree",
      DoctoralDegree: "Doctoral degree",
      EducationNone: "None",
      SkipEducation: "Skip"
    ) do
      text("@button_error_text")
    end
end

card PrimarySchool, then: SocioeconomicStatus do
  update_contact(education: "Primary school")
end

card HighSchool, then: SocioeconomicStatus do
  update_contact(education: "High school")
end

card Diploma, then: SocioeconomicStatus do
  update_contact(education: "Diploma")
end

card Degree, then: SocioeconomicStatus do
  update_contact(education: "Primary school")
end

card MastersDegree, then: SocioeconomicStatus do
  update_contact(education: "Masters degree")
end

card DoctoralDegree, then: SocioeconomicStatus do
  update_contact(education: "Doctoral degree")
end

card EducationNone, then: SocioeconomicStatus do
  update_contact(education: "None")
end

card SkipEducation, then: SocioeconomicStatus do
  update_contact(education: "Skip")
end

```

# Socioeconomic status

Message that asks the user to enter their Socioeconomic Status from a list of options

```stack
card SocioeconomicStatus, then: SocioeconomicStatusError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "socioeconomic-status"]
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

  socioeconomic_status =
    list("Income",
      LessThan500: "R0-R500",
      LessThan2500: "R501-R2500",
      LessThan10000: "R2501-R10000",
      LessThan20000: "R10001-R20000",
      LessThan35000: "R20001-R35000",
      MoreThan35000: "More than R35000",
      SocioeconomicStatusNone: "None",
      SkipSocioeconomicStatus: "Skip"
    ) do
      text("@message.message")
    end
end

card SocioeconomicStatusError, then: SocioeconomicStatusError do
  socioeconomic_status =
    list("Income",
      LessThan500: "R0-R500",
      LessThan2500: "R501-R2500",
      LessThan10000: "R2501-R10000",
      LessThan20000: "R10001-R20000",
      LessThan35000: "R20001-R35000",
      MoreThan35000: "More than R35000",
      SocioeconomicStatusNone: "None",
      SkipSocioeconomicStatus: "Skip"
    ) do
      text("What @button_error_text")
    end
end

card LessThan500, then: SocialSupport do
  update_contact(socioeconomic_status: "R0-R500")
end

card LessThan2500, then: SocialSupport do
  update_contact(socioeconomic_status: "R501-R2500")
end

card LessThan10000, then: SocialSupport do
  update_contact(socioeconomic_status: "R2501-R10000")
end

card LessThan20000, then: SocialSupport do
  update_contact(socioeconomic_status: "R10001-R20000")
end

card LessThan35000, then: SocialSupport do
  update_contact(socioeconomic_status: "R20001-R35000")
end

card MoreThan35000, then: SocialSupport do
  update_contact(socioeconomic_status: "More than R35000")
end

card SocioeconomicStatusNone, then: SocialSupport do
  text("here @socioeconomic_status")
end

card SkipSocioeconomicStatus, then: SocialSupport do
  update_contact(socioeconomic_status: "Skip")
end

```

# Social support

Message that asks the user to enter their Social Support

```stack
card SocialSupport, then: SocialSupportError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "social-support"]
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

  buttons(SocialSupportYes: "@button_labels[0]", SocialSupportNo: "@button_labels[1]") do
    text("@message.message")
  end
end

card SocialSupportError, then: SocialSupportError do
  buttons(SocialSupportYes: "@button_labels[0]", SocialSupportNo: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card SocialSupportYes, then: AdditionalChildren do
  update_contact(social_support: "Yes")
end

card SocialSupportNo, then: AdditionalChildren do
  update_contact(social_support: "No")
end

```

# Additional Child/ren?

Ask the user if they would like to add additional children

```stack
card AdditionalChildren, then: AdditionalChildrenError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "additional-children"]
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
    AdditionalChildrenYes: "@button_labels[0]",
    AdditionalChildrenNo: "@button_labels[1]",
    AdditionalChildrenNotNow: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card AdditionalChildrenError, then: AdditionalChildrenError do
  buttons(
    AdditionalChildrenYes: "@button_labels[0]",
    AdditionalChildrenNo: "@button_labels[1]",
    AdditionalChildrenNotNow: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card AdditionalChildrenYes do
  update_contact(other_children: "TRUE")
  run_stack("92634e24-6d45-41cb-adc5-a11e904db331")
end

card AdditionalChildrenNo, then: OnboardingComplete do
  update_contact(onboarding_part_3: "complete")
  log("No additional children.  Onboarding Part 3 complete")
end

card AdditionalChildrenNotNow do
  log("here not now")
end

```

# Onboarding complete badge

Send the user a message stating that onboarding is complete

```stack
card OnboardingComplete, then: ValidateOnboardingComplete do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "onboarding-complete-badge"]
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
    MyHealthGuide: "@button_labels[0]",
    MainMenu: "@button_labels[1]",
    DoneForToday: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card OnboardingCompleteError, then: OnboardingCompleteError do
  buttons(
    MyHealthGuide: "@button_labels[0]",
    MainMenu: "@button_labels[1]",
    DoneForToday: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card MyHealthGuide, then: TODO do
  text("MyHealthGuide here")
end

card MainMenu, then: TODO do
  text("MainMenu here")
end

card DoneForToday, then: TODO do
  text("DoneForTodayhere")
end

card ValidateOnboardingComplete, then: OnboardingCompleteError do
  log("Invalid input for Onboarding Complete")
end

```

# Onboarding Incomplete

Send the user a message stating that onboarding is incomplete

```stack
card OnboardingIncomplete, then: ValidateOnboardingIncomplete do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "onboarding-incomplete"]
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
    MyHealthGuide: "@button_labels[0]",
    MainMenu: "@button_labels[1]",
    DoneForToday: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card OnboardingIncompleteError, then: OnboardingIncompleteError do
  buttons(
    MyHealthGuide: "@button_labels[0]",
    MainMenu: "@button_labels[1]",
    DoneForToday: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card MyHealthGuide, then: TODO do
  log("MyHealthGuide selected")
end

card MainMenu, then: TODO do
  log("MainMenu selected")
end

card DoneForToday, then: TODO do
  log("DoneForToday selected")
end

card ValidateOnboardingIncomplete, then: OnboardingIncompleteError do
  log("Invalid input for Onboarding Incomplete")
end

```

## TODO

Temporary TODO card to route to when we haven't created the destination yet

```stack
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

## Content Dependencies

This stack requires the following pieces of content to exist in the content repo, identified by their slugs

## Message Content Slugs

* `user-sentiment` , Asks the user to select how they are feeling
* `location` , Ask the user to select a location type
* `relationship-status`, Ask the user to select a relationship status
* `year-of-birth` , Ask the user to enter a their year of birth
* `confirm-parent-age` , Ask the user to confirm their year of birth
* `socioeconomic-status` , Ask the user to select a socioeconomic status
* `social-support` , Ask the user to select whether they have social social support
* `additional-children`, Ask the user if they want to add additional children
* `onboarding-complete-badge` , Present the user with their onboarding complete badge
* `onboarding-incomplete` , Send the user a message stating that onboarding is incomplete

## Error Message Slugs

TODO: Should we have all the error messages and acknowledgement messages here, or document them more "locally" to the code sections that use them below?

* `button-error` , Generic error for invalid input on buttons (and lists?)
* `invalid-year` , Error message for invalid YearOfBirth input
