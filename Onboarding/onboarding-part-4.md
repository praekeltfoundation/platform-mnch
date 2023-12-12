# Onboarding: Pt 4 - Babies Info

This is where mothers can input all the information about all of the children that are under their care.

They are asked in the beginning how many children they want to add information for, and then they're guided through adding the information for each child. They can add an arbitrary amount of children to their profile.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A full list of these slugs can be found at the end of the stack

## Contact fields

This stack updates the following contact fields:

* `children` - JSON serialised list of children details
* `relationship_to_children` - Can be changed if the user elects to
* `onboarding_part_4` - Set to "incomplete" in the beginning, and "complete" at the end
* `number_of_children` - Set to the number of children under care

## Flow results

This stack writes to the following flow results:

* `child_n_dob_year` - The year of the date of birth of the nth child
* `child_n_dob_month` - The month of the date of birth of the nth child
* `child_n_dob_day` - The day of the date of birth of the nth child
* `child_n_dob` - The date of birth of the nth child

## Connections to other stacks

This stack calls the following stacks:
None - TODO: This stack links either to onboarding complete, or onboarding incomplete

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

<!-- { section: "5a82d578-24e0-45e1-9fd2-2bfa1fa0d7bd", x: 0, y: 0} -->

```stack
card FetchError, then: NumberOfChildren do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "button-error"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
  update_contact(onboarding_part_4: "incomplete")
end

```

# Number of children

```stack
card NumberOfChildren, then: ValidateNumberOfChildren do
  children = "[]"

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "number-of-children"]
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
  number_of_children = ask("@message.message")
end

card ValidateNumberOfChildren when not has_pattern("@number_of_children", "^\d+$"),
  then: NumberOfChildrenError do
  log("Non-integer number of children")
end

card ValidateNumberOfChildren when number_of_children >= 10, then: NumberOfChildrenLarge do
  log("Number of children > 10")
end

card ValidateNumberOfChildren when number_of_children == 0, then: NumberOfChildrenZero do
  log("Number of children == 0")
end

card ValidateNumberOfChildren when number_of_children > 0, then: ChildrenSetup do
  log("Valid number of children")
end

card ValidateNumberOfChildren, then: NumberOfChildrenError do
  log("Invalid input for number of children")
end

card NumberOfChildrenError, then: ValidateNumberOfChildren do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "number-of-children-error"]
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
  number_of_children = ask("@message.message")
end

```

# Number of children large

If they enter >= 10 children, they end up here, to double check that they entered the number correctly

```stack
card NumberOfChildrenLarge, then: NumberOfChildrenLargeError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "number-of-children-large"]
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

  buttons(ChildrenSetup: "@button_labels[0]", NumberOfChildren: "@button_labels[1]") do
    text("@message.message")
  end
end

card NumberOfChildrenLargeError, then: NumberOfChildrenLargeError do
  buttons(ChildrenSetup: "@button_labels[0]", NumberOfChildren: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

# Number of children zero

If they say they don't have any children, double check they entered the number correctly

```stack
card NumberOfChildrenZero, then: NumberOfChildrenZeroError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "number-of-children-zero"]
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

  buttons(NumberOfChildren: "@button_labels[0]", NoChildrenEnd: "@button_labels[1]") do
    text("@message.message")
  end
end

