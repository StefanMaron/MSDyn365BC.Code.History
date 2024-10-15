codeunit 144538 "EMR ECSL - GB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ECSL Report]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesPageShownWhenSingleVATEntryConnectsToECSLLine()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        ECSLReport: TestPage "ECSL Report";
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 294938] VAT Entries page shown when single VAT Entry connects to ECSL VAT Report Line

        // [GIVEN] ECSL Report with line connects to single VAT Entry
        MockVATReport(ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);

        // [GIVEN] ECSL Report page opened
        ECSLReport.OpenEdit;
        ECSLReport.FILTER.SetFilter("No.", ECSLVATReportLine."Report No.");
        VATEntries.Trap;

        // [WHEN] User clicks "Show Lines" in ECSL Report subpage
        ECSLReport.ECSLReportLines.ShowLines.Invoke;

        // [THEN] VAT Entries page shown
        VATEntry.Get(ECSLVATReportLineRelation."VAT Entry No.");
        VATEntries."Document No.".AssertEquals(VATEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPreviewEntriesPageShownWhenMultipleVATEntriesConnectsToECSLLine()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        ECSLReport: TestPage "ECSL Report";
        VATEntriesPreview: TestPage "VAT Entries Preview";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 294938] VAT Entries Preview page shown when multiple VAT Entries connects to ECSL VAT Report Line

        // [GIVEN] ECSL Report with line connects to multiple VAT Entries
        MockVATReport(ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);

        // [GIVEN] ECSL Report page opened
        ECSLReport.OpenEdit;
        ECSLReport.FILTER.SetFilter("No.", ECSLVATReportLine."Report No.");
        VATEntriesPreview.Trap;

        // [WHEN] User clicks "Show Lines" in ECSL Report subpage
        ECSLReport.ECSLReportLines.ShowLines.Invoke;

        // [THEN] VAT Entries Preview page shown
        VATEntry.Get(ECSLVATReportLineRelation."VAT Entry No.");
        VATEntriesPreview."Document No.".AssertEquals(VATEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesPageOpensFromVATEntriesPreviewPage()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        ECSLReport: TestPage "ECSL Report";
        VATEntriesPreview: TestPage "VAT Entries Preview";
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 294938] Stan can open VAT Entries page from VAT Entries preview page

        // [GIVEN] ECSL Report with line connects to multiple VAT Entries
        MockVATReport(ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);

        // [GIVEN] VAT Entries Preview page opened from ECSL Report page
        ECSLReport.OpenEdit;
        ECSLReport.FILTER.SetFilter("No.", ECSLVATReportLine."Report No.");
        VATEntriesPreview.Trap;
        ECSLReport.ECSLReportLines.ShowLines.Invoke;
        VATEntries.Trap;

        // [WHEN] User clicks "Edit VAT Entry"
        VATEntriesPreview.EditVATEntry.Invoke;

        // [THEN] Single VAT Entry shown on VAT Entries page
        VATEntry.Get(ECSLVATReportLineRelation."VAT Entry No.");
        VATEntries."Document No.".AssertEquals(VATEntry."Document No.");
        Assert.IsFalse(VATEntries.Next, '');
    end;

    local procedure MockVATReport(var ECSLVATReportLine: Record "ECSL VAT Report Line")
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        MockVATReportConfiguration;
        VATReportHeader.Init;
        VATReportHeader.Validate("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"EC Sales List");
        VATReportHeader.Validate(Status, VATReportHeader.Status::Open);
        VATReportHeader.Insert(true);
        ECSLVATReportLine.Init;
        ECSLVATReportLine.Validate("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.Validate("Line No.", 10000);
        ECSLVATReportLine.Insert;
    end;

    local procedure MockECSLToVATEntryRelation(var ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation"; ECSLVATReportLine: Record "ECSL VAT Report Line")
    begin
        ECSLVATReportLineRelation.Init;
        ECSLVATReportLineRelation.Validate("ECSL Report No.", ECSLVATReportLine."Report No.");
        ECSLVATReportLineRelation.Validate("ECSL Line No.", ECSLVATReportLine."Line No.");
        ECSLVATReportLineRelation.Validate("VAT Entry No.", MockVATEntry);
        ECSLVATReportLineRelation.Insert;
    end;

    local procedure MockVATEntry(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init;
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Document No." := LibraryUtility.GenerateGUID;
        VATEntry.Insert;
        exit(VATEntry."Entry No.");
    end;

    local procedure MockVATReportConfiguration()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.DeleteAll;
        VATReportsConfiguration.Init;
        VATReportsConfiguration.Validate("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"EC Sales List");
        VATReportsConfiguration.Insert(true);
    end;
}

