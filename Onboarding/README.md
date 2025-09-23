# Onboarding
These flows put together form the MNCH onboarding process. The main purpose of this process is to collect the required information from the user in order to serve them relevant content and interventions.

More in-depth documentation for each of the flows is contained in each of the markdown files for the flows, alongside the stacks implementation of the flow. The documentation should include:
- Contact fields, which contact fields are set or modified in this flow
- Flow results, which flow results are saved during this flow
- Connections to other stacks, which stacks are linked to/run from this stack
- Configuration, and configurable values that apply to the stack, that should be set after import

The stacks are as follows:
- Intro & Welcome: This is the welcome flow, where the user can read and accept the privacy policy, select their language, set their intent, and select their data preferences.
- Exploring Tour: This gives users a basic introduction to the service and allows them to navigate to the Help Desk, or to create a profile (which navigates to the Profile Classifier below).
- Profile Classifier: In this flow the user can select which domains they are interested in. Domains are prioritised so that users who select multiple domains are navigated to the most important succeeding flow, e.g. a user who selects both an interest in pregnancy information and HCW information will be directed to the pregnancy onboarding.
- Profile Pregnancy Health: If the user selects pregnancy information from the Profile Classifier they'll go through this flow. In this flow they will select that they either are pregnant, have a partner who is pregnant or are simply curious. In each case they will be asked relevant questions to that classification (e.g. a curious user won't be asked an EDD), and relevant information will be surfaced based on either the EDD or the trimester. Basic and Personal Profile questions are asked during this flow as well as the LOC assessment.
- Profile Generic: This is the Profile creation flow for any users that are interested in information other than Pregnancy or HCW information.
- HCW Profile: This is the Profile creation flow for Health care workers.
- Basic Questions: A flow asking basic questions like age, gender, province.
- Personal Profile Questions: A flow asking users more personal questions like Relationship status, Education, Socio-economic, and how many children they have.
- Intro & Welcome Reminder: A reminder for potential users to opt in to the Privacy Policy.
- Exploring Tour Reminder: A reminder for curious users to complete their profile.
- EDD Reminder: A reminder for users to fill in their EDD so that we can provide tailored information.
- Opt In Reminder: A reminder for users to opt in to push messages.
- HCW Reminder: A reminder for HCW's to continue completing their profile.


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## Tests