card NumberOfChildrenZeroError, then: NumberOfChildrenZeroError do
  buttons(NumberOfChildren: "@button_labels[0]", NoChildrenEnd: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

# No children end

```stack
card NoChildrenEnd, then: NoChildrenEndError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "no-children-end"]
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

  buttons(TODO: "@button_labels[0]", TODO: "@button_labels[1]") do
    text("@message.message")
  end
end

card NoChildrenEndError, then: NoChildrenEndError do
  buttons(TODO: "@button_labels[0]", TODO: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

# Children setup

This is where we do any config/setup before we start looping through getting the information for all the children

We create the `ordinal_suffix` variable here, based on which child they're entering details for. Will be one of `th`, `st`, `nd`, and `rd`

```stack
card ChildrenSetup, then: OrdinalSuffix do
  update_contact(number_of_children: "@number_of_children")
  children_details = ""
  child_num = 1
end

card OrdinalSuffix when rem(child_num, 100) >= 11 and rem(child_num, 100) <= 13,
  then: ChildName do
  ordinal_suffix = "th"
end

card OrdinalSuffix when rem(child_num, 10) == 1, then: ChildName do
  ordinal_suffix = "st"
end

card OrdinalSuffix when rem(child_num, 10) == 2, then: ChildName do
  ordinal_suffix = "nd"
end

card OrdinalSuffix when rem(child_num, 10) == 3, then: ChildName do
  ordinal_suffix = "rd"
end

card OrdinalSuffix, then: ChildName do
  ordinal_suffix = "th"
end

card ChildName when number_of_children == 1, then: ChildNameSingular do
  log("Collecting information for single child")
end

card ChildName, then: ChildNameMultiple do
  log("Collecting information for multiple children")
end

```

# Child name singular

Saves variable `child_name`

```stack
card ChildNameSingular, then: ChildYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-name-singular"]
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
  child_name = ask("@message.message")
end

```

# Child name multiple

We replace `{{ordinal_number}}` in the message text with the `ordinal_number` variable created in setup, eg. `Let's start with your 2nd born child`

Saves variable `child_name`

```stack
card ChildNameMultiple, then: ChildYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-name-multiple"]
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

  question =
    substitute(message.message, "{{ordinal_number}}", concatenate(child_num, ordinal_suffix))

  child_name = ask("@question")
end

```

# Child year of birth

We use the `ordinal_suffix` created in child name multiple here, to substitute into the message

Saves variable `child_year_of_birth`

```stack
card ChildYearOfBirth when has_number("@child_year_of_birth"), then: ChildProfileConfirmation do
  log("Skipping date of birth, we already have it")
end

card ChildYearOfBirth, then: ValidateYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-year-of-birth"]
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

  question =
    substitute(message.message, "{{ordinal_number}}", concatenate(child_num, ordinal_suffix))

  child_year_of_birth = ask("@question")
end

card ValidateYearOfBirth when not has_pattern("@child_year_of_birth", "^\d+$"),
  then: ChildYearOfBirthError do
  log("non-integer year of birth")
end

card ValidateYearOfBirth when child_year_of_birth > year(today()), then: ChildYearOfBirthError do
  log("child not yet born")
end

card ValidateYearOfBirth when child_year_of_birth < year(today()) - 21,
  then: ChildYearOfBirthError do
  log("child older than 21")
end

card ValidateYearOfBirth, then: ChildMonthOfBirth do
  log("Valid year of birth")
  write_result("child_@(child_num)_dob_year", child_year_of_birth)
end

card ChildYearOfBirthError, then: ValidateYearOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-year-of-birth-error"]
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

  child_year_of_birth = ask("@message.message")
end

```

# Child month of birth

Saves variable `child_month_of_birth`

```stack
card ChildMonthOfBirth, then: ValidateMonthOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-month-of-birth"]
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

  child_month_of_birth = ask("@message.message")
end

card ValidateMonthOfBirth when not has_pattern("@child_month_of_birth", "^\d+$"),
  then: ChildMonthOfBirthError do
  log("Non-integer month of birth")
end

card ValidateMonthOfBirth when child_month_of_birth < 1 or child_month_of_birth > 12,
  then: ChildMonthOfBirthError do
  log("Month of birth not between 1 and 12")
end

card ValidateMonthOfBirth
     when child_year_of_birth == year(today()) and child_month_of_birth > month(today()),
     then: ChildMonthOfBirthError do
  log("Month after current month")
end

card ValidateMonthOfBirth, then: ChildDayOfBirth do
  write_result("child_@(child_num)_dob_month", child_month_of_birth)
  log("Valid month of birth")
end

card ChildMonthOfBirthError, then: ValidateMonthOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-month-of-birth-error"]
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

  child_month_of_birth = ask("@message.message")
end

```

# Child day of birth

Saves variable `child_day_of_birth`

```stack
card ChildDayOfBirth, then: ValidateDayOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-day-of-birth"]
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

  child_day_of_birth = ask("@message.message")
end

card ValidateDayOfBirth when not has_pattern("@child_day_of_birth", "^\d+$"),
  then: ChildDayOfBirthError do
  log("Non-integer day of birth")
end

card ValidateDayOfBirth when child_day_of_birth < 1 or child_day_of_birth > 31,
  then: ChildDayOfBirthError do
  log("Day of birth not between 1 and 31")
end

card ValidateDayOfBirth
     when child_year_of_birth == year(today()) and child_month_of_birth == month(today()) and
            child_day_of_birth > day(today()),
     then: ChildDayOfBirthError do
  log("Day after current day")
end

card ValidateDayOfBirth, then: ChildProfileConfirmation do
  write_result("child_@(child_num)_dob_day", child_day_of_birth)
  child_dob = date(child_year_of_birth, child_month_of_birth, child_day_of_birth)
  write_result("child_@(child_num)_dob", child_dob)
  log("Valid day of birth")
end

card ChildDayOfBirthError, then: ValidateDayOfBirth do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-day-of-birth-error"]
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

  child_day_of_birth = ask("@message.message")
end

```

# Child profile confirmation

Fills the message variables `name` with `child_name`, `date_of_birth` with `child_day_of_birth`, `child_month_of_birth`, and `child_year_of_birth`, and `relation` with `contact.relationship_to_children`

Updates the contact field `children` if the user selects to save a child, adds the current child details to the list

```stack
card ChildProfileConfirmation, then: ChildProfileConfirmationError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "child-profile-confirmation"]
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

  child_name = clean("@child_name")
  # Remove any "
  child_name = substitute(child_name, char(34), "")
  # Remove any \
  child_name = substitute(child_name, char(92), "")
  message_text = substitute(message.message, "{{name}}", child_name)

  date_of_birth = date(child_year_of_birth, child_month_of_birth, child_day_of_birth)
  date_of_birth = datevalue(date_of_birth, "%Y-%m-%d")

  message_text =
    substitute(
      message_text,
      "{{date_of_birth}}",
      "@date_of_birth"
    )

  relationship_to_children =
    find(
      [
        ["mother", "Mother"],
        ["father", "Father"],
        ["grandparent", "Grandparent"],
        ["aunt_or_uncle", "Aunt/Uncle"],
        ["brother_or_sister", "Brother/Sister"],
        ["family_friend", "Family friend"],
        ["other", "Other"],
        ["skip", "Skip"],
        ["", ""]
      ],
      &(&1[0] == "@contact.relationship_to_children")
    )[1]

  message_text = substitute(message_text, "{{relation}}", "@relationship_to_children")

  buttons(SaveChild: "@button_labels[0]", EditChildProfile: "@button_labels[1]") do
    text("@message_text")
  end
end

card ChildProfileConfirmationError, then: ChildProfileConfirmationError do
  buttons(TODO: "@button_labels[0]", EditChildProfile: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card SaveChild, then: NextChild do
  # Remove closing `]`
  children = left(children, len(children) - 1)
  # Add comma if not first item
  children = if(right(children, 1) == "[", children, concatenate(children, ","))
  # Add object to just in JSON format
  # We've already escaped and formatted the values in ChildProfileConfirmation, so this should be JSON compliant
  # TODO: When stacks gets proper list and map manipulation, we can do that instead and serialise to JSON
  children =
    concatenate(children, "{\"name\":\"@child_name\",\"date_of_birth\":\"@date_of_birth\"}]")

  update_contact(children: "@children")
end

card NextChild when child_num == number_of_children, then: OnboardingCompleteBadge do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "no-more-children"]
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
  message_text = substitute(message.message, "{{name}}", child_name)

  text("@message_text")
end

card NextChild, then: NextOrdinalSuffix do
  log("More children to add")
end

```

