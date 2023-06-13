codeunit 5631 "FA Jnl.-Check Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        CheckJobNo(Rec);
        TestField("FA Posting Type");
        TestField("Depreciation Book Code");
        if "Duplicate in Depreciation Book" = "Depreciation Book Code" then
            FieldError(
              "Duplicate in Depreciation Book",
              StrSubstNo(Text000, FieldCaption("Depreciation Book Code")));
        if "Account Type" = "Bal. Account Type" then
            Error(
              Text001,
              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"), "Account Type");
        if "Account No." <> '' then
            CheckAccountNo(Rec);

        if "Bal. Account No." <> '' then
            CheckBalAccountNo(Rec);

        if "Recurring Method".AsInteger() > "Recurring Method"::"V  Variable".AsInteger() then begin
            GenJnlline2."Account Type" := GenJnlline2."Account Type"::"Fixed Asset";
            FieldError(
              "Recurring Method",
              StrSubstNo(Text002,
                "Recurring Method",
                FieldCaption("Account Type"),
                FieldCaption("Bal. Account Type"),
                GenJnlline2."Account Type"));
        end;
        DeprBookCode := "Depreciation Book Code";
        if "FA Posting Date" = 0D then
            "FA Posting Date" := "Posting Date";
        FAPostingDate := "FA Posting Date";
        PostingDate := "Posting Date";
        FAPostingType := "FA Journal Line FA Posting Type".FromInteger("FA Posting Type".AsInteger() - 1);
        GenJnlPosting := true;
        GenJnlLine := Rec;
        CheckJnlLine();
        CheckFADepAcrossFiscalYear();

        OnAfterCheckGenJnlLine(Rec);
    end;

    var
        UserSetup: Record "User Setup";
        FASetup: Record "FA Setup";
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlline2: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        DimMgt: Codeunit DimensionManagement;
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        GenJnlPosting: Boolean;
        FANo: Code[20];
        DeprBookCode: Code[10];
        PostingDate: Date;
        FAPostingDate: Date;
        FAPostingType: Enum "FA Journal Line FA Posting Type";
        FieldErrorText: Text[250];

        Text000: Label 'is not different than %1';
        Text001: Label '%1 and %2 must not both be %3.';
        Text002: Label 'must not be %1 when %2 or %3 are %4';
        Text003: Label 'can only be a closing date for G/L entries';
        Text004: Label 'is not within your range of allowed posting dates';
        Text005: Label 'must be identical to %1';
        Text006: Label 'must not be a %1';
        Text007: Label '%1 must be posted in the general journal';
        Text008: Label '%1 must be posted in the FA journal';
        Text009: Label 'must not be specified when %1 = %2 in %3';
        Text010: Label 'must not be specified when %1 is specified';
        Text011: Label 'must not be specified together with %1 = %2';
        Text012: Label 'must not be specified when %1 is a %2';
        Text013: Label 'is a %1';
        Text014: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text015: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';
        Text016: Label '%1 + %2 must be %3.';
        Text017: Label '%1 + %2 must be -%3.';
        Text018: Label 'You cannot dispose Main Asset %1 until Components are disposed.';
        Text019Err: Label 'You cannot post depreciation, because the calculation is across different fiscal year periods, which is not supported.';

    procedure CheckFAJnlLine(var FAJournalLine: Record "FA Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        with FAJournalLine do begin
            if "FA No." = '' then
                exit;
            TestField("FA Posting Date");
            TestField("Depreciation Book Code");
            TestField("Document No.");
            if "Duplicate in Depreciation Book" = "Depreciation Book Code" then
                FieldError("Duplicate in Depreciation Book",
                  StrSubstNo(Text000, FieldCaption("Depreciation Book Code")));
            FANo := "FA No.";
            PostingDate := "Posting Date";
            FAPostingDate := "FA Posting Date";
            if PostingDate = 0D then
                PostingDate := FAPostingDate;
            DeprBookCode := "Depreciation Book Code";
            FAPostingType := "FA Posting Type";
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                Error(
                  Text014,
                  TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                  DimMgt.GetDimCombErr());

            TableID[1] := DATABASE::"Fixed Asset";
            No[1] := "FA No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                if "Line No." <> 0 then
                    Error(
                      Text015,
                      TableCaption, "Journal Template Name", "Journal Batch Name", "Line No.",
                      DimMgt.GetDimValuePostingErr())
                else
                    Error(DimMgt.GetDimValuePostingErr());
        end;
        GenJnlPosting := false;
        OnCheckFAJnlLineOnBeforeCheckJnlLine(FAJournalLine);
        FAJnlLine := FAJournalLine;
        CheckJnlLine();

        OnAfterCheckFAJnlLine(FAJournalLine);
    end;

    local procedure CheckAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountNo(GenJournalLine, FANo, IsHandled);
        if IsHandled then
            exit;

        with GenJournalLine do
            if "Account Type" = "Account Type"::"Fixed Asset" then begin
                if "FA Posting Type" in
                   ["FA Posting Type"::"Acquisition Cost",
                    "FA Posting Type"::Appreciation,
                    "FA Posting Type"::Disposal,
                    "FA Posting Type"::Maintenance]
                then begin
                    if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                       ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                    then
                        TestField("Gen. Posting Type");
                    if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and
                       ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                    then begin
                        if "VAT Amount" + "VAT Base Amount" <> Amount then
                            Error(
                              Text016, FieldCaption("VAT Amount"), FieldCaption("VAT Base Amount"),
                              FieldCaption(Amount));
                        if "Currency Code" <> '' then
                            if "VAT Amount (LCY)" + "VAT Base Amount (LCY)" <> "Amount (LCY)" then
                                Error(
                                  Text016, FieldCaption("VAT Amount (LCY)"),
                                  FieldCaption("VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)"));
                    end;
                end else begin
                    TestField("Gen. Posting Type", 0);
                    TestField("Gen. Bus. Posting Group", '');
                    TestField("Gen. Prod. Posting Group", '');
                    TestField("VAT Bus. Posting Group", '');
                    TestField("VAT Prod. Posting Group", '');
                end;
                FANo := "Account No.";
            end;
    end;

    local procedure CheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountNo(GenJournalLine, FANo, IsHandled);
        if IsHandled then
            exit;

        with GenJournalLine do
            if "Bal. Account Type" = "Bal. Account Type"::"Fixed Asset" then begin
                if "FA Posting Type" in
                   ["FA Posting Type"::"Acquisition Cost",
                    "FA Posting Type"::Disposal,
                    "FA Posting Type"::Maintenance]
                then begin
                    if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                       ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                    then
                        TestField("Bal. Gen. Posting Type");
                    if ("Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" ") and
                       ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                    then begin
                        if "Bal. VAT Amount" + "Bal. VAT Base Amount" <> -Amount then
                            Error(
                              Text017, FieldCaption("Bal. VAT Amount"), FieldCaption("Bal. VAT Base Amount"),
                              FieldCaption(Amount));
                        if "Currency Code" <> '' then
                            if "Bal. VAT Amount (LCY)" + "Bal. VAT Base Amount (LCY)" <> -"Amount (LCY)" then
                                Error(
                                  Text017, FieldCaption("Bal. VAT Amount (LCY)"),
                                  FieldCaption("Bal. VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)"));
                    end;
                end else begin
                    TestField("Bal. Gen. Posting Type", 0);
                    TestField("Bal. Gen. Bus. Posting Group", '');
                    TestField("Bal. Gen. Prod. Posting Group", '');
                    TestField("Bal. VAT Bus. Posting Group", '');
                    TestField("Bal. VAT Prod. Posting Group", '');
                end;
                FANo := "Bal. Account No.";
            end;
    end;

    local procedure CheckJnlLine()
    begin
        FA.Get(FANo);
        FASetup.Get();
        DeprBook.Get(DeprBookCode);
        FADeprBook.Get(FANo, DeprBookCode);
        CheckFAPostingDate();
        CheckFAIntegration();
        CheckConsistency();
        CheckErrorNo();
        CheckMainAsset();
    end;

    local procedure CheckJobNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckJobNo(GenJournalLine, IsHandled);
        if IsHandled then
            exit;

        GenJournalLine.TestField("Job No.", '');
    end;

    local procedure CheckFAPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAPostingDate(GenJnlLine, FAJnlLine, DeprBook, IsHandled, FADeprBook, GenJnlPosting);
        if IsHandled then
            exit;

        if FAPostingDate <> NormalDate(FAPostingDate) then
            if GenJnlPosting then
                GenJnlLine.FieldError("FA Posting Date", Text003)
            else
                FAJnlLine.FieldError("FA Posting Date", Text003);

        if (FAPostingDate < DMY2Date(1, 1, 2)) or
           (FAPostingDate > DMY2Date(31, 12, 9998))
        then
            if GenJnlPosting then
                GenJnlLine.FieldError("FA Posting Date", Text004)
            else
                FAJnlLine.FieldError("FA Posting Date", Text004);

        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
            if UserId <> '' then
                if UserSetup.Get(UserId) then begin
                    AllowPostingFrom := UserSetup."Allow FA Posting From";
                    AllowPostingTo := UserSetup."Allow FA Posting To";
                end;
            if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                FASetup.Get();
                AllowPostingFrom := FASetup."Allow FA Posting From";
                AllowPostingTo := FASetup."Allow FA Posting To";
            end;
            if AllowPostingTo = 0D then
                AllowPostingTo := DMY2Date(31, 12, 9998);
        end;
        if (FAPostingDate < AllowPostingFrom) or
           (FAPostingDate > AllowPostingTo)
        then
            if GenJnlPosting then
                GenJnlLine.FieldError("FA Posting Date", Text004)
            else
                FAJnlLine.FieldError("FA Posting Date", Text004);

        if DeprBook."Use Same FA+G/L Posting Dates" and (PostingDate <> FAPostingDate) then begin
            if GenJnlPosting then
                GenJnlLine.FieldError(
                  "FA Posting Date", StrSubstNo(Text005,
                    GenJnlLine.FieldCaption("Posting Date")));

            FAJnlLine.FieldError(
              "Posting Date", StrSubstNo(Text005,
                FAJnlLine.FieldCaption("FA Posting Date")))
        end;
    end;

    local procedure CheckFAIntegration()
    var
        GLIntegration: Boolean;
    begin
        if GenJnlPosting and FA."Budgeted Asset" then
            GenJnlLine.FieldError("Account No.", StrSubstNo(Text006, FA.FieldCaption("Budgeted Asset")));
        if FA."Budgeted Asset" then
            exit;
        case FAPostingType of
            FAPostingType::"Acquisition Cost":
                GLIntegration := DeprBook."G/L Integration - Acq. Cost";
            FAPostingType::Depreciation:
                GLIntegration := DeprBook."G/L Integration - Depreciation";
            FAPostingType::"Write-Down":
                GLIntegration := DeprBook."G/L Integration - Write-Down";
            FAPostingType::Appreciation:
                GLIntegration := DeprBook."G/L Integration - Appreciation";
            FAPostingType::"Custom 1":
                GLIntegration := DeprBook."G/L Integration - Custom 1";
            FAPostingType::"Custom 2":
                GLIntegration := DeprBook."G/L Integration - Custom 2";
            FAPostingType::Disposal:
                GLIntegration := DeprBook."G/L Integration - Disposal";
            FAPostingType::Maintenance:
                GLIntegration := DeprBook."G/L Integration - Maintenance";
            FAPostingType::"Salvage Value":
                GLIntegration := false;
        end;

        OnAfterSetGLIntegration(FAPostingType, GLIntegration, GenJnlPosting, DeprBook);

        if GLIntegration and not GenJnlPosting then
            FAJnlLine.FieldError(
              "FA Posting Type",
              StrSubstNo(Text007, FAJnlLine."FA Posting Type"));
        if not GLIntegration and GenJnlPosting then
            GenJnlLine.FieldError(
              "FA Posting Type",
              StrSubstNo(Text008, GenJnlLine."FA Posting Type"));

        GLIntegration := DeprBook."G/L Integration - Depreciation";
        if GenJnlPosting then
            with GenJnlLine do begin
                if "Depr. until FA Posting Date" and not GLIntegration then
                    FieldError(
                      "Depr. until FA Posting Date", StrSubstNo(Text009,
                        DeprBook.FieldCaption("G/L Integration - Depreciation"), false, DeprBook.TableCaption()));
                if "Depr. Acquisition Cost" and not GLIntegration then
                    FieldError(
                      "Depr. Acquisition Cost", StrSubstNo(Text009,
                        DeprBook.FieldCaption("G/L Integration - Depreciation"), false, DeprBook.TableCaption()));
            end;
        if not GenJnlPosting then
            with FAJnlLine do begin
                if "Depr. until FA Posting Date" and GLIntegration then
                    FieldError(
                      "Depr. until FA Posting Date", StrSubstNo(Text009,
                        DeprBook.FieldCaption("G/L Integration - Depreciation"), true, DeprBook.TableCaption()));
                if "Depr. Acquisition Cost" and GLIntegration then
                    FieldError(
                      "Depr. Acquisition Cost", StrSubstNo(Text009,
                        DeprBook.FieldCaption("G/L Integration - Depreciation"), true, DeprBook.TableCaption()));
            end;
    end;

    local procedure CheckErrorNo()
    begin
        if GenJnlPosting and (GenJnlLine."FA Error Entry No." > 0) then
            with GenJnlLine do begin
                FieldErrorText :=
                  StrSubstNo(Text010,
                    FieldCaption("FA Error Entry No."));
                case true of
                    "Depr. until FA Posting Date":
                        FieldError("Depr. until FA Posting Date", FieldErrorText);
                    "Depr. Acquisition Cost":
                        FieldError("Depr. Acquisition Cost", FieldErrorText);
                    "Duplicate in Depreciation Book" <> '':
                        FieldError("Duplicate in Depreciation Book", FieldErrorText);
                    "Use Duplication List":
                        FieldError("Use Duplication List", FieldErrorText);
                    "Salvage Value" <> 0:
                        FieldError("Salvage Value", FieldErrorText);
                    "Insurance No." <> '':
                        FieldError("Insurance No.", FieldErrorText);
                    "Budgeted FA No." <> '':
                        FieldError("Budgeted FA No.", FieldErrorText);
                    "Recurring Method" <> "Recurring Method"::" ":
                        FieldError("Recurring Method", FieldErrorText);
                end;
            end;
        if not GenJnlPosting and (FAJnlLine."FA Error Entry No." > 0) then
            with FAJnlLine do begin
                FieldErrorText :=
                  StrSubstNo(Text010,
                    FieldCaption("FA Error Entry No."));
                case true of
                    "Depr. until FA Posting Date":
                        FieldError("Depr. until FA Posting Date", FieldErrorText);
                    "Depr. Acquisition Cost":
                        FieldError("Depr. Acquisition Cost", FieldErrorText);
                    "Duplicate in Depreciation Book" <> '':
                        FieldError("Duplicate in Depreciation Book", FieldErrorText);
                    "Use Duplication List":
                        FieldError("Use Duplication List", FieldErrorText);
                    "Salvage Value" <> 0:
                        FieldError("Salvage Value", FieldErrorText);
                    "Insurance No." <> '':
                        FieldError("Insurance No.", FieldErrorText);
                    "Budgeted FA No." <> '':
                        FieldError("Budgeted FA No.", FieldErrorText);
                    "Recurring Method" > 0:
                        FieldError("Recurring Method", FieldErrorText);
                end;
            end;
    end;

    local procedure CheckConsistency()
    var
        IsHandled: Boolean;
        ShouldCheckNoOfDepreciationDays: Boolean;
    begin
        if GenJnlPosting then
            with GenJnlLine do begin
                if "Journal Template Name" = '' then
                    Quantity := 0;
                FieldErrorText :=
                  StrSubstNo(Text011,
                    FieldCaption("FA Posting Type"), "FA Posting Type");
                if ("FA Error Entry No." > 0) and ("FA Posting Type" = "FA Posting Type"::Maintenance) then
                    FieldError("FA Error Entry No.", FieldErrorText);
                if not IsAcquisitionCost() then
                    case true of
                        "Depr. Acquisition Cost":
                            FieldError("Depr. Acquisition Cost", FieldErrorText);
                        "Salvage Value" <> 0:
                            FieldError("Salvage Value", FieldErrorText);
                        "Insurance No." <> '':
                            FieldError("Insurance No.", FieldErrorText);
                        Quantity <> 0:
                            begin
                                IsHandled := false;
                                OnCheckConsistencyOnBeforeCheckQuantity(GenJnlLine, IsHandled, FAJnlLine);
                                if not IsHandled then
                                    if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                                        FieldError(Quantity, FieldErrorText);
                            end;
                    end;
                if ("FA Posting Type" <> "FA Posting Type"::Maintenance) and
                   ("Maintenance Code" <> '')
                then
                    FieldError("Maintenance Code", FieldErrorText);
                if "FA Posting Type" = "FA Posting Type"::Maintenance then
                    if "Depr. until FA Posting Date" then
                        FieldError("Depr. until FA Posting Date", FieldErrorText);

                ShouldCheckNoOfDepreciationDays := ("FA Posting Type" <> "FA Posting Type"::Depreciation) and ("FA Posting Type" <> "FA Posting Type"::"Custom 1") and ("No. of Depreciation Days" <> 0);
                OnCheckConsistencyOnAfterCalcShouldCheckNoOfDepreciationDays(GenJnlLine, FieldErrorText, ShouldCheckNoOfDepreciationDays);
                if ShouldCheckNoOfDepreciationDays then
                    FieldError("No. of Depreciation Days", FieldErrorText);

                if "FA Posting Type" = "FA Posting Type"::Disposal then begin
                    if "FA Reclassification Entry" then
                        FieldError("FA Reclassification Entry", FieldErrorText);
                    if "Budgeted FA No." <> '' then
                        FieldError("Budgeted FA No.", FieldErrorText);
                end;

                FieldErrorText := StrSubstNo(Text012,
                    FieldCaption("Account No."), FA.FieldCaption("Budgeted Asset"));

                if FA."Budgeted Asset" and ("Budgeted FA No." <> '') then
                    FieldError("Budgeted FA No.", FieldErrorText);

                if IsAcquisitionCost() and
                   ("Insurance No." <> '') and
                   (DeprBook.Code <> FASetup."Insurance Depr. Book")
                then
                    TestField("Insurance No.", '');

                if FA."Budgeted Asset" then
                    FieldError("Account No.", StrSubstNo(Text013, FA.FieldCaption("Budgeted Asset")));
            end;

        if not GenJnlPosting then
            with FAJnlLine do begin
                FieldErrorText :=
                  StrSubstNo(Text011,
                    FieldCaption("FA Posting Type"), "FA Posting Type");

                if ("FA Error Entry No." > 0) and ("FA Posting Type" = "FA Posting Type"::Maintenance) then
                    FieldError("FA Error Entry No.", FieldErrorText);

                if not IsAcquisitionCost() then
                    case true of
                        "Depr. Acquisition Cost":
                            FieldError("Depr. Acquisition Cost", FieldErrorText);
                        "Salvage Value" <> 0:
                            FieldError("Salvage Value", FieldErrorText);
                        Quantity <> 0:
                            begin
                                IsHandled := false;
                                OnCheckConsistencyOnBeforeCheckQuantity(GenJnlLine, IsHandled, FAJnlLine);
                                if not IsHandled then
                                    if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                                        FieldError(Quantity, FieldErrorText);
                            end;
                        "Insurance No." <> '':
                            FieldError("Insurance No.", FieldErrorText);
                    end;
                if ("FA Posting Type" = "FA Posting Type"::Maintenance) and
                   "Depr. until FA Posting Date"
                then
                    FieldError("Depr. until FA Posting Date", FieldErrorText);
                if ("FA Posting Type" <> "FA Posting Type"::Maintenance) and
                   ("Maintenance Code" <> '')
                then
                    FieldError("Maintenance Code", FieldErrorText);

                if ("FA Posting Type" <> "FA Posting Type"::Depreciation) and
                   ("FA Posting Type" <> "FA Posting Type"::"Custom 1") and
                   ("No. of Depreciation Days" <> 0)
                then
                    FieldError("No. of Depreciation Days", FieldErrorText);

                if "FA Posting Type" = "FA Posting Type"::Disposal then begin
                    if "FA Reclassification Entry" then
                        FieldError("FA Reclassification Entry", FieldErrorText);
                    if "Budgeted FA No." <> '' then
                        FieldError("Budgeted FA No.", FieldErrorText);
                end;

                FieldErrorText := StrSubstNo(Text012,
                    FieldCaption("FA No."), FA.FieldCaption("Budgeted Asset"));

                if FA."Budgeted Asset" and ("Budgeted FA No." <> '') then
                    FieldError("Budgeted FA No.", FieldErrorText);

                if IsAcquisitionCost() and
                   ("Insurance No." <> '') and
                   (DeprBook.Code <> FASetup."Insurance Depr. Book")
                then
                    TestField("Insurance No.", '');
            end;
    end;

    local procedure CheckMainAsset()
    var
        MainAssetComponent: Record "Main Asset Component";
        ComponentFADeprBook: Record "FA Depreciation Book";
    begin
        if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Disposal then
            exit;
        if FA."Main Asset/Component" <> FA."Main Asset/Component"::"Main Asset" then
            exit;

        with MainAssetComponent do begin
            Reset();
            SetRange("Main Asset No.", FA."No.");
            if FindSet() then
                repeat
                    if ComponentFADeprBook.Get("FA No.", DeprBookCode) then
                        if ComponentFADeprBook."Disposal Date" = 0D then
                            Error(Text018, FA."No.");
                until Next() = 0;
        end;
    end;

    local procedure CheckFADepAcrossFiscalYear()
    var
        AccPeriod: Record "Accounting Period";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        EndingDate: Date;
        StartingDate: Date;
    begin
        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Depreciation) and
           (GenJnlLine."No. of Depreciation Days" <> 0) and
           (FADeprBook."Depreciation Method" = FADeprBook."Depreciation Method"::"Declining-Balance 1")
        then begin
            EndingDate := DepreciationCalculation.ToMorrow(GenJnlLine."FA Posting Date", DeprBook."Fiscal Year 365 Days");
            if DeprBook."Fiscal Year 365 Days" then
                StartingDate := CalcDate(StrSubstNo('<-%1D>', GenJnlLine."No. of Depreciation Days"), EndingDate)
            else begin
                StartingDate := CalcDate(StrSubstNo('<-%1M>', GenJnlLine."No. of Depreciation Days" div 30), EndingDate);
                StartingDate := CalcDate(StrSubstNo('<-%1D>', GenJnlLine."No. of Depreciation Days" mod 30), StartingDate);
            end;
            AccPeriod.SetFilter("Starting Date", '>%1&<=%2', AccountingPeriodMgt.FindFiscalYear(StartingDate), GenJnlLine."FA Posting Date");
            AccPeriod.SetRange("New Fiscal Year", true);
            if not AccPeriod.IsEmpty() then
                Error(Text019Err);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFAJnlLine(var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGLIntegration(FAPostingType: Enum "FA Journal Line FA Posting Type"; var GLIntegration: Boolean; var GnlJnlPosting: Boolean; DeprBook: Record "Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAPostingDate(GenJournalLine: Record "Gen. Journal Line"; FAJournalLine: Record "FA Journal Line"; DepreciationBook: Record "Depreciation Book"; var IsHandled: Boolean; FADepreciationBook: Record "FA Depreciation Book"; GenJnlPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var FANo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalAccountNo(var GenJournalLine: Record "Gen. Journal Line"; var FANo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckConsistencyOnAfterCalcShouldCheckNoOfDepreciationDays(GenJournalLine: Record "Gen. Journal Line"; FieldErrorText: Text[250]; var ShouldCheckNoOfDepreciationDays: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckConsistencyOnBeforeCheckQuantity(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckFAJnlLineOnBeforeCheckJnlLine(var FAJournalLine2: Record "FA Journal Line")
    begin
    end;
}

