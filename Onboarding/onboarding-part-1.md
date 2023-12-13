# Onboarding: Pt 1 - Welcome

This is the first flow that users interact with during onboarding.

If they haven't accepted the terms and conditions, then they'll go through this flow. If they have, then they'll instead go to the main menu.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `language` , this stack allows the user to select their language.
* `privacy_policy` , this stack sets the privacy policy to `TRUE` if they accept it.
* `user_intent`, set according to user choice, to one of: `expecting`, `newborn`, `children`, `health`, `family`, `patient_care`, and `facility_admin`
* `relationship_to_children`, set according to user choice, to one of: `mother`, `father`, `grandparent`, `aunt_or_uncle`, `brother_or_sister`, `family_friend`, `other`, `skip`
* `onboarding_part_1`, gets set to `incomplete` when they click the "Get started" button, gets set to "complete" when they reach the end of the stack

## Flow results

This stack doesn't save any flow results

## Connections to other stacks

* Goes to "Onboarding Part 2" to collect the mother's details, if they select "Expecting" as their intent
* Goes to "Onboarding Part 4" to collect the baby's details, if they select "Newborn baby" or "My children" as their intent

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "152df000-7e2b-4bb7-8a42-7c269f7fb568", x: 0, y: 0} -->

```stack
card FetchError, then: WelcomeMessage do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "button-error"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

```

## Welcome Message

```stack
card WelcomeMessage, then: WelcomeMessageError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "welcome-message"]
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

  buttons(PrivacyPolicy: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@message.message")
  end
end

card WelcomeMessageError, then: WelcomeMessageError do
  buttons(PrivacyPolicy: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Language Options

List values are hardcoded for now, since ContentRepo doesn't yet have support for list messages

Each language goes to its own stack, but is all set to English for now, since there aren't any translations. Having separate stacks per language helps if the language options are themselves translated.

```stack
card LanguageOptions, then: LanguageOptionsError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "language-options"]
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

  language =
    list("Languages", Language1: "Language 1", Language2: "Language 2", Language3: "Language 3") do
      text("@message.message")
    end
end

card LanguageOptionsError, then: LanguageOptionsError do
  language =
    list("Languages", Language1: "Language 1", Language2: "Language 2", Language3: "Language 3") do
      text("@button_error_text")
    end
end

card Language1, then: LanguageConfirmation do
  update_contact(language: "eng")
end

card Language2, then: LanguageConfirmation do
  update_contact(language: "eng")
end

card Language3, then: LanguageConfirmation do
  update_contact(language: "eng")
end