# Add more children

```stack
card NextOrdinalSuffix when rem(child_num + 1, 100) >= 11 and rem(child_num + 1, 100) <= 13,
  then: AddMoreChildren do
  ordinal_suffix = "th"
end

card NextOrdinalSuffix when rem(child_num + 1, 10) == 1, then: AddMoreChildren do
  ordinal_suffix = "st"
end

card NextOrdinalSuffix when rem(child_num + 1, 10) == 2, then: AddMoreChildren do
  ordinal_suffix = "nd"
end

card NextOrdinalSuffix when rem(child_num + 1, 10) == 3, then: AddMoreChildren do
  ordinal_suffix = "rd"
end

card NextOrdinalSuffix, then: AddMoreChildren do
  ordinal_suffix = "th"
end

card AddMoreChildren, then: AddMoreChildrenError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "add-more-children"]
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

  message_text = substitute(message.message, "{{name}}", child_name)
  ordinal_number = concatenate(child_num + 1, ordinal_suffix)
  message_text = substitute(message_text, "{{ordinal_number}}", ordinal_number)

  buttons(
    AddNextChild: "@button_labels[0]",
    OnboardingCompleteBadge: "@button_labels[1]",
    OnboardingCompleteBadge: "@button_labels[2]"
  ) do
    text("@message_text")
  end
end

card AddMoreChildrenError, then: AddMoreChildrenError do
  buttons(
    AddNextChild: "@button_labels[0]",
    OnboardingCompleteBadge: "@button_labels[1]",
    OnboardingCompleteBadge: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card AddNextChild, then: OrdinalSuffix do
  child_name = ""
  child_day_of_birth = ""
  child_month_of_birth = ""
  child_year_of_birth = ""
  child_num = child_num + 1
end

```

