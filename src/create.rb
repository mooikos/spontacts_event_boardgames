# frozen_string_literal: true

# debugger
require 'pry-byebug'

# environment variables helper
require 'dotenv/load'

# browser automation
require 'selenium-webdriver'

# date/time validation
require 'date'

# Validate that TARGET_DATE is in the future
begin
  target_date_str = ENV.fetch('TARGET_DATE')
  # Parse the date - assuming format like "10/15/2025" (MM/DD/YYYY)
  target_date = Date.strptime(target_date_str, '%m/%d/%Y')
  today = Date.today

  if target_date < today
    puts "❌ ERROR: TARGET_DATE (#{target_date_str}) is in the past!"
    puts "Current date: #{today.strftime('%m/%d/%Y')}"
    puts 'The activity date must be in the future.'
    puts 'Please update TARGET_DATE in your .env file.'
    exit 1
  elsif target_date == today
    puts "⚠️  WARNING: TARGET_DATE (#{target_date_str}) is today."
    puts "Make sure the START_TIME hasn't passed yet."
  else
    puts "✅ Date validation passed: #{target_date_str} is in the future"
  end
rescue KeyError
  puts '❌ ERROR: TARGET_DATE environment variable is not set!'
  puts 'Please set TARGET_DATE in your .env file (format: MM/DD/YYYY)'
  exit 1
rescue Date::Error => e
  puts "❌ ERROR: Invalid date format for TARGET_DATE: #{target_date_str}"
  puts 'Expected format: MM/DD/YYYY (e.g., 10/15/2025)'
  puts "Error: #{e.message}"
  exit 1
end

# Configure Chrome for automation
options = Selenium::WebDriver::Chrome::Options.new

# Speed up page loads significantly
options.page_load_strategy = :eager # Don't wait for images/CSS to fully load

# Optional: Add Chrome arguments for better automation
# options.add_argument('--headless') # Uncomment for headless mode
# options.add_argument('--disable-gpu')
# options.add_argument('--no-sandbox')

# Initialize driver with Chrome
# Selenium 4.6+ automatically downloads and manages ChromeDriver
begin
  driver = Selenium::WebDriver.for(:chrome, options: options)
rescue Selenium::WebDriver::Error::SessionNotCreatedError => e
  puts '❌ Failed to start Chrome browser!'
  puts ''
  puts "Error: #{e.message}"
  puts ''
  puts 'Please make sure Chrome is installed on your system.'
  puts 'Selenium will automatically download the appropriate ChromeDriver.'
  puts ''
  exit 1
end

# Maximize the Chrome window
driver.manage.window.maximize
puts '🔍 Maximized browser window for better element visibility'

# Shorter wait times
wait = Selenium::WebDriver::Wait.new(timeout: 10)
driver.manage.timeouts.page_load = 30

puts '🚀 Starting fast automation (visible mode for debugging)...'

