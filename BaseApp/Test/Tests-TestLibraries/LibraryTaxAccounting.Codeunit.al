codeunit 143015 "Library - Tax Accounting"
{
    Permissions = tabledata "FA Ledger Entry" = imd;

    var
        FASetup: Record "FA Setup";
        TaxRegSetup: Record "Tax Register Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure GenerateRandomCode(TableID: Integer; FieldID: Integer): Code[10]
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(FieldID, TableID),
            1, LibraryUtility.GetFieldLength(TableID, FieldID)));
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlTemplate(var TaxDiffJnlTemplate: Record "Tax Diff. Journal Template")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        with TaxDiffJnlTemplate do begin
            Init();
            Validate(Name, GenJnlTemplate.Name);
            Validate(Description, Name);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlBatch(var TaxDiffJnlBatch: Record "Tax Diff. Journal Batch"; TaxDiffJnlTemplateName: Code[10])
    begin
        with TaxDiffJnlBatch do begin
            Init();
            Validate("Journal Template Name", TaxDiffJnlTemplateName);
            Validate(Name, GenerateRandomCode(DATABASE::"Tax Diff. Journal Batch", FieldNo(Name)));
            Validate(Description, Name);
            Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlSetup(var TaxDiffJnlTemplateName: Code[10]; var TaxDiffJnlBatchName: Code[10])
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        CreateTaxDiffJnlTemplate(TaxDiffJnlTemplate);
        CreateTaxDiffJnlBatch(TaxDiffJnlBatch, TaxDiffJnlTemplate.Name);
        TaxDiffJnlTemplateName := TaxDiffJnlTemplate.Name;
        TaxDiffJnlBatchName := TaxDiffJnlBatch.Name;
    end;

    [Scope('OnPrem')]
    procedure CreateAccDeprBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        with DepreciationBook do begin
            Validate("Posting Book Type", "Posting Book Type"::Accounting);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxAccDeprBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        with DepreciationBook do begin
            Validate("Posting Book Type", "Posting Book Type"::"Tax Accounting");
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDifference(var TaxDifference: Record "Tax Difference")
    begin
        with TaxDifference do begin
            Init();
            Validate(Code, GenerateRandomCode(DATABASE::"Tax Difference", FieldNo(Code)));
            Validate("Source Code Mandatory", true);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffPostingGroup(var TaxDiffPostingGroup: Record "Tax Diff. Posting Group")
    begin
        with TaxDiffPostingGroup do begin
            Init();
            Validate(Code, GenerateRandomCode(DATABASE::"Tax Diff. Posting Group", FieldNo(Code)));
            Validate("CTA Tax Account", LibraryERM.CreateGLAccountNo());
            Validate("CTL Tax Account", LibraryERM.CreateGLAccountNo());
            Validate("DTA Tax Account", LibraryERM.CreateGLAccountNo());
            Validate("DTL Tax Account", LibraryERM.CreateGLAccountNo());
            Validate("CTA Account", LibraryERM.CreateGLAccountNo());
            Validate("CTL Account", LibraryERM.CreateGLAccountNo());
            Validate("DTA Account", LibraryERM.CreateGLAccountNo());
            Validate("DTL Account", LibraryERM.CreateGLAccountNo());
            Validate("DTA Disposal Account", LibraryERM.CreateGLAccountNo());
            Validate("DTL Disposal Account", LibraryERM.CreateGLAccountNo());
            Validate("DTA Transfer Bal. Account", LibraryERM.CreateGLAccountNo());
            Validate("DTL Transfer Bal. Account", LibraryERM.CreateGLAccountNo());
            Validate("CTA Transfer Tax Account", LibraryERM.CreateGLAccountNo());
            Validate("CTL Transfer Tax Account", LibraryERM.CreateGLAccountNo());
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDeprBonusTaxDifference(var TaxDifference: Record "Tax Difference")
    begin
        CreateTaxDifference(TaxDifference);
        with TaxDifference do begin
            Validate(Type, Type::"Temporary");
            Validate("Depreciation Bonus", true);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffDeprBonusSetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Fixed Asset Nos.", LibraryERM.CreateNoSeriesCode());
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateDeprBonusTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Depr. Bonus TD Code", TaxDifference.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffFASetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        DepreciationBook.Validate("Control FA Acquis. Cost", true);
        DepreciationBook.Modify(true);
        FASetup.Get();
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Use Group Depr. Method from", 0D);
        TaxRegSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Default FA TD Code", TaxDifference.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffDisposalSetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Release Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Use Group Depr. Method from", 0D);
        TaxRegSetup.Validate("Tax Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Validate("Calculate TD for each FA", true);
        TaxRegSetup.Validate("Disposal TD Code", TaxDifference.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PrepareTaxDiffDeprFESetup()
    var
        DepreciationBook: Record "Depreciation Book";
        TaxDifference: Record "Tax Difference";
    begin
        CreateAccDeprBook(DepreciationBook);
        FASetup.Get();
        FASetup.Validate("Future Depr. Book", DepreciationBook.Code);
        FASetup.Modify(true);

        CreateTaxAccDeprBook(DepreciationBook);
        CreateTaxDifference(TaxDifference);
        TaxRegSetup.Get();
        TaxRegSetup.Validate("Future Exp. Depreciation Book", DepreciationBook.Code);
        TaxRegSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        TaxDifference: Record "Tax Difference";
        FADeprBook: Record "FA Depreciation Book";
    begin
        CreateTaxDifference(TaxDifference);
        TaxDifference.Validate(Type, TaxDifference.Type::"Temporary");
        TaxDifference.Modify(true);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("Tax Difference Code", TaxDifference.Code);
        FixedAsset.Modify(true);

        FADeprBook.SetRange("FA No.", FixedAsset."No.");
        FADeprBook.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateFutureExpense(var FutureExpense: Record "Fixed Asset")
    var
        TaxDifference: Record "Tax Difference";
        FADeprBook: Record "FA Depreciation Book";
    begin
        CreateTaxDifference(TaxDifference);
        TaxDifference.Validate(Type, TaxDifference.Type::"Temporary");
        TaxDifference.Modify(true);

        LibraryFixedAsset.CreateFixedAsset(FutureExpense);
        FutureExpense.Validate("FA Type", FutureExpense."FA Type"::"Future Expense");
        FutureExpense.Validate("Tax Difference Code", TaxDifference.Code);
        FutureExpense.Modify(true);

        FADeprBook.SetRange("FA No.", FutureExpense."No.");
        FADeprBook.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcSection(var TaxCalcSection: Record "Tax Calc. Section"; StartingDate: Date; EndingDate: Date)
    begin
        with TaxCalcSection do begin
            Init();
            Validate(Code, GenerateRandomCode(DATABASE::"Tax Calc. Section", FieldNo(Code)));
            Validate(Description, Code);
            Validate(Status, Status::Blocked);
            Validate("Starting Date", StartingDate);
            Validate("Ending Date", EndingDate);
            Validate(Status, Status::Open);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcHeader(var TaxCalcHeader: Record "Tax Calc. Header"; TaxCalcSectionCode: Code[10]; TableID: Integer)
    begin
        with TaxCalcHeader do begin
            Init();
            Validate("Section Code", TaxCalcSectionCode);
            Validate("No.", GenerateRandomCode(DATABASE::"Tax Calc. Header", FieldNo("No.")));
            Validate(Description, "No.");
            Validate("Table ID", TableID);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLastTaxCalcLineNo(TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10]): Integer
    var
        TaxCalcLine: Record "Tax Calc. Line";
    begin
        with TaxCalcLine do begin
            SetRange("Section Code", TaxCalcSectionCode);
            SetRange(Code, TaxCalcHeaderNo);
            if FindLast() then
                exit("Line No.");
            exit(0);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcLine(var TaxCalcLine: Record "Tax Calc. Line"; ExpressionType: Option; TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10])
    begin
        with TaxCalcLine do begin
            Init();
            Validate("Section Code", TaxCalcSectionCode);
            Validate(Code, TaxCalcHeaderNo);
            Validate("Line No.", GetLastTaxCalcLineNo(TaxCalcSectionCode, TaxCalcHeaderNo) + 10000);
            Validate("Line Code", GenerateRandomCode(DATABASE::"Tax Calc. Line", FieldNo("Line Code")));
            Validate("Expression Type", ExpressionType);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLastTaxCalcSelectionSetupLineNo(TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10]): Integer
    var
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
    begin
        with TaxCalcSelectionSetup do begin
            SetRange("Section Code", TaxCalcSectionCode);
            SetRange("Register No.", TaxCalcHeaderNo);
            if FindLast() then
                exit("Line No.");
            exit(0);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcSelectionSetup(var TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup"; TaxCalcSectionCode: Code[10]; TaxCalcHeaderNo: Code[10])
    begin
        with TaxCalcSelectionSetup do begin
            Init();
            Validate("Section Code", TaxCalcSectionCode);
            Validate("Register No.", TaxCalcHeaderNo);
            Validate("Line No.", GetLastTaxCalcSelectionSetupLineNo(TaxCalcSectionCode, TaxCalcHeaderNo) + 10000);
            Validate("Line Code", GenerateRandomCode(DATABASE::"Tax Calc. Selection Setup", FieldNo("Line Code")));
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegSection(var TaxRegSection: Record "Tax Register Section")
    begin
        with TaxRegSection do begin
            Init();
            Validate(Code, LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Tax Register Section"));
            Validate(Description, Code);
            Insert(true);
            Validate("Starting Date", CalcDate('<-CM>', WorkDate()));
            Validate("Ending Date", CalcDate('<CM>', WorkDate()));
            Validate(Status, Status::Open);
            Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxReg(var TaxReg: Record "Tax Register"; TaxRegSectionCode: Code[10]; TableId: Integer; StoringMethod: Option)
    begin
        with TaxReg do begin
            Init();
            Validate("Section Code", TaxRegSectionCode);
            Validate("No.", LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Tax Register"));
            Validate(Description, "No.");
            Validate("Table ID", TableId);
            Validate("Storing Method", StoringMethod);
            Validate("Register ID", LibraryUtility.GenerateGUID());
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegTemplate(var TaxRegTemplate: Record "Tax Register Template"; TaxRegSectionCode: Code[10]; TaxRegNo: Code[10])
    var
        RecRef: RecordRef;
    begin
        with TaxRegTemplate do begin
            Init();
            Validate("Section Code", TaxRegSectionCode);
            Validate(Code, TaxRegNo);
            RecRef.GetTable(TaxRegTemplate);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Validate(
              "Line Code",
              LibraryUtility.GenerateRandomCode(FieldNo("Line Code"), DATABASE::"Tax Register Template"));
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegTerm(var TaxRegTerm: Record "Tax Register Term"; SectionCode: Code[10]; ExpressionType: Option)
    begin
        with TaxRegTerm do begin
            Init();
            Validate("Section Code", SectionCode);
            Validate("Term Code",
              LibraryUtility.GenerateRandomCode(FieldNo("Term Code"), DATABASE::"Tax Register Term"));
            Validate("Expression Type", ExpressionType);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegTermFormula(var TaxRegTermFormula: Record "Tax Register Term Formula"; SectionCode: Code[10]; TermCode: Code[20]; OperationType: Option; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        with TaxRegTermFormula do begin
            Init();
            Validate("Section Code", SectionCode);
            Validate("Term Code", TermCode);
            RecRef.GetTable(TaxRegTermFormula);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Validate(Operation, OperationType);
            Validate("Account Type", AccountType);
            Validate("Account No.", AccountNo);
            if BalAccountNo <> '' then
                Validate("Bal. Account No.", BalAccountNo);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateFALedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DeprBookCode: Code[10]; PostingDate: Date)
    var
        RecRef: RecordRef;
    begin
        with FALedgerEntry do begin
            Init();
            RecRef.GetTable(FALedgerEntry);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "FA No." := FANo;
            "Depreciation Book Code" := DeprBookCode;
            "Posting Date" := PostingDate;
            "FA Posting Date" := PostingDate;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateFAWithTaxFADeprBook(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();

        CreateSimpleFA(FixedAsset);
        with FADeprBook do begin
            Init();
            "FA No." := FixedAsset."No.";
            "Depreciation Book Code" := TaxRegSetup."Tax Depreciation Book";
            Insert();
        end;
        exit(FixedAsset."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFEWithTaxFADeprBook(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        TaxRegSetup: Record "Tax Register Setup";
    begin
        TaxRegSetup.Get();

        CreateSimpleFA(FixedAsset);
        with FADeprBook do begin
            Init();
            "FA No." := FixedAsset."No.";
            "Depreciation Book Code" := TaxRegSetup."Future Exp. Depreciation Book";
            Insert();
        end;
        exit(FixedAsset."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateSimpleFA(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset.Init();
        FixedAsset."No." := LibraryUtility.GenerateRandomCode(FixedAsset.FieldNo("No."), DATABASE::"Fixed Asset");
        FixedAsset.Insert();
    end;

    [Scope('OnPrem')]
    procedure FindCalendarPeriod(var CalendarPeriod: Record Date; StartDate: Date)
    begin
        with CalendarPeriod do begin
            Reset();
            SetRange("Period Type", "Period Type"::Month);
            SetFilter("Period Start", '..%1', StartDate);
            SetFilter("Period End", '%1..', StartDate);
            FindFirst();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateEntryNoAmountBuffer(var EntryNoAmountBuffer: Record "Entry No. Amount Buffer"; LineNo: Integer)
    begin
        with EntryNoAmountBuffer do begin
            "Entry No." := LineNo;
            Amount := LibraryRandom.RandDec(100, 2);
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        RecordRef: RecordRef;
    begin
        with TaxDiffJnlLine do begin
            Init();
            "Journal Template Name" := JnlTemplateName;
            "Journal Batch Name" := JnlBatchName;
            RecordRef.GetTable(TaxDiffJnlLine);
            "Line No." :=
              LibraryUtility.GetNewLineNo(RecordRef, FieldNo("Line No."));
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure FillTaxDiffJnlLine(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; SourceType: Option; SourceNo: Code[10])
    var
        TaxDifference: Record "Tax Difference";
        TaxDiffPostingGroup: Record "Tax Diff. Posting Group";
    begin
        with TaxDiffJnlLine do begin
            Init();
            "Posting Date" := WorkDate();
            "Document No." := LibraryUtility.GenerateGUID();
            CreateTaxDifference(TaxDifference);
            "Tax Diff. Code" := TaxDifference.Code;
            CreateTaxDiffPostingGroup(TaxDiffPostingGroup);
            "Tax Diff. Posting Group" := TaxDiffPostingGroup.Code;
            "Tax Factor" := LibraryRandom.RandDec(50, 2);
            "Source Type" := SourceType;
            "Source No." := SourceNo;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegDimFilter(var TaxRegDimFilter: Record "Tax Register Dim. Filter"; SectionCode: Code[10]; TaxRegisterNo: Code[20]; DefineType: Option; DimensionCode: Code[20]; DimValueCode: Code[20])
    var
        RecRef: RecordRef;
    begin
        with TaxRegDimFilter do begin
            Init();
            "Section Code" := SectionCode;
            "Tax Register No." := TaxRegisterNo;
            Define := DefineType;
            RecRef.GetTable(TaxRegDimFilter);
            "Line No." :=
              LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            "Dimension Code" := DimensionCode;
            "Dimension Value Filter" := DimValueCode;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcDimFilter(SectionCode: Code[10]; TaxRegisterNo: Code[10]; LineNo: Integer; DimValue: Record "Dimension Value")
    var
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        with TaxCalcDimFilter do begin
            Init();
            "Section Code" := SectionCode;
            "Register No." := TaxRegisterNo;
            Define := Define::Template;
            "Line No." := LineNo;
            "Dimension Code" := DimValue."Dimension Code";
            "Dimension Value Filter" := DimValue.Code;
            "Entry No." := 1;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcCorrespEntry(var TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry"; SectionCode: Code[10])
    begin
        with TaxCalcCorrespEntry do begin
            "Section Code" := SectionCode;
            "Debit Account No." := LibraryERM.CreateGLAccountNo();
            "Credit Account No." := LibraryERM.CreateGLAccountNo();
            "Register Type" := "Register Type"::Item;
            "Entry No." := 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcDimCorrFilter(var TaxCalcDimCorrFilter: Record "Tax Calc. Dim. Corr. Filter"; SectionCode: Code[10])
    begin
        with TaxCalcDimCorrFilter do begin
            Init();
            "Section Code" := SectionCode;
            "Corresp. Entry No." := 1;
            "Connection Entry No." := 1;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegNormJurisdiction(var TaxRegNormJurisdiction: Record "Tax Register Norm Jurisdiction")
    begin
        with TaxRegNormJurisdiction do begin
            Init();
            Validate(Code,
              GenerateRandomCode(DATABASE::"Tax Register Norm Jurisdiction", FieldNo(Code)));
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegNormGroup(var TaxRegNormGroup: Record "Tax Register Norm Group"; TaxNormJurisdictionCode: Code[10])
    begin
        with TaxRegNormGroup do begin
            Init();
            Validate("Norm Jurisdiction Code", TaxNormJurisdictionCode);
            Validate(Code,
              GenerateRandomCode(DATABASE::"Tax Register Norm Group", FieldNo(Code)));
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegNormDetail(var TaxRegNormDetail: Record "Tax Register Norm Detail"; TaxNormJurisdictionCode: Code[10]; TaxNormGroupCode: Code[10]; NormType: Option; EffectiveDate: Date)
    begin
        with TaxRegNormDetail do begin
            Init();
            Validate("Norm Jurisdiction Code", TaxNormJurisdictionCode);
            Validate("Norm Group Code", TaxNormGroupCode);
            Validate("Norm Type", NormType);
            Validate("Effective Date", EffectiveDate);
            Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcAccumulation(var TaxCalcAccum: Record "Tax Calc. Accumulation"; SectionCode: Code[10]; StartingDate: Date)
    var
        RecRef: RecordRef;
    begin
        with TaxCalcAccum do begin
            Init();
            RecRef.GetTable(TaxCalcAccum);
            "Entry No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Entry No."));
            "Section Code" := SectionCode;
            "Starting Date" := StartingDate;
            Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateFAWithAccFADeprBook(): Code[20]
    var
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();

        CreateSimpleFA(FixedAsset);
        with FADeprBook do begin
            Init();
            "FA No." := FixedAsset."No.";
            "Depreciation Book Code" := FASetup."Release Depr. Book";
            Insert();
        end;
        exit(FixedAsset."No.");
    end;
}

