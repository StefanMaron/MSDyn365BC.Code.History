page 17444 "Time Activity Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Time Activity Groups';
    PageType = Document;
    SourceTable = "Time Activity Group";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the activity group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the activity group.';
                }
            }
            part(Lines; "Time Activity Group Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Code = FIELD(Code);
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

