pageextension 18545 "General Journal" extends "General Journal"
{
    layout
    {
        addbefore(Amount)
        {
            field("Location Code"; "Location Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the location code for which the journal lines will be posted.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
            field("T.A.N. No."; "T.A.N. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the T.A.N. number of the location for which the entry will be posted.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
        }
        modify(Amount)
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        modify("Credit Amount")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        modify("Debit Amount")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        modify("Amount (LCY)")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        modify("Currency Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        modify("Posting Date")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
        }
        modify("Document Type")
        {
            trigger OnAfterValidate()
            begin
                UpdateTaxAmount();
            end;
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