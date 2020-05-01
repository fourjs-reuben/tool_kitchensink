IMPORT os
IMPORT util

DEFINE arr DYNAMIC ARRAY OF RECORD
    insert STRING,
    delete STRING,
    label STRING,
    name STRING,
    datatype STRING,
    precision STRING,
    widget STRING,
    size SMALLINT,
    attributes STRING,
    value STRING
END RECORD
CONSTANT INSERT_INLINE_IMAGE="fa-plus"
CONSTANT DELETE_INLINE_IMAGE = "fa-minus"


MAIN
DEFINE t TEXT

    CLOSE WINDOW SCREEN
    OPEN WINDOW w  WITH FORM "tool_kitchensink"

    LOCATE t IN MEMORY
    TRY
        CALL t.readFile("default.json")
        CALL util.JSON.parse(t,arr)
    CATCH
        CALL FGL_WINMESSAGE("Error","Could not load default","error")        
    END TRY
    FREE t

    INPUT ARRAY arr FROM scr.* ATTRIBUTES(WITHOUT DEFAULTS=TRUE, UNBUFFERED, ACCEPT=FALSE, CANCEl=FALSE)
        BEFORE INSERT
            LET arr[arr_curr()].insert = INSERT_INLINE_IMAGE 
            LET arr[arr_curr()].delete = DELETE_INLINE_IMAGE
        ON ACTION input
            CALL go("input")

        ON ACTION construct
            CALL go("construct")

        ON ACTION viewform
            CALL go("viewform")

         ON ACTION checksyntax
            CALL go("checksyntax")

        ON ACTION duplicate
            IF arr.getLength() = arr_curr() THEN
                CALL arr.appendElement()
            ELSE
                CALL arr.insertElement(arr_curr()+1)
            END IF
            LET arr[arr_curr()+1].* = arr[arr_curr()].*

        ON ACTION save
            CALL save()
            
        ON ACTION load
            CALL load()

        ON ACTION clear
            #TODO add a warning
            CALL arr.clear()
            
        ON ACTION close
            EXIT INPUT
    END INPUT
END MAIN

FUNCTION go(dialog_type STRING)
DEFINE d ui.Dialog
DEFINE ev STRING
DEFINE temp_filename STRING
DEFINE result INTEGER
DEFINE ch base.Channel
DEFINE i,j INTEGER
DEFINE spaces base.StringBuffer

DEFINE names DYNAMIC ARRAY OF RECORD
    name STRING, datatype STRING
END RECORD
DEFINE t TEXT


    LET temp_filename  = os.Path.makeTempName()

    LET ch = base.Channel.create()
    CALL ch.openFile(temp_filename||".per","w")
    CALL ch.writeLine("LAYOUT")
    CALL ch.writeLine("GRID")
    CALL ch.writeLine("{")
    FOR i= 1 TO arr.getLength()
        LET spaces = base.StringBuffer.create()
        FOR j = 4 TO arr[i].size
            CALL spaces.append(" ")
        END FOR
        CALL ch.writeLine(SFMT("[l%1          ][f%1%2: ]", i USING "&&", spaces.toString()))
    END FOR
    CALL ch.writeLine("}")
    CALL ch.writeLine("END #GRID")
    CALL ch.writeLine("END #LAYOUT")
    CALL ch.writeLine("ATTRIBUTES")
    FOR i = 1 TO arr.getLength()
        CALL ch.writeLine(SFMT("LABEL l%1 : l%1, TEXT=\"%2\";", i USING "&&", arr[i].label))
        CALL ch.writeLine(SFMT("%2 f%1 = formonly.%3 TYPE %4, %5;", i USING "&&", arr[i].widget, arr[i].name, variable_type_2_data_type(arr[i].datatype), nvl(arr[i].attributes,"COMMENT=\"No attributes specified\"")))
    END FOR

    CALL ch.close()

    IF dialog_type = "viewform" THEN
        LOCATE t IN FILE SFMT("%1.per", temp_filename)
        CALL FGL_WINMESSAGE("View Form ",t,"info")
        RETURN
    END IF

    
    RUN SFMT("fglform -M \"%1\" 2>%1.out ", temp_filename) RETURNING result

    IF dialog_type="checksyntax" THEN
        IF result = 0 THEN
            CALL FGL_WINMESSAGE("Info","Form File Compiles","info")
            RETURN
        END IF
    END IF
    
    IF result  > 0 THEN
        LOCATE t IN FILE SFMT("%1.out", temp_filename)
        CALL FGL_WINMESSAGE("Compile Error",t,"error")
        RETURN
    END IF

    CALL names.clear()
    FOR i = 1 To arr.getLength()
        LET names[i].name = "formonly.",arr[i].name
        IF arr[i].precision IS NULL THEN
            LET names[i].datatype = arr[i].datatype
        ELSE
            IF arr[i].datatype = "*DATETIME" OR arr[i].datatype = "INTERVAL" THEN
                LET names[i].datatype = SFMT("%1 %2", arr[i].datatype, arr[i].precision)
            ELSE
                LET names[i].datatype = SFMT("%1(%2)", arr[i].datatype, arr[i].precision)
            END IF
        END IF
    END FOR
    
    OPEN WINDOW w2 WITH FORM temp_filename ATTRIBUTES(TEXT="Test Form")

    CASE dialog_type
        WHEN "construct"
            LET d = ui.Dialog.createConstructByName(names)
        OTHERWISE
            LET d = ui.Dialog.createInputByName(names)
    END CASE
    CALL d.addTrigger("ON ACTION close")
    CALL d.addTrigger("ON ACTION accept")
    CALL d.addTrigger("ON ACTION cancel")
    WHILE TRUE
        LET ev = d.nextEvent()
        DISPLAY ev
        CASE
            WHEN ev = "BEFORE INPUT" OR ev = "BEFORE CONSTRUCT"
                FOR i = 1 TO arr.getLength()
                    IF arr[i].value IS NOT NULL THEN
                        CALL d.setFieldValue(arr[i].name, arr[i].value)
                    END IF
                END FOR
            WHEN ev = "ON ACTION accept"
                IF d.validate("formonly.*") = 0 THEN
                    EXIT WHILE
                END IF
            WHEN ev = "ON ACTION cancel"
                EXIT WHILE
                
            WHEN ev = "ON ACTION close"
                EXIT WHILE
        END CASE
    END WHILE
    LET int_flag = 0
    CALL d.close()
    CLOSE WINDOW w2
    
    IF os.Path.delete(temp_filename||".42f") THEN
    END IF
    IF os.Path.delete(temp_filename||".per") THEN
    END IF

