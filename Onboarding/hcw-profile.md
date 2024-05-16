# Onboarding: Profile HCW

This is the onboarding flow for Health Care Workers.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `occupational_role`, the type of nurse that they are e.g. `Enrolled Nurse`, `Enrolled Nursing Auxillary`, `Registered Nurse`, `Advanced Practice Nurse`, `Public Health Nurse`, `Midwife`, `Psyciatric Nurse`, `Other`
* `facility_type`, the type of facility they work in, e.g. `District Hospital`, `Regional Hospital`, `Academic Hospital`, `Clinic`, `Comminity Health Clinic`, `Satellite Clinic`, `Other`
* `professional_support`, whether the user receives professional support or not
* `checkpoint`, where in the flow the user stopped

## Flow results

* `workplace_support`,  Whether the nurse receives workplace support. Options: `Yes, always`, `Sometimes`, `No, never`
* `profile_completion`, How much of the profile they have completed e.g. 0%, 50%, 100%

## Connections to other stacks

* If the user is just curios (so, not a HCW) they will be directed to the Generic Profile
* During the flow the user will be asked to complete the Basic Profile, Personal Profile, and LOC Assessment

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  |

## Setup

Here we do any setup and fetching of values before we start the flow.

```stack
card FetchError, then: NurseCheck do
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
end

```

## Checkpoints

Here we check the checkpoints and forward the user to the correct point depending on where they left off.

```stack
card Checkpoint when contact.checkpoint == "hcw_profile_0" do
  then(NurseCheck)
end

card Checkpoint when contact.checkpoint == "hcw_profile_30" do
  then(ProfileProgress30)
end

card Checkpoint when contact.checkpoint == "hcw_profile_50" do
  then(ProfileProgress50)
end

card Checkpoint when contact.checkpoint == "hcw_profile_75" do
  then(ProfileProgress75)
end

card Checkpoint when contact.checkpoint == "hcw_profile_100" do
  then(ProfileProgress100)
end

card Checkpoint do
  then(NurseCheck)
end

```

## NurseCheck

```stack
card NurseCheck, then: NurseCheckBranch do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_nursecheck"]
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

  write_result("profile_completion", "0%")
  update_contact(checkpoint: "hcw_profile_0")
end

# Text only
card NurseCheckBranch when contact.data_preference == "text only", then: NurseCheckError do
  buttons(
    OccupationalRole: "@button_labels[0]",
    Curious: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Show image
card NurseCheckBranch, then: NurseCheckError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(
    OccupationalRole: "@button_labels[0]",
    Curious: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card NurseCheckError, then: NurseCheckError do
  buttons(
    OccupationalRole: "@button_labels[0]",
    Curious: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## OccupationalRole

```stack
card OccupationalRole, then: OccupationalRoleError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_occupational_role"]
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

card OccupationalRoleResponse when has_phrase(lower("@role"), "skip"), then: FacilityType do
  log("Skipping occupational_role")
end

card OccupationalRoleResponse, then: FacilityType do
  role = lower("@role")
  log("Updating occupational_role to @role")
  update_contact(occupational_role: "@role")
end

```

## Curious

```stack
card Curious do
  # TODO: Kick off Generic Onboarding
  text("TODO")
end

```

## FacilityType

```stack
card FacilityType, then: FacilityTypeError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_facility_type"]
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
  then: ProfessionalSupport do
  log("Skipping facility_type")
end

card FacilityTypeResponse, then: ProfessionalSupport do
  facility_type = lower("@facility_type")
  log("Updating facility_type to @facility_type")
  update_contact(facility_type: "@rofacility_typele")
end

```

## ProfessionalSupport

```stack
card ProfessionalSupport, then: ProfessionalSupportError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_professional_support"]
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

card ProfessionalSupportResponse, then: ProfileProgress30 do
  professional_support = lower("@professional_support")
  log("Updating professional_support to @professional_support")
  update_contact(professional_support: "@professional_support")
  write_result("workplace_support", "@professional_support")
end

