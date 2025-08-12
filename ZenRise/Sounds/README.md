# Sound Files for ZenRise

This folder contains the alarm sound files for the ZenRise app.

## Required Sound Files

Add the following MP3 files to this folder:

1. **default_alarm.mp3** - Default alarm sound
2. **gentle_chime.mp3** - Gentle chime sound
3. **morning_birds.mp3** - Nature sounds with birds
4. **upbeat_alarm.mp3** - Energetic wake-up sound
5. **classic_bell.mp3** - Traditional bell sound

## Sound File Requirements

- **Format**: MP3
- **Duration**: 10-30 seconds recommended
- **Quality**: 128-320 kbps
- **Size**: Keep under 2MB per file for optimal performance

## Where to Find Sound Files

You can find free alarm sounds from:
- [Freesound.org](https://freesound.org/)
- [Zapsplat](https://www.zapsplat.com/)
- [SoundBible](http://soundbible.com/)
- [BBC Sound Effects](https://sound-effects.bbcrewind.co.uk/)

## Adding Sounds to Xcode

1. Drag and drop the MP3 files into this folder
2. In Xcode, right-click on the ZenRise project
3. Select "Add Files to ZenRise"
4. Choose the sound files from this folder
5. Make sure "Add to target" is checked for your app target
6. Click "Add"

## Testing Sounds

You can test the sounds in the Settings view by:
1. Going to Settings tab
2. Enabling the alarm
3. Tapping the play button next to each sound option

## Notes

- Sound files are automatically included in the app bundle
- The app will fall back to the system default sound if a file is missing
- Make sure you have the rights to use any sound files you include
