pageextension 18766 "General Journal Ext" extends "General Journal"
{
    layout
    {
        addbefore("Account Type")
        {
            field("Party Type"; "Party Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of party that the entry on the journal line will be posted to.';
            }
            field("Party Code"; "Party Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the party number that the entry on the journal line will be posted to.';
            }
        }
        addafter(Description)
        {
            field("TDS Section Code"; "TDS Section Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Section Codes as per the Income Tax Act 1961 for eTDS returns';
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
                ToolTip = 'Specify the type of Remittance deductee deals with for which the journal line has been created.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
            field("Act Applicable"; "Act Applicable")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the tax rates prescribed under the IT Act or DTAA for which the journal line has been created.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }

            field("Work Tax Nature Of Deduction"; "Work Tax Nature Of Deduction")
            {
                ApplicationArea = Basic, Suite;
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
            field("TDS Certificate Receivable"; "TDS Certificate Receivable")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'TDS Certificate Receivable';
                ToolTip = 'Selected to allow calculating TDS for the customer.';
                trigger OnValidate()
                begin
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