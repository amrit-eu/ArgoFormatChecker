import pytest
from argofilechecker_python_wrapper import FileChecker

@pytest.fixture
def env_paths(tmp_path, monkeypatch):
    """create a mock JAR file and specs dir and add it to env variables"""
    jar = tmp_path / "app.jar"
    jar.touch()  # simulate jar existence
    specs = tmp_path / "specs"
    specs.mkdir()

    monkeypatch.setenv("FILE_CHECKER_JAR", str(jar))
    monkeypatch.setenv("FILE_CHECKER_SPECS", str(specs))
    return jar, specs

def test_check_files_empty_input_files_list(env_paths) :
    fileChecker = FileChecker()

    with pytest.raises(ValueError):
        fileChecker.check_files([], "coriolis")


def test_check_files_all_missing_raise(env_paths):
    fileChecker = FileChecker()

    with pytest.raises(FileNotFoundError):
        fileChecker.check_files(["NOEXISTS.nc"], "coriolis")