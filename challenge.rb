# frozen_string_literal: true

# Place this file in the same directory as users.json and companies.json
# WARNING: If there is already a file in the directory called "output.txt", it will be overwritten!

require 'json'

EXPECTED_USER_FIELDS = {
  'id' => Integer,
  'company_id' => Integer,
  'first_name' => String,
  'last_name' => String,
  'email' => String,
  'tokens' => Integer,
  'active_status' => [TrueClass, FalseClass],
  'email_status' => [TrueClass, FalseClass]
}.freeze

EXPECTED_COMPANY_FIELDS = {
  'id' => Integer,
  'name' => String,
  'top_up' => Integer,
  'email_status' => [TrueClass, FalseClass]
}.freeze

# Method to load JSON data from a file with error handling
def load_json_file(file_path)
  JSON.parse(File.read(file_path))
rescue Errno::ENOENT
  puts "Error: File '#{file_path}' not found.\nCannot proceed without complete input data.\nAborting!"
  exit
rescue JSON::ParserError
  puts "Error: Failed to parse JSON file '#{file_path}'.\nCannot proceed without complete input data.\nAborting!"
  exit
end

# Method to verify data of an object and log if there is an error
def verify_object_data(object, expected_object_fields, object_name)
  return_value = true
  object_id = object['id'] || 'unknown'
  log_file = File.open('verification_log.txt', 'a') # 'a' for append mode

  # Timestamp for the log entry
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  # Iterate object fields
  expected_object_fields.each do |field, expected_type|
    # Is the field missing?
    unless object.key?(field)
      warning = "Warning: #{object_name} (ID: #{object_id}) missing field '#{field}'.  Skipping..."
      puts warning
      log_file.puts "[#{timestamp}] #{warning}"
      return_value = false
    end

    actual_type = object[field].class
    valid_type = expected_type.is_a?(Array) ? expected_type.include?(actual_type) : actual_type == expected_type

    # Is the field of valid type?
    next if valid_type

    warning = "Warning: #{object_name} (ID: #{object_id}) field '#{field}' has invalid type '#{actual_type}' (expected '#{expected_type}').  Skipping..."
    puts warning
    log_file.puts "[#{timestamp}] #{warning}"
    return_value = false
  end

  log_file.close # Close the log file
  return_value
end

# Define a method to process user top-ups for a given company
def process_user_top_ups(company, users_in_company)
  users_emailed = ["\tUsers Emailed:"]
  users_not_emailed = ["\tUsers Not Emailed:"]

  users_in_company.each do |user|
    previous_token_balance = user['tokens']
    user['tokens'] += company['top_up']
    user_output_text = user_top_up_summary(user, previous_token_balance)

    if user['email_status'] && company['email_status']
      send_top_up_email_to_user(user)
      users_emailed << user_output_text
    else
      users_not_emailed << user_output_text
    end
  end

  [users_emailed, users_not_emailed]
end

# Method to process user top ups for a company and return a summary
def process_company_top_ups(company, valid_users)
  users_in_company = valid_users.select { |user| user['company_id'] == company['id'] && user['active_status'] == true }

  # Only proceed if the company has any valid and active users to top up
  return [] unless users_in_company.any?

  users_in_company.sort_by! { |user| user['last_name'] }
  company_top_up_summary = [company_top_up_summary_header(company)]

  # Process user top-ups and get the results
  users_emailed, users_not_emailed = process_user_top_ups(company, users_in_company)

  company_top_up_summary << users_emailed
  company_top_up_summary << users_not_emailed

  # Calculate total top ups for company.  Subtract 2 to exclude header lines
  top_up_total = company['top_up'] * (users_emailed.size + users_not_emailed.size - 2)
  company_top_up_summary << company_top_up_summary_footer(company, top_up_total)

  company_top_up_summary
end

# Method to email the user
def send_top_up_email_to_user(user)
  # TODO: Implement an email solution if this were real and not a code challenge.
end

# Method to construct the header for a company's output
def company_top_up_summary_header(company)
  <<~INFO.chomp
    \n\tCompany Id: #{company['id']}
    \tCompany Name: #{company['name']}
  INFO
end

# Method to construct formatted info about a user who was topped up
def user_top_up_summary(user, previous_token_balance)
  <<~INFO.chomp
    \t\t#{user['last_name']}, #{user['first_name']}, #{user['email']}
    \t\t  Previous Token Balance, #{previous_token_balance}
    \t\t  New Token Balance #{user['tokens']}
  INFO
end

# Method to construct a summary about a company's top ups
def company_top_up_summary_footer(company, top_up_total)
  <<~INFO.chomp
    \t\tTotal amount of top ups for #{company['name']}: #{top_up_total}
  INFO
end

# Load the JSON data
json_companies = load_json_file('companies.json')
json_users = load_json_file('users.json')

# Verify data of companies
valid_companies, invalid_companies = json_companies.partition do |company|
  verify_object_data(company, EXPECTED_COMPANY_FIELDS, 'Company')
end

# Verify companies do not have duplicate ids, and move those that do into invalid_companies
grouped_companies = valid_companies.group_by { |company| company['id'] }

grouped_companies.each do |_id, companies|
  next unless companies.length > 1

  # Move companies with duplicate IDs to invalid_companies
  invalid_companies.concat(companies)
  log_file = File.open('verification_log.txt', 'a') # 'a' for append mode

  # Timestamp for the log entry
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  companies.each do |company|
    valid_companies.delete(company)
    warning = "Warning: Company #{company['name']} (ID: #{company['id']}) is a duplicate ID.  Skipping..."
    puts warning
    log_file.puts "[#{timestamp}] #{warning}"
  end

  log_file.close # Close the log file
end

# Sort valid_companies by company id
valid_companies.sort_by! { |company| company['id'] }

# Verify data of users
valid_users, invalid_users = json_users.partition do |user|
  verify_object_data(user, EXPECTED_USER_FIELDS, 'User')
end

# Open the output file in write mode
File.open('output.txt', 'w') do |file|
  # Iterate through each valid company, do top ups, and construct output
  valid_companies.each do |company|
    # Write the company result to the file
    file.puts process_company_top_ups(company, valid_users).flatten
  end

  file.puts ''
end

puts 'output.txt generated successfully!'

# Write the invalid_companies array to a JSON file
if invalid_companies.any?
  puts 'There are companies with bad format, generating a list of bad companies in invalid_companies.json'
  puts 'Check verification_log.txt for details'

  File.open('invalid_companies.json', 'w') do |file|
    file.write(JSON.pretty_generate(invalid_companies))
  end
end

# Write the invalid_users array to a JSON file
if invalid_users.any?
  puts 'There are users with bad format, generating a list of bad users in invalid_users.json'
  puts 'Check verification_log.txt for details'

  File.open('invalid_users.json', 'w') do |file|
    file.write(JSON.pretty_generate(invalid_users))
  end
end
