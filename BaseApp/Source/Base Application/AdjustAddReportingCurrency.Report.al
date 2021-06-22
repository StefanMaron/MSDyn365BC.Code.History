report 86 "Adjust Add. Reporting Currency"
{
    Caption = 'Adjust Add. Reporting Currency';
    Permissions = TableData "G/L Entry" = im,
                  TableData "Item Ledger Entry" = m,
                  TableData "G/L Register" = im,
                  TableData "Job Ledger Entry" = m,
                  TableData "VAT Entry" = m,
                  TableData "Dimension Set ID Filter Line" = imd,
                  TableData "Value Entry" = m;
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = SORTING(Type, Closed) WHERE(Type = FILTER(Purchase .. Sale));

            trigger OnAfterGetRecord()
            begin
                VATEntryCount := VATEntryCount + VATEntryStep;
                if VATEntryOldCount div 100000 <> VATEntryCount div 100000 then begin
                    Window.Update(1, VATEntryCount div 100000);
                    VATEntryOldCount := VATEntryCount;
                end;

                "Additional-Currency Amount" := ExchangeAmtLCYToFCY("Posting Date", Amount, false);
                "Additional-Currency Base" := ExchangeAmtLCYToFCY("Posting Date", Base, false);
                "Add.-Currency Unrealized Amt." := ExchangeAmtLCYToFCY("Posting Date", "Unrealized Amount", false);
                "Add.-Currency Unrealized Base" := ExchangeAmtLCYToFCY("Posting Date", "Unrealized Base", false);
                "Add.-Curr. Rem. Unreal. Amount" := ExchangeAmtLCYToFCY("Posting Date", "Remaining Unrealized Amount", false);
                "Add.-Curr. Rem. Unreal. Base" := ExchangeAmtLCYToFCY("Posting Date", "Remaining Unrealized Base", false);
                Modify;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
            end;

            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                Window.Open(
                  Text002);
                if Count > 0 then
                    VATEntryStep := 10000 * 100000 div Count;

                GLSetup.Get();
                if not GLSetup."Unrealized VAT" then
                    SetRange(Closed, false);
            end;
        }
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = SORTING("Entry No.");

            trigger OnAfterGetRecord()
            var
                GLAccNo: Code[20];
            begin
                if OldGLEntry."Posting Date" < "Posting Date" then begin
                    Window.Update(1, "Posting Date");
                    OldGLEntry := "G/L Entry";
                end;
                "Additional-Currency Amount" := ExchangeAmtLCYToFCY("Posting Date", Amount, false);
                if "Debit Amount" <> 0 then begin
                    "Add.-Currency Debit Amount" := "Additional-Currency Amount";
                    "Add.-Currency Credit Amount" := 0;
                end else begin
                    "Add.-Currency Debit Amount" := 0;
                    "Add.-Currency Credit Amount" := -"Additional-Currency Amount";
                end;
                Modify;

                TotalAddCurrAmount := TotalAddCurrAmount + "Additional-Currency Amount";
                TotalAmount := TotalAmount + Amount;
                if TotalAmount = 0 then
                    if TotalAddCurrAmount <> 0 then begin
                        if TotalAddCurrAmount < 0 then
                            GLAccNo := Currency."Residual Losses Account"
                        else
                            GLAccNo := Currency."Residual Gains Account";
                        InsertGLEntry(
                          "Posting Date", "Document Date", "Document Type", "Document No.", GLAccNo,
                          "Journal Batch Name", "Reason Code", -TotalAddCurrAmount);
                        TotalAddCurrAmount := 0;
                    end;

                if "Entry No." = LastEntryNo then
                    CurrReport.Break();

                if "Posting Date" = ClosingDate("Posting Date") then begin
                    TmpCloseIncomeStatementBuffer."Closing Date" := "Posting Date";
                    TmpCloseIncomeStatementBuffer."G/L Account No." := "G/L Account No.";
                    if TmpCloseIncomeStatementBuffer.Insert() then;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if TmpCloseIncomeStatementBuffer.Find('-') then
                    repeat
                        if IsAccountingPeriodClosingDate(
                             TmpCloseIncomeStatementBuffer."Closing Date")
                        then begin
                            CheckCombination(TmpCloseIncomeStatementBuffer);

                            Clear(TmpCloseIncomeStatementBuffer3);
                            TmpCloseIncomeStatementBuffer3."Closing Date" := "Posting Date";
                            TmpCloseIncomeStatementBuffer3."G/L Account No." := Currency."Residual Gains Account";
                            if TmpCloseIncomeStatementBuffer3.Insert() then;
                            TmpCloseIncomeStatementBuffer3."Closing Date" := "Posting Date";
                            TmpCloseIncomeStatementBuffer3."G/L Account No." := Currency."Residual Losses Account";
                            if TmpCloseIncomeStatementBuffer3.Insert() then;
                        end;
                    until TmpCloseIncomeStatementBuffer.Next = 0;

                if TmpCloseIncomeStatementBuffer3.Find('-') then
                    repeat
                        CheckCombination(TmpCloseIncomeStatementBuffer3);
                    until TmpCloseIncomeStatementBuffer3.Next = 0;

                if GLReg."To Entry No." <> 0 then
                    GLReg.Insert();
                Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text003 +
                  Text004);
            end;
        }
        dataitem("Value Entry"; "Value Entry")
        {
            DataItemTableView = SORTING("Item No.");

            trigger OnAfterGetRecord()
            var
                ItemLedgerEntry: Record "Item Ledger Entry";
                PostingDate: Date;
            begin
                if OldValueEntry."Item No." <> "Item No." then begin
                    Window.Update(1, "Item No.");
                    OldValueEntry := "Value Entry";
                end;

                if "Entry Type" = "Entry Type"::Revaluation then begin
                    ItemLedgerEntry.Get("Item Ledger Entry No.");
                    PostingDate := ItemLedgerEntry."Posting Date";
                end else
                    PostingDate := "Posting Date";

                "Cost per Unit (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost per Unit", true);
                "Cost Amount (Actual) (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Amount (Actual)", false);
                "Cost Amount (Expected) (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Amount (Expected)", false);
                "Cost Amount (Non-Invtbl.)(ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Amount (Non-Invtbl.)", false);
                "Cost Posted to G/L (ACY)" := ExchangeAmtLCYToFCY(PostingDate, "Cost Posted to G/L", false);

                Modify;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text011 +
                  Text006);
            end;
        }
        dataitem("Job Ledger Entry"; "Job Ledger Entry")
        {
            DataItemTableView = SORTING("Job No.", "Posting Date");

            trigger OnAfterGetRecord()
            begin
                if OldJobLedgEntry."Job No." <> "Job No." then begin
                    Window.Update(1, "Job No.");
                    OldJobLedgEntry := "Job Ledger Entry";
                end;

                "Additional-Currency Total Cost" := ExchangeAmtLCYToFCY("Posting Date", "Total Cost (LCY)", false);
                "Add.-Currency Total Price" := ExchangeAmtLCYToFCY("Posting Date", "Total Price (LCY)", false);
                Modify;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text007 +
                  Text008);
            end;
        }
        dataitem("Prod. Order Line"; "Prod. Order Line")
        {
            DataItemTableView = SORTING(Status, "Prod. Order No.", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if OldProdOrderLine."Prod. Order No." <> "Prod. Order No." then begin
                    Window.Update(1, "Prod. Order No.");
                    OldProdOrderLine := "Prod. Order Line";
                end;

                "Cost Amount (ACY)" := ExchangeAmtLCYToFCY(WorkDate, "Cost Amount", false);
                "Unit Cost (ACY)" := ExchangeAmtLCYToFCY(WorkDate, "Unit Cost", true);
                Modify;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text99000004 +
                  Text99000002);
            end;
        }
        dataitem("Cost Entry"; "Cost Entry")
        {

            trigger OnAfterGetRecord()
            begin
                if OldCostEntry."Posting Date" < "Posting Date" then begin
                    Window.Update(1, "Posting Date");
                    OldCostEntry := "Cost Entry";
                end;
                "Additional-Currency Amount" := ExchangeAmtLCYToFCY("Posting Date", Amount, false);
                if "Debit Amount" <> 0 then begin
                    "Add.-Currency Debit Amount" := "Additional-Currency Amount";
                    "Add.-Currency Credit Amount" := 0;
                end else begin
                    "Add.-Currency Debit Amount" := 0;
                    "Add.-Currency Credit Amount" := -"Additional-Currency Amount";
                end;
                Modify;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text012 +
                  Text004);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("GLSetup.""Additional Reporting Currency"""; GLSetup."Additional Reporting Currency")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Additional Reporting Currency';
                        Editable = true;
                        ToolTip = 'Specifies the currency code from the Additional Reporting Currency field in the General Ledger Setup window.';

                        trigger OnAssistEdit()
                        begin
                            ChangeExchangeRate.SetParameter(GLSetup."Additional Reporting Currency", CurrencyFactor, WorkDate);
                            if ChangeExchangeRate.RunModal = ACTION::OK then
                                CurrencyFactor := ChangeExchangeRate.GetParameter;
                            Clear(ChangeExchangeRate);
                        end;

                        trigger OnValidate()
                        begin
                            GLSetup := GLSetup2;
                        end;
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies a document number that will be copied to rounding entries if another document number does not apply. The batch job creates these rounding entries.';
                    }
                    field(RetainedEarningsAcc; RetainedEarningsGLAcc."No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Retained Earnings Acc.';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the retained earnings account that the batch job posts to. This account should be the same as the account that is used by the Close Income Statement batch job.';

                        trigger OnValidate()
                        begin
                            if RetainedEarningsGLAcc."No." <> '' then begin
                                RetainedEarningsGLAcc.Find;
                                RetainedEarningsGLAcc.CheckGLAcc;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.TestField("Additional Reporting Currency");
            GLSetup2 := GLSetup;
            CurrencyFactor := CurrExchRate.ExchangeRate(WorkDate, GLSetup."Additional Reporting Currency");
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if GLSetup."Additional Reporting Currency" = '' then
            GLSetup.Get();
    end;

    trigger OnPostReport()
    begin
        ReportIsExecuted := true;
    end;

    trigger OnPreReport()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Currency.Get(GLSetup."Additional Reporting Currency");
        Currency.TestField("Amount Rounding Precision");
        Currency.TestField("Unit-Amount Rounding Precision");
        Currency.TestField("Residual Gains Account");
        ResidualGLAcc.Get(Currency."Residual Gains Account");
        ResidualGLAcc.TestField(Blocked, false);
        ResidualGLAcc.TestField("Account Type", ResidualGLAcc."Account Type"::Posting);
        Currency.TestField("Residual Losses Account");
        ResidualGLAcc.Get(Currency."Residual Losses Account");
        ResidualGLAcc.TestField(Blocked, false);
        ResidualGLAcc.TestField("Account Type", ResidualGLAcc."Account Type"::Posting);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Adjust Add. Reporting Currency");

        if DocumentNo = '' then
            Error(
              Text000, GenJnlLine.FieldCaption("Document No."));
        if RetainedEarningsGLAcc."No." = '' then
            Error(Text001);
    end;

    var
        Text000: Label 'Enter a %1.';
        Text001: Label 'Enter Retained Earnings Account No.';
        Text002: Label 'Processing VAT Entries @1@@@@@@@@@@\';
        Text003: Label 'Processing G/L Entries...\\';
        Text004: Label 'Posting Date #1##########\';
        Text006: Label 'Item No. #1##########\';
        Text007: Label 'Processing Job Ledger Entries...\\';
        Text008: Label 'Job No. #1##########\';
        Text010: Label 'Residual caused by rounding of %1';
        Text011: Label 'Processing Value Entries...\\';
        Text012: Label 'Processing Cost Entries...\\';
        Text99000002: Label 'Prod. Order No. #1##########\';
        Text99000004: Label 'Processing Finished Prod. Order Lines...\\';
        GLSetup: Record "General Ledger Setup";
        GLSetup2: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        OldGLEntry: Record "G/L Entry";
        OldValueEntry: Record "Value Entry";
        OldJobLedgEntry: Record "Job Ledger Entry";
        OldProdOrderLine: Record "Prod. Order Line";
        OldCostEntry: Record "Cost Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLEntry2: Record "G/L Entry";
        GLReg: Record "G/L Register";
        TmpCloseIncomeStatementBuffer: Record "Close Income Statement Buffer" temporary;
        TmpCloseIncomeStatementBuffer3: Record "Close Income Statement Buffer" temporary;
        GLEntry3: Record "G/L Entry";
        RetainedEarningsGLAcc: Record "G/L Account";
        ResidualGLAcc: Record "G/L Account";
        ChangeExchangeRate: Page "Change Exchange Rate";
        Window: Dialog;
        CurrencyFactor: Decimal;
        TotalAddCurrAmount: Decimal;
        TotalAmount: Decimal;
        NextEntryNo: Integer;
        LastEntryNo: Integer;
        NextTransactionNo: Integer;
        FiscalYearStartDate: Date;
        ReportIsExecuted: Boolean;
        VATEntryCount: Integer;
        VATEntryOldCount: Integer;
        VATEntryStep: Integer;
        FiscalYearStartDate2: Date;
        FiscalYearEndDate2: Date;
        LastDateChecked: Date;
        LastFiscalYearStartDate: Date;
        LastFiscalYearEndDate: Date;
        LastIsAccPeriodClosingDate: Boolean;
        DocumentNo: Code[20];

    procedure SetAddCurr(AddCurr: Code[10])
    begin
        GLSetup."Additional Reporting Currency" := AddCurr;
    end;

    procedure IsExecuted(): Boolean
    begin
        exit(ReportIsExecuted);
    end;

    local procedure ExchangeAmtLCYToFCY(PostingDate: Date; Amount: Decimal; IsUnitAmount: Boolean): Decimal
    var
        AmtRndgPrec: Decimal;
    begin
        if IsUnitAmount then
            AmtRndgPrec := Currency."Unit-Amount Rounding Precision"
        else
            AmtRndgPrec := Currency."Amount Rounding Precision";
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              PostingDate, GLSetup."Additional Reporting Currency", Amount,
              CurrExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency")),
            AmtRndgPrec));
    end;

    procedure IsAccountingPeriodClosingDate(Date: Date): Boolean
    var
        AccountingPeriod: Record "Accounting Period";
        OK: Boolean;
    begin
        if AccountingPeriod.IsEmpty then
            exit(false);

        if Date <> LastDateChecked then begin
            OK := AccountingPeriod.Get(NormalDate(Date) + 1);
            if OK then
                OK := AccountingPeriod."New Fiscal Year";
            if OK then begin
                LastFiscalYearEndDate := ClosingDate(Date);
                AccountingPeriod.SetRange("New Fiscal Year", true);
                OK := AccountingPeriod.Find('<');
                LastFiscalYearStartDate := AccountingPeriod."Starting Date";
                LastIsAccPeriodClosingDate := true;
            end else begin
                LastIsAccPeriodClosingDate := false;
                LastFiscalYearStartDate := 0D;
                LastFiscalYearEndDate := 0D;
            end;
        end;
        FiscalYearStartDate2 := LastFiscalYearStartDate;
        FiscalYearEndDate2 := LastFiscalYearEndDate;
        exit(LastIsAccPeriodClosingDate);
    end;

    procedure CheckCombination(CloseIncomeStmtBuffer2: Record "Close Income Statement Buffer")
    begin
        Clear(GLEntry3);
        GLEntry3.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry3.SetRange("G/L Account No.", CloseIncomeStmtBuffer2."G/L Account No.");
        GLEntry3.SetRange("Posting Date", FiscalYearStartDate2, FiscalYearEndDate2);

        GLEntry3.CalcSums(Amount);
        if GLEntry3.Amount = 0 then begin
            GLEntry3.CalcSums("Additional-Currency Amount");
            if GLEntry3."Additional-Currency Amount" <> 0 then begin
                InsertGLEntry(
                  FiscalYearEndDate2, FiscalYearEndDate2, GLEntry3."Document Type"::" ", DocumentNo,
                  CloseIncomeStmtBuffer2."G/L Account No.",
                  '', '', -GLEntry3."Additional-Currency Amount");

                InsertGLEntry(
                  FiscalYearEndDate2, FiscalYearEndDate2, GLEntry3."Document Type"::" ", DocumentNo,
                  RetainedEarningsGLAcc."No.",
                  '', '', GLEntry3."Additional-Currency Amount");
            end;
        end;
    end;

    procedure InsertGLEntry(PostingDate: Date; DocumentDate: Date; DocumentType: Integer; DocumentNo: Code[20]; GLAccountNo: Code[20]; JnlBatchName: Code[10]; ReasonCode: Code[10]; AddCurrAmount: Decimal)
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        if NextEntryNo = 0 then begin
            GLEntry2.GetLastEntry(LastEntryNo, NextTransactionNo);
            NextEntryNo := LastEntryNo + 1;
            NextTransactionNo += 1;

            FiscalYearStartDate := AccountingPeriodMgt.GetPeriodStartingDate;

            GLReg.LockTable();
            if GLReg.FindLast then;
            GLReg.Initialize(GLReg."No." + 1, 0, 0, SourceCodeSetup."Adjust Add. Reporting Currency", JnlBatchName, '');
        end else
            NextEntryNo := NextEntryNo + 1;

        GLEntry2.Init();
        GLEntry2."Posting Date" := PostingDate;
        GLEntry2."Document Date" := DocumentDate;
        GLEntry2."Document Type" := DocumentType;
        GLEntry2."Document No." := DocumentNo;
        GLEntry2."External Document No." := '';
        GLEntry2.Description :=
          CopyStr(
            StrSubstNo(
              Text010,
              GLEntry2.FieldCaption("Additional-Currency Amount")),
            1, MaxStrLen(GLEntry2.Description));
        GLEntry2."Source Code" := SourceCodeSetup."Adjust Add. Reporting Currency";
        GLEntry2."Source Type" := 0;
        GLEntry2."Source No." := '';
        GLEntry2."Job No." := '';
        GLEntry2.Quantity := 0;
        GLEntry2."Journal Batch Name" := JnlBatchName;
        GLEntry2."Reason Code" := ReasonCode;
        GLEntry2."Entry No." := NextEntryNo;
        GLEntry2."Transaction No." := NextTransactionNo;
        GLEntry2."G/L Account No." := GLAccountNo;
        GLEntry2.Amount := 0;
        GLEntry2."User ID" := UserId;
        GLEntry2."No. Series" := '';
        GLEntry2."System-Created Entry" := true;
        GLEntry2."Prior-Year Entry" := GLEntry2."Posting Date" < FiscalYearStartDate;
        GLEntry2."Additional-Currency Amount" := AddCurrAmount;
        if GLEntry2."Additional-Currency Amount" > 0 then begin
            GLEntry2."Add.-Currency Debit Amount" := GLEntry2."Additional-Currency Amount";
            GLEntry2."Add.-Currency Credit Amount" := 0;
        end else begin
            GLEntry2."Add.-Currency Debit Amount" := 0;
            GLEntry2."Add.-Currency Credit Amount" := -GLEntry2."Additional-Currency Amount";
        end;
        GLEntry2.Insert();

        GLReg."To Entry No." := GLEntry2."Entry No.";
    end;

    procedure InitializeRequest(NewDocumentNo: Code[20]; NewRetainedEarningsGLAccNo: Code[20])
    begin
        DocumentNo := NewDocumentNo;
        RetainedEarningsGLAcc."No." := NewRetainedEarningsGLAccNo;
        GLSetup2 := GLSetup;
        CurrencyFactor := CurrExchRate.ExchangeRate(WorkDate, GLSetup."Additional Reporting Currency");
    end;
}

