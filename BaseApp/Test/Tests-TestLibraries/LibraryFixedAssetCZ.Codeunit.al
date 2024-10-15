codeunit 143030 "Library - Fixed Asset CZ"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateDepreciationGroup(var DepreciationGroup: Record "Depreciation Group"; StartingDate: Date)
    begin
        DepreciationGroup.Init();
        DepreciationGroup.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(DepreciationGroup.FieldNo(Code), DATABASE::"Depreciation Group"),
            1, MaxStrLen(DepreciationGroup.Code)));
        DepreciationGroup.Validate("Starting Date", StartingDate);
        DepreciationGroup.Validate(Description, DepreciationGroup.Code); // Validating Description as Code because value is not important.
        DepreciationGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateFALocation(var FALocation: Record "FA Location")
    begin
        FALocation.Init();
        FALocation.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(FALocation.FieldNo(Code), DATABASE::"FA Location"),
            1, MaxStrLen(FALocation.Code)));
        FALocation.Validate(Name, FALocation.Code); // Validating Description as Code because value is not important.
        FALocation.Insert(true);
    end;

#if not CLEAN18
    [Scope('OnPrem')]
    procedure CreateFAExtendedPostingGroup(var FAExtendedPostingGroup: Record "FA Extended Posting Group"; FAPostingGroupCode: Code[20]; FAPostingType: Option; ReasonCode: Code[10])
    begin
        FAExtendedPostingGroup.Init();
        FAExtendedPostingGroup.Validate("FA Posting Group Code", FAPostingGroupCode);
        FAExtendedPostingGroup.Validate("FA Posting Type", FAPostingType);
        FAExtendedPostingGroup.Validate(Code, ReasonCode);
        FAExtendedPostingGroup.Insert(true);
    end;

#endif
    [Scope('OnPrem')]
    procedure GenerateDeprecationGroupCode(): Text
    var
        DepreciationGroup: Record "Depreciation Group";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(DepreciationGroup.FieldNo("Depreciation Group"), DATABASE::"Depreciation Group"),
            1, MaxStrLen(DepreciationGroup."Depreciation Group")));
    end;

    [Scope('OnPrem')]
    procedure FindFiscalYear(PostingDate: Date): Date
    var
        FAJnlCheckLine: Codeunit "FA Jnl.-Check Line";
    begin
        exit(FAJnlCheckLine.FindFiscalYear2(PostingDate));
    end;

    [Scope('OnPrem')]
    procedure RunCalculateDepreciation(var FixedAsset: Record "Fixed Asset"; DepreciationBookCode: Code[10]; FAPostingDate: Date; DocumentNo: Code[20]; PostingDescription: Text)
    var
        FixedAsset2: Record "Fixed Asset";
        ReportCalculateDepreciation: Report "Calculate Depreciation";
    begin
        FixedAsset2.Copy(FixedAsset);
        ReportCalculateDepreciation.InitializeRequest(
          DepreciationBookCode, FAPostingDate, false, 0,
          0D, DocumentNo, PostingDescription, false);
        ReportCalculateDepreciation.SetTableView(FixedAsset2);
        ReportCalculateDepreciation.UseRequestPage(false);
        ReportCalculateDepreciation.RunModal;
    end;
}

