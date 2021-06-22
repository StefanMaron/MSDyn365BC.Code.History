codeunit 5640 "Duplicate Depr. Book"
{

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlLine2: Record "Gen. Journal Line";
        FAJnlLine2: Record "FA Journal Line";
        DeprBook: Record "Depreciation Book";
        DimMgt: Codeunit DimensionManagement;
        FAGetJnl: Codeunit "FA Get Journal";
        InsuranceJnlPostLine: Codeunit "Insurance Jnl.-Post Line";
        FAAmount: Decimal;
        DuplicateInGenJnl: Boolean;
        TemplateName: Code[10];
        BatchName: Code[10];
        ExchangeRate: Decimal;
        NextLineNo: Integer;

    procedure DuplicateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; FAAmount2: Decimal)
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        OnBeforeGenJnlLineDuplicate(GenJnlLine, FAAmount2);

        with GenJnlLine do begin
            FAAmount := FAAmount2;
            DeprBook.Get("Depreciation Book Code");
            if "Insurance No." <> '' then
                InsertInsurance(true, GenJnlLine, FAJnlLine2);
            if ("Duplicate in Depreciation Book" = '') and
               (not "Use Duplication List")
            then
                exit;
            ExchangeRate := GetExchangeRate("Account No.", DeprBook);
            if "Duplicate in Depreciation Book" <> '' then begin
                DeprBook.Get("Duplicate in Depreciation Book");
                CreateLine(true, GenJnlLine, FAJnlLine2);
                exit;
            end;
            if "Use Duplication List" then
                if DeprBook.Find('-') then
                    repeat
                        if DeprBook."Part of Duplication List" and (DeprBook.Code <> "Depreciation Book Code") then
                            if FADeprBook.Get("Account No.", DeprBook.Code) then
                                CreateLine(true, GenJnlLine, FAJnlLine2);
                    until DeprBook.Next = 0;
        end;
    end;

    procedure DuplicateFAJnlLine(var FAJnlLine: Record "FA Journal Line")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        with FAJnlLine do begin
            DeprBook.Get("Depreciation Book Code");
            if "Insurance No." <> '' then
                InsertInsurance(false, GenJnlLine2, FAJnlLine);
            if ("Duplicate in Depreciation Book" = '') and
               (not "Use Duplication List")
            then
                exit;
            FA.Get("FA No.");
            ExchangeRate := GetExchangeRate("FA No.", DeprBook);
            if "Duplicate in Depreciation Book" <> '' then begin
                DeprBook.Get("Duplicate in Depreciation Book");
                CreateLine(false, GenJnlLine2, FAJnlLine);
                exit;
            end;
            if "Use Duplication List" then
                if DeprBook.Find('-') then
                    repeat
                        if DeprBook."Part of Duplication List" and (DeprBook.Code <> "Depreciation Book Code") then
                            if FADeprBook.Get(FA."No.", DeprBook.Code) then
                                CreateLine(false, GenJnlLine2, FAJnlLine);
                    until DeprBook.Next = 0;
        end;
    end;

    local procedure InsertInsurance(GenJnlPosting: Boolean; GenJnlLine: Record "Gen. Journal Line"; FAJnlLine: Record "FA Journal Line")
    var
        InsuranceJnlLine: Record "Insurance Journal Line";
    begin
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book", DeprBook.Code);
        InsuranceJnlLine.Init();
        InsuranceJnlLine."Line No." := 0;
        if not FASetup."Automatic Insurance Posting" then
            InitInsuranceJnlLine(InsuranceJnlLine);

        with InsuranceJnlLine do begin
            if GenJnlPosting then begin
                if FASetup."Automatic Insurance Posting" then begin
                    "Journal Batch Name" := GenJnlLine."Journal Batch Name";
                    "Source Code" := GenJnlLine."Source Code";
                    "Reason Code" := GenJnlLine."Reason Code"
                end;
                Validate("Insurance No.", GenJnlLine."Insurance No.");
                Validate("FA No.", GenJnlLine."Account No.");
                "Posting Date" := GenJnlLine."FA Posting Date";
                if "Posting Date" = 0D then
                    "Posting Date" := GenJnlLine."Posting Date";
                Validate(Amount, FAAmount);
                "Document Type" := GenJnlLine."Document Type";
                "Document Date" := GenJnlLine."Document Date";
                if "Document Date" = 0D then
                    "Document Date" := "Posting Date";
                "Document No." := GenJnlLine."Document No.";
                "External Document No." := GenJnlLine."External Document No.";
                if not DeprBook."Use Default Dimension" then begin
                    "Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
                    "Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
                    "Dimension Set ID" := GenJnlLine."Dimension Set ID";
                end;
            end;
            if not GenJnlPosting then begin
                if FASetup."Automatic Insurance Posting" then begin
                    "Journal Batch Name" := FAJnlLine."Journal Batch Name";
                    "Source Code" := FAJnlLine."Source Code";
                    "Reason Code" := FAJnlLine."Reason Code"
                end;
                Validate("Insurance No.", FAJnlLine."Insurance No.");
                Validate("FA No.", FAJnlLine."FA No.");
                "Posting Date" := FAJnlLine."FA Posting Date";
                Validate(Amount, FAJnlLine.Amount);
                "Document Type" := FAJnlLine."Document Type";
                "Document Date" := FAJnlLine."Document Date";
                if "Document Date" = 0D then
                    "Document Date" := "Posting Date";
                "Document No." := FAJnlLine."Document No.";
                "External Document No." := FAJnlLine."External Document No.";
                if not DeprBook."Use Default Dimension" then begin
                    "Shortcut Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
                    "Shortcut Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
                    "Dimension Set ID" := FAJnlLine."Dimension Set ID";
                end;
            end;
            if FASetup."Automatic Insurance Posting" then
                InsuranceJnlPostLine.RunWithCheck(InsuranceJnlLine)
            else begin
                "Line No." := NextLineNo;
                if DeprBook."Use Default Dimension" then
                    CreateDim(DATABASE::Insurance, "Insurance No.");
                Insert(true);
            end;
        end;
    end;

    procedure InitInsuranceJnlLine(var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        InsuranceJnlLine2: Record "Insurance Journal Line";
    begin
        with InsuranceJnlLine do begin
            FAGetJnl.InsuranceJnlName(DeprBook.Code, TemplateName, BatchName);
            "Journal Template Name" := TemplateName;
            "Journal Batch Name" := BatchName;
            LockTable();
            FAGetJnl.SetInsuranceJnlRange(InsuranceJnlLine2, TemplateName, BatchName);
            NextLineNo := InsuranceJnlLine2."Line No." + 10000;
            "Posting No. Series" := FAJnlSetup.GetInsuranceNoSeries(InsuranceJnlLine);
        end;
    end;

    local procedure CreateLine(GenJnlPosting: Boolean; var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    begin
        if GenJnlPosting then
            with GenJnlLine do begin
                DuplicateInGenJnl := true;
                TemplateName := "Journal Template Name";
                BatchName := "Journal Batch Name";
                FAGetJnl.JnlName(
                  DeprBook.Code, false, "FA Posting Type" - 1,
                  DuplicateInGenJnl, TemplateName, BatchName);
            end;
        if not GenJnlPosting then
            with FAJnlLine do begin
                FA.Get("FA No.");
                DuplicateInGenJnl := false;
                TemplateName := "Journal Template Name";
                BatchName := "Journal Batch Name";
                FAGetJnl.JnlName(
                  DeprBook.Code, FA."Budgeted Asset", "FA Posting Type",
                  DuplicateInGenJnl, TemplateName, BatchName);
            end;
        InsertLine(GenJnlPosting, DuplicateInGenJnl, GenJnlLine, FAJnlLine);
    end;

    local procedure MakeGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    begin
        with GenJnlLine do begin
            "Account Type" := "Account Type"::"Fixed Asset";
            "Account No." := FAJnlLine."FA No.";
            "Depreciation Book Code" := FAJnlLine."Depreciation Book Code";
            "FA Posting Type" := FAJnlLine."FA Posting Type" + 1;
            "FA Posting Date" := FAJnlLine."FA Posting Date";
            "Posting Date" := FAJnlLine."Posting Date";
            if "Posting Date" = "FA Posting Date" then
                "FA Posting Date" := 0D;
            "Document Type" := FAJnlLine."Document Type";
            "Document Date" := FAJnlLine."Document Date";
            "Document No." := FAJnlLine."Document No.";
            "External Document No." := FAJnlLine."External Document No.";
            Description := FAJnlLine.Description;
            Validate(Amount, FAJnlLine.Amount);
            "Salvage Value" := FAJnlLine."Salvage Value";
            Quantity := FAJnlLine.Quantity;
            Validate(Correction, FAJnlLine.Correction);
            "No. of Depreciation Days" := FAJnlLine."No. of Depreciation Days";
            "Depr. until FA Posting Date" := FAJnlLine."Depr. until FA Posting Date";
            "Depr. Acquisition Cost" := FAJnlLine."Depr. Acquisition Cost";
            "Posting Group" := FAJnlLine."FA Posting Group";
            "Maintenance Code" := FAJnlLine."Maintenance Code";
            "Shortcut Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := FAJnlLine."Dimension Set ID";
            "Budgeted FA No." := FAJnlLine."Budgeted FA No.";
            "FA Reclassification Entry" := FAJnlLine."FA Reclassification Entry";
            "Index Entry" := FAJnlLine."Index Entry"
        end;

        OnAfterMakeGenJnlLine(GenJnlLine, FAJnlLine);
    end;

    local procedure MakeFAJnlLine(var FAJnlLine: Record "FA Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        with FAJnlLine do begin
            "Depreciation Book Code" := GenJnlLine."Depreciation Book Code";
            "FA Posting Type" := GenJnlLine."FA Posting Type" - 1;
            "FA No." := GenJnlLine."Account No.";
            "FA Posting Date" := GenJnlLine."FA Posting Date";
            "Posting Date" := GenJnlLine."Posting Date";
            if "Posting Date" = "FA Posting Date" then
                "Posting Date" := 0D;
            "Document Type" := GenJnlLine."Document Type";
            "Document Date" := GenJnlLine."Document Date";
            "Document No." := GenJnlLine."Document No.";
            "External Document No." := GenJnlLine."External Document No.";
            Description := GenJnlLine.Description;
            Validate(Amount, FAAmount);
            "Salvage Value" := GenJnlLine."Salvage Value";
            Quantity := GenJnlLine.Quantity;
            Validate(Correction, GenJnlLine.Correction);
            "No. of Depreciation Days" := GenJnlLine."No. of Depreciation Days";
            "Depr. until FA Posting Date" := GenJnlLine."Depr. until FA Posting Date";
            "Depr. Acquisition Cost" := GenJnlLine."Depr. Acquisition Cost";
            "FA Posting Group" := GenJnlLine."Posting Group";
            "Maintenance Code" := GenJnlLine."Maintenance Code";
            "Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := GenJnlLine."Dimension Set ID";
            "Budgeted FA No." := GenJnlLine."Budgeted FA No.";
            "FA Reclassification Entry" := GenJnlLine."FA Reclassification Entry";
            "Index Entry" := GenJnlLine."Index Entry"
        end;

        OnAfterMakeFAJnlLine(FAJnlLine, GenJnlLine);
    end;

    local procedure AdjustGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2 := GenJnlLine;
        with GenJnlLine do begin
            Init;
            "Account Type" := "Account Type"::"Fixed Asset";
            "Depreciation Book Code" := GenJnlLine2."Depreciation Book Code";
            "FA Posting Type" := GenJnlLine2."FA Posting Type";
            "Account No." := GenJnlLine2."Account No.";
            "FA Posting Date" := GenJnlLine2."FA Posting Date";
            "Posting Date" := GenJnlLine2."Posting Date";
            if "Posting Date" = "FA Posting Date" then
                "FA Posting Date" := 0D;
            "Document Type" := GenJnlLine2."Document Type";
            "Document Date" := GenJnlLine2."Document Date";
            "Document No." := GenJnlLine2."Document No.";
            "External Document No." := GenJnlLine2."External Document No.";
            Description := GenJnlLine2.Description;
            Validate(Amount, FAAmount);
            "Salvage Value" := GenJnlLine2."Salvage Value";
            Quantity := GenJnlLine2.Quantity;
            Validate(Correction, GenJnlLine2.Correction);
            "No. of Depreciation Days" := GenJnlLine2."No. of Depreciation Days";
            "Depr. until FA Posting Date" := GenJnlLine2."Depr. until FA Posting Date";
            "Depr. Acquisition Cost" := GenJnlLine2."Depr. Acquisition Cost";
            "Posting Group" := GenJnlLine2."Posting Group";
            "Maintenance Code" := GenJnlLine2."Maintenance Code";
            "Shortcut Dimension 1 Code" := GenJnlLine2."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := GenJnlLine2."Shortcut Dimension 2 Code";
            "Dimension Set ID" := GenJnlLine2."Dimension Set ID";
            "Budgeted FA No." := GenJnlLine2."Budgeted FA No.";
            "FA Reclassification Entry" := GenJnlLine2."FA Reclassification Entry";
            "Index Entry" := GenJnlLine2."Index Entry"
        end;

        OnAfterAdjustGenJnlLine(GenJnlLine, GenJnlLine2);
    end;

    local procedure AdjustFAJnlLine(var FAJnlLine: Record "FA Journal Line")
    var
        FAJnlLine2: Record "FA Journal Line";
    begin
        FAJnlLine2 := FAJnlLine;
        with FAJnlLine do begin
            Init;
            "FA No." := FAJnlLine2."FA No.";
            "Depreciation Book Code" := FAJnlLine2."Depreciation Book Code";
            "FA Posting Type" := FAJnlLine2."FA Posting Type";
            "FA Posting Date" := FAJnlLine2."FA Posting Date";
            "Posting Date" := FAJnlLine2."Posting Date";
            if "Posting Date" = "FA Posting Date" then
                "Posting Date" := 0D;
            "Document Type" := FAJnlLine2."Document Type";
            "Document Date" := FAJnlLine2."Document Date";
            "Document No." := FAJnlLine2."Document No.";
            "External Document No." := FAJnlLine2."External Document No.";
            Description := FAJnlLine2.Description;
            Validate(Amount, FAJnlLine2.Amount);
            "Salvage Value" := FAJnlLine2."Salvage Value";
            Quantity := FAJnlLine2.Quantity;
            Validate(Correction, FAJnlLine2.Correction);
            "No. of Depreciation Days" := FAJnlLine2."No. of Depreciation Days";
            "Depr. until FA Posting Date" := FAJnlLine2."Depr. until FA Posting Date";
            "Depr. Acquisition Cost" := FAJnlLine2."Depr. Acquisition Cost";
            "FA Posting Group" := FAJnlLine2."FA Posting Group";
            "Maintenance Code" := FAJnlLine2."Maintenance Code";
            "Shortcut Dimension 1 Code" := FAJnlLine2."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := FAJnlLine2."Shortcut Dimension 2 Code";
            "Dimension Set ID" := FAJnlLine2."Dimension Set ID";
            "Budgeted FA No." := FAJnlLine2."Budgeted FA No.";
            "FA Reclassification Entry" := FAJnlLine2."FA Reclassification Entry";
            "Index Entry" := FAJnlLine2."Index Entry"
        end;

        OnAfterAdjustFAJnlLine(FAJnlLine, FAJnlLine2);
    end;

    local procedure CalcExchangeRateAmount(DuplicateInGenJnl: Boolean; FANo: Code[20]; var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    var
        ExchangeRate2: Decimal;
    begin
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            exit;
        ExchangeRate2 := ExchangeRate / GetExchangeRate(FANo, DeprBook);
        if DuplicateInGenJnl then
            with GenJnlLine do begin
                Validate(Amount, Round(Amount * ExchangeRate2));
                Validate("Salvage Value", Round("Salvage Value" * ExchangeRate2));
            end;
        if not DuplicateInGenJnl then
            with FAJnlLine do begin
                Validate(Amount, Round(Amount * ExchangeRate2));
                Validate("Salvage Value", Round("Salvage Value" * ExchangeRate2));
            end;
    end;

    local procedure GetExchangeRate(FANo: Code[20]; var DeprBook: Record "Depreciation Book"): Decimal
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            exit(100);
        FADeprBook.Get(FANo, DeprBook.Code);
        if FADeprBook."FA Exchange Rate" > 0 then
            exit(FADeprBook."FA Exchange Rate");
        if DeprBook."Default Exchange Rate" > 0 then
            exit(DeprBook."Default Exchange Rate");
        exit(100);
    end;

    local procedure InsertLine(GenJnlPosting: Boolean; DuplicateInGenJnl: Boolean; GenJnlLine: Record "Gen. Journal Line"; FAJnlLine: Record "FA Journal Line")
    begin
        if GenJnlPosting and DuplicateInGenJnl then
            with GenJnlLine do begin
                AdjustGenJnlLine(GenJnlLine);
                "Journal Template Name" := TemplateName;
                "Journal Batch Name" := BatchName;
                LockTable();
                FAGetJnl.SetGenJnlRange(GenJnlLine2, TemplateName, BatchName);
                Validate("Depreciation Book Code", DeprBook.Code);
                CalcExchangeRateAmount(DuplicateInGenJnl, "Account No.", GenJnlLine, FAJnlLine);
                "Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                if DeprBook."Use Default Dimension" then
                    CreateDim(
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DATABASE::Job, "Job No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, "Campaign No.");
                "Line No." := GenJnlLine2."Line No." + 10000;
                OnBeforeGenJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl);
                Insert(true);
            end;

        if GenJnlPosting and not DuplicateInGenJnl then
            with FAJnlLine do begin
                MakeFAJnlLine(FAJnlLine, GenJnlLine);
                "Journal Template Name" := TemplateName;
                "Journal Batch Name" := BatchName;
                LockTable();
                FAGetJnl.SetFAJnlRange(FAJnlLine2, TemplateName, BatchName);
                Validate("Depreciation Book Code", DeprBook.Code);
                CalcExchangeRateAmount(DuplicateInGenJnl, "FA No.", GenJnlLine, FAJnlLine);
                "Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
                FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                if DeprBook."Use Default Dimension" then
                    CreateDim(DATABASE::"Fixed Asset", "FA No.");
                "Line No." := FAJnlLine2."Line No." + 10000;
                OnBeforeFAJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl, DeprBook);
                Insert(true);
            end;

        if not GenJnlPosting and DuplicateInGenJnl then
            with GenJnlLine do begin
                MakeGenJnlLine(GenJnlLine, FAJnlLine);
                "Journal Template Name" := TemplateName;
                "Journal Batch Name" := BatchName;
                LockTable();
                FAGetJnl.SetGenJnlRange(GenJnlLine2, TemplateName, BatchName);
                Validate("Depreciation Book Code", DeprBook.Code);
                CalcExchangeRateAmount(DuplicateInGenJnl, "Account No.", GenJnlLine, FAJnlLine);
                "Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
                FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
                if DeprBook."Use Default Dimension" then
                    CreateDim(
                      DimMgt.TypeToTableID1("Account Type"), "Account No.",
                      DimMgt.TypeToTableID1("Bal. Account Type"), "Bal. Account No.",
                      DATABASE::Job, "Job No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, "Campaign No.");
                "Line No." := GenJnlLine2."Line No." + 10000;
                OnBeforeGenJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl);
                Insert(true);
            end;

        if not GenJnlPosting and not DuplicateInGenJnl then
            with FAJnlLine do begin
                AdjustFAJnlLine(FAJnlLine);
                "Journal Template Name" := TemplateName;
                "Journal Batch Name" := BatchName;
                LockTable();
                FAGetJnl.SetFAJnlRange(FAJnlLine2, TemplateName, BatchName);
                Validate("Depreciation Book Code", DeprBook.Code);
                CalcExchangeRateAmount(DuplicateInGenJnl, "FA No.", GenJnlLine, FAJnlLine);
                "Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
                FAJnlSetup.SetFAJnlTrailCodes(FAJnlLine);
                if DeprBook."Use Default Dimension" then
                    CreateDim(DATABASE::"Fixed Asset", "FA No.");
                "Line No." := FAJnlLine2."Line No." + 10000;
                OnBeforeFAJnlLineInsert(GenJnlLine, FAJnlLine, GenJnlPosting, DuplicateInGenJnl, DeprBook);
                Insert(true);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAdjustFAJnlLine(var FAJournalLine: Record "FA Journal Line"; var FAJournalLine2: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var FAJnlLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeFAJnlLine(var FAJnlLine: Record "FA Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var FAJournalLine: Record "FA Journal Line"; GenJnlPosting: Boolean; DuplicateInGenJnl: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; var FAJournalLine: Record "FA Journal Line"; GenJnlPosting: Boolean; DuplicateInGenJnl: Boolean; DepreciationBook: Record "Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineDuplicate(var GenJournalLine: Record "Gen. Journal Line"; var FAAmount: Decimal)
    begin
    end;
}

