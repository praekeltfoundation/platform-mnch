<!-- { section: "4aa07183-5f40-416e-a47d-34f3ddeaec44", x: 0, y: 0} -->

```stack
trigger(interval: "+1m", relative_to: "contact.public_registration_date")
trigger(interval: "+2m", relative_to: "contact.public_registration_date")
trigger(interval: "+3m", relative_to: "contact.public_registration_date")

card DecideMessage when now() < datetime_add(contact.public_registration_date, 2, "m") do
  then(FirstMessage)
end

card DecideMessage when now() < datetime_add(contact.public_registration_date, 2, "m") do
  then(SecondMessage)
end

card DecideMessage do
  then(SecondMessage)
end

card FirstMessage do
  text("""
  Congratulations on your pregnancy. You will now get free messages about MomConnect. You can register for the full set of FREE helpful messages at a clinic.
  """)
end

card SecondMessage do
  text("""
  If you are HIV+, your baby can be born HIV-. Learn more about HIV and pregnancy by registering for free messages at any clinic.
  """)
end

card ThirdMessage do
  text("""
  High blood pressure can be dangerous for you and your baby. Find out more about chronic illness in pregnancy by registering with MomConnect at a clinic.
  """)
end

```