# MomConnect Public Registration

This is a light version of the MomConnect public registration. It does not contain the full functionality, but has enough to allow us to run some tests.

## Welcome

Welcome message and then allows the user to proceed with the rest of the registration

<!-- { section: "467e51a4-2ea2-46fd-9470-36c66628f3c2", x: 0, y: 0} -->

```stack
card DecideSubsctipionType do
  then(Welcome)
end

card Welcome do
  welcome =
    ask("""
    Welcome to the Department of Health’s MomConnect. We send free messages to help pregnant moms and babies.

    1. Continue
    """)

  then(WelcomeResponse)
end

card WelcomeResponse when has_any_exact_phrase(welcome, ["1", "1.", "Continue", "1. Continue"]) do
  then(InfoConsent)
end

card WelcomeResponse do
  # Error message for welcome
  welcome =
    ask("""
    Sorry, please reply with the number next to your answer. We send free messages to help pregnant moms and babies.

    1. Continue
    """)

  then(WelcomeResponse)
end

```

## Info content

Gets consent from the user to process their information

```stack
card InfoConsent do
  info_consent =
    ask("""
    MomConnect needs to process your personal info to send you relevant messages about your pregnancy. Do you agree?

    1. Yes
    2. No
    """)

  then(InfoConsentResponse)
end

card InfoConsentResponse when has_any_exact_phrase(info_consent, ["1", "1.", "Yes", "1. Yes"]) do
  then(CreateRegistration)
end

card InfoConsentResponse when has_any_exact_phrase(info_consent, ["2", "2.", "No", "2. No"]) do
  then(InfoConsentDenied)
end

card InfoConsentResponse do
  # Error message for info consent
  info_consent =
    ask("""
    Sorry, please reply with the number next to your answer. Do you agree?

    1. Yes
    2. No
    3. I need more info to decide
    """)

  then(InfoConsentResponse)
end

```

## Info consent denied

If the user doesn't consent to us processing their info, we cannot proceed. Allow them to still consent if they change their mind

```stack
card InfoConsentDenied do
  info_consent =
    ask("""
    Unfortunately, without agreeing we can't send MomConnect to you. Do you agree to MomConnect processing your personal info?

    1. Yes
    2. No
    """)

  then(InfoConsentDeniedResponse)
end

card InfoConsentDeniedResponse
     when has_any_exact_phrase(info_consent, ["1", "1.", "Yes", "1. Yes"]) do
  then(CreateRegistration)
end

card InfoConsentDeniedResponse
     when has_any_exact_phrase(info_consent, ["2", "2.", "No", "2. No"]) do
  then(Exit)
end

card InfoConsentDeniedResponse do
  info_consent =
    ask("""
    Sorry, please reply with the number next to your answer. Unfortunately without your consent, you can't register to MomConnect.

    1. Yes
    2. No
    """)

  then(InfoConsentDeniedResponse)
end

```

## Create registration

Here is where we do what we need to sign the user up to public messages.

TODO: Test sending a WhatsApp template or SMS here

```stack
card CreateRegistration do
  response =
    post("https://whatsapp.turn.io/v1/stacks/a82040e2-874d-4621-ba0c-1a0de8189b83/start",
      timeout: 5_000,
      cache_ttl: 0,
      body: """
      {"wa_id": "@contact.whatsapp_id"}
      """,
      headers: [
        ["authorization", "Bearer @global.config.turn_token"],
        ["content-type", "application/json"]
      ]
    )

  log("@response")
  then(RegistrationComplete)
end

```

## Registration complete

Send a message to the user letting them know that registration is complete and successful

```stack
card RegistrationComplete do
  text("""
  You're done! This number @contact.whatsapp_id will get helpful messages from MomConnect. For the full set of messages, visit a clinic.
  """)
end

```

## Exit

If the user doesn't want to consent, then we have to end the interaction

```stack
card Exit do
  text("""
  Thank you for considering MomConnect. We respect your decision. Have a lovely day.
  """)
end

```