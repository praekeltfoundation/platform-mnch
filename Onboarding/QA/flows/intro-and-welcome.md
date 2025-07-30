<!-- { section: "fab529b2-584b-46e4-803e-54702ba2a95d", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_any_exact_phrase(event.message.text.body, ["0", "hi"])

```

# Onboarding: Pt 1 - Welcome

This is the first flow that users interact with during onboarding.

If they haven't accepted the terms and conditions, then they'll go through this flow. If they have, then they'll instead go to the main menu.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `language` , this stack allows the user to select their language.
* `privacy_policy_accepted`, this stack sets the privacy policy to `yes` if they accept it or `no` if they don't. The default value for this is blank in the case that they have neither accepted nor declined (i.e. they are a first time user).
* `opted_in`, this stack sets the opt in value to `yes` or `no`
* `intent`, set according to user choice, to one of: `create profile`, `get health advice` or `explore`
* `data_preference`, this stack allows the user to select their data preference and stores one of `all`, `text and images`, `text only`

## Flow results

* `intro_started`, this stack sets this value to `yes` when the intro starts
* `intro_completed`, this stack sets this value to true when the user leaves this stack for any of the above `intent` reasons

## Connections to other stacks

* Onboarding Part 1.1 is scheduled if they don't agree to the privacy privacy_policy_accepted
* Goes to the Explore journey if the select that want to explore the service
* Goes to the Profile Classifier if they select they want to make a Profile
* Goes to the Help desk if they select they want to go to the help desk

## Auth

The token for ContentRepo is stored in a global dictionary.

## Setup

Here we do any setup and fetching of values before we start the flow.

<!-- { section: "152df000-7e2b-4bb7-8a42-7c269f7fb568", x: 0, y: 0} -->

```stack
card FetchError, then: GoToPrivacyPolicy do
  # Fetch and store the error message, so that we don't need to do it for every error card
  log("Starting the Intro & Welcome journey")

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

## Branching

* If they are entering this journey and the privacy policy has not been accepted or declined, we redirect to the privacy policy, otherwise we start from the beginning (this will happen in the case of the reminder stack starting this stack).

* If the privacy policy is accepted, but they  haven't opted in, got to Opt In

* If the privacy policy is accepted and they have opted in, go to the Intent

```stack
card GoToPrivacyPolicy
     when contact.privacy_policy_accepted == "yes" and
            contact.opted_in == false,
     then: OptIn do
  log("Privacy Policy accepted and not opted in, go to Opt In")
end

card GoToPrivacyPolicy
     when contact.privacy_policy_accepted == "yes" and contact.opted_in == true,
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
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_welcome/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  buttons(DefaultLanguageSelection: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@message.text")
  end
end

card WelcomeMessageError, then: WelcomeMessageError do
  buttons(DefaultLanguageSelection: "@button_labels[0]", LanguageOptions: "@button_labels[1]") do
    text("@button_error_text")
  end
end

card DefaultLanguageSelection when len("@contact.language") > 0, then: PrivacyPolicy do
  log("Language already set to @contact.language - continuing.")
end

card DefaultLanguageSelection, then: PrivacyPolicy do
  log("Language not set. Setting to English.")
  update_contact(language: "eng")
end

```

## Language Options

List values are hardcoded for now, since ContentRepo doesn't yet have support for list messages

Each language goes to its own stack, but is all set to English for now, since there aren't any translations. Having separate stacks per language helps if the language options are themselves translated.

```stack
card LanguageOptions, then: LanguageOptionsError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_languages/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  list_items = map(message.list_items, & &1.title)

  language =
    list("Languages",
      Language1: "@list_items[0]",
      Language2: "@list_items[1]",
      Language3: "@list_items[2]",
      Language4: "@list_items[3]",
      Language5: "@list_items[4]",
      Language6: "@list_items[5]"
    ) do
      text("@message.text")
    end
end

card LanguageOptionsError, then: LanguageOptionsError do
  language =
    list("Languages",
      Language1: "@list_items[0]",
      Language2: "@list_items[1]",
      Language3: "@list_items[2]",
      Language4: "@list_items[3]",
      Language5: "@list_items[4]",
      Language6: "@list_items[5]"
    ) do
      text("@list_error_text")
    end
end

card Language1, then: LanguageConfirmation do
  # English
  selected_language = "English"
  update_contact(language: "eng")
end

card Language2, then: LanguageConfirmation do
  # French
  selected_language = "Français"
  update_contact(language: "fra")
end

card Language3, then: LanguageConfirmation do
  # Portuguese
  selected_language = "Português"
  update_contact(language: "por")
end

card Language4, then: LanguageConfirmation do
  # Arabic
  selected_language = "عربي"
  update_contact(language: "ara")
end

card Language5, then: LanguageConfirmation do
  # Spanish
  selected_language = "Español"
  update_contact(language: "spa")
end

card Language6, then: LanguageConfirmation do
  # Chinese
  selected_language = "中国人"
  update_contact(language: "zho")
end

```

## Language Confirmation

Occurances of `{language selection}` in the message are replaced with the user-selected option

```stack
card LanguageConfirmation, then: LanguageConfirmationError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_language_updated/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  message_text = substitute(message.text, "{language selection}", "@selected_language")
  button_labels = map(message.buttons, & &1.title)

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

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_pp_document/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]

  log("@message.document")

  document =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/documents/@message.document/",
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  document_url = document.body.meta.download_url

  button_labels = map(message.buttons, & &1.title)

  buttons(
    AcceptPrivacyPolicy: "@button_labels[0]",
    DeclinePrivacyPolicy: "@button_labels[1]",
    ReadSummary: "@button_labels[2]"
  ) do
    # TODO: When we finally have the document, upload it and make this work
    document("@document_url", filename: "Privacy Policy")
    text("@message.text")
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

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_pp_not_accepted/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]

  button_labels = map(message.buttons, & &1.title)

  buttons(SeePrivacyPolicy: "@button_labels[0]") do
    text("@message.text")
  end
end

card SeePrivacyPolicy, then: PrivacyPolicy do
  # Cancel any previous scheduled instance of this stack
  cancel_scheduled_stacks("8407c748-140f-43fa-b5f4-b5652e07f484")
  schedule_stack("8407c748-140f-43fa-b5f4-b5652e07f484", in: 60 * 60 * 23)
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
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_pp_summary/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]

  # document =
  #   get(
  #     "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/documents/@message.document/",
  #     headers: [["Authorization", "Token @global.config.contentrepo_token"]]
  #   )

  # document_url = document.body.meta.download_url

  button_labels = map(message.buttons, & &1.title)

  buttons(AcceptPrivacyPolicy: "@button_labels[0]", DeclinePrivacyPolicy: "@button_labels[1]") do
    # TODO: When we finally have the document, upload it and make this work
    # document("@document_url")
    text("@message.text")
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
card OptIn, then: OptInError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_opt_in/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  buttons(OptInAccept: "@button_labels[0]", OptInDecideLater: "@button_labels[1]") do
    text("@message.text")
  end
end

card OptInError, then: OptInError do
  buttons(
    OptInAccept: "@button_labels[0]",
    OptInDecideLater: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

card OptInAccept, then: UserIntent do
  log("OptIn Accepted")
  update_contact(opted_in: "true")
  schedule_stack("689e019d-beb5-4ba2-8c04-f4663a67ab81", in: 60 * 60)
end

card OptInDecideLater, then: UserIntent do
  log("OptIn Declined")
  update_contact(opted_in: "false")
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
  update_contact(checkpoint: "intro_welcome")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_intent/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  intent =
    buttons(
      CreateProfile: "@button_labels[0]",
      Explore: "@button_labels[1]",
      SpeakToAgent: "@button_labels[2]"
    ) do
      text("@message.text")
    end
end

card UserIntentError, then: UserIntentError do
  buttons(
    CreateProfile: "@button_labels[0]",
    Explore: "@button_labels[1]",
    SpeakToAgent: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card CreateProfile, then: DataPreferences do
  log("Set intent to create profile")
  update_contact(intent: "create profile")
end

card Explore, then: DataPreferences do
  log("Set intent to explore")
  update_contact(intent: "explore")
end

card SpeakToAgent do
  update_contact(intent: "get health advice")
  run_stack("141a7271-30ec-4b31-83a5-11e4fa655df7")
end

```

## Data Preferences

Options for rich data messages, or pure text messages to save on data costs.

Values saved into data_preference contact field:

* all
* text and images
* text only

```stack
card DataPreferences, then: DataPreferencesError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_data_preferences/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  button_labels = map(message.buttons, & &1.title)

  data_preference =
    buttons(
      DataPreferenceAll: "@button_labels[0]",
      DataPreferenceTextAndImages: "@button_labels[1]",
      DataPreferenceTextOnly: "@button_labels[2]"
    ) do
      text("@message.text")
    end
end

card DataPreferencesError, then: DataPreferencesError do
  buttons(
    DataPreferenceAll: "@button_labels[0]",
    DataPreferenceTextAndImages: "@button_labels[1]",
    DataPreferenceTextOnly: "@button_labels[2]"
  ) do
    text("@button_error_text")
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

card DataPreferencesSelected, then: DataPreferencesSelectedError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_data_preferences_yes/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.messages[0]
  message_text = substitute(message.text, "{option choice}", "@contact.data_preference")
  button_labels = map(message.buttons, & &1.title)

  buttons(SelectNextJourney: "@button_labels[0]") do
    text("@message_text")
  end
end

card DataPreferencesSelectedError, then: DataPreferencesSelectedError do
  buttons(SelectNextJourney: "@button_labels[0]") do
    text("@button_error_text")
  end
end

card SelectNextJourney when contact.intent == "create profile" do
  # Go to Profile Classifier journey
  log("Navigating to Profile Classifier")
  write_result("intro_completed", "yes")
  run_stack("c77efa62-1c9d-4ace-ae7a-4585e4e929d1")
end

card SelectNextJourney when contact.intent == "explore" do
  # Go to Explore journey
  log("Navigating to Explore")
  write_result("intro_completed", "yes")
  run_stack("359b3ff4-796d-4b80-91a6-15532c7bdb90")
end

card SelectNextJourney do
  # TODO: How did we get here and what should we do in this case?
  log("Unknown intent @intent. User stuck.")
  write_result("intro_completed", "yes")
end

```

## TODO

Temporary TODO card to route to when we haven't created the destination yet

```stack
card TODO do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/todo/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  text("@page.body.messages[0].text")
end

```

## Content dependancies

Content is stored in the content repo, and referenced in the stack by slug. This means that we require the following slugs to be present in the contentrepo, and we're making the following assumptions:

* `mnch_onboarding_welcome` , whatsapp message with two buttons
* `mnch_onboarding_languages` , whatsapp message with 6 options.
* `mnch_onboarding_language-updated`, whatsapp message with two buttons, variable `{language selection}` in message content will be replaced with selected language
* `mnch_onboarding_pp_document`, whatsapp message with three buttons, and a document
* `mnch_onboarding_pp_not_accepted`, whatsapp message with two buttons
* `mnch_onboarding_pp_summary`, whatsapp message with two buttons, and a document
* `mnch_onboarding_opt_in`, whatsapp message with two buttons
* `mnch_onboarding_intent`, whatsapp message with 7-item list (hardcoded for now)
* `mnch_onboarding_data_preferences`, whatsapp message with 3 buttons
* `mnch_onboarding_data_preferences_yes`, whatsapp message

## Error messages

* `mnch_onboarding_error_handling_button`, for when a user sends in a message when we're expecting them to press one of the buttons