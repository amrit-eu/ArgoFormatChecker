import os
from typing import List
from argofilechecker_python_wrapper import FileChecker, ValidationResult
from argofilechecker_python_wrapper.models import ResultType

jar_path ="./file_checker_exec-2.9.3-SNAPSHOT.jar"
spec_path = "./file_checker_spec"


# 1) Instantiate the wrapper (explicit paths)
fileChecker = FileChecker(jar_path, spec_path)
# You can also instantiate the checker without arguments if your environment variables are set:
# file_checker = FileChecker()  # reads FILE_CHECKER_JAR / FILE_CHECKER_SPECS

# 2) Validate a list of files from the same DAC
list_files = [f'./test_data/2903996/{file}' for file in os.listdir('./test_data/2903996')]
validation_results:List[ValidationResult] = fileChecker.check_files(list_files,"coriolis" )

# 3) Iterate over the results
for file_result in validation_results :

    print (file_result.to_string())

    if (file_result.result == ResultType.FAILURE or file_result.result == ResultType.ERROR ):
        print(*file_result.errors_messages)
        print(*file_result.warnings_messages)
