codeunit 144208 "FatturaPA Unit Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [UT]
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
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;

    [Test]
    procedure FCYConvertsToLCYWhenPrepareDocumentToExport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        RecRef: RecordRef;
    begin
        // [FEAUTURE] [Sales] [FCY]
        // [SCENARIO 308849] All the FCY amounts of the document converts to LCY when runnning CollectDocumentInformation of "Fattura Doc. Helper" codeunit again posted sales invoice

        Initialize;
        CreateSalesInvoiceFCY(SalesHeader,SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader,true,true));
        RecRef.GetTable(SalesInvoiceHeader);
        FatturaDocHelper.InitializeErrorLog(SalesInvoiceHeader);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader,TempFatturaLine,RecRef);
        TempFatturaLine.FindFirst;
        Assert.AreEqual(ExchangeToLCYAmount(SalesHeader,SalesLine."Unit Price"),TempFatturaLine."Unit Price",'');
        Assert.AreEqual(ExchangeToLCYAmount(SalesHeader,SalesLine.Amount),TempFatturaLine.Amount,'');
        Assert.AreEqual(ExchangeToLCYAmount(SalesHeader,SalesLine."Amount Including VAT"),TempFatturaHeader."Total Amount",'');
    end;

    [Test]
    procedure FatturaFileNameGotTenCharsFromProgresiveNo()
    var
        CompanyInformation: Record "Company Information";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        ProgressiveNo: Code[10];
        ZeroNo: Code[10];
        BaseString: Text;
    begin
        // [SCENARIO 305855] When a file name generates by function GetFileName of "Fattura Doc. Helper" codeunit it takes ten chars from "Progressive No." passed as parameter

        Initialize;
        ProgressiveNo := CopyStr(LibraryUtility.GenerateRandomText(10),1,MaxStrLen(ProgressiveNo));
        CompanyInformation.Get;
        BaseString := CopyStr(DelChr(ProgressiveNo,'=',',?;.:/-_ '),1,10);
        ZeroNo := PadStr('',10 - StrLen(BaseString),'0');
        Assert.AreEqual(
          CompanyInformation."Country/Region Code" + CompanyInformation."Fiscal Code" + '_' + ZeroNo + BaseString,
          FatturaDocHelper.GetFileName(ProgressiveNo),'');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleExtendedTextFattuesLines()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        RecRef: RecordRef;
    begin
        // [SCENARIO X] Multiple Fattura Line records with "Line Type" = "Extended Text" can be generated

        Initialize;
        CreateSalesDocInvWithMultipleExtTexts(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        RecRef.GetTable(SalesInvoiceHeader);

        FatturaDocHelper.InitializeErrorLog(SalesInvoiceHeader);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader, TempFatturaLine, RecRef);

        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::"Extended Text");
        Assert.RecordCount(TempFatturaLine, 2);
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

    local procedure CreateSalesInvoiceFCY(var SalesHeader: Record "Sales Header";var SalesLine: Record "Sales Line")
    var
        CustNo: Code[20];
    begin
        CustNo := CreateCustomerNo;
        LibrarySales.CreateSalesHeader(SalesHeader,SalesHeader."Document Type"::Invoice,CustNo);
        SalesHeader.Validate(
          "Payment Terms Code",LibraryITLocalization.CreateFatturaPaymentTermsCode);
        SalesHeader.Validate(
          "Payment Method Code",LibraryITLocalization.CreateFatturaPaymentMethodCode);
        SalesHeader.Validate("Currency Code",LibraryERM.CreateCurrencyWithRandomExchRates);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine,SalesHeader,SalesLine.Type::Item,LibraryInventory.CreateItemNo,LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price",LibraryRandom.RandDec(100,2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocInvWithMultipleExtTexts(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo);
        SalesHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode);
        SalesHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode);
        SalesHeader.Modify(true);
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithExtendedText, LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
            TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
            TransferExtendedText.InsertSalesExtText(SalesLine);
        end;
    end;

    local procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreateItemWithExtendedText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Rename(PadStr(Item."No.", MaxStrLen(Item."No."), 'X'));
        LibraryService.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Starting Date", WorkDate);
        ExtendedTextHeader.Validate("Ending Date", WorkDate);
        ExtendedTextHeader.Validate("Sales Invoice", true);
        ExtendedTextHeader.Validate("Sales Credit Memo", true);
        ExtendedTextHeader.Validate("Service Invoice", true);
        ExtendedTextHeader.Validate("Service Credit Memo", true);
        ExtendedTextHeader.Modify(true);
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, CopyStr(LibraryUtility.GenerateGUID, 1, MaxStrLen(ExtendedTextLine.Text)));
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure ExchangeToLCYAmount(SalesHeader: Record "Sales Header";Amount: Decimal): Decimal
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(SalesHeader."Currency Code");
        Currency.InitRoundingPrecision;
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              SalesHeader."Posting Date",SalesHeader."Currency Code",
              Amount,SalesHeader."Currency Factor"),
            Currency."Amount Rounding Precision"));
    end;
}

