pageextension 18667 "Cash Receipt Journal" extends "Cash Receipt Journal"
{
    layout
    {
        addbefore(Amount)
        {
            field("TDS Certificate Receivable"; "TDS Certificate Receivable")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Selected to allow calculating TDS for the customer.';
            }
            field("TDS Section Code"; "TDS Section Code")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Section Codes as per the Income Tax Act 1961 for e tds returns';

                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;

                trigger OnLookup(var Text: Text): Boolean
                var
                    TDSForCustomerSubscribers: Codeunit "TDS For Customer Subscribers";
                begin
                    TDSForCustomerSubscribers.TDSSectionCodeLookupGenLineForCustomer(Rec, "Account No.", true);
                    UpdateTaxAmount();
                end;
            }
        }
    }
    local procedure UpdateTaxAmount()
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CurrPage.SaveRecord();
        CalculateTax.CallTaxEngineOnGenJnlLine(Rec, xRec);
    end;
}