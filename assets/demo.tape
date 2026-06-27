# VHS Tape file to generate orbital simulation GIF
Output assets/orbital_simulation.gif

Set FontSize 14
Set FontFamily "DejaVu Sans Mono"
Set Width 1100
Set Height 450
Set Padding 10
Set Theme "Dracula"
Set PlaybackSpeed 2.0

# Start the simulation
Type "./phi-anim orbit"
Enter

# Let it run for 15 seconds
Sleep 40s

# Press 'q' to quit cleanly
Type "q"
Type "q"

# Wait a brief moment to complete the capture
Sleep 1s
