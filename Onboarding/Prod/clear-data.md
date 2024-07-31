<!-- { section: "b6de5111-dd48-43c5-b2e4-ab909ea52d78", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "clear")

```

<!-- { section: "478a00b1-4d78-423b-a5c4-499c26b13591", x: 0, y: 0} -->

```stack
card ClearData do
  # Clear all fields to default value
  text("Clearing data")
  update_contact(year_of_birth: "")
  update_contact(province: "")
  update_contact(area_type: "")
  update_contact(gender: "")
  update_contact(topic: "")
  update_contact(profile_type: "")
  update_contact(checkpoint: "")
  update_contact(privacy_policy_accepted: "")
  update_contact(profile_completion: "")
  update_contact(opted_in: "false")
  update_contact(onboarding_part_1: "")
  update_contact(onboarding_part_2: "")
  update_contact(language: "eng")
  update_contact(occupational_role: "")
  update_contact(facility_type: "")
  update_contact(professional_support: "")
  update_contact(intent: "")
  update_contact(data_preference: "")
  update_contact(name: "")
  update_contact(love_and_relationships: "false")
  update_contact(pregnancy_information: "false")
  update_contact(baby_and_child: "false")
  update_contact(well_being: "false")
  update_contact(family_planning: "false")
  update_contact(info_for_health_professionals: "false")
  update_contact(relationship_status: "")
  update_contact(education: "")
  update_contact(socio_economic: "")
  update_contact(other_children: "")
  update_contact(edd: "")
  update_contact(socio_economic: "")
  update_contact(pregnancy_status: "")
  update_contact(content_completed: "")
  update_contact(pages_seen: "")
  update_contact(pregnancy_sentiment: "")
  update_contact(data_preference: "")
  update_contact(reengagement_message: "")

  # Cancel all scheduled stacks
  cancel_scheduled_stacks("97e8ba1c-5638-4515-bd5d-ca6aca01e7f8")
  cancel_scheduled_stacks("d7cc2c04-5931-4910-9f1e-0cebbb80d1f8")
  cancel_scheduled_stacks("d28a1658-18af-4552-a985-905cf040d50e")
  cancel_scheduled_stacks("78cca41f-d27d-4669-ae16-a785744047a1")

  text("Profile successfully reseted")
end

```