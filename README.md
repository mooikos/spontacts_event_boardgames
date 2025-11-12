# project spontacts automation

aims at automatically create from a template a spontacts entry

## setup

### Safari Driver Setup

This project uses Safari WebDriver. To enable Safari for automation:

1. **Enable safaridriver** (requires password):
   ```bash
   sudo safaridriver --enable
   ```
   Or run the helper script:
   ```bash
   ./scripts/enable_safari.sh
   ```

2. **Enable Remote Automation in Safari**:
   - Open Safari
   - If you don't see "Develop" in the menu bar:
     - Go to Safari > Settings/Preferences (⌘,)
     - Click "Advanced" tab
     - Check "☑ Show Develop menu in menu bar"
     - Close Settings
   - In Safari's menu bar, click: **Develop > Allow Remote Automation**

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Login credentials
SPONTACTS_PASSWORD=your_password

# Event details (single-day events)
TARGET_DATE=10/29/2025  # Format: MM/DD/YYYY (must be in the future)
START_TIME=18:30        # Format: HH:MM
END_TIME=22:30          # Format: HH:MM (same day as TARGET_DATE)
```

**Note:** The script is designed for single-day events. The end date is automatically set to the same day as `TARGET_DATE`.

## usage

- **`bundle exec ruby src/create.rb`**

The script will:
1. Validate the date is in the future
2. Login to Spontacts
3. Create a new event with all details
4. Upload the header image (`assets/fancy_catan.jpg`)
5. Logout and close the browser

## language template

```
We are an English language meetup and the main language at all of our meetups is English. So if you only speak English, you're absolutely in the right group. About half of our members are native speakers of German or speak German well enough to play board games in German, so it might happen that there's a table where everyone speaks German and they agree to speak German while playing. However, we cannot guarantee this happens.
```

```
Just start with the event in a german group … my Idea is to have you own place to start events and where people could join the group … but even If you start the meetup in on german group even people outside that group would see it … the reach is connected to the community
```
