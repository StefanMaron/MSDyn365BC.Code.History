codeunit 143018 "Library - VAT Ledger"
{
    // // [FEATURE] [VAT Ledger]


    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateCustomerEAEU(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        with Customer do begin
            Validate("Country/Region Code", MockCountryEAEU);
            Modify(true);
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockSalesHeader(CustomerNo: Code[20]; ShipToCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        with SalesHeader do begin
            Init;
            "Document Type" := "Document Type"::Invoice;
            "No." := LibraryUtility.GenerateGUID;
            "Sell-to Customer No." := CustomerNo;
            "Ship-to Code" := ShipToCode;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        with SalesLine do begin
            Init;
            "Document Type" := "Document Type"::Invoice;
            "Document No." := DocumentNo;
            "Line No." := LibraryUtility.GetNewRecNo(SalesLine, FieldNo("Line No."));
            Type := Type::Item;
            "No." := ItemNo;
            "Location Code" := LocationCode;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockSalesInvHeader(CustomerNo: Code[20]; ShipToCode: Code[10]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        with SalesInvoiceHeader do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Sell-to Customer No." := CustomerNo;
            "Ship-to Code" := ShipToCode;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockSalesInvLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        with SalesInvoiceLine do begin
            Init;
            "Document No." := DocumentNo;
            "Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLine, FieldNo("Line No."));
            Type := Type::Item;
            "No." := ItemNo;
            "Location Code" := LocationCode;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockSalesCrMemoHeader(CustomerNo: Code[20]; ShipToCode: Code[10]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        with SalesCrMemoHeader do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Sell-to Customer No." := CustomerNo;
            "Ship-to Code" := ShipToCode;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        with SalesCrMemoLine do begin
            Init;
            "Document No." := DocumentNo;
            "Line No." := LibraryUtility.GetNewRecNo(SalesCrMemoLine, FieldNo("Line No."));
            Type := Type::Item;
            "No." := ItemNo;
            "Location Code" := LocationCode;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        with Vendor do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
            "VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 10);
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockCustomerNo(CountryRegionCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        with Customer do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Country/Region Code" := CountryRegionCode;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVATLedger(var VATLedger: Record "VAT Ledger"; TypeValue: Option)
    begin
        with VATLedger do begin
            Init;
            Type := TypeValue;
            Code := LibraryUtility.GenerateGUID;
            "Start Date" := WorkDate;
            "End Date" := WorkDate;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVendorVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; var VendorNo: Code[20])
    begin
        VendorNo := MockVendorNo;
        MockVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure MockCustomerVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; var CustomerNo: Code[20])
    begin
        CustomerNo := MockCustomerNo(MockCountryEAEU);
        MockVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, CustomerNo);
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; TypeValue: Option; CVType: Option; CVNo: Code[20])
    var
        VATLedger: Record "VAT Ledger";
    begin
        MockVATLedger(VATLedger, TypeValue);
        with VATLedgerLine do begin
            Init;
            Type := VATLedger.Type;
            Code := VATLedger.Code;
            "Line No." := LibraryUtility.GetNewRecNo(VATLedgerLine, FieldNo("Line No."));
            "C/V Type" := CVType;
            "C/V No." := CVNo;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLineForTheGivenVATLedger(var VATLedgerLine: Record "VAT Ledger Line"; VATLedger: Record "VAT Ledger"; AddSheet: Boolean)
    begin
        with VATLedgerLine do begin
            Init;
            Type := VATLedger.Type;
            Code := VATLedger.Code;
            "Line No." := LibraryUtility.GetNewRecNo(VATLedgerLine, FieldNo("Line No."));
            "Additional Sheet" := AddSheet;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVendorVATLedgerLineWithCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: Code[30])
    begin
        CDNo := GenerateCDNoValue;
        MockVATLedgerLineWithCDNo(
          VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, MockVendorNo, CDNo);
    end;

    [Scope('OnPrem')]
    procedure MockCustomerVATLedgerLineWithCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: Code[30])
    begin
        CDNo := GenerateCDNoValue;
        MockVATLedgerLineWithCDNo(
          VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, MockCustomerNo(''), CDNo);
    end;

    local procedure MockVATLedgerLineWithCDNo(var VATLedgerLine: Record "VAT Ledger Line"; Type: Option; CVType: Option; CVNo: Code[20]; CDNo: Code[30])
    begin
        MockVATLedgerLine(VATLedgerLine, Type, CVType, CVNo);
        MockVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Scope('OnPrem')]
    procedure MockVendorVATLedgerLineWithTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: Code[20])
    begin
        TariffNo := MockTariffNo;
        MockVATLedgerLineWithTariffNo(
          VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, MockVendorNo, TariffNo);
    end;

    [Scope('OnPrem')]
    procedure MockCustomerVATLedgerLineWithTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: Code[20])
    begin
        TariffNo := MockTariffNo;
        MockVATLedgerLineWithTariffNo(
          VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, MockCustomerNo(''), TariffNo);
    end;

    local procedure MockVATLedgerLineWithTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; Type: Option; CVType: Option; CVNo: Code[20]; TariffNo: Code[20])
    begin
        MockVATLedgerLine(VATLedgerLine, Type, CVType, CVNo);
        MockVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLineCDNo(var VATLedgerLine: Record "VAT Ledger Line"; CDNo: Code[30])
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        with VATLedgerLineCDNo do begin
            Init;
            Type := VATLedgerLine.Type;
            Code := VATLedgerLine.Code;
            "Line No." := VATLedgerLine."Line No.";
            "CD No." := CDNo;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLineTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; TariffNo: Code[20])
    var
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        with VATLedgerLineTariffNo do begin
            Init;
            Type := VATLedgerLine.Type;
            Code := VATLedgerLine.Code;
            "Line No." := VATLedgerLine."Line No.";
            "Tariff No." := TariffNo;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockVendorValueEntryWithCDNo(VendorNo: Code[20]; DocumentNo: Code[20]; CDNo: Code[30])
    var
        ValueEntry: Record "Value Entry";
    begin
        MockValueEntry(ValueEntry."Source Type"::Vendor, VendorNo, DocumentNo, '', MockItemLedgerEntryNo(CDNo));
    end;

    [Scope('OnPrem')]
    procedure MockCustomerValueEntryWithCDNo(CustomerNo: Code[20]; DocumentNo: Code[20]; CDNo: Code[30])
    var
        ValueEntry: Record "Value Entry";
    begin
        MockValueEntry(ValueEntry."Source Type"::Customer, CustomerNo, DocumentNo, '', MockItemLedgerEntryNo(CDNo));
    end;

    [Scope('OnPrem')]
    procedure MockVendorValueEntryWithTariffNo(VendorNo: Code[20]; DocumentNo: Code[20]; TariffNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        MockValueEntry(ValueEntry."Source Type"::Vendor, VendorNo, DocumentNo, MockItemNo(TariffNo), MockItemLedgerEntryNo(''));
    end;

    [Scope('OnPrem')]
    procedure MockCustomerValueEntryWithTariffNo(CustomerNo: Code[20]; DocumentNo: Code[20]; TariffNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DummyValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        ItemNo := MockItemNo(TariffNo);
        MockSalesInvLine(SalesInvoiceLine, DocumentNo, ItemNo, '');
        MockValueEntry(DummyValueEntry."Source Type"::Customer, CustomerNo, DocumentNo, ItemNo, MockItemLedgerEntryNo(''));
    end;

    local procedure MockValueEntry(SourceType: Option; SourceNo: Code[20]; DocumentNo: Code[20]; ItemNo: Code[20]; ItemLedgerEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, FieldNo("Entry No."));
            "Source Type" := SourceType;
            "Source No." := SourceNo;
            "Item No." := ItemNo;
            "Item Ledger Entry No." := ItemLedgerEntryNo;
            "Document Type" := "Document Type"::"Sales Invoice";
            "Document No." := DocumentNo;
            "Document Line No." := 10000;
            Insert;
        end;
    end;

    local procedure MockItemLedgerEntryNo(CDNo: Code[30]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, FieldNo("Entry No."));
            "CD No." := CDNo;
            Insert;
            exit("Entry No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockPurchaseVATEntry(var DocumentNo: Code[20]; var VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VendorNo := MockVendorNo;
        DocumentNo := LibraryUtility.GenerateGUID;
        MockVATEntry(VATEntry.Type::Purchase, DocumentNo, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure MockSalesVATEntry(var DocumentNo: Code[20]; var CustomerNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        CustomerNo := MockCustomerNo(MockCountryEAEU);
        DocumentNo := MockSalesInvHeader(CustomerNo, '');
        MockVATEntry(VATEntry.Type::Sale, DocumentNo, CustomerNo);
    end;

    [Scope('OnPrem')]
    procedure MockPurchaseVATEntryAddSheet(var DocumentNo: Code[20]; var VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VendorNo := MockVendorNo;
        DocumentNo := LibraryUtility.GenerateGUID;
        MockVATEntryAddSheet(VATEntry.Type::Purchase, DocumentNo, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure MockSalesVATEntryAddSheet(var DocumentNo: Code[20]; var CustomerNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        CustomerNo := MockCustomerNo(MockCountryEAEU);
        DocumentNo := MockSalesInvHeader(CustomerNo, '');
        MockVATEntryAddSheet(VATEntry.Type::Sale, DocumentNo, CustomerNo);
    end;

    local procedure MockVATEntry(TypeValue: Option; DocumentNo: Code[20]; CVNo: Code[20]): Integer
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        with VATEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(VATEntry, FieldNo("Entry No."));
            Type := TypeValue;
            "Posting Date" := WorkDate;
            "Document Type" := "Document Type"::Invoice;
            "Document No." := DocumentNo;
            "Bill-to/Pay-to No." := CVNo;
            Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
            "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
            "VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
            Insert;
            exit("Entry No.");
        end;
    end;

    local procedure MockVATEntryAddSheet(TypeValue: Option; DocumentNo: Code[20]; CVNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            Get(MockVATEntry(TypeValue, DocumentNo, CVNo));
            Reversed := true;
            "Corrected Document Date" := "Posting Date";
            "Additional VAT Ledger Sheet" := true;
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure MockItemNo(TariffNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        with Item do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Tariff No." := TariffNo;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockTariffNo(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        with TariffNumber do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
            exit("No.");
        end;
    end;

    [Scope('OnPrem')]
    procedure MockCountryNonEAEU(): Code[10]
    begin
        exit(MockCountry(''));
    end;

    [Scope('OnPrem')]
    procedure MockCountryEAEU(): Code[10]
    begin
        exit(MockCountry(LibraryUtility.GenerateGUID));
    end;

    local procedure MockCountry(EAEUCountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        with CountryRegion do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            "EAEU Country/Region Code" := EAEUCountryRegionCode;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockLocationNonEAEU(): Code[10]
    begin
        exit(MockLocation(MockCountryNonEAEU));
    end;

    [Scope('OnPrem')]
    procedure MockLocationEAEU(): Code[10]
    begin
        exit(MockLocation(MockCountryEAEU));
    end;

    [Scope('OnPrem')]
    procedure MockLocation(CountryRegionCode: Code[10]): Code[10]
    var
        Location: Record Location;
    begin
        with Location do begin
            Init;
            Code := LibraryUtility.GenerateGUID;
            "Country/Region Code" := CountryRegionCode;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure MockShipToAddressNonEAEU(CustomerNo: Code[20]): Code[10]
    begin
        exit(MockShipToAddress(CustomerNo, MockCountryNonEAEU));
    end;

    [Scope('OnPrem')]
    procedure MockShipToAddressEAEU(CustomerNo: Code[20]): Code[10]
    begin
        exit(MockShipToAddress(CustomerNo, MockCountryEAEU));
    end;

    [Scope('OnPrem')]
    procedure MockShipToAddress(CustomerNo: Code[20]; CountryRegionCode: Code[10]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        with ShipToAddress do begin
            Init;
            "Customer No." := CustomerNo;
            Code := LibraryUtility.GenerateGUID;
            "Country/Region Code" := CountryRegionCode;
            Insert;
            exit(Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure GenerateCDNoValue(): Code[30]
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 0), 1, 30));
    end;

    [Scope('OnPrem')]
    procedure FindVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; VATLedger: Record "VAT Ledger")
    begin
        with VATLedgerLine do begin
            SetRange(Type, VATLedger.Type);
            SetRange(Code, VATLedger.Code);
            FindFirst;
        end;
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATPurchaseLedgerReport(VATLedger: Record "VAT Ledger"; VendorNo: Code[20])
    var
        CreateVATPurchaseLedger: Report "Create VAT Purchase Ledger";
    begin
        VATLedger.SetRecFilter;
        Clear(CreateVATPurchaseLedger);
        CreateVATPurchaseLedger.SetTableView(VATLedger);
        CreateVATPurchaseLedger.SetParameters(VendorNo, '', '', 0, false, true, 0, 0, true, true, false, false);
        CreateVATPurchaseLedger.UseRequestPage(false);
        CreateVATPurchaseLedger.Run;
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATSalesLedgerReport(VATLedger: Record "VAT Ledger"; CustomerNo: Code[20])
    var
        CreateVATSalesLedger: Report "Create VAT Sales Ledger";
    begin
        VATLedger.SetRecFilter;
        Clear(CreateVATSalesLedger);
        CreateVATSalesLedger.SetTableView(VATLedger);
        CreateVATSalesLedger.SetParameters(CustomerNo, '', '', 0, true, true, true, false, false, false, false);
        CreateVATSalesLedger.UseRequestPage(false);
        CreateVATSalesLedger.Run;
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATPurchLedAdShReport(VATLedger: Record "VAT Ledger"; VendorNo: Code[20])
    var
        CreateVATPurchLedAdSh: Report "Create VAT Purch. Led. Ad. Sh.";
    begin
        VATLedger.SetRecFilter;
        Clear(CreateVATPurchLedAdSh);
        CreateVATPurchLedAdSh.SetTableView(VATLedger);
        CreateVATPurchLedAdSh.SetParameters(VendorNo, '', '', 0, false, true, 0, 0, true, true, false, false);
        CreateVATPurchLedAdSh.UseRequestPage(false);
        CreateVATPurchLedAdSh.Run;
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATSalesLedAdShReport(VATLedger: Record "VAT Ledger"; CustomerNo: Code[20])
    var
        CreateVATSalesLedAdSh: Report "Create VAT Sales Led. Ad. Sh.";
    begin
        VATLedger.SetRecFilter;
        Clear(CreateVATSalesLedAdSh);
        CreateVATSalesLedAdSh.SetTableView(VATLedger);
        CreateVATSalesLedAdSh.SetParameters(CustomerNo, '', '', 0, true, true, true, false, false, false);
        CreateVATSalesLedAdSh.UseRequestPage(false);
        CreateVATSalesLedAdSh.Run;
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyInformationEAEU()
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get;
            Validate("Country/Region Code", MockCountryEAEU);
            Modify(true);
        end;
    end;
}

