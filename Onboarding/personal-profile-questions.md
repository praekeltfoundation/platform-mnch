```stack
trigger(on: "MESSAGE RECEIVED")
when has_any_phrase(event.message.text.body, ["personal"])

```

# Onboarding: Personal Profile Questions

This is the flow for the personal profile questions which are asked in various user profile journeys. All quastions are skippable.

## Contact fields

* `relationship_status`, the user's relationship status, one of `single`, `in a relationship`, `it's complicated`
* `education`, the users's level of education, one of `primary school`, `high school`, `diploma`, `degree`, `masters degree`, `doctors degree`, `none`
* `finance_sentiment`, how the user feels about their finances, one of `comfortable`, `i get by`, `money is an issue`
* `other_children`, how many other children they have, one of `none`, `1`, `2`, `3`, `more than 3`

## Flow results

This journey has no flow result.

## Connections to other stacks

This journey gets called in various places in the Profile Pregnancy journey.

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

<!-- { section: "1d2d2295-8c33-45f3-b64c-8bdc9c5acd6e", x: 0, y: 0} -->

```stack
card FetchError, then: Question1 do
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

## Question 1

Relationship status

```stack
card Question1, then: Question1Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_relationshipstatus"]
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

  relationship_status =
    buttons(Question1Response, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card Question1Error when has_phrase(lower("@relationship_status"), "skip"), then: Question2 do
  log("Skipping relationship status")
end

card Question1Error, then: Question1Error do
  relationship_status =
    buttons(Question1Response, map(button_labels, &[&1, &1])) do
      text("@button_error_text")
    end
end

card Question1Response, then: Question2 do
  relationship_status = lower("@relationship_status")
  log("Updating relationship_status to @relationship_status")
  update_contact(relationship_status: "@relationship_status")
end

```

## Question 2

Education

```stack
card Question2, then: Question2Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_education"]
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

  education =
    list("Education", Question2Response, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card Question2Error when has_phrase(lower("@education"), "skip"), then: Question3 do
  log("Skipping relationship status")
end

card Question2Error, then: Question2Error do
  education =
    list("Education", Question2Response, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card Question2Response when has_phrase(lower("@education"), "skip"), then: Question3 do
  log("Skipping education")
end

card Question2Response, then: Question3 do
  education = lower("@education")
  log("Updating education to @education")
  update_contact(education: "@education")
end

```

## Question 3

Socio-economic

```stack
card Question3, then: Question3Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_q_socioeconomic"]
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

  socio_economic =
    buttons(Question3Response, map(button_labels, &[&1, &1])) do
      text("@message.message")
    end
end

card Question3Error when has_phrase(lower("@socio_economic"), "skip"), then: Question4 do
  log("Skipping socio economic")
end

card Question3Error, then: Question3Error do
  socio_economic =
    buttons(Question3Response, map(button_labels, &[&1, &1])) do
      text("@button_error_text")
    end
end

card Question3Response, then: Question4 do
  socio_economic = lower("@socio_economic")
  log("Updating socio economic to @socio_economic")
  update_contact(socio_economic: "@socio_economic")
end

```

## Question 4

Children

```stack
card Question4, then: Question4Error do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_children"]
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

  children =
    list("Children", Question4Response, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card Question4Error when has_phrase(lower("@children"), "skip") do
  log("Skipping Children")
end

card Question4Error, then: Question4Error do
  children =
    list("Children", Question4Response, map(list_items, &[&1, &1])) do
      text("@list_error_text")
    end
end

card Question4Response when has_phrase(lower("@children"), "skip") do
  log("Skipping children")
end

card Question4Response when has_phrase(lower("@children"), "why") do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_children_why"]
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

  children =
    list("Children", Question4Response, map(list_items, &[&1, &1])) do
      text("@message.message")
    end
end

card Question4Response do
  children = lower("@children")
  log("Updating other_children to @children")
  update_contact(other_children: "@children")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_q_relationshipstatus`, whatsapp message with 3 buttons
* `mnch_onboarding_q_education` , whatsapp message a list of options
* `mnch_onboarding_q_socioeconomic` , whatsapp message with 3 buttons.
* `mnch_onboarding_children`, whatsapp message with a list of options
* `mnch_onboarding_children_why`, whatsapp message with three buttons, and a document

## Error messages

* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons
* `mnch_onboarding_error_handling_list_message`, for when a user sends in a message when we're expecting them to press one of the list options