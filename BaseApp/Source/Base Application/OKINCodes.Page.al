page 17361 "OKIN Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'OKIN Codes';
    PageType = List;
    SourceTable = "Classificator OKIN";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Group; Group)
                {
                    ApplicationArea = All;
                    Visible = GroupVisible;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        GroupVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
        GroupVisible := not CurrPage.LookupMode;
    end;

    var
        [InDataSet]
        GroupVisible: Boolean;
}

