namespace System.Tooling;

page 9847 "Designed Query Objects"
{
    Caption = 'Designed Query Objects';
    Editable = false;
    PageType = List;
    SourceTable = "Designed Query Obj";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object ID';
                    ToolTip = 'Specifies the ID of the object.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Object Name';
                    ToolTip = 'Specifies the name of the object.';
                }
            }
        }
    }
}

