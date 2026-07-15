# Existing project and test assets

The retained project tools deliberately cover existing assets:

- `model_project_inventory` discovers models, libraries, dictionaries, external harness `.slx` files, `.mldatx` files, feature files, and MATLAB scripts. It performs a live filesystem inventory and does not maintain a second cache.
- `model_test_manager_list` inspects suites and cases in an existing `.mldatx` file.
- `model_test_manager_run` executes selected or all native tests and returns the summary plus requested JUnit/PDF artifact paths.

External harness models are normal `.slx` assets and are read or edited with `model_read`, `model_edit`, and `model_check`. Gherkin-based tests and automatic temporary harness generation remain available through `model_test`.

Typical workflow:

```text
model_project_inventory
model_test_manager_list
model_read / model_edit / model_check on an external harness when needed
model_test_manager_run
```