begin
  # AUTOMATION

  ## open login
  puts '📝 Navigating to login...'
  driver.get 'https://community.spontacts.com/login'

  ## accepts terms and conditions
  begin
    terms_and_conditions_selector = 'onetrust-accept-btn-handler'
    wait.until { driver.find_element(id: terms_and_conditions_selector).displayed? }
    # Use JavaScript click to avoid interception issues
    button = driver.find_element(id: terms_and_conditions_selector)
    driver.execute_script('arguments[0].click();', button)
    sleep 2 # Wait for dialog to close completely
    puts '✅ Accepted terms and conditions'
  rescue Selenium::WebDriver::Error::TimeoutError, Selenium::WebDriver::Error::NoSuchElementError
    puts '⚠️  Terms dialog not found (might already be accepted)'
  end

  # Extra wait to ensure any overlay is gone
  sleep 1

  ## perform login
  puts '🔐 Logging in...'
  begin
    email_field_selector = 'loginformlogin-email'
    wait.until { driver.find_element(id: email_field_selector) }
    email = 'maxtru2005@gmail.com'
    driver.find_element(id: 'loginformlogin-email').send_keys(email)
    password = ENV.fetch('SPONTACTS_PASSWORD')
    driver.find_element(id: 'loginformlogin-password').send_keys(password)
    # Use JavaScript click to avoid interception
    login_button = driver.find_element(name: 'login-submit')
    driver.execute_script('arguments[0].click();', login_button)

    # Wait for login to complete - check that we're no longer on the login page
    puts '⏳ Waiting for login to complete...'
    Selenium::WebDriver::Wait.new(timeout: 20).until do
      !driver.current_url.include?('/login')
    end
    puts '✅ Redirected from login page'

    # Additional wait for page to fully load
    sleep 3
    puts '✅ Logged in successfully'
  rescue Selenium::WebDriver::Error::TimeoutError => e
    puts '❌ Login timeout - still on login page after waiting'
    puts "Current URL: #{driver.current_url}"
    puts 'Please check credentials or if login requires additional steps'
    raise
  end

  ## open community page
  puts '🎮 Navigating to community...'
  driver.get 'https://community.spontacts.com/community/spiele'

  # Wait for page to load completely
  puts '⏳ Waiting for community page to load...'
  sleep 2 # Initial wait for page to start loading

  # Wait for page to load - try with longer timeout and fallback
  begin
    Selenium::WebDriver::Wait.new(timeout: 20).until do
      driver.execute_script('return document.readyState') == 'complete'
    end
    puts '✅ Page load complete'

    # Now wait for specific content to appear
    Selenium::WebDriver::Wait.new(timeout: 10).until do
      driver.execute_script("return document.querySelector('[class*=\"online-user-contentbox\"]') !== null")
    end
    puts '✅ Community page loaded'
  rescue Selenium::WebDriver::Error::TimeoutError
    # Fallback: just wait and continue
    puts '⚠️  Community page selector timeout - continuing anyway'
    puts "Current URL: #{driver.current_url}"
    sleep 3
    puts '⚠️  Community page loaded (fallback)'
  end
  sleep 2 # Extra wait for page to fully render

  ## initial activity details
  puts '📅 Creating activity...'
  begin
    # Try to find and click the create activity button using CSS selector
    puts '⏳ Looking for create activity button...'
    wait.until { driver.find_element(css: '[class*="fs-icon-activity"]') }
    create_button = driver.find_element(css: '[class*="fs-icon-activity"]')
    driver.execute_script('arguments[0].click();', create_button)
    puts '✅ Found create activity button'
  rescue Selenium::WebDriver::Error::TimeoutError, Selenium::WebDriver::Error::NoSuchElementError => e
    puts "⚠️  Primary selector failed (#{e.class.name}), trying alternative methods..."
    puts "Current URL: #{driver.current_url}"
    # Try finding any clickable element with text containing "Aktivität"
    sleep 2
    begin
      all_elements = driver.find_elements(xpath: "//*[contains(text(), 'Aktivität') or contains(@title, 'Aktivität') or contains(@aria-label, 'Aktivität')]")
      activity_button = all_elements.find do |elem|
        elem.displayed?
      rescue StandardError
        false
      end
      if activity_button
        driver.execute_script('arguments[0].click();', activity_button)
        puts '✅ Found activity button via text search'
      else
        # Last resort: try finding link with href containing "create" or "new"
        links = driver.find_elements(tag_name: 'a')
        create_link = links.find do |l|
          (l.attribute('href').to_s.include?('create') || l.attribute('href').to_s.include?('new')) && l.displayed?
        rescue StandardError
          false
        end
        if create_link
          driver.execute_script('arguments[0].click();', create_link)
          puts '✅ Found create link'
        else
          puts '❌ Could not find create activity button - please create manually'
          puts 'Available elements on page:'
          driver.find_elements(tag_name: 'button').first(5).each do |b|
            puts "  Button: #{b.text}"
          rescue StandardError
            nil
          end
          sleep 5
        end
      end
    rescue StandardError => e
      puts "❌ Error finding create button: #{e.message}"
      raise
    end
  end
  sleep 1 # Wait for modal/form to appear

  # Wait for and click the second radio checkbox (activity in a group)
  puts '⏳ Waiting for activity type options...'
  wait.until { driver.find_elements(css: '[class*="fs-radio-checkbox"]').length >= 2 }
  radio_buttons = driver.find_elements(css: '[class*="fs-radio-checkbox"]')
  driver.execute_script('arguments[0].click();', radio_buttons[1])
  puts '✅ Selected activity in a group'

  # Fill in activity title
  puts '⏳ Filling activity title...'
  wait.until { driver.find_element(name: 'p::title') }
  activity_title = 'Boardgames in Barmbek North'
  sleep 0.5
  title_field = driver.find_element(name: 'p::title')
  driver.execute_script('arguments[0].focus(); arguments[0].value = arguments[1];', title_field, activity_title)
  puts "✅ Title filled: #{activity_title}"

  # Select community/group from dropdown
  puts '⏳ Selecting community...'
  wait.until { driver.find_element(name: 'group') }
  group_select = driver.find_element(name: 'group')
  # Use JavaScript to set the value and trigger change event
  driver.execute_script(
    "arguments[0].value = '411288'; arguments[0].dispatchEvent(new Event('change', { bubbles: true }));", group_select
  )
  puts '✅ Community selected from dropdown'

  # Submit the form
  puts '⏳ Submitting form...'
  submit_button = driver.find_element(name: 'p::submit')
  driver.execute_script('arguments[0].click();', submit_button)
  puts '✅ Activity details submitted - waiting for next dialog...'

  # Wait for dialog/modal to transition
  sleep 2

  ## other activity details
  puts '⏰ Setting date and time...'
  begin
    # The form might be in a dialog/modal, let's try multiple selectors
    Selenium::WebDriver::Wait.new(timeout: 15).until do
      date_field = begin
        driver.find_element(name: 'view:form:baseForm:appointment-form:timeInfo:startDate:datePanel:date')
      rescue StandardError
        nil
      end
      date_field ||= begin
        driver.find_element(css: 'input[name*="startDate"][name*="date"]')
      rescue StandardError
        nil
      end
      date_field
    end
    puts '✅ Date field found'
  rescue Selenium::WebDriver::Error::TimeoutError
    puts '❌ Timeout waiting for date field'
    puts "Current URL: #{driver.current_url}"

    # Try to see what's on the page
    puts "\n🔍 Debugging - Looking for form fields on page:"
    form_inputs = driver.find_elements(tag_name: 'input')
    puts "Found #{form_inputs.length} input fields"
    form_inputs.first(10).each do |input|
      name = begin
        input.attribute('name')
      rescue StandardError
        'no-name'
      end
      type = begin
        input.attribute('type')
      rescue StandardError
        'no-type'
      end
      visible = begin
        input.displayed?
      rescue StandardError
        false
      end
      puts "  - Input: name=#{name}, type=#{type}, visible=#{visible}" if name&.length&.positive?
    end

    # Check if there's an error message
    error_messages = driver.find_elements(css: '.error, .alert, [class*="error"], [class*="alert"]')
    if error_messages.any?
      puts "\n⚠️  Error messages found on page:"
      error_messages.each do |msg|
        puts "  - #{msg.text}" if msg.displayed?
      rescue StandardError
        nil
      end
    end

    puts "\nThis might mean the form submission failed or requires additional fields"
    raise
  end

  # Set date using Flatpickr
  target_date = ENV.fetch('TARGET_DATE')
  driver.execute_script("document.querySelector('[name=\"view:form:baseForm:appointment-form:timeInfo:startDate:datePanel:date\"]')._flatpickr.setDate('#{target_date}')")
  puts "✅ Date set to #{target_date}"

  # Set start time
  start_time = ENV.fetch('START_TIME')
  time_field = driver.find_element(name: 'view:form:baseForm:appointment-form:timeInfo:startDate:time')
  time_field.clear
  time_field.send_keys(start_time)
  puts "✅ Time set to #{start_time}"

  # Set end date and time (same day as start date for single-day events)
  begin
    # Set end date to same as target date (single-day event)
    driver.execute_script("document.querySelector('[name=\"view:form:baseForm:appointment-form:timeInfo:endDateContainer:endDate:datePanel:date\"]')._flatpickr.setDate('#{target_date}')")
    puts "✅ End date set to #{target_date}"

    # Set end time
    end_time = ENV.fetch('END_TIME', '')
    if end_time.empty?
      puts '⚠️  No end time specified'
    else
      end_time_field = driver.find_element(name: 'view:form:baseForm:appointment-form:timeInfo:endDateContainer:endDate:time')
      end_time_field.clear
      end_time_field.send_keys(end_time)
      puts "✅ End time set to #{end_time}"
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    puts "⚠️  End date/time field not found: #{e.message}"
  end

  # Set description
  puts '📝 Setting description...'
  activity_description = 'Heey everyone 👋,

