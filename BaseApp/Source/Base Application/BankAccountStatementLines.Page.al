page 384 "Bank Account Statement Lines"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Bank Account Statement Line";

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
                    ToolTip = 'Specifies the posting date of the bank account or check ledger entry that the transaction on this line has been applied to.';
                }
                field("Value Date"; "Value Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value date of the transaction on this line.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of this line.';
                    Visible = false;
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check number for the transaction on this line.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of ledger entry, or a difference that has been reconciled with the transaction on the bank''s statement on this line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the transaction on this line.';
                }
                field("Statement Amount"; "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction on the bank''s statement on this line.';
                }
                field("Applied Amount"; "Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount on the bank account or check ledger entry that the transaction on this line has been applied to.';

                    trigger OnDrillDown()
                    begin
                        DisplayApplication;
                    end;
                }
                field(Difference; Difference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the amount in the Statement Amount field and Applied Amount field on this line.';
                }
                field("Applied Entries"; "Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the transaction on this line has been applied to one or more ledger entries.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DisplayApplication;
                    end;
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                field(Balance; Balance + "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = GetCurrencyCode();
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    Enabled = BalanceEnable;
                    ToolTip = 'Specifies a balance, consisting of the Balance Last Statement field, plus the balance that has accumulated in the Statement Amount field.';
                }
                field(TotalBalance; TotalBalance + "Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = GetCurrencyCode();
                    AutoFormatType = 1;
                    Caption = 'Total Balance';
                    Editable = false;
                    Enabled = TotalBalanceEnable;
                    ToolTip = 'Specifies the accumulated balance of the Bank Account Statement, which consists of the Balance Last Statement field, plus the balance in the Statement Amount field.';
                }
                field(TotalDiff; TotalDiff + Difference)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = GetCurrencyCode();
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcBalance("Statement Line No.");
    end;

    trigger OnInit()
    begin
        BalanceEnable := true;
        TotalBalanceEnable := true;
        TotalDiffEnable := true;
    end;

    var
        TotalDiff: Decimal;
        TotalBalance: Decimal;
        Balance: Decimal;
        [InDataSet]
        TotalDiffEnable: Boolean;
        [InDataSet]
        TotalBalanceEnable: Boolean;
        [InDataSet]
        BalanceEnable: Boolean;

    local procedure CalcBalance(BankAccStmtLineNo: Integer)
    var
        BankAccStmt: Record "Bank Account Statement";
        TempBankAccStmtLine: Record "Bank Account Statement Line";
    begin
        if BankAccStmt.Get("Bank Account No.", "Statement No.") then;

        TempBankAccStmtLine.Copy(Rec);

        TotalDiff := -Difference;
        if TempBankAccStmtLine.CalcSums(Difference) then begin
            TotalDiff := TotalDiff + TempBankAccStmtLine.Difference;
            TotalDiffEnable := true;
        end else
            TotalDiffEnable := false;

        TotalBalance := BankAccStmt."Balance Last Statement" - "Statement Amount";
        if TempBankAccStmtLine.CalcSums("Statement Amount") then begin
            TotalBalance := TotalBalance + TempBankAccStmtLine."Statement Amount";
            TotalBalanceEnable := true;
        end else
            TotalBalanceEnable := false;

        Balance := BankAccStmt."Balance Last Statement" - "Statement Amount";
        TempBankAccStmtLine.SetRange("Statement Line No.", 0, BankAccStmtLineNo);
        if TempBankAccStmtLine.CalcSums("Statement Amount") then begin
            Balance := Balance + TempBankAccStmtLine."Statement Amount";
            BalanceEnable := true;
        end else
            BalanceEnable := false;
    end;
}

