<!-- { section: "eb52f5e9-02f8-415a-a3b2-4547fce463af", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED")
when has_any_exact_phrase(event.message.text.body, ["0", "Menu", "Hi"])

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
  run_stack("e823ad1d-e2d7-4d5c-b928-786b601f0f29")
end

```

## Non-Personalised Menu

```stack
card NonPersonalisedMenu do
  run_stack("c73d7bc1-4b07-44f0-9949-38d2b88f4707")
end

```