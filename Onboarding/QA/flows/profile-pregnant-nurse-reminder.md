```stack
card FetchError, then: NudgeCompleteProfile do
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
end

```

<!-- { section: "d2e4adf7-b975-4f9a-b50c-78812fdd6de3", x: 0, y: 0} -->

```stack
card NudgeCompleteProfile, then: NudgeCompleteProfileError do
  cancel_scheduled_stacks("107bebf6-eb76-4886-a0ee-1a11067fe089")

  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_nudge_complete_profile/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    Continue: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@message.text")
  end
end

card NudgeCompleteProfileError, then: NudgeCompleteProfileError do
  buttons(
    Continue: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

```stack
card Continue do
  run_stack("1ed10e1b-f812-4730-8ec5-3f46088c41c7")
end

```

## Main Menu

```stack
card MainMenu do
  run_stack("fb98bb9d-60a6-47a1-a474-bb0f45b80030")
end

```