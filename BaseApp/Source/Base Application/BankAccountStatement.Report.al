report 1407 "Bank Account Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BankAccountStatement.rdlc';
    Caption = 'Bank Account Statement';

    dataset
    {
        dataitem("Bank Account Statement"; "Bank Account Statement")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(ComanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(BankAccStmtTableCaptFltr; TableCaption + ': ' + BankAccStmtFilter)
            {
            }
            column(BankAccStmtFilter; BankAccStmtFilter)
            {
            }
            column(StmtNo_BankAccStmt; "Statement No.")
            {
                IncludeCaption = true;
            }
            column(Bank_Acc__Reconciliation___Statement_Date_Caption; Bank_Acc__Reconciliation___Statement_Date_CaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___Statement_Date_; Format("Bank Account Statement"."Statement Date"))
            {
            }
            column(Bank_Acc__Reconciliation___Balance_Last_Statement_Caption; Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___Balance_Last_Statement_; "Bank Account Statement"."Balance Last Statement")
            {
            }
            column(Bank_Acc__Reconciliation___Statement_Ending_Balance_Caption; Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___Statement_Ending_Balance_; "Bank Account Statement"."Statement Ending Balance")
            {
            }
            column(G_L_BalanceCaption; G_L_BalanceCaptionTxt)
            {
            }
            column(Bank_Acc__Reconciliation___TotalBalOnBankAccount; "Bank Account Statement"."G/L Balance at Posting Date")
            {
            }
            column(Subtotal_Caption; Subtotal_CaptionLbl)
            {
            }
            column(GL_Subtotal; "Bank Account Statement"."G/L Balance at Posting Date" + "Bank Account Statement"."Total Pos. Diff. at Posting")
            {
            }
            column(Ending_G_L_BalanceCaption; BankAccountBalanceLbl)
            {
            }
            column(Ending_GL_Balance; "Bank Account Statement"."G/L Balance at Posting Date" + "Bank Account Statement"."Total Pos. Diff. at Posting" + "Bank Account Statement"."Total Neg. Diff. at Posting")
            {
            }
            column(Currency_CodeCaption; CurrencyCodeCaption)
            {
            }
            column(Currency_Code; CurrencyCode)
            {
            }
            column(Statement_BalanceCaption; Statement_BalanceCaptionLbl)
            {
            }
            column(Outstanding_BankTransactionsCaption; Outstanding_BankTransactionsCaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___TotalOutstdBankTransactions; "Bank Account Statement"."Outstd. Transact. at Posting")
            {
            }
            column(Statement_Subtotal; "Bank Account Statement"."Statement Ending Balance" + "Bank Account Statement"."Outstd. Transact. at Posting")
            {
            }
            column(Outstanding_PaymentsCaption; Outstanding_PaymentsCaptionLbl)
            {
            }
            column(Bank_Acc__Reconciliation___TotalOutstdPayments; "Bank Account Statement"."Outstd. Payments at Posting")
            {
            }
            column(Ending_BalanceCaption; BankAccountBalanceLbl)
            {
            }
            column(Adjusted_Statement_Ending_Balance; "Bank Account Statement"."Statement Ending Balance" + "Bank Account Statement"."Outstd. Payments at Posting" + "Bank Account Statement"."Outstd. Transact. at Posting")
            {
            }
            column(Amt_BankAccStmtLineStmt; "Bank Account Statement Line"."Statement Amount")
            {
            }
            column(AppliedAmt_BankAccStmtLine; "Bank Account Statement Line"."Applied Amount")
            {
            }
            column(BankAccNo_BankAccStmt; "Bank Account No.")
            {
            }
            column(BankAccStmtCapt; BankAccStmtCaptLbl)
            {
            }
            column(CurrReportPAGENOCapt; CurrReportPAGENOCaptLbl)
            {
            }
            column(BnkAccStmtLinTrstnDteCapt; BnkAccStmtLinTrstnDteCaptLbl)
            {
            }
            column(BnkAcStmtLinValDteCapt; BnkAcStmtLinValDteCaptLbl)
            {
            }
            column(GLBalanceCaption; GLBalanceCaptionLbl)
            {
            }
            dataitem("Bank Account Statement Line"; "Bank Account Statement Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Statement Line No.");
                column(TrnsctnDte_BnkAcStmtLin; Format("Transaction Date"))
                {
                }
                column(Type_BankAccStmtLine; Type)
                {
                    IncludeCaption = true;
                }
                column(LineDocNo_BankAccStmt; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(AppliedEntr_BankAccStmtLine; "Applied Entries")
                {
                    IncludeCaption = true;
                }
                column(Amt1_BankAccStmtLineStmt; "Statement Amount")
                {
                    IncludeCaption = true;
                }
                column(AppliedAmt1_BankAccStmtLine; "Applied Amount")
                {
                    IncludeCaption = true;
                }
                column(Desc_BankAccStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(ValueDate_BankAccStmtLine; Format("Value Date"))
                {
                }
            }
            trigger OnAfterGetRecord()
            var
                BankAcc: Record "Bank Account";
            begin
                if BankAcc.Get("Bank Account Statement"."Bank Account No.") then begin
                    CurrencyCode := BankAcc."Currency Code";
                    CurrencyCodeCaption := BankAcc.FieldCaption("Currency Code");
                end;
                G_L_BalanceCaptionTxt := G_L_BalanceCaptionLbl;
                if "Bank Account Statement"."Statement Date" <> 0D then
                    G_L_BalanceCaptionTxt := G_L_BalanceCaptionTxt + AtLbl + format("Statement Date");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        TotalCaption = 'Total';
    }

    trigger OnPreReport()
    begin
        BankAccStmtFilter := "Bank Account Statement".GetFilters;
    end;

    var
        BankAccStmtFilter: Text;
        BankAccStmtCaptLbl: Label 'Bank Account Statement';
        CurrReportPAGENOCaptLbl: Label 'Page';
        BnkAccStmtLinTrstnDteCaptLbl: Label 'Transaction Date';
        BnkAcStmtLinValDteCaptLbl: Label 'Value Date';
        GLBalanceCaptionLbl: Label 'G/L Balance';
        Bank_Acc__Reconciliation___Statement_Date_CaptionLbl: Label 'Statement Date';
        Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl: Label 'Balance Last Statement';
        Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl: Label 'Statement Ending Balance';
        G_L_BalanceCaptionTxt: Text;
        G_L_BalanceCaptionLbl: Label 'G/L Balance';
        AtLbl: Label ' at ', Comment = 'used to build the construct a string like balance at 31-12-2020';
        Subtotal_CaptionLbl: Label 'Subtotal';
        BankAccountBalanceLbl: Label 'Bank Account Balance';
        CurrencyCodeCaption: Text;
        Statement_BalanceCaptionLbl: Label 'Statement Balance';
        Outstanding_BankTransactionsCaptionLbl: Label 'Outstanding Bank Transactions';
        Outstanding_PaymentsCaptionLbl: Label 'Outstanding Checks';
        CurrencyCode: Code[20];
}

