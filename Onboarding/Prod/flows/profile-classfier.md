```stack
trigger(on: "MESSAGE RECEIVED")
when has_any_phrase(event.message.text.body, ["classify"])

```

# Onboarding: Profile Classifier

In this flow we allow the user to select one or multiple Domains, and then prioritise which subsequent journey to send the user to based on their response. This journey falls between the first entry point and anything that comes after.

## Contact fields

* `name`, this stack sets the user's name
* `love_and_relationships`, a boolean that is set to true if the user selects this domain
* `pregnancy_information`, a boolean that is set to true if the user selects this domain
* `baby_and_child`, a boolean that is set to true if the user selects this domain
* `well_being`, a boolean that is set to true if the user selects this domain
* `family_planning`, a boolean that is set to true if the user selects this domain
* `info_for_health_professionals`, a boolean that is set to true if the user selects this domain
* `checkpoint`, the checkpoint for where we are in onboarding

## Flow results

## Connections to other stacks

* Intro & Welcome starts this stack
* Goes to Profile Pregnancy Health if they select `pregnancy_information`
* Goes to Profile HCW if they select `info_for_health_professionals`
* Goes to Generic Profile if they select anything else or nothing

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card Checkpoint, then: NameError do
  update_contact(checkpoint: "profile_classifier")
end

card NameError, then: Name do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_name_error"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  name_error_text = page.body.body.text.value.message

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

```

## Name and NameValidation

<!-- { section: "c3a73fa8-590a-4d2a-ba3e-fb9deef2bfcb", x: 0, y: 0} -->

```stack
card Name, then: NameValidation do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_name_call"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  name = ask("@message.message")
end

card NameValidation when lower("@name") == "skip" do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_name_skip"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(Name: "@button_labels[0]", Domains1: "@button_labels[1]") do
    text("@message.message")
  end
end

card NameValidation when has_number("@name") == true or len("@name") > 20, then: NameValidation do
  name = ask("@name_error_text")
end

card NameValidation, then: Domains1 do
  log("Name @name validated @has_number(\"@name\")")
  update_contact(name: "@name")
end

```

# Domains

Each of the Domains has a text only and text and images branch.

## Domains 1

Introductory message to domains.

```stack
card Domains1, then: Domains1Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_01"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  message_text = substitute(message.message, "{@username}", "@contact.name")
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains1Branch when @contact.data_preference == "text only", then: Domains1Error do
  buttons(Domains2: "@button_labels[0]") do
    text("@message_text")
  end
end

# Show image
card Domains1Branch, then: Domains1Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(Domains2: "@button_labels[0]") do
    image("@image_data.body.meta.download_url")
    text("@message_text")
  end
end

