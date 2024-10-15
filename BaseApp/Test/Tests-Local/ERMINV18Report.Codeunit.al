codeunit 144710 "ERM INV-18 Report"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        AmountType: Option " ",QtyPlus,AmountPlus,QtyMinus,AmountMinus;
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure INV18_MultipleLinesWithDiffSign()
    var
        FixedAsset: Record "Fixed Asset";
        TempFAJournalLine: Record "FA Journal Line" temporary;
    begin
        Initialize();
        MockFixedAsset(FixedAsset);
        MockFAJournalLines(TempFAJournalLine, FixedAsset."No.");
        RunINV18Report;
        VerifyReportValuesFromBuffer(TempFAJournalLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure MockFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        with FixedAsset do begin
            Init();
            "No." := '';
            Insert(true);
            "Manufacturing Year" := Format(Date2DMY(WorkDate(), 3));
            "Inventory Number" := LibraryUtility.GenerateGUID();
            "Factory No." := LibraryUtility.GenerateGUID();
            "Passport No." := LibraryUtility.GenerateGUID();
            Modify();
        end;
    end;

    local procedure MockFAJournalLines(var TempFAJournalLine: Record "FA Journal Line"; FANo: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        Qty: Decimal;
        Amount: Decimal;
        Factor: Integer;
        i: Integer;
    begin
        FilterFAJournalLineWithEmptyBatch(FAJournalLine);
        FAJournalLine.DeleteAll();
        Qty := LibraryRandom.RandDec(100, 2);
        Amount := LibraryRandom.RandDec(100, 2);
        Factor := LibraryRandom.RandIntInRange(3, 5);
        // Should not print because calc. value equal to actual value.
        MockFAJournalLine(TempFAJournalLine, FANo, Qty, Qty, Amount, Amount, false);
        for i := 1 to 2 do begin
            // Should print with minus quantity/amount values
            MockFAJournalLine(TempFAJournalLine, FANo, Qty, Round(Qty * Factor), Amount, Round(Amount * Factor), true);
            // Should print with plus quantity/amount values
            MockFAJournalLine(TempFAJournalLine, FANo, Round(Qty * Factor), Qty, Round(Amount * Factor), Amount, true);
        end;
    end;

    local procedure MockFAJournalLine(var TempFAJournalLine: Record "FA Journal Line"; FANo: Code[20]; CalcQty: Decimal; ActualQty: Decimal; CalcAmount: Decimal; ActualAmount: Decimal; AddLineToBuffer: Boolean)
    var
        FAJournalLine: Record "FA Journal Line";
        RecRef: RecordRef;
    begin
        with FAJournalLine do begin
            Init();
            "Journal Template Name" := '';
            "Journal Batch Name" := '';
            RecRef.GetTable(FAJournalLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "FA No." := FANo;
            Description := LibraryUtility.GenerateGUID();
            "Calc. Quantity" := CalcQty;
            "Actual Quantity" := ActualQty;
            "Calc. Amount" := CalcAmount;
            "Actual Amount" := ActualAmount;
            Insert();
            if AddLineToBuffer then begin
                TempFAJournalLine := FAJournalLine;
                TempFAJournalLine.Insert();
            end;
        end;
    end;

    local procedure RunINV18Report()
    var
        FAJournalLine: Record "FA Journal Line";
        INV18Rep: Report "FA Comparative Sheet INV-18";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FilterFAJournalLineWithEmptyBatch(FAJournalLine);
        with INV18Rep do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            SetTableView(FAJournalLine);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure FilterFAJournalLineWithEmptyBatch(var FAJournalLine: Record "FA Journal Line")
    begin
        with FAJournalLine do begin
            SetRange("Journal Template Name", '');
            SetRange("Journal Batch Name", '');
        end;
    end;

    local procedure VerifyReportValuesFromBuffer(var TempFAJournalLine: Record "FA Journal Line" temporary)
    var
        FixedAsset: Record "Fixed Asset";
        RowShift: Integer;
        ValueArray: array[2, 4] of Decimal;
        i: Integer;
    begin
        RowShift := 0;
        with TempFAJournalLine do begin
            FindSet();
            FixedAsset.Get("FA No.");
            repeat
                for i := 1 to ArrayLen(ValueArray, 2) do
                    ValueArray[1, i] := 0;
                if "Calc. Quantity" > "Actual Quantity" then begin
                    ValueArray[1, AmountType::AmountMinus] := "Calc. Amount" - "Actual Amount";
                    ValueArray[1, AmountType::QtyMinus] := "Calc. Quantity" - "Actual Quantity";
                end else begin
                    ValueArray[1, AmountType::AmountPlus] := "Actual Amount" - "Calc. Amount";
                    ValueArray[1, AmountType::QtyPlus] := "Actual Quantity" - "Calc. Quantity";
                end;
                for i := 1 to ArrayLen(ValueArray, 2) do
                    ValueArray[2, i] += ValueArray[1, i];
                VerifyLineValue(
                  RowShift, Description, FixedAsset."Manufacturing Year", FixedAsset."Inventory Number", FixedAsset."Factory No.",
                  FixedAsset."Passport No.", ValueArray[1], false);
                RowShift += 1;
            until Next = 0;
            // Verify Footer
            VerifyLineValue(
              RowShift, '', '', '', '', '', ValueArray[2], true);
        end;
    end;

    local procedure VerifyLineValue(RowShift: Integer; Description: Text; ManufYear: Text; InventoryNumber: Text; FactoryNo: Text; PassportNo: Text; ValueArray: array[4] of Decimal; CheckTotalsOnly: Boolean)
    var
        LineRowId: Integer;
    begin
        LineRowId := 32 + RowShift;
        if not CheckTotalsOnly then begin
            LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(RowShift + 1));
            LibraryReportValidation.VerifyCellValue(LineRowId, 2, Description);
            LibraryReportValidation.VerifyCellValue(LineRowId, 6, ManufYear);
            LibraryReportValidation.VerifyCellValue(LineRowId, 9, InventoryNumber);
            LibraryReportValidation.VerifyCellValue(LineRowId, 11, FactoryNo);
            LibraryReportValidation.VerifyCellValue(LineRowId, 12, PassportNo);
        end;

        LibraryReportValidation.VerifyCellValue(LineRowId, 14, Format(ValueArray[AmountType::QtyPlus]));
        LibraryReportValidation.VerifyCellValue(LineRowId, 15, Format(ValueArray[AmountType::AmountPlus]));
        LibraryReportValidation.VerifyCellValue(LineRowId, 19, Format(ValueArray[AmountType::QtyMinus]));
        LibraryReportValidation.VerifyCellValue(LineRowId, 22, Format(ValueArray[AmountType::AmountMinus]));
    end;
}

