namespace Microsoft.Finance.Currency;

page 483 "Currency Exchange Rates"
{
    Caption = 'Currency Exchange Rates';
    DataCaptionFields = "Currency Code";
    PageType = List;
    SourceTable = "Currency Exchange Rate";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date on which the exchange rate on this line comes into effect.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the foreign currency on this line.';
                }
                field("Relational Currency Code"; Rec."Relational Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how you want to set up the two currencies, one of the currencies can be LCY, for which you want to register exchange rates.';
                }
                field("Exchange Rate Amount"; Rec."Exchange Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line.';
                }
                field("Relational Exch. Rate Amount"; Rec."Relational Exch. Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line.';
                }
                field("Adjustment Exch. Rate Amount"; Rec."Adjustment Exch. Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates that will be used by the Adjust Exchange Rates batch job.';
                }
                field("Relational Adjmt Exch Rate Amt"; Rec."Relational Adjmt Exch Rate Amt")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates that will be used by the Adjust Exchange Rates batch job.';
                }
                field("Settlement Rate Amount"; Rec."Settlement Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the base amount for the exchange rate which is entered in Relational Sett. Rate Amount.';
                }
                field("Relational Sett. Rate Amount"; Rec."Relational Sett. Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the settlement exchange rate with which you want to settle the VAT entries.';
                }
                field("Fix Exchange Rate Amount"; Rec."Fix Exchange Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the currency''s exchange rate can be changed on invoices and journal lines.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate := xRec;
        if not BelowxRec then begin
            CurrExchRate.CopyFilters(Rec);
            if CurrExchRate.Next(-1) <> 0 then
                Rec.TransferFields(CurrExchRate, false)
        end else
            Rec.TransferFields(CurrExchRate, false)
    end;
}

