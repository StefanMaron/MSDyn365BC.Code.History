namespace System.Reflection;

page 669 "Table Objects"
{
    Caption = 'Table Objects';
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableView = where("Object Type" = const(Table));

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
                    Caption = 'ID';
                    ToolTip = 'Specifies the object ID.';
                }
                field("Object Caption"; Rec."Object Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the table object.';
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

