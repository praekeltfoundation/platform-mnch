import yaml
import pathlib

ROOT = pathlib.Path()


def load_config(path=ROOT / "stacks_config.yaml"):
    with open(path) as file:
        stacks_config = yaml.safe_load(file.read())
        file.close()
    return stacks_config


def get_stacks_uuids(stacks_config=None):
    if not stacks_config:
        stacks_config = load_config()
    return stacks_config["stack_uuids"]

def get_urls(stacks_config=None):
    if not stacks_config:
        stacks_config = load_config()
    return stacks_config["qa_url"], stacks_config["prod_url"]

def get_sorted_filenames_with_extension(env: str):
    match env.lower():
        case "prod":
            folder = "Prod"
        case "qa":
            folder = "QA"
        case "test":
            folder = "test_resources/QA"
    path = ROOT / folder

    files = list(path.iterdir())
    files.sort()
    return [file_name.name for file_name in files]
