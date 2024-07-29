<!-- { section: "fab529b2-584b-46e4-803e-54702ba2a95d", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "menu")

```

<!-- { section: "48cd4edc-a82a-4e85-9e69-c4c5f3682f9f", x: 0, y: 0} -->

```stack
card RedirectToMenu when contact.profile_completion == "100%", then: PersonalisedMenu do
  log("Go to personalised menu")
end

card RedirectToMenu, then: NonPersonalisedMenu do
  log("Go to non personalised menu")
end

```

## Personalised Menu

```stack
card PersonalisedMenu do
  run_stack("31bfb947-74a5-4b3b-8dec-def4b7732fd5")
end

```

## Non-Personalised Menu

```stack
card NonPersonalisedMenu do
  run_stack("d02746ff-a3e2-4153-99ff-cd01a941a00d")
end

```