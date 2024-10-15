page 11743 "Currency Nominal Values"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Currency Nominal Values';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Currency Nominal Value";
    UsageCategory = Administration;

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

