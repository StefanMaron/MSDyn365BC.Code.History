page 380 "Bank Acc. Reconciliation Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Acc. Reconciliation Line";
    SourceTableView = WHERE("Statement Type" = CONST("Bank Reconciliation"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction Date"; "Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the posting date of the bank account or check ledger entry on the reconciliation line when the Suggest Lines function is used.';
                }
                field("Value Date"; "Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value date of the transaction on the bank reconciliation line.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number of your choice that will appear on the reconciliation line.';
                    Visible = false;
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check number for the transaction on the reconciliation line.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of ledger entry, or a difference to be reconciled on this line.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies a description for the transaction on the reconciliation line.';
                }
                field("Statement Amount"; "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the amount of the transaction on the bank''s statement shown on this reconciliation line.';
                }
                field("Applied Amount"; "Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction on the reconciliation line that has been applied to a bank account or check ledger entry.';

                    trigger OnDrillDown()
                    begin
                        DisplayApplication;
                    end;
                }
                field(Difference; Difference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the amount in the Applied Amount field.';
                }
                field("Applied Entries"; "Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the transaction on the bank''s statement has been applied to one or more bank account or check ledger entries.';
                    Visible = false;
                }
                field("Related-Party Name"; "Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer or vendor who made the payment that is represented by the journal line.';
                    Visible = false;
                }
                field("Additional Transaction Info"; "Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional information on the bank statement line for the payment.';
                    Visible = false;
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                label(Control13)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Caption = '';
                }
                field(Balance; Balance + "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    Enabled = BalanceEnable;
                    ToolTip = 'Specifies a balance, consisting of the Balance Last Statement field, plus the balance that has accumulated in the Statement Amount field.';
                }
                field(TotalBalance; TotalBalance + "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Total Balance';
                    Editable = false;
                    Enabled = TotalBalanceEnable;
                    ToolTip = 'Specifies the accumulated balance of the bank reconciliation, which consists of the Balance Last Statement field, plus the balance in the Statement Amount field.';
                }
                field(TotalDiff; TotalDiff + Difference)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = GetCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Total Difference';
                    Editable = false;
                    Enabled = TotalDiffEnable;
                    ToolTip = 'Specifies the total amount of the Difference field for all the lines on the bank reconciliation.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowStatementLineDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Details';
                RunObject = Page "Bank Statement Line Details";
                RunPageLink = "Data Exch. No." = FIELD("Data Exch. Entry No."),
                              "Line No." = FIELD("Data Exch. Line No.");
                ToolTip = 'View additional information about the document on the selected line and link to the related card.';
            }
            action(ApplyEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Apply Entries...';
                Enabled = ApplyEntriesAllowed;
                Image = ApplyEntries;
                ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded.';

                trigger OnAction()
                begin
                    ApplyBankReconEntries;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if "Statement Line No." <> 0 then
            CalcBalance("Statement Line No.");
        SetUserInteractions;
    end;

    trigger OnAfterGetRecord()
    begin
        SetUserInteractions;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        SetUserInteractions;
    end;

    trigger OnInit()
    begin
        BalanceEnable := true;
        TotalBalanceEnable := true;
        TotalDiffEnable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if BelowxRec then
            CalcBalance(xRec."Statement Line No.")
        else
            CalcBalance(xRec."Statement Line No." - 1);
    end;

    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        StyleTxt: Text;
        TotalDiff: Decimal;
        Balance: Decimal;
        TotalBalance: Decimal;
        [InDataSet]
        TotalDiffEnable: Boolean;
        [InDataSet]
        TotalBalanceEnable: Boolean;
        [InDataSet]
        BalanceEnable: Boolean;
        ApplyEntriesAllowed: Boolean;

    local procedure CalcBalance(BankAccReconLineNo: Integer)
    var
        TempBankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        if BankAccRecon.Get("Statement Type", "Bank Account No.", "Statement No.") then;

        TempBankAccReconLine.Copy(Rec);

        TotalDiff := -Difference;
        if TempBankAccReconLine.CalcSums(Difference) then begin
            TotalDiff := TotalDiff + TempBankAccReconLine.Difference;
            TotalDiffEnable := true;
        end else
            TotalDiffEnable := false;

        TotalBalance := BankAccRecon."Balance Last Statement" - "Statement Amount";
        if TempBankAccReconLine.CalcSums("Statement Amount") then begin
            TotalBalance := TotalBalance + TempBankAccReconLine."Statement Amount";
            TotalBalanceEnable := true;
        end else
            TotalBalanceEnable := false;

        Balance := BankAccRecon."Balance Last Statement" - "Statement Amount";
        TempBankAccReconLine.SetRange("Statement Line No.", 0, BankAccReconLineNo);
        if TempBankAccReconLine.CalcSums("Statement Amount") then begin
            Balance := Balance + TempBankAccReconLine."Statement Amount";
            BalanceEnable := true;
        end else
            BalanceEnable := false;
    end;

    local procedure ApplyBankReconEntries()
    var
        BankAccReconApplyEntries: Codeunit "Bank Acc. Recon. Apply Entries";
    begin
        "Ready for Application" := true;
        CurrPage.SaveRecord;
        Commit();
        BankAccReconApplyEntries.ApplyEntries(Rec);
    end;

    procedure GetSelectedRecords(var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        CurrPage.SetSelectionFilter(BankAccReconciliationLine);
        if BankAccReconciliationLine.FindSet then
            repeat
                TempBankAccReconciliationLine := BankAccReconciliationLine;
                TempBankAccReconciliationLine.Insert();
            until BankAccReconciliationLine.Next = 0;
    end;

    local procedure SetUserInteractions()
    begin
        StyleTxt := GetStyle;
        ApplyEntriesAllowed := Type = Type::"Check Ledger Entry";
    end;

    procedure ToggleMatchedFilter(SetFilterOn: Boolean)
    begin
        if SetFilterOn then
            SetFilter(Difference, '<>%1', 0)
        else
            Reset;
        CurrPage.Update;
    end;
}

