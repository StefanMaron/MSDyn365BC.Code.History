codeunit 144085 "Swiss SEPA Direct Debit"
{
    // // [FEATURE] [SEPA] [Direct Debit]

    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        XMLUnknownElementErr: Label 'Unknown element: %1.', Comment = '%1 = xml element name.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        StringConversionMgt: Codeunit StringConversionManagement;
        Initialized: Boolean;
        XmlWrongValueErr: Label 'Wrong value';

    [Test]
    [Scope('OnPrem')]
    procedure IsSEPADDExportForW1Export()
    var
        CHMgt: Codeunit CHMgt;
        DDCollectionNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222118] IsSwissSEPADDExport returns FALSE when "SEPA Direct Debit Exp. Format" is set up with W1 processing codeunit
        DDCollectionNo := CreateMockBankAccWithDDSetup(GetW1ProcCodeunitID);
        Assert.IsFalse(CHMgt.IsSwissSEPADDExport(DDCollectionNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsSEPADDExportForSwissExport()
    var
        CHMgt: Codeunit CHMgt;
        DDCollectionNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222118] IsSwissSEPADDExport returns FALSE when "SEPA Direct Debit Exp. Format" is set up with Swiss processing codeunit
        DDCollectionNo := CreateMockBankAccWithDDSetup(GetSwissProcCodeunitID);
        Assert.IsTrue(CHMgt.IsSwissSEPADDExport(DDCollectionNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSwissDDCollectionCHF()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPADDExportFile: Codeunit "SEPA DD-Export File";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 222118] Export Direct Debit Collection with ch03 xml schema for invoice in local currency
        Initialize;

        // [GIVEN] LCY Currency set to 'CHF' in G/L Setup
        LibraryERM.SetLCYCode('CHF');

        // [GIVEN] Bank Account with Direct Debit Export Setup
        BankAccountNo := CreateBankWithDDSetup;

        // [GIVEN] Local Customer with Posted Sales Invoice in LCY
        CreateCustomerAndPostInvoice(Customer, SEPADirectDebitMandate, CustLedgerEntry);
        CustLedgerEntry.TestField("Currency Code", '');

        // [GIVEN] Direct Debit Collection Entry
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry, BankAccountNo);

        // [WHEN] When run SEPA DD Export File
        SEPADDExportFile.EnableExportToServerFile;
        SEPADDExportFile.Run(DirectDebitCollectionEntry);

        // [THEN] Export completed without errors
        // [THEN] Direct Debit Collection updated with Status "File Created"
        DirectDebitCollection.Find;
        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::"File Created");
        DirectDebitCollectionEntry.Find;
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::"File Created");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSwissDDCollectionVerifyXML()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 222118] Create xml via Export Direct Debit Collection with ch03 xml schema
        Initialize;

        // [GIVEN] LCY Currency set to 'CHF' in G/L Setup
        LibraryERM.SetLCYCode('CHF');

        // [GIVEN] Bank Account with Direct Debit Export Setup
        BankAccountNo := CreateBankWithDDSetup;

        // [GIVEN] Direct Debit Collection Entry for local Customer with Posted Sales Invoice in LCY
        CreateCustomerAndPostInvoice(Customer, SEPADirectDebitMandate, CustLedgerEntry);
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgerEntry, BankAccountNo);

        // [WHEN] Export XML via 'SEPA DD pain.008.001.02.ch03' xml port
        // [THEN] Namespace and tags match to posted data in exported XML
        ExportVerifySepaDDXML(DirectDebitCollectionEntry);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Swiss SEPA Direct Debit");
        LibrarySetupStorage.Restore;
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Swiss SEPA Direct Debit");

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Swiss SEPA Direct Debit");
    end;

    local procedure GetIBAN(): Code[50]
    begin
        exit('CH9581320000001998736');
    end;

    local procedure GetIBANCust(): Code[50]
    begin
        exit('CH0400235235X98765432');
    end;

    local procedure GetSWIFT(): Code[20]
    begin
        exit('MUDABAABC');
    end;

    local procedure GetSWIFTCUst(): Code[20]
    begin
        exit('DKDABAKK');
    end;

    local procedure GetRSPID(): Code[35]
    begin
        exit('41101000000465011');
    end;

    local procedure GetW1ProcCodeunitID(): Integer
    begin
        exit(CODEUNIT::"SEPA DD-Export File");
    end;

    local procedure GetSwissProcCodeunitID(): Integer
    begin
        exit(CODEUNIT::"Swiss SEPA DD-Export File");
    end;

    local procedure CreateBankWithDDSetup(): Code[20]
    begin
        UpdateDDNosOnSalesSetup;
        exit(
          CreateBankAccount(CreateBankExpImpSetup));
    end;

    local procedure CreateBankExpImpSetup(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        with BankExportImportSetup do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            Direction := Direction::Export;
            "Processing Codeunit ID" := GetSwissProcCodeunitID;
            "Processing XMLport ID" := XMLPORT::"SEPA DD pain.008.001.02.ch03";
            "Check Export Codeunit" := CODEUNIT::"SEPA DD-Check Line";
            Insert;
            exit(Code);
        end;
    end;

    local procedure CreateBankAccount(BankExpImpCode: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        with BankAccount do begin
            "SEPA Direct Debit Exp. Format" := BankExpImpCode;
            "Direct Debit Msg. Nos." := LibraryERM.CreateNoSeriesCode;
            IBAN := GetIBAN;
            "SWIFT Code" := GetSWIFT;
            "Creditor No." := GetRSPID;
            Modify;
            exit("No.");
        end;
    end;

    local procedure CreateMockBankAccWithDDSetup(ProcessingCodeunitID: Integer): Integer
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        BankExportImportSetup.Init;
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID;
        BankExportImportSetup."Processing Codeunit ID" := ProcessingCodeunitID;
        BankExportImportSetup.Insert;
        DirectDebitCollection.Init;
        DirectDebitCollection."No." := LibraryUtility.GetNewRecNo(DirectDebitCollection, DirectDebitCollection.FieldNo("No."));
        DirectDebitCollection."To Bank Account No." := CreateBankAccount(BankExportImportSetup.Code);
        DirectDebitCollection.Insert;
        exit(DirectDebitCollection."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.IBAN := GetIBANCust;
        CustomerBankAccount."SWIFT Code" := GetSWIFTCUst;
        CustomerBankAccount.Modify;
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCustomerWithDDMandate(var Customer: Record Customer; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        CustBankAccCode: Code[10];
    begin
        LibrarySales.CreateCustomer(Customer);
        CustBankAccCode := CreateCustomerBankAccount(Customer."No.");
        Customer."Preferred Bank Account Code" := CustBankAccCode;
        Customer."Partner Type" := Customer."Partner Type"::Company;
        Customer.Address := LibraryUtility.GenerateGUID;
        Customer.Modify;

        CreateMandate(SEPADirectDebitMandate, Customer."No.");
        SEPADirectDebitMandate."Customer Bank Account Code" := CustBankAccCode;
        SEPADirectDebitMandate.Modify;
    end;

    local procedure CreateCustomerAndPostInvoice(var Customer: Record Customer; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        InvoiceNo: Code[20];
    begin
        CreateCustomerWithDDMandate(Customer, SEPADirectDebitMandate);
        InvoiceNo := PostCustGenJnlLine(Customer."No.", SEPADirectDebitMandate.ID);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateDirectDebitCollectionEntry(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; BankAccountNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustLedgerEntry."Customer No.");
        DirectDebitCollection.CreateNew(
          LibraryUtility.GenerateGUID, BankAccountNo, Customer."Partner Type");

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", CustLedgerEntry);

        DirectDebitCollectionEntry."Transfer Amount" := CustLedgerEntry."Remaining Amount";
        DirectDebitCollectionEntry.Modify;
    end;

    local procedure PostCustGenJnlLine(CustomerNo: Code[20]; DirectDebitMandateID: Code[35]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Direct Debit Mandate ID", DirectDebitMandateID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateMandate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustNo: Code[20])
    begin
        with SEPADirectDebitMandate do begin
            ID := LibraryUtility.GenerateGUID;
            "Customer No." := CustNo;
            "Type of Payment" := "Type of Payment"::Recurrent;
            "Expected Number of Debits" := 10;
            "Date of Signature" := Today;
            Insert;
        end;
    end;

    local procedure GetCreditorNo(BankAccNo: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        exit(BankAccount."Creditor No.");
    end;

    local procedure OpenXMLDoc(var TempBlob: Codeunit "Temp Blob"; var XMLDoc: DotNet XmlDocument; var XMLDocNode: DotNet XmlNode)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XMLDoc);
        XMLDocNode := XMLDoc.DocumentElement;
        Assert.IsTrue(XMLDocNode.HasChildNodes, 'No child nodes');
    end;

    local procedure UpdateDDNosOnSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup."Direct Debit Mandate Nos." := LibraryERM.CreateNoSeriesCode;
        SalesReceivablesSetup.Modify;
    end;

    local procedure ExportVerifySepaDDXML(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        TempBlob: Codeunit "Temp Blob";
        XMLDoc: DotNet XmlDocument;
        XMLDocNode: DotNet XmlNode;
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        OutStr: OutStream;
        InStr: InStream;
        Str: Text;
        i: Integer;
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        DirectDebitCollection.Get(DirectDebitCollectionEntry."Direct Debit Collection No.");
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.02.ch03", OutStr, DirectDebitCollectionEntry);
        TempBlob.CreateInStream(InStr);

        InStr.ReadText(Str);
        Assert.AreEqual('<?xml version="1.0" encoding="UTF-8" standalone="no"?>', Str, 'Wrong XML header.');
        InStr.ReadText(Str);
        Assert.AreEqual(
          '<Document xmlns="http://www.six-interbank-clearing.com/de/pain.008.001.02.ch.03.xsd">',
          Str, 'Wrong XML Instruction.');
        InStr.ReadText(Str);
        Assert.AreEqual('  <CstmrDrctDbtInitn>', Str, 'Wrong XML root.');

        OpenXMLDoc(TempBlob, XMLDoc, XMLDocNode);

        XMLNode := XMLDocNode.FirstChild;  // CstmrDrctDbtInitn
        XMLNodes := XMLNode.ChildNodes;
        Assert.AreEqual(1 + DirectDebitCollectionEntry.Count, XMLNodes.Count, 'Wrong node count');

        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'GrpHdr':
                    ValidateGrpHdr(XMLNode, DirectDebitCollection, DirectDebitCollectionEntry);
                'PmtInf':
                    ValidatePmtInf(
                      XMLNode, 1, 1,
                      DirectDebitCollectionEntry."Transfer Date",
                      GetCreditorNo(DirectDebitCollection."To Bank Account No."));
                else
                    Error(XMLUnknownElementErr, XMLNode.Name);
            end;
        end;
    end;

    local procedure ValidateGrpHdr(var XMLParentNode: DotNet XmlNode; var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
        dt: DateTime;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'MsgId':
                    Assert.AreEqual(DirectDebitCollection."Message ID", XMLNode.InnerXml, 'Wrong MsgID.');
                'CreDtTm':
                    begin
                        Evaluate(dt, XMLNode.InnerXml, 9);
                        Assert.AreNearlyEqual(0, CurrentDateTime - dt, 60000, 'Wrong CreDtTm.');
                        Assert.AreEqual(19, StrLen(XMLNode.InnerXml), 'Wrong CreDtTm length');
                    end;
                'NbOfTxs':
                    Assert.AreEqual(Format(DirectDebitCollectionEntry.Count, 0, 9), XMLNode.InnerXml, 'Wrong NbOfTxs.');
                'CtrlSum':
                    begin
                        DirectDebitCollectionEntry.CalcSums("Transfer Amount");
                        Assert.AreEqual(
                          Format(DirectDebitCollectionEntry."Transfer Amount", 0, '<Precision,2:2><Standard Format,9>'),
                          XMLNode.InnerXml, 'Wrong CtrlSum.');
                    end;
                'InitgPty':
                    ValidatePartyElement(XMLNode);
                else
                    Assert.Fail(StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
            end;
        end;
    end;

    local procedure ValidateCdtr(var XMLParentNode: DotNet XmlNode)
    var
        CompanyInfo: Record "Company Information";
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        CompanyInfo.Get;
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'Nm':
                    Assert.AreEqual(StringConversionMgt.WindowsToASCII(CompanyInfo.Name), XMLNode.InnerXml, '');
                else
                    Assert.IsTrue(XMLNode.Name in ['Id', 'PstlAdr'], StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
            end;
        end;
    end;

    local procedure ValidateCdtrSchmeId(var XMLParentNode: DotNet XmlNode; CreditorNo: Text)
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := XMLParentNode.FirstChild;
        Assert.AreEqual('Id', XMLNode.Name, '<SchmeId><Id>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('PrvtId', XMLNode.Name, '<SchmeId><Id><PrvtId>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Othr', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Id', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr><Id>');
        Assert.AreEqual(CreditorNo, XMLNode.InnerXml, '<SchmeId><Id><PrvtId><Othr><Id>'); // RS-PID

        XMLNode := XMLNode.ParentNode.LastChild;
        Assert.AreEqual('SchmeNm', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr><SchmeNm>');
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Prtry', XMLNode.Name, '<SchmeId><Id><PrvtId><Othr><SchmeNm><Prtry>');
        Assert.AreEqual('CHDD', XMLNode.InnerXml, '<SchmeId><Id><PrvtId><Othr><SchmeNm><Prtry>');
    end;

    local procedure ValidatePmtInf(var XMLParentNode: DotNet XmlNode; ExpectedNoOfDrctDbtTxInf: Integer; ExpectedCtrlSum: Decimal; ExpectedDate: Date; ExpectedCreditorNo: Text)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        ActualDate: Date;
        NoOfDrctDbtTxInf: Integer;
        i: Integer;
        CtrlSum: Decimal;
        NbOfTxs: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'PmtInfId', 'CdtrAcct', 'CdtrAgt':
                    ;
                'PmtTpInf':
                    ValidatePmtTpInf(XMLNode);
                'Cdtr':
                    ValidateCdtr(XMLNode);
                'PmtMtd':
                    Assert.AreEqual('DD', XMLNode.InnerXml, 'PmtMtd');
                'CdtrSchmeId':
                    ValidateCdtrSchmeId(XMLNode, ExpectedCreditorNo);
                'CtrlSum':
                    begin
                        Evaluate(CtrlSum, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedCtrlSum, CtrlSum, 'CtrlSum');
                    end;
                'NbOfTxs':
                    begin
                        Evaluate(NbOfTxs, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedNoOfDrctDbtTxInf, NbOfTxs, 'NbOfTxs');
                    end;
                'ReqdColltnDt':
                    begin
                        Evaluate(ActualDate, XMLNode.InnerXml, 9);
                        Assert.AreEqual(ExpectedDate, ActualDate, 'ReqdColltnDt');
                    end;
                'DrctDbtTxInf':
                    begin
                        ValidateDrctDbtTxInf(XMLNode);
                        NoOfDrctDbtTxInf += 1;
                    end;
                else
                    Assert.Fail(StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
            end;
        end;
        Assert.AreEqual(ExpectedNoOfDrctDbtTxInf, NoOfDrctDbtTxInf, 'Wrong number of DrctDbtTxInf nodes.');
    end;

    local procedure ValidateDrctDbtTxInf(var XMLParentNode: DotNet XmlNode)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'DbtrAcct':
                    ValidateDbtrAcct(XMLNode);
                else
                    Assert.IsTrue(
                      XMLNode.Name in ['PmtId', 'InstdAmt', 'DbtrAgt', 'Dbtr', 'RmtInf'],
                      StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
            end;
        end;
    end;

    local procedure ValidatePartyElement(var XMLParentNode: DotNet XmlNode)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            case XMLNode.Name of
                'Nm':
                    Assert.AreNotEqual('', XMLNode.InnerXml, '');
                'CtctDtls':
                    ValidateContactDetails(XMLNode);
                'Id':
                    ValidateHdrRSPID(XMLNode);
                else
                    Assert.Fail(StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
            end;
        end;
    end;

    local procedure ValidateContactDetails(var XMLParentNode: DotNet XmlNode)
    var
        XMLNodes: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodes := XMLParentNode.ChildNodes;
        for i := 0 to XMLNodes.Count - 1 do begin
            XMLNode := XMLNodes.ItemOf(i);
            Assert.IsTrue(XMLNode.Name in ['Nm', 'Othr'], StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
        end;
    end;

    local procedure ValidatePmtTpInf(var XMLParentNode: DotNet XmlNode)
    var
        XMLNode: DotNet XmlNode;
        XMLNodeLvl2: DotNet XmlNode;
    begin
        XMLNode := XMLParentNode.FirstChild;
        Assert.AreEqual('SvcLvl', XMLNode.Name, StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
        XMLNodeLvl2 := XMLNode.FirstChild;
        Assert.AreEqual('CHDD', XMLNodeLvl2.InnerXml, XmlWrongValueErr);

        XMLNode := XMLParentNode.LastChild;
        Assert.AreEqual('LclInstrm', XMLNode.Name, StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
        XMLNodeLvl2 := XMLNode.FirstChild;
        Assert.AreEqual('DDCOR1', XMLNodeLvl2.InnerXml, XmlWrongValueErr);
    end;

    local procedure ValidateDbtrAcct(var XMLParentNode: DotNet XmlNode)
    var
        XMLNode: DotNet XmlNode;
        XMLNodeLvl2: DotNet XmlNode;
    begin
        XMLNode := XMLParentNode.FirstChild;
        Assert.AreEqual('Id', XMLNode.Name, StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
        XMLNodeLvl2 := XMLNode.FirstChild;
        Assert.AreEqual('IBAN', XMLNodeLvl2.Name, StrSubstNo(XMLUnknownElementErr, XMLNodeLvl2.Name));
        Assert.AreEqual(GetIBANCust, XMLNodeLvl2.InnerXml, XmlWrongValueErr);
    end;

    local procedure ValidateHdrRSPID(var XMLParentNode: DotNet XmlNode)
    var
        XMLNode: DotNet XmlNode;
    begin
        XMLNode := XMLParentNode.FirstChild;
        XMLNode := XMLNode.FirstChild;
        XMLNode := XMLNode.FirstChild;
        Assert.AreEqual('Id', XMLNode.Name, StrSubstNo(XMLUnknownElementErr, XMLNode.Name));
        Assert.AreEqual(GetRSPID, XMLNode.InnerXml, XmlWrongValueErr);
    end;
}

