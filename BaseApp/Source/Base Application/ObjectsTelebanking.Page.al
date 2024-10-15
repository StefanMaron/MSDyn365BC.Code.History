page 11000013 "Objects (Telebanking)"
{
    Caption = 'Objects';
    PageType = List;
    SourceTable = "Object";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced with the AL Objects (Telebanking) page';
    ObsoleteTag = '15.2';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the object.';
                    Visible = TypeVisible;
                }
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object.';
                }
                field(Modified; Modified)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the object was last modified.';
                    Visible = false;
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the object was added.';
                    Visible = false;
                }
                field("Version List"; "Version List")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Telebanking object versions.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        TypeVisible := true;
    end;

    trigger OnOpenPage()
    begin
        TypeVisible := GetFilter(Type) = '';
    end;

    var
        [InDataSet]
        TypeVisible: Boolean;
}

