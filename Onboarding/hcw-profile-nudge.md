# Onboarding: HCW Nudge

This is a nudge for HCWs to complete their profile.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

## Flow results

## Connections to other stacks

* If the user consents, it takes them to the HCW Profile flow to complete their profile.
* The user can click on Main Menu to take them to the non-personalised menu

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

<!-- { section: "9548c74a-61db-42e5-bcbe-e4ca3461988f", x: 0, y: 0} -->

```stack
card FetchError, then: HCWNudge do
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

## HCW Nudge

```stack
card HCWNudge, then: HCWNudgeError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_nudge_complete_profile"]
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
  run_stack("38cca9df-21a1-4edc-9c13-5724904ca3c3")
end

card MainMenu do
  text("TODO: Go to non-personalised menu")
end

```