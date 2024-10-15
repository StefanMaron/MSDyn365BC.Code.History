codeunit 142086 "Intrastat XML Export DACH"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat] [XML] [Export] [Local]
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        FormatTypeGlb: Option ASCII,XML;
        ExportTypeGlb: Option Receipt,Shipment;
        FileDoesntExistErr: Label 'Specified file ''%1'' doesn''t exist.';

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_Initialize_MandatoryFields()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".Initialize() checks for a Company Information mandatory fields
        Initialize;
        with CompanyInformation do begin
            Init;
            Modify;
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo("Registration No."));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo(Area));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo("Agency No."));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo("Company No."));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo(Address));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo("Post Code"));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo(City));
            VerifyCompInfMandatoryField(CompanyInformation, FieldNo("Country/Region Code"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_Initialize_IntrastatContactTypeMandatory()
    var
        IntrastatSetup: Record "Intrastat Setup";
        Contact: Record Contact;
        Vendor: Record Vendor;
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".Initialize() checks for a Intrastat Contact Type mandatory field
        Initialize;
        with IntrastatSetup do begin
            Get;
            Validate("Intrastat Contact Type", "Intrastat Contact Type"::" ");
            Modify(true);

            // Blanked Contact Type
            asserterror IntrastatExportMgtDACH.Initialize(CurrentDateTime);
            Assert.ExpectedErrorCode('TestField');
            Assert.ExpectedError(FieldName("Intrastat Contact Type"));

            Validate("Intrastat Contact Type", "Intrastat Contact Type"::Contact);
            Modify(true);

            // Blanket Contact No. (Type = Contact)
            asserterror IntrastatExportMgtDACH.Initialize(CurrentDateTime);
            Assert.ExpectedErrorCode('DB:RecordNotFound');
            Assert.ExpectedError(Contact.TableCaption);

            Validate("Intrastat Contact Type", "Intrastat Contact Type"::Vendor);
            Modify(true);

            // Blanket Contact No. (Type = Vendor)
            asserterror IntrastatExportMgtDACH.Initialize(CurrentDateTime);
            Assert.ExpectedErrorCode('DB:RecordNotFound');
            Assert.ExpectedError(Vendor.TableCaption);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_Initialize_IntrastatContactMandatoryFields()
    var
        IntrastatSetup: Record "Intrastat Setup";
        Contact: Record Contact;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".Initialize() checks for a Intrastat Contact mandatory fields
        Initialize;
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Name := '';
        Contact.Modify();

        LibraryERM.SetIntrastatContact(IntrastatSetup."Intrastat Contact Type"::Contact, Contact."No.");
        Commit();

        with Contact do begin
            VerifyIntrastatContactMandatoryField(Contact, FieldNo(Name));
            VerifyIntrastatContactMandatoryField(Contact, FieldNo(Address));
            VerifyIntrastatContactMandatoryField(Contact, FieldNo("Post Code"));
            VerifyIntrastatContactMandatoryField(Contact, FieldNo(City));
            VerifyIntrastatContactMandatoryField(Contact, FieldNo("Country/Region Code"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_Initialize_IntrastatVendorMandatoryFields()
    var
        IntrastatSetup: Record "Intrastat Setup";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".Initialize() checks for a Intrastat Vendor mandatory fields
        Initialize;
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := '';
        Vendor.Modify();

        LibraryERM.SetIntrastatContact(IntrastatSetup."Intrastat Contact Type"::Vendor, Vendor."No.");
        Commit();

        with Vendor do begin
            VerifyIntrastatVendorMandatoryField(Vendor, FieldNo(Name));
            VerifyIntrastatVendorMandatoryField(Vendor, FieldNo(Address));
            VerifyIntrastatVendorMandatoryField(Vendor, FieldNo("Post Code"));
            VerifyIntrastatVendorMandatoryField(Vendor, FieldNo(City));
            VerifyIntrastatVendorMandatoryField(Vendor, FieldNo("Country/Region Code"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_SaveAndCloseFile_ASCII()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        File: File;
        XMLDocument: DotNet XmlDocument;
        ASCIIFileBodyText: Text;
        ReadValue: Text;
        ServerFileName: Text;
        EndOfFile: Text;
    begin
        // [FEATURE] [UT] [ASCII]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".SaveAndCloseFile() in case of "Format Type" = "ASCII"
        ASCIIFileBodyText := LibraryUtility.GenerateRandomXMLText(LibraryRandom.RandIntInRange(1000, 2000));

        IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileName, FormatTypeGlb::ASCII);

        File.TextMode(true);
        File.Open(ServerFileName);
        File.Read(ReadValue);
        File.Close;

        EndOfFile[1] := 26;
        ASCIIFileBodyText += EndOfFile;
        Assert.AreEqual(ASCIIFileBodyText, ReadValue, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_SaveAndCloseFile_XML()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLDocument: array[2] of DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        DummyASCIIFileBodyText: Text;
        ServerFileName: Text;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".SaveAndCloseFile() in case of "Format Type" = "XML"
        Initialize;
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument[1], XMLNode, false, StartDate);

        IntrastatExportMgtDACH.SaveAndCloseFile(DummyASCIIFileBodyText, XMLDocument[1], ServerFileName, FormatTypeGlb::XML);
        XMLDOMMgt.LoadXMLDocumentFromFile(ServerFileName, XMLDocument[2]);

        Assert.AreEqual(XMLDocument[1].OuterXml, XMLDocument[2].OuterXml, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLHeader()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLHeader() in case of "Test Submission" = FALSE
        Initialize;
        CompanyInformation.Get();
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, XMLNode, false, StartDate);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLHeader(VATIDNo, CompanyInformation.Name, CompanyInformation."Company No.");
        VerifyXMLHeaderTimeDependentValues(MessageID, CreationDate, CreationTime);
        LibraryXPathXMLReader.VerifyNodeAbsence('/INSTAT/Envelope/testIndicator');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLHeader_TestSubmission()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLHeader() in case of "Test Submission" = TRUE
        Initialize;
        CompanyInformation.Get();
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, true);

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, XMLNode, true, StartDate);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLHeader(VATIDNo, CompanyInformation.Name, 'XGTEST');
        VerifyXMLHeaderTimeDependentValues(MessageID, CreationDate, CreationTime);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/INSTAT/Envelope/testIndicator', 'true')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLHeader_IntrastatContact()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLHeader() in case of "Intrastat Contact Type" = "Contact"
        Initialize;
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, XMLNode, false, StartDate);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLHeaderIntrastatContact;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLHeader_IntrastatVendor()
    var
        IntrastatSetup: Record "Intrastat Setup";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLHeader() in case of "Intrastat Contact Type" = "Vendor"
        Initialize;
        with IntrastatSetup do
            LibraryERM.SetIntrastatContact(
              "Intrastat Contact Type"::Vendor,
              LibraryERM.CreateIntrastatContact("Intrastat Contact Type"::Vendor));
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, XMLNode, false, StartDate);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLHeaderIntrastatVendor;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLDeclaration_Receipt()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
        Currencycode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLDeclaration() in case of Receipt
        Initialize;
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        Currencycode := LibraryUtility.GenerateGUID;

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, Currencycode);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLDeclaration('/INSTAT/Envelope/', StartDate, VATIDNo, 'A', Currencycode, 0);
        VerifyXMLDeclarationTimeDependentValues('/INSTAT/Envelope/', MessageID, CreationDate, CreationTime, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLDeclaration_Shipment()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
        Currencycode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLDeclaration() in case of Shipment
        Initialize;
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        Currencycode := LibraryUtility.GenerateGUID;

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Shipment, Currencycode);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLDeclaration('/INSTAT/Envelope/', StartDate, VATIDNo, 'D', Currencycode, 0);
        VerifyXMLDeclarationTimeDependentValues('/INSTAT/Envelope/', MessageID, CreationDate, CreationTime, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLDeclaration_Both()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
        Currencycode: array[2] of Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLDeclaration() in case of Receipt and Shipment
        Initialize;
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        Currencycode[1] := LibraryUtility.GenerateGUID;
        Currencycode[2] := LibraryUtility.GenerateGUID;

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, Currencycode[1]);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Shipment, Currencycode[2]);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLDeclaration('/INSTAT/Envelope/', StartDate, VATIDNo, 'A', Currencycode[1], 0);
        VerifyXMLDeclarationTimeDependentValues('/INSTAT/Envelope/', MessageID, CreationDate, CreationTime, 0);
        VerifyXMLDeclaration('/INSTAT/Envelope/', StartDate, VATIDNo, 'D', Currencycode[2], 1);
        VerifyXMLDeclarationTimeDependentValues('/INSTAT/Envelope/', MessageID, CreationDate, CreationTime, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLDeclarationTotals()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLDeclarationTotals()
        Initialize;
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine, ExportTypeGlb::Receipt, false);

        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, '');
        IntrastatExportMgtDACH.WriteXMLDeclarationTotals(XMLNode, IntrastatJnlLine);

        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLDeclarationTotals('/INSTAT/Envelope/Declaration/', IntrastatJnlLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_Receipt_Single()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() in case of Receipt with a single item
        Initialize;

        // [GIVEN] Intrastat Journal Line with "Type" = "Receipt", "Supplementary Units" = FALSE, Quantity = 1, "Country/Region of Origin Code" = "DE" (with "Intrastat Code" = "X")
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine, ExportTypeGlb::Receipt, false);

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine, XMLNode);

        // [THEN] "countryOfOriginCode" = "X"
        // [THEN] There is no "quantityInSU" node
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLItemWithOriginCountry('/INSTAT/Envelope/Declaration/', IntrastatJnlLine, 0);
        LibraryXPathXMLReader.VerifyNodeAbsence('/INSTAT/Envelope/Declaration/Item/quantityInSU');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_Receipt_Single_BlankedIntrastatCode()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 258143] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() in case of Receipt with a single item
        // [SCENARIO 258143] and blanked origin country's "Intrastat Code"
        Initialize;

        // [GIVEN] Intrastat Journal Line with "Type" = "Receipt", "Supplementary Units" = FALSE, Quantity = 1, "Country/Region of Origin Code" = "DE" (with "Intrastat Code" = "")
        // [GIVEN] "Partner VAT ID" is not filled in
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine, ExportTypeGlb::Receipt, false);
        ModifyCountryRegionIntrastatCode(IntrastatJnlLine."Country/Region of Origin Code", '');

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine, XMLNode);

        // [THEN] "countryOfOriginCode" = "DE"
        // [THEN] There is no "quantityInSU" node
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLItemWithOriginCountry('/INSTAT/Envelope/Declaration/', IntrastatJnlLine, 0);
        LibraryXPathXMLReader.VerifyNodeAbsence('/INSTAT/Envelope/Declaration/Item/quantityInSU');
        // [THEN] 'Item/partnerId' node is not exported (TFS 380061)
        LibraryXPathXMLReader.VerifyNodeAbsence('/INSTAT/Envelope/Declaration/Item/partnerId');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_Shipment_Single()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() in case of Shipment with a single item
        Initialize;

        // [GIVEN] Intrastat Journal Line with "Type" = "Shipment", "Supplementary Units" = TRUE, Quantity = 1
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine, ExportTypeGlb::Shipment, true);

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Shipment, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine, XMLNode);

        // [THEN] There is no "countryOfOriginCode" node
        // [THEN] "quantityInSU" = 1
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLItemWithSUQty('/INSTAT/Envelope/Declaration/', IntrastatJnlLine, 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
            '/INSTAT/Envelope/Declaration/Item/countryOfOriginCode',
            IntrastatExportMgtDACH.GetOriginCountryCode(IntrastatJnlLine."Country/Region of Origin Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_Receipt_Several()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() in case of Receipt with a several items
        Initialize;

        // [GIVEN] Intrastat Journal Line1 with "Type" = "Receipt", "Supplementary Units" = FALSE, Quantity = 1, "Country/Region of Origin Code" = "DE" (with "Intrastat Code" = "X")
        // [GIVEN] Intrastat Journal Line2 with "Type" = "Receipt", "Supplementary Units" = TRUE, Quantity = 2, "Country/Region of Origin Code" = "AT" (with "Intrastat Code" = "Y")
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine[1], ExportTypeGlb::Receipt, false);
        MockIntrastatJnlLine(IntrastatJnlLine[2], ExportTypeGlb::Receipt, true);

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine[1], XMLNode);
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine[2], XMLNode);

        // [THEN] Item1: "countryOfOriginCode" = "X", no "quantityInSU" node
        // [THEN] Item2: "countryOfOriginCode" = "Y", "quantityInSU" = 2
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLItemWithOriginCountry('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[1], 0);
        VerifyXMLItemWithOriginCountry('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[2], 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/INSTAT/Envelope/Declaration/Item/quantityInSU', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/quantityInSU', FormatDecimal(IntrastatJnlLine[2].Quantity), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_Shipment_Several()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() in case of Shipment with a several items
        Initialize;

        // [GIVEN] Intrastat Journal Line1 with "Type" = "Shipment", "Supplementary Units" = FALSE, Quantity = 1
        // [GIVEN] Intrastat Journal Line2 with "Type" = "Shipment", "Supplementary Units" = TRUE, Quantity = 2
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine[1], ExportTypeGlb::Shipment, false);
        MockIntrastatJnlLine(IntrastatJnlLine[2], ExportTypeGlb::Shipment, true);

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine[1], XMLNode);
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine[2], XMLNode);

        // [THEN] Item1: no "countryOfOriginCode" node, no "quantityInSU" node
        // [THEN] Item2: no "countryOfOriginCode" node, "quantityInSU" = 2
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLItem('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[1], 0);
        VerifyXMLItem('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[2], 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/INSTAT/Envelope/Declaration/Item/quantityInSU', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/quantityInSU', FormatDecimal(IntrastatJnlLine[2].Quantity), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
            '/INSTAT/Envelope/Declaration/Item/countryOfOriginCode',
            IntrastatExportMgtDACH.GetOriginCountryCode(IntrastatJnlLine[1]."Country/Region of Origin Code"), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
            '/INSTAT/Envelope/Declaration/Item/countryOfOriginCode',
            IntrastatExportMgtDACH.GetOriginCountryCode(IntrastatJnlLine[2]."Country/Region of Origin Code"), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_Both()
    var
        IntrastatJnlLine: array[2] of Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255730] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() in case of Receipt and Shipment
        Initialize;

        // [GIVEN] Intrastat Journal Line1 with "Type" = "Receipt", "Supplementary Units" = FALSE, Quantity = 1, "Country/Region of Origin Code" = "DE" (with "Intrastat Code" = "X")
        // [GIVEN] Intrastat Journal Line2 with "Type" = "Shipment", "Supplementary Units" = TRUE, Quantity = 2
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine[1], ExportTypeGlb::Receipt, false);
        MockIntrastatJnlLine(IntrastatJnlLine[2], ExportTypeGlb::Shipment, true);

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Receipt, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine[1], XMLNode);
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine[2], XMLNode);

        // [THEN] Item1: "countryOfOriginCode" = "X", no "quantityInSU" node
        // [THEN] Item2: no "countryOfOriginCode" node, "quantityInSU" = 2
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        VerifyXMLItemWithOriginCountry('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[1], 0);
        VerifyXMLItem('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[1], 0);
        VerifyXMLItem('/INSTAT/Envelope/Declaration/', IntrastatJnlLine[2], 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/INSTAT/Envelope/Declaration/Item/countryOfOriginCode', 2);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/INSTAT/Envelope/Declaration/Item/quantityInSU', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/quantityInSU', FormatDecimal(IntrastatJnlLine[2].Quantity), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMgt_WriteXMLItem_PartnerVATID()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        XMLNode: DotNet XmlNode;
        StartDate: Date;
        CreationDate: Date;
        CreationTime: Time;
        MessageID: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 380061] COD 11002 "Intrastat - Export Mgt. DACH".WriteXMLItem() with "Partner VAT ID"
        Initialize();

        // [GIVEN] Intrastat Journal Line1 with "Type" = "Shipment", Partner VAT ID = "DE444555666777"
        PrepareXMLExport(IntrastatExportMgtDACH, StartDate, CreationDate, CreationTime, MessageID, VATIDNo, false);
        MockIntrastatJnlLine(IntrastatJnlLine, ExportTypeGlb::Shipment, false);
        IntrastatJnlLine."Partner VAT ID" := LibraryUtility.GenerateGUID();
        IntrastatJnlLine.Modify();

        // [WHEN] Export XML
        IntrastatExportMgtDACH.WriteXMLHeader(XMLDocument, RootXMLNode, false, StartDate);
        IntrastatExportMgtDACH.WriteXMLDeclaration(RootXMLNode, XMLNode, ExportTypeGlb::Shipment, '');
        IntrastatExportMgtDACH.WriteXMLItem(IntrastatJnlLine, XMLNode);

        // [THEN] 'Item/partnerId' node is exported with value "DE444555666777"
        LibraryXPathXMLReader.InitializeWithText(XMLDocument.OuterXml, '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/INSTAT/Envelope/Declaration/Item/partnerId', IntrastatJnlLine."Partner VAT ID");
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure Report_ASCII_BatchReportedIsTrue()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [Report] [ASCII]
        // [SCENARIO 255730] "Intrastat Journal Batch"."Reported" = TRUE after run REP 11014 "Intrastat - Disk Tax Auth DE" in case of "Format Type" = "ASCII", "Test Submission" = FALSE
        Initialize;

        // [GIVEN] A new Intrastat Journal Batch "X"
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);

        // [WHEN] Run REP 11014 "Intrastat - Disk Tax Auth DE" using "Format Type" = "ASCII", "Test Submission" = FALSE
        RunReport(IntrastatJnlBatch, FormatTypeGlb::ASCII, false);

        // [THEN] Batch "X"."Reported" = TRUE
        VerifyBatchReported(IntrastatJnlBatch, true);
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure Report_ASCII_BatchReportedIsFalse()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [Report] [ASCII]
        // [SCENARIO 255730] "Intrastat Journal Batch"."Reported" = FALSE after run REP 11014 "Intrastat - Disk Tax Auth DE" in case of "Format Type" = "ASCII", "Test Submission" = TRUE
        Initialize;

        // [GIVEN] A new Intrastat Journal Batch "X"
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);

        // [WHEN] Run REP 11014 "Intrastat - Disk Tax Auth DE" using "Format Type" = "ASCII", "Test Submission" = TRUE
        RunReport(IntrastatJnlBatch, FormatTypeGlb::ASCII, true);

        // [THEN] Batch "X"."Reported" = FALSE
        VerifyBatchReported(IntrastatJnlBatch, false);
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure Report_XML_BatchReportedIsTrue()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 255730] "Intrastat Journal Batch"."Reported" = TRUE after run REP 11014 "Intrastat - Disk Tax Auth DE" in case of "Format Type" = "XML", "Test Submission" = FALSE
        Initialize;

        // [GIVEN] A new Intrastat Journal Batch "X"
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);

        // [WHEN] Run REP 11014 "Intrastat - Disk Tax Auth DE" using "Format Type" = "XML", "Test Submission" = FALSE
        RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, false);

        // [THEN] Batch "X"."Reported" = TRUE
        VerifyBatchReported(IntrastatJnlBatch, true);
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure Report_XML_BatchReportedIsFalse()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 255730] "Intrastat Journal Batch"."Reported" = TRUE after run REP 11014 "Intrastat - Disk Tax Auth DE" in case of "Format Type" = "XML", "Test Submission" = TRUE
        Initialize;

        // [GIVEN] A new Intrastat Journal Batch "X"
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);

        // [WHEN] Run REP 11014 "Intrastat - Disk Tax Auth DE" using "Format Type" = "XML", "Test Submission" = TRUE
        RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, true);

        // [THEN] Batch "X"."Reported" = FALSE
        VerifyBatchReported(IntrastatJnlBatch, false);
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure Report_XML_BasicScenario()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        DummyIntrastatJnlLineSpec: array[4] of Record "Intrastat Jnl. Line";
        CompanyInformation: Record "Company Information";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text;
        VATIDNo: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 255730] REP 11014 "Intrastat - Disk Tax Auth DE" in case of "Format Type" = "XML", "Test Submission" = FALSE, several item specifications with Receipts, Shipments
        Initialize;
        CompanyInformation.Get();
        VATIDNo := GetVATIDNo;

        // [GIVEN] Several item specifications "S1".."S4"
        // [GIVEN] Intrastat Journal with 8 lines: 2 Shipment lines per each item specification "S1","S2" and 2 Receipt lines per each item spec "S3", "S4"
        PrepareIntraJnlForBasicScenario(IntrastatJnlBatch, DummyIntrastatJnlLineSpec);

        // [WHEN] Run REP 11014 "Intrastat - Disk Tax Auth DE" using "Format Type" = "XML"
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, FALSE);

        // [THEN] XML has been exported with two Declarations: Receipt (items spec "S1", "S2"), Shipment (items spec "S3", "S4")
        ExtractXMLFromZipFile(ZipFileName, TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        VerifyXMLHeader(VATIDNo, CompanyInformation.Name, CompanyInformation."Company No.");
        LibraryXPathXMLReader.VerifyNodeAbsence('/INSTAT/Envelope/testIndicator');
        VerifyXMLDeclaration(
          '/INSTAT/Envelope/', IntrastatJnlBatch.GetStatisticsStartDate, VATIDNo, 'A', IntrastatJnlBatch."Currency Identifier", 0);
        VerifyXMLDeclaration(
          '/INSTAT/Envelope/', IntrastatJnlBatch.GetStatisticsStartDate, VATIDNo, 'D', IntrastatJnlBatch."Currency Identifier", 1);
        VerifyXMLItemWithSUQtyAndOriginCountry('/INSTAT/Envelope/Declaration/', DummyIntrastatJnlLineSpec[1], 0);
        VerifyXMLItemWithSUQtyAndOriginCountry('/INSTAT/Envelope/Declaration/', DummyIntrastatJnlLineSpec[2], 1);
        VerifyXMLItemWithSUQty('/INSTAT/Envelope/Declaration/', DummyIntrastatJnlLineSpec[3], 2);
        VerifyXMLItemWithSUQty('/INSTAT/Envelope/Declaration/', DummyIntrastatJnlLineSpec[4], 3);
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure ReportXMLIntrastatDE_StatisticalValue()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 331036] REP 11014 "Intrastat - Disk Tax Auth DE" in case of "Format Type" = "XML", Amount = 0, Statistical Value entered manually
        Initialize;

        // [GIVEN] Intrastat Journal Line with no item, Amount = 0, Statistical Value = 100
        MockIntrastatJnlLine(IntrastatJnlLine, 0, false);
        IntrastatJnlLine."Item No." := '';
        IntrastatJnlLine.Amount := 0;
        IntrastatJnlLine."Statistical Value" := LibraryRandom.RandDecInRange(1000, 2000, 2);
        IntrastatJnlLine.Modify();
        IntrastatJnlBatch.Get(IntrastatJnlLine."Journal Template Name", IntrastatJnlLine."Journal Batch Name");

        // [WHEN] Run REP 11014 "Intrastat - Disk Tax Auth DE" using "Format Type" = "XML"
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, FALSE);

        // [THEN] XML has been exported with Amount = 0, Statistical Value = 100
        ExtractXMLFromZipFile(ZipFileName, TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        IntrastatJnlLine.Find;
        VerifyXMLItem('/INSTAT/Envelope/Declaration/', IntrastatJnlLine, 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/INSTAT/Envelope/Declaration/Item/invoicedAmount', FormatDecimal(IntrastatJnlLine.Amount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/INSTAT/Envelope/Declaration/Item/statisticalValue', FormatDecimal(IntrastatJnlLine."Statistical Value"));
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileForASCIIWithFilledAuthorizedNo()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        DestinationFilePath: Text;
    begin
        // [SCENARIO 327393] Codeunit 11002 "Intrastat - Export Mgt. DACH".DownloadFile() copies ASCII file when Sales Authorized No and Purch. Authorized No fileds are filled in Company Information.
        Initialize;

        // [GIVEN] Company Information with <not blank> "Sales Authorized No." and "Purch. Authorized No.".
        CompanyInformation.Get();
        CompanyInformation.Validate("Sales Authorized No.", LibraryUtility.GenerateRandomAlphabeticText(8, 0));
        CompanyInformation.Validate("Purch. Authorized No.", LibraryUtility.GenerateRandomAlphabeticText(8, 0));
        CompanyInformation.Modify(true);

        // [GIVEN] Two files and path for destination file.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, DestinationFilePath);

        // [WHEN] Invoke DownloadFile() with format type is ASCII.
        IntrastatExportMgtDACH.DownloadFile(DestinationFilePath, ServerFileReceiptsPath, ServerFileShipmentsPath, FormatTypeGlb::ASCII, '');

        // [THEN] Files are archived and copied to the destination file.
        Assert.IsTrue(File.Exists(DestinationFilePath), StrSubstNo(FileDoesntExistErr, DestinationFilePath));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileForASCIIWithBlankSalesAuthorizedNo()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        DestinationFilePath: Text;
    begin
        // [SCENARIO 327393] Codeunit 11002 "Intrastat - Export Mgt. DACH".DownloadFile() prints error when format type is ASCII and Sales Authorized No is not filled in Company Information.
        Initialize;

        // [GIVEN] Company Information with <blank> "Sales Authorized No.".
        CompanyInformation.Get();
        CompanyInformation.Validate("Sales Authorized No.", '');
        CompanyInformation.Modify(true);

        // [GIVEN] Two files and path for destination file.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, DestinationFilePath);

        // [WHEN] Invoke DownloadFile() with format type is ASCII.
        asserterror IntrastatExportMgtDACH.DownloadFile(
            DestinationFilePath, ServerFileReceiptsPath, ServerFileShipmentsPath, FormatTypeGlb::ASCII, '');

        // [THEN] Testfield is failed with error "Sales Authorized No. must have a value in Company Information: Primary Key=. It cannot be zero or empty.".
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(CompanyInformation.FieldName("Sales Authorized No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileForASCIIWithBlankPurchaseAuthorizedNo()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        DestinationFilePath: Text;
    begin
        // [SCENARIO 327393] Codeunit 11002 "Intrastat - Export Mgt. DACH".DownloadFile() prints error when format type is ASCII and Purchase Authorized No is not filled in Company Information.
        Initialize;

        // [GIVEN] Company Information with <not blank> "Sales Authorized No." and <blank> "Purch. Authorized No".
        CompanyInformation.Get();
        CompanyInformation.Validate("Sales Authorized No.", LibraryUtility.GenerateRandomAlphabeticText(8, 0));
        CompanyInformation.Validate("Purch. Authorized No.", '');
        CompanyInformation.Modify(true);

        // [GIVEN] Two files and path for destination file.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, DestinationFilePath);

        // [WHEN] Invoke DownloadFile() with format type is ASCII.
        asserterror IntrastatExportMgtDACH.DownloadFile(
            DestinationFilePath, ServerFileReceiptsPath, ServerFileShipmentsPath, FormatTypeGlb::ASCII, '');

        // [THEN] Testfield is failed with error "Purch. Authorized No. must have a value in Company Information: Primary Key=. It cannot be zero or empty.".
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(CompanyInformation.FieldName("Purch. Authorized No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileForXMLWithBlankSalesAuthorizedNo()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        DestinationFilePath: Text;
    begin
        // [SCENARIO 327393] Codeunit 11002 "Intrastat - Export Mgt. DACH".DownloadFile() copies XML file when Sales Authorized No is not filled in Company Information.
        Initialize;

        // [GIVEN] Company Information with <blank> "Sales Authorized No.".
        CompanyInformation.Get();
        CompanyInformation.Validate("Sales Authorized No.", '');
        CompanyInformation.Validate("Purch. Authorized No.");
        CompanyInformation.Modify(true);

        // [GIVEN] Source file and path for destination file.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, DestinationFilePath);

        // [WHEN] Invoke DownloadFile() with format type is XML.
        IntrastatExportMgtDACH.DownloadFile(DestinationFilePath, '', ServerFileShipmentsPath, FormatTypeGlb::XML, '');

        // [THEN] Source file is archived and copied to the destination file.
        Assert.IsTrue(File.Exists(DestinationFilePath), StrSubstNo(FileDoesntExistErr, DestinationFilePath));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileForXMLWithBlankPurchaseAuthorizedNo()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        DestinationFilePath: Text;
    begin
        // [SCENARIO 327393] Codeunit 11002 "Intrastat - Export Mgt. DACH".DownloadFile() copies XML file when Purchase Authorized No is not filled in Company Information.
        Initialize;

        // [GIVEN] Company Information with <not blank> "Sales Authorized No." and <blank> "Purch. Authorized No.".
        CompanyInformation.Get();
        CompanyInformation.Validate("Sales Authorized No.", LibraryUtility.GenerateRandomAlphabeticText(8, 0));
        CompanyInformation.Validate("Purch. Authorized No.", '');
        CompanyInformation.Modify(true);

        // [GIVEN] Source file and path for destination file.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, DestinationFilePath);

        // [WHEN] Invoke DownloadFile() with format type is XML.
        IntrastatExportMgtDACH.DownloadFile(DestinationFilePath, '', ServerFileShipmentsPath, FormatTypeGlb::XML, '');

        // [THEN] Source file is archived and copied to the destination file.
        Assert.IsTrue(File.Exists(DestinationFilePath), StrSubstNo(FileDoesntExistErr, DestinationFilePath));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileForXMLWithBlankAuthorizedNo()
    var
        CompanyInformation: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        DestinationFilePath: Text;
    begin
        // [SCENARIO 327393] Codeunit 11002 "Intrastat - Export Mgt. DACH".DownloadFile() copies XML file when Sales Authorized No and Purchase Authorized No are not filled in Company Information.
        Initialize;

        // [GIVEN] Company Information with <blank> "Sales Authorized No." and "Purch. Authorized No.".
        CompanyInformation.Get();
        CompanyInformation.Validate("Sales Authorized No.", '');
        CompanyInformation.Validate("Purch. Authorized No.", '');
        CompanyInformation.Modify(true);

        // [GIVEN] Source file and path for destination file.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, DestinationFilePath);

        // [WHEN] Invoke DownloadFile() with format type is XML.
        IntrastatExportMgtDACH.DownloadFile(DestinationFilePath, '', ServerFileShipmentsPath, FormatTypeGlb::XML, '');

        // [THEN] Source file is archived and copied to the destination file.
        Assert.IsTrue(File.Exists(DestinationFilePath), StrSubstNo(FileDoesntExistErr, DestinationFilePath));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileASCIIShipmentsOnly()
    var
        CompanyInfo: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        ZipFilePath: Text;
        FileList: List of [Text];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333492] Run function DownloadFile of IntrastatExportMgtDACH codeunit in case Receipt ACSII file is not found.
        Initialize;
        CompanyInfo.Get();

        // [GIVEN] Mock files for zipping.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, ZipFilePath);

        // [WHEN] Run DownloadFile function of IntrastatExportMgtDACH codeunit for ASCII type in case path for Receipts file is empty.
        IntrastatExportMgtDACH.DownloadFile(ZipFilePath, '', ServerFileShipmentsPath, FormatTypeGlb::ASCII, '');

        // [THEN] DownloadFile function creates a zip file, that contains only one ASCII file for Shipments.
        GetFileListFromZipFile(ZipFilePath, FileList);
        Assert.AreEqual(1, FileList.Count(), '');
        Assert.ExpectedMessage(StrSubstNo('%1.ASC', CompanyInfo."Sales Authorized No."), FileList.Get(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileASCIIReceiptsOnly()
    var
        CompanyInfo: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        ServerFileReceiptsPath: Text;
        ServerFileShipmentsPath: Text;
        ZipFilePath: Text;
        FileList: List of [Text];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333492] Run function DownloadFile of IntrastatExportMgtDACH codeunit in case Shipments ACSII file is not found.
        Initialize;
        CompanyInfo.Get();

        // [GIVEN] Mock files for zipping.
        CreateServerFiles(ServerFileReceiptsPath, ServerFileShipmentsPath, ZipFilePath);

        // [WHEN] Run DownloadFile function of IntrastatExportMgtDACH codeunit for ASCII type in case path for Shipments file is empty.
        IntrastatExportMgtDACH.DownloadFile(ZipFilePath, ServerFileReceiptsPath, '', FormatTypeGlb::ASCII, '');

        // [THEN] DownloadFile function creates a zip file, that contains only one ASCII file for Receipts.
        GetFileListFromZipFile(ZipFilePath, FileList);
        Assert.AreEqual(1, FileList.Count(), '');
        Assert.ExpectedMessage(StrSubstNo('%1.ASC', CompanyInfo."Purch. Authorized No."), FileList.Get(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadFileXMLWhenShipmentsFileNotFound()
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        FileManagement: Codeunit "File Management";
        ZipFilePath: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333492] Run function DownloadFile of IntrastatExportMgtDACH codeunit in case Shipments XML file is not found.
        Initialize;

        // [WHEN] Run DownloadFile function of IntrastatExportMgtDACH codeunit for XML type in case path for Shipments file is empty.
        ZipFilePath := FileManagement.ServerTempFileName('');
        IntrastatExportMgtDACH.DownloadFile(ZipFilePath, '', '', FormatTypeGlb::XML, '');

        // [THEN] DownloadFile function does not create a zip file, because there is nothing to archive.
        Assert.IsFalse(File.Exists(ZipFilePath), '');
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEAsciiWhenReceiptsAndShipmentsAreSet()
    var
        CompanyInfo: Record "Company Information";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ZipFileName: Text;
        FileList: List of [Text];
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with ASCII format in case "Report Receipts"/"Report Shipments" are set.
        Initialize;
        CompanyInfo.Get();

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" and "Report Shipments" of Intrastat Setup are set.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format ASCII.
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::ASCII, false);

        // [THEN] Zip arhive is created, it contains two ASCII files, one for Receipts, one for Shipments.
        GetFileListFromZipFile(ZipFileName, FileList);
        Assert.AreEqual(2, FileList.Count(), '');
        Assert.ExpectedMessage(StrSubstNo('%1.ASC', CompanyInfo."Purch. Authorized No."), FileList.Get(1));
        Assert.ExpectedMessage(StrSubstNo('%1.ASC', CompanyInfo."Sales Authorized No."), FileList.Get(2));


        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEAsciiWhenReceiptsAndShipmentsAreNotSet()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with ASCII format in case "Report Receipts"/"Report Shipments" are not set.
        Initialize;

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" and "Report Shipments" of Intrastat Setup are not set.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        UpdateReceiptsShipmentsOnIntrastatSetup(false, false);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format ASCII.
        asserterror RunReport(IntrastatJnlBatch, FormatTypeGlb::ASCII, false);

        // [THEN] Error "There are no values to report as per Intrastat Setup" is thrown.
        Assert.ExpectedError('You must select the Report Receipts and Report Shipments check boxes on the Intrastat Setup page.');
        Assert.ExpectedErrorCode('Dialog');

        // Tear down
        LibraryVariableStorage.DequeueInteger;
        LibraryVariableStorage.DequeueBoolean;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEAsciiWhenReceiptsIsSet()
    var
        CompanyInfo: Record "Company Information";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ZipFileName: Text;
        FileList: List of [Text];
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with ASCII format in case "Report Receipts" is set, "Report Shipments" is not set.
        Initialize;
        CompanyInfo.Get();

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" is set, "Report Shipments" is not set in Intrastat Setup.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        UpdateReceiptsShipmentsOnIntrastatSetup(true, false);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format ASCII.
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::ASCII, false);

        // [THEN] Zip arhive is created, it contains only one ASCII file for Receipts.
        GetFileListFromZipFile(ZipFileName, FileList);
        Assert.AreEqual(1, FileList.Count(), '');
        Assert.ExpectedMessage(StrSubstNo('%1.ASC', CompanyInfo."Purch. Authorized No."), FileList.Get(1));

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEAsciiWhenShipmentsIsSet()
    var
        CompanyInfo: Record "Company Information";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        ZipFileName: Text;
        FileList: List of [Text];
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with ASCII format in case "Report Receipts" is not set, "Report Shipments" is set.
        Initialize;
        CompanyInfo.Get();

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" is not set, "Report Shipments" is set in Intrastat Setup.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        UpdateReceiptsShipmentsOnIntrastatSetup(false, true);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format ASCII.
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::ASCII, false);

        // [THEN] Zip arhive is created, it contains only one ASCII file for Shipments.
        GetFileListFromZipFile(ZipFileName, FileList);
        Assert.AreEqual(1, FileList.Count(), '');
        Assert.ExpectedMessage(StrSubstNo('%1.ASC', CompanyInfo."Sales Authorized No."), FileList.Get(1));

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEXmlWhenReceiptsAndShipmentsAreSet()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text;
        ItemDescription: List of [Text[100]];
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with XML format in case "Report Receipts"/"Report Shipments" are set.
        Initialize;

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" and "Report Shipments" of Intrastat Setup are set.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        FindIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch.Name, IntrastatJnlLine.Type::Receipt);
        ItemDescription.Add(IntrastatJnlLine."Item Description");
        FindIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch.Name, IntrastatJnlLine.Type::Shipment);
        ItemDescription.Add(IntrastatJnlLine."Item Description");
        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format XML.
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, false);

        // [THEN] Zip arhive is created, it contains XML file with sections for Receipts and Shipments.
        ExtractXMLFromZipFile(ZipFileName, TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item', 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Declaration/Item/goodsDescription', ItemDescription.Get(1), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//Declaration/Item/goodsDescription', ItemDescription.Get(2), 1);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEXmlWhenReceiptsIsSet()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text;
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with XML format in case "Report Receipts" is set, "Report Shipments" is not set.
        Initialize;

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" is set, "Report Shipments" is not set in Intrastat Setup.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        FindIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch.Name, IntrastatJnlLine.Type::Receipt);
        UpdateReceiptsShipmentsOnIntrastatSetup(true, false);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format XML.
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, false);

        // [THEN] Zip arhive is created, it contains XML file with section for Receipts only.
        ExtractXMLFromZipFile(ZipFileName, TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//Declaration/Item/goodsDescription', IntrastatJnlLine."Item Description");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('IntrastatDiskTaxAuthDE_RPH')]
    [Scope('OnPrem')]
    procedure RunIntrastatDiskTaxAuthDEXmlWhenShipmentsIsSet()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text;
    begin
        // [SCENARIO 333492] Run report "Intrastat - Disk Tax Auth DE" on Receipt and Shipment lines with XML format in case "Report Receipts" is not set, "Report Shipments" is set.
        Initialize;

        // [GIVEN] Two Intrastat Journal Lines with Type Receipt and Shipment.
        // [GIVEN] "Report Receipts" is not set, "Report Shipments" is set in Intrastat Setup.
        CreateReceiptAndShipmentIntrastatJnlLines(IntrastatJnlBatch);
        FindIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch.Name, IntrastatJnlLine.Type::Shipment);
        UpdateReceiptsShipmentsOnIntrastatSetup(false, true);

        // [WHEN] Run report "Intrastat - Disk Tax Auth DE" with format XML.
        ZipFileName := RunReport(IntrastatJnlBatch, FormatTypeGlb::XML, false);

        // [THEN] Zip arhive is created, it contains XML file with section for Shipments only.
        ExtractXMLFromZipFile(ZipFileName, TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//Declaration/Item', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//Declaration/Item/goodsDescription', IntrastatJnlLine."Item Description");

        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;
        IsInitialized := true;

        UpdateCompanyInformation;
        UpdateReceiptsShipmentsOnIntrastatSetup(true, true);
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Intrastat Setup");
        Commit();
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            Validate(Name, LibraryUtility.GenerateGUID);
            Validate("Intrastat Code", CopyStr(LibraryUtility.GenerateRandomXMLText(3), 1, 3));
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure CreateIntrastatJnlBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, LibraryRandom.RandDate(100));
        IntrastatJnlBatch."Currency Identifier" := LibraryUtility.GenerateGUID;
        IntrastatJnlBatch.Modify();
    end;

    local procedure CreateIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var IntrastatJnlLineSpec: Record "Intrastat Jnl. Line"; IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        LibraryERM.CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlBatch."Journal Template Name", IntrastatJnlBatch.Name);
        with IntrastatJnlLine do begin
            Type := IntrastatJnlLineSpec.Type;
            "Item Description" := IntrastatJnlLineSpec."Item Description";
            "Country/Region Code" := IntrastatJnlLineSpec."Country/Region Code";
            "Tariff No." := IntrastatJnlLineSpec."Tariff No.";
            "Transaction Type" := IntrastatJnlLineSpec."Transaction Type";
            "Transport Method" := IntrastatJnlLineSpec."Transport Method";
            Area := IntrastatJnlLineSpec.Area;
            "Transaction Specification" := IntrastatJnlLineSpec."Transaction Specification";
            "Country/Region of Origin Code" := IntrastatJnlLineSpec."Country/Region of Origin Code";
            "Supplementary Units" := IntrastatJnlLineSpec."Supplementary Units";
            "Document No." := IntrastatJnlLineSpec."Document No.";
            Date := IntrastatJnlLineSpec.Date;

            Validate(Quantity, LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));
            Validate("Net Weight", LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));
            Validate(Amount, LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));
            Modify;

            IntrastatJnlLineSpec.Amount += Amount;
            IntrastatJnlLineSpec.Quantity += Quantity;
            IntrastatJnlLineSpec."Statistical Value" += "Statistical Value";
            IntrastatJnlLineSpec."Total Weight" += "Total Weight";
        end;
    end;

    local procedure CreateItemSpecification(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; NewType: Option; SU: Boolean; InternalRefNo: Text)
    begin
        with IntrastatJnlLine do begin
            Init;
            "Internal Ref. No." := CopyStr(InternalRefNo, 1, MaxStrLen("Internal Ref. No."));
            Type := NewType;
            "Item Description" := LibraryUtility.GenerateGUID;
            "Country/Region Code" := CreateCountryRegionCode;
            "Tariff No." := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen("Tariff No.")), 1, 8);
            "Transaction Type" := Format(LibraryRandom.RandIntInRange(10, 99));
            "Transport Method" := LibraryUtility.GenerateGUID;
            Area := LibraryUtility.GenerateGUID;
            "Transaction Specification" := LibraryUtility.GenerateGUID;
            "Country/Region of Origin Code" := CreateCountryRegionCode;
            "Supplementary Units" := SU;
            "Document No." := LibraryUtility.GenerateGUID;
            Date := WorkDate();
        end;
    end;

    local procedure CreateReceiptAndShipmentIntrastatJnlLines(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch");
    VAR
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJnlLineSpec: Record "Intrastat Jnl. Line";
    begin
        CreateIntrastatJnlBatch(IntrastatJnlBatch);
        CreateItemSpecification(IntrastatJnlLineSpec, IntrastatJnlLineSpec.Type::Receipt, false, LibraryUtility.GenerateGUID);
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec, IntrastatJnlBatch);
        CreateItemSpecification(IntrastatJnlLineSpec, IntrastatJnlLineSpec.Type::Shipment, false, LibraryUtility.GenerateGUID);
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec, IntrastatJnlBatch);
    end;

    local procedure CreateServerFiles(var ServerFileReceiptsPath: Text; var ServerFileShipmentsPath: Text; var DestinationFilePath: Text)
    var
        FileManagement: Codeunit "File Management";
        ServerFileReceipts: File;
        ServerFileShipments: File;
    begin
        ServerFileReceiptsPath := FileManagement.ServerTempFileName('');
        ServerFileReceipts.Create(ServerFileReceiptsPath);
        ServerFileReceipts.Close;

        ServerFileShipmentsPath := FileManagement.ServerTempFileName('');
        ServerFileShipments.Create(ServerFileShipmentsPath);
        ServerFileShipments.Close;

        DestinationFilePath := FileManagement.ServerTempFileName('');
    end;

    local procedure ExtractXMLFromZipFile(ZipFileName: Text; var TempBlob: Codeunit "Temp Blob")
    var
        DataCompression: Codeunit "Data Compression";
        ZipFileInStream: InStream;
        EntryFileOutStream: OutStream;
        EntryList: List of [Text];
        EntryLength: Integer;
        ZipFile: File;
    begin
        ZipFile.Open(ZipFileName);
        ZipFile.CreateInStream(ZipFileInStream);
        DataCompression.OpenZipArchive(ZipFileInStream, false);
        DataCompression.GetEntryList(EntryList);
        TempBlob.CreateOutStream(EntryFileOutStream);
        DataCompression.ExtractEntry(EntryList.Get(1), EntryFileOutStream, EntryLength);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
    end;

    local procedure FormatDecimal(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Precision,0><Standard Format,9>'));
    end;

    local procedure FindIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; IntrastatJnlBatchName: Code[10]; LineType: Option);
    BEGIN
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatchName);
        IntrastatJnlLine.SetRange(Type, LineType);
        IntrastatJnlLine.FindFirst();
    END;

    local procedure GetMaterialNumber(TestSubmission: Boolean): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        if TestSubmission then
            exit('XGTEST');

        CompanyInformation.Get();
        exit(CompanyInformation."Company No.");
    end;

    local procedure GetMessageID(MaterialNumber: Text; StartDate: Date; CreationDate: Date; CreationTime: Time): Text
    begin
        exit(
          MaterialNumber + '-' +
          Format(StartDate, 0, '<Year4><Month,2>') + '-' +
          Format(CreationDate, 0, '<Year4><Month,2><Day,2>') + '-' +
          Format(CreationTime, 0, '<Hours2><Minutes>'));
    end;

    local procedure GetCountryName(CountryRegionCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        with CountryRegion do begin
            Get(CountryRegionCode);
            exit(Name);
        end;
    end;

    local procedure GetVATIDNo(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            exit(Format(Area, 2) + Format("Registration No.") + Format("Agency No.", 3));
        end;
    end;

    local procedure GetInternalRefNo(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; Index: Integer): Text
    begin
        exit(IntrastatJnlBatch."Statistics Period" + Format(Index, 0, '<Integer,6><Filler Character,0>'));
    end;

    local procedure GetFileListFromZipFile(ZipFileName: Text; var EntryList: List of [Text])
    var
        DataCompression: Codeunit "Data Compression";
        ZipFileInStream: InStream;
        EntryFileOutStream: OutStream;
        ZipFile: File;
    begin
        ZipFile.Open(ZipFileName);
        ZipFile.CreateInStream(ZipFileInStream);
        DataCompression.OpenZipArchive(ZipFileInStream, false);
        DataCompression.GetEntryList(EntryList);
        DataCompression.CloseZipArchive();
        ZipFile.Close();
    end;

    local procedure MockIntrastatJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; LineType: Option; SU: Boolean)
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLineSpec: Record "Intrastat Jnl. Line";
    begin
        CreateIntrastatJnlBatch(IntrastatJnlBatch);
        CreateItemSpecification(IntrastatJnlLineSpec, LineType, SU, LibraryUtility.GenerateGUID);
        CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec, IntrastatJnlBatch);
        IntrastatJnlLine."Internal Ref. No." := LibraryUtility.GenerateGUID;
        IntrastatJnlLine.Modify();
    end;

    local procedure ModifyCountryRegionIntrastatCode(CountryRegionCode: Code[10]; NewIntrastatCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        with CountryRegion do begin
            Get(CountryRegionCode);
            Validate("Intrastat Code", NewIntrastatCode);
            Modify(true);
        end;
    end;

    local procedure PrepareXMLExport(var IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH"; var StartDate: Date; var CreationDate: Date; var CreationTime: Time; var MessageID: Text; var VATIDNo: Text; TestSubmission: Boolean)
    var
        CreationDateTime: DateTime;
        MaterialNumber: Text;
    begin
        StartDate := LibraryRandom.RandDate(100);
        CreationDateTime := CurrentDateTime;
        IntrastatExportMgtDACH.Initialize(CreationDateTime);
        CreationDate := DT2Date(CreationDateTime);
        CreationTime := DT2Time(CreationDateTime);
        MaterialNumber := GetMaterialNumber(TestSubmission);
        MessageID := GetMessageID(MaterialNumber, StartDate, CreationDate, CreationTime);
        VATIDNo := GetVATIDNo;
    end;

    local procedure PrepareIntraJnlForBasicScenario(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var IntrastatJnlLineSpec: array[4] of Record "Intrastat Jnl. Line")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        i: Integer;
    begin
        CreateIntrastatJnlBatch(IntrastatJnlBatch);

        for i := 1 to 2 do begin
            CreateItemSpecification(
              IntrastatJnlLineSpec[i], IntrastatJnlLine.Type::Receipt, true, GetInternalRefNo(IntrastatJnlBatch, i));
            CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec[i], IntrastatJnlBatch);
            CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec[i], IntrastatJnlBatch);
        end;

        for i := 3 to ArrayLen(IntrastatJnlLineSpec) do begin
            CreateItemSpecification(
              IntrastatJnlLineSpec[i], IntrastatJnlLine.Type::Shipment, true, GetInternalRefNo(IntrastatJnlBatch, i - 2));
            CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec[i], IntrastatJnlBatch);
            CreateIntrastatJnlLine(IntrastatJnlLine, IntrastatJnlLineSpec[i], IntrastatJnlBatch);
        end;
    end;

    local procedure RunReport(IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; FormatType: Option; TestSubmission: Boolean) ZipFileName: Text
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatDiskTaxAuthDE: Report "Intrastat - Disk Tax Auth DE";
        FileMgt: Codeunit "File Management";
    begin
        ZipFileName := FileMgt.ServerTempFileName('zip');
        LibraryVariableStorage.Enqueue(FormatType);
        LibraryVariableStorage.Enqueue(TestSubmission);
        IntrastatJnlLine.SetRange("Journal Template Name", IntrastatJnlBatch."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", IntrastatJnlBatch.Name);

        Commit();
        Clear(IntrastatDiskTaxAuthDE);
        IntrastatDiskTaxAuthDE.InitializeRequest(ZipFileName);
        IntrastatDiskTaxAuthDE.SetTableView(IntrastatJnlLine);
        IntrastatDiskTaxAuthDE.UseRequestPage(true);
        IntrastatDiskTaxAuthDE.RunModal;
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        with CompanyInformation do begin
            Get;
            "Registration No." := '01234567890';
            Area := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(Area)), 1, MaxStrLen(Area));
            "Agency No." := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen("Agency No.")), 1, MaxStrLen("Agency No."));
            "Sales Authorized No." :=
              CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen("Sales Authorized No.")), 1, MaxStrLen("Sales Authorized No."));
            "Purch. Authorized No." :=
              CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen("Purch. Authorized No.")), 1, MaxStrLen("Purch. Authorized No."));
            "Company No." := LibraryUtility.GenerateGUID;
            Address := LibraryUtility.GenerateGUID;
            "Post Code" := LibraryUtility.GenerateGUID;
            City := LibraryUtility.GenerateGUID;
            "Country/Region Code" := CreateCountryRegionCode;
            "Phone No." := LibraryUtility.GenerateGUID;
            "Fax No." := LibraryUtility.GenerateGUID;
            "E-Mail" := LibraryUtility.GenerateGUID;
            Modify;
        end;
        with IntrastatSetup do
            LibraryERM.SetIntrastatContact(
              "Intrastat Contact Type"::Contact,
              LibraryERM.CreateIntrastatContact("Intrastat Contact Type"::Contact));
    end;

    local procedure UpdateReceiptsShipmentsOnIntrastatSetup(ReportReceipts: Boolean; ReportShipments: Boolean)
    var
        IntrastatSetup: Record "Intrastat Setup";
    begin
        IntrastatSetup.Get();
        IntrastatSetup."Report Receipts" := ReportReceipts;
        IntrastatSetup."Report Shipments" := ReportShipments;
        IntrastatSetup.Modify();
    end;

    local procedure VerifyBatchReported(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; ExpectedReportedValue: Boolean)
    begin
        IntrastatJnlBatch.Find;
        IntrastatJnlBatch.TestField(Reported, ExpectedReportedValue);
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure VerifyCompInfMandatoryField(var CompanyInformation: Record "Company Information"; FieldNo: Integer)
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.GetTable(CompanyInformation);
        FieldRef := RecordRef.Field(FieldNo);
        asserterror IntrastatExportMgtDACH.Initialize(CurrentDateTime);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FieldRef.Name);
        FieldRef.Value := CopyStr(LibraryUtility.GenerateRandomXMLText(FieldRef.Length), 1, FieldRef.Length);
        RecordRef.Modify();
        RecordRef.SetTable(CompanyInformation);
    end;

    local procedure VerifyIntrastatContactMandatoryField(var Contact: Record Contact; FieldNo: Integer)
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.GetTable(Contact);
        FieldRef := RecordRef.Field(FieldNo);
        asserterror IntrastatExportMgtDACH.Initialize(CurrentDateTime);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FieldRef.Name);
        FieldRef.Value := CopyStr(LibraryUtility.GenerateRandomXMLText(FieldRef.Length), 1, FieldRef.Length);
        RecordRef.Modify();
        RecordRef.SetTable(Contact);
    end;

    local procedure VerifyIntrastatVendorMandatoryField(var Vendor: Record Vendor; FieldNo: Integer)
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecordRef.GetTable(Vendor);
        FieldRef := RecordRef.Field(FieldNo);
        asserterror IntrastatExportMgtDACH.Initialize(CurrentDateTime);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FieldRef.Name);
        FieldRef.Value := CopyStr(LibraryUtility.GenerateRandomXMLText(FieldRef.Length), 1, FieldRef.Length);
        RecordRef.Modify();
        RecordRef.SetTable(Vendor);
    end;

    local procedure VerifyXMLHeader(SenderPartyID: Text; SenderName: Text; SenderAgreementID: Text)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/INSTAT', 1);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/INSTAT/Envelope', 1);
        VerifyXMLParty('/INSTAT/Envelope/', 'PSI', 'sender', SenderPartyID, SenderName, SenderAgreementID, 0);
        with CompanyInformation do begin
            VerifyXMLAddress('/INSTAT/Envelope/Party/', Address, "Post Code", City, GetCountryName("Country/Region Code"), 0);
            VerifyXMLAddressDetails('/INSTAT/Envelope/Party/', "Phone No.", "Fax No.", "E-Mail", 0);
        end;
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/INSTAT/Envelope/softwareUsed', PRODUCTNAME.Full);
    end;

    local procedure VerifyXMLHeaderTimeDependentValues(MessageID: Text; CreationDate: Date; CreationTime: Time)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/INSTAT/Envelope/envelopeId', MessageID);
        VerifyXMLDateTime('/INSTAT/Envelope/', CreationDate, CreationTime, 0);
    end;

    local procedure VerifyXMLHeaderIntrastatContact()
    var
        IntrastatSetup: Record "Intrastat Setup";
        Contact: Record Contact;
    begin
        IntrastatSetup.Get();
        with Contact do begin
            Get(IntrastatSetup."Intrastat Contact No.");
            VerifyXMLParty('/INSTAT/Envelope/', 'CC', 'receiver', '00', Name, '', 1);
            VerifyXMLAddress('/INSTAT/Envelope/Party/', Address, "Post Code", City, GetCountryName("Country/Region Code"), 1);
            VerifyXMLAddressDetails('/INSTAT/Envelope/Party/', "Phone No.", "Fax No.", "E-Mail", 1);
        end;
    end;

    local procedure VerifyXMLHeaderIntrastatVendor()
    var
        IntrastatSetup: Record "Intrastat Setup";
        Vendor: Record Vendor;
    begin
        IntrastatSetup.Get();
        with Vendor do begin
            Get(IntrastatSetup."Intrastat Contact No.");
            VerifyXMLParty('/INSTAT/Envelope/', 'CC', 'receiver', '00', Name, '', 1);
            VerifyXMLAddress('/INSTAT/Envelope/Party/', Address, "Post Code", City, GetCountryName("Country/Region Code"), 1);
            VerifyXMLAddressDetails('/INSTAT/Envelope/Party/', "Phone No.", "Fax No.", "E-Mail", 1);
        end;
    end;

    local procedure VerifyXMLDeclaration(RootPath: Text; StartDate: Date; VATIDNo: Text; FlowCode: Text; CurrencyCode: Text; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          RootPath + 'Declaration/referencePeriod', Format(StartDate, 0, '<Year4>-<Month,2>'), NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Declaration/PSIId', VATIDNo, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Declaration/flowCode', FlowCode, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Declaration/currencyCode', CurrencyCode, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Declaration/Function/functionCode', 'O', NodeIndex);
    end;

    local procedure VerifyXMLDeclarationTimeDependentValues(RootPath: Text; DeclarationId: Text; CreationDate: Date; CreationTime: Time; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Declaration/declarationId', DeclarationId, NodeIndex);
        VerifyXMLDateTime(RootPath + 'Declaration/', CreationDate, CreationTime, 0);
    end;

    local procedure VerifyXMLDeclarationTotals(RootPath: Text; IntrastatJnlLine: Record "Intrastat Jnl. Line"; NodeIndex: Integer)
    begin
        with IntrastatJnlLine do begin
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'totalNetMass', FormatDecimal("Total Weight"), NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'totalInvoicedAmount', FormatDecimal(Amount), NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
              RootPath + 'totalStatisticalValue', FormatDecimal("Statistical Value"), NodeIndex);
        end;
    end;

    local procedure VerifyXMLItem(RootPath: Text; IntrastatJnlLine: Record "Intrastat Jnl. Line"; NodeIndex: Integer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        with IntrastatJnlLine do begin
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/itemNumber', "Internal Ref. No.", NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/CN8/CN8Code', "Tariff No.", NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/goodsDescription', "Item Description", NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
              RootPath + 'Item/MSConsDestCode', LibraryERM.GetCountryIntrastatCode("Country/Region Code"), NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/netMass', FormatDecimal("Total Weight"), NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/invoicedAmount', FormatDecimal(Amount), NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
              RootPath + 'Item/statisticalValue', FormatDecimal("Statistical Value"), NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/invoiceNumber', "Document No.", NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/modeOfTransportCode', "Transport Method", NodeIndex);
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Item/regionCode', Area, NodeIndex);
            VerifyXMLNatureOfTransaction(RootPath + 'Item/', "Transaction Type", NodeIndex);
        end;
    end;

    local procedure VerifyXMLItemWithSUQty(RootPath: Text; IntrastatJnlLine: Record "Intrastat Jnl. Line"; NodeIndex: Integer)
    begin
        VerifyXMLItem(RootPath, IntrastatJnlLine, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/quantityInSU', FormatDecimal(IntrastatJnlLine.Quantity), NodeIndex);
    end;

    local procedure VerifyXMLItemWithOriginCountry(RootPath: Text; IntrastatJnlLine: Record "Intrastat Jnl. Line"; NodeIndex: Integer)
    var
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
    begin
        VerifyXMLItem(RootPath, IntrastatJnlLine, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/countryOfOriginCode',
          IntrastatExportMgtDACH.GetOriginCountryCode(IntrastatJnlLine."Country/Region of Origin Code"), NodeIndex);
    end;

    local procedure VerifyXMLItemWithSUQtyAndOriginCountry(RootPath: Text; IntrastatJnlLine: Record "Intrastat Jnl. Line"; NodeIndex: Integer)
    begin
        VerifyXMLItem(RootPath, IntrastatJnlLine, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/quantityInSU', FormatDecimal(IntrastatJnlLine.Quantity), NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '/INSTAT/Envelope/Declaration/Item/countryOfOriginCode',
          LibraryERM.GetCountryIntrastatCode(IntrastatJnlLine."Country/Region of Origin Code"), NodeIndex);
    end;

    local procedure VerifyXMLDateTime(RootPath: Text; ExpectedDate: Date; ExpectedTime: Time; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          RootPath + 'DateTime/date', Format(ExpectedDate, 0, '<Year4>-<Month,2>-<Day,2>'), NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          RootPath + 'DateTime/time', Format(ExpectedTime, 0, '<Hours2>:<Minutes>:<Seconds>'), NodeIndex);
    end;

    local procedure VerifyXMLParty(RootPath: Text; PartyType: Text; PartyRole: Text; PartyId: Text; PartyName: Text; InterchangeAgreementId: Text; NodeIndex: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.VerifyNodeCountByXPath(RootPath + 'Party', 2);
        LibraryXPathXMLReader.GetNodeList(RootPath + 'Party', XMLNodeList);
        XMLNode := XMLNodeList.Item(NodeIndex);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, 'partyType', PartyType);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, 'partyRole', PartyRole);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Party/partyId', PartyId, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Party/partyName', PartyName, NodeIndex);
        if InterchangeAgreementId <> '' then
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
              RootPath + 'Party/interchangeAgreementId', InterchangeAgreementId, NodeIndex)
    end;

    local procedure VerifyXMLAddress(RootPath: Text; StreetName: Text; PostalCode: Text; CityName: Text; CountryName: Text; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeCountByXPath(RootPath + 'Address', 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/streetName', StreetName, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/postalCode', PostalCode, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/cityName', CityName, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/countryName', CountryName, NodeIndex);
    end;

    local procedure VerifyXMLAddressDetails(RootPath: Text; PhoneNumber: Text; FaxNumber: Text; EMail: Text; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/phoneNumber', PhoneNumber, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/faxNumber', FaxNumber, NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(RootPath + 'Address/e-mail', EMail, NodeIndex);
    end;

    local procedure VerifyXMLNatureOfTransaction(RootPath: Text; TransactionCode: Text; NodeIndex: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          RootPath + 'NatureOfTransaction/natureOfTransactionACode', Format(TransactionCode[1]), NodeIndex);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          RootPath + 'NatureOfTransaction/natureOfTransactionBCode', Format(TransactionCode[2]), NodeIndex);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatDiskTaxAuthDE_RPH(var IntrastatDiskTaxAuthDE: TestRequestPage "Intrastat - Disk Tax Auth DE")
    begin
        IntrastatDiskTaxAuthDE."Format Type".SetValue(LibraryVariableStorage.DequeueInteger);
        IntrastatDiskTaxAuthDE."Test Submission".SetValue(LibraryVariableStorage.DequeueBoolean);
        IntrastatDiskTaxAuthDE.OK.Invoke;
    end;
}

