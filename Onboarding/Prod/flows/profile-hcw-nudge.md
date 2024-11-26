<!-- { section: "e335b0ad-9a0c-47ac-a750-61806ef44305", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "hcwr")

```

# Onboarding: HCW Nudge

This is a nudge for HCWs to complete their profile.

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

## HCW Nudge

```stack
card HCWNudge, then: HCWNudgeError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_nudge_complete_profile"]
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

  buttons(
    CompleteProfile: "@button_labels[0]",
    MainMenu: "@button_labels[1]"
  ) do
    text("@message.message")
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
  run_stack("c4c8d015-2255-4aeb-94be-eb0b7a2174e0")
end

card MainMenu do
  run_stack("75eada25-7a3e-4df8-a19c-39ace798427d")
end

```