#if not CLEAN19
page 5308 "Outlook Synch. Table List"
{
    Caption = 'Outlook Synch. Table List';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableView = SORTING("Object Type", "Object ID")
                      WHERE("Object Type" = CONST(Table));
    ObsoleteState = Pending;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object ID';
                    ToolTip = 'Specifies the ID of the table.';
                }
                field("Object Caption"; Rec."Object Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Caption';
                    ToolTip = 'Specifies the caption of the object, that is, the name that will be displayed in the user interface.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
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
