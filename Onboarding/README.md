# Onboarding
These flows put together form the MNCH onboarding process. The main purpose of this process is to collect the required information from the user in order to serve them relevant content and interventions.

More in-depth documentation for each of the flows is contained in each of the markdown files for the flows, alongside the stacks implementation of the flow. The documentation should include:
- Contact fields, which contact fields are set or modified in this flow
- Flow results, which flow results are saved during this flow
- Connections to other stacks, which stacks are linked to/run from this stack
- Configuration, and configurable values that apply to the stack, that should be set after import

The stacks are as follows:
- Onboarding Part 1. This is the welcome flow, where the user can read and accept the privacy policy, select their language, set their intent, and their relation to the child/ren.
- Onboarding Part 2. If the user is pregnant, then they go through this flow. It captures their estimated due date.
- Onboarding Part 3. This captures information about the user, namely their sentiment, location, relationship status, year of birth, education level, socioeconomic status, and social support.
- Onboarding Part 4. If the user has any children under their care, we collect the details for all those children in this flow. For each child we collect the child's name and date of birth.
- Reminders Schedule Message 1. This schedules the first reminder message to be sent.
- Reminders Send Message 1. This is the callback that gets triggered for when it's time to send the first reminder message. It sends the message.
- Stage Based Messaging Schedule Pregnancy. This gets called to schedule all the messaging for the mother's pregnancy, relative to the estimated due date captured.
- Stage Based Messaging Send Pregnancy Message. This gets called when it's time to send a pregnancy message. It figures out which message should be sent by looking at the current date, and the estimated due date on the contact profile. It then compares this to what is present in the content repo, and selects the correct message to send to the user.


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