I am happy to organise a social meeting with center on boardgames.

The time for people to arrive or leave is flexible.
Everyone is welcome to join and bring games.
What will be played will be a shared decision (but lets try to keep it to the simple/medium difficulty "spectrum" 🙂).

The event is free to join.
BUT the location is a bar/brewery/restaurant, so is better to consume something (food or drinks).

I created a whatsapp chat for this activity (inside a general purpose whatsapp Community).
In case you are interested to join it please ask during the event to Organisers/Participants.

Looking forward seeing/meeting you 👋'

  # Chrome WebDriver has issues with emojis (characters outside BMP)
  # Solution: Use placeholders during send_keys, then replace with emojis using JavaScript
  emoji_map = {
    '👋' => '__WAVE_EMOJI__',
    '🙂' => '__SMILE_EMOJI__'
  }
  
  # Replace emojis with placeholders for send_keys
  activity_description_with_placeholders = activity_description.dup
  emoji_map.each { |emoji, placeholder| activity_description_with_placeholders.gsub!(emoji, placeholder) }

  # Set the description using CKEditor5
  begin
    # Wait for the description field
    wait.until { driver.find_element(name: 'view:form:baseForm:appointment-form:description') }
    sleep 0.5

    # Find the visible CKEditor contenteditable div
    editor_div = driver.find_elements(css: '[contenteditable="true"]').find { |e| e.displayed? rescue false }

    if editor_div
      # Scroll element into view and ensure it's clickable (Chrome-compatible)
      driver.execute_script('arguments[0].scrollIntoView({block: "center", behavior: "smooth"});', editor_div)
      sleep 0.5
      
      # Focus the editor using JavaScript (more reliable in Chrome)
      driver.execute_script('arguments[0].focus();', editor_div)
      sleep 0.3

      # Use send_keys with placeholders (this properly updates CKEditor's internal state)
      activity_description_with_placeholders.split("\n").each_with_index do |line, index|
        editor_div.send_keys(line) unless line.empty?
        # Add line break (Enter key) after each line, except the last one
        editor_div.send_keys(:return) if index < activity_description_with_placeholders.split("\n").length - 1
      end

      sleep 0.5
      puts '✅ Description added via CKEditor (send_keys with placeholders)'
      
      # Now replace placeholders with actual emojis using JavaScript
      # And manually sync to the hidden textarea
      replacement_script = <<~JS
        const editor = arguments[0];
        const textarea = arguments[1];
        let html = editor.innerHTML;
        
        // Replace each placeholder with actual emoji in HTML
        html = html.replace(/__WAVE_EMOJI__/g, '👋');
        html = html.replace(/__SMILE_EMOJI__/g, '🙂');
        
        editor.innerHTML = html;
        
        // Also update the textarea by extracting text from HTML
        // Create a temporary div to parse HTML and get text content
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = html;
        textarea.value = tempDiv.innerText || tempDiv.textContent;
        
        // Trigger input events on both elements
        const editorEvent = new Event('input', { bubbles: true, cancelable: true });
        editor.dispatchEvent(editorEvent);
        
        const textareaEvent = new Event('change', { bubbles: true });
        textarea.dispatchEvent(textareaEvent);
        
        return 'emojis-restored-and-synced';
      JS
      
      desc_textarea = driver.find_element(name: 'view:form:baseForm:appointment-form:description')
      result = driver.execute_script(replacement_script, editor_div, desc_textarea)
      sleep 0.5
      puts "✅ Emojis restored (#{result})"
      
      # Verify the emojis are in the textarea
      desc_textarea = driver.find_element(name: 'view:form:baseForm:appointment-form:description')
      textarea_content = driver.execute_script('return arguments[0].value;', desc_textarea)
      
      if textarea_content.include?('👋') || textarea_content.include?('🙂')
        puts '✅ Emojis successfully saved in form data!'
      else
        puts '⚠️  Emojis might not be in textarea - checking editor...'
        editor_content = driver.execute_script('return arguments[0].innerHTML;', editor_div)
        if editor_content.include?('👋') || editor_content.include?('🙂')
          puts '✅ Emojis are in editor HTML - should work'
        else
          puts '⚠️  Warning: Emojis not found in editor or textarea'
        end
      end
    else
      # Fallback: just set the textarea value (won't work with CKEditor but try anyway)
      desc_textarea = driver.find_element(name: 'view:form:baseForm:appointment-form:description')
      driver.execute_script('arguments[0].value = arguments[1];', desc_textarea, activity_description)
      puts '⚠️  Description set via textarea fallback (may not work)'
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    puts "⚠️  Could not set description: #{e.message}"
  end

  # Set location (offline/online)
  puts '📍 Setting location...'
  location_type = ENV.fetch('LOCATION_TYPE', 'offline')
  if location_type == 'offline'
    offline_radio = driver.find_elements(name: 'view:form:baseForm:appointment-form:location:form:online:group')[0]
    driver.execute_script('arguments[0].click();', offline_radio)
    sleep 1
    puts '✅ Selected offline location'

    # Fill in address
    location_address = ENV.fetch('LOCATION_ADDRESS')
    address_field = driver.find_element(name: 'view:form:baseForm:appointment-form:location:form:content:location-select:location:form:address')
    driver.execute_script('arguments[0].scrollIntoView({block: "center"});', address_field)
    sleep 0.3
    driver.execute_script('arguments[0].click();', address_field)
    address_field.send_keys(location_address)
    sleep 2 # Wait for autocomplete suggestions

    # Try to select first suggestion or just press enter
    begin
      # Wait for autocomplete dropdown and select first item
      wait.until { driver.find_elements(css: '.pac-item, .autocomplete-item, [role="option"]').any? }
      first_suggestion = driver.find_elements(css: '.pac-item, .autocomplete-item, [role="option"]').first
      driver.execute_script('arguments[0].click();', first_suggestion) if first_suggestion
      puts '✅ Location address selected from suggestions'
    rescue Selenium::WebDriver::Error::TimeoutError
      # If no suggestions appear, just press enter
      address_field.send_keys(:enter)
      puts '✅ Location address entered'
    end
  else
    online_radio = driver.find_elements(name: 'view:form:baseForm:appointment-form:location:form:online:group')[1]
    driver.execute_script('arguments[0].click();', online_radio)
    puts '✅ Selected online location'
  end

  sleep 1

  # Set participant limits
  puts '👥 Setting participant limits...'
  max_participants = ENV.fetch('MAX_PARTICIPANTS', '')
  unless max_participants.empty?
    begin
      # First, need to expand "Wie willst du die Aktivität organisieren?" section
      organize_section = driver.find_elements(xpath: "//*[contains(text(), 'Wie willst du die Aktivität organisieren')]").first
      if organize_section
        # Scroll to it and click to expand
        driver.execute_script('arguments[0].scrollIntoView(true);', organize_section)
        sleep 0.5
        driver.execute_script('arguments[0].click();', organize_section)
        sleep 1.5 # Wait for section to expand
        puts '✅ Expanded organization section'
      end

      # Make sure "Teilnahme erst nach Bestätigung oder mit Einladung" is NOT checked
      begin
        confirmation_checkbox = driver.find_element(xpath: "//*[contains(text(), 'Teilnahme erst nach Bestätigung') or contains(text(), 'mit Einladung')]//ancestor::label//input[@type='checkbox']")
        if confirmation_checkbox.selected?
          driver.execute_script('arguments[0].click();', confirmation_checkbox)
          puts "✅ Unchecked 'Teilnahme erst nach Bestätigung'"
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        # Checkbox not found or not selected, that's fine
      end

      # Now find "Teilnehmeranzahl limitieren" checkbox
      # Try multiple methods to find it
      limit_checkbox = nil
      begin
        # Try finding by text content
        limit_checkbox = driver.find_element(xpath: "//*[contains(text(), 'Teilnehmeranzahl')]//ancestor::label//input[@type='checkbox']")
      rescue Selenium::WebDriver::Error::NoSuchElementError
        # Try alternative selector
        limit_checkbox = driver.find_element(xpath: "//*[contains(text(), 'limitieren')]//ancestor::label//input[@type='checkbox']")
      end

      if limit_checkbox
        # Scroll into view and click
        driver.execute_script('arguments[0].scrollIntoView(true);', limit_checkbox)
        sleep 0.5
        driver.execute_script('arguments[0].click();', limit_checkbox) unless limit_checkbox.selected?
        sleep 2 # Wait for field to become visible/interactable
        puts '✅ Enabled participant limit'

        # Find and fill max participants field - it should now be visible
        max_fields = driver.find_elements(css: 'input[type="number"]')
        max_field = max_fields.find { |f| f.displayed? && !f.attribute('value').nil? }
        if max_field
          # Use JavaScript to set value to avoid interactability issues
          driver.execute_script("arguments[0].value = '';", max_field)
          driver.execute_script('arguments[0].value = arguments[1];', max_field, max_participants)
          puts "✅ Max participants set to #{max_participants}"
        end

        # Enable waitlist if requested - "Warteliste aktivieren" checkbox
        enable_waitlist = ENV.fetch('ENABLE_WAITLIST', 'false')
        if enable_waitlist == 'true'
          # Find the waitlist checkbox by text
          waitlist_checkbox = driver.find_elements(xpath: "//*[contains(text(), 'Warteliste')]//ancestor::label//input[@type='checkbox']").first
          if waitlist_checkbox
            # Check if it's not already selected
            if waitlist_checkbox.selected?
              puts '✅ Waitlist already enabled'
            else
              driver.execute_script('arguments[0].scrollIntoView(true);', waitlist_checkbox)
              sleep 0.3
              driver.execute_script('arguments[0].click();', waitlist_checkbox)
              puts '✅ Waitlist enabled'
            end
          else
            puts '⚠️  Waitlist checkbox not found'
          end
        end
      else
        puts "⚠️  Could not find 'Teilnehmeranzahl limitieren' checkbox"
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError => e
      puts "⚠️  Could not set participant limits: #{e.message}"
    end
  end

  puts "\n🎉 All fields completed!"

  # Submit the event creation form
  puts '📤 Submitting event creation form...'
  begin
    submit_button = driver.find_element(name: 'buttons:finish')
    driver.execute_script('arguments[0].click();', submit_button)
    puts '⏳ Waiting for event to be created...'
    sleep 5  # Increased wait time for page to process and redirect

    # Wait for the page to actually change (URL should change after submission)
    wait.until do
      driver.execute_script('return document.readyState') == 'complete'
    end
    sleep 2  # Additional wait for any JavaScript to complete

    puts "✅ Event creation form submitted (Current URL: #{driver.current_url})"
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    puts "⚠️  Could not find submit button: #{e.message}"
  end

  # Upload header image
  puts "\n🖼️  Uploading header image..."
  begin
    # Wait for page to fully load after submission
    sleep 3

    # Get image path
    image_path = File.join(Dir.pwd, 'assets', 'fancy_catan.jpg')

    if File.exist?(image_path)
      puts "📁 Image file: #{image_path} (#{File.size(image_path) / 1024}KB)"

      # Wait and find the "Titelbild bearbeiten" link
      wait.until { driver.find_elements(css: '.edit-banner-link').any? }
      edit_banner_link = driver.find_element(css: '.edit-banner-link')
      driver.execute_script('arguments[0].click();', edit_banner_link)
      sleep 2
      puts '✅ Opened image upload dialog'

      # Find file input and upload image
      file_input = driver.find_element(id: 'upload')
      file_input.send_keys(image_path)
      sleep 3
      puts '✅ Image file selected'

      # Check for errors
      errors = driver.find_elements(xpath: "//*[contains(@class, 'error') or contains(text(), 'Fehler')]")
                     .select { |e| e.displayed? rescue false }

      if errors.empty?
        # Click save button
        save_button = driver.find_elements(xpath: "//*[contains(text(), 'Speichern')]")
                           .find { |e| e.displayed? rescue false }
        if save_button
          driver.execute_script('arguments[0].click();', save_button)
          sleep 2
          puts '✅ Header image uploaded successfully'
        else
          puts '⚠️  Save button not found, image may have auto-saved'
        end
      else
        puts "⚠️  Upload error: #{errors.first.text}"
      end
    else
      puts '⚠️  Image file not found, skipping image upload'
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    puts "⚠️  Could not upload image: #{e.message}"
  rescue StandardError => e
    puts "⚠️  Image upload failed: #{e.message}"
  end

  puts "\n✅ Automation complete!"
  puts "📍 Event should now be created with header image"

  # Optional: Keep browser open for review
  binding.pry

ensure
  # Always logout at the end
  begin
    puts "\n🚪 Logging out..."

    # Click on user profile picture to open menu
    user_pic = driver.find_element(css: 'img.user.userpic')
    driver.execute_script('arguments[0].click();', user_pic)
    sleep 1

    # Find and click the "Ausloggen" link
    logout_link = driver.find_elements(tag_name: 'a').find { |l| l.text.strip == 'Ausloggen' }
    if logout_link
      driver.execute_script('arguments[0].click();', logout_link)
      sleep 2
      puts '✅ Logged out successfully'
    else
      puts '⚠️  Logout link not found - trying direct URL'
      driver.get('https://community.spontacts.com/logout')
      sleep 2
    end
  rescue StandardError => e
    puts "⚠️  Could not logout automatically: #{e.message}"
  end

  # Close the browser
  puts '🔒 Closing browser...'
  begin
    driver.quit
  rescue StandardError
    nil
  end
  puts '✅ Browser closed'
end
