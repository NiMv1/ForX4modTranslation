cd ..\..

XRCatTool.exe -dump -include ".lua" ".xpl" ".xml" -exclude "(content.xml)|(ui.xml)|(0001.*\.xml)|(.bak)" -in "extensions\kuertee_ui_extensions" -out "extensions\kuertee_ui_extensions\subst_01.cat"

set /p DUMMY=Hit ENTER to exit...
