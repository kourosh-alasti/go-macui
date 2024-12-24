# How to Contribute
### 1. Reporting Bugs
- Check the issues to ensure the bug hasn’t already been reported.
- If it hasn’t, create a new issue with the following:
-- Title: A brief description of the bug.
-- Description: Detailed steps to reproduce the issue.
-- Expected Behavior: What you expected to happen.
-- Actual Behavior: What actually happened.
### 2. Requesting Features
- Open a new issue labeled as `feature request`.
- Provide a clear explanation of the feature and its benefits.
### 3. Submitting Code Changes
**Fork the Repository**
- Fork the project repository to your GitHub account.
**Clone Your Fork**
```bash
git clone https://github.com/your-username/your-repo.git
```
**Create a New Branch**
- Use a descriptive branch name:
```bash
git checkout -b feature/your-feature-name
```
**Make Your Changes**
- Follow the project's coding standards.
- Add or update tests where applicable.
**Test Your Changes**
- Ensure all tests pass before submitting a pull request:
```bash
go test ./...
```
**Commit Your Changes**
- Write clear and concise commit messages:
```bash
git commit -m "Add feature: description of the feature"
``` 
**Push Your Changes**
```bash
git push origin feature/your-feature-name
```
**Open a Pull Request**
- Go to the original repository.
- Click the Pull Request button.
- Provide a detailed description of your changes.

### Code Guidelines
- Code Style: Adhere to Go conventions and the Effective Go guidelines.
- Formatting: Use `gofmt` to format your code before committing.
- Documentation: Document your code where necessary, especially for exported functions and types.

### Communication
- Join the discussions on the GitHub Discussions page.
- Use clear and respectful language in all interactions.

### Thank You!
Your contributions make this project better for everyone. 😊

