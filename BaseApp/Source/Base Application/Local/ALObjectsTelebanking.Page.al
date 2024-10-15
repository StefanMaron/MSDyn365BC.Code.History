page 11000017 "AL Objects (Telebanking)"
{
    Caption = 'Objects';
    PageType = List;
    SourceTable = AllObj;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; "Object Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the object.';
                    Visible = TypeVisible;
                }
                field(ID; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object.';
                }
                field(Name; "Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object.';
                }
                field("App Package ID"; Rec."App Package ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the GUID of the app from which the object originated.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        TypeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        TypeVisible := GetFilter("Object Type") = '';
    end;

    var
        [InDataSet]
        TypeVisible: Boolean;
}

