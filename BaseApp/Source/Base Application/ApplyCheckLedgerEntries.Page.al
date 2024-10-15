page 382 "Apply Check Ledger Entries"
{
    Caption = 'Apply Check Ledger Entries';
    PageType = Worksheet;
    SourceTable = "Check Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(LineApplied; LineApplied)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied';
                    ToolTip = 'Specifies if the check ledger entry has been applied.';

                    trigger OnValidate()
                    begin
                        LineAppliedOnPush;
                    end;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the check ledger entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document type linked to the check ledger entry. For example, Payment.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number on the check ledger entry.';
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the check date if a check is printed.';
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the check number if a check is printed.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount on the check ledger entry.';
                }
                field("Check Type"; "Check Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type check, such as Manual.';
                }
                field(Open; Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field("Statement Status"; "Statement Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that the structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
                    Visible = false;
                }
                field("Statement No."; "Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account statement that the check ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied or Check Ledger Applied.';
                    Visible = false;
                }
                field("Statement Line No."; "Statement Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the statement line that the check ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied or Check Ledger Applied.';
                    Visible = false;
                }
            }
            group(Control25)
            {
                ShowCaption = false;
                field("BankAccReconLine.""Statement Amount"""; BankAccReconLine."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Statement Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was applied in the selected check ledger entry line.';
                }
                field(AppliedAmount; BankAccReconLine."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Applied Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was applied by the check ledger entry in the selected line.';
                }
                field("BankAccReconLine.Difference"; BankAccReconLine.Difference)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the applied amount and the statement amount in the selected line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        LineApplied :=
          ("Statement Status" = "Statement Status"::"Check Entry Applied") and
          ("Statement No." = BankAccReconLine."Statement No.") and
          ("Statement Line No." = BankAccReconLine."Statement Line No.");
    end;

    trigger OnAfterGetRecord()
    begin
        LineApplied :=
          ("Statement Status" = "Statement Status"::"Check Entry Applied") and
          ("Statement No." = BankAccReconLine."Statement No.") and
          ("Statement Line No." = BankAccReconLine."Statement Line No.");
    end;

    var
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CheckSetStmtNo: Codeunit "Check Entry Set Recon.-No.";
        ChangeAmount: Boolean;
        LineApplied: Boolean;

    procedure SetStmtLine(NewBankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconLine := NewBankAccReconLine;
        ChangeAmount := BankAccReconLine."Statement Amount" = 0;
    end;

    local procedure LineAppliedOnPush()
    begin
        CheckLedgEntry.Copy(Rec);
        CheckSetStmtNo.ToggleReconNo(CheckLedgEntry, BankAccReconLine, ChangeAmount);
        CurrPage.Update();
    end;
}

