codeunit 144715 "ERM FA-3 Report Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FAMovementReport()
    var
        FADocHeader: Record "FA Document Header";
        FANo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize;
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset;
        MockFADocument(FADocHeader, FANo);
        RunFAMovementReport(FADocHeader);
        VerifyFAMovementReportValues(FADocHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedFAMovementReport()
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FANo: array[2] of Code[20];
        i: Integer;
    begin
        Initialize;
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset;
        MockPostedFADocument(PostedFADocHeader, FANo);
        RunPostedFAMovementReport(PostedFADocHeader);
        VerifyPostedFAMovementReportValues(PostedFADocHeader);
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        RemoveMandatorySignSetup;

        isInitialized := true;
    end;

    local procedure MockFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        with FixedAsset do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            Description := LibraryUtility.GenerateGUID;
            "Inventory Number" := LibraryUtility.GenerateGUID;
            "Passport No." := LibraryUtility.GenerateGUID;
            "Factory No." := LibraryUtility.GenerateGUID;
            Modify;
            InitFADeprBooks("No.");
            exit("No.");
        end;
    end;

    local procedure MockFADocument(var FADocHeader: Record "FA Document Header"; FANo: array[2] of Code[20])
    var
        i: Integer;
    begin
        MockFAHeader(FADocHeader);
        for i := 1 to ArrayLen(FANo) do
            MockFALine(FADocHeader, FANo[i]);
    end;

    local procedure MockFAHeader(var FADocHeader: Record "FA Document Header")
    begin
        with FADocHeader do begin
            Init;
            "Document Type" := "Document Type"::Movement;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            "Posting Date" := WorkDate;
            "FA Location Code" := LibraryRUReports.MockFALocation;
            "New FA Location Code" := LibraryRUReports.MockFALocation;
            Modify;
        end;
    end;

    local procedure MockFALine(FADocHeader: Record "FA Document Header"; FANo: Code[20])
    var
        FADocLine: Record "FA Document Line";
        RecRef: RecordRef;
    begin
        with FADocLine do begin
            Init;
            "Document Type" := FADocHeader."Document Type";
            "Document No." := FADocHeader."No.";
            RecRef.GetTable(FADocLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            Insert;
            Description := LibraryUtility.GenerateGUID;
            "FA No." := FANo;
            "Depreciation Book Code" := LibraryRUReports.GetFirstFADeprBook("FA No.");
            "FA Posting Group" := LibraryRUReports.MockFAPostingGroup;
            Amount := LibraryRandom.RandDec(100, 2);
            Modify;
        end;
    end;

    local procedure MockPostedFADocument(var PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: array[2] of Code[20])
    var
        i: Integer;
    begin
        MockPostedFAHeader(PostedFADocHeader);
        for i := 1 to ArrayLen(FANo) do
            MockPostedFALine(PostedFADocHeader, FANo[i]);
    end;

    local procedure MockPostedFAHeader(var PostedFADocHeader: Record "Posted FA Doc. Header")
    begin
        with PostedFADocHeader do begin
            Init;
            "Document Type" := "Document Type"::Movement;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            "Posting Date" := WorkDate;
            "FA Location Code" := LibraryRUReports.MockFALocation;
            "New FA Location Code" := LibraryRUReports.MockFALocation;
            Modify;
        end;
    end;

    local procedure MockPostedFALine(PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: Code[20])
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
        RecRef: RecordRef;
    begin
        with PostedFADocLine do begin
            Init;
            "Document Type" := PostedFADocHeader."Document Type";
            "Document No." := PostedFADocHeader."No.";
            RecRef.GetTable(PostedFADocLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            Insert;
            "FA No." := FANo;
            "Depreciation Book Code" := LibraryRUReports.GetFirstFADeprBook("FA No.");
            "FA Posting Group" := LibraryRUReports.MockFAPostingGroup;
            Amount := LibraryRandom.RandDec(100, 2);
            Modify;
        end;
    end;

    local procedure RunFAMovementReport(FADocHeader: Record "FA Document Header")
    var
        FAMovementRep: Report "FA Movement FA-3";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter;
        with FAMovementRep do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            SetTableView(FADocHeader);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure RunPostedFAMovementReport(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAMovementRep: Report "FA Posted Movement FA-3";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter;
        with PostedFAMovementRep do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            SetTableView(PostedFADocHeader);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure RemoveMandatorySignSetup()
    var
        DefaultSignSetup: Record "Default Signature Setup";
    begin
        DefaultSignSetup.SetFilter("Table ID", '%1|%2', DATABASE::"FA Document Header", DATABASE::"FA Document Line");
        DefaultSignSetup.SetRange(Mandatory, true);
        DefaultSignSetup.DeleteAll(true);
    end;

    local procedure VerifyFAMovementReportValues(FADocHeader: Record "FA Document Header")
    var
        FADocLine: Record "FA Document Line";
        RowShift: Integer;
    begin
        VerifyReportHeader(
          FADocHeader."FA Location Code", FADocHeader."New FA Location Code", FADocHeader."No.", FADocHeader."Posting Date");

        with FADocLine do begin
            SetRange("Document Type", FADocHeader."Document Type");
            SetRange("Document No.", FADocHeader."No.");
            FindSet;
            RowShift := 0;
            repeat
                VerifyReportLineValues(RowShift, Description, "FA No.", Amount);
                RowShift += 1;
            until Next = 0;
        end;
    end;

    local procedure VerifyPostedFAMovementReportValues(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
        RowShift: Integer;
    begin
        VerifyReportHeader(
          PostedFADocHeader."FA Location Code", PostedFADocHeader."New FA Location Code",
          PostedFADocHeader."No.", PostedFADocHeader."Posting Date");

        with PostedFADocLine do begin
            SetRange("Document Type", PostedFADocHeader."Document Type");
            SetRange("Document No.", PostedFADocHeader."No.");
            FindSet;
            RowShift := 0;
            repeat
                VerifyReportLineValues(RowShift, Description, "FA No.", Amount);
                RowShift += 1;
            until Next = 0;
        end;
    end;

    local procedure VerifyReportHeader(FALocationCode: Code[10]; NewFALocationCode: Code[10]; DocNo: Code[20]; DocDate: Date)
    var
        FALocation: Record "FA Location";
    begin
        LibraryReportValidation.VerifyCellValue(8, 1, FALocation.GetName(NewFALocationCode));
        LibraryReportValidation.VerifyCellValue(10, 20, FALocation.GetName(FALocationCode));
        LibraryReportValidation.VerifyCellValue(15, 45, DocNo);
        LibraryReportValidation.VerifyCellValue(15, 65, Format(DocDate));
    end;

    local procedure VerifyReportLineValues(RowShift: Integer; Description: Text; FANo: Code[20]; ExpectedAmount: Decimal)
    var
        FixedAsset: Record "Fixed Asset";
        StdRepMgt: Codeunit "Local Report Management";
        LineRowId: Integer;
    begin
        FixedAsset.Get(FANo);
        LineRowId := 28 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, Format(RowShift + 1));
        LibraryReportValidation.VerifyCellValue(LineRowId, 11, Description);
        LibraryReportValidation.VerifyCellValue(LineRowId, 51, FixedAsset."Inventory Number");
        LibraryReportValidation.VerifyCellValue(LineRowId, 69, FixedAsset."Passport No.");
        LibraryReportValidation.VerifyCellValue(LineRowId, 89, FixedAsset."Factory No.");
        LibraryReportValidation.VerifyCellValue(LineRowId, 108, StdRepMgt.FormatReportValue(ExpectedAmount, 2));
    end;
}

