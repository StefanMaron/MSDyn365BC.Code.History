codeunit 137457 "PostedPhyInvtOrderDiff UT REP"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order] [Difference] [Report]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineDimensionLoopOnAfterGetRecordSingleDimension()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO] validate the LineDimensionLoop OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line. Create and update Dimension Set Entry on Posted Phys. Inventory Line.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        CreateDimension(DimensionSetEntry);
        PstdPhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry."Dimension Set ID";
        PstdPhysInvtOrderLine.Modify();

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the Dimension Code and Dimension Value correctly updated on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'DimText', StrSubstNo('%1 %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LineDimensionLoopOnAfterGetRecordMultipleDimensions()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        // [SCENARIO] validate the LineDimensionLoop OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report for else condition.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line. Create and update Dimension Set Entry on Posted Phys. Inventory Line.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        CreateDimension(DimensionSetEntry);
        CreateDimensionSetEntry(
          DimensionSetEntry2, DimensionSetEntry."Dimension Set ID", LibraryUTUtility.GetNewCode, LibraryUTUtility.GetNewCode);
        PstdPhysInvtOrderLine."Dimension Set ID" := DimensionSetEntry."Dimension Set ID";
        PstdPhysInvtOrderLine.Modify();

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the Dimension Code and Dimension Value correctly updated on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'DimText',
          StrSubstNo(
            '%1 %2, %3 %4',
            DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code",
            DimensionSetEntry2."Dimension Code", DimensionSetEntry2."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithRecordedTrackingAndPositiveAdjmt()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate the Posted Phys. Inventory Order Line OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report with Recording and Positive Adjmt.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line. Update Tracking on Posted Phys. Inventory Order Line. Create Phys. Inventory Recording.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        UpdateTrackingOnPostedPhysInventoryOrderLine(PstdExpPhysInvtTrack, PstdPhysInvtOrderHdr."No.");
        CreatePostedPhysInventoryRecording(PstdPhysInvtRecordLine, PstdPhysInvtOrderHdr."No.");

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the Recorded Tracking, Recorded Quantity and Location Code on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Rec__Serial_No__', PstdPhysInvtRecordLine."Serial No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Rec__Lot_No__', PstdPhysInvtRecordLine."Lot No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Rec__Qty___Base__', PstdPhysInvtOrderLine."Pos. Qty. (Base)");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Order_Line__Location_Code_', PstdPhysInvtOrderLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithRecordedTrackingAndNegativeAdjmt()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate the Posted Phys. Inventory Order Line OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report with Recording and Negative Adjmt.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line. Update Tracking on Posted Phys. Inventory Order Line. Create Phys. Inventory Recording.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
        UpdateTrackingOnPostedPhysInventoryOrderLine(PstdExpPhysInvtTrack, PstdPhysInvtOrderHdr."No.");
        CreatePostedPhysInventoryRecording(PstdPhysInvtRecordLine, PstdPhysInvtOrderHdr."No.");

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the Recorded Tracking, Recorded Quantity and Location Code on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Rec__Serial_No__', PstdPhysInvtRecordLine."Serial No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Rec__Lot_No__', PstdPhysInvtRecordLine."Lot No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Rec__Qty___Base__', PstdPhysInvtOrderLine."Neg. Qty. (Base)");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Order_Line__Location_Code_', PstdPhysInvtOrderLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithExpectedTrackingAndPositiveAdjmt()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
    begin
        // [SCENARIO] validate the Posted Phys. Inventory Order Line OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report with Expected Tracking and Positive Adjmt.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line. Update Tracking on Posted Phys. Inventory Order Line.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        UpdateTrackingOnPostedPhysInventoryOrderLine(PstdExpPhysInvtTrack, PstdPhysInvtOrderHdr."No.");

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the Expected Tracking, Expected Quantity and Location Code on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Exp__Serial_No__', PstdExpPhysInvtTrack."Serial No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Exp__Qty___Base__', PstdPhysInvtOrderLine."Pos. Qty. (Base)");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Order_Line__Location_Code_', PstdPhysInvtOrderLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithExpectedTrackingAndNegativeAdjmt()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track";
    begin
        // [SCENARIO] validate the Posted Phys. Inventory Order Line OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report with Expected Tracking and Negative Adjmt.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line. Update Tracking on Posted Phys. Inventory Order Line.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
        UpdateTrackingOnPostedPhysInventoryOrderLine(PstdExpPhysInvtTrack, PstdPhysInvtOrderHdr."No.");

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the Expected Tracking, Expected Quantity and Location Code on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Exp__Serial_No__', PstdExpPhysInvtTrack."Serial No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'TempPhysInvtCountBuffer__Exp__Qty___Base__', PstdPhysInvtOrderLine."Neg. Qty. (Base)");
        LibraryReportDataset.AssertElementWithValueExists(
          'Posted_Phys__Invt__Order_Line__Location_Code_', PstdPhysInvtOrderLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNewAmountPositive()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate the Posted Phys. Inventory Order Line OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report for New Amount Positive.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.");
        UpdatePostedPhysInventoryOrderStatusToFinished(PstdPhysInvtOrderHdr);  // Update Posted Phys. Inventory Order Status to Finished.

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the New Amount Positive on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'NewAmountPos', PstdPhysInvtOrderLine."Pos. Qty. (Base)" * PstdPhysInvtOrderLine."Unit Amount");
    end;

    [Test]
    [HandlerFunctions('PostedPhysInvtOrderDiffReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordNewAmountNegative()
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate the Posted Phys. Inventory Order Line OnAfterGetRecord of the Posted Phys. Inventory Order Diff. Report for New Amount Negative.

        // [GIVEN] Create Posted Phys. Inventory Order. Update Posted Phys. Inventory Order Line.
        CreatePostedPhysInventoryOrder(PstdPhysInvtOrderHdr, PstdPhysInvtOrderLine, CreateItem);
        UpdatePostedPhysInventoryOrderLine(PstdPhysInvtOrderLine, PstdPhysInvtOrderLine."Entry Type"::"Negative Adjmt.");
        UpdatePostedPhysInventoryOrderStatusToFinished(PstdPhysInvtOrderHdr);  // Update Posted Phys. Inventory Order Status to Finished.

        // [WHEN] Run Posted Phys. Inventory Order Diff. Report.
        RunPostedPhysInvtOrderDiffReport(PstdPhysInvtOrderHdr);

        // [THEN] Verify the New Amount Negative on Posted Phys. Inventory Order Diff. Report.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          'NewAmountNeg', PstdPhysInvtOrderLine."Neg. Qty. (Base)" * PstdPhysInvtOrderLine."Unit Amount");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode;
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreatePostedPhysInventoryOrder(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr"; var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; ItemNo: Code[20])
    begin
        PstdPhysInvtOrderHdr."No." := LibraryUTUtility.GetNewCode;
        PstdPhysInvtOrderHdr.Insert();

        PstdPhysInvtOrderLine."Document No." := PstdPhysInvtOrderHdr."No.";
        PstdPhysInvtOrderLine."Line No." := 1;
        PstdPhysInvtOrderLine."Item No." := ItemNo;
        PstdPhysInvtOrderLine."Location Code" := LibraryUTUtility.GetNewCode10;
        PstdPhysInvtOrderLine.Insert();
    end;

    local procedure CreatePostedPhysInventoryRecording(var PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line"; OrderNo: Code[20])
    var
        PstdPhysInvtRecordHdr: Record "Pstd. Phys. Invt. Record Hdr";
    begin
        PstdPhysInvtRecordHdr."Order No." := OrderNo;
        PstdPhysInvtRecordHdr."Recording No." := 1;
        PstdPhysInvtRecordHdr.Insert();

        PstdPhysInvtRecordLine."Order No." := OrderNo;
        PstdPhysInvtRecordLine."Order Line No." := 1;
        PstdPhysInvtRecordLine.Quantity := 1;
        PstdPhysInvtRecordLine."Quantity (Base)" := 1;
        PstdPhysInvtRecordLine.Recorded := true;
        PstdPhysInvtRecordLine."Serial No." := LibraryUTUtility.GetNewCode;
        PstdPhysInvtRecordLine."Lot No." := LibraryUTUtility.GetNewCode;
        PstdPhysInvtRecordLine.Insert();
    end;

    local procedure CreateDimension(var DimensionSetEntry: Record "Dimension Set Entry")
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry2: Record "Dimension Set Entry";
    begin
        DimensionValue.Code := LibraryUTUtility.GetNewCode;
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode;
        DimensionValue.Insert();

        DimensionSetEntry2.FindLast();
        CreateDimensionSetEntry(DimensionSetEntry,
          DimensionSetEntry2."Dimension Set ID" + LibraryRandom.RandInt(10), DimensionValue."Dimension Code", DimensionValue.Code);  // Should be greater than available Dimension Set ID.
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        DimensionSetEntry."Dimension Set ID" := DimensionSetID;
        DimensionSetEntry."Dimension Code" := DimensionCode;
        DimensionSetEntry."Dimension Value Code" := DimensionValueCode;
        DimensionSetEntry.Insert();
    end;

    local procedure UpdatePostedPhysInventoryOrderLine(var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line"; EntryType: Option)
    begin
        PstdPhysInvtOrderLine."Entry Type" := EntryType;
        PstdPhysInvtOrderLine."Unit Amount" := 1;
        PstdPhysInvtOrderLine."Quantity (Base)" := 1;
        PstdPhysInvtOrderLine."Neg. Qty. (Base)" := 1;
        PstdPhysInvtOrderLine."Pos. Qty. (Base)" := 1;
        PstdPhysInvtOrderLine."Use Item Tracking" := true;
        PstdPhysInvtOrderLine.Modify();
    end;

    local procedure UpdatePostedPhysInventoryOrderStatusToFinished(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr")
    begin
        PstdPhysInvtOrderHdr.Status := PstdPhysInvtOrderHdr.Status::Finished;
        PstdPhysInvtOrderHdr.Modify();
    end;

    local procedure UpdateTrackingOnPostedPhysInventoryOrderLine(var PstdExpPhysInvtTrack: Record "Pstd. Exp. Phys. Invt. Track"; OrderNo: Code[20])
    begin
        PstdExpPhysInvtTrack."Order No" := OrderNo;
        PstdExpPhysInvtTrack."Order Line No." := 1;
        PstdExpPhysInvtTrack."Serial No." := LibraryUTUtility.GetNewCode;
        PstdExpPhysInvtTrack."Quantity (Base)" := 1;
        PstdExpPhysInvtTrack.Insert();
    end;

    local procedure RunPostedPhysInvtOrderDiffReport(var PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr")
    var
        PostedPhysInvtOrderDiff: Report "Posted Phys. Invt. Order Diff.";
    begin
        PstdPhysInvtOrderHdr.SetRange("No.", PstdPhysInvtOrderHdr."No.");
        PostedPhysInvtOrderDiff.SetTableView(PstdPhysInvtOrderHdr);
        PostedPhysInvtOrderDiff.Run();  // Invokes PostedPhysInvtOrderDiffReportHandler.
        Clear(PostedPhysInvtOrderDiff);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedPhysInvtOrderDiffReportHandler(var PostedPhysInvtOrderDiff: TestRequestPage "Posted Phys. Invt. Order Diff.")
    begin
        PostedPhysInvtOrderDiff.ShowDimensions.SetValue(true);
        PostedPhysInvtOrderDiff.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

