from utils import get_sorted_filenames_with_extension, get_stacks_uuids


def get_sorted_list_stacks_in_config():
    stacks_uuids = get_stacks_uuids()
    return sorted([stack["name"] for stack in stacks_uuids])


def get_sorted_filenames_without_extension(env: str):
    files = get_sorted_filenames_with_extension(env)
    return [file_name.replace(".txt", "") for file_name in files]


def get_list_duplicates(list):
    seen = set()
    return [x for x in list if x in seen or seen.add(x)]


def get_list_differences(list_1, list_2):
    longer_list = max([list_1, list_2], key=len)
    shorter_list = min([list_1, list_2], key=len)
    return [x for x in shorter_list if x not in longer_list]


def test_prod_and_qa_dir_same():
    """Prod and QA have the same files"""
    prod = get_sorted_filenames_without_extension("prod")
    qa = get_sorted_filenames_without_extension("qa")
    difference = get_list_differences(prod, qa)

    assert len(prod) == len(qa)
    assert difference == []


def test_all_qa_files_listed_in_config():
    """All files in the QA dir are listed in stacks_config.yaml"""
    stacks_names = get_sorted_list_stacks_in_config()
    qa = get_sorted_filenames_without_extension("qa")
    difference = get_list_differences(stacks_names, qa)

    assert len(qa) == len(stacks_names)
    assert difference == []


def test_all_prod_files_listed_in_config():
    """All files in the Prod dir are listed in stacks_config.yaml"""
    stacks_names = get_sorted_list_stacks_in_config()
    prod = get_sorted_filenames_without_extension("prod")
    difference = get_list_differences(stacks_names, prod)

    assert len(prod) == len(stacks_names)
    assert difference == []


def test_no_duplicate_stacks_in_config():
    """All stacks listed once in config"""
    stacks_names = get_sorted_list_stacks_in_config()

    duplicate_names = get_list_duplicates(stacks_names)

    assert duplicate_names == []
