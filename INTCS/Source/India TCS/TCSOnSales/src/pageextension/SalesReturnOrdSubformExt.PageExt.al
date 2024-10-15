pageextension 18844 "Sales Return Ord Subform Ext" extends "Sales Return Order Subform"
{
    layout
    {
        addafter("Location Code")
        {
            field("TCS Nature of Collection"; "TCS Nature of Collection")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the TCS Nature of collection on which the TCS will be calculated for the Sales Return Order.';
                trigger OnLookup(var Text: Text): Boolean
                begin
                    AllowedNocLookup(Rec, "Sell-to Customer No.");
                    UpdateTaxAmount();
                end;

                trigger OnValidate()
                var
                begin
                    UpdateTaxAmount();
                end;
            }
        }
        modify("Invoice Disc. Pct.")
        {
            trigger OnAfterValidate()
            begin
                TCSSalesValidation.UpdateTaxAmountOnSalesLine(Rec);
            end;
        }
        modify("Invoice Discount Amount")
        {
            trigger OnAfterValidate()
            begin
                TCSSalesValidation.UpdateTaxAmountOnSalesLine(Rec);
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
        TCSSalesValidation: Codeunit "TCS Sales Validations";
}