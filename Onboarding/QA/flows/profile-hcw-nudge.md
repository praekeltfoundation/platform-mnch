# Onboarding: HCW Reminder

This is a reminder for HCWs to complete their profile.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

None.

## Flow results

None.

## Connections to other stacks

* If the user consents, it takes them to the HCW Profile flow to complete their profile.
* The user can click on Main Menu to take them to the non-personalised menu

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "9548c74a-61db-42e5-bcbe-e4ca3461988f", x: 0, y: 0} -->

```stack
card FetchError, then: HCWNudge do
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

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_list_message/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  list_error_text = page.body.messages[0].text
end

```

## HCW Nudge

```stack
card HCWNudge, then: HCWNudgeError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_nudge_complete_profile/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.value.title)

  write_result("profile_completion", "0%")

  buttons(
    CompleteProfile: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@message.text")
  end
end

card HCWNudgeError, then: HCWNudgeError do
  buttons(
    CompleteProfile: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card CompleteProfile do
  # Go to HCWProfile to complete
  log("Go to HCWProfile to complete")
  run_stack("9aa596d3-40f0-4349-8322-e44d1fd1d127")
end

card MainMenu do
  text("TODO: Go to non-personalised menu")
end

```