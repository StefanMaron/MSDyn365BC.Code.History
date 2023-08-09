codeunit 432 Consolidate
{
    Permissions = TableData "G/L Entry" = rimd;
    TableNo = "Business Unit";

    trigger OnRun()
    var
        PreviousDate: Date;
        i: Integer;
        ShouldClearPreviousConsolidation: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec);

        BusUnit := Rec;
        if NormalDate(EndingDate) - NormalDate(StartingDate) + 1 > ArrayLen(RoundingResiduals) then
            ReportError(StrSubstNo(Text008, ArrayLen(RoundingResiduals)));

        if ("Starting Date" <> 0D) or ("Ending Date" <> 0D) then begin
            if "Starting Date" = 0D then
                ReportError(StrSubstNo(
                    Text033, FieldCaption("Starting Date"),
                    FieldCaption("Ending Date"), "Company Name"));
            if "Ending Date" = 0D then
                ReportError(StrSubstNo(
                    Text033, FieldCaption("Ending Date"),
                    FieldCaption("Starting Date"), "Company Name"));
            if "Starting Date" > "Ending Date" then
                ReportError(StrSubstNo(
                    Text032, FieldCaption("Starting Date"),
                    FieldCaption("Ending Date"), "Company Name"));
        end;

        ConsolidatingClosingDate :=
          (StartingDate = EndingDate) and
          (StartingDate <> NormalDate(StartingDate));
        if (StartingDate <> NormalDate(StartingDate)) and
           (StartingDate <> EndingDate)
        then
            ReportError(Text030);

        ReadSourceCodeSetup();
        ClearInternals();

        IsHandled := false;
        OnRunOnBeforeWindowOpen(Window, IsHandled);
        if not IsHandled then
            Window.Open(Text001 + Text002 + Text003 + Text004);

        Window.Update(1, BusUnit.Code);

        ShouldClearPreviousConsolidation := not TestMode;
        OnRunOnAfterCalcShouldClearPreviousConsolidation(ShouldClearPreviousConsolidation);
        if ShouldClearPreviousConsolidation then begin
            UpdatePhase(Text018);
            ClearPreviousConsolidation();
        end;

        if ("Last Balance Currency Factor" <> 0) and
           ("Balance Currency Factor" <> "Last Balance Currency Factor")
        then begin
            UpdatePhase(Text019);
            UpdatePriorPeriodBalances();
        end;

        // Consolidate Current Entries
        UpdatePhase(Text020);
        Clear(GenJnlLine);
        GenJnlLine."Business Unit Code" := BusUnit.Code;
        GenJnlLine."Document No." := GLDocNo;
        GenJnlLine."Source Code" := ConsolidSourceCode;
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        TempSubsidGLEntry.Reset();
        TempSubsidGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        TempSubsidGLEntry.SetRange("Posting Date", StartingDate, EndingDate);
        OnBeforeUpdateTempGLEntry(TempSubsidGLEntry, GenJnlLine, CurErrorIdx, ErrorText, TestMode, Window);
        TempSubsidGLAcc.Reset();
        if TempSubsidGLAcc.FindSet() then
            repeat
                Window.Update(3, TempSubsidGLAcc."No.");
                DimBufMgt.DeleteAllDimensions();
                InitializeGLAccount();
                PreviousDate := 0D;
                if TempSubsidGLEntry.FindSet() then
                    repeat
                        if (TempSubsidGLEntry."Posting Date" <> NormalDate(TempSubsidGLEntry."Posting Date")) and
                           not ConsolidatingClosingDate
                        then
                            ReportError(
                              StrSubstNo(Text031,
                                TempSubsidGLEntry.TableCaption(),
                                TempSubsidGLEntry.FieldCaption("Posting Date"),
                                TempSubsidGLEntry."Posting Date"));
                        if (TempSubsidGLAcc."Consol. Translation Method" = TempSubsidGLAcc."Consol. Translation Method"::"Historical Rate") and
                           (TempSubsidGLEntry."Posting Date" <> PreviousDate)
                        then begin
                            if PreviousDate <> 0D then begin
                                TempDimBufOut.Reset();
                                TempDimBufOut.DeleteAll();
                                if TempGLEntry.FindSet() then
                                    repeat
                                        if not SkipAllDimensions then begin
                                            DimBufMgt.GetDimensions(TempGLEntry."Entry No.", TempDimBufOut);
                                            TempDimBufOut.SetRange("Entry No.", TempGLEntry."Entry No.");
                                        end;
                                        CreateAndPostGenJnlLine(GenJnlLine, TempGLEntry, TempDimBufOut);
                                    until TempGLEntry.Next() = 0;
                            end;
                            TempGLEntry.Reset();
                            TempGLEntry.DeleteAll();
                            DimBufMgt.DeleteAllDimensions();
                            PreviousDate := TempSubsidGLEntry."Posting Date";
                        end;
                        TempDimBufIn.Reset();
                        TempDimBufIn.DeleteAll();
                        if not SkipAllDimensions then begin
                            TempSubsidDimBuf.SetRange("Entry No.", TempSubsidGLEntry."Entry No.");
                            if TempSubsidDimBuf.FindSet() then
                                repeat
                                    if TempSelectedDim.Get('', 0, 0, '', TempSubsidDimBuf."Dimension Code") then begin
                                        TempDimBufIn.Init();
                                        TempDimBufIn."Table ID" := DATABASE::"G/L Entry";
                                        TempDimBufIn."Entry No." := TempSubsidGLEntry."Entry No.";
                                        TempDimBufIn."Dimension Code" := TempSubsidDimBuf."Dimension Code";
                                        TempDimBufIn."Dimension Value Code" := TempSubsidDimBuf."Dimension Value Code";
                                        OnRunOnBeforeInsertTempDimBuf(TempDimBufIn, TempSubsidDimBuf);
                                        TempDimBufIn.Insert();
                                    end;
                                until TempSubsidDimBuf.Next() = 0;
                        end;
                        UpdateTempGLEntry(TempSubsidGLEntry);
                        OnAfterUpdateTempGLEntry(BusUnit, TempSubsidGLEntry);
                    until TempSubsidGLEntry.Next() = 0;

                TempDimBufOut.Reset();
                TempDimBufOut.DeleteAll();
                OnRunOnBeforeTempGLEntryLoop(TempGLEntry, TempSubsidGLAcc);
                if TempGLEntry.FindSet() then
                    repeat
                        if not SkipAllDimensions then begin
                            DimBufMgt.GetDimensions(TempGLEntry."Entry No.", TempDimBufOut);
                            TempDimBufOut.SetRange("Entry No.", TempGLEntry."Entry No.");
                        end;
                        CreateAndPostGenJnlLine(GenJnlLine, TempGLEntry, TempDimBufOut);
                    until TempGLEntry.Next() = 0;
            until TempSubsidGLAcc.Next() = 0;

        // Post balancing entries and adjustments
        UpdatePhase(Text025);
        OnBeforePostBalancingEntries(GenJnlLine);

        for i := 1 to NormalDate(EndingDate) - NormalDate(StartingDate) + 1 do begin
            if ExchRateAdjAmounts[i] <> 0 then begin
                GenJnlLine.Amount := ExchRateAdjAmounts[i];
                if (BusUnit."Consolidation %" < 100) and
                   (BusUnit."Consolidation %" > 0)
                then begin
                    GenJnlLine.Amount := GenJnlLine.Amount * 100 / BusUnit."Consolidation %";
                    MinorExchRateAdjAmts[i] :=
                      MinorExchRateAdjAmts[i] - GenJnlLine.Amount + ExchRateAdjAmounts[i];
                end;
                if GenJnlLine.Amount < 0 then begin
                    BusUnit.TestField("Exch. Rate Gains Acc.");
                    GenJnlLine."Account No." := BusUnit."Exch. Rate Gains Acc.";
                end else begin
                    BusUnit.TestField("Exch. Rate Losses Acc.");
                    GenJnlLine."Account No." := BusUnit."Exch. Rate Losses Acc.";
                end;
                Window.Update(3, GenJnlLine."Account No.");
                if not ConsolidatingClosingDate then
                    GenJnlLine."Posting Date" := StartingDate + i - 1
                else
                    GenJnlLine."Posting Date" := StartingDate;
                GenJnlLine.Description := StrSubstNo(Text015, WorkDate());
                GenJnlPostLineTmp(GenJnlLine);
                RoundingResiduals[i] := RoundingResiduals[i] + GenJnlLine.Amount;
            end;
            if CompExchRateAdjAmts[i] <> 0 then begin
                GenJnlLine.Amount := CompExchRateAdjAmts[i];
                if (BusUnit."Consolidation %" < 100) and
                   (BusUnit."Consolidation %" > 0)
                then begin
                    GenJnlLine.Amount := GenJnlLine.Amount * 100 / BusUnit."Consolidation %";
                    MinorExchRateAdjAmts[i] :=
                      MinorExchRateAdjAmts[i] - GenJnlLine.Amount + CompExchRateAdjAmts[i];
                end;
                if GenJnlLine.Amount < 0 then begin
                    BusUnit.TestField("Comp. Exch. Rate Gains Acc.");
                    GenJnlLine."Account No." := BusUnit."Comp. Exch. Rate Gains Acc.";
                end else begin
                    BusUnit.TestField("Comp. Exch. Rate Losses Acc.");
                    GenJnlLine."Account No." := BusUnit."Comp. Exch. Rate Losses Acc.";
                end;
                OnBeforeWindowUpdate(GenJnlLine);
                Window.Update(3, GenJnlLine."Account No.");
                if not ConsolidatingClosingDate then
                    GenJnlLine."Posting Date" := StartingDate + i - 1
                else
                    GenJnlLine."Posting Date" := StartingDate;
                GenJnlLine.Description := StrSubstNo(Text027 + Text015, WorkDate());
                GenJnlPostLineTmp(GenJnlLine);
                RoundingResiduals[i] := RoundingResiduals[i] + GenJnlLine.Amount;
            end;
            if EqExchRateAdjAmts[i] <> 0 then begin
                GenJnlLine.Amount := EqExchRateAdjAmts[i];
                if (BusUnit."Consolidation %" < 100) and
                   (BusUnit."Consolidation %" > 0)
                then begin
                    GenJnlLine.Amount := GenJnlLine.Amount * 100 / BusUnit."Consolidation %";
                    MinorExchRateAdjAmts[i] :=
                      MinorExchRateAdjAmts[i] - GenJnlLine.Amount + EqExchRateAdjAmts[i];
                end;
                if GenJnlLine.Amount < 0 then begin
                    BusUnit.TestField("Equity Exch. Rate Gains Acc.");
                    GenJnlLine."Account No." := BusUnit."Equity Exch. Rate Gains Acc.";
                end else begin
                    BusUnit.TestField("Equity Exch. Rate Losses Acc.");
                    GenJnlLine."Account No." := BusUnit."Equity Exch. Rate Losses Acc.";
                end;
                OnBeforeWindowUpdate(GenJnlLine);
                Window.Update(3, GenJnlLine."Account No.");
                if not ConsolidatingClosingDate then
                    GenJnlLine."Posting Date" := StartingDate + i - 1
                else
                    GenJnlLine."Posting Date" := StartingDate;
                GenJnlLine.Description := StrSubstNo(Text028 + Text015, WorkDate());
                GenJnlPostLineTmp(GenJnlLine);
                RoundingResiduals[i] := RoundingResiduals[i] + GenJnlLine.Amount;
            end;
            if MinorExchRateAdjAmts[i] <> 0 then begin
                GenJnlLine.Amount := MinorExchRateAdjAmts[i];
                if GenJnlLine.Amount < 0 then begin
                    BusUnit.TestField("Minority Exch. Rate Gains Acc.");
                    GenJnlLine."Account No." := BusUnit."Minority Exch. Rate Gains Acc.";
                end else begin
                    BusUnit.TestField("Minority Exch. Rate Losses Acc");
                    GenJnlLine."Account No." := BusUnit."Minority Exch. Rate Losses Acc";
                end;
                OnBeforeWindowUpdate(GenJnlLine);
                Window.Update(3, GenJnlLine."Account No.");
                GenJnlLine."Posting Date" := StartingDate + i - 1;
                GenJnlLine.Description := StrSubstNo(Text029 + Text015, WorkDate());
                GenJnlPostLineTmp(GenJnlLine);
                RoundingResiduals[i] := RoundingResiduals[i] + GenJnlLine.Amount;
            end;
            if RoundingResiduals[i] <> 0 then begin
                GenJnlLine.Amount := -RoundingResiduals[i];
                BusUnit.TestField("Residual Account");
                GenJnlLine."Account No." := BusUnit."Residual Account";
                OnBeforeWindowUpdate(GenJnlLine);
                Window.Update(3, GenJnlLine."Account No.");
                if not ConsolidatingClosingDate then
                    GenJnlLine."Posting Date" := StartingDate + i - 1
                else
                    GenJnlLine."Posting Date" := StartingDate;
                GenJnlLine.Description :=
                  CopyStr(
                    StrSubstNo(Text016, WorkDate(), GenJnlLine.Amount),
                    1, MaxStrLen(GenJnlLine.Description));
                GenJnlPostLineTmp(GenJnlLine);
            end;
        end;

        if not TestMode then begin
            UpdatePhase(Text026);
            GenJnlPostLineFinally();
        end;
        Window.Close();

        if not TestMode then begin
            BusUnit."Last Balance Currency Factor" := BusUnit."Balance Currency Factor";
            BusUnit."Last Run" := WorkDate();
            BusUnit.Modify();
            OnAfterBusUnitModify(Rec, BusUnit);
        end;

        ShowAnalysisViewEntryMessage();
    end;

    var
        BusUnit: Record "Business Unit";
        ConsolidGLAcc: Record "G/L Account";
        ConsolidGLEntry: Record "G/L Entry";
        ConsolidDimSetEntry: Record "Dimension Set Entry";
        ConsolidCurrExchRate: Record "Currency Exchange Rate";
        TempSubsidGLAcc: Record "G/L Account" temporary;
        TempSubsidGLEntry: Record "G/L Entry" temporary;
        TempSubsidDimBuf: Record "Dimension Buffer" temporary;
        TempSubsidCurrExchRate: Record "Currency Exchange Rate" temporary;
        TempSelectedDim: Record "Selected Dimension" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempDimBufIn: Record "Dimension Buffer" temporary;
        TempDimBufOut: Record "Dimension Buffer" temporary;
        TempGLEntry: Record "G/L Entry" temporary;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        GLDocNo: Code[20];
        ProductVersion: Code[10];
        FormatVersion: Code[10];
        SubCompanyName: Text[30];
        CurrencyLCY: Code[10];
        CurrencyACY: Code[10];
        CurrencyPCY: Code[10];
        StoredCheckSum: Decimal;
        StartingDate: Date;
        EndingDate: Date;
        ConsolidSourceCode: Code[10];
        RoundingResiduals: array[500] of Decimal;
        ExchRateAdjAmounts: array[500] of Decimal;
        CompExchRateAdjAmts: array[500] of Decimal;
        EqExchRateAdjAmts: array[500] of Decimal;
        MinorExchRateAdjAmts: array[500] of Decimal;
        DeletedAmounts: array[500] of Decimal;
        DeletedDates: array[500] of Date;
        DeletedIndex: Integer;
        MaxDeletedIndex: Integer;
        AnalysisViewEntriesDeleted: Boolean;
        Text000: Label 'Enter a document number.';
        Text001: Label 'Consolidating companies...\\';
        Text002: Label 'Business Unit Code   #1###################\';
        Text003: Label 'Phase                #2############################\';
        Text004: Label 'G/L Account No.      #3##################';
        Text005: Label 'Analysis View Entries were deleted during the consolidation. An update is necessary.';
        Text006: Label 'There are more than %1 errors.';
        Text008: Label 'The consolidation can include a maximum of %1 days.';
        Text010: Label 'Previously consolidated entries cannot be erased because this would cause the general ledger to be out of balance by an amount of %1. ';
        Text011: Label ' Check for manually posted G/L entries on %2 for posting across business units.';
        Text013: Label '%1 adjusted from %2 to %3 on %4';
        Text014: Label 'Adjustment of opening entries on %1';
        Text015: Label 'Exchange rate adjustment on %1';
        Text016: Label 'Posted %2 to residual account as of %1';
        Text017: Label '%1 at exchange rate %2 on %3';
        Text018: Label 'Clear Previous Consolidation';
        SkipAllDimensions: Boolean;
        Text019: Label 'Update Prior Period Balances';
        ConsolidatingClosingDate: Boolean;
        ExchRateAdjAmount: Decimal;
        HistoricalCurrencyFactor: Decimal;
        NextLineNo: Integer;
        Text020: Label 'Consolidate Current Data';
        Text021: Label 'Within the Subsidiary (%5), there are two G/L Accounts: %1 and %4; which refer to the same %2, but with a different %3.';
        Text022: Label '%1 %2, referenced by %5 %3 %4, does not exist in the consolidated %3 table.';
        Text023: Label '%7 %1 %2 must have the same %3 as consolidated %1 %4. (%5 and %6, respectively)';
        Text024: Label '%1 at %2 %3';
        Text025: Label 'Calculate Residual Entries';
        Text026: Label 'Post to General Ledger';
        Text027: Label 'Composite ';
        Text028: Label 'Equity ';
        Text029: Label 'Minority ';
        TestMode: Boolean;
        CurErrorIdx: Integer;
        ErrorText: array[500] of Text;
        Text030: Label 'When using closing dates, the starting and ending dates must be the same.';
        Text031: Label 'A %1 with %2 on a closing date (%3) was found while consolidating non-closing entries.';
        Text032: Label 'The %1 is later than the %2 in company %3.';
        Text033: Label '%1 must not be empty when %2 is not empty, in company %3.';
        Text034: Label 'It is not possible to consolidate ledger entry dimensions for G/L Entry No. %1, because there are conflicting dimension values %2 and %3 for consolidation dimension %4.';

    procedure SetDocNo(NewDocNo: Code[20])
    begin
        GLDocNo := NewDocNo;
        if GLDocNo = '' then
            Error(Text000);
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    procedure SetSelectedDim(var SelectedDim: Record "Selected Dimension")
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetSelectedDim(TempSelectedDim, SelectedDim, SkipAllDimensions, IsHandled);
        if IsHandled then
            exit;
        TempSelectedDim.Reset();
        TempSelectedDim.DeleteAll();
        SkipAllDimensions := SelectedDim.IsEmpty();
        if SkipAllDimensions then
            exit;

        if SelectedDim.FindSet() then
            repeat
                TempSelectedDim := SelectedDim;
                TempSelectedDim."User ID" := '';
                TempSelectedDim."Object Type" := 0;
                TempSelectedDim."Object ID" := 0;
                TempSelectedDim.Insert();
            until SelectedDim.Next() = 0;
    end;

    procedure SetGlobals(NewProductVersion: Code[10]; NewFormatVersion: Code[10]; NewCompanyName: Text[30]; NewCurrencyLCY: Code[10]; NewCurrencyACY: Code[10]; NewCurrencyPCY: Code[10]; NewCheckSum: Decimal; NewStartingDate: Date; NewEndingDate: Date)
    begin
        ProductVersion := NewProductVersion;
        FormatVersion := NewFormatVersion;
        SubCompanyName := NewCompanyName;
        CurrencyLCY := NewCurrencyLCY;
        CurrencyACY := NewCurrencyACY;
        CurrencyPCY := NewCurrencyPCY;
        StoredCheckSum := NewCheckSum;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;

    local procedure ShowAnalysisViewEntryMessage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowAnalysisViewEntryMessage(AnalysisViewEntriesDeleted, IsHandled);
        if IsHandled then
            exit;

        if AnalysisViewEntriesDeleted then
            Message(Text005);
    end;

    procedure InsertGLAccount(NewGLAccount: Record "G/L Account")
    begin
        TempSubsidGLAcc.Init();
        TempSubsidGLAcc."No." := NewGLAccount."No.";
        TempSubsidGLAcc."Consol. Translation Method" := NewGLAccount."Consol. Translation Method";
        TempSubsidGLAcc."Consol. Debit Acc." := NewGLAccount."Consol. Debit Acc.";
        TempSubsidGLAcc."Consol. Credit Acc." := NewGLAccount."Consol. Credit Acc.";
        TempSubsidGLAcc.Insert();
    end;

    procedure InsertGLEntry(NewGLEntry: Record "G/L Entry"): Integer
    var
        NextEntryNo: Integer;
    begin
        NextEntryNo := TempSubsidGLEntry.GetLastEntryNo() + 1;

        TempSubsidGLEntry.Init();
        TempSubsidGLEntry."Entry No." := NextEntryNo;
        TempSubsidGLEntry."G/L Account No." := NewGLEntry."G/L Account No.";
        TempSubsidGLEntry."Posting Date" := NewGLEntry."Posting Date";
        TempSubsidGLEntry."Debit Amount" := NewGLEntry."Debit Amount";
        TempSubsidGLEntry."Credit Amount" := NewGLEntry."Credit Amount";
        TempSubsidGLEntry."Add.-Currency Debit Amount" := NewGLEntry."Add.-Currency Debit Amount";
        TempSubsidGLEntry."Add.-Currency Credit Amount" := NewGLEntry."Add.-Currency Credit Amount";
        OnBeforeInsertGLEntry(TempSubsidGLEntry, NewGLEntry);
        TempSubsidGLEntry.Insert();
        exit(NextEntryNo);
    end;

    procedure InsertEntryDim(NewDimBuf: Record "Dimension Buffer"; GLEntryNo: Integer)
    begin
        if TempSubsidDimBuf.Get(NewDimBuf."Table ID", GLEntryNo, NewDimBuf."Dimension Code") then begin
            if NewDimBuf."Dimension Value Code" <> TempSubsidDimBuf."Dimension Value Code" then
                Error(
                  Text034, GLEntryNo, NewDimBuf."Dimension Value Code", TempSubsidDimBuf."Dimension Value Code",
                  NewDimBuf."Dimension Code");
        end else begin
            TempSubsidDimBuf.Init();
            TempSubsidDimBuf := NewDimBuf;
            TempSubsidDimBuf."Entry No." := GLEntryNo;
            TempSubsidDimBuf.Insert();
        end;
    end;

    procedure InsertExchRate(NewCurrExchRate: Record "Currency Exchange Rate")
    begin
        TempSubsidCurrExchRate.Init();
        TempSubsidCurrExchRate."Currency Code" := NewCurrExchRate."Currency Code";
        TempSubsidCurrExchRate."Starting Date" := NewCurrExchRate."Starting Date";
        TempSubsidCurrExchRate."Relational Currency Code" := NewCurrExchRate."Relational Currency Code";
        TempSubsidCurrExchRate."Exchange Rate Amount" := NewCurrExchRate."Exchange Rate Amount";
        TempSubsidCurrExchRate."Relational Exch. Rate Amount" := NewCurrExchRate."Relational Exch. Rate Amount";
        TempSubsidCurrExchRate.Insert();
    end;

    procedure UpdateGLEntryDimSetID()
    begin
        if SkipAllDimensions then
            exit;

        TempSubsidGLEntry.Reset();
        TempSubsidDimBuf.Reset();
        TempSubsidDimBuf.SetRange("Table ID", DATABASE::"G/L Entry");
        with TempSubsidGLEntry do begin
            Reset();
            if FindSet(true, false) then
                repeat
                    TempSubsidDimBuf.SetRange("Entry No.", "Entry No.");
                    if TempSubsidDimBuf.FindFirst() then begin
                        "Dimension Set ID" := DimMgt.CreateDimSetIDFromDimBuf(TempSubsidDimBuf);
                        OnUpdateGLEntryDimSetIDOnAfterAssignDimensionSetID(TempSubsidDimBuf);
                        Modify();
                    end;
                until Next() = 0;
        end;
    end;

    procedure CalcCheckSum() CheckSum: Decimal
    begin
        CheckSum :=
          DateToDecimal(StartingDate) + DateToDecimal(EndingDate) +
          TextToDecimal(FormatVersion) + TextToDecimal(ProductVersion);
        TempSubsidGLAcc.Reset();
        if TempSubsidGLAcc.FindSet() then
            repeat
                CheckSum :=
                  CheckSum +
                  TextToDecimal(CopyStr(TempSubsidGLAcc."No.", 1, 10)) + TextToDecimal(CopyStr(TempSubsidGLAcc."No.", 11, 10)) +
                  TextToDecimal(CopyStr(TempSubsidGLAcc."Consol. Debit Acc.", 1, 10)) +
                  TextToDecimal(CopyStr(TempSubsidGLAcc."Consol. Debit Acc.", 11, 10)) +
                  TextToDecimal(CopyStr(TempSubsidGLAcc."Consol. Credit Acc.", 1, 10)) +
                  TextToDecimal(CopyStr(TempSubsidGLAcc."Consol. Credit Acc.", 11, 10));
            until TempSubsidGLAcc.Next() = 0;
        TempSubsidGLEntry.Reset();
        if TempSubsidGLEntry.FindSet() then
            repeat
                CheckSum := CheckSum +
                  TempSubsidGLEntry."Debit Amount" + TempSubsidGLEntry."Credit Amount" +
                  TempSubsidGLEntry."Add.-Currency Debit Amount" + TempSubsidGLEntry."Add.-Currency Credit Amount" +
                  DateToDecimal(TempSubsidGLEntry."Posting Date");
            until TempSubsidGLEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportFromXML(FileName: Text)
    var
        Consolidation: XMLport "Consolidation Import/Export";
        InputFile: File;
        InputStream: InStream;
    begin
        InputFile.TextMode(true);
        InputFile.WriteMode(false);
        InputFile.Open(FileName);

        InputFile.CreateInStream(InputStream);

        Consolidation.SetSource(InputStream);
        Consolidation.Import();
        InputFile.Close();

        Consolidation.GetGLAccount(TempSubsidGLAcc);
        OnAfterGetGLAccount(TempSubsidGLAcc);
        Consolidation.GetGLEntry(TempSubsidGLEntry);
        Consolidation.GetEntryDim(TempSubsidDimBuf);
        Consolidation.GetExchRate(TempSubsidCurrExchRate);
        Consolidation.GetGlobals(
          ProductVersion, FormatVersion, SubCompanyName, CurrencyLCY, CurrencyACY, CurrencyPCY,
          StoredCheckSum, StartingDate, EndingDate);

        SelectAllImportedDimensions();
    end;

    [Scope('OnPrem')]
    procedure ExportToXML(FileName: Text)
    var
        Consolidation: XMLport "Consolidation Import/Export";
        OutputFile: File;
        OutputStream: OutStream;
    begin
        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);

        OutputFile.CreateOutStream(OutputStream);

        Consolidation.SetGlobals(SubCompanyName, CurrencyLCY, CurrencyACY, CurrencyPCY, StoredCheckSum, StartingDate, EndingDate);
        Consolidation.SetGLAccount(TempSubsidGLAcc);
        Consolidation.SetGLEntry(TempSubsidGLEntry);
        Consolidation.SetEntryDim(TempSubsidDimBuf);
        Consolidation.SetExchRate(TempSubsidCurrExchRate);

        Consolidation.SetDestination(OutputStream);
        Consolidation.Export();
        OutputFile.Close();
    end;

    procedure GetGlobals(var ImpProductVersion: Code[10]; var ImpFormatVersion: Code[10]; var ImpCompanyName: Text[30]; var ImpCurrencyLCY: Code[10]; var ImpCurrencyACY: Code[10]; var ImpCurrencyPCY: Code[10]; var ImpCheckSum: Decimal; var ImpStartingDate: Date; var ImpEndingDate: Date)
    begin
        ImpProductVersion := ProductVersion;
        ImpFormatVersion := FormatVersion;
        ImpCompanyName := SubCompanyName;
        ImpCurrencyLCY := CurrencyLCY;
        ImpCurrencyACY := CurrencyACY;
        ImpCurrencyPCY := CurrencyPCY;
        ImpCheckSum := StoredCheckSum;
        ImpStartingDate := StartingDate;
        ImpEndingDate := EndingDate;
    end;

    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
        CurErrorIdx := 0;
    end;

    procedure GetAccumulatedErrors(var NumErrors: Integer; var Errors: array[100] of Text)
    var
        Idx: Integer;
    begin
        NumErrors := 0;
        Clear(Errors);
        for Idx := 1 to CurErrorIdx do begin
            NumErrors := NumErrors + 1;
            Errors[NumErrors] := ErrorText[Idx];
            if (Idx = ArrayLen(Errors)) and (CurErrorIdx > Idx) then begin
                CopyArray(ErrorText, ErrorText, ArrayLen(Errors) + 1);
                CurErrorIdx := CurErrorIdx - ArrayLen(Errors);
                exit;
            end;
        end;
        CurErrorIdx := 0;
        Clear(ErrorText);
    end;

    procedure SelectAllImportedDimensions()
    begin
        // assume all dimensions that were imported were also selected.
        TempSelectedDim.Reset();
        TempSelectedDim.DeleteAll();
        if TempSubsidDimBuf.FindSet() then
            repeat
                TempSelectedDim.Init();
                TempSelectedDim."User ID" := '';
                TempSelectedDim."Object Type" := 0;
                TempSelectedDim."Object ID" := 0;
                TempSelectedDim."Dimension Code" := TempSubsidDimBuf."Dimension Code";
                if TempSelectedDim.Insert() then;
            until TempSubsidDimBuf.Next() = 0;
        SkipAllDimensions := TempSelectedDim.IsEmpty();
    end;

    local procedure ReadSourceCodeSetup()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        ConsolidSourceCode := SourceCodeSetup.Consolidation;
    end;

    local procedure ClearInternals()
    begin
        NextLineNo := 0;
        AnalysisViewEntriesDeleted := false;
        TempGenJnlLine.Reset();
        TempGenJnlLine.DeleteAll();
        TempDimBufOut.Reset();
        TempDimBufOut.DeleteAll();
        TempDimBufIn.Reset();
        TempDimBufIn.DeleteAll();
        Clear(RoundingResiduals);
        Clear(ExchRateAdjAmounts);
        Clear(CompExchRateAdjAmts);
        Clear(EqExchRateAdjAmts);
        Clear(MinorExchRateAdjAmts);
    end;

    local procedure UpdatePhase(PhaseText: Text[50])
    begin
        Window.Update(2, PhaseText);
        Window.Update(3, '');
    end;

    local procedure ClearPreviousConsolidation()
    var
        TempGLAccount: Record "G/L Account" temporary;
        AnalysisView: Record "Analysis View";
        TempAnalysisView: Record "Analysis View" temporary;
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewFound: Boolean;
    begin
        OnBeforeClearPreviousConsolidation(ConsolidGLEntry);
        ClearAmountArray();
        with ConsolidGLEntry do begin
            if not
               SetCurrentKey("G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Posting Date")
            then
                SetCurrentKey("G/L Account No.", "Business Unit Code", "Posting Date");
            SetRange("Business Unit Code", BusUnit.Code);
            SetRange("Posting Date", StartingDate, EndingDate);
            if FindSet(true, false) then
                repeat
                    OnClearPreviousConsolidationOnBeforeUpdateAmountArray(ConsolidGLEntry, DeletedAmounts, DeletedDates, DeletedIndex);
                    UpdateAmountArray("Posting Date", Amount);
                    Description := '';
                    Amount := 0;
                    "Debit Amount" := 0;
                    "Credit Amount" := 0;
                    "Additional-Currency Amount" := 0;
                    "Add.-Currency Debit Amount" := 0;
                    "Add.-Currency Credit Amount" := 0;
                    Modify();
                    if "G/L Account No." <> TempGLAccount."No." then begin
                        Window.Update(3, "G/L Account No.");
                        TempGLAccount."No." := "G/L Account No.";
                        TempGLAccount.Insert();
                    end;
                until Next() = 0;
        end;
        OnClearPreviousConsolidationOnBeforeCheckAmountArray(DeletedAmounts, DeletedDates);
        CheckAmountArray();

        if AnalysisView.FindSet() then
            repeat
                AnalysisViewFound := false;
                if TempGLAccount.FindSet() then
                    repeat
                        AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
                        AnalysisViewEntry.SetRange("Account No.", TempGLAccount."No.");
                        AnalysisViewEntry.SetRange("Account Source", AnalysisViewEntry."Account Source"::"G/L Account");
                        if AnalysisViewEntry.FindFirst() then begin
                            TempAnalysisView.Code := AnalysisViewEntry."Analysis View Code";
                            TempAnalysisView."Account Source" := AnalysisViewEntry."Account Source";
                            TempAnalysisView.Insert();
                            AnalysisViewFound := true;
                        end;
                    until (TempGLAccount.Next() = 0) or AnalysisViewFound;
            until AnalysisView.Next() = 0;

        AnalysisViewEntry.Reset();
        if TempAnalysisView.FindSet() then
            repeat
                AnalysisView.Get(TempAnalysisView.Code);
                if AnalysisView.Blocked then begin
                    AnalysisView."Refresh When Unblocked" := true;
                    AnalysisView.Modify();
                end else begin
                    AnalysisViewEntry.SetRange("Analysis View Code", TempAnalysisView.Code);
                    AnalysisViewEntry.DeleteAll();
                    AnalysisView."Last Entry No." := 0;
                    AnalysisView."Last Date Updated" := 0D;
                    AnalysisView.Modify();
                    AnalysisViewEntriesDeleted := true;
                end;
            until TempAnalysisView.Next() = 0;
    end;

    local procedure ClearAmountArray()
    begin
        Clear(DeletedAmounts);
        Clear(DeletedDates);
        DeletedIndex := 0;
        MaxDeletedIndex := 0;
    end;

    local procedure UpdateAmountArray(PostingDate: Date; Amount: Decimal)
    var
        Top: Integer;
        Bottom: Integer;
        Middle: Integer;
        Found: Boolean;
        NotFound: Boolean;
        idx: Integer;
    begin
        if DeletedIndex = 0 then begin
            DeletedIndex := 1;
            MaxDeletedIndex := 1;
            DeletedDates[DeletedIndex] := PostingDate;
            DeletedAmounts[DeletedIndex] := Amount;
        end else
            if PostingDate = DeletedDates[DeletedIndex] then
                DeletedAmounts[DeletedIndex] := DeletedAmounts[DeletedIndex] + Amount
            else begin
                Top := 0;
                Bottom := MaxDeletedIndex + 1;
                Found := false;
                NotFound := false;
                repeat
                    Middle := (Top + Bottom) div 2;
                    if Bottom - Top <= 1 then
                        NotFound := true
                    else
                        if DeletedDates[Middle] > PostingDate then
                            Bottom := Middle
                        else
                            if DeletedDates[Middle] < PostingDate then
                                Top := Middle
                            else
                                Found := true;
                until Found or NotFound;
                if Found then begin
                    DeletedIndex := Middle;
                    DeletedAmounts[DeletedIndex] := DeletedAmounts[DeletedIndex] + Amount;
                end else begin
                    if MaxDeletedIndex >= ArrayLen(DeletedDates) then
                        ReportError(StrSubstNo(Text008, ArrayLen(DeletedDates)))
                    else
                        MaxDeletedIndex := MaxDeletedIndex + 1;
                    for idx := MaxDeletedIndex downto Bottom + 1 do begin
                        DeletedAmounts[idx] := DeletedAmounts[idx - 1];
                        DeletedDates[idx] := DeletedDates[idx - 1];
                    end;
                    DeletedIndex := Bottom;
                    DeletedDates[DeletedIndex] := PostingDate;
                    DeletedAmounts[DeletedIndex] := Amount;
                end;
            end;
    end;

    local procedure CheckAmountArray()
    var
        idx: Integer;
    begin
        for idx := 1 to MaxDeletedIndex do
            if DeletedAmounts[idx] <> 0 then
                ReportError(StrSubstNo(Text010 + Text011, DeletedAmounts[idx], DeletedDates[idx]));
    end;

    local procedure TestGLAccounts()
    var
        AccountToTest: Record "G/L Account";
    begin
        // First test within the Subsidiary Chart of Accounts
        AccountToTest := TempSubsidGLAcc;
        if AccountToTest.TranslationMethodConflict(TempSubsidGLAcc) then begin
            if TempSubsidGLAcc.GetFilter("Consol. Debit Acc.") <> '' then
                ReportError(
                  StrSubstNo(
                    Text021,
                    TempSubsidGLAcc."No.",
                    TempSubsidGLAcc.FieldCaption("Consol. Debit Acc."),
                    TempSubsidGLAcc.FieldCaption("Consol. Translation Method"),
                    AccountToTest."No.", BusUnit.TableCaption()))
            else
                ReportError(
                  StrSubstNo(Text021,
                    TempSubsidGLAcc."No.",
                    TempSubsidGLAcc.FieldCaption("Consol. Credit Acc."),
                    TempSubsidGLAcc.FieldCaption("Consol. Translation Method"),
                    AccountToTest."No.", BusUnit.TableCaption()));
        end else begin
            TempSubsidGLAcc.Reset();
            TempSubsidGLAcc := AccountToTest;
            TempSubsidGLAcc.Find('=');
        end;
        // Then, test for conflicts between subsidiary and parent (consolidated)
        if TempSubsidGLAcc."Consol. Debit Acc." <> '' then begin
            if not ConsolidGLAcc.Get(TempSubsidGLAcc."Consol. Debit Acc.") then
                ReportError(
                  StrSubstNo(Text022,
                    TempSubsidGLAcc.FieldCaption("Consol. Debit Acc."), TempSubsidGLAcc."Consol. Debit Acc.",
                    TempSubsidGLAcc.TableCaption(), TempSubsidGLAcc."No.", BusUnit.TableCaption()));
            if (TempSubsidGLAcc."Consol. Translation Method" <> ConsolidGLAcc."Consol. Translation Method") and
               (BusUnit."File Format" <> BusUnit."File Format"::"Version 3.70 or Earlier (.txt)")
            then
                ReportError(
                  StrSubstNo(Text023,
                    TempSubsidGLAcc.TableCaption(), TempSubsidGLAcc."No.",
                    TempSubsidGLAcc.FieldCaption("Consol. Translation Method"), ConsolidGLAcc."No.",
                    TempSubsidGLAcc."Consol. Translation Method", ConsolidGLAcc."Consol. Translation Method",
                    BusUnit.TableCaption()));
        end;
        if TempSubsidGLAcc."Consol. Debit Acc." = TempSubsidGLAcc."Consol. Credit Acc." then
            exit;
        if TempSubsidGLAcc."Consol. Credit Acc." <> '' then begin
            if not ConsolidGLAcc.Get(TempSubsidGLAcc."Consol. Credit Acc.") then
                ReportError(
                  StrSubstNo(Text022,
                    TempSubsidGLAcc.FieldCaption("Consol. Credit Acc."), TempSubsidGLAcc."Consol. Credit Acc.",
                    TempSubsidGLAcc.TableCaption(), TempSubsidGLAcc."No.", BusUnit.TableCaption()));
            if (TempSubsidGLAcc."Consol. Translation Method" <> ConsolidGLAcc."Consol. Translation Method") and
               (BusUnit."File Format" <> BusUnit."File Format"::"Version 3.70 or Earlier (.txt)")
            then
                ReportError(
                  StrSubstNo(Text023,
                    TempSubsidGLAcc.TableCaption(), TempSubsidGLAcc."No.",
                    TempSubsidGLAcc.FieldCaption("Consol. Translation Method"), ConsolidGLAcc."No.",
                    TempSubsidGLAcc."Consol. Translation Method", ConsolidGLAcc."Consol. Translation Method",
                    BusUnit.TableCaption()));
        end;
    end;

    local procedure UpdatePriorPeriodBalances()
    var
        idx: Integer;
        AdjustmentAmount: Decimal;
    begin
        Clear(GenJnlLine);
        OnBeforeUpdatePriorPeriodBalances(GenJnlLine);

        GenJnlLine."Business Unit Code" := BusUnit.Code;
        GenJnlLine."Document No." := GLDocNo;
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJnlLine."Source Code" := ConsolidSourceCode;

        BusUnit.TestField("Balance Currency Factor");
        BusUnit.TestField("Last Balance Currency Factor");
        ExchRateAdjAmount := 0;
        idx := NormalDate(EndingDate) - NormalDate(StartingDate) + 1;

        with ConsolidGLAcc do begin
            Reset();
            SetRange("Account Type", "Account Type"::Posting);
            SetRange("Business Unit Filter", BusUnit.Code);
            SetRange("Date Filter", 0D, EndingDate);
            SetRange("Income/Balance", "Income/Balance"::"Balance Sheet");
            SetFilter(
              "No.", '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6&<>%7&<>%8&<>%9',
              BusUnit."Exch. Rate Losses Acc.", BusUnit."Exch. Rate Gains Acc.",
              BusUnit."Comp. Exch. Rate Gains Acc.", BusUnit."Comp. Exch. Rate Losses Acc.",
              BusUnit."Equity Exch. Rate Gains Acc.", BusUnit."Equity Exch. Rate Losses Acc.",
              BusUnit."Minority Exch. Rate Gains Acc.", BusUnit."Minority Exch. Rate Losses Acc",
              BusUnit."Residual Account");
            OnBeforeConsolidGlAccFindSet(ConsolidGLAcc);
            if FindSet() then
                repeat
                    Window.Update(3, "No.");
                    case "Consol. Translation Method" of
                        "Consol. Translation Method"::"Average Rate (Manual)",
                      "Consol. Translation Method"::"Closing Rate":
                            // Post adjustment to existing balance to convert that balance to new Closing Rate
                            if SkipAllDimensions then begin
                                CalcFields("Debit Amount", "Credit Amount");
                                if "Debit Amount" <> 0 then
                                    PostBalanceAdjustment("No.", "Debit Amount");
                                if "Credit Amount" <> 0 then
                                    PostBalanceAdjustment("No.", -"Credit Amount");
                            end else begin
                                TempGLEntry.Reset();
                                TempGLEntry.DeleteAll();
                                DimBufMgt.DeleteAllDimensions();
                                ConsolidGLEntry.Reset();
                                ConsolidGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                                ConsolidGLEntry.SetRange("G/L Account No.", "No.");
                                ConsolidGLEntry.SetRange("Posting Date", 0D, EndingDate);
                                ConsolidGLEntry.SetRange("Business Unit Code", BusUnit.Code);
                                OnBeforeConsolidGLEntryFindSet(ConsolidGLEntry);
                                if ConsolidGLEntry.FindSet() then
                                    repeat
                                        TempDimBufIn.Reset();
                                        TempDimBufIn.DeleteAll();
                                        ConsolidDimSetEntry.SetRange("Dimension Set ID", ConsolidGLEntry."Dimension Set ID");
                                        if ConsolidDimSetEntry.FindSet() then
                                            repeat
                                                if TempSelectedDim.Get('', 0, 0, '', ConsolidDimSetEntry."Dimension Code") then begin
                                                    TempDimBufIn.Init();
                                                    TempDimBufIn."Table ID" := DATABASE::"G/L Entry";
                                                    TempDimBufIn."Entry No." := ConsolidGLEntry."Entry No.";
                                                    TempDimBufIn."Dimension Code" := ConsolidDimSetEntry."Dimension Code";
                                                    TempDimBufIn."Dimension Value Code" := ConsolidDimSetEntry."Dimension Value Code";
                                                    TempDimBufIn.Insert();
                                                end;
                                            until ConsolidDimSetEntry.Next() = 0;
                                        UpdateTempGLEntry(ConsolidGLEntry);
                                    until ConsolidGLEntry.Next() = 0;
                                TempDimBufOut.Reset();
                                TempDimBufOut.DeleteAll();
                                if TempGLEntry.FindSet() then
                                    repeat
                                        DimBufMgt.GetDimensions(TempGLEntry."Entry No.", TempDimBufOut);
                                        TempDimBufOut.SetRange("Entry No.", TempGLEntry."Entry No.");
                                        if TempGLEntry."Debit Amount" <> 0 then
                                            PostBalanceAdjustment("No.", TempGLEntry."Debit Amount");
                                        if TempGLEntry."Credit Amount" <> 0 then
                                            PostBalanceAdjustment("No.", -TempGLEntry."Credit Amount");
                                    until TempGLEntry.Next() = 0;
                            end;
                        "Consol. Translation Method"::"Historical Rate":
                            // accumulate adjustment for historical accounts
                            begin
                                CalcFields("Balance at Date");
                                AdjustmentAmount := 0;
                                ExchRateAdjAmounts[idx] := ExchRateAdjAmounts[idx] + AdjustmentAmount;
                            end;
                        "Consol. Translation Method"::"Composite Rate":
                            // accumulate adjustment for composite accounts
                            begin
                                CalcFields("Balance at Date");
                                AdjustmentAmount := 0;
                                CompExchRateAdjAmts[idx] := CompExchRateAdjAmts[idx] + AdjustmentAmount;
                            end;
                        "Consol. Translation Method"::"Equity Rate":
                            // accumulate adjustment for equity accounts
                            begin
                                CalcFields("Balance at Date");
                                AdjustmentAmount := 0;
                                EqExchRateAdjAmts[idx] := EqExchRateAdjAmts[idx] + AdjustmentAmount;
                            end;
                    end;
                until Next() = 0;
        end;

        TempDimBufOut.Reset();
        TempDimBufOut.DeleteAll();

        if ExchRateAdjAmount <> 0 then begin
            Clear(GenJnlLine);
            GenJnlLine."Business Unit Code" := BusUnit.Code;
            GenJnlLine."Document No." := GLDocNo;
            GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            GenJnlLine."Source Code" := ConsolidSourceCode;
            GenJnlLine.Amount := -ExchRateAdjAmount;
            if GenJnlLine.Amount < 0 then begin
                BusUnit.TestField("Exch. Rate Gains Acc.");
                GenJnlLine."Account No." := BusUnit."Exch. Rate Gains Acc.";
            end else begin
                BusUnit.TestField("Exch. Rate Losses Acc.");
                GenJnlLine."Account No." := BusUnit."Exch. Rate Losses Acc.";
            end;
            OnBeforeGenJnlPostLineTmp(GenJnlLine);
            Window.Update(3, GenJnlLine."Account No.");
            GenJnlLine."Posting Date" := EndingDate;
            GenJnlLine.Description := StrSubstNo(Text014, WorkDate());
            GenJnlPostLineTmp(GenJnlLine);
        end;
    end;

    local procedure PostBalanceAdjustment(GLAccNo: Code[20]; AmountToPost: Decimal)
    var
        TempDimSetEntry2: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
    begin
        GenJnlLine.Amount :=
          Round(
            (AmountToPost * BusUnit."Last Balance Currency Factor" / BusUnit."Balance Currency Factor") - AmountToPost);
        if GenJnlLine.Amount <> 0 then begin
            GenJnlLine."Account No." := GLAccNo;
            GenJnlLine."Posting Date" := EndingDate;
            GenJnlLine.Description :=
              CopyStr(
                StrSubstNo(
                  Text013,
                  AmountToPost,
                  Round(BusUnit."Last Balance Currency Factor", 0.00001),
                  Round(BusUnit."Balance Currency Factor", 0.00001),
                  WorkDate()),
                1, MaxStrLen(GenJnlLine.Description));
            if TempDimBufOut.FindSet() then begin
                repeat
                    TempDimSetEntry2.Init();
                    TempDimSetEntry2."Dimension Code" := TempDimBufOut."Dimension Code";
                    TempDimSetEntry2."Dimension Value Code" := TempDimBufOut."Dimension Value Code";
                    DimValue.Get(TempDimSetEntry2."Dimension Code", TempDimSetEntry2."Dimension Value Code");
                    TempDimSetEntry2."Dimension Value ID" := DimValue."Dimension Value ID";
                    TempDimSetEntry2.Insert();
                until TempDimBufOut.Next() = 0;
                GenJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry2);
            end else begin
                GenJnlLine."Shortcut Dimension 1 Code" := '';
                GenJnlLine."Shortcut Dimension 2 Code" := '';
                GenJnlLine."Dimension Set ID" := 0;
            end;
            GenJnlPostLineTmp(GenJnlLine);
            ExchRateAdjAmount := ExchRateAdjAmount + GenJnlLine.Amount;
        end;
    end;

    local procedure UpdateTempGLEntry(var GLEntry: Record "G/L Entry")
    var
        DimEntryNo: Integer;
        Found: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTempGLEntryProcedure(TempGLEntry, GLEntry, IsHandled, TempDimBufIn);
        if IsHandled then
            exit;

        DimEntryNo := DimBufMgt.FindDimensions(TempDimBufIn);
        Found := TempDimBufIn.FindFirst();
        if Found and (DimEntryNo = 0) then begin
            TempGLEntry := GLEntry;
            TempGLEntry."Entry No." := DimBufMgt.InsertDimensions(TempDimBufIn);
            TempGLEntry.Insert();
        end else begin
            if TempGLEntry.Get(DimEntryNo) then begin
                TempGLEntry.Amount := TempGLEntry.Amount + GLEntry.Amount;
                TempGLEntry."Debit Amount" := TempGLEntry."Debit Amount" + GLEntry."Debit Amount";
                TempGLEntry."Credit Amount" := TempGLEntry."Credit Amount" + GLEntry."Credit Amount";
                TempGLEntry."Additional-Currency Amount" := TempGLEntry."Additional-Currency Amount" + GLEntry."Additional-Currency Amount";
                TempGLEntry."Add.-Currency Debit Amount" := TempGLEntry."Add.-Currency Debit Amount" + GLEntry."Add.-Currency Debit Amount";
                TempGLEntry."Add.-Currency Credit Amount" :=
                  TempGLEntry."Add.-Currency Credit Amount" + GLEntry."Add.-Currency Credit Amount";
                TempGLEntry.Modify();
            end else begin
                TempGLEntry := GLEntry;
                TempGLEntry."Entry No." := DimEntryNo;
                TempGLEntry.Insert();
            end;
        end;
    end;

    local procedure CreateAndPostGenJnlLine(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var DimBuf: Record "Dimension Buffer")
    var
        TempDimSetEntry2: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
        ConsolidAmount: Decimal;
        AmountToPost: Decimal;
        AdjustAmount: Decimal;
        ClosingAmount: Decimal;
        TranslationNeeded: Boolean;
        idx: Integer;
        OriginalTranslationMethod: Integer;
    begin
        with GenJnlLine do begin
            if BusUnit."Data Source" = BusUnit."Data Source"::"Local Curr. (LCY)" then
                AmountToPost := GLEntry."Debit Amount" - GLEntry."Credit Amount"
            else
                AmountToPost := GLEntry."Add.-Currency Debit Amount" - GLEntry."Add.-Currency Credit Amount";

            if AmountToPost > 0 then
                "Account No." := TempSubsidGLAcc."Consol. Debit Acc."
            else
                "Account No." := TempSubsidGLAcc."Consol. Credit Acc.";

            if "Account No." = '' then
                "Account No." := TempSubsidGLAcc."No.";
            if AmountToPost = 0 then
                exit;
            ConsolidGLAcc.Get("Account No.");

            OriginalTranslationMethod := TempSubsidGLAcc."Consol. Translation Method";
            if TempSubsidGLAcc."Consol. Translation Method" = TempSubsidGLAcc."Consol. Translation Method"::"Average Rate (Manual)" then
                if ConsolidGLAcc."Income/Balance" = ConsolidGLAcc."Income/Balance"::"Balance Sheet" then
                    TempSubsidGLAcc."Consol. Translation Method" := TempSubsidGLAcc."Consol. Translation Method"::"Closing Rate";

            ConsolidAmount := AmountToPost * BusUnit."Consolidation %" / 100;

            TranslationNeeded := (BusUnit."Currency Code" <> '');
            if TranslationNeeded then
                if BusUnit."Data Source" = BusUnit."Data Source"::"Add. Rep. Curr. (ACY)" then
                    TranslationNeeded := (BusUnit."Currency Code" <> CurrencyACY);

            if TranslationNeeded then begin
                ClosingAmount :=
                  Round(
                    ConsolidCurrExchRate.ExchangeAmtFCYToLCY(
                      EndingDate, BusUnit."Currency Code",
                      ConsolidAmount, BusUnit."Balance Currency Factor"));
                case TempSubsidGLAcc."Consol. Translation Method" of
                    TempSubsidGLAcc."Consol. Translation Method"::"Closing Rate":
                        begin
                            Amount := ClosingAmount;
                            Description :=
                              CopyStr(
                                StrSubstNo(
                                  Text017,
                                  ConsolidAmount, Round(BusUnit."Balance Currency Factor", 0.00001), EndingDate),
                                1, MaxStrLen(Description));
                        end;
                    TempSubsidGLAcc."Consol. Translation Method"::"Composite Rate",
                    TempSubsidGLAcc."Consol. Translation Method"::"Equity Rate",
                    TempSubsidGLAcc."Consol. Translation Method"::"Average Rate (Manual)":
                        begin
                            Amount :=
                              Round(
                                ConsolidCurrExchRate.ExchangeAmtFCYToLCY(
                                  EndingDate, BusUnit."Currency Code",
                                  ConsolidAmount, BusUnit."Income Currency Factor"));
                            Description :=
                              CopyStr(
                                StrSubstNo(
                                  Text017,
                                  ConsolidAmount, Round(BusUnit."Income Currency Factor", 0.00001), EndingDate),
                                1, MaxStrLen(Description));
                        end;
                    TempSubsidGLAcc."Consol. Translation Method"::"Historical Rate":
                        begin
                            Amount := TranslateUsingHistoricalRate(ConsolidAmount, GLEntry."Posting Date");
                            Description :=
                              CopyStr(
                                StrSubstNo(
                                  Text017,
                                  ConsolidAmount, Round(HistoricalCurrencyFactor, 0.00001), GLEntry."Posting Date"),
                                1, MaxStrLen(Description));
                        end;
                end;
            end else begin
                Amount := Round(ConsolidAmount);
                ClosingAmount := Amount;
                Description :=
                  StrSubstNo(Text024, AmountToPost, BusUnit."Consolidation %", BusUnit.FieldCaption("Consolidation %"));
            end;

            if TempSubsidGLAcc."Consol. Translation Method" = TempSubsidGLAcc."Consol. Translation Method"::"Historical Rate" then
                "Posting Date" := GLEntry."Posting Date"
            else
                "Posting Date" := EndingDate;
            idx := NormalDate("Posting Date") - NormalDate(StartingDate) + 1;

            if DimBuf.FindSet() then begin
                repeat
                    TempDimSetEntry2.Init();
                    TempDimSetEntry2."Dimension Code" := DimBuf."Dimension Code";
                    TempDimSetEntry2."Dimension Value Code" := DimBuf."Dimension Value Code";
                    DimValue.Get(TempDimSetEntry2."Dimension Code", TempDimSetEntry2."Dimension Value Code");
                    TempDimSetEntry2."Dimension Value ID" := DimValue."Dimension Value ID";
                    TempDimSetEntry2.Insert();
                until DimBuf.Next() = 0;
                "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry2);
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID",
                  "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;

            OnBeforeTempDimSetEntryDelete(GenJnlLine, GLEntry);

            if Amount <> 0 then
                GenJnlPostLineTmp(GenJnlLine);
            TempDimSetEntry2.Reset();
            TempDimSetEntry2.DeleteAll();

            RoundingResiduals[idx] := RoundingResiduals[idx] + Amount;
            AdjustAmount := ClosingAmount - Amount;
            case TempSubsidGLAcc."Consol. Translation Method" of
                TempSubsidGLAcc."Consol. Translation Method"::"Composite Rate":
                    CompExchRateAdjAmts[idx] := CompExchRateAdjAmts[idx] + AdjustAmount;
                TempSubsidGLAcc."Consol. Translation Method"::"Equity Rate":
                    EqExchRateAdjAmts[idx] := EqExchRateAdjAmts[idx] + AdjustAmount;
                else
                    ExchRateAdjAmounts[idx] := ExchRateAdjAmounts[idx] + AdjustAmount;
            end;
            TempSubsidGLAcc."Consol. Translation Method" := OriginalTranslationMethod;
        end;
        OnAfterCreateAndPostGenJnlLine(GenJnlLine, ConsolidAmount, CurrencyACY);
    end;

    local procedure TranslateUsingHistoricalRate(AmountToTranslate: Decimal; DateToTranslate: Date) TranslatedAmount: Decimal
    begin
        if BusUnit."Currency Exchange Rate Table" = BusUnit."Currency Exchange Rate Table"::"Local"
        then begin
            ConsolidCurrExchRate.Reset();
            ConsolidCurrExchRate.SetRange("Currency Code", BusUnit."Currency Code");
            ConsolidCurrExchRate.SetRange("Starting Date", 0D, DateToTranslate);
            ConsolidCurrExchRate.FindLast();
            ConsolidCurrExchRate.TestField("Exchange Rate Amount");
            ConsolidCurrExchRate.TestField("Relational Exch. Rate Amount");
            ConsolidCurrExchRate.TestField("Relational Currency Code", '');
            HistoricalCurrencyFactor :=
              ConsolidCurrExchRate."Exchange Rate Amount" / ConsolidCurrExchRate."Relational Exch. Rate Amount";
        end else begin
            TempSubsidCurrExchRate.Reset();
            TempSubsidCurrExchRate.SetRange("Starting Date", 0D, DateToTranslate);
            TempSubsidCurrExchRate.SetRange("Currency Code", CurrencyPCY);
            TempSubsidCurrExchRate.FindLast();
            TempSubsidCurrExchRate.TestField("Exchange Rate Amount");
            TempSubsidCurrExchRate.TestField("Relational Exch. Rate Amount");
            TempSubsidCurrExchRate.TestField("Relational Currency Code", '');
            HistoricalCurrencyFactor := TempSubsidCurrExchRate."Relational Exch. Rate Amount" /
              TempSubsidCurrExchRate."Exchange Rate Amount";
            if BusUnit."Data Source" = BusUnit."Data Source"::"Add. Rep. Curr. (ACY)" then begin
                TempSubsidCurrExchRate.SetRange("Currency Code", CurrencyACY);
                TempSubsidCurrExchRate.FindLast();
                TempSubsidCurrExchRate.TestField("Exchange Rate Amount");
                TempSubsidCurrExchRate.TestField("Relational Exch. Rate Amount");
                TempSubsidCurrExchRate.TestField("Relational Currency Code", '');
                HistoricalCurrencyFactor := HistoricalCurrencyFactor *
                  TempSubsidCurrExchRate."Exchange Rate Amount" / TempSubsidCurrExchRate."Relational Exch. Rate Amount";
            end;
        end;
        TranslatedAmount := Round(AmountToTranslate / HistoricalCurrencyFactor);
    end;

    local procedure GenJnlPostLineTmp(var GenJnlLine: Record "Gen. Journal Line")
    begin
        NextLineNo := NextLineNo + 1;
        TempGenJnlLine := GenJnlLine;
        TempGenJnlLine.Amount := Round(TempGenJnlLine.Amount);
        TempGenJnlLine."Line No." := NextLineNo;
        TempGenJnlLine."System-Created Entry" := true;
        OnBeforeTempGenJnlLineInsert(TempGenJnlLine);
        DimMgt.UpdateGlobalDimFromDimSetID(TempGenJnlLine."Dimension Set ID",
          TempGenJnlLine."Shortcut Dimension 1 Code", TempGenJnlLine."Shortcut Dimension 2 Code");
        TempGenJnlLine.Insert();
    end;

    local procedure GenJnlPostLineFinally()
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        TempGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date");
        if TempGenJnlLine.FindSet() then
            repeat
                Window.Update(3, TempGenJnlLine."Account No.");
                OnBeforeGenJnlPostLine(TempGenJnlLine);
                GenJnlPostLine.RunWithCheck(TempGenJnlLine);
            until TempGenJnlLine.Next() = 0;
    end;

    local procedure TextToDecimal(Txt: Text[50]) Result: Decimal
    var
        DecOnlyTxt: Text[50];
        Idx: Integer;
    begin
        for Idx := 1 to StrLen(Txt) do
            if Txt[Idx] in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] then
                DecOnlyTxt := DecOnlyTxt + CopyStr(Txt, Idx, 1);
        if DecOnlyTxt = '' then
            Result := 0
        else
            Evaluate(Result, DecOnlyTxt);
    end;

    local procedure DateToDecimal(Dt: Date) Result: Decimal
    var
        Mon: Decimal;
        Day: Decimal;
        Yr: Decimal;
    begin
        Day := Date2DMY(Dt, 1);
        Mon := Date2DMY(Dt, 2);
        Yr := Date2DMY(Dt, 3);
        Result := Yr * 100 + Mon + Day / 100;
    end;

    local procedure ReportError(ErrorMsg: Text)
    begin
        if TestMode then begin
            if CurErrorIdx = ArrayLen(ErrorText) then
                ErrorText[CurErrorIdx] := StrSubstNo(Text006, ArrayLen(ErrorText))
            else begin
                CurErrorIdx := CurErrorIdx + 1;
                ErrorText[CurErrorIdx] := ErrorMsg;
            end;
        end else
            Error(ErrorMsg);
    end;

    procedure GetNumSubsidGLAcc(): Integer
    begin
        TempSubsidGLAcc.Reset();
        exit(TempSubsidGLAcc.Count);
    end;

    procedure Get1stSubsidGLAcc(var GlAccount: Record "G/L Account"): Boolean
    begin
        TempSubsidGLAcc.Reset();
        if TempSubsidGLAcc.FindFirst() then begin
            GlAccount := TempSubsidGLAcc;
            if TestMode then
                TestGLAccounts();
            exit(true);
        end;
        exit(false);
    end;

    procedure GetNxtSubsidGLAcc(var GLAccount: Record "G/L Account"): Boolean
    begin
        if TempSubsidGLAcc.Next() <> 0 then begin
            GLAccount := TempSubsidGLAcc;
            if TestMode then
                TestGLAccounts();
            exit(true);
        end;
        exit(false);
    end;

    procedure GetNumSubsidGLEntry(): Integer
    begin
        with TempSubsidGLEntry do begin
            Reset();
            SetCurrentKey("G/L Account No.", "Posting Date");
            SetRange("G/L Account No.", TempSubsidGLAcc."No.");
            exit(Count);
        end;
    end;

    procedure Get1stSubsidGLEntry(var GLEntry: Record "G/L Entry"): Boolean
    var
        IsError: Boolean;
        ErrorMsg: Text;
    begin
        ConsolidatingClosingDate :=
          (StartingDate = EndingDate) and
          (StartingDate <> NormalDate(StartingDate));
        if (StartingDate <> NormalDate(StartingDate)) and
           (StartingDate <> EndingDate)
        then
            ReportError(Text030);
        with TempSubsidGLEntry do begin
            Reset();
            SetCurrentKey("G/L Account No.", "Posting Date");
            SetRange("G/L Account No.", TempSubsidGLAcc."No.");
            if FindFirst() then begin
                GLEntry := TempSubsidGLEntry;
                if TestMode then begin
                    if ("Posting Date" <> NormalDate("Posting Date")) and
                       not ConsolidatingClosingDate
                    then
                        ReportError(StrSubstNo(
                            Text031,
                            TableCaption,
                            FieldCaption("Posting Date"),
                            "Posting Date"));
                    IsError := false;
                    OnAfterCheckPostingDate(TempSubsidGLEntry, IsError, ErrorMsg);
                    if IsError then
                        ReportError(ErrorMsg);
                end;
                exit(true);
            end;
            exit(false);
        end;
    end;

    procedure GetNxtSubsidGLEntry(var GLEntry: Record "G/L Entry"): Boolean
    var
        IsError: Boolean;
        ErrorMsg: Text;
    begin
        with TempSubsidGLEntry do begin
            if Next() <> 0 then begin
                GLEntry := TempSubsidGLEntry;
                if TestMode then begin
                    if ("Posting Date" <> NormalDate("Posting Date")) and
                       not ConsolidatingClosingDate
                    then
                        ReportError(StrSubstNo(
                            Text031,
                            TableCaption,
                            FieldCaption("Posting Date"),
                            "Posting Date"));
                    IsError := false;
                    OnAfterCheckPostingDate(TempSubsidGLEntry, IsError, ErrorMsg);
                    if IsError then
                        ReportError(ErrorMsg);
                end;
                exit(true);
            end else
                exit(false);
        end;
    end;

    local procedure InitializeGLAccount()
    begin
        TestGLAccounts();
        TempGLEntry.Reset();
        TempGLEntry.DeleteAll();
        TempSubsidGLEntry.SetRange("G/L Account No.", TempSubsidGLAcc."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLEntry(var SubsidGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowAnalysisViewEntryMessage(var AnalysisViewEntriesDeleted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearPreviousConsolidationOnBeforeCheckAmountArray(var DeletedAmountsArray: array[500] of Decimal; var DeletedDatesArray: array[500] of Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearPreviousConsolidationOnBeforeUpdateAmountArray(var ConsolidatedGLEntry: Record "G/L Entry"; var DeletedAmountsArray: array[500] of Decimal; var DeletedDatesArray: array[500] of Date; var DeletedIdx: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateGLEntryDimSetIDOnAfterAssignDimensionSetID(var TempSubsidDimBuf: Record "Dimension Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTempGLEntry(var TempSubsidGLEntry: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line"; var CurErrorIdx: Integer; var ErrorText: array[500] of Text; TestMode: Boolean; var WindowDialog: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTempGLEntry(var BusUnit: Record "Business Unit"; var TempSubsidGLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ConsolidAmount: Decimal; CurrencyACY: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnRun(var BusinessUnit: Record "Business Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntries(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWindowUpdate(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBusUnitModify(var Rec: Record "Business Unit"; var BusUnit: Record "Business Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSelectedDim(var TempSelectedDim: Record "Selected Dimension"; var SelectedDim: Record "Selected Dimension"; var SkipAllDimensions: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLAccount(var TempSubsidGLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearPreviousConsolidation(var ConsolidGLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePriorPeriodBalances(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConsolidGLEntryFindSet(var ConsolidGLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConsolidGLAccFindSet(var ConsolidGLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlPostLineTmp(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDimSetEntryDelete(var GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempGenJnlLineInsert(var TempGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPostingDate(var GlEntry: Record "G/L Entry"; var IsError: Boolean; var ErrorMsg: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTempGLEntryProcedure(var TempGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean; TempDimensionBufferIn: Record "Dimension Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRunOnAfterCalcShouldClearPreviousConsolidation(var ShouldClearPreviousConsolidation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeTempGLEntryLoop(var TempGLEntry: Record "G/L Entry"; TempSubsidGLAcc: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeWindowOpen(var WindowDialog: Dialog; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeInsertTempDimBuf(var TempDimensionBuffer: Record "Dimension Buffer"; var TempSubsidDimensionBuffer: Record "Dimension Buffer")
    begin
    end;
}

