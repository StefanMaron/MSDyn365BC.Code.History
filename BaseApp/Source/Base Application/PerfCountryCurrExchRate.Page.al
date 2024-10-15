page 11764 "Perf. Country Curr. Exch. Rate"
{
    Caption = 'Perf. Country Curr. Exch. Rate';
    DataCaptionFields = "Currency Code";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Perf. Country Curr. Exch. Rate";
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Relational Currency Code"; "Relational Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for exchange rate conversion.';
                    Visible = false;
                }
                field("Perform. Country/Region Code"; "Perform. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the our country/region code in the other EU countries.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date for the VAT period.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                    Visible = true;
                }
                field("Exchange Rate Amount"; "Exchange Rate Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line.';
                }
                field("Relational Exch. Rate Amount"; "Relational Exch. Rate Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of exchange rate.';
                }
                field("Fix Exchange Rate Amount"; "Fix Exchange Rate Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies fix echgange of rate amount';
                }
                field("Intrastat Exch. Rate Amount"; "Intrastat Exch. Rate Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exchange rate amount for intrastat.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220010; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220009; Notes)
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

