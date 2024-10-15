codeunit 144721 "ERM Tax Register Report"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        StdRepMgt: Codeunit "Local Report Management";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value not exist in worksheet no. %1', Comment = '%1 - row % 2 - column';

    [Test]
    [Scope('OnPrem')]
    procedure TaxRegisterWithMultipleAccumLines()
    var
        TaxRegister: Record "Tax Register";
        TaxRegtemEntry: Record "Tax Register Item Entry";
        TotalAmount: Decimal;
        i: Integer;
    begin
        Initialize;

        MockTaxRegister(TaxRegister);
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            TotalAmount += MockTaxRegAccumLine(TaxRegister);
        MockTaxRegisterEntries(TaxRegtemEntry, TaxRegister, TotalAmount);
        RunTaxRegisterReport(TaxRegister);
        VerifyReportValues(TaxRegister, TaxRegtemEntry);
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        isInitialized := true;
    end;

    local procedure MockTaxRegSection(): Code[10]
    var
        TaxRegSection: Record "Tax Register Section";
    begin
        TaxRegSection.Init;
        TaxRegSection.Code := LibraryUtility.GenerateGUID;
        TaxRegSection.Insert;
        exit(TaxRegSection.Code);
    end;

    local procedure MockTaxRegister(var TaxRegister: Record "Tax Register")
    begin
        with TaxRegister do begin
            Init;
            "Section Code" := MockTaxRegSection;
            "No." := LibraryUtility.GenerateGUID;
            Description := "No.";
            "Table ID" := DATABASE::"Tax Register Item Entry";
            Insert;
        end;
    end;

    local procedure MockTaxRegAccumLine(TaxRegister: Record "Tax Register"): Decimal
    var
        TaxRegAccum: Record "Tax Register Accumulation";
        RecRef: RecordRef;
    begin
        with TaxRegAccum do begin
            Init;
            RecRef.GetTable(TaxRegAccum);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Section Code" := TaxRegister."Section Code";
            "Tax Register No." := TaxRegister."No.";
            "Starting Date" := WorkDate;
            "Ending Date" := CalcDate('<1D>', "Starting Date");
            Description := LibraryUtility.GenerateGUID;
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
            exit(Amount);
        end;
    end;

    local procedure MockTaxRegisterEntries(var TaxRegtemEntry: Record "Tax Register Item Entry"; TaxRegister: Record "Tax Register"; TotalAmount: Decimal)
    var
        RecRef: RecordRef;
    begin
        with TaxRegtemEntry do begin
            Init;
            RecRef.GetTable(TaxRegtemEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Section Code" := TaxRegister."Section Code";
            "Where Used Register IDs" := TaxRegister."No.";
            // Outside of period entry that should not be print.
            "Starting Date" := CalcDate('<CM+1M>', WorkDate);
            "Ending Date" := CalcDate('<1D>', "Starting Date");
            "Amount (Document)" := TotalAmount;
            "Document No." := LibraryUtility.GenerateGUID;
            Insert;

            // Inside of period.
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Starting Date" := WorkDate;
            "Ending Date" := CalcDate('<1D>', "Starting Date");
            Insert;
        end;
    end;

    local procedure RunTaxRegisterReport(var TaxRegister: Record "Tax Register")
    var
        TaxRegisterRep: Report "Tax Register";
    begin
        TaxRegister.SetRecFilter;
        TaxRegister.SetFilter(
          "Date Filter", '%1..%2', CalcDate('<-CM>', WorkDate), CalcDate('<CM>', WorkDate));

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        with TaxRegisterRep do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            InitializeRequest(true);
            SetTableView(TaxRegister);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure VerifyReportValues(var TaxRegister: Record "Tax Register"; TaxRegisterEntry: Record "Tax Register Item Entry")
    var
        TaxRegAccum: Record "Tax Register Accumulation";
        i: Integer;
    begin
        LibraryReportValidation.VerifyCellValue(4, 1, TaxRegister.Description);
        LibraryReportValidation.VerifyCellValue(2, 2, Format(TaxRegister.GetFilter("Date Filter")));

        with TaxRegAccum do begin
            SetRange("Section Code", TaxRegister."Section Code");
            SetRange("Tax Register No.", TaxRegister."No.");
            FindSet;
            repeat
                VerifyLineValue(i, Description, StdRepMgt.FormatReportValue(Amount, 2));
                i += 1;
            until Next = 0;
            // Verify Footer
            LibraryReportValidation.VerifyCellValue(7 + i, 4, StdRepMgt.FormatReportValue(TaxRegisterEntry."Amount (Document)", 2));
        end;
        VerifyDetails(TaxRegisterEntry);
    end;

    local procedure VerifyLineValue(RowShift: Integer; Description: Text; Amount: Text)
    var
        LineRowId: Integer;
    begin
        LineRowId := 7 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(RowShift + 1));
        LibraryReportValidation.VerifyCellValue(LineRowId, 2, Description);
        LibraryReportValidation.VerifyCellValue(LineRowId, 4, Amount);
    end;

    local procedure VerifyDetails(TaxRegisterEntry: Record "Tax Register Item Entry")
    begin
        with TaxRegisterEntry do begin
            CheckIfValueExistsOnSpecificWorksheet(Format("Entry No."));
            CheckIfValueExistsOnSpecificWorksheet("Section Code");
            CheckIfValueExistsOnSpecificWorksheet("Where Used Register IDs");
            CheckIfValueExistsOnSpecificWorksheet(Format("Amount (Document)"));
            CheckIfValueExistsOnSpecificWorksheet("Document No.");
        end;
    end;

    local procedure CheckIfValueExistsOnSpecificWorksheet(Value: Text)
    var
        WorksheetNo: Integer;
    begin
        WorksheetNo := 2;
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(WorksheetNo, Value),
          StrSubstNo(ValueNotExistErr, WorksheetNo));
    end;
}