```

## Language Confirmation

Occurances of `{{language}}` in the message are replaced with the user-selected option

```stack
card LanguageConfirmation, then: LanguageConfirmationError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "language-confirmation"]
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
  message_text = substitute(message.message, "{{language}}", "@language.label")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(PrivacyPolicy: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@message_text")
  end
end

card LanguageConfirmationError, then: LanguageConfirmationError do
  buttons(PrivacyPolicy: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Privacy policy

This message has the privacy policy as a document attachment

```stack
card PrivacyPolicy, then: PrivacyPolicyError do
  update_contact(onboarding_part_1: "incomplete")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "privacy-policy"]
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

  document =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/documents/@message.document/",
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  document_url = document.body.meta.download_url

  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    AcceptPrivacyPolicy: "@button_labels[0]",
    DeclinePrivacy: "@button_labels[1]",
    ReadSummary: "@button_labels[2]"
  ) do
    document("@document_url")
    text("@message.message")
  end
end

card PrivacyPolicyError, then: PrivacyPolicyError do
  buttons(
    AcceptPrivacyPolicy: "@button_labels[0]",
    DeclinePrivacy: "@button_labels[1]",
    ReadSummary: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card AcceptPrivacyPolicy, then: UserIntent do
  update_contact(privacy_policy: "TRUE")
end

```

## Decline privacy

```stack
card DeclinePrivacy, then: DeclinePrivacyError do
  update_contact(privacy_policy: "NULL")

  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "decline-privacy"]
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

  buttons(PrivacyPolicy: "@button_labels[0]", TODO: "@button_labels[1]") do
    text("@message.message")
  end
end

card DeclinePrivacyError, then: DeclinePrivacyError do
  buttons(PrivacyPolicy: "@button_labels[0]", TODO: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Read summary

```stack
card ReadSummary, then: ReadSummaryError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "read-summary"]
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

  document =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/documents/@message.document/",
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  document_url = document.body.meta.download_url

  button_labels = map(message.buttons, & &1.value.title)

  buttons(UserIntent: "@button_labels[0]", DeclinePrivacy: "@button_labels[1]") do
    document("@document_url")
    text("@message.message")
  end
end

card ReadSummaryError, then: ReadSummaryError do
  buttons(UserIntent: "@button_labels[0]", DeclinePrivacy: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## User intent

Values saved into the `user_intent` contact field:

* expecting
* newborn
* children
* health
* family
* patient_care
* facility_admin

```stack
card UserIntent, then: UserIntentError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "user-intent"]
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

  list("List option",
    Expecting: "Expecting",
    Newborn: "Newborn baby",
    Children: "My children",
    Health: "My health",
    Family: "My family",
    PatientCare: "Patient care",
    FaciltyAdmin: "Facility admin"
  ) do
    text("@message.message")
  end
end

card UserIntentError, then: UserIntentError do
  list("List option",
    Expecting: "Expecting",
    Newborn: "Newborn baby",
    Children: "My children",
    Health: "My health",
    Family: "My family",
    PatientCare: "Patient care",
    FaciltyAdmin: "Facility admin"
  ) do
    text("@button_error_text")
  end
end

card Expecting, then: RelationshipToChildren do
  update_contact(user_intent: "expecting")
end

card Newborn, then: RelationshipToChildren do
  update_contact(user_intent: "newborn")
end

card Children, then: RelationshipToChildren do
  update_contact(user_intent: "children")
end

card Health, then: TODO do
  update_contact(user_intent: "health")
end

card Family, then: TODO do
  update_contact(user_intent: "family")
end

card PatientCare, then: TODO do
  update_contact(user_intent: "patient_care")
end

card FaciltyAdmin, then: TODO do
  update_contact(user_intent: "facility_admin")
end

```

## Relationship to children

Values saved into the `relationship_to_children` contact field:

* mother
* father
* grandparent
* aunt_or_uncle
* brother_or_sister
* family_friend
* other
* skip

```stack
card RelationshipToChildren, then: RelationshipToChildrenError do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "relationship-to-children"]
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

  list("List option",
    Mother: "Mother",
    Father: "Father",
    Grandparent: "Grandparent",
    AuntUncle: "Aunt/Uncle",
    BrotherSister: "Brother/Sister",
    FamilyFriend: "Family friend",
    Other: "Other",
    Skip: "Skip"
  ) do
    text("@message.message")
  end
end

card RelationshipToChildrenError, then: RelationshipToChildrenError do
  list("List option",
    Mother: "Mother",
    Father: "Father",
    Grandparent: "Grandparent",
    AuntUncle: "Aunt/Uncle",
    BrotherSister: "Brother/Sister",
    FamilyFriend: "Family friend",
    Other: "Other",
    Skip: "Skip"
  ) do
    text("@button_error_text")
  end
end

card Mother, then: GoToNext do
  update_contact(relationship_to_children: "mother")
end

card Father, then: GoToNext do
  update_contact(relationship_to_children: "father")
end

card Grandparent, then: GoToNext do
  update_contact(relationship_to_children: "grandparent")
end

card AuntUncle, then: GoToNext do
  update_contact(relationship_to_children: "aunt_or_uncle")
end

card BrotherSister, then: GoToNext do
  update_contact(relationship_to_children: "brother_or_sister")
end

card FamilyFriend, then: GoToNext do
  update_contact(relationship_to_children: "family_friend")
end

card Other, then: GoToNext do
  update_contact(relationship_to_children: "other")
end

card Skip, then: GoToNext do
  update_contact(relationship_to_children: "skip")
end

card GoToNext, then: GoToNextPart do
  update_contact(onboarding_part_1: "complete")
  update_contact(onboarding_part_2: "incomplete")
end

card GoToNextPart when contact.user_intent == "expecting", then: GoToMotherDetails do
  log("User intent is expecting, go to mother details")
end

card GoToNextPart when contact.user_intent == "newborn", then: GoToChildrenDetails do
  log("User intent in newborn, go to children details")
end

card GoToNextPart when contact.user_intent = "children", then: GoToChildrenDetails do
  log("User intent in children, go to children details")
end

card GoToNextPart, then: TODO do
  log("Other user intent, TODO")
end

card GoToMotherDetails do
  run_stack("16209615-bd5b-4514-9bfa-15c9293d495f")
end

card GoToChildrenDetails do
  run_stack("92634e24-6d45-41cb-adc5-a11e904db331")
end

```

## TODO

Temporary TODO card to route to when we haven't created the destination yet

```stack
card TODO do
  search =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["whatsapp", "true"],
        ["slug", "todo"]
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

  text("@page.body.body.text.value.message")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `welcome-message` , whatsapp message with two buttons
* `language-options` , whatsapp message with 3 item list (hardcoded for now, since contentrepo can't do whatsapp lists)
* `language-confirmation`, whatsapp message with two buttons, variable `{{language}}` in message content will be replaced with selected language
* `privacy-policy`, whatsapp message with three buttons, and a document
* `decline-privacy`, whatsapp message with two buttons
* `read-summary`, whatsapp message with two buttons, and a document
* `user-intent`, whatsapp message with 7-item list (hardcoded for now)
* `relationship-to-children`, whatsapp message with 8-item list (hardcoded for now)

## Error messages

* `button-error`, for when a user sends in a message when we're expecting them to press one of the buttons
