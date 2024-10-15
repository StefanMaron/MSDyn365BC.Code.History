codeunit 137456 "Phys. Invt. Recording UT REP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Recording] [Report]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('PhysInvtRecordingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPhysInvtRecordingWithVariousFilters()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] verify execution of Report Physical Inventory Recording with various filters.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInvtRecordingOrderHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        LibraryVariableStorage.Enqueue(PhysInvtRecordHeader."Order No."); // Required inside PhysInvtRecordingRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Phys. Invt. Recording");

        // [THEN] Verify Order No, Recording No, Status and Description on Report Physical Inventory Recording.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header_Order_No_', PhysInvtRecordHeader."Order No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header_Recording_No_', 1);
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header__Status', Format(PhysInvtRecordHeader.Status));
        LibraryReportDataset.AssertElementWithValueExists(
          'Phys__Invt__Recording_Header__Description', PhysInvtRecordHeader.Description);
    end;

    [Test]
    [HandlerFunctions('PhysInvtRecordingWithoutFilterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPhysInvtRecordingWithoutFilters()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        // [SCENARIO] verify execution of Report Physical Inventory Recording without any filter.
        // Setup.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePhysInvtRecordingOrderHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");

        // [WHEN] Run report Physical Inventory Recording without any filter.
        REPORT.Run(REPORT::"Phys. Invt. Recording");

        // [THEN] Verify Report runs for all the Physical Inventory Order which exists in database.
        LibraryReportDataset.LoadDataSetFile();
        PhysInvtRecordHeader.FindFirst();
        repeat
            LibraryReportDataset.AssertElementWithValueExists(
              'Phys__Invt__Recording_Header_Order_No_', PhysInvtRecordHeader."Order No.");
        until PhysInvtRecordHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecordingRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPostedPhysInvtRecordingWithVariousFilters()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
    begin
        // [SCENARIO] verify execution of Report Posted Phys. Invt. Recording with various filters.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePostedPhysInvtRecordingOrderHeader(PstdPhysInvtRecordHdr, PhysInvtOrderHeader."No.");
        LibraryVariableStorage.Enqueue(PstdPhysInvtRecordHdr."Order No."); // Required inside PostedPhysInvtRecordingRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Posted Phys. Invt. Recording");

        // [THEN] Verify Order No, Recording No and Description on Report Posted Physical Inventory Recording.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Rec__Header___Order_No__', PstdPhysInvtRecordHdr."Order No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Rec__Header___Recording_No__', 1);
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Rec__Header__Description', PstdPhysInvtRecordHdr.Description);
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtRecordingWithoutFilterRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportPostedPhysInvtRecordingWithoutFilter()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
    begin
        // [SCENARIO] verify execution of Report Posted Phys. Invt. Recording without any  filters.
        // Setup.
        CreatePhysInventoryOrderHeader(PhysInvtOrderHeader);
        CreatePostedPhysInvtRecordingOrderHeader(PstdPhysInvtRecordHdr, PhysInvtOrderHeader."No.");

        // [WHEN] Run report Posted Physical Inventory Recording without any filter.
        REPORT.Run(REPORT::"Posted Phys. Invt. Recording");

        // [THEN] Verify Report runs for all the Physical Inventory Order which exists in database.
        LibraryReportDataset.LoadDataSetFile();
        PstdPhysInvtRecordHdr.FindFirst();
        repeat
            LibraryReportDataset.AssertElementWithValueExists(
              'Posted_Phys__Invt__Rec__Header___Order_No__', PstdPhysInvtRecordHdr."Order No.");
        until PstdPhysInvtRecordHdr.Next() = 0;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePhysInventoryOrderHeader(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader.Insert();
    end;

    local procedure CreatePhysInvtRecordingOrderHeader(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; OrderNo: Code[20])
    begin
        PhysInvtRecordHeader."Order No." := OrderNo;
        PhysInvtRecordHeader."Recording No." := 1;
        PhysInvtRecordHeader.Description := 'Description';
        PhysInvtRecordHeader.Insert();
    end;

    local procedure CreatePostedPhysInvtRecordingOrderHeader(var PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr"; OrderNo: Code[20])
    begin
        PstdPhysInvtRecordHdr."Order No." := OrderNo;
        PstdPhysInvtRecordHdr."Recording No." := 1;
        PstdPhysInvtRecordHdr.Description := 'Description';
        PstdPhysInvtRecordHdr.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecordingRequestPageHandler(var PhysInvtRecording: TestRequestPage "Phys. Invt. Recording")
    var
        PhysInvtRecordHeaderOrderNo: Variant;
        Status: Option Open,Finished;
    begin
        LibraryVariableStorage.Dequeue(PhysInvtRecordHeaderOrderNo);
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter("Order No.", PhysInvtRecordHeaderOrderNo);
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter("Recording No.", Format(1));
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter(Status, Format(Status::Open));
        PhysInvtRecording."Phys. Invt. Record Header".SetFilter(Description, 'Description');
        PhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecordingRequestPageHandler(var PostedPhysInvtRecording: TestRequestPage "Posted Phys. Invt. Recording")
    var
        PostedPhysInvtRecHeaderOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedPhysInvtRecHeaderOrderNo);
        PostedPhysInvtRecording."Posted Phys. Invt. Record Hdr".SetFilter("Order No.", PostedPhysInvtRecHeaderOrderNo);
        PostedPhysInvtRecording."Posted Phys. Invt. Record Hdr".SetFilter("Recording No.", Format(1));
        PostedPhysInvtRecording."Posted Phys. Invt. Record Hdr".SetFilter(Description, 'Description');
        PostedPhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecordingWithoutFilterRequestPageHandler(var PhysInvtRecording: TestRequestPage "Phys. Invt. Recording")
    begin
        PhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtRecordingWithoutFilterRequestPageHandler(var PostedPhysInvtRecording: TestRequestPage "Posted Phys. Invt. Recording")
    begin
        PostedPhysInvtRecording.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

