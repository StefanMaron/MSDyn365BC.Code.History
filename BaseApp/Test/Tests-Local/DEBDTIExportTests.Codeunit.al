codeunit 144000 "DEB DTI Export Tests"
{
    // // [FEATURE] [Intrastat] [DTI]
    // 
    // Covers Test cases: 298067,298057,298061

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryXMLRead: Codeunit "Library - XML Read";
        BatchReportedErr: Label 'This batch is already marked as reported. If you want to export an XML file for another obligation level, clear the Reported field in the Intrastat journal batch %1.', Comment = '%1 - Intrastat Jnl. Batch Name';
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        PostingMessage: Label 'The journal lines were successfully exported.';
        StatisticsPeriodError: Label '%1 must have a value in %2: %3=%4, %5=%6. It cannot be zero or empty.';
        CompanyInfoError: Label '%1 must have a value in %2: Primary Key=. It cannot be zero or empty.';
        TransactionSpecificationError: Label '%1 must have a value in %2: %3=%4, %5=%6, %7=%8. It cannot be zero or empty.';
        FileNotExistErr: Label 'File does not exist';

    [Test]
    [Scope('OnPrem')]
    procedure TestBasicXMLContent()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        DefaultExportToXML(TempIntrastatJnlLine);

        VerifyXMLFileHeader;
        VerifyXMLDeclarationHeader;
        // TFS ID 399429: Intrastat xml file has: "MSConsDestCode" = "Entry/Exit Point", "regionCode" = "Area"
        VerifyXMLItemContent(TempIntrastatJnlLine);
        VerifyNoOptionalXMLItemContent;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBatchStatPeriodMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        IntrastatJnlBatch.Get(TempIntrastatJnlLine."Journal Template Name", TempIntrastatJnlLine."Journal Batch Name");
        IntrastatJnlBatch."Statistics Period" := '';
        IntrastatJnlBatch.Modify(true);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(
          StrSubstNo(
            StatisticsPeriodError,
            IntrastatJnlBatch.FieldCaption("Statistics Period"), IntrastatJnlBatch.TableCaption,
            IntrastatJnlBatch.FieldCaption("Journal Template Name"), IntrastatJnlBatch."Journal Template Name",
            IntrastatJnlBatch.FieldCaption(Name), IntrastatJnlBatch.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCISDFieldOnCompanyInfoPage()
    var
        CompanyInformationPage: TestPage "Company Information";
        CISDValue: Code[10];
    begin
        Initialize;
        SetCompanyInfoCISDValue('');

        CompanyInformationPage.OpenEdit;
        CISDValue := Format(Today, 0, 9);
        CompanyInformationPage.CISD.SetValue(CISDValue);

        Assert.IsTrue(CompanyInformationPage.CISD.Visible, 'CISD control should be visible.');
        Assert.IsTrue(CompanyInformationPage.CISD.Editable, 'CISD control should be editable.');
        Assert.AreEqual(CISDValue, CompanyInformationPage.CISD.Value, 'Wrong CISD value.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCISDIsMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        CompanyInfo: Record "Company Information";
    begin
        Initialize;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        SetCompanyInfoCISDValue('');

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(StrSubstNo(CompanyInfoError, CompanyInfo.FieldCaption(CISD), CompanyInfo.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeclarationIdIncreased()
    var
        CompanyInfo: Record "Company Information";
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        ExpectedDeclarationID: Integer;
    begin
        Initialize;
        SetCompanyInfo;
        CompanyInfo.Get();
        ExpectedDeclarationID := CompanyInfo."Last Intrastat Declaration ID";
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        ExpectedDeclarationID := ExpectedDeclarationID + 1;
        DefaultExportToXML(TempIntrastatJnlLine);

        LibraryXMLRead.VerifyNodeValue('declarationId', Format(ExpectedDeclarationID, 0, '<Integer,6><Filler Character,0>'));

        VerifyLastDeclarationId(ExpectedDeclarationID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeclarationIdOnTwoDecl()
    var
        CompanyInfo: Record "Company Information";
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        Node: DotNet XmlNode;
        ExpectedDeclarationID: Integer;
        TotalAmountRcpt: Decimal;
        TotalAmountShpt: Decimal;
        i: Integer;
    begin
        Initialize;
        SetCompanyInfo;
        CompanyInfo.Get();
        ExpectedDeclarationID := CompanyInfo."Last Intrastat Declaration ID";
        GenerateSetOfRcptShpt(TempIntrastatJnlLine, TotalAmountRcpt, TotalAmountShpt);
        DefaultExportToXML(TempIntrastatJnlLine);

        LibraryXMLRead.GetNodeListByElementName('Declaration', NodeList);
        Assert.IsTrue(NodeList.Count > 0, 'Declaration element doesnt have child nodes.');
        for i := 0 to NodeList.Count - 1 do begin
            ExpectedDeclarationID := ExpectedDeclarationID + 1;
            Node := NodeList.Item(i).SelectSingleNode('declarationId');
            Assert.AreEqual(
              Format(ExpectedDeclarationID, 0, '<Integer,6><Filler Character,0>'), Node.InnerText, 'Wrong <declarationId>');
        end;

        VerifyLastDeclarationId(ExpectedDeclarationID);
    end;

    [Test]
    [HandlerFunctions('VerifyVisibleObligationLivelIs1')]
    [Scope('OnPrem')]
    procedure TestDefaultObligationLevelOnReqPage()
    begin
        Initialize;
        InvokeReportAction;
        // Verification is in handler VerifyVisibleObligationLivelIs1
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyXMLFile()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        ExportDEBDTI: Codeunit "Export DEB DTI";
        ObligationLevel: Integer;
        FileOutStream: OutStream;
    begin
        Initialize;
        SetCompanyInfo;
        TempIntrastatJnlLine.DeleteAll();
        ObligationLevel := 1;
        asserterror ExportDEBDTI.ExportToXML(TempIntrastatJnlLine, ObligationLevel, FileOutStream);
        Assert.ExpectedError('There is nothing to export')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPartyIDControlSumTwoNum()
    begin
        Initialize;
        VerifyPartyID('404833048', '83');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPartyIDControlSumOneNum()
    begin
        Initialize;
        VerifyPartyID('404833055', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGroupingInXMLFile()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        ExportDEBDTI: Codeunit "Export DEB DTI";
        FileTempBlob: Codeunit "Temp Blob";
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        FlowCodeNode: DotNet XmlNode;
        ObligationLevel: Integer;
        ReceiptExists: Boolean;
        ShipmentExists: Boolean;
        TotalAmountForReceipt: Decimal;
        TotalAmountForShipment: Decimal;
        i: Integer;
        FileOutStream: OutStream;
        FileInStream: InStream;
        FileContent: Text;
    begin
        Initialize;
        SetCompanyInfo;

        GenerateSetOfRcptShpt(TempIntrastatJnlLine, TotalAmountForReceipt, TotalAmountForShipment);

        ObligationLevel := 1;
        FileTempBlob.CreateOutStream(FileOutStream);
        ExportDEBDTI.ExportToXML(TempIntrastatJnlLine, ObligationLevel, FileOutStream);
        FileTempBlob.CreateInStream(FileInStream, TextEncoding::UTF8);
        FileInStream.Read(FileContent);
        LibraryXMLRead.InitializeFromXmlText(FileContent);

        LibraryXMLRead.GetNodeListByElementName('Declaration', NodeList);
        Assert.AreEqual(2, NodeList.Count, 'Incorrect count for Declaration');

        for i := 0 to (NodeList.Count - 1) do begin
            FlowCodeNode := NodeList.Item(i).SelectSingleNode('flowCode');
            case FlowCodeNode.InnerText of
                'A':
                    ValidateFlowCode(ReceiptExists, TotalAmountForReceipt, FlowCodeNode);
                'D':
                    ValidateFlowCode(ShipmentExists, TotalAmountForShipment, FlowCodeNode);
                else
                    Error('Incorrect flowCode: %1', FlowCodeNode.InnerText);
            end;
        end;
        Assert.IsTrue(ReceiptExists, 'Information for Receipts not found');
        Assert.IsTrue(ShipmentExists, 'Information for Shipments not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJnlTransactionTypeBCode()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        TempIntrastatJnlLine."Transaction Type" := '70';
        TempIntrastatJnlLine.Modify(true);

        DefaultExportToXML(TempIntrastatJnlLine);

        LibraryXMLRead.VerifyNodeValue('natureOfTransactionACode', '7');
        asserterror LibraryXMLRead.VerifyNodeValue('natureOfTransactionBCode', '0');
        Assert.ExpectedError('natureOfTransactionBCode');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJnlTransactionTypeMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        TempIntrastatJnlLine."Transaction Type" := '01';
        TempIntrastatJnlLine.Modify(true);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError('must not start with zero');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestJnlTransSpecMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        TempIntrastatJnlLine."Transaction Specification" := '';
        TempIntrastatJnlLine.Modify(true);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(
          StrSubstNo(
            TransactionSpecificationError, TempIntrastatJnlLine.FieldCaption("Transaction Specification"),
            TempIntrastatJnlLine.TableCaption,
            TempIntrastatJnlLine.FieldCaption("Journal Template Name"), TempIntrastatJnlLine."Journal Template Name",
            TempIntrastatJnlLine.FieldCaption("Journal Batch Name"),
            TempIntrastatJnlLine."Journal Batch Name", TempIntrastatJnlLine.FieldCaption("Line No."), TempIntrastatJnlLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMinXMLFile()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        ExportDEBDTI: Codeunit "Export DEB DTI";
        ObligationLevel: Integer;
        FileTempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        ObligationLevel := 2;
        FileTempBlob.CreateOutStream(FileOutStream);
        ExportDEBDTI.ExportToXML(TempIntrastatJnlLine, ObligationLevel, FileOutStream);
        Assert.IsTrue(FileTempBlob.HasValue(), FileNotExistErr);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure TestMinXMLFileViaReport()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        ExportDEBDTI: Report "Export DEB DTI";
        FileTempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
    begin
        Initialize;
        SetCompanyInfo;
        SetBatchStatPeriod(IntrastatJnlBatch);
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);
        IntrastatJnlLine.DeleteAll();
        CreateBasicIntrastatJnlLine(IntrastatJnlLine);
        IntrastatJnlBatch.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlBatch.SetRange(Name, IntrastatJnlBatch.Name);

        FileTempBlob.CreateOutStream(FileOutStream);
        ExportDEBDTI.InitializeRequest(FileOutStream);
        ExportDEBDTI.UseRequestPage(false);
        ExportDEBDTI.SetTableView(IntrastatJnlBatch);
        ExportDEBDTI.Run;

        Assert.IsTrue(FileTempBlob.HasValue(), FileNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultiJnlTransSpecMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateInvalidStatValueJnlSet(TempIntrastatJnlLine);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(
          StrSubstNo(
            TransactionSpecificationError, TempIntrastatJnlLine.FieldCaption("Transaction Specification"),
            TempIntrastatJnlLine.TableCaption,
            TempIntrastatJnlLine.FieldCaption("Journal Template Name"), TempIntrastatJnlLine."Journal Template Name",
            TempIntrastatJnlLine.FieldCaption("Journal Batch Name"),
            TempIntrastatJnlLine."Journal Batch Name", TempIntrastatJnlLine.FieldCaption("Line No."), TempIntrastatJnlLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMultJnlTransTypeMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateInvalidTransTypeJnlSet(TempIntrastatJnlLine);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError('must not start with zero');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNameIsMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        CompanyInfo: Record "Company Information";
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        SetCompanyInfoNameValue('');

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(StrSubstNo(CompanyInfoError, CompanyInfo.FieldCaption(Name), CompanyInfo.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeQuantity()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        TempIntrastatJnlLine.Quantity := -TempIntrastatJnlLine.Quantity;
        TempIntrastatJnlLine.Modify(true);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError('Quantity must be positive');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNegativeStatsValue()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        TempIntrastatJnlLine."Statistical Value" := -TempIntrastatJnlLine."Statistical Value";
        TempIntrastatJnlLine.Modify(true);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError('Statistical Value must be positive');
    end;

    [Test]
    [HandlerFunctions('VerifyObligationLevelAllowedIn1to4')]
    [Scope('OnPrem')]
    procedure TestObligationLevelOnReqPageInRange1To4()
    begin
        Initialize;
        SetCompanyInfo;
        InvokeReportAction;
        // Verification is in handler VerifyObligationLevelAllowedIn1to4.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOptionalXMLContent()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        SetDefaultOptionalValues(TempIntrastatJnlLine);
        DefaultExportToXML(TempIntrastatJnlLine);

        VerifyXMLFileHeader;
        VerifyXMLDeclarationHeader;
        VerifyXMLItemContent(TempIntrastatJnlLine);
        VerifyOptionalXMLItemContent(TempIntrastatJnlLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestQtyForTariffWithoutSU()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        SetTariffNoWithSupplemUnit(TempIntrastatJnlLine, false);
        asserterror LibraryXMLRead.VerifyNodeValue('quantityInSU', '0');
        Assert.ExpectedError('quantityInSU');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestQtyForTariffWithSU()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;
        SetTariffNoWithSupplemUnit(TempIntrastatJnlLine, true);
        LibraryXMLRead.VerifyNodeValue('quantityInSU', Format(Round(TempIntrastatJnlLine.Quantity, 1), 0, 9));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRegistrationNoIsMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        CompanyInfo: Record "Company Information";
    begin
        Initialize;
        SetCompanyInfo;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        SetCompanyInfoRegNoValue('');

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(StrSubstNo(CompanyInfoError, CompanyInfo.FieldCaption("Registration No."), CompanyInfo.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportedFlagIsTrue()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        SetCompanyInfo;

        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        DefaultExportToXML(TempIntrastatJnlLine);

        VerifyExpectedReportedFlag(TempIntrastatJnlLine, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportedFlagPreventsExport()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        Initialize;
        SetCompanyInfo;

        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        DefaultExportToXML(TempIntrastatJnlLine);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(
          StrSubstNo(BatchReportedErr, TempIntrastatJnlLine."Journal Batch Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportedFlagRemainsFalse()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
    begin
        Initialize;
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        Commit();
        TempIntrastatJnlLine.Quantity := 0;
        TempIntrastatJnlLine.Modify(true);

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        VerifyExpectedReportedFlag(TempIntrastatJnlLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATRegNoIsMandatory()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        CompanyInfo: Record "Company Information";
    begin
        Initialize;
        SetCompanyInfo;

        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        SetCompanyInfoVATRegNoValue('');

        asserterror DefaultExportToXML(TempIntrastatJnlLine);
        Assert.ExpectedError(
          StrSubstNo(
            CompanyInfoError, CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemNumberNodeIncrementAndExtend()
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        LineCount: Integer;
        ItemNodeCount: Integer;
    begin
        // [SCENARIO 375212] itemNumber XML tag value is incremented line by line and is expanded to 6 sybmols with zeros
        Initialize;
        SetCompanyInfo;

        // [GIVEN] "X" Intrastat Journal lines
        for LineCount := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        DefaultExportToXML(TempIntrastatJnlLine);

        // [WHEN] Intrastat Journal lines exported to DTI XML file
        LibraryXMLRead.VerifyNodeValue('itemNumber', Format(1, 0, '<Integer,6><Filler Character,0>'));

        // [THEN] Exported file contain "X" "Item" nodes with "itemNumber" begin from 000001 and ends with 00000X
        for ItemNodeCount := 1 to LineCount do
            LibraryXMLRead.VerifyNodeValueInSubtree('Item', 'itemNumber', Format(ItemNodeCount, 0, '<Integer,6><Filler Character,0>'));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"DEB DTI Export Tests");
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"DEB DTI Export Tests");

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"DEB DTI Export Tests");
    end;

    local procedure CreateBasicIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        SetBatchStatPeriod(IntrastatJnlBatch);

        IntrastatJnlLine.Init();
        IntrastatJnlLine."Journal Template Name" := IntrastatJnlBatch."Journal Template Name";
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        IntrastatJnlLine."Line No." := IntrastatJnlLine."Line No." + 10000;
        IntrastatJnlLine.Type := IntrastatJnlLine.Type::Shipment;
        IntrastatJnlLine.Date := WorkDate;
        IntrastatJnlLine.Quantity := 9001.0;
        IntrastatJnlLine.Amount := 10003.12;
        IntrastatJnlLine."Statistical Value" := 19234.5;
        IntrastatJnlLine."Transaction Specification" := '21';
        IntrastatJnlLine.Area := CreateArea;
        IntrastatJnlLine."Entry/Exit Point" := CreateEntryExitPoint;
        IntrastatJnlLine.Insert();
    end;

    local procedure CreateIntrastatJnlLineSpecType(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; LineType: Integer; var TotalAmount: Decimal)
    begin
        CreateBasicIntrastatJnlLine(IntrastatJnlLine);
        IntrastatJnlLine.Type := LineType;
        IntrastatJnlLine.Modify();

        TotalAmount := TotalAmount + Round(IntrastatJnlLine."Statistical Value", 1);
    end;

    local procedure CreateInvalidStatValueJnlSet(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        TotalAmountReceipt: Decimal;
        TotalAmountShip: Decimal;
    begin
        GenerateSetOfRcptShpt(IntrastatJnlLine, TotalAmountReceipt, TotalAmountShip);
        IntrastatJnlLine.Next(IntrastatJnlLine.Count div 2);
        IntrastatJnlLine."Transaction Specification" := '';
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateInvalidTransTypeJnlSet(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        TotalAmountReceipt: Decimal;
        TotalAmountShip: Decimal;
    begin
        GenerateSetOfRcptShpt(IntrastatJnlLine, TotalAmountReceipt, TotalAmountShip);
        IntrastatJnlLine.Next(IntrastatJnlLine.Count div 2);
        IntrastatJnlLine."Transaction Type" := '01';
        IntrastatJnlLine.Modify();
    end;

    local procedure CreateArea(): Code[10]
    var
        "Area": Record "Area";
    begin
        Area.Init;
        Area.Code :=
          LibraryUtility.GenerateRandomCodeWithLength(Area.FieldNo(Code), DATABASE::Area, MaxStrLen(Area.Code));
        Area.Insert;
        exit(Area.Code);
    end;

    local procedure CreateEntryExitPoint(): Code[10]
    var
        EntryExitPoint: Record "Entry/Exit Point";
    begin
        EntryExitPoint.Init;
        EntryExitPoint.Code :=
          LibraryUtility.GenerateRandomCodeWithLength(
            EntryExitPoint.FieldNo(Code), DATABASE::"Entry/Exit Point", MaxStrLen(EntryExitPoint.Code));
        EntryExitPoint.Insert;
        exit(EntryExitPoint.Code);
    end;

    local procedure DefaultExportToXML(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        ExportDEBDTI: Codeunit "Export DEB DTI";
        FileTempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
        FileInStream: InStream;
        FileContent: Text;
    begin
        FileTempBlob.CreateOutStream(FileOutStream);
        ExportDEBDTI.ExportToXML(IntrastatJnlLine, 1, FileOutStream);

        FileTempBlob.CreateInStream(FileInStream, TextEncoding::UTF8);
        FileInStream.Read(FileContent);
        LibraryXMLRead.InitializeFromXmlText(FileContent);
    end;

    local procedure GenerateSetOfRcptShpt(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var TotalAmountForReceipt: Decimal; var TotalAmountForShipment: Decimal)
    begin
        CreateIntrastatJnlLineSpecType(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, TotalAmountForReceipt);
        CreateIntrastatJnlLineSpecType(IntrastatJnlLine, IntrastatJnlLine.Type::Shipment, TotalAmountForShipment);
        CreateIntrastatJnlLineSpecType(IntrastatJnlLine, IntrastatJnlLine.Type::Receipt, TotalAmountForReceipt);
    end;

    local procedure GetStatsPeriodForDate(Date: Date): Code[10]
    begin
        exit(Format(Date, 0, '<Year,2><Month,2>'));
    end;

    local procedure GetTariffNo(var TariffNo: Record "Tariff Number"; SupplementaryUnit: Boolean)
    begin
        TariffNo.FindFirst;
        TariffNo."Supplementary Units" := SupplementaryUnit;
        TariffNo.Modify();
    end;

    local procedure InvokeReportAction()
    var
        IntrastatJournalPage: TestPage "Intrastat Journal";
    begin
        Commit();
        IntrastatJournalPage.OpenEdit;
        IntrastatJournalPage."Export DEB DTI+".Invoke;
    end;

    local procedure SetBatchStatPeriod(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlTemplate: Record "Intrastat Jnl. Template";
        StatsPeriod: Code[10];
    begin
        StatsPeriod := GetStatsPeriodForDate(WorkDate);
        if not IntrastatJnlTemplate.FindFirst then begin
            IntrastatJnlTemplate.Init();
            IntrastatJnlTemplate.Name := 'Test';
            IntrastatJnlTemplate.Insert(true);
        end;

        IntrastatJnlBatch.Reset();
        IntrastatJnlBatch.SetRange("Statistics Period", StatsPeriod);
        IntrastatJnlBatch.DeleteAll(true);

        IntrastatJnlBatch.Reset();
        if IntrastatJnlBatch.Get(IntrastatJnlTemplate.Name, StatsPeriod) then
            IntrastatJnlBatch.Delete(true);

        IntrastatJnlBatch.Init();
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlTemplate.Name;
        IntrastatJnlBatch.Name := StatsPeriod;
        IntrastatJnlBatch."Statistics Period" := StatsPeriod;
        IntrastatJnlBatch.Reported := false;
        IntrastatJnlBatch.Insert(true);
    end;

    local procedure SetCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
        SIREN: Code[9];
        SIRET: Code[14];
    begin
        SIREN := '404833048';
        SIRET := SIREN + '00022';
        CompanyInfo.Get();
        CompanyInfo.Validate("Registration No.", SIRET);
        CompanyInfo.Validate("Country/Region Code", 'FR');
        CompanyInfo.Validate("VAT Registration No.", CopyStr(CompanyInfo.GetPartyID, 1, 13));
        CompanyInfo.CISD := 'A1';
        // CompanyInfo.Name shouldnt be empty
        CompanyInfo.Modify(true);
    end;

    local procedure SetCompanyInfoCISDValue(NewCISDValue: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.CISD := NewCISDValue;
        CompanyInformation.Modify(true);
    end;

    local procedure SetCompanyInfoNameValue(NewNameValue: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, NewNameValue);
        CompanyInformation.Modify(true);
    end;

    local procedure SetCompanyInfoRegNoValue(NewRegNoValue: Text[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Registration No.", NewRegNoValue);
        CompanyInformation.Modify(true);
    end;

    local procedure SetCompanyInfoVATRegNoValue(NewVATRegNoValue: Text[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", NewVATRegNoValue);
        CompanyInformation.Modify(true);
    end;

    local procedure SetDefaultOptionalValues(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        TariffNo: Record "Tariff Number";
    begin
        GetTariffNo(TariffNo, true);
        IntrastatJnlLine."Tariff No." := TariffNo."No.";
        IntrastatJnlLine."Partner VAT ID" := 'FI01137535';
        IntrastatJnlLine."Country/Region of Origin Code" := 'FI';
        IntrastatJnlLine."Total Weight" := 2009.1;
        IntrastatJnlLine."Supplementary Units" := true;
        IntrastatJnlLine."Transport Method" := '3';
        IntrastatJnlLine."Transaction Type" := '12';
        IntrastatJnlLine.Modify();
    end;

    local procedure SetTariffNoWithSupplemUnit(var TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary; SupplementaryUnit: Boolean)
    var
        TariffNo: Record "Tariff Number";
    begin
        CreateBasicIntrastatJnlLine(TempIntrastatJnlLine);
        GetTariffNo(TariffNo, SupplementaryUnit);
        TempIntrastatJnlLine.Validate("Tariff No.", TariffNo."No.");
        TempIntrastatJnlLine.Modify();

        DefaultExportToXML(TempIntrastatJnlLine);
    end;

    local procedure TotalInvoicedAmount(FlowCodeNode: DotNet XmlNode) Total: Decimal
    var
        [RunOnClient]
        ItemsNodeList: DotNet XmlNodeList;
        [RunOnClient]
        ItemNode: DotNet XmlNode;
        [RunOnClient]
        InvoicedAmountNode: DotNet XmlNode;
        i: Integer;
        Amount: Decimal;
    begin
        ItemsNodeList := FlowCodeNode.ParentNode.SelectNodes('Item');
        for i := 0 to ItemsNodeList.Count - 1 do begin
            ItemNode := ItemsNodeList.Item(i);
            InvoicedAmountNode := ItemNode.SelectSingleNode('invoicedAmount');
            Evaluate(Amount, InvoicedAmountNode.InnerText, 9);
            Total := Total + Amount;
        end;

        exit(Total);
    end;

    local procedure ValidateFlowCode(var NodeExists: Boolean; TotalAmount: Decimal; FlowCodeNode: DotNet XmlNode)
    var
        Amount: Decimal;
    begin
        Amount := TotalInvoicedAmount(FlowCodeNode);
        Assert.AreEqual(TotalAmount, Amount, 'Incorrect invoicedAmount for flowCode = ' + FlowCodeNode.InnerText);
        NodeExists := true;
    end;

    local procedure VerifyDateTimeStructure()
    var
        Value: Text;
        ActualTime: Time;
        ActualDate: Date;
    begin
        Value := LibraryXMLRead.GetElementValue('time');
        Assert.AreEqual(8, StrLen(Value), '<time> length must be 8.');
        Evaluate(ActualTime, Value, 9);

        Value := LibraryXMLRead.GetElementValue('date');
        Evaluate(ActualDate, Value, 9);
        if Abs(Today - ActualDate) > 1 then
            Assert.Fail('<date> is wrong.');
    end;

    local procedure VerifyExpectedReportedFlag(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ExpectedFlagValue: Boolean)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        AssertFailedMessage: Text[1024];
    begin
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");
        if ExpectedFlagValue then
            AssertFailedMessage :=
              StrSubstNo('Reported flag should have been set to TRUE in Intrastat Jnl. Batch %1.', IntrastatJnlBatch.Name)
        else
            AssertFailedMessage :=
              StrSubstNo('Reported flag must remain FALSE in Intrastat Jnl. Batch %1, when export gets aborted.', IntrastatJnlBatch.Name);

        Assert.AreEqual(ExpectedFlagValue, IntrastatJnlBatch.Reported, AssertFailedMessage);
    end;

    local procedure VerifyLastDeclarationId(ExpectedDeclarationId: Integer)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        Assert.AreEqual(
          ExpectedDeclarationId, CompanyInfo."Last Intrastat Declaration ID",
          'Wrong <Last Intrastat Declaration ID> in CompanyInfo');
    end;

    local procedure VerifyNodeHasChildren(ElementName: Text[30])
    var
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        LibraryXMLRead.GetNodeByElementName(ElementName, Node);
        Assert.IsTrue(Node.HasChildNodes, StrSubstNo('<%1> should have child nodes.', ElementName));
    end;

    local procedure VerifyNoOptionalXMLItemContent()
    begin
        asserterror VerifyNodeHasChildren('CN8');
        Assert.ExpectedError('CN8');
        asserterror LibraryXMLRead.VerifyNodeValue('CN8Code', '');
        Assert.ExpectedError('CN8Code');
        asserterror LibraryXMLRead.VerifyNodeValue('countryOfOriginCode', '');
        Assert.ExpectedError('countryOfOriginCode');
        asserterror LibraryXMLRead.VerifyNodeValue('netMass', '0');
        Assert.ExpectedError('netMass');
        asserterror LibraryXMLRead.VerifyNodeValue('quantityInSU', '0');
        Assert.ExpectedError('quantityInSU');
        asserterror LibraryXMLRead.VerifyNodeValue('partnerId', '');
        Assert.ExpectedError('partnerId');
        asserterror VerifyNodeHasChildren('NatureOfTransaction');
        Assert.ExpectedError('NatureOfTransaction');
        asserterror LibraryXMLRead.VerifyNodeValue('natureOfTransactionACode', '');
        Assert.ExpectedError('natureOfTransactionACode');
        asserterror LibraryXMLRead.VerifyNodeValue('natureOfTransactionBCode', '');
        Assert.ExpectedError('natureOfTransactionBCode');
        asserterror LibraryXMLRead.VerifyNodeValue('modeOfTransportCode', '');
        Assert.ExpectedError('modeOfTransportCode');
    end;

    local procedure VerifyOptionalXMLItemContent(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        VerifyNodeHasChildren('CN8');
        LibraryXMLRead.VerifyNodeValue('CN8Code', DelChr(IntrastatJnlLine."Tariff No."));
        LibraryXMLRead.VerifyNodeValue('countryOfOriginCode', IntrastatJnlLine."Country/Region of Origin Code");
        LibraryXMLRead.VerifyNodeValue('netMass', Format(Round(IntrastatJnlLine."Total Weight", 1), 0, 9));
        LibraryXMLRead.VerifyNodeValue('quantityInSU', Format(IntrastatJnlLine.Quantity, 0, 9));
        LibraryXMLRead.VerifyNodeValue('partnerId', IntrastatJnlLine."Partner VAT ID");
        VerifyNodeHasChildren('NatureOfTransaction');
        LibraryXMLRead.VerifyNodeValue('natureOfTransactionACode', CopyStr(IntrastatJnlLine."Transaction Type", 1, 1));
        LibraryXMLRead.VerifyNodeValue('natureOfTransactionBCode', CopyStr(IntrastatJnlLine."Transaction Type", 2, 1));
        LibraryXMLRead.VerifyNodeValue('modeOfTransportCode', IntrastatJnlLine."Transport Method");
    end;

    local procedure VerifyPartyID(SIREN: Text[9]; ExpectedControlSum: Text[2])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo."Country/Region Code" := 'FR';
        CompanyInfo."Registration No." := SIREN + '00022';
        Assert.AreEqual(
          CompanyInfo."Country/Region Code" + ExpectedControlSum + CompanyInfo."Registration No.",
          CompanyInfo.GetPartyID, 'Wrong PartyID generated.');
    end;

    local procedure VerifyXMLDeclarationHeader()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        VerifyNodeHasChildren('Declaration');

        LibraryXMLRead.VerifyNodeValue('referencePeriod', Format(WorkDate, 0, '<Year4>-<Month,2>'));
        LibraryXMLRead.VerifyNodeValue('PSIId', CompanyInfo.GetPartyID);

        VerifyNodeHasChildren('Function');
        LibraryXMLRead.VerifyNodeValue('functionCode', 'O');

        LibraryXMLRead.VerifyNodeValue('declarationTypeCode', '1');
        LibraryXMLRead.VerifyNodeValue('flowCode', 'D');
        LibraryXMLRead.VerifyNodeValue('currencyCode', 'EUR');
    end;

    local procedure VerifyXMLFileHeader()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        LibraryXMLRead.VerifyXMLDeclaration('1.0', 'UTF-8', '');

        VerifyNodeHasChildren('INSTAT');
        VerifyNodeHasChildren('Envelope');
        LibraryXMLRead.VerifyNodeValue('envelopeId', CompanyInfo.CISD);

        VerifyNodeHasChildren('DateTime');
        VerifyDateTimeStructure;

        VerifyNodeHasChildren('Party');
        LibraryXMLRead.VerifyNodeValue('partyId', CompanyInfo.GetPartyID);
        LibraryXMLRead.VerifyAttributeValue('Party', 'partyType', 'PSI');
        LibraryXMLRead.VerifyAttributeValue('Party', 'partyRole', 'sender');
        LibraryXMLRead.VerifyNodeValue('partyName', CompanyInfo.Name);

        LibraryXMLRead.VerifyNodeValue('softwareUsed', 'DynamicsNAV');
    end;

    local procedure VerifyXMLItemContent(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        VerifyNodeHasChildren('Item');
        LibraryXMLRead.VerifyNodeValue('itemNumber', Format(1, 0, '<Integer,6><Filler Character,0>'));
        LibraryXMLRead.VerifyNodeValue('invoicedAmount', Format(Round(IntrastatJnlLine."Statistical Value", 1), 0, 9));
        LibraryXMLRead.VerifyNodeValue('statisticalProcedureCode', Format(IntrastatJnlLine."Transaction Specification", 0, 9));
        LibraryXMLRead.VerifyNodeValue('MSConsDestCode', IntrastatJnlLine."Entry/Exit Point");
        LibraryXMLRead.VerifyNodeValue('regionCode', IntrastatJnlLine.Area);
    end;

    local procedure VerifyObligationLevelIsSetOnReqPage(var ExportDEBDTI: TestRequestPage "Export DEB DTI"; ExpectedValue: Integer)
    begin
        ExportDEBDTI."Obligation Level".SetValue(ExpectedValue);
        Assert.AreEqual(ExpectedValue, ExportDEBDTI."Obligation Level".AsInteger, 'Allowed Obligation Level is in range 1..4.')
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VerifyVisibleObligationLivelIs1(var ExportDEBDTI: TestRequestPage "Export DEB DTI")
    begin
        Assert.IsTrue(ExportDEBDTI."Obligation Level".Visible, 'Obligation Level control should be visible.');
        Assert.AreEqual(1, ExportDEBDTI."Obligation Level".AsInteger, 'Wrong default Obligation Level value.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VerifyObligationLevelAllowedIn1to4(var ExportDEBDTI: TestRequestPage "Export DEB DTI")
    var
        ObligationLevel: Integer;
    begin
        for ObligationLevel := 0 to 5 do
            if ObligationLevel in [1 .. 4] then
                VerifyObligationLevelIsSetOnReqPage(ExportDEBDTI, ObligationLevel)
            // else
            //    asserterror VerifyObligationLevelIsSetOnReqPage(ExportDEBDTI, ObligationLevel);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SuccessMsgHandler(ActualMessage: Text[1024])
    begin
        Assert.AreEqual(Format(PostingMessage), ActualMessage, 'Unexpected success message.');
    end;
}

