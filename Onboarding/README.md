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

Running the tests requires elixir >= 1.17 (for Date.shift)

## Opening Journey as Markdown
You can open a Turn Journey as a markdown file by taking the url, removing `/app` and appending `?format=md`. A one click solution is to add the following code as a bookmark

```
javascript:var%20winURL%20=%20window.location.href;if(winURL.indexOf('/app')%20%3E%200)%7BwinURL%20=%20winURL.replace('/app',%20'') + '?format=md';window.location.assign(winURL);%7Delse%7Balert('Incorrect%20URL%20format');%7D
```

## Gitleaks
When committing the Markdown files, you have to remember to remove any API keys that may be saved in them. Typically we store these in a config dictionary at the top of a Journey so that we can use it throughout. To help with remembering, you can set up Gitleaks in a pre-commit hook.

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
1. `poetry install`
1. Download the latest version of the Journeys from the QA environment. See `Opening Journey as Markdown` above for more info on how to do this. 
1. Make a new Journey on the Production environment for each Journey that you want to deploy. DO NOT MODIFY THE JOURNEY YET.
1. Add the Journey with the QA and Prod UUID to `stacks_config.yaml` e.g.
    ```yaml
      - name: Onboarding
        prod_uuid: 1d791269-d1a1-49f8-8947-dab61f3e3cb9
        qa_uuid: 7dad867e-b140-4d38-a3b4-c4ad98525d4d
    ``` 
1. Run `python3 convert_qa_files_to_prod.py` to create all the necessary Prod files and update any new changes to existing Prod files.
1. Run `yamllint .` to ensure the YAML file is correctly formatted.
1. Run `pytest` to ensure that all files have been successfully created and the stacks files line up correctly with the `stacks_config.yaml` file.
1. Create a PR for review.
1. Create any new Custom Fields that are required.
1. Copy the Prod file/s to the Prod enviroment.

## License
[MIT](https://choosealicense.com/licenses/mit/)
