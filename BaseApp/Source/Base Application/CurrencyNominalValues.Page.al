page 11743 "Currency Nominal Values"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Currency Nominal Values (Obsolete)';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Currency Nominal Value";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies usable value for currency.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
    }
}

