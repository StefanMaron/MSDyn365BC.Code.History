pageextension 18720 "PurchaseOrderSubform" extends "Purchase Order Subform"
{
    layout
    {
        addafter("Line Amount")
        {
            field("TDS Section Code"; "TDS Section Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Section Codes as per the Income Tax Act 1961 for e tds returns';
                trigger OnLookup(var Text: Text): Boolean
                begin
                    OnAfterTDSSectionCodeLookupPurchLine(Rec, "Buy-from Vendor No.", true);
                    UpdateTaxAmount();
                end;

                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
            field("Nature of Remittance"; "Nature of Remittance")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the type of remittance deductee deals with.';
                trigger OnValidate()
                begin
                    CheckNonResidentsPaymentSelection();
                    UpdateTaxAmount()
                end;
            }
            field("Act Applicable"; "Act Applicable")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the tax rates prescribed under the IT Act or DATA on the TDS entry.';
                trigger OnValidate()
                begin
                    CheckNonResidentsPaymentSelection();
                    UpdateTaxAmount()
                end;
            }
            field("Work Tax Nature Of Deduction"; "Work Tax Nature Of Deduction")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Work Tax Nature of Deduction for the Purchase line.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount()
                end;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    OnAfterTDSSectionCodeLookupPurchLine(Rec, "Buy-from Vendor No.", false);
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
        CalculateTax.CallTaxEngineOnPurchaseLine(Rec, xRec);
    end;

}