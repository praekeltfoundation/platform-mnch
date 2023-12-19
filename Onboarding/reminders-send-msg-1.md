# Onboarding: Send Reminder Message #1

This stack sends the reminder message.  It pulls its content from a page in ContentRepo with the slug `re-engagement-message-1`.  For now there is only the 1 reminder message.  The rest of the logic and messages are still to be designed & developed

## Connections to other stacks

* This stack gets called on a schedule set by `Onboarding: Schedule Reminder Msg #1`
* When a user clicks `Get Started` we send them to `Onboarding: Pt 2 - Pregnancy Detail`

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxx |

<!-- { section: "432ba496-7feb-4d54-bebd-a8be57e66a81", x: 0, y: 0} -->

```stack
card SendMessage do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "re-engagement-message-1"]
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

  buttons(GetStarted: "@button_labels[0]", NotInterested: "@button_labels[1]") do
    text("@message.message")
  end

  text("@page.body.body.text.value.message")
end

card GetStarted do
  run_stack("16209615-bd5b-4514-9bfa-15c9293d495f")
end

card NotInterested do
  update_contact(onboarding_part_2: "Not Interested")
  log("User clicked Not Interested.  No path to route yet")
end

```