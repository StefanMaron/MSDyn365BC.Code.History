report 1408 "Bank Acc. Recon. - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BankAccReconTest.rdlc';
    Caption = 'Bank Acc. Recon. - Test';

    dataset
    {
        dataitem("Bank Acc. Reconciliation"; "Bank Acc. Reconciliation")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(Bank_Acc__Reconciliation_Bank_Account_No_; "Bank Account No.")
            {
            }
            column(Bank_Acc__Reconciliation_Statement_No_; "Statement No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Bank_Acc__Reconciliation__TABLECAPTION___________BankAccReconFilter; "Bank Acc. Reconciliation".TableCaption + ': ' + BankAccReconFilter)
                {
                }
                column(BankAccReconFilter; BankAccReconFilter)
                {
                }
                column(Bank_Acc__Reconciliation___Bank_Account_No____________Bank_Acc__Reconciliation___Statement_No__; "Bank Acc. Reconciliation"."Bank Account No." + ' ' + "Bank Acc. Reconciliation"."Statement No.")
                {
                }
                column(Bank_Acc__Reconciliation___Balance_Last_Statement_; "Bank Acc. Reconciliation"."Balance Last Statement")
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Date_; Format("Bank Acc. Reconciliation"."Statement Date"))
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Ending_Balance_; "Bank Acc. Reconciliation"."Statement Ending Balance")
                {
                }
                column(Bank_Acc__Reconciliation___TotalBalOnBankAccount; BankAcc."Balance at Date")
                {
                }
                column(Bank_Acc__Reconciliation___TotalBalOnBankAccountLCY; BankAcc."Balance at Date (LCY)")
                {
                }
                column(Bank_Acc__Reconciliation___TotalPositiveAdjustments; TotalPositiveDifference)
                {
                }
                column(Bank_Acc__Reconciliation___TotalNegativeAdjustments; TotalNegativeDifference)
                {
                }
                column(Bank_Acc__Reconciliation___TotalOutstdBankTransactions; TotalOutstdBankTransac)
                {
                }
                column(Bank_Acc__Reconciliation___TotalOutstdPayments; TotalOutstdPayments)
                {
                }
                column(ErrorLabel; ErrorLabel)
                {
                }
                column(HeaderError1; HeaderError1)
                {
                }
                column(HeaderError2; HeaderError2)
                {
                }
                column(Bank_Account_Statement___TestCaption; Bank_Account_Statement___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Bank_Acc__Reconciliation___Balance_Last_Statement_Caption; Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl)
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Date_Caption; Bank_Acc__Reconciliation___Statement_Date_CaptionLbl)
                {
                }
                column(Bank_Acc__Reconciliation___Statement_Ending_Balance_Caption; Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl)
                {
                }
                column(G_L_BalanceCaption; G_L_BalanceCaptionLbl)
                {
                }
                column(G_L_Balance_LCYCaption; G_L_BalanceLCYCaptionLbl)
                {
                }
                column(Ending_G_L_BalanceCaption; Ending_G_L_BalanceCaptionLbl)
                {
                }
                column(Positive_AdjustmentsCaption; Positive_AdjustmentsCaptionLbl)
                {
                }
                column(Negative_AdjustmentsCaption; Negative_AdjustmentsCaptionLbl)
                {
                }
                column(Subtotal_Caption; Subtotal_CaptionLbl)
                {
                }
                column(Difference_Caption; Difference_CaptionLbl)
                {
                }
                column(Ending_BalanceCaption; Ending_BalanceCaptionLbl)
                {
                }
                column(Outstanding_BankTransactionsCaption; Outstanding_BankTransactionsCaptionLbl)
                {
                }
                column(Total_Outstanding_BankTransactionsCaption; Total_Outstanding_BankTransactionsCaptionLbl)
                {
                }
                column(Outstanding_PaymentsCaption; Outstanding_PaymentsCaptionLbl)
                {
                }
                column(Total_Outstanding_PaymentsCaption; Total_Outstanding_PaymentsCaptionLbl)
                {
                }
                column(Print_Outstanding_Transactions; PrintOutstandingTransactions)
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
                column(GL_Subtotal; (BankAcc."Balance at Date" + TotalPositiveDifference))
                {
                }
                column(Ending_GL_Balance; EndingGLBalance)
                {
                }
                column(Statement_Subtotal; ("Bank Acc. Reconciliation"."Statement Ending Balance" + TotalOutstdBankTransac))
                {
                }
                column(Adjusted_Statement_Ending_Balance; EndingStatementBalance)
                {
                }
                column(Difference; "Bank Acc. Reconciliation"."Total Balance on Bank Account" + TotalPositiveDifference + TotalNegativeDifference - "Bank Acc. Reconciliation"."Statement Ending Balance" - TotalOutstdBankTransac - TotalOutstdPayments)
                {
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem("Bank Acc. Reconciliation Line"; "Bank Acc. Reconciliation Line")
                {
                    DataItemLink = "Statement Type" = FIELD("Statement Type"), "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                    DataItemLinkReference = "Bank Acc. Reconciliation";
                    DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Statement Line No.");
                    column(Bank_Acc__Reconciliation_Line__Transaction_Date_; Format("Transaction Date"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Description; Description)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Value_Date_; Format("Value Date"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Entries_; "Applied Entries")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Amount_; "Applied Amount")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Statement_Amount_; "Statement Amount")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Type; Type)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Difference; Difference)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Amount__Control25; "Applied Amount")
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_Difference_Control29; Difference)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Transaction_Date_Caption; Bank_Acc__Reconciliation_Line__Transaction_Date_CaptionLbl)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Value_Date_Caption; Bank_Acc__Reconciliation_Line__Value_Date_CaptionLbl)
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Entries_Caption; FieldCaption("Applied Entries"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Statement_Amount_Caption; FieldCaption("Statement Amount"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line__Applied_Amount_Caption; FieldCaption("Applied Amount"))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_TypeCaption; FieldCaption(Type))
                    {
                    }
                    column(Bank_Acc__Reconciliation_Line_DifferenceCaption; FieldCaption(Difference))
                    {
                    }
                    column(TotalsCaption; TotalsCaptionLbl)
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(ErrorText_Number__Control97; ErrorText[Number])
                        {
                        }
                        column(ErrorText_Number__Control97Caption; ErrorText_Number__Control97CaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        TableID: array[10] of Integer;
                        No: array[10] of Code[20];
                    begin
                        AppliedAmount := 0;
                        ErrorLabel := 1;

                        case Type of
                            Type::"Bank Account Ledger Entry":
                                begin
                                    if "Bank Acc. Reconciliation"."Statement Type" =
                                       "Bank Acc. Reconciliation"."Statement Type"::"Bank Reconciliation"
                                    then begin
                                        BankAccLedgEntry.SetFilterBankAccNoOpen("Bank Account No.");
                                        BankAccLedgEntry.SetRange(
                                          "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
                                        BankAccLedgEntry.SetRange("Statement No.", "Statement No.");
                                        BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                                        if BankAccLedgEntry.Find('-') then
                                            repeat
                                                AppliedAmount := AppliedAmount + BankAccLedgEntry.Amount;
                                                VerifyCheckLedgerEntry(BankAccLedgEntry);
                                            until BankAccLedgEntry.Next = 0;
                                    end else
                                        AppliedAmount := GetPaymentReconciliationAppliedAmount("Bank Acc. Reconciliation Line");
                                end;
                            Type::"Check Ledger Entry":
                                begin
                                    if "Bank Acc. Reconciliation"."Statement Type" =
                                       "Bank Acc. Reconciliation"."Statement Type"::"Bank Reconciliation"
                                    then begin
                                        CheckLedgEntry.SetFilterBankAccNoOpen("Bank Account No.");
                                        CheckLedgEntry.SetRange(
                                          "Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
                                        CheckLedgEntry.SetRange("Statement No.", "Statement No.");
                                        CheckLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                                        if CheckLedgEntry.Find('-') then
                                            repeat
                                                AppliedAmount := AppliedAmount - CheckLedgEntry.Amount;
                                                BankAccLedgEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
                                                if not BankAccLedgEntry.Open then
                                                    AddError(
                                                      StrSubstNo(
                                                        TableValueWrongErr,
                                                        BankAccLedgEntry.FieldCaption(Open), true,
                                                        BankAccLedgEntry.TableCaption, BankAccLedgEntry."Entry No."));
                                                if BankAccLedgEntry."Statement Status" <> BankAccLedgEntry."Statement Status"::"Check Entry Applied" then
                                                    AddError(
                                                      StrSubstNo(
                                                        TableValueWrongErr,
                                                        BankAccLedgEntry.FieldCaption("Statement Status"),
                                                        BankAccLedgEntry."Statement Status"::"Check Entry Applied",
                                                        BankAccLedgEntry.TableCaption, BankAccLedgEntry."Entry No."));
                                                if BankAccLedgEntry."Statement No." <> '' then
                                                    AddError(
                                                      StrSubstNo(
                                                        TableValueWrongErr,
                                                        BankAccLedgEntry.FieldCaption("Statement No."), '',
                                                        BankAccLedgEntry.TableCaption, BankAccLedgEntry."Entry No."));
                                                if BankAccLedgEntry."Statement Line No." <> 0 then
                                                    AddError(
                                                      StrSubstNo(
                                                        TableValueWrongErr,
                                                        BankAccLedgEntry.FieldCaption("Statement Line No."), 0,
                                                        BankAccLedgEntry.TableCaption, BankAccLedgEntry."Entry No."));
                                            until CheckLedgEntry.Next = 0;
                                    end else
                                        AppliedAmount := GetPaymentReconciliationAppliedAmount("Bank Acc. Reconciliation Line");
                                end;
                            Type::Difference:
                                if "Bank Acc. Reconciliation"."Statement Type" =
                                   "Bank Acc. Reconciliation"."Statement Type"::"Payment Application"
                                then begin
                                    AppliedAmount := "Applied Amount";
                                    TotalDiff := TotalDiff + ("Statement Amount" - "Applied Amount");
                                end else
                                    TotalDiff := TotalDiff + "Statement Amount";
                        end;
                        if "Applied Amount" <> AppliedAmount then
                            AddError(StrSubstNo(AmountWrongErr, FieldCaption("Applied Amount"), AppliedAmount));

                        if not DimensionManagement.CheckDimIDComb("Dimension Set ID") then
                            AddError(DimensionManagement.GetDimCombErr);

                        TableID[1] := DimensionManagement.TypeToTableID1("Account Type");
                        No[1] := "Account No.";
                        if not DimensionManagement.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                            AddError(DimensionManagement.GetDimValuePostingErr);

                        TotalAmount := TotalAmount + "Statement Amount";
                        TotalAppliedAmount := TotalAppliedAmount + AppliedAmount;
                    end;

                    trigger OnPostDataItem()
                    begin
                        if TotalAmount <> TotalAppliedAmount + TotalDiff then begin
                            AddError(ApplicationErr);
                            FooterError1 := ApplicationErr;
                        end;

                        if BankAccReconLine.Difference <> TotalDiff then begin
                            AddError(
                              StrSubstNo(
                                TotalDifferenceErr, BankAccReconLine.Difference, TotalDiff));
                            FooterError2 := StrSubstNo(TotalDifferenceErr, BankAccReconLine.Difference, TotalDiff);
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalAmount := 0;
                        TotalAppliedAmount := 0;
                        TotalDiff := 0;
                        ErrorLabel := 1;
                    end;
                }
                dataitem(FooterErrorCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(FooterError1; FooterError1)
                    {
                    }
                    column(FooterError2; FooterError2)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem(OutstandingBankTransaction; "Outstanding Bank Transaction")
                {
                    UseTemporary = true;
                    column(Outstd_Bank_Transac_Amount; Amount)
                    {
                    }
                    column(Outstd_Bank_Transac_EntryNo_; "Entry No.")
                    {
                    }
                    column(Outstd_Bank_Transac_Posting_Date; Format("Posting Date"))
                    {
                    }
                    column(Outstd_Bank_Transac_Doc_Type; "Document Type")
                    {
                    }
                    column(Outstd_Bank_Transac_Doc_No_; "Document No.")
                    {
                    }
                    column(Outstd_Bank_Transac_Bank_Acc_No_; "Bank Account No.")
                    {
                    }
                    column(Outstd_Bank_Transac_Description; Description)
                    {
                    }
                    column(Outstd_Bank_Transac_Type; Type)
                    {
                    }
                    column(Outstd_Bank_Transac_Applied; Applied)
                    {
                    }
                }
                dataitem(OutstandingPayment; "Outstanding Bank Transaction")
                {
                    UseTemporary = true;
                    column(Outstd_Payment_Amount; Amount)
                    {
                    }
                    column(Outstd_Payment_Entry_No_; "Entry No.")
                    {
                    }
                    column(Outstd_Payment_Posting_Date; Format("Posting Date"))
                    {
                    }
                    column(Outstd_Payment_Doc_Type; "Document Type")
                    {
                    }
                    column(Outstd_Payment_Doc_No_; "Document No.")
                    {
                    }
                    column(Outstd_Payment_Bank_Acc_No_; "Bank Account No.")
                    {
                    }
                    column(Outstd_Payment_Description; Description)
                    {
                    }
                    column(Outstd_Payment_Type; Type)
                    {
                    }
                    column(Outstd_Payment_Applied; Applied)
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                SetupRecord;
                ErrorLabel := 1;
                OutstandingBankTransaction.DeleteAll;
                OutstandingPayment.DeleteAll;
                CreateOutstandingBankTransactions("Bank Account No.");
                case "Statement Type" of
                    "Statement Type"::"Bank Reconciliation":
                        begin
                            TotalOutstdBankTransac := "Total Outstd Bank Transactions" -
                              ("Total Applied Amount" - "Total Applied Amount Payments");
                            TotalPositiveDifference := "Total Positive Difference";
                            TotalNegativeDifference := "Total Negative Difference";
                        end;
                    "Statement Type"::"Payment Application":
                        begin
                            TotalOutstdBankTransac := "Total Outstd Bank Transactions" -
                              ("Total Applied Amount" - "Total Applied Amount Payments" - "Total Unposted Applied Amount");
                            TotalPositiveDifference := "Total Positive Adjustments";
                            TotalNegativeDifference := "Total Negative Adjustments";
                        end;
                end;
                if "Statement Date" = 0D then
                    AddError(StrSubstNo(StatementDateErr, FieldCaption("Statement Date")));

                BankAccReconLine.FilterBankRecLines("Bank Acc. Reconciliation");
                BankAccReconLine.CalcSums("Statement Amount", Difference);

                if BankAccReconLine."Statement Amount" <> "Statement Ending Balance" - "Balance Last Statement" then begin
                    AddError(
                      StrSubstNo(
                        StatementBalanceErr, FieldCaption("Statement Ending Balance")));
                    HeaderError1 := StrSubstNo(StatementBalanceErr, FieldCaption("Statement Ending Balance"));
                end;

                if BankAcc.Get("Bank Account No.") then begin
                    CurrencyCode := BankAcc."Currency Code";
                    CurrencyCodeCaption := BankAcc.FieldCaption("Currency Code");
                    if BankAcc.Blocked then begin
                        AddError(
                          StrSubstNo(
                            TableValueWrongErr,
                            BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption, "Bank Account No."));
                        HeaderError2 := StrSubstNo(TableValueWrongErr, BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption, "Bank Account No.");
                    end;
                end else begin
                    AddError(
                      StrSubstNo(
                        TableValueMissingErr,
                        BankAcc.TableCaption, "Bank Account No."));
                    HeaderError2 := StrSubstNo(TableValueMissingErr, BankAcc.TableCaption, "Bank Account No.");
                end;
                if "Statement Date" <> 0D then
                    BankAcc.SetFilter("Date Filter", '..%1', "Statement Date");
                BankAcc.CalcFields("Balance at Date", "Balance at Date (LCY)");

                TotalOutstdPayments := "Total Outstd Payments" - "Total Applied Amount Payments";
                EndingGLBalance := BankAcc."Balance at Date" + TotalPositiveDifference + TotalNegativeDifference;
                EndingStatementBalance := "Statement Ending Balance" + TotalOutstdBankTransac + TotalOutstdPayments;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    ShowCaption = false;
                    field(PrintOutstdTransac; PrintOutstandingTransactions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Outstanding Transactions';
                        ToolTip = 'Specifies if the report includes reconciliation lines for outstanding transactions.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        BankAccReconFilter := "Bank Acc. Reconciliation".GetFilters;
    end;

    var
        StatementDateErr: Label '%1 must be specified.', Comment = '%1=Statement Date field caption';
        StatementBalanceErr: Label '%1 is not equal to Total Balance.', Comment = '%1=Statement Ending Balance field caption';
        TableValueWrongErr: Label '%1 must be %2 for %3 %4.', Comment = '%1=field caption;%2=field value;%3=table name caption;%4=field value';
        TableValueMissingErr: Label '%1 %2 does not exist.', Comment = '%1=table name caption;%2=table field name caption';
        AmountWrongErr: Label '%1 must be %2.', Comment = '%1=field name caption;%2=field value';
        ApplicationErr: Label 'Application is wrong.';
        TotalDifferenceErr: Label 'The total difference is %1. It must be %2.', Comment = '%1=field value;%2=field value';
        BankAcc: Record "Bank Account";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        DimensionManagement: Codeunit DimensionManagement;
        AppliedAmount: Decimal;
        TotalAmount: Decimal;
        TotalAppliedAmount: Decimal;
        TotalDiff: Decimal;
        TotalOutstdBankTransac: Decimal;
        TotalOutstdPayments: Decimal;
        EndingGLBalance: Decimal;
        EndingStatementBalance: Decimal;
        TotalPositiveDifference: Decimal;
        TotalNegativeDifference: Decimal;
        BankAccReconFilter: Text;
        ErrorCounter: Integer;
        ErrorText: array[99] of Text[250];
        ErrorLabel: Integer;
        HeaderError1: Text[250];
        HeaderError2: Text[250];
        FooterError1: Text[250];
        FooterError2: Text[250];
        Bank_Account_Statement___TestCaptionLbl: Label 'Bank Account Statement';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bank_Acc__Reconciliation___Balance_Last_Statement_CaptionLbl: Label 'Balance Last Statement';
        Bank_Acc__Reconciliation___Statement_Date_CaptionLbl: Label 'Statement Date';
        Bank_Acc__Reconciliation___Statement_Ending_Balance_CaptionLbl: Label 'Statement Ending Balance';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Bank_Acc__Reconciliation_Line__Transaction_Date_CaptionLbl: Label 'Transaction Date';
        Bank_Acc__Reconciliation_Line__Value_Date_CaptionLbl: Label 'Value Date';
        TotalsCaptionLbl: Label 'Totals';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        Outstanding_BankTransactionsCaptionLbl: Label 'Outstanding Bank Transactions';
        Outstanding_PaymentsCaptionLbl: Label 'Outstanding Payments';
        Total_Outstanding_BankTransactionsCaptionLbl: Label 'Total Outstanding Bank Transactions';
        Total_Outstanding_PaymentsCaptionLbl: Label 'Total Outstanding Payments';
        CurrencyCodeCaption: Text[250];
        PrintOutstandingTransactions: Boolean;
        G_L_BalanceCaptionLbl: Label 'G/L Balance';
        G_L_BalanceLCYCaptionLbl: Label 'G/L Balance (LCY)';
        Ending_G_L_BalanceCaptionLbl: Label 'Ending G/L Balance';
        Positive_AdjustmentsCaptionLbl: Label 'Positive Adjustments';
        Negative_AdjustmentsCaptionLbl: Label 'Negative Adjustments';
        Subtotal_CaptionLbl: Label 'Subtotal';
        Difference_CaptionLbl: Label 'Difference';
        Ending_BalanceCaptionLbl: Label 'Ending Balance';
        CurrencyCode: Code[20];
        Statement_BalanceCaptionLbl: Label 'Statement Balance';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CreateOutstandingBankTransactions(BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        RemainingAmt: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange(Reversed, false);
        if "Bank Acc. Reconciliation"."Statement Type" = "Bank Acc. Reconciliation"."Statement Type"::"Bank Reconciliation" then
            BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Open);
        if BankAccountLedgerEntry.FindSet then
            repeat
                BankAccountLedgerEntry.CalcFields("Check Ledger Entries");
                if BankAccountLedgerEntry."Check Ledger Entries" <> 0 then begin
                    RemainingAmt := BankAccountLedgerEntry.Amount -
                      OutstandingPayment.GetAppliedAmount(BankAccountLedgerEntry."Entry No.");
                    if RemainingAmt <> 0 then
                        OutstandingPayment.CopyFromBankAccLedgerEntry(BankAccountLedgerEntry, OutstandingPayment.Type::"Check Ledger Entry",
                          "Bank Acc. Reconciliation"."Statement Type", "Bank Acc. Reconciliation"."Statement No.", RemainingAmt)
                end else begin
                    RemainingAmt := BankAccountLedgerEntry.Amount -
                      OutstandingBankTransaction.GetAppliedAmount(BankAccountLedgerEntry."Entry No.");
                    if RemainingAmt <> 0 then
                        OutstandingBankTransaction.CopyFromBankAccLedgerEntry(BankAccountLedgerEntry,
                          OutstandingBankTransaction.Type::"Bank Account Ledger Entry",
                          "Bank Acc. Reconciliation"."Statement Type", "Bank Acc. Reconciliation"."Statement No.", RemainingAmt)
                end;
            until BankAccountLedgerEntry.Next = 0;
    end;

    local procedure GetPaymentReconciliationAppliedAmount(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedAmountTemp: Decimal;
    begin
        AppliedPaymentEntry.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", BankAccReconciliationLine."Statement Line No.");
        if AppliedPaymentEntry.FindSet then
            repeat
                if AppliedPaymentEntry."Applies-to Entry No." = 0 then
                    AppliedAmountTemp += AppliedPaymentEntry."Applied Amount"
                else
                    case AppliedPaymentEntry."Account Type" of
                        AppliedPaymentEntry."Account Type"::Customer:
                            begin
                                if CustLedgerEntry.Get(AppliedPaymentEntry."Applies-to Entry No.") then begin
                                    if not CustLedgerEntry.Open then
                                        AddError(
                                          StrSubstNo(
                                            TableValueWrongErr,
                                            CustLedgerEntry.FieldCaption(Open), true,
                                            CustLedgerEntry.TableCaption, CustLedgerEntry."Entry No."));
                                    CustLedgerEntry.CalcFields(Amount);
                                    if Abs(AppliedPaymentEntry."Applied Amount") > Abs(CustLedgerEntry.Amount) then
                                        AddError(StrSubstNo(AmountWrongErr, AppliedPaymentEntry.FieldCaption("Applied Amount"), CustLedgerEntry.Amount));
                                    AppliedAmountTemp += AppliedPaymentEntry."Applied Amount";
                                end else
                                    AddError(
                                      StrSubstNo(
                                        TableValueMissingErr,
                                        CustLedgerEntry.TableCaption,
                                        AppliedPaymentEntry."Applies-to Entry No."))
                            end;
                        AppliedPaymentEntry."Account Type"::Vendor:
                            begin
                                if VendorLedgerEntry.Get(AppliedPaymentEntry."Applies-to Entry No.") then begin
                                    if not VendorLedgerEntry.Open then
                                        AddError(
                                          StrSubstNo(
                                            TableValueWrongErr,
                                            VendorLedgerEntry.FieldCaption(Open), true,
                                            VendorLedgerEntry.TableCaption, VendorLedgerEntry."Entry No."));
                                    VendorLedgerEntry.CalcFields(Amount);
                                    if Abs(AppliedPaymentEntry."Applied Amount") > Abs(VendorLedgerEntry.Amount) then
                                        AddError(StrSubstNo(AmountWrongErr, AppliedPaymentEntry.FieldCaption("Applied Amount"), VendorLedgerEntry.Amount));
                                    AppliedAmountTemp += AppliedPaymentEntry."Applied Amount";
                                end else
                                    AddError(
                                      StrSubstNo(
                                        TableValueMissingErr,
                                        VendorLedgerEntry.TableCaption,
                                        AppliedPaymentEntry."Applies-to Entry No."))
                            end;
                        AppliedPaymentEntry."Account Type"::"Bank Account":
                            begin
                                if BankAccountLedgerEntry.Get(AppliedPaymentEntry."Applies-to Entry No.") then begin
                                    if not BankAccountLedgerEntry.Open then
                                        AddError(
                                          StrSubstNo(
                                            TableValueWrongErr,
                                            BankAccountLedgerEntry.FieldCaption(Open), true,
                                            BankAccountLedgerEntry.TableCaption, BankAccountLedgerEntry."Entry No."));
                                    AppliedAmountTemp += AppliedPaymentEntry."Applied Amount";
                                end else
                                    AddError(
                                      StrSubstNo(
                                        TableValueMissingErr,
                                        BankAccountLedgerEntry.TableCaption,
                                        AppliedPaymentEntry."Applies-to Entry No."))
                            end;
                    end;
            until AppliedPaymentEntry.Next = 0;
        exit(AppliedAmountTemp);
    end;

    local procedure VerifyCheckLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        CheckLedgEntry.Reset;
        CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        CheckLedgEntry.SetRange(Open, true);
        if CheckLedgEntry.FindSet then
            repeat
                if not CheckLedgEntry.Open then
                    AddError(
                      StrSubstNo(
                        TableValueWrongErr,
                        CheckLedgEntry.FieldCaption(Open), true,
                        CheckLedgEntry.TableCaption, CheckLedgEntry."Entry No."));
                if CheckLedgEntry."Statement Status" <> CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied" then
                    AddError(
                      StrSubstNo(
                        TableValueWrongErr,
                        CheckLedgEntry.FieldCaption("Statement Status"),
                        CheckLedgEntry."Statement Status"::"Bank Acc. Entry Applied",
                        CheckLedgEntry.TableCaption, CheckLedgEntry."Entry No."));
                if CheckLedgEntry."Statement No." <> '' then
                    AddError(
                      StrSubstNo(
                        TableValueWrongErr,
                        CheckLedgEntry.FieldCaption("Statement No."), '',
                        CheckLedgEntry.TableCaption, CheckLedgEntry."Entry No."));
                if CheckLedgEntry."Statement Line No." <> 0 then
                    AddError(
                      StrSubstNo(
                        TableValueWrongErr,
                        CheckLedgEntry.FieldCaption("Statement Line No."), 0,
                        CheckLedgEntry.TableCaption, CheckLedgEntry."Entry No."));
            until CheckLedgEntry.Next = 0;
    end;

    local procedure SetupRecord()
    begin
        with "Bank Acc. Reconciliation" do
            CalcFields("Total Balance on Bank Account",
              "Bank Account Balance (LCY)",
              "Total Positive Adjustments",
              "Total Negative Adjustments",
              "Total Outstd Bank Transactions",
              "Total Outstd Payments",
              "Total Applied Amount",
              "Total Applied Amount Payments",
              "Total Unposted Applied Amount",
              "Total Positive Difference",
              "Total Negative Difference");
    end;
}

