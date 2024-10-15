pageextension 18747 "Bank Payment Voucher" extends "Bank Payment Voucher"
{
    layout
    {
        addafter(Description)
        {
            field("T.A.N. No."; "T.A.N. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the T.A.N. Number.';
                trigger OnValidate()
                begin
                    UpdateTaxAmount();
                end;

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
        }
    }
    actions
    {
        addafter(Approvals)
        {
            group("Pay TDS")
            {
                action(TDS)
                {
                    Caption = 'TDS';
                    ApplicationArea = Basic, Suite;
                    Image = CollectedTax;
                    ToolTip = 'Select TDS to open Pay TDS page that will show all TDS entries.';

                    trigger OnAction()
                    var
                        TDSPay: Codeunit "TDS Pay";
                    begin
                        TDSPay.PayTDS(Rec);
                    end;
                }
            }
            group("Pay Work Tax")
            {
                action("Work Tax")
                {
                    Caption = 'Work Tax';
                    ApplicationArea = Basic, Suite;
                    Image = CollectedTax;
                    ToolTip = 'Select this field to pay Work tax to the government.';

                    trigger OnAction()
                    var
                        TDSPay: Codeunit "TDS Pay";
                    begin
                        TDSPay.PayWorkTax(Rec);
                    end;
                }
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