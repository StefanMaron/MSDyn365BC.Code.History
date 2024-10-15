pageextension 18838 "Sales Credit Memo Subform Ext" extends "Sales Cr. Memo Subform"
{
    layout
    {
        addafter("Location Code")
        {
            field("TCS Nature of Collection"; "TCS Nature of Collection")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the TCS Nature of collection on which the TCS will be calculated for the Sales Credit Memo.';
                trigger OnLookup(var Text: Text): Boolean
                begin
                    AllowedNocLookup(Rec, "Sell-to Customer No.");
                    UpdateTaxAmount();
                end;

                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
        }
        modify("Invoice Disc. Pct.")
        {
            trigger OnAfterValidate()
            begin
                TCSSalesValidations.UpdateTaxAmountOnSalesLine(Rec);
            end;
        }
        modify("Invoice Discount Amount")
        {
            trigger OnAfterValidate()
            begin
                TCSSalesValidations.UpdateTaxAmountOnSalesLine(Rec);
            end;
        }
    }
    local procedure UpdateTaxAmount()
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CurrPage.SaveRecord();
        CalculateTax.CallTaxEngineOnSalesLine(Rec, xRec);
    end;

    var
        TCSSalesValidations: Codeunit "TCS Sales Validations";
}