Running the tests requires elixir >= 1.17 (for hexdocs) and the (flow_tester)[https://github.com/praekeltfoundation/flow_tester] to be set up and installed.

You can run the tests using a similar command to:
```
../flow_tester/run_flow_tests.exs Onboarding/QA/tests/
```

### Test Content
The journey tests for HelpCentre and Onboarding use CSV files to import content used in the tests.

The content import files are located in the ./QA/content/ directories for each of the above sections

HelpCentre also uses a `error_messages.csv`, as the journeys all use error messages with slugs starting with `mnch-onboarding-*` for example `mnch_onboarding_error_handling_button`.  We split these out into a smaller csv file so we don't have to import the entire onboarding.csv just for these few error messages.  Ideally we should split the error messages for each section out into their own, for example `mnch_onboarding_error_handling_button` or use another more generic approach.

Onboarding also has two extra files for variation messages, `variations-facts.csv` and `variations-sentiment.csv`, as these pages do not use the same slug prefix as used above, but rather use `mnch-facts` and `mnch-sentiment` respectively

To export the content, go to the Content Pages section of the CMS Admin interface, and search for the prefix `mnch_onboarding_` or `mnch_helpcentre_` respectively.  Select the locale in the right hand panel to filter the results. For now we only export the English content, and have manual fixtures for other language pages where needed. Save the file as csv by clicking the arrow next to `Download XLSX` and select `Download CSV`.

Optionally, I manually clean up the CSV file by deleting a bunch of random dummy / test folders and pages in various languages from the bottom of the file, that is unrelated to this repo's function.

Upload the file to the relevant folder mentioned above, and run the tests to check if everything is in order.


## Managing and editing Journeys
This repo uses the (flow-wrangler)[https://github.com/flow-wrangler/flow-wrangler] CLI tool to manage the Journeys. Please see that repo for instructions on how to set up and use it.

The environment variables that are used for this project are as follows:

`TURN_TOKEN_QA` - This is the "Reach CAPI QA" +27600143703 number in the Praekelt.org organisation

`TURN_TOKEN_PROD` - This is the "My Health By Reach Digital Health" +25420764111 number in the Reach Digital health organisation

`TURN_TOKEN_SMS_QA` - This is the Platform QA SMS *24545 line on the Praekelt.org organisation

`TURN_TOKEN_USSD_QA` - This is the Platform QA USSD *120*4216*25# line on the Praekelt.org organisation

## Gitleaks
When committing the Markdown files, you have to remember to remove any API keys that may be saved in them. Typically we store these in a config dictionary in the Turn globals that for that number. To help with remembering, you can set up Gitleaks in a pre-commit hook.

1. Install [gitleaks](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#installing)
2. In your `.git/hooks` directory make a `pre-commit` file with the following content
```bash
#!/bin/bash

python .git/hooks/gitleaks.py
```
3. Make your gitleaks.py with this ([pilfered from them](https://github.com/gitleaks/gitleaks/blob/master/scripts/pre-commit.py) with slight modification)
```python
#!/usr/bin/env python3
"""Helper script to be used as a pre-commit hook."""
import os
import sys
import subprocess


def gitleaksEnabled():
    """Determine if the pre-commit hook for gitleaks is enabled."""
    out = subprocess.getoutput("git config --bool hooks.gitleaks")
    if out == "false":
        return False
    return True


if gitleaksEnabled():
    exitCode = os.WEXITSTATUS(os.system('gitleaks protect -v --staged -c .git/hooks/gitleaks.toml'))
    if exitCode == 1:
        print('''Warning: gitleaks has detected sensitive information in your changes.
To disable the gitleaks precommit hook run the following command:

    git config hooks.gitleaks false
''')
        sys.exit(1)
else:
    print('gitleaks precommit disabled\
     (enable with `git config hooks.gitleaks true`)')
```
4. Make a gitleaks.toml file, [copy their toml file](https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml) just for good measure, then add this to the bottom. The regex checks for 40 character keys, so placeholders will have to be less than that (Go doesn't support lookaheads, so we can't use a fancier regex to exclude repeating characters).
```
[[rules]]
id = "wagtail-key"
description = "Detected a Wagtail Key, risking unauthorized access to CMS."
regex = '''[a-zA-Z0-9]{40}'''
```
5. Make sure your pre-commit file is executable (`chmod 755 pre-commit`)

## Deploying to Production
1. If there are any new Journeys, add them to the relevant environment's `config.yaml` file. For production, you'll need to create an empty Journey in order to get a UUID for it.
1. Download the latest version of the Journeys from the QA environment. See (how do I download my journeys)[https://github.com/praekeltfoundation/flow-wrangler/?tab=readme-ov-file#how-do-i-download-my-journeys] for more info on how to do this.
1. Run and update the elixir tests
1. If there are changes to QA, create a PR and get approval, and get the QA team to test, before deploying to production
1. Run the relevant (convert command)[https://github.com/praekeltfoundation/flow-wrangler/?tab=readme-ov-file#how-do-i-convert-my-journeys] for the environment. You can find the list of conversions in `wrangler_config.yaml`
1. Create any new Custom Fields that are required.
1. Create a PR and get approval before uploading the Journeys to Production
1. (Upload the Journeys)[https://github.com/praekeltfoundation/flow-wrangler/?tab=readme-ov-file#how-do-i-upload-my-journeys] to Production

## License
[MIT](https://choosealicense.com/licenses/mit/)
