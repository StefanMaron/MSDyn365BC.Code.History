pageextension 18903 "Cash Receipt Voucher" extends "Cash Receipt Voucher"
{
    layout
    {
        addbefore(Amount)
        {
            field("TCS Nature of Collection"; "TCS Nature of Collection")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the TCS Nature of collection on which the TCS will be calculated for the journal line.';
                trigger OnLookup(var Text: Text): Boolean
                begin
                    AllowedNOCLookup(Rec, "Account No.");
                    UpdateTaxAmount();
                end;

                trigger OnValidate()
                var
                begin
                    UpdateTaxAmount();
                end;
            }
            field("T.C.A.N. No."; "T.C.A.N. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the T.C.A.N. number of the person who is responsible for collecting tax.';
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
    procedure UpdateTaxAmount()
    var
        CalculateTax: Codeunit "Calculate Tax";
    begin
        CurrPage.SaveRecord();
        CalculateTax.CallTaxEngineOnGenJnlLine(Rec, xRec);
    end;
}