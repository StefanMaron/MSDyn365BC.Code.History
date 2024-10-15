#if not CLEAN17
page 31082 "File Mapping"
{
    Caption = 'File Mapping (Obsolete)';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Statement File Mapping";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.5';

    layout
    {
        area(content)
        {
            repeater(Control1220006)
            {
                ShowCaption = false;
                field("Excel Cell"; "Excel Cell")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies excel cell in which will be exported the value from system. The value is mapped in format RxCy.';
                }
                field(Split; Split)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if line splits';
                    Visible = false;
                }
                field(Offset; Offset)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies offset of line';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}
#endif