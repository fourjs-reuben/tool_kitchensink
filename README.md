# tool_kitchensink
A tool to test various form attributes without having to create a runnable program

In order to test an individual attribute of a widget, wether because it is new or in the course of handling a support call, I have to create a demo or test program in order to test that widget.

What this program does is remove the overhead of creating the demo program.  I run this program, add a line or lines with the widget and attribute I want to test, and BINGO I can instantly see what the difference is.

To understand the program, run it.  By default the array will have 1 line for a simple EDIT widget.  If you click input, it will dynamically create a dialog to interact with a form that has that 1 EDIT widget.

Now click Load and type password.json.  It should now have 2 lines in the array, and if you click input, it will dynamically create a dialog to interact with a form that has that 2 EDIT widget's, the difference is that one has the INVISIBLE attribute defined.

Now click and load widget.json.  The array should have multiple lines, and if you click input, it will dynamically create a dialog to interact with a form that has many different widgets.

TODO

Add screenshots to this README so its purpose is clear
Tidyup text of action buttons
Implement a screen to display entered values
Add a HEIGHT attribute for use with TEXTEDITS, IMAGE etc
Add a means to align widgets in grid
Add a proper screen to display generated .per
Lots of testing for various widgets, datatypes
Create more default .json files
Provide a style editor as well
Consider moving .json files to client and/or provide a window to list available entries
Implement a DISPLAY ARRAY