```

## ProfileProgress30

```stack
card ProfileProgress30, then: ProfileProgress30Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_30_hcw"]
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

  write_result("profile_completion", "30%")
  update_contact(checkpoint: "hcw_profile_30")

  buttons(
    ProfileProgress30Continue: "@button_labels[0]",
    ProfileProgress30Why: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ProfileProgress30Error, then: ProfileProgress30Error do
  buttons(
    ProfileProgress30Continue: "@button_labels[0]",
    ProfileProgress30Why: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card ProfileProgress30Continue, then: ProfileProgress50 do
  # Ask the Basic Profile Questions
  run_stack("26e0c9e4-6547-4e3f-b9f4-e37c11962b6d")
end

card ProfileProgress30Why, then: ProfileProgress30WhyBranch do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_why_personal_info"]
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

card ProfileProgress30WhyBranch when contact.data_preference == "text only",
  then: ProfileProgress30WhyError do
  buttons(
    ProfileProgress30Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ProfileProgress30WhyBranch, then: ProfileProgress30WhyError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(
    ProfileProgress30Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card ProfileProgress30WhyError, then: ProfileProgress30WhyError do
  buttons(
    ProfileProgress30Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card RemindMeLater do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_remind_me_later"]
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

  # TODO: kick off nudge to complete profile

  buttons(ViewPopularTopics: "@button_labels[0]") do
    text("@message.message")
  end
end

card ViewPopularTopics do
  text("TODO: Browsable content for nurses")
end

```

## ProfileProgress50

```stack
card ProfileProgress50, then: ProfileProgress50Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_50_hcw"]
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

  write_result("profile_completion", "50%")
  update_contact(checkpoint: "hcw_profile_50")

  buttons(ProfileProgress50Continue: "@button_labels[0]") do
    text("@message.message")
  end
end

card ProfileProgress50Error do
  buttons(ProfileProgress50Continue: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card ProfileProgress50Continue, then: ProfileProgress75 do
  # Ask the Personal Profile Questions
  run_stack("61a880e4-cf7b-47c5-a047-60802aaa7975")
end

```

## ProfileProgress75

```stack
card ProfileProgress75, then: ProfileProgress75Branch do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_75_hcw"]
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

  write_result("profile_completion", "75%")
  update_contact(checkpoint: "hcw_profile_75")
end

# Text only
card ProfileProgress75Branch when contact.data_preference == "text only",
  then: ProfileProgress75Error do
  buttons(
    ProfileProgress75Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Show image
card ProfileProgress75Branch, then: ProfileProgress75Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  buttons(
    ProfileProgress75Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card ProfileProgress75Error do
  buttons(
    ProfileProgress75Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card ProfileProgress75Continue, then: ProfileProgress100 do
  # TODO: Ask the LOC Assessment
  # run_stack("61a880e4-cf7b-47c5-a047-60802aaa7975")
  text("TODO: Ask the LOC Assessment")
end

```

## ProfileProgress100

```stack
card ProfileProgress100, then: ProfileProgress100Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100_hcw"]
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

  write_result("profile_completion", "100%")
  update_contact(checkpoint: "hcw_profile_100")

  buttons(
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card ProfileProgress100Error do
  buttons(
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card ExploreHealthGuide do
  text("TODO: Health Guide TBD as part of new activity")
end

card TopicsForYou do
  text("TODO: Go to personalised menu")
end

card MainMenu do
  text("TODO: Go to non-personalised menu")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_nursecheck` , whatsapp message asking whether the user is a nurse or not, with an attached image
* `mnch_onboarding_occupational_role` , whatsapp message asking what type of nurse they are
* `mnch_onboarding_facility_type` , whatsapp message asking what type of facility they work in
* `mnch_onboarding_professional_support` , whatsapp message asking whether they receive professional support or not
* `mnch_onboarding_profile_progress_30_hcw` , whatsapp message with 2 buttons, with an attached image
* `mnch_onboarding_why_personal_info`, whatsapp message with 2 buttons, with an attached image
* `mnch_onboarding_profile_progress_50_hcw`, whatsapp message with 1 button
* `mnch_onboarding_profile_progress_75_hcw`, whatsapp message with 2 buttons, with an attached image
* `mnch_onboarding_profile_progress_100_hcw`, whatsapp message with 3 buttons

## Error messages

* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons
* `mnch_onboarding_error_handling_list_message`, for when a user sends in a message when we're expecting them to press one of the list items