END FUNCTION

FUNCTION variable_type_2_data_type(t)
DEFINE t STRING

    CASE t.toUpperCase()
        WHEN "STRING"
            RETURN "VARCHAR"
        WHEN "TINYINT"
            RETURN "SMALLINT"
        OTHERWISE
            RETURN t
    END CASE
END FUNCTION



FUNCTION combo_populate_widget(cb)
DEFINE cb ui.ComboBox

    CALL cb.clear()
    CALL cb.addItem("EDIT","EDIT")
   
    CALL cb.addItem("BUTTONEDIT","BUTTONEDIT")
    
    CALL cb.addItem("DATEEDIT", "DATEEDIT")
    CALL cb.addItem("DATETIMEEDIT", "DATETIMEEDIT")
    CALL cb.addItem("SPINEDIT", "SPINEDIT")
    CALL cb.addItem("TEXTEDIT", "TEXTEDIT")
    CALL cb.addItem("TIMEEDIT", "TIMEEDIT")
    
    CALL cb.addItem("CHECKBOX", "CHECKBOX")
    CALL cb.addItem("COMBOBOX", "COMBOBOX")
    CALL cb.addItem("RADIOGROUP", "RADIOGROUP")
    CALL cb.addItem("SLIDER", "SLIDER")

     CALL cb.addItem("IMAGE","IMAGE")
    CALL cb.addItem("LABEL","LABEL")
    CALL cb.addItem("PROGRESSBAR", "PROGRESSBAR")
   

END FUNCTION

FUNCTION combo_populate_datatype(cb)
DEFINE cb ui.ComboBox

    CALL cb.clear()
    CALL cb.addItem("STRING","STRING")
    CALL cb.addItem("CHAR","CHAR")
    CALL cb.addItem("VARCHAR","VARCHAR")

    CALL cb.addItem("INTEGER","INTEGER")
    CALL cb.addItem("SMALLINT","SMALLINT")
    CALL cb.addItem("BIGINT","BIGINT")
    CALL cb.addItem("TINYINT","TINYINT")

    CALL cb.addItem("DATE","DATE")
    CALL cb.addItem("DATETIME","DATETIME")
    CALL cb.addItem("INTERVAL","INTERVAL")

    CALL cb.addItem("DECIMAL","DECIMAL")
    CALL cb.addItem("FLOAT","FLOAT")
    CALL cb.addItem("SMALLFLOAT","SMALLFLOAT")
    CALL cb.addItem("MONEY","MONEY")

    CALL cb.addItem("BOOLEAN","BOOLEAN")
END FUNCTION


FUNCTION save()
DEFINE filename STRING
DEFINE t TEXT

    WHILE TRUE
        PROMPT "Enter filename to save?" FOR filename
        IF int_flag THEN
            CALL FGL_WINMESSAGE("Warning","Data not saved","warn")
            LET int_flag = 0
            RETURN
        END IF
        IF filename.trim().getLength() = 0 THEN
            CALL FGL_WINMESSAGE("Error","Filename must be entered","error")
            CONTINUE WHILE
        END IF
        IF os.Path.exists(filename) THEN
            IF FGL_WINQUESTION("","","","","","") THEN
                CALL FGL_WINMESSAGE("Error","Filename already exists","error")
                CONTINUE WHILE
            END IF
        END IF
        LOCATE t IN MEMORY
        LET t = util.JSON.stringify(arr)
        CALL t.writeFile(filename)
        FREE t
        EXIT WHILE
    END WHILE
END FUNCTION

FUNCTION load()
DEFINE filename STRING
DEFINE t TEXT

    WHILE TRUE
        PROMPT "Enter filename to save?" FOR filename 
        IF int_flag THEN
            CALL FGL_WINMESSAGE("Warning","No file loaded","warn")
            LET int_flag = 0
            RETURN
        END IF
        IF filename.trim().getLength() = 0 THEN
            CALL FGL_WINMESSAGE("Error","Filename must be entered","error")
            CONTINUE WHILE
        END IF
        IF NOT os.Path.exists(filename) THEN
            CALL FGL_WINMESSAGE("Error","Filename does not exist","error")
            CONTINUE WHILE
        END IF
        CALL arr.clear()
        LOCATE t IN MEMORY
        TRY
            CALL t.readFile(filename)
            CALL util.JSON.parse(t,arr)
        CATCH
            CALL FGL_WINMESSAGE("Error","Could not read file","error")        
        END TRY
        FREE t
        EXIT WHILE
    END WHILE
        
END FUNCTION
    
