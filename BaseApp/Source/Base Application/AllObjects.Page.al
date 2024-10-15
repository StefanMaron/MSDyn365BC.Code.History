page 696 "All Objects"
{
    Caption = 'All Objects';
    DataCaptionFields = "Object Type";
    Editable = false;
    PageType = List;
    SourceTable = AllObj;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Type';
                    ToolTip = 'Specifies the type of the object.';
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object ID';
                    ToolTip = 'Specifies the ID of the object.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    ToolTip = 'Specifies the name of the object.';
                }
            }
        }
    }

    actions
    {
    }
}

