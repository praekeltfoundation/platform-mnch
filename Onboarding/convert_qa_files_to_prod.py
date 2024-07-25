from uuid import UUID
from dataclasses import dataclass

from utils import get_sorted_filenames_with_extension, get_stacks_uuids

QA_DIR = "./QA/"
PROD_DIR = "./Prod/"


def is_valid_uuid(uuid_str: str):
    try:
        UUID(uuid_str)
        return True
    except ValueError:
        return False


def get_stacks_with_no_prod_uuid(stack_uuids):
    return sorted(
        [
            stack["name"]
            for stack in stack_uuids
            if not is_valid_uuid(stack["prod_uuid"])
        ]
    )


@dataclass
class Config:
    stack_uuids: dict[str, dict]
    qa_dir: str
    prod_dir: str


class StackEnvironmentConverter:
    def __init__(self, path, config) -> None:
        self.qa_path = f"{config.qa_dir}{path}"
        self.qa_str = self.get_qa_file_as_str()
        self.prod_str = self.qa_str
        self.prod_path = f"{config.prod_dir}{path}"
        self.qa_to_prod(config.stack_uuids)

    def get_qa_file_as_str(self):
        with open(f"{self.qa_path}", "r") as file:
            file_str = file.read()
            file.close()
        return file_str

    def replace_uuids(self, stack_uuids):
        for stack in stack_uuids:
            self.prod_str = self.prod_str.replace(
                str(stack["qa_uuid"]), str(stack["prod_uuid"])
            )

    def qa_to_prod(self, stack_uuids):
        self.prod_str = self.prod_str.replace('["qa", "true"]', '["qa", "false"]')
        self.replace_uuids(stack_uuids)

    def export_prod(self):
        with open(self.prod_path, "w") as file:
            file.write(self.prod_str)
        file.close()


if __name__ == "__main__":
    all_filenames = get_sorted_filenames_with_extension("qa")
    stack_uuids = get_stacks_uuids()
    config = Config(stack_uuids, QA_DIR, PROD_DIR)
    for qa_file in all_filenames:
        StackEnvironmentConverter(path=qa_file, config=config).export_prod()
    stack_not_in_prod = get_stacks_with_no_prod_uuid(stack_uuids)

    if not stack_not_in_prod:
        print("There are currently no stacks missing in prod")
    else:
        print(
            f"\nThe following stacks need prod UUIDs and will need to be deployed: \n\t{chr(8226)} {f'{chr(10)}{chr(9)}{chr(8226)} '.join(stack_not_in_prod)}"
        )
