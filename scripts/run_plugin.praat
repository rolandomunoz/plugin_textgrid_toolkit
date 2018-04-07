# Open one by one, all the audio files and their TextGrids in the specified directory
# If the TextGrid does not exist, then create a new one
#
# Written by Rolando Muñoz A. (28 March 2018)
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# A copy of the GNU General Public License is available at
# <http://www.gnu.org/licenses/>.
#
include ../procedures/config.proc

@config.init: "../preferences.txt"

beginPause: "Annotation assistant"
  comment: "The directories where your files are stored..."
  sentence: "Audio folder", config.init.return$["audio_dir"]
  sentence: "Textgrid folder", config.init.return$["textgrid_dir"]
  comment: "Create tiers..."
  sentence: "All tier names", config.init.return$["all_tier_names"]
  sentence: "Which of these are point tiers", config.init.return$["point_tiers"]
  comment: "Settings..."
  optionMenu: "Show", number(config.init.return$["show"])
    option: "New cases"
    option: "Done cases"
    option: "All cases"
  boolean: "Search inside TextGrids", number(config.init.return$["deep_search"])
clicked = endPause: "Cancel", "Apply", "Ok", 3

if clicked = 1
  exitScript()
endif

# remember option values
@config.setField: "audio_dir", audio_folder$
@config.setField: "textgrid_dir", textgrid_folder$
@config.setField: "all_tier_names", all_tier_names$
@config.setField: "point_tiers", which_of_these_are_point_tiers$
@config.setField: "show", string$(show)
@config.setField: "deep_search", string$(search_inside_TextGrids)
deep_search= search_inside_TextGrids

# Get audio preferences from preferences.txt
open_as_LongSound= number(config.init.return$["open_as_LongSound"])
adjust_volume= number(config.init.return$["adjust_volume"])
audio_extension$= config.init.return$["audio_extension"]

# Get TextGridEditor preferences from preferences.txt
default_values= number(config.init.return$["textGridEditor.default_values"])
if default_values
  min_range= number(config.init.return$["spectrogram.min_range"])
  max_range= number(config.init.return$["spectrogram.max_range"])
  dynamic_range= number(config.init.return$["spectrogram.dynamic_range"])
  view_lenght= number(config.init.return$["spectrogram.view_lenght"])
  show_pitch= number(config.init.return$["analysis.pitch"])
  show_intensity= number(config.init.return$["analysis.intensity"])
  show_formants= number(config.init.return$["analysis.formants"])
  show_pulse= number(config.init.return$["analysis.pulse"])
endif

# Check the dialog box
if all_tier_names$ == ""
  writeInfoLine: "Please, complete the ""All tier names"" field"
  exitScript()
audio_folder$ == ""
  writeInfoLine: "Please, complete the ""Audio folder"" field"
  exitScript()
elsif textgrid_folder$ == ""
  writeInfoLine: "Please, complete the ""TextGrid folder"" field"
  exitScript()
endif

# Create Corpus table
deep_search$= if search_inside_TextGrids then all_tier_names$ else "" fi

runScript: "create_corpus_table.praat", textgrid_folder$, audio_folder$, audio_extension$, deep_search$
tb_corpus= selected("Table")

if show < 3
  columnName$= if deep_search then "all_tiers" else "annotation" fi
  boolean= if show = 1 then 0 else 1 fi
  tb_temp= nowarn Extract rows where column (number): columnName$, "equal to", boolean
  removeObject: tb_corpus
  tb_corpus= tb_temp
  selectObject: tb_corpus
endif

number_of_files= object[tb_corpus].nrow
if !number_of_files
  writeInfoLine: "No cases were found"
  exitScript()
endif
file_number = 1
volume = 1

## Create corpus table
while 1
  status$ = "no changes"
  file_number = if file_number > number_of_files then 1 else file_number fi
  annotation= object[tb_corpus, file_number, "annotation"]
  all_tiers= object[tb_corpus, file_number, "all_tiers"]
  
  sd$= object$[tb_corpus, file_number, "sound_file"]
  tg$= sd$ - audio_extension$ + ".TextGrid"
  
  # Open a Sound file from the list
  if open_as_LongSound
    sd = Open long sound file: audio_folder$ + "/"+ sd$
  else
    sd = Read from file: audio_folder$ + "/"+ sd$
    if adjust_volume
      Formula: "self*'volume'"
    endif
  endif
  
  # If the corresponding textgrid exists, then open it. Otherwise, create it
  if annotation
    # Open the TextGrid
    tg = Read from file: textgrid_folder$ + "/"+ tg$
    if deep_search
      if !all_tiers
        status$= "modified"
        runScript: "add_tiers.praat", all_tier_names$, which_of_these_are_point_tiers$
      endif
    endif
  else
    # Create a TextGrid
    tg = To TextGrid: all_tier_names$, which_of_these_are_point_tiers$
    status$ = "new TextGrid"
  endif
  
  selectObject: sd
  plusObject: tg
  View & Edit
  
  editor: tg
  if default_values
    Spectrogram settings: min_range, max_range, view_lenght, dynamic_range
    Show analyses: "yes", show_pitch, show_intensity, show_formants, show_pulse, 10
  endif
  
  beginPause: "Audio transcriber"
    comment: "Status: 'status$'"
    comment: "Case: 'file_number'/'number_of_files'"
    natural: "Next file",  if (file_number + 1) > number_of_files then 1 else file_number + 1 fi
    if adjust_volume
      real: "Volume", volume
    endif
  clicked = endPause: "Save", "Jump", "Quit", 1
  endeditor

  if clicked = 1
    selectObject: tb_corpus
    Set numeric value: file_number, "annotation", 1
    Set numeric value: file_number, "all_tiers", 1
    selectObject: tg
    Save as text file: textgrid_folder$ + "/"+ tg$
  endif

  removeObject: sd, tg
  file_number = next_file

  if clicked = 3
    removeObject: tb_corpus
    exitScript()
  endif
endwhile

if clicked = 2
  runScript: "run_plugin.praat"
endif
