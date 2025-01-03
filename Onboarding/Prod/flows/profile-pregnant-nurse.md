<!-- { section: "e335b0ad-9a0c-47ac-a750-61806ef44305", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "pregnurse")

```

# Onboarding: Profile Pregnant Nurse

This is the onboarding flow specifically for pregnant nurses, indicating that they need to receive both content for pregnant women, and for HCW's.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `profile_type`, writes the value `pregnant_nurse`
* `profile_completion`, how complete the profile is. One of `20%`, `40%`, `60%`, `80%`, `100%`
* `checkpoint`, the checkpoint for where we are in this flow. One of `pregnant_nurse_profile_20`, `pregnant_nurse_profile_40`, `pregnant_nurse_profile_60`, `pregnant_nurse_profile_80`, `pregnant_nurse_profile_100`

## Flow results

* `profile_completion`, How much of the profile they have completed e.g. 0%, 25%, 50%, 100%
* `questioning_info_gathering`, Whether they questioned why we need certain information. One of `yes` or `no`.

## Connections to other stacks

* Basic Profile Questions
* Personal Profile Questions
* Nurse Profile Questions
* Menu Redirect

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "41a32b90-a27b-48a5-a8a4-05b2bf55cb9a", x: 500, y: 48} -->

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
end

```

## Check Point

```stack
card Checkpoint
     when contact.checkpoint == "pregnant_nurse_profile_40" or
            has_beginning(contact.checkpoint, "hcw_profile_"),
     then: PregnantNurse40 do
  log("Go to PregnantNurse40")
end

card Checkpoint when contact.checkpoint == "pregnant_nurse_profile_60",
  then: PregnantNurse60 do
  log("Go to PregnantNurse60")
end

card Checkpoint when contact.checkpoint == "pregnant_nurse_profile_80",
  then: PregnantNurse80 do
  log("Go to PregnantNurse80")
end

card Checkpoint when contact.checkpoint == "pregnant_nurse_profile_100",
  then: PregnantNurse100 do
  log("Go to PregnantNurse100")
end

card Checkpoint, then: PregnantNurse20 do
  log("Go to PregnantNurse20")
end

```

## Pregnant Nurse 20%

<!-- { section: "478a00b1-4d78-423b-a5c4-499c26b13591", x: 0, y: 0} -->

```stack
card PregnantNurse20, then: DisplayPregnantNurse20 do
  update_contact(profile_type: "pregnant_nurse")
  write_result("profile_completion", "20%")
  update_contact(profile_completion: "20%")
  update_contact(checkpoint: "pregnant_nurse_profile_20")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnant_nurse_20"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayPregnantNurse20 when contact.data_preference == "text only",
  then: PregnantNurse20Error do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    HealthGuide: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayPregnantNurse20, then: PregnantNurse20Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    HealthGuide: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card PregnantNurse20Error, then: PregnantNurse20Error do
  buttons(
    CompleteProfile: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    HealthGuide: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

```stack
card TopicsForYou, then: TODO do
  log("TopicsForYou to be developed as part of a new activity")
end

card HealthGuide, then: TODO do
  log("ExploreHealthGuide to be developed as part of a new activity")
end

card TODO do
end

```

## Nurse Questions

```stack
card CompleteProfile, then: PregnantNurse40 do
  log("Running Nurse Profile Questions")
  run_stack("c4c8d015-2255-4aeb-94be-eb0b7a2174e0")
end

```

## Pregnant Nurse 40%

```stack
card PregnantNurse40, then: DisplayPregnantNurse40 do
  write_result("profile_completion", "40%")
  update_contact(profile_completion: "40%")
  update_contact(checkpoint: "pregnant_nurse_profile_40")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnant_nurse_40"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

card DisplayPregnantNurse40, then: PregnantNurse40Error do
  buttons(BasicProfileQuestions: "@button_labels[0]") do
    text("@message.message")
  end
end

card PregnantNurse40Error, then: PregnantNurse40Error do
  buttons(BasicProfileQuestions: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

```stack
card BasicProfileQuestions, then: PregnantNurse60 do
  log("Running Basic Profile Questions")
  run_stack("fe7139a4-60c5-4ced-ad82-daa43f483c37")
end

```

## Pregnant Nurse 60%

```stack
card PregnantNurse60, then: PregnantNurse60Error do
  write_result("profile_completion", "60%")
  update_contact(profile_completion: "60%")
  update_contact(checkpoint: "pregnant_nurse_profile_60")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnant_nurse_60"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    WhyPersonalInfo: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

card PregnantNurse60Error, then: PregnantNurse60Error do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    WhyPersonalInfo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Ask Personal Questions

```stack
card PersonalProfileQuestions, then: PregnantNurse80 do
  write_result("questioning_info_gathering", "no")
  log("Go to Personal Questions")
  run_stack("67e29cda-52a9-4eb4-9fc0-224c44585c8c")
end

```

## Why Personal Information

```stack
card WhyPersonalInfo, then: DisplayWhyPersonalInfo do
  write_result("questioning_info_gathering", "yes")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_why_personal_info"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayWhyPersonalInfo when contact.data_preference == "text only",
  then: WhyPersonalInfoError do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayWhyPersonalInfo, then: WhyPersonalInfoError do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card WhyPersonalInfoError, then: WhyPersonalInfoError do
  buttons(
    PersonalProfileQuestions: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Remind Later

```stack
card RemindLater, then: RemindLaterError do
  schedule_stack("d7cc2c04-5931-4910-9f1e-0cebbb80d1f8", in: 23 * 60 * 60)

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_remind_me_later"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)

  buttons(TopicsForYou: "@button_labels[0]") do
    text("@message.message")
  end
end

card RemindLaterError, then: RemindLaterError do
  buttons(TopicsForYou: "@button_labels[0]") do
    text("@button_error_text")
  end
end

```

## Pregnant Nurse 80%

```stack
card PregnantNurse80, then: DisplayPregnantNurse80 do
  write_result("profile_completion", "80%")
  update_contact(profile_completion: "80%")
  update_contact(checkpoint: "pregnant_nurse_profile_80")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnant_nurse_80"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayPregnantNurse80 when contact.data_preference == "text only",
  then: PregnantNurse80Error do
  buttons(
    LOCAssessment: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayPregnantNurse80, then: PregnantNurse80Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    LOCAssessment: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card PregnantNurse80Error, then: PregnantNurse80Error do
  buttons(
    LOCAssessment: "@button_labels[0]",
    RemindLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## LOC Assessment

```stack
card LOCAssessment, then: PregnantNurse100 do
  run_stack("b283e7c1-0a79-45ab-976c-5566d9ba06cd")
end

```

## Pregnant Nurse 100%

```stack
card PregnantNurse100, then: DisplayPregnantNurse100 do
  write_result("profile_completion", "100%")
  update_contact(profile_completion: "100%")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_pregnant_nurse_100"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  content_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.body.text.value
  button_labels = map(message.buttons, & &1.value.title)
end

# Text only
card DisplayPregnantNurse100 when contact.data_preference == "text only",
  then: PregnantNurse100Error do
  buttons(
    HealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

# Display with image
card DisplayPregnantNurse100, then: PregnantNurse100Error do
  image_id = content_data.body.body.text.value.image

  image_data =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/images/@image_id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  buttons(
    HealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    image("@image_data.body.meta.download_url")
    text("@message.message")
  end
end

card PregnantNurse100Error, then: PregnantNurse100Error do
  buttons(
    HealthGuide: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    MainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Main Menu

```stack
card MainMenu do
  log("Go to Main Menu")
  run_stack("75eada25-7a3e-4df8-a19c-39ace798427d")
end

```