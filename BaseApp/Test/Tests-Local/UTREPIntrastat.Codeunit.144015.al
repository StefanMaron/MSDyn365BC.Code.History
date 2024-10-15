#if not CLEAN22
codeunit 144015 "UT REP Intrastat"
{
    // [FEATURE] [Intrastat] [Report]
    // 
    // 1. Verify Total Weight on Intrastat - CheckList Report.
    // 
    // Covers Test Cases for WI - 340255
    // -----------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordIntrastatJnlLineIntrastatCheckList                                                                   340255

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        FileNotCreatedErr: Label 'Intrastat file was not created';

    [Test]
    [HandlerFunctions('IntrastatCheckListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordIntrastatJnlLineIntrastatCheckList()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TotalWtIntrastatJnlLine: Decimal;
    begin
        // Purpose of the test is to verify Total Weight on Intrastat - CheckList Report.

        // Setup: Create Intrastat Journal Line.
        Initialize();
        CreateIntrastatJournalLine(IntrastatJnlLine);
        TotalWtIntrastatJnlLine := IntrastatJnlLine."Total Weight";

        // Exercise.
        REPORT.Run(REPORT::"Intrastat - Checklist");  // Opens handler - IntrastatCheckListRequestPageHandler.

        // Verify: Verify Total Weight and Print Journal Lines on Report - Intrastat - CheckList.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('PrintJnlLines', true);
        LibraryReportDataset.AssertElementWithValueExists('TotalWt_IntrastatJnlLine', TotalWtIntrastatJnlLine);
    end;

    local procedure Initialize()
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        LibraryVariableStorage.Clear();
        IntrastatSetup.DeleteAll();
    end;

    local procedure CreateIntrastatJournalLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        CountryRegion: Record "Country/Region";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        CountryRegion.FindFirst();
        CreateIntrastatJournalTemplateAndBatch(IntrastatJnlBatch);
        IntrastatJnlLine."Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        IntrastatJnlLine."Tariff No." := LibraryUTUtility.GetNewCode;
        IntrastatJnlLine."Country/Region Code" := CountryRegion.Code;
        IntrastatJnlLine."Transaction Type" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Transport Method" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Shpt. Method Code" := LibraryUTUtility.GetNewCode10;
        IntrastatJnlLine."Net Weight" := LibraryRandom.RandDec(10, 2);
        IntrastatJnlLine."Total Weight" := IntrastatJnlLine."Net Weight";
        IntrastatJnlLine.Insert();
        LibraryVariableStorage.Enqueue(IntrastatJnlLine."Journal Template Name");  // Enqueue value for Request Page handler - IntrastatCheckListRequestPageHandler.
    end;

    local procedure CreateIntrastatJournalTemplateAndBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        IntrastatJnlTemplate.Name := LibraryUTUtility.GetNewCode10;
        IntrastatJnlTemplate.Insert();
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Insert();
    end;

    local procedure GetExportedTotalWeight(LineText: Text) TotalWeight: Decimal
    var
        TotalWeightAsText: Text;
    begin
        TotalWeightAsText := SelectStr(5, LineText);
        Assert.IsTrue(Evaluate(TotalWeight, TotalWeightAsText), 'Cannot evaluate text to decimal');
    end;

    local procedure VerifyExportedTotalWeight(FileName: Text; ExpectedTotalWeight: Decimal)
    var
        File: File;
        InStream: InStream;
        LineText: Text;
    begin
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.ReadText(LineText);
        InStream.ReadText(LineText);
        File.Close();

        Assert.AreEqual(ExpectedTotalWeight, GetExportedTotalWeight(LineText), 'Invalid Total Weigth value');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatCheckListRequestPageHandler(var IntrastatCheckList: TestRequestPage "Intrastat - Checklist")
    var
        JournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        IntrastatCheckList."Intrastat Jnl. Line".SetFilter("Journal Template Name", JournalTemplateName);
        IntrastatCheckList.ShowIntrastatJournalLines.SetValue(true);
        IntrastatCheckList.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}
#endif