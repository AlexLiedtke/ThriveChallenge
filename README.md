# ThriveChallenge
Repository for a code challenge completed for Thrive.

## How to Use This Code
1. Place `challenge.rb` in the same directory as `users.json` and `companies.json`.
2. Open your terminal and type `ruby challenge.rb`.
3. Ensure Ruby is installed on your system. If not, install it following the instructions for your operating system.

**WARNING:** If there is already a file named "output.txt" in the directory, it will be overwritten!

## What Happens When You Run This Code
### Case Scenarios:
- **Case 1: Missing JSON Files**
  - Error message will display in the terminal.
  - The program will abort until `users.json` and `companies.json` are provided.

- **Case 2: JSON Parsing Issues**
  - Error message will show if `users.json` or `companies.json` cannot be parsed.
  - The program will abort until valid JSON files are provided.

- **Case 3: Missing Fields or Incorrect Data Types in the JSON**
  - Error messages will log missing fields or invalid data types in `verification_log.txt`.
  - The program will skip objects with errors and proceed to generate `output.txt` with the remaining valid data.

- **Case 4: Duplicate Company IDs**
  - Companies with duplicate IDs will be moved to `invalid_companies.json`.
  - `output.txt` will still generate successfully with the remaining valid data.
 
- **Case 5: Everything works!**
  - `output.txt` will generate, there will be no terminal warnings, and none of the log files will be updated!

### Other Notes:
- Valid/Invalid are terms used here to denote whether data is in a state for the program to use it with full functionality for a "top up".

- If a valid company has no valid active users, it's section will be disregarded from `output.txt`

- The `send_top_up_email_to_user` method is a TODO stub to represent email functionality.
  - Modify or implement this method according to your email service requirements.

- Extra log and JSON files (`verification_log.txt`, `invalid_companies.json`, `invalid_users.json`) document bad data for debugging or improvement purposes.
