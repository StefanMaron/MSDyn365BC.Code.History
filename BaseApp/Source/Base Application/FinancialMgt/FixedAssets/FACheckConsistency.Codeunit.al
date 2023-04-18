codeunit 5606 "FA Check Consistency"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Posting Type Setup" = r,
                  TableData "FA Depreciation Book" = rm,
                  TableData "Maintenance Ledger Entry" = rm,
                  TableData "Ins. Coverage Ledger Entry" = rm;
    TableNo = "FA Ledger Entry";

    trigger OnRun()
    begin
        if ("FA Posting Category" <> "FA Posting Category"::" ") or
           ("FA Posting Type" = "FA Posting Type"::"Gain/Loss") or
           ("FA Posting Type" = "FA Posting Type"::"Book Value on Disposal")
        then
            exit;
        ClearAll();
        FALedgEntry := Rec;
        // This record is not modified in the codeunit.
        FALedgEntry2 := Rec;
        with FALedgEntry do begin
            DeprBookCode := "Depreciation Book Code";
            FANo := "FA No.";
            FAPostingDate := "FA Posting Date";
            FA.Get(FANo);
            DeprBook.Get(DeprBookCode);
            FADeprBook.Get(FANo, DeprBookCode);
            case "FA Posting Type" of
                "FA Posting Type"::"Write-Down":
                    FAPostingTypeSetup.Get(
                      DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
                "FA Posting Type"::Appreciation:
                    FAPostingTypeSetup.Get(
                      DeprBookCode, FAPostingTypeSetup."FA Posting Type"::Appreciation);
                "FA Posting Type"::"Custom 1":
                    FAPostingTypeSetup.Get(
                      DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 1");
                "FA Posting Type"::"Custom 2":
                    FAPostingTypeSetup.Get(
                      DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 2");
            end;
            if "FA Posting Type" = "FA Posting Type"::"Proceeds on Disposal" then
                CheckSalesPosting()
            else
                CheckNormalPosting();
        end;
        SetFAPostingDate(FALedgEntry2, true);
        CheckInsuranceIntegration();
    end;

    var
        DeprBook: Record "Depreciation Book";
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        FALedgEntry: Record "FA Ledger Entry";
        FALedgEntry2: Record "FA Ledger Entry";
        FAJnlLine: Record "FA Journal Line";
        FANo: Code[20];
        DeprBookCode: Code[10];
        FAPostingDate: Date;
        BookValue: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        NewAmount: Decimal;

        Text000: Label 'The first entry must be an %2 for %1.';
        Text001: Label '%1 is disposed.';
        InvalidDisposalDateErr: Label 'The disposal date of fixed asset code %1 must be the last date%2.', Comment = '%1=code value, e.g.E000140, %2=in depreciation book code x(x= a code value, e.g. COMPANY), remains empty when depr. book code is empty';
        Text003: Label 'Accumulated';
        Text004: Label '%2%3 must not be positive on %4 for %1.';
        Text005: Label '%2%3 must not be negative on %4 for %1.';
        Text006: Label '%2 must not be negative or less than %3 on %4 for %1.';
        Text007: Label '%2 must not be negative on %3 for %1.';
        SalvageValueErr: Label 'There is a reclassification salvage amount that must be posted first. Open the FA Journal page, and then post the relevant reclassification entry.';

    local procedure CheckNormalPosting()
    begin
        with FALedgEntry do begin
            CheckDisposalDate(FADeprBook, FA);
            SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
            SetRange("FA No.", FANo);
            SetRange("Depreciation Book Code", DeprBookCode);
            OnCheckNormalPostingOnAfterSetFALedgerEntryFilters(FALedgEntry, FANo, DeprBookCode);
            if Find('-') then begin
                if not IsAcquisitionCost() then
                    CreateAcquisitionCostError();
                if not FADeprBook."Use FA Ledger Check" then
                    DeprBook.TestField("Use FA Ledger Check", false)
                else begin
                    SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
                    SetRange("Part of Book Value", true);
                    SetRange("FA Posting Date", 0D, FAPostingDate - 1);
                    OnCheckNormalPostingOnBeforeCalcSumsForBookValue(FALedgEntry, FAPostingDate);
                    CalcSums(Amount);
                    BookValue := Amount;
                    SetRange("Part of Book Value");
                    SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Depreciable Basis", "FA Posting Date");
                    SetRange("Part of Depreciable Basis", true);
                    CalcSums(Amount);
                    DeprBasis := Amount;
                    SetRange("Part of Depreciable Basis");
                    SetCurrentKey(
                      "FA No.", "Depreciation Book Code",
                      "FA Posting Category", "FA Posting Type", "FA Posting Date");
                    SetRange("FA Posting Category", "FA Posting Category"::" ");
                    SetRange("FA Posting Type", "FA Posting Type"::"Salvage Value");
                    CalcSums(Amount);
                    SalvageValue := Amount;
                    SetRange("FA Posting Type", FALedgEntry2."FA Posting Type");
                    CalcSums(Amount);
                    NewAmount := Amount;
                    SetRange("FA Posting Type");
                    SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    SetFilter("FA Posting Date", '%1..', FAPostingDate);
                    SetRange(Reversed, false);
                    OnCheckNormalPostingOnBeforeFind(FALedgEntry, FAPostingDate);
                    if Find('-') then
                        repeat
                            if "Part of Book Value" then
                                BookValue := BookValue + Amount;
                            if "Part of Depreciable Basis" then
                                DeprBasis := DeprBasis + Amount;
                            if "FA Posting Type" = "FA Posting Type"::"Salvage Value" then
                                SalvageValue := SalvageValue + Amount;
                            if "FA Posting Type" = FALedgEntry2."FA Posting Type" then
                                NewAmount := NewAmount + Amount;
                            CheckForError();
                        until Next() = 0;
                end;
            end;
        end;
    end;

    local procedure CheckSalesPosting()
    begin
        with FALedgEntry do begin
            if FADeprBook."Acquisition Date" = 0D then
                CreateAcquisitionCostError();
            SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
            SetRange("FA No.", FANo);
            SetRange("Depreciation Book Code", DeprBookCode);
            SetRange("Part of Book Value", true);
            SetFilter("FA Posting Date", '%1..', FAPostingDate + 1);
            OnCheckSalesPostingOnBeforeFirstFind(FALedgEntry, FANo, DeprBookCode);
            if Find('-') then
                CreateDisposalError();
            SetRange("Part of Book Value");
            SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Depreciable Basis", "FA Posting Date");
            SetRange("Part of Depreciable Basis", true);
            OnCheckSalesPostingOnAfterSetFALedgerEntryFilters(FALedgEntry, FANo, DeprBookCode);
            if Find('-') then
                CreateDisposalError();
            SetRange("Part of Depreciable Basis");
            if not FADeprBook."Use FA Ledger Check" then
                DeprBook.TestField("Use FA Ledger Check", false)
            else begin
                SetCurrentKey(
                  "FA No.", "Depreciation Book Code",
                  "FA Posting Category", "FA Posting Type", "FA Posting Date");
                SetRange("FA Posting Category", "FA Posting Category"::" ");
                SetRange("FA Posting Type", "FA Posting Type"::"Proceeds on Disposal");
                SetRange("FA Posting Date");
                if Find('-') then
                    repeat
                        NewAmount := NewAmount + Amount;
                        if NewAmount > 0 then
                            CreatePostingTypeError();
                    until Next() = 0;
            end;
        end;
    end;

    procedure SetFAPostingDate(var FALedgEntry2: Record "FA Ledger Entry"; LocalCall: Boolean)
    var
        MaxDate: Date;
        MinDate: Date;
        GLDate: Date;
    begin
        with FALedgEntry2 do
            if not LocalCall then begin
                FANo := "FA No.";
                DeprBookCode := "Depreciation Book Code";
                FADeprBook.Get(FANo, DeprBookCode);
            end;
        with FALedgEntry do begin
            Reset();
            SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
            SetRange("Depreciation Book Code", DeprBookCode);
            SetRange("FA No.", FANo);
            SetRange("FA Posting Category", "FA Posting Category"::" ");
            SetRange("FA Posting Type", FALedgEntry2."FA Posting Type");
            if Find('+') then
                MaxDate := "FA Posting Date"
            else
                MaxDate := 0D;
            case FALedgEntry2."FA Posting Type" of
                FALedgEntry2."FA Posting Type"::"Acquisition Cost",
              FALedgEntry2."FA Posting Type"::"Proceeds on Disposal":
                    if Find('-') then
                        MinDate := "FA Posting Date"
                    else
                        MinDate := 0D;
            end;
            case FALedgEntry2."FA Posting Type" of
                FALedgEntry2."FA Posting Type"::"Acquisition Cost":
                    begin
                        SetCurrentKey(
                          "FA No.", "Depreciation Book Code",
                          "FA Posting Category", "FA Posting Type", "Posting Date");
                        if Find('-') then
                            GLDate := "Posting Date"
                        else
                            GLDate := 0D;
                    end;
            end;
        end;
        with FALedgEntry2 do
            case "FA Posting Type" of
                "FA Posting Type"::"Acquisition Cost":
                    begin
                        FADeprBook."Last Acquisition Cost Date" := MaxDate;
                        FADeprBook."Acquisition Date" := MinDate;
                        FADeprBook."G/L Acquisition Date" := GLDate;
                    end;
                "FA Posting Type"::"Salvage Value":
                    FADeprBook."Last Salvage Value Date" := MaxDate;
                "FA Posting Type"::Depreciation:
                    FADeprBook."Last Depreciation Date" := MaxDate;
                "FA Posting Type"::"Write-Down":
                    FADeprBook."Last Write-Down Date" := MaxDate;
                "FA Posting Type"::Appreciation:
                    FADeprBook."Last Appreciation Date" := MaxDate;
                "FA Posting Type"::"Custom 1":
                    FADeprBook."Last Custom 1 Date" := MaxDate;
                "FA Posting Type"::"Custom 2":
                    FADeprBook."Last Custom 2 Date" := MaxDate;
                "FA Posting Type"::"Proceeds on Disposal":
                    FADeprBook."Disposal Date" := MinDate;
            end;

        OnSetFAPostingDateOnBeforeFADeprBookModify(FADeprBook, FALedgEntry2, MaxDate, MinDate, GLDate);
        FADeprBook.Modify();
    end;

    local procedure CheckInsuranceIntegration()
    var
        FASetup: Record "FA Setup";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
    begin
        if FALedgEntry2."FA Posting Type" <> FALedgEntry2."FA Posting Type"::"Proceeds on Disposal" then
            exit;
        if InsCoverageLedgEntry.IsEmpty() then
            exit;
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        if DeprBook.Code <> FASetup."Insurance Depr. Book" then
            exit;
        InsCoverageLedgEntry.SetCurrentKey("FA No.");
        InsCoverageLedgEntry.SetRange("FA No.", FA."No.");
        InsCoverageLedgEntry.ModifyAll("Disposed FA", FADeprBook."Disposal Date" > 0D)
    end;

    local procedure CheckForError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckForError(FALedgEntry2, FAJnlLine, FAPostingTypeSetup, NewAmount, BookValue, SalvageValue, DeprBasis, IsHandled);
        if IsHandled then
            exit;

        with FALedgEntry2 do begin
            case "FA Posting Type" of
                "FA Posting Type"::"Acquisition Cost":
                    if NewAmount < 0 then
                        CreatePostingTypeError();
                "FA Posting Type"::Depreciation,
              "FA Posting Type"::"Salvage Value":
                    if NewAmount > 0 then
                        CreatePostingTypeError();
                "FA Posting Type"::"Write-Down",
                "FA Posting Type"::Appreciation,
                "FA Posting Type"::"Custom 1",
                "FA Posting Type"::"Custom 2":
                    begin
                        if NewAmount > 0 then
                            if FAPostingTypeSetup.Sign = FAPostingTypeSetup.Sign::Credit then
                                CreatePostingTypeError();
                        if NewAmount < 0 then
                            if FAPostingTypeSetup.Sign = FAPostingTypeSetup.Sign::Debit then
                                CreatePostingTypeError();
                    end;
            end;
            if BookValue + SalvageValue < 0 then
                if not DeprBook."Allow Depr. below Zero" or
                   ("FA Posting Type" <> "FA Posting Type"::Depreciation)
                then
                    if not DeprBook."Allow Acq. Cost below Zero" or
                       ("FA Posting Type" <> "FA Posting Type"::"Acquisition Cost") or
                       not "Index Entry"
                    then begin
                        if "Reclassification Entry" and (SalvageValue <> 0) then
                            Error(SalvageValueErr);
                        CreateBookValueError();
                    end;
            if DeprBasis < 0 then
                CreateDeprBasisError();
        end;
    end;

    procedure CheckDisposalDate(FADeprBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    begin
        if FADeprBook."Disposal Date" > 0D then
            CreateDisposedError(FixedAsset, FADeprBook."Depreciation Book Code");
    end;

    local procedure CreateAcquisitionCostError()
    begin
        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Acquisition Cost";
        Error(Text000,
          FAName(), FAJnlLine."FA Posting Type");
    end;

    local procedure CreateDisposedError(FixedAsset: Record "Fixed Asset"; DeprBookCode: Code[10])
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDisposerError(FixedAsset, DeprBookCode, IsHandled, FALedgEntry);
        if not IsHandled then
            Error(Text001, DepreciationCalc.FAName(FixedAsset, DeprBookCode));
    end;

    local procedure CreateDisposalError()
    begin
        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Disposal;
        Error(InvalidDisposalDateErr, FA."No.", FADeprBookName());
    end;

    local procedure CreatePostingTypeError()
    var
        AccumText: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostingTypeError(FAJnlLine, FALedgEntry2, DeprBook, IsHandled);
        if IsHandled then
            exit;

        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(FALedgEntry2.ConvertPostingType());
        if FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Depreciation then
            AccumText := StrSubstNo('%1 %2', Text003, '');
        if NewAmount > 0 then
            Error(Text004, FAName(), AccumText, FAJnlLine."FA Posting Type", FALedgEntry."FA Posting Date");
        if NewAmount < 0 then
            Error(Text005, FAName(), AccumText, FAJnlLine."FA Posting Type", FALedgEntry."FA Posting Date");
    end;

    local procedure CreateBookValueError()
    begin
        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Salvage Value";
        Error(
          Text006,
          FAName(), FADeprBook.FieldCaption("Book Value"), FAJnlLine."FA Posting Type", FALedgEntry."FA Posting Date");
    end;

    local procedure CreateDeprBasisError()
    begin
        Error(
          Text007, FAName(), FADeprBook.FieldCaption("Depreciable Basis"), FALedgEntry."FA Posting Date");
    end;

    local procedure FAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure FADeprBookName(): Text[200]
    var
        DepreciationCalculation: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalculation.FADeprBookName(DeprBookCode));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckForError(FALedgEntry2: Record "FA Ledger Entry"; var FAJnlLine: Record "FA Journal Line"; FAPostingTypeSetup: Record "FA Posting Type Setup"; NewAmount: Decimal; BookValue: Decimal; SalvageValue: Decimal; DeprBasis: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnBeforeCalcSumsForBookValue(var FALedgerEntry: Record "FA Ledger Entry"; FAPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnBeforeFind(var FALedgerEntry: Record "FA Ledger Entry"; FAPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnAfterSetFALedgerEntryFilters(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesPostingOnAfterSetFALedgerEntryFilters(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesPostingOnBeforeFirstFind(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFAPostingDateOnBeforeFADeprBookModify(var FADepreciationBook: Record "FA Depreciation Book"; var FALedgerEntry: Record "FA Ledger Entry"; MaxDate: Date; MinDate: Date; GLDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDisposerError(FixedAsset: Record "Fixed Asset"; DeprBookCode: code[10]; var IsHandled: Boolean; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostingTypeError(
        FAJnlLine: Record "FA Journal Line";
        FALedgEntry2: Record "FA Ledger Entry";
        DeprBook: Record "Depreciation Book";
        var IsHandled: Boolean)
    begin
    end;
}