# Edit child profile

```stack
card EditChildProfile, then: EditChildProfileError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "edit-child-profile"]
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
    EditName: "@button_labels[0]",
    EditDateOfBirth: "@button_labels[1]",
    RelationshipToChildren: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card EditChildProfileError, then: EditChildProfileError do
  buttons(
    EditName: "@button_labels[0]",
    EditDateOfBirth: "@button_labels[1]",
    TODO: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card EditName, then: ChildName do
  child_name = ""
end

card EditDateOfBirth, then: ChildYearOfBirth do
  child_year_of_birth = ""
end

```

# Relationship to children

```stack
card RelationshipToChildren, then: RelationshipToChildrenError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "relationship-to-children"]
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

  list("List option",
    Mother: "Mother",
    Father: "Father",
    Grandparent: "Grandparent",
    AuntUncle: "Aunt/Uncle",
    BrotherSister: "Brother/Sister",
    FamilyFriend: "Family friend",
    Other: "Other",
    Skip: "Skip"
  ) do
    text("@message.message")
  end
end

card RelationshipToChildrenError, then: RelationshipToChildrenError do
  list("List option",
    Mother: "Mother",
    Father: "Father",
    Grandparent: "Grandparent",
    AuntUncle: "Aunt/Uncle",
    BrotherSister: "Brother/Sister",
    FamilyFriend: "Family friend",
    Other: "Other",
    Skip: "Skip"
  ) do
    text("@button_error_text")
  end
end

card Mother, then: GoToNext do
  update_contact(relationship_to_children: "mother")
end

card Father, then: GoToNext do
  update_contact(relationship_to_children: "father")
end

card Grandparent, then: GoToNext do
  update_contact(relationship_to_children: "grandparent")
end

card AuntUncle, then: GoToNext do
  update_contact(relationship_to_children: "aunt_or_uncle")
end

card BrotherSister, then: GoToNext do
  update_contact(relationship_to_children: "brother_or_sister")
end

card FamilyFriend, then: GoToNext do
  update_contact(relationship_to_children: "family_friend")
end

card Other, then: GoToNext do
  update_contact(relationship_to_children: "other")
end

card Skip, then: GoToNext do
  update_contact(relationship_to_children: "skip")
end

card GoToNext, then: ChildProfileConfirmation do
  log("Updated relationship to children")
end

```

# Onboarding complete badge

```stack
card OnboardingCompleteBadge, then: OnboardingCompleteBadgeError do
  update_contact(onboarding_part_4: "complete")

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
    TODO: "@button_labels[0]",
    TODO: "@button_labels[1]",
    TODO: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card OnboardingCompleteBadgeError, then: OnboardingCompleteBadgeError do
  buttons(
    TODO: "@button_labels[0]",
    TODO: "@button_labels[1]",
    TODO: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
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

# Content dependancies

We require pages with the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `number-of-children` - WhatsApp message, asking number of children to add
* `number-of-children-large` - WhatsApp message with two buttons, if they enter a number >= 10
* `number-of-children-zero` - Whatsapp message with two buttons, if they enter 0
* `no-children-end` - Whatsapp message with two buttons
* `child-name-singular` - Whatsapp message, if they only have one child
* `child-name-multiple` - Whatsapp message, if they have more than one child. Variable `{{ordinal_number}}`, which gets replaced with the ordinal number of the child they're adding details for, eg. `1st`, `2nd`, `3rd`
* `child-year-of-birth` - Whatsapp message. Variable `{{ordinal_number}}` gets replace with the ordinal number of the
* `child-month-of-birth` - Whatsapp message
* `child-day-of-birth` - Whatsapp message
* `child-profile-confirmation` - Whatsapp message with two buttons. Variables `{{name}}`, `{{date_of_birth}}`, and `{{relation_to_child}}`
* `edit-child-profile` - Whatsapp message with 3 buttons
* `add-more-children` - Whatsapp message with 3 buttons
* `no-more-children` - Whatsapp message
* `relationship-to-children`, whatsapp message with 8-item list (hardcoded for now)

## Error messages

* `button-error`, whatsapp message
* `child-day-of-birth-error` - Whatsapp message
* `child-month-of-birth-error` - Whatsapp messages
* `child-year-of-birth-error` - Whatsapp message
* `number-of-children-error` - WhatsApp message, if they enter a non-number
