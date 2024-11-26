<!-- { section: "e335b0ad-9a0c-47ac-a750-61806ef44305", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "hcw")

```

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

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "d032bc4c-282f-422e-bff6-1d83897b82a5", x: 500, y: 48} -->

```stack
card FetchError, then: Checkpoint do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
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

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_list_message"]
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

  list_error_text = page.body.body.text.value.message
end

```

## Checkpoints

Here we check the checkpoints and forward the user to the correct point depending on where they left off.

```stack
card Checkpoint when contact.checkpoint == "hcw_profile_0" do
  then(NurseCheck)
end

card Checkpoint when contact.checkpoint == "hcw_profile_25" do
  then(ProfileProgress25)
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

card Checkpoint when contact.checkpoint == "hcw_personal_info" do
  then(ProfileProgress50Continue)
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_nursecheck"]
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

  write_result("profile_completion", "0%")
  update_contact(profile_completion: "0%")
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    OccupationalRole: "@button_labels[0]",
    JustCurious: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card NurseCheckError, then: NurseCheckError do
  buttons(
    OccupationalRole: "@button_labels[0]",
    JustCurious: "@button_labels[1]"
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_occupational_role"]
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
  list_items = map(message.list_items, & &1.value)

  role =
    list("Role", OccupationalRoleResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card OccupationalRoleError when has_phrase(lower("@role"), "skip") do
  log("Skipping Occupational role")
  then(FacilityType)
end

card OccupationalRoleError, then: OccupationalRoleError do
  role =
    list("Role", OccupationalRoleResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
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

## Just Curious

```stack
card JustCurious, then: JustCuriousError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_curioushcw"]
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

  buttons(Curious: "@button_labels[0]") do
    text("@message.message")
  end
end

card JustCuriousError, then: JustCuriousError do
  buttons(Curious: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Curious

```stack
card Curious do
  # Kick off Generic Onboarding
  log("Navigating to generic profile")
  run_stack("a7eae888-77a0-4e68-ac47-ceb03676bef1")
end

```

## FacilityType

```stack
card FacilityType, then: FacilityTypeError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_facility_type"]
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
  list_items = map(message.list_items, & &1.value)

  facility_type =
    list("Facility", FacilityTypeResponse, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card FacilityTypeError when has_phrase(lower("@facility_type"), "skip") do
  log("Skipping facility type")
  then(ProfessionalSupport)
end

card FacilityTypeError, then: FacilityTypeError do
  facility_type =
    list("Facility", FacilityTypeResponse, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card FacilityTypeResponse when has_phrase(lower("@facility_type"), "skip"),
  then: ProfessionalSupport do
  log("Skipping facility_type")
end

card FacilityTypeResponse, then: ProfessionalSupport do
  facility_type = lower("@facility_type")
  log("Updating facility_type to @facility_type")
  update_contact(facility_type: "@facility_type")
end

```

## ProfessionalSupport

```stack
card ProfessionalSupport, then: ProfessionalSupportError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_professional_support"]
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

  professional_support =
    buttons(ProfessionalSupportResponse, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card ProfessionalSupportError when has_phrase(lower("@professional_support"), "skip") do
  log("Skipping professional support")
  then(PregnancyInfo)
end

card ProfessionalSupportError, then: ProfessionalSupportError do
  professional_support =
    buttons(ProfessionalSupportResponse, map(button_labels, &[&1, &1])) do
      text("@button_error_text")
    end
end

card ProfessionalSupportResponse, then: PregnancyInfo do
  professional_support = lower("@professional_support")
  log("Updating professional_support to @professional_support")
  update_contact(professional_support: "@professional_support")
  write_result("workplace_support", "@professional_support")
end

```

## Pregnancy Information

```stack
card PregnancyInfo when contact.pregnancy_information == true do
  log("Pregnancy info added")
  run_stack("8e71f3ab-9d34-491e-930a-2b1435a9afed")
end

card PregnancyInfo, then: ProfileProgress25 do
  log("Pregnancy info NOT added")
end

```

## ProfileProgress25

```stack
card ProfileProgress25, then: ProfileProgress25Error do
  write_result("profile_completion", "25%")
  update_contact(profile_completion: "25%")
  update_contact(checkpoint: "hcw_profile_25")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_25_hcw"]
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

  buttons(
    ProfileProgress25Continue: "@button_labels[0]",
    ProfileProgress25Why: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ProfileProgress25Error, then: ProfileProgress25Error do
  buttons(
    ProfileProgress25Continue: "@button_labels[0]",
    ProfileProgress25Why: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card ProfileProgress25Continue, then: ProfileProgress50 do
  # Ask the Basic Profile Questions
  log("Ask the Basic Profile Questions")
  run_stack("fe7139a4-60c5-4ced-ad82-daa43f483c37")
end

card ProfileProgress25Why, then: ProfileProgress25WhyBranch do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_why_personal_info"]
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

card ProfileProgress25WhyBranch when contact.data_preference == "text only",
  then: ProfileProgress25WhyError do
  buttons(
    ProfileProgress25Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card ProfileProgress25WhyBranch, then: ProfileProgress25WhyError do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    ProfileProgress25Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card ProfileProgress25WhyError, then: ProfileProgress25WhyError do
  buttons(
    ProfileProgress25Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card RemindMeLater do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_remind_me_later"]
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

  # kick off nudge to complete profile
  log("Scheduling nudge to complete profile")
  schedule_stack("97e8ba1c-5638-4515-bd5d-ca6aca01e7f8", in: 60 * 60 * 23)

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
  write_result("profile_completion", "50%")
  update_contact(profile_completion: "50%")
  update_contact(checkpoint: "hcw_profile_50")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_50_hcw"]
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

  buttons(ProfileProgress50Continue: "@button_labels[0]") do
    text("@message.message")
  end
end

card ProfileProgress50Error, then: ProfileProgress50Error do
  buttons(ProfileProgress50Continue: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card ProfileProgress50Continue, then: ProfileProgress75 do
  # Ask the Personal Profile Questions
  log("Ask the Personal Profile Questions")
  update_contact(checkpoint: "hcw_personal_info")
  run_stack("67e29cda-52a9-4eb4-9fc0-224c44585c8c")
end

```

## ProfileProgress75

```stack
card ProfileProgress75, then: ProfileProgress75Branch do
  write_result("profile_completion", "75%")
  update_contact(profile_completion: "75%")
  update_contact(checkpoint: "hcw_profile_75")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_75_hcw"]
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
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
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

card ProfileProgress75Error, then: ProfileProgress75Error do
  buttons(
    ProfileProgress75Continue: "@button_labels[0]",
    RemindMeLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card ProfileProgress75Continue, then: ProfileProgress100 do
  log("Placeholder Form")
  run_stack("b283e7c1-0a79-45ab-976c-5566d9ba06cd")
end

```

## ProfileProgress100

```stack
card ProfileProgress100, then: ProfileProgress100Branch do
  write_result("profile_completion", "100%")
  update_contact(profile_completion: "100%")
  update_contact(checkpoint: "hcw_profile_100")
  cancel_scheduled_stacks("78cca41f-d27d-4669-ae16-a785744047a1")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_profile_progress_100_hcw"]
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
card ProfileProgress100Branch when contact.data_preference == "text only",
  then: ProfileProgress100Error do
  buttons(
    ExploreHealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Show image
card ProfileProgress100Branch, then: ProfileProgress100Error do
  image_id = page.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
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
    text("@message.message")
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

card ExploreHealthGuide do
  text("TODO: Health Guide TBD as part of new activity")
end

card TopicsForYou do
  text("TODO: Go to personalised menu")
end

card MainMenu do
  log("Go to main menu")
  run_stack("75eada25-7a3e-4df8-a19c-39ace798427d")
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