# Onboarding: Pt 1 - Welcome

This is the first flow that users interact with during onboarding.

If they haven't accepted the terms and conditions, then they'll go through this flow. If they have, then they'll instead go to the main menu.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `language` , this stack allows the user to select their language.
* `privacy_policy` , this stack sets the privacy policy to `yes` if they accept it or `no` if they don't.
* `opted_in`, this stack sets the opt in value to `yes` or `no`
* `intent`, set according to user choice, to one of: `create profile`, `get health advice` or `explore`
* `data_preference`, this stack allows the user to select their data preference and stores one of `all`, `text and images`, `text only`

## Flow results

* `intro_started`, this stack sets this value to `yes` when the intro starts
* `intro_completed`, this stack sets this value to true when the user leaves this stack for any of the above `intent` reasons

## Connections to other stacks

* Onboarding Part 1.1 is scheduled if they don't agree to the privacy policy

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
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "button-error"]
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
end

```

## Branching

* If they are entering this journey and the privacy policy has not been accepted, we redirect to the privacy policy, otherwise we start from the beginning (this will happen in the case of the reminder stack starting this stack).

* If the privacy policy is accepted, but they  haven't opted in, got to Opt In

* If the privacy policy is accepted and they have opted in, go to the Intent

```stack
card GoToPrivacyPolicy
     when contact.privacy_policy_accepted == "yes" and
            (contact.opted_in == "" or contact.opted_in == "no"),
     then: OptIn do
  log("Privacy Policy accepted and not opted in, go to Opt In")
end

card GoToPrivacyPolicy
     when contact.privacy_policy_accepted == "yes" and contact.opted_in == "yes",
     then: UserIntent do
  log("Privacy Policy accepted and opted in, go to User Intent")
end

card GoToPrivacyPolicy when contact.privacy_policy_accepted == "no", then: PrivacyPolicy do
  log("Privacy Policy not accepted, go to Privacy Policy")
end

card GoToPrivacyPolicy, then: WelcomeMessage do
  log("Privacy Policy not accepted or declined, go to Welcome Message")
end

```

## Welcome Message

```stack
card WelcomeMessage, then: WelcomeMessageError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "welcome"]
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

  buttons(DefaultLanguageSelection: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@message.message")
  end
end

card WelcomeMessageError, then: WelcomeMessageError do
  buttons(DefaultLanguageSelection: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card DefaultLanguageSelection, then: PrivacyPolicy do
  update_contact(language: "en")
end

```

## Language Options

List values are hardcoded for now, since ContentRepo doesn't yet have support for list messages

Each language goes to its own stack, but is all set to English for now, since there aren't any translations. Having separate stacks per language helps if the language options are themselves translated.

```stack
card LanguageOptions, then: LanguageOptionsError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "languages"]
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
  list_items = map(message.list_items[0], & &1.value.value)

  language =
    list("Languages",
      Language1: "list_items[0]",
      Language2: "list_items[1]",
      Language3: "list_items[2]",
      Language4: "list_items[3]",
      Language5: "list_items[4]",
      Language6: "list_items[5]"
    ) do
      text("@message.message")
    end
end

card LanguageOptionsError, then: LanguageOptionsError do
  language =
    list("Languages",
      Language1: "list_items[0]",
      Language2: "list_items[1]",
      Language3: "list_items[2]",
      Language4: "list_items[3]",
      Language5: "list_items[4]",
      Language6: "list_items[5]"
    ) do
      text("@button_error_text")
    end
end

card Language1, then: LanguageConfirmation do
  # English
  update_contact(language: "en")
end

card Language2, then: LanguageConfirmation do
  # French
  update_contact(language: "fr")
end

card Language3, then: LanguageConfirmation do
  # Portuguese
  update_contact(language: "pt")
end

card Language4, then: LanguageConfirmation do
  # Arabic
  update_contact(language: "ar")
end

card Language5, then: LanguageConfirmation do
  # Spanish
  update_contact(language: "es")
end

card Language6, then: LanguageConfirmation do
  # Chinese
  update_contact(language: "zh")
end

```

## Language Confirmation

Occurances of `{language selection}` in the message are replaced with the user-selected option

```stack
card LanguageConfirmation, then: LanguageConfirmationError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "language_updated"]
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
  message_text = substitute(message.message, "{language selection}", "@language.label")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(OkThanks: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@message_text")
  end
end

card LanguageConfirmationError, then: LanguageConfirmationError do
  buttons(OkThanks: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card OkThanks, then: WelcomeMessage do
  write_result("intro_started", "yes")
end

```

## Privacy policy

This message has the privacy policy as a document attachment

```stack
card PrivacyPolicy, then: PrivacyPolicyError do
  update_contact(onboarding_part_1: "incomplete")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pp_document"]
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

  document =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/documents/@message.document/",
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  document_url = document.body.meta.download_url

  button_labels = map(message.buttons, & &1.value.title)

  buttons(
    AcceptPrivacyPolicy: "@button_labels[0]",
    DeclinePrivacyPolicy: "@button_labels[1]",
    ReadSummary: "@button_labels[2]"
  ) do
    document("@document_url")
    text("@message.message")
  end
end

card PrivacyPolicyError, then: PrivacyPolicyError do
  buttons(
    AcceptPrivacyPolicy: "@button_labels[0]",
    DeclinePrivacyPolicy: "@button_labels[1]",
    ReadSummary: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card AcceptPrivacyPolicy, then: OptIn do
  update_contact(privacy_policy_accepted: "yes")
end

```

## Decline privacy

```stack
card DeclinePrivacyPolicy, then: DeclinePrivacyPolicyError do
  update_contact(privacy_policy_accepted: "no")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pp_not_accepted"]
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

  buttons(SeePrivacyPolicy: "@button_labels[0]") do
    text("@message.message")
  end
end

card SeePrivacyPolicy, then: PrivacyPolicy do
  # Cancel any previous scheduled instance of this stack
  cancel_scheduled_stacks("ce992f8b-49d8-4876-8bfd-a62b6482206d")
  schedule_stack("ce992f8b-49d8-4876-8bfd-a62b6482206d", in: 60 * 60 * 23)
end

card DeclinePrivacyPolicyError, then: DeclinePrivacyPolicyError do
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
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "pp_summary"]
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

  document =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/documents/@message.document/",
      headers: [["Authorization", "Token @config.items.contentrepo_token"]]
    )

  document_url = document.body.meta.download_url

  button_labels = map(message.buttons, & &1.value.title)

  buttons(AcceptPrivacyPolicy: "@button_labels[0]", DeclinePrivacyPolicy: "@button_labels[1]") do
    document("@document_url")
    text("@message.message")
  end
end

card ReadSummaryError, then: ReadSummaryError do
  buttons(AcceptPrivacyPolicy: "@button_labels[0]", DeclinePrivacyPolicy: "@button_labels[1]") do
    text("@button_error_text")
  end
end

```

## Opt In

Opt in for push messages

```stack
card OptIn do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "opt_in"]
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

  buttons(OptInAccept: "@button_labels[0]", OptInDecideLater: "@button_labels[1]") do
    text("@message.message")
  end
end

card OptInAccept, then: UserIntent do
  update_contact(opted_in: "yes")
end

card OptInDecideLater, then: UserIntent do
  update_contact(opted_in: "no")
  # TODO: kick off opt-in reminder flow
end

```

## User intent

Values saved into the `intent` contact field:

* create profile
* explore
* get health advice

```stack
card UserIntent, then: UserIntentError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "intent"]
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

  intent =
    buttons(
      CreateProfile: "@button_labels[0]",
      Explore: "@button_labels[1]",
      SpeakToAgent: "@button_labels[2]"
    ) do
      text("@message.message")
    end
end

card UserIntentError, then: UserIntentError do
  buttons(
    CreateProfile: "@button_labels[0]",
    Explore: "@button_labels[1]",
    SpeakToAgent: "@button_labels[2]"
  ) do
    text("@message.message")
  end
end

card CreateProfile, then: DataPreferences do
  update_contact(intent: "create profile")
end

card Explore, then: DataPreferences do
  update_contact(intent: "explore")
end

card SpeakToAgent do
  update_contact(intent: "get health advice")
  # TODO: Kick off Speak to agent workflow
end

```

## Data Preferences

Options for rich data messages, or pure text messages to save on data costs.

Values saved into data_preference contact field:

* all
* text and images
* text only

```stack
card DataPreferences do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "data_preferences"]
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

  data_preference =
    buttons(
      DataPreferenceAll: "@button_labels[0]",
      DataPreferenceTextAndImages: "@button_labels[1]",
      DataPreferenceTextOnly: "@button_labels[2]"
    ) do
      text("@message.message")
    end
end

card DataPreferenceAll, then: DataPreferencesSelected do
  update_contact(data_preference: "all")
end

card DataPreferenceTextAndImages, then: DataPreferencesSelected do
  update_contact(data_preference: "text and images")
end

card DataPreferenceTextOnly, then: DataPreferencesSelected do
  update_contact(data_preference: "text only")
end

card DataPreferencesSelected do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "data_preferences_yes"]
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
  message_text = substitute(message.message, "{option choice}", "@data_preference.label")
  button_labels = map(message.buttons, & &1.value.title)

  buttons(SelectNextJourney: "@button_labels[0]") do
    text("@message_text")
  end

  write_result("intro_completed", "yes")
end

card SelectNextJourney when intent == "CreateProfile" do
  # TODO: Go to CreateProfile journey
  text("@intent")
end

card SelectNextJourney when intent == "Explore" do
  # TODO: Go to Explore journey
  text("@intent")
end

card SelectNextJourney do
  # TODO: How did we get here and what should we do in this case?
  text("@intent")
end

```

## TODO

Temporary TODO card to route to when we haven't created the destination yet

```stack
card TODO do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["whatsapp", "true"],
        ["slug", "todo"]
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

  text("@page.body.body.text.value.message")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `welcome` , whatsapp message with two buttons
* `languages` , whatsapp message with 6 options.
* `language-updated`, whatsapp message with two buttons, variable `{language selection}` in message content will be replaced with selected language
* `pp_document`, whatsapp message with three buttons, and a document
* `pp_not_accepted`, whatsapp message with two buttons
* `pp_summary`, whatsapp message with two buttons, and a document
* `opt_in`, whatsapp message with two buttons
* `intent`, whatsapp message with 7-item list (hardcoded for now)
* `data_preferences`, whatsapp message with 3 buttons
* `data_preferences_yes`, whatsapp message

## Error messages

* `button-error`, for when a user sends in a message when we're expecting them to press one of the buttons