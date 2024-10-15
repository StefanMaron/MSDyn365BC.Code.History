codeunit 144717 "ERM FA-4 Report Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        StdRepMgt: Codeunit "Local Report Management";
        isInitialized: Boolean;
        ValueNotExistErr: Label 'Value not exist in worksheet no. %1', Comment = '%1 - row % 2 - column';

    [Test]
    [Scope('OnPrem')]
    procedure SingleLineFAWriteOffFA4()
    begin
        FAWriteoffAct(REPORT::"FA Write-off Act FA-4", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLineFAWriteOffFA4()
    begin
        FAWriteoffAct(REPORT::"FA Write-off Act FA-4", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleLinePostedFAWriteOffFA4()
    begin
        FAPostedWriteoffAct(REPORT::"FA Posted Writeoff Act FA-4", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinePostedFAWriteOffFA4()
    begin
        FAPostedWriteoffAct(REPORT::"FA Posted Writeoff Act FA-4", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleLineFAWriteOffFA4a()
    begin
        FAWriteoffAct(REPORT::"FA Writeoff Act FA-4a", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLineFAWriteOffFA4a()
    begin
        FAWriteoffAct(REPORT::"FA Writeoff Act FA-4a", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleLinePostedFAWriteOffFA4a()
    begin
        FAPostedWriteoffAct(REPORT::"Posted FA Writeoff Act FA-4a", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinePostedFAWriteOffFA4a()
    begin
        FAPostedWriteoffAct(REPORT::"Posted FA Writeoff Act FA-4a", true);
    end;

    local procedure FAWriteoffAct(ReportID: Integer; MultipleLine: Boolean)
    var
        FADocHeader: Record "FA Document Header";
        FANo: array[2] of Code[20];
        ReceiptNo: Code[20];
        i: Integer;
    begin
        Initialize;
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset;
        ReceiptNo := MockItemDocLines;
        MockFADocument(FADocHeader, FANo, ReceiptNo, MultipleLine);
        RunReport(FADocHeader, ReportID);
        VerifyResults(FADocHeader, ReportID);
    end;

    local procedure FAPostedWriteoffAct(ReportID: Integer; MultipleLine: Boolean)
    var
        PostedFADocHeader: Record "Posted FA Doc. Header";
        FANo: array[2] of Code[20];
        ReceiptNo: Code[20];
        i: Integer;
    begin
        Initialize;
        for i := 1 to ArrayLen(FANo) do
            FANo[i] := MockFixedAsset;
        ReceiptNo := MockItemRcptLines;
        MockPostedFADocument(PostedFADocHeader, FANo, ReceiptNo, MultipleLine);
        RunPostedReport(PostedFADocHeader, ReportID);
        VerifyPostedResults(PostedFADocHeader, ReportID);
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
        FADeprBook: Record "FA Depreciation Book";
        i: Integer;
    begin
        with FixedAsset do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            Description := LibraryUtility.GenerateGUID;
            "Description 2" := LibraryUtility.GenerateGUID;
            "Initial Release Date" := WorkDate;
            "FA Location Code" := LibraryRUReports.MockFALocation;
            "Depreciation Code" := LibraryRUReports.MockDepreciationCode;
            "Depreciation Group" := LibraryRUReports.MockDepreciationGroup;
            "Inventory Number" := LibraryUtility.GenerateGUID;
            "Factory No." := LibraryUtility.GenerateGUID;
            "Manufacturing Year" := Format(Date2DMY(WorkDate, 3));
            "Vehicle Model" := LibraryUtility.GenerateGUID;
            "Vehicle Reg. No." := LibraryUtility.GenerateGUID;
            "Vehicle Engine No." := LibraryUtility.GenerateGUID;
            "Vehicle Chassis No." := LibraryUtility.GenerateGUID;
            "Is Vehicle" := true;
            "Vehicle Writeoff Date" := GetRandomDate;
            "Run after Release Date" := LibraryRandom.RandInt(100);
            "Run after Renovation Date" := LibraryRandom.RandInt(100);
            Modify;

            InitFADeprBooks("No.");
            FADeprBook.SetRange("FA No.", "No.");
            FADeprBook.FindFirst;
            LibraryRUReports.MockFADepreciationBook(FADeprBook);

            for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
                LibraryRUReports.MockMainAssetComponent("No.");
                LibraryRUReports.MockItemFAPreciousMetal("No.");
            end;

            exit("No.");
        end;
    end;

    local procedure MockItem(): Code[20]
    var
        Item: Record Item;
    begin
        with Item do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            exit("No.");
        end;
    end;

    local procedure MockFADocument(var FADocHeader: Record "FA Document Header"; FANo: array[2] of Code[20]; ReceiptNo: Code[20]; MultipleLine: Boolean)
    var
        "Count": Integer;
        i: Integer;
    begin
        MockFAHeader(FADocHeader);
        if MultipleLine then
            Count := ArrayLen(FANo)
        else
            Count := 1;
        for i := 1 to Count do
            MockFALine(FADocHeader, FANo[i], ReceiptNo);
    end;

    local procedure MockFAHeader(var FADocHeader: Record "FA Document Header")
    begin
        with FADocHeader do begin
            Init;
            "Document Type" := "Document Type"::Writeoff;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            "Posting Date" := WorkDate;
            Modify;
        end;
    end;

    local procedure MockFALine(FADocHeader: Record "FA Document Header"; FANo: Code[20]; ReceiptNo: Code[20])
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
            "FA No." := FANo;
            "Depreciation Book Code" := LibraryRUReports.GetFirstFADeprBook("FA No.");
            "FA Posting Group" := LibraryRUReports.MockFAPostingGroup;
            "Item Receipt No." := ReceiptNo;
            Modify;
        end;
    end;

    local procedure MockPostedFADocument(var PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: array[2] of Code[20]; ReceiptNo: Code[20]; MultipleLine: Boolean)
    var
        "Count": Integer;
        i: Integer;
    begin
        MockPostedFAHeader(PostedFADocHeader);
        if MultipleLine then
            Count := ArrayLen(FANo)
        else
            Count := 1;
        for i := 1 to Count do
            MockPostedFALine(PostedFADocHeader, FANo[i], ReceiptNo);
    end;

    local procedure MockPostedFAHeader(var PostedFADocHeader: Record "Posted FA Doc. Header")
    begin
        with PostedFADocHeader do begin
            Init;
            "Document Type" := "Document Type"::Writeoff;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            "Posting Date" := WorkDate;
            Modify;
        end;
    end;

    local procedure MockPostedFALine(PostedFADocHeader: Record "Posted FA Doc. Header"; FANo: Code[20]; ReceiptNo: Code[20])
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
            "Item Receipt No." := ReceiptNo;
            Modify;
        end;
    end;

    local procedure MockItemDocLines(): Code[20]
    var
        ItemDocLine: Record "Item Document Line";
    begin
        with ItemDocLine do begin
            "Document No." := LibraryUtility.GenerateGUID;
            Description := "Document No.";
            "Item No." := MockItem;
            Quantity := LibraryRandom.RandInt(100);
            "Unit Amount" := LibraryRandom.RandDec(100, 2);
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
            exit("Document No.");
        end;
    end;

    local procedure MockItemRcptLines(): Code[20]
    var
        ItemRcptLine: Record "Item Receipt Line";
    begin
        with ItemRcptLine do begin
            "Document No." := LibraryUtility.GenerateGUID;
            Description := "Document No.";
            "Item No." := MockItem;
            Quantity := LibraryRandom.RandInt(100);
            "Unit Amount" := LibraryRandom.RandDec(100, 2);
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
            exit("Document No.");
        end;
    end;

    local procedure RunReport(FADocHeader: Record "FA Document Header"; ReportID: Integer)
    begin
        case ReportID of
            REPORT::"FA Write-off Act FA-4":
                RunFAWriteOffFA4(FADocHeader);
            REPORT::"FA Writeoff Act FA-4a":
                RunFAWriteOffFA4a(FADocHeader);
        end;
    end;

    local procedure RunPostedReport(PostedFADocHeader: Record "Posted FA Doc. Header"; ReportID: Integer)
    begin
        case ReportID of
            REPORT::"FA Posted Writeoff Act FA-4":
                RunPostedFAWriteOffFA4(PostedFADocHeader);
            REPORT::"Posted FA Writeoff Act FA-4a":
                RunPostedFAWriteOffFA4a(PostedFADocHeader);
        end;
    end;

    local procedure RunFAWriteOffFA4(FADocHeader: Record "FA Document Header")
    var
        FAWriteoffActFA4: Report "FA Write-off Act FA-4";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter;
        with FAWriteoffActFA4 do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            SetTableView(FADocHeader);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure RunPostedFAWriteOffFA4(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAWriteoffActFA4: Report "FA Posted Writeoff Act FA-4";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter;
        with PostedFAWriteoffActFA4 do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            SetTableView(PostedFADocHeader);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure RunFAWriteOffFA4a(FADocHeader: Record "FA Document Header")
    var
        FAWriteoffActFA4a: Report "FA Writeoff Act FA-4a";
    begin
        LibraryReportValidation.SetFileName(FADocHeader."No.");
        FADocHeader.SetRecFilter;
        with FAWriteoffActFA4a do begin
            SetFileNameSilent(LibraryReportValidation.GetFileName);
            SetTableView(FADocHeader);
            UseRequestPage(false);
            Run;
        end;
    end;

    local procedure RunPostedFAWriteOffFA4a(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        PostedFAWriteoffActFA4a: Report "Posted FA Writeoff Act FA-4a";
    begin
        LibraryReportValidation.SetFileName(PostedFADocHeader."No.");
        PostedFADocHeader.SetRecFilter;
        with PostedFAWriteoffActFA4a do begin
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

    local procedure GetRandomDate(): Date
    begin
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate));
    end;

    local procedure VerifyResults(FADocHeader: Record "FA Document Header"; ReportID: Integer)
    var
        FADocLine: Record "FA Document Line";
        RowShift: Integer;
    begin
        with FADocLine do begin
            SetRange("Document Type", FADocHeader."Document Type");
            SetRange("Document No.", FADocHeader."No.");
            FindSet;
            RowShift := 0;
            repeat
                case ReportID of
                    REPORT::"FA Write-off Act FA-4":
                        VerifyFAWriteoffFA4Results(
                          "FA No.", Description, "Depreciation Book Code", "Item Receipt No.", ReportID, RowShift);
                    REPORT::"FA Writeoff Act FA-4a":
                        VerifyFAWriteoffFA4aResults(
                          "FA No.", "Depreciation Book Code", "Item Receipt No.", ReportID, RowShift);
                end;
                RowShift += 1;
            until Next = 0;
        end;
    end;

    local procedure VerifyPostedResults(PostedFADocHeader: Record "Posted FA Doc. Header"; ReportID: Integer)
    var
        PostedFADocLine: Record "Posted FA Doc. Line";
        RowShift: Integer;
    begin
        with PostedFADocLine do begin
            SetRange("Document Type", PostedFADocHeader."Document Type");
            SetRange("Document No.", PostedFADocHeader."No.");
            FindSet;
            RowShift := 0;
            repeat
                case ReportID of
                    REPORT::"FA Posted Writeoff Act FA-4":
                        VerifyFAWriteoffFA4Results(
                          "FA No.", Description, "Depreciation Book Code", "Item Receipt No.", ReportID, RowShift);
                    REPORT::"Posted FA Writeoff Act FA-4a":
                        VerifyFAWriteoffFA4aResults(
                          "FA No.", "Depreciation Book Code", "Item Receipt No.", ReportID, RowShift);
                end;
                RowShift += 1;
            until Next = 0;
        end;
    end;

    local procedure VerifyFAWriteoffFA4Results(FANo: Code[20]; Description: Text; DeprBookCode: Code[10]; ReceiptNo: Code[20]; ReportID: Integer; RowShift: Integer)
    var
        FA: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        LineRowID: Integer;
    begin
        LineRowID := 38 + RowShift;
        FA.Get(FANo);
        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        LibraryReportValidation.VerifyCellValue(LineRowID, 1, Description);
        LibraryReportValidation.VerifyCellValue(LineRowID, 20, FA."Inventory Number");
        LibraryReportValidation.VerifyCellValue(LineRowID, 30, FA."Factory No.");
        LibraryReportValidation.VerifyCellValue(LineRowID, 40, FA."Manufacturing Year");
        LibraryReportValidation.VerifyCellValue(LineRowID, 50, Format(FA."Initial Release Date"));
        case ReportID of
            REPORT::"FA Write-off Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(FADepreciationBook."Acquisition Cost"));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 90, Format(FADepreciationBook."Book Value"));
                    VerifyItemDocLine(ReceiptNo, 2);
                end;
            REPORT::"FA Posted Writeoff Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(Abs(FADepreciationBook."Acquisition Cost")));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(
                      LineRowID, 90, Format(FADepreciationBook."Acquisition Cost" + FADepreciationBook.Depreciation));
                    VerifyItemRcptLine(ReceiptNo, 2);
                end;
        end;

        VerifyMainAssetComponent(FANo);
        VerifyItemFAPreciousMetal(FANo);
    end;

    local procedure VerifyFAWriteoffFA4aResults(FANo: Code[20]; DeprBookCode: Code[10]; ReceiptNo: Code[20]; ReportID: Integer; RowShift: Integer)
    var
        FA: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        LineRowID: Integer;
    begin
        LineRowID := 40 + RowShift;
        FA.Get(FANo);
        FADepreciationBook.Get(FANo, DeprBookCode);
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        LibraryReportValidation.VerifyCellValue(LineRowID, 1, FA."Manufacturing Year");
        LibraryReportValidation.VerifyCellValue(LineRowID, 10, Format(FADepreciationBook."Acquisition Date", 0, '<Month,2>.<Year4>'));
        LibraryReportValidation.VerifyCellValue(LineRowID, 20, Format(FADepreciationBook."G/L Acquisition Date"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 30, Format(FA."Is Vehicle"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 40, Format(FA."Vehicle Writeoff Date"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 50, Format(FA."Run after Release Date"));
        LibraryReportValidation.VerifyCellValue(LineRowID, 60, Format(FA."Run after Renovation Date"));
        case ReportID of
            REPORT::"FA Write-off Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(Abs(FADepreciationBook."Initial Acquisition Cost")));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 90, Format(FADepreciationBook."Book Value"));
                    VerifyItemDocLine(ReceiptNo, 3);
                end;
            REPORT::"FA Posted Writeoff Act FA-4":
                begin
                    LibraryReportValidation.VerifyCellValue(LineRowID, 70, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(LineRowID, 80, Format(Abs(FADepreciationBook.Depreciation)));
                    LibraryReportValidation.VerifyCellValue(
                      LineRowID, 90, Format(FADepreciationBook."Acquisition Cost" + FADepreciationBook.Depreciation));
                    VerifyItemRcptLine(ReceiptNo, 3);
                end;
        end;

        VerifyFAChars(FANo);
        VerifyItemFAPreciousMetal(FANo);
    end;

    local procedure VerifyMainAssetComponent(FANo: Code[20])
    var
        MainAssetComponent: Record "Main Asset Component";
    begin
        with MainAssetComponent do begin
            SetRange("Main Asset No.", FANo);
            FindSet;
            repeat
                CheckIfValueExistsOnSpecificWorksheet(2, Description);
                CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(Quantity, 2));
            until Next = 0;
        end;
    end;

    local procedure VerifyItemFAPreciousMetal(FANo: Code[20])
    var
        ItemFAPreciousMetal: Record "Item/FA Precious Metal";
    begin
        with ItemFAPreciousMetal do begin
            SetRange("Item Type", "Item Type"::FA);
            SetRange("No.", FANo);
            FindSet;
            repeat
                CalcFields(Name);
                CheckIfValueExistsOnSpecificWorksheet(2, Name);
                CheckIfValueExistsOnSpecificWorksheet(2, "Precious Metals Code");
                CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(Quantity, 2));
                CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue(Mass, 2));
            until Next = 0;
        end;
    end;

    local procedure VerifyFAChars(FANo: Code[20])
    var
        FA: Record "Fixed Asset";
    begin
        with FA do begin
            Get(FANo);
            CheckIfValueExistsOnSpecificWorksheet(2, "Vehicle Reg. No.");
            CheckIfValueExistsOnSpecificWorksheet(2, "Vehicle Engine No.");
            CheckIfValueExistsOnSpecificWorksheet(2, "Vehicle Chassis No.");
            CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue("Vehicle Capacity", 2));
            CheckIfValueExistsOnSpecificWorksheet(2, StdRepMgt.FormatReportValue("Vehicle Passport Weight", 2));
        end;
    end;

    local procedure VerifyItemDocLine(ReceiptNo: Code[20]; WorksheetNo: Integer)
    var
        ItemDocLine: Record "Item Document Line";
    begin
        with ItemDocLine do begin
            SetRange("Document No.", ReceiptNo);
            FindSet;
            repeat
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, "Document No.");
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, Description);
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, "Item No.");
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(Quantity, 2));
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue("Unit Amount", 2));
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(Amount, 2));
            until Next = 0;
        end;
    end;

    local procedure VerifyItemRcptLine(ReceiptNo: Code[20]; WorksheetNo: Integer)
    var
        ItemRcptLine: Record "Item Receipt Line";
    begin
        with ItemRcptLine do begin
            SetRange("Document No.", ReceiptNo);
            FindSet;
            repeat
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, "Document No.");
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, Description);
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, "Item No.");
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(Quantity, 2));
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue("Unit Amount", 2));
                CheckIfValueExistsOnSpecificWorksheet(WorksheetNo, StdRepMgt.FormatReportValue(Amount, 2));
            until Next = 0;
        end;
    end;

    local procedure CheckIfValueExistsOnSpecificWorksheet(WorksheetNo: Integer; Value: Text)
    begin
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(WorksheetNo, Value),
          StrSubstNo(ValueNotExistErr, WorksheetNo));
    end;
}

