pageextension 18770 "Journal Voucher" extends "Journal Voucher"
{
    layout
    {
        addafter("Account No.")
        {
            field("TDS Section Code"; "TDS Section Code")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'TDS Section Code';
                ToolTip = 'Specifies the Section Codes as per the Income Tax Act 1961 for e tds returns';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    TDSSectionCodeLookupGenLine(Rec, "Account No.", true);
                    UpdateTaxAmount();
                end;
            }
            field("Nature of Remittance"; "Nature of Remittance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Nature of Remittance';
                ToolTip = 'Specify the type of Remittance deductee deals with for which the journal line has been created.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
            field("Act Applicable"; "Act Applicable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Act Applicable';
                ToolTip = 'Specify the tax rates prescribed under the IT Act or DTAA for which the journal line has been created.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }

            field("Work Tax Nature Of Deduction"; "Work Tax Nature Of Deduction")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Work Tax Nature Of Deduction';
                ToolTip = 'Specifies the Work Tax Nature of Deduction for the journal line.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    TDSSectionCodeLookupGenLine(Rec, "Account No.", false);
                    UpdateTaxAmount();
                end;
            }
            field("T.A.N. No."; "T.A.N. No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T.A.N. No.';
                ToolTip = 'Specifies the T.A.N. Number.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
            field("TDS Certificate Receivable"; "TDS Certificate Receivable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'TDS Certificate Receivable';
                ToolTip = 'Selected to allow calculating TDS for the customer.';
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