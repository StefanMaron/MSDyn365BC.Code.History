codeunit 144207 "FatturaPA Applications"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Application]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementNameErr: Label 'Unexpected element name. Expected element name: %1. Actual element name: %2.', Comment='%1=Expetced XML Element Name;%2=Actual XML Element Name;';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment='%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';

    [Test]
    procedure InvoiceToCreditMemoFromDocument()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 305069] An information about the sales invoice applied to credit memo from document exists in FatturaPA XML File under node DatiFattureCollegate

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with "Document No." = "X", "Posting Date" = 01.01.2020, "Fattura Project Code" = "A", "Fattura Tender Code" = "B"
        CreatePostSalesDocWithFatturaCodes(
          CustLedgerEntry,FatturaProjectCode,FatturaTenderCode,CustLedgerEntry."Document Type"::"Credit Memo");

        // [GIVEN] Sales Invoice with "Applies-To Doc. No." = "X"
        CreateSalesDocument(
          SalesHeader,SalesHeader."Document Type"::Invoice,CustLedgerEntry."Sell-to Customer No.",'','',
          SalesHeader."Applies-to Doc. Type"::"Credit Memo",CustLedgerEntry."Document No.");

        // [GIVEN] Sales Invoice was posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader,true,true);
        SalesInvoiceHeader.SetRange("No.",DocNo);

        // [WHEN] Export Sales Invoice
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName,SalesInvoiceHeader,CopyStr(FatturaPA_ElectronicFormatTxt,1,20));

        // [THEN] XML file has the following XML nodes under node DatiFattureCollegate
        // [THEN] "IdDocumento" = "X"
        // [THEN] "Data" = 01.01.2020
        // [THEN] "CodiceCUP" = "A"
        // [THEN] "CodiceCIG" = "B"
        VerifyApplicationInformation(
          ServerFileName,CustLedgerEntry."Document No.",CustLedgerEntry."Posting Date",FatturaProjectCode,FatturaTenderCode);
    end;

    [Test]
    procedure InvoiceToCreditMemoForwardApplicationAfterPosting()
    var
        InvCustLedgerEntry: Record "Cust. Ledger Entry";
        CrMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 305069] An information about the sales credit memo applied from invoice after posting exists in FatturaPA XML File under node DatiFattureCollegate

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with "Document No." = "X", "Posting Date" = 01.01.2020, "Fattura Project Code" = "A", "Fattura Tender Code" = "B"
        CreatePostSalesDocWithFatturaCodes(
          CrMemoCustLedgerEntry,FatturaProjectCode,FatturaTenderCode,CrMemoCustLedgerEntry."Document Type"::"Credit Memo");

        // [GIVEN] Posted Sales Invoice
        CreatePostedSalesDoc(
          InvCustLedgerEntry,CrMemoCustLedgerEntry."Sell-to Customer No.",InvCustLedgerEntry."Document Type"::Invoice,'','');

        // [GIVEN] Posted Sales Invoice applied to Sales Credit Memo
        ApplyCustLedgEntries(InvCustLedgerEntry,CrMemoCustLedgerEntry);
        SalesInvoiceHeader.SetRange("No.",InvCustLedgerEntry."Document No.");

        // [WHEN] Export Sales Invoice
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName,SalesInvoiceHeader,CopyStr(FatturaPA_ElectronicFormatTxt,1,20));

        // [THEN] XML file has the following XML nodes under node DatiFattureCollegate
        // [THEN] "IdDocumento" = "X"
        // [THEN] "Data" = 01.01.2020
        // [THEN] "CodiceCUP" = "A"
        // [THEN] "CodiceCIG" = "B"
        VerifyApplicationInformation(
          ServerFileName,CrMemoCustLedgerEntry."Document No.",CrMemoCustLedgerEntry."Posting Date",FatturaProjectCode,FatturaTenderCode);
    end;

    [Test]
    procedure InvoiceToCreditMemoBackwardApplicationAfterPosting()
    var
        InvCustLedgerEntry: Record "Cust. Ledger Entry";
        CrMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 305069] An information about the sales credit memo applied to invoice after posting exists in FatturaPA XML File under node DatiFattureCollegate

        Initialize;

        // [GIVEN] Posted Sales Credit Memo with "Document No." = "X", "Posting Date" = 01.01.2020, "Fattura Project Code" = "A", "Fattura Tender Code" = "B"
        CreatePostSalesDocWithFatturaCodes(
          CrMemoCustLedgerEntry,FatturaProjectCode,FatturaTenderCode,CrMemoCustLedgerEntry."Document Type"::"Credit Memo");

        // [GIVEN] Posted Sales Invoice
        CreatePostedSalesDoc(
          InvCustLedgerEntry,CrMemoCustLedgerEntry."Sell-to Customer No.",InvCustLedgerEntry."Document Type"::Invoice,'','');

        // [GIVEN] Posted Sales Credit Memo applied to Sales Invoice
        ApplyCustLedgEntries(CrMemoCustLedgerEntry,InvCustLedgerEntry);
        SalesInvoiceHeader.SetRange("No.",InvCustLedgerEntry."Document No.");

        // [WHEN] Export Sales Invoice
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName,SalesInvoiceHeader,CopyStr(FatturaPA_ElectronicFormatTxt,1,20));

        // [THEN] XML file has the following XML nodes under node DatiFattureCollegate
        // [THEN] "IdDocumento" = "X"
        // [THEN] "Data" = 01.01.2020
        // [THEN] "CodiceCUP" = "A"
        // [THEN] "CodiceCIG" = "B"
        VerifyApplicationInformation(
          ServerFileName,CrMemoCustLedgerEntry."Document No.",CrMemoCustLedgerEntry."Posting Date",FatturaProjectCode,FatturaTenderCode);
    end;

    [Test]
    procedure CreditMemoToInvoiceFromDocument()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 305069] An information about the sales credit invoice applied to credit memo from document exists in FatturaPA XML File under node DatiFattureCollegate

        Initialize;

        // [GIVEN] Posted Sales Invoice with "Document No." = "X", "Posting Date" = 01.01.2020, "Fattura Project Code" = "A", "Fattura Tender Code" = "B"
        CreatePostSalesDocWithFatturaCodes(
          CustLedgerEntry,FatturaProjectCode,FatturaTenderCode,CustLedgerEntry."Document Type"::Invoice);

        // [GIVEN] Sales Credit Memo with "Applies-To Doc. No." = "X"
        CreateSalesDocument(
          SalesHeader,SalesHeader."Document Type"::"Credit Memo",CustLedgerEntry."Sell-to Customer No.",'','',
          SalesHeader."Applies-to Doc. Type"::Invoice,CustLedgerEntry."Document No.");

        // [GIVEN] Sales Credit Memo was posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader,true,true);
        SalesCrMemoHeader.SetRange("No.",DocNo);

        // [WHEN] Export Sales Credit Memo
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName,SalesCrMemoHeader,CopyStr(FatturaPA_ElectronicFormatTxt,1,20));

        // [THEN] XML file has the following XML nodes under node DatiFattureCollegate
        // [THEN] "IdDocumento" = "X"
        // [THEN] "Data" = 01.01.2020
        // [THEN] "CodiceCUP" = "A"
        // [THEN] "CodiceCIG" = "B"
        VerifyApplicationInformation(
          ServerFileName,CustLedgerEntry."Document No.",CustLedgerEntry."Posting Date",FatturaProjectCode,FatturaTenderCode);
    end;

    [Test]
    procedure CreditMemoToInvoiceForwardApplicationAfterPosting()
    var
        InvCustLedgerEntry: Record "Cust. Ledger Entry";
        CrMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 305069] An information about the sales invoice applied from credit memo after posting exists in FatturaPA XML File under node DatiFattureCollegate

        Initialize;

        // [GIVEN] Posted Sales Invoice with "Document No." = "X", "Posting Date" = 01.01.2020, "Fattura Project Code" = "A", "Fattura Tender Code" = "B"
        CreatePostSalesDocWithFatturaCodes(
          InvCustLedgerEntry,FatturaProjectCode,FatturaTenderCode,InvCustLedgerEntry."Document Type"::Invoice);

        // [GIVEN] Posted Sales Credit Memo
        CreatePostedSalesDoc(
          CrMemoCustLedgerEntry,InvCustLedgerEntry."Sell-to Customer No.",CrMemoCustLedgerEntry."Document Type"::"Credit Memo",'','');

        // [GIVEN] Posted Sales Credit Memo applied to Sales Invoice
        ApplyCustLedgEntries(CrMemoCustLedgerEntry,InvCustLedgerEntry);
        SalesCrMemoHeader.SetRange("No.",CrMemoCustLedgerEntry."Document No.");

        // [WHEN] Export Sales Credit Memo
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName,SalesCrMemoHeader,CopyStr(FatturaPA_ElectronicFormatTxt,1,20));

        // [THEN] XML file has the following XML nodes under node DatiFattureCollegate
        // [THEN] "IdDocumento" = "X"
        // [THEN] "Data" = 01.01.2020
        // [THEN] "CodiceCUP" = "A"
        // [THEN] "CodiceCIG" = "B"
        VerifyApplicationInformation(
          ServerFileName,InvCustLedgerEntry."Document No.",InvCustLedgerEntry."Posting Date",FatturaProjectCode,FatturaTenderCode);
    end;

    [Test]
    procedure CreditMemoToInvoiceBackwardApplicationAfterPosting()
    var
        InvCustLedgerEntry: Record "Cust. Ledger Entry";
        CrMemoCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        ClientFileName: Text[250];
        ServerFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 305069] An information about the sales invoice applied to credit memo after posting exists in FatturaPA XML File under node DatiFattureCollegate

        Initialize;

        // [GIVEN] Posted Sales Invoice with "Document No." = "X", "Posting Date" = 01.01.2020, "Fattura Project Code" = "A", "Fattura Tender Code" = "B"
        CreatePostSalesDocWithFatturaCodes(
          InvCustLedgerEntry,FatturaProjectCode,FatturaTenderCode,InvCustLedgerEntry."Document Type"::Invoice);

        // [GIVEN] Posted Sales Credit Memo
        CreatePostedSalesDoc(
          CrMemoCustLedgerEntry,InvCustLedgerEntry."Sell-to Customer No.",CrMemoCustLedgerEntry."Document Type"::"Credit Memo",'','');

        // [GIVEN] Posted Sales Invoice applied to Sales Credit Memo
        ApplyCustLedgEntries(InvCustLedgerEntry,CrMemoCustLedgerEntry);
        SalesCrMemoHeader.SetRange("No.",CrMemoCustLedgerEntry."Document No.");

        // [WHEN] Export Sales Credit Memo
        ElectronicDocumentFormat.SendElectronically(ServerFileName,
          ClientFileName,SalesCrMemoHeader,CopyStr(FatturaPA_ElectronicFormatTxt,1,20));

        // [THEN] XML file has the following XML nodes under node DatiFattureCollegate
        // [THEN] "IdDocumento" = "X"
        // [THEN] "Data" = 01.01.2020
        // [THEN] "CodiceCUP" = "A"
        // [THEN] "CodiceCIG" = "B"
        VerifyApplicationInformation(
          ServerFileName,InvCustLedgerEntry."Document No.",InvCustLedgerEntry."Posting Date",FatturaProjectCode,FatturaTenderCode);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        if IsInitialized then
          exit;

        LibraryITLocalization.SetupFatturaPA;
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure CreatePostSalesDocWithFatturaCodes(var CustLedgerEntry: Record "Cust. Ledger Entry";var FatturaProjectCode: Code[15];var FatturaTenderCode: Code[15];DocType: Option)
    begin
        FatturaProjectCode := LibraryITLocalization.CreateFatturaProjectCode;
        FatturaTenderCode := LibraryITLocalization.CreateFatturaTenderCode;
        CreateNormalPostedSalesDoc(CustLedgerEntry,DocType,FatturaProjectCode,FatturaTenderCode);
    end;

    local procedure CreateNormalPostedSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry";DocType: Option;FatturaProjectCode: Code[15];FatturaTenderCode: Code[15])
    var
        Customer: Record Customer;
        CustNo: Code[20];
    begin
        CustNo :=
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"),DATABASE::Customer),1,6));
        CreatePostedSalesDoc(CustLedgerEntry,CustNo,DocType,FatturaProjectCode,FatturaTenderCode);
    end;

    local procedure CreatePostedSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry";CustNo: Code[20];DocType: Option;FatturaProjectCode: Code[15];FatturaTenderCode: Code[15])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesHeader,DocType,CustNo,FatturaProjectCode,FatturaTenderCode,0,'');
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry,DocType,
          LibrarySales.PostSalesDocument(SalesHeader,true,true));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header";DocType: Option;CustNo: Code[20];FatturaProjectCode: Code[15];FatturaTenderCode: Code[15];AppliesToDocType: Option;AppliesToDocNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader,DocType,CustNo);
        SalesHeader.Validate("Payment Terms Code",LibraryITLocalization.CreateFatturaPaymentTermsCode);
        SalesHeader.Validate("Payment Method Code",LibraryITLocalization.CreateFatturaPaymentMethodCode);
        SalesHeader.Validate("Fattura Project Code",FatturaProjectCode);
        SalesHeader.Validate("Fattura Tender Code",FatturaTenderCode);
        SalesHeader.Validate("Applies-to Doc. Type",AppliesToDocType);
        SalesHeader.Validate("Applies-to Doc. No.",AppliesToDocNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine,SalesHeader,SalesLine.Type::Item,LibraryInventory.CreateItemNo,LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price",LibraryRandom.RandDec(100,2));
        SalesLine.Modify(true);
    end;

    local procedure ApplyCustLedgEntries(ApplyFromCustLedgEntry: Record "Cust. Ledger Entry";ApplyToCustLedgEntry: Record "Cust. Ledger Entry")
    begin
        ApplyFromCustLedgEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(ApplyFromCustLedgEntry,ApplyFromCustLedgEntry."Remaining Amount");
        ApplyToCustLedgEntry.SetRecFilter;
        LibraryERM.SetAppliestoIdCustomer(ApplyToCustLedgEntry);
        LibraryERM.PostCustLedgerApplication(ApplyFromCustLedgEntry);
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(Format(DateToFormat,0,TypeHelper.GetXMLDateFormat));
    end;

    local procedure DeleteServerFile(ServerFileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    local procedure AssertElementValue(var TempXMLBuffer: Record "XML Buffer" temporary;ElementName: Text;ElementValue: Text)
    begin
        FindNextElement(TempXMLBuffer);
        Assert.AreEqual(ElementName,TempXMLBuffer.GetElementName,
          StrSubstNo(UnexpectedElementNameErr,ElementName,TempXMLBuffer.GetElementName));
        Assert.AreEqual(ElementValue,TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr,ElementName,ElementValue,TempXMLBuffer.Value));
    end;

    local procedure FindNextElement(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        if TempXMLBuffer.HasChildNodes then
          TempXMLBuffer.FindChildElements(TempXMLBuffer)
        else
          if not (TempXMLBuffer.Next > 0) then begin
            TempXMLBuffer.GetParent;
            TempXMLBuffer.SetRange("Parent Entry No.",TempXMLBuffer."Parent Entry No.");
            if not (TempXMLBuffer.Next > 0) then
              repeat
                TempXMLBuffer.GetParent;
                TempXMLBuffer.SetRange("Parent Entry No.",TempXMLBuffer."Parent Entry No.");
              until (TempXMLBuffer.Next > 0);
          end;
    end;

    local procedure VerifyApplicationInformation(ServerFileName: Text[250];DocNo: Code[20];PostingDate: Date;FatturaProjectCode: Code[15];FatturaTenderCode: Code[15])
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Load(ServerFileName);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,'/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiFattureCollegate');
        AssertElementValue(TempXMLBuffer,'IdDocumento',DocNo);
        AssertElementValue(TempXMLBuffer,'Data',FormatDate(PostingDate));
        AssertElementValue(TempXMLBuffer,'CodiceCUP',FatturaProjectCode);
        AssertElementValue(TempXMLBuffer,'CodiceCIG',FatturaTenderCode);
        DeleteServerFile(ServerFileName);
    end;
}