card Domains1Error do
  buttons(Domains2: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Domains 2

Love and relationships

```stack
card Domains2, then: Domains2Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_02"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains2Branch when @contact.data_preference == "text only", then: Domains2Error do
  buttons(AddDomain2: "@button_labels[0]", Domains3: "@button_labels[1]") do
    text("@message.message")
  end
end

card Domains2Branch, then: Domains2Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(AddDomain2: "@button_labels[0]", Domains3: "@button_labels[1]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card AddDomain2, then: Domains3 do
  update_contact(love_and_relationships: "true")
end

card Domains2Error do
  buttons(AddDomain2: "@button_labels[0]", Domains3: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Domains 3

Pregnancy Information

```stack
card Domains3, then: Domains3Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_03"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains3Branch when @contact.data_preference == "text only", then: Domains3Error do
  buttons(AddDomain3: "@button_labels[0]", Domains4: "@button_labels[1]") do
    text("@message.message")
  end
end

# Show image
card Domains3Branch, then: Domains3Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(AddDomain3: "@button_labels[0]", Domains4: "@button_labels[1]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card AddDomain3, then: Domains4 do
  update_contact(pregnancy_information: "true")
end

card Domains3Error do
  buttons(AddDomain3: "@button_labels[0]", Domains4: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Domains 4

Baby and Child Health

```stack
card Domains4, then: Domains4Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_04"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains4Branch when @contact.data_preference == "text only", then: Domains4Error do
  buttons(AddDomain4: "@button_labels[0]", Domains5: "@button_labels[1]") do
    text("@message.message")
  end
end

# Show image
card Domains4Branch, then: Domains4Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(AddDomain4: "@button_labels[0]", Domains5: "@button_labels[1]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card AddDomain4, then: Domains5 do
  update_contact(baby_and_child: "true")
end

card Domains4Error do
  buttons(AddDomain4: "@button_labels[0]", Domains5: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Domains 5

Well-Being

```stack
card Domains5, then: Domains5Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_05"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains5Branch when @contact.data_preference == "text only", then: Domains5Error do
  buttons(AddDomain5: "@button_labels[0]", Domains6: "@button_labels[1]") do
    text("@message.message")
  end
end

# Show image
card Domains5Branch, then: Domains5Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(AddDomain5: "@button_labels[0]", Domains6: "@button_labels[1]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card AddDomain5, then: Domains6 do
  update_contact(well_being: "true")
end

card Domains5Error do
  buttons(AddDomain5: "@button_labels[0]", Domains6: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Domains 6

Family Planning

```stack
card Domains6, then: Domains6Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_06"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains6Branch when @contact.data_preference == "text only", then: Domains6Error do
  buttons(AddDomain6: "@button_labels[0]", Domains7: "@button_labels[1]") do
    text("@message.message")
  end
end

# Show image
card Domains6Branch, then: Domains6Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(AddDomain6: "@button_labels[0]", Domains7: "@button_labels[1]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card AddDomain6, then: Domains7 do
  update_contact(family_planning: "true")
end

card Domains6Error do
  buttons(AddDomain6: "@button_labels[0]", Domains7: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Domains 7

Info for health professionals

```stack
card Domains7, then: Domains7Branch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_domains_07"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card Domains7Branch when @contact.data_preference == "text only", then: Domains7Error do
  buttons(AddDomain7: "@button_labels[0]", GoToNext: "@button_labels[1]") do
    text("@message.message")
  end
end

# Show image
card Domains7Branch, then: Domains7Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(AddDomain7: "@button_labels[0]", GoToNext: "@button_labels[1]") do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card AddDomain7, then: GoToNext do
  update_contact(info_for_health_professionals: "true")
end

card Domains7Error do
  buttons(AddDomain7: "@button_labels[0]", GoToNext: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## GoToNext

This determines which journey to kick off next based on prioritising the domains selected. The priority is:

1. Pregnancy
2. Info for health professionals
3. Well-Being / Family Planning / Baby and Child / Love and Relationships

```stack
card GoToNext when contact.pregnancy_information do
  log("Navigating to Pregnancy Profile")
  run_stack("2063ff09-4405-4cf2-9a57-12ffa00c99da")
end

card GoToNext when contact.info_for_health_professionals do
  log("Navigating to Health Professional Profile")
  run_stack("c4c8d015-2255-4aeb-94be-eb0b7a2174e0")
end

card GoToNext do
  # For all other options, go to the generic profile onboarding
  log("Navigating to generic profile")
  run_stack("a7eae888-77a0-4e68-ac47-ceb03676bef1")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_name`, a whatsapp message asking the user for their name
* `mnch_onboarding_name_skip`, a whatsapp message with 2 buttons
* `mnch_onboarding_domains_01`, a whatsapp message with 1 buttons
* `mnch_onboarding_domains_02`, a whatsapp message with 2 buttons
* `mnch_onboarding_domains_03`, a whatsapp message with 2 buttons
* `mnch_onboarding_domains_04`, a whatsapp message with 2 buttons
* `mnch_onboarding_domains_05`, a whatsapp message with 2 buttons
* `mnch_onboarding_domains_06`, a whatsapp message with 2 buttons
* `mnch_onboarding_domains_07`, a whatsapp message with 2 buttons

## Error messages

* `mnch_onboarding_name_error`, for when the user types an invalid name
* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons