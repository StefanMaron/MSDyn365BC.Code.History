pageextension 18768 "Purchase Journal TDS" extends "Purchase Journal"
{
    layout
    {
        addafter("Account No.")
        {
            field("Provisional Entry"; "Provisional Entry")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether this is a provisional entry or not.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;
            }
            field("Applied Provisional Entry"; "Applied Provisional Entry")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the applied provisional entry number.';
            }
            field("TDS Section Code"; "TDS Section Code")
            {
                ApplicationArea = Basic, Suite;
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
                ToolTip = 'Specify the type of Remittance deductee deals with for which the journal line has been created.';
                trigger OnValidate()
                begin
                    CheckNonResidentsPaymentSelection();
                    UpdateTaxAmount();
                end;
            }
            field("Act Applicable"; "Act Applicable")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the tax rates prescribed under the IT Act or DTAA for which the journal line has been created.';
                trigger OnValidate()
                begin
                    CheckNonResidentsPaymentSelection();
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
        }
    }
    actions
    {
        addafter("F&unctions")
        {
            action("Apply Provisional Entry")
            {
                ApplicationArea = Basic, Suite;
                Image = Apply;
                ToolTip = 'Select this option to apply provisional entry against purchase invoice (actual entry).';
                trigger OnAction()
                var
                    ProvisionalEntry: Record "Provisional Entry";
                    ApplyProvisionalEntries: Page "Apply Provisional Entries";
                    AmtNegErr: Label 'Amount must be Negative.';
                begin
                    TestField("Account Type", "Account Type"::Vendor);
                    TestField("Account No.");
                    TestField("Bal. Account Type", "Bal. Account Type"::"G/L Account");
                    TestField("Document Type", "Document Type"::Invoice);
                    TestField("Work Tax Nature Of Deduction", '');
                    TestField("TDS Section Code", '');
                    IF Amount > 0 THEN
                        ERROR(AmtNegErr);

                    ProvisionalEntry.SetRange("Party Type", ProvisionalEntry."Party Type"::Vendor);
                    ProvisionalEntry.SetRange("Party Code", "Account No.");
                    ProvisionalEntry.SetRange(Open, TRUE);
                    ProvisionalEntry.SetRange(Reversed, FALSE);
                    ProvisionalEntry.SetRange("Reversed After TDS Paid", FALSE);
                    ApplyProvisionalEntries.SetGenJnlLine(Rec);
                    ApplyProvisionalEntries.SETTABLEVIEW(ProvisionalEntry);
                    ApplyProvisionalEntries.LOOKUPMODE(TRUE);
                    ProvisionalEntry.Update := ApplyProvisionalEntries.RunModal() = ACTION::LookupOK;
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