page 31061 "Intrastat Currency Exch. Rate"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Intrastat Currency Exch. Rate';
    PageType = List;
    SourceTable = "Intrastat Currency Exch. Rate";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220003)
            {
                ShowCaption = false;
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date for the intrastat currency exch. rate.';
                }
                field("Exchange Rate Amount"; "Exchange Rate Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220005; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220004; Notes)
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

