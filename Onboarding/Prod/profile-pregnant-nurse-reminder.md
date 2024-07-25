```stack
card FetchError, then: NudgeCompleteProfile do
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

<!-- { section: "d2e4adf7-b975-4f9a-b50c-78812fdd6de3", x: 0, y: 0} -->

```stack
card NudgeCompleteProfile, then: NudgeCompleteProfileError do
  cancel_scheduled_stacks("1fb80591-565b-4e5f-a18d-e02420a12058")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_nudge_complete_profile"]
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
    Continue: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@message.message")
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
  run_stack("406cd221-3e6d-41cb-bc1e-cec65d412fb8")
end

```

## Main Menu

```stack
card MainMenu do
  run_stack("21b892d6-685c-458e-adae-304ece46022a")
end

```