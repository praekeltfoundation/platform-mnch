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

## License
[MIT](https://choosealicense.com/licenses/mit/)
