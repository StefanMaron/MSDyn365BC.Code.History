page 130416 "Get Semi-Manual Test Codeunits"
{
    Caption = 'Get Semi-Manual Test Codeunits';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = AllObjWithCaption;
    SourceTableView = WHERE("Object Type" = CONST(Codeunit));

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object ID number for the object named in the codeunit.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the object name in the codeunit.';
                }
            }
        }
    }

    actions
    {
    }
}

