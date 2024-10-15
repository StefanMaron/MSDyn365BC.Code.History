namespace Microsoft.Foundation.Address;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 365 "Format Address"
{
    Permissions = tabledata "Country/Region" = r;
    SingleInstance = true;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        GLSetupRead: Boolean;
        i: Integer;
        LanguageCode: Code[10];

    procedure FormatAddr(var AddrArray: array[8] of Text[100]; Name: Text[100]; Name2: Text[100]; Contact: Text[100]; Addr: Text[100]; Addr2: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10])
    var
        Country: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        InsertText: Integer;
        Index: Integer;
        NameLineNo: Integer;
        Name2LineNo: Integer;
        AddrLineNo: Integer;
        Addr2LineNo: Integer;
        ContLineNo: Integer;
        PostCodeCityLineNo: Integer;
        CountyLineNo: Integer;
        CountryLineNo: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeFormatAddr(Country, CountryCode);
        Clear(AddrArray);

        if CountryCode = '' then begin
            GetGLSetup();
            Clear(Country);
            Country."Address Format" := "Country/Region Address Format".FromInteger(GLSetup."Local Address Format");
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            if not Country.Get(CountryCode) then begin
                Country.Init();
                Country.Name := CountryCode;
            end else
                Country.TranslateName(LanguageCode);
        IsHandled := false;
        OnFormatAddrOnAfterGetCountry(
            AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, LanguageCode, IsHandled, Country);
        if IsHandled then
            exit;

        if Country."Address Format" = Country."Address Format"::Custom then begin
            CustomAddressFormat.Reset();
            CustomAddressFormat.SetCurrentKey("Country/Region Code", "Line Position");
            CustomAddressFormat.SetRange("Country/Region Code", CountryCode);
            if CustomAddressFormat.FindSet() then
                repeat
                    case CustomAddressFormat."Field ID" of
                        CompanyInfo.FieldNo(Name):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Name;
                        CompanyInfo.FieldNo("Name 2"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Name2;
                        CompanyInfo.FieldNo("Contact Person"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Contact;
                        CompanyInfo.FieldNo(Address):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Addr;
                        CompanyInfo.FieldNo("Address 2"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Addr2;
                        CompanyInfo.FieldNo(City):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := City;
                        CompanyInfo.FieldNo("Post Code"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := PostCode;
                        CompanyInfo.FieldNo(County):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := County;
                        CompanyInfo.FieldNo("Country/Region Code"):
                            AddrArray[CustomAddressFormat."Line Position" + 1] := Country.Name;
                        else
                            GenerateCustomPostCodeCity(AddrArray[CustomAddressFormat."Line Position" + 1], City, PostCode, County, Country);
                    end;
                until CustomAddressFormat.Next() = 0;

            CompressArray(AddrArray);
        end else begin
            SetLineNos(Country, NameLineNo, Name2LineNo, AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo);

            IsHandled := false;
            OnBeforeFormatAddress(
              Country, AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, NameLineNo, Name2LineNo,
              AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo, IsHandled);
            if IsHandled then
                exit;

            AddrArray[NameLineNo] := Name;
            AddrArray[Name2LineNo] := Name2;
            AddrArray[AddrLineNo] := Addr;
            AddrArray[Addr2LineNo] := Addr2;

            case Country."Address Format" of
                Country."Address Format"::"Post Code+City",
                Country."Address Format"::"City+County+Post Code",
                Country."Address Format"::"City+Post Code":
                    UpdateAddrArrayForPostCodeCity(AddrArray, Contact, ContLineNo, Country, CountryLineNo, PostCodeCityLineNo, CountyLineNo, City, PostCode, County);

                Country."Address Format"::"Blank Line+Post Code+City":
                    begin
                        if ContLineNo < PostCodeCityLineNo then
                            AddrArray[ContLineNo] := Contact;
                        CompressArray(AddrArray);

                        Index := 1;
                        InsertText := 1;
                        repeat
                            if AddrArray[Index] = '' then begin
                                case InsertText of
                                    2:
                                        GeneratePostCodeCity(AddrArray[Index], AddrArray[Index + 1], City, PostCode, County, Country);
                                    3:
                                        AddrArray[Index] := Country.Name;
                                    4:
                                        if ContLineNo > PostCodeCityLineNo then
                                            AddrArray[Index] := Contact;
                                end;
                                InsertText := InsertText + 1;
                            end;
                            Index := Index + 1;
                        until Index = 9;
                    end;
            end;
        end;
        OnAfterFormatAddress(AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, LanguageCode);
    end;

    local procedure UpdateAddrArrayForPostCodeCity(var AddrArray: array[8] of Text[100]; Contact: Text[100]; ContLineNo: Integer; Country: Record "Country/Region"; CountryLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; City: Text[50]; PostCode: Code[20]; County: Text[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAddrArrayForPostCodeCity(AddrArray, Contact, ContLineNo, Country, CountryLineNo, PostCodeCityLineNo, CountyLineNo, City, PostCode, County, IsHandled);
        if IsHandled then
            exit;

        AddrArray[ContLineNo] := Contact;
        GeneratePostCodeCity(AddrArray[PostCodeCityLineNo], AddrArray[CountyLineNo], City, PostCode, County, Country);
        AddrArray[CountryLineNo] := Country.Name;
        CompressArray(AddrArray);
    end;

    procedure FormatPostCodeCity(var PostCodeCityText: Text[100]; var CountyText: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10])
    var
        Country: Record "Country/Region";
    begin
        OnBeforeFormatPostCodeCity(Country, CountryCode);
        Clear(PostCodeCityText);
        Clear(CountyText);

        if CountryCode = '' then begin
            GetGLSetup();
            Clear(Country);
            Country."Address Format" := "Country/Region Address Format".FromInteger(GLSetup."Local Address Format");
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            Country.Get(CountryCode);

        if Country."Address Format" = Country."Address Format"::Custom then
            GenerateCustomPostCodeCity(PostCodeCityText, City, PostCode, County, Country)
        else
            GeneratePostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, Country);
    end;

    procedure GeneratePostCodeCity(var PostCodeCityText: Text[100]; var CountyText: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; Country: Record "Country/Region")
    var
        DummyString: Text;
        OverMaxStrLen: Integer;
    begin
        DummyString := '';
        OverMaxStrLen := MaxStrLen(PostCodeCityText);
        if OverMaxStrLen < MaxStrLen(DummyString) then
            OverMaxStrLen += 1;

        case Country."Address Format" of
            Country."Address Format"::"Post Code+City":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := DelStr(PostCode + ' ' + City, OverMaxStrLen)
                    else
                        PostCodeCityText := City;
                    CountyText := County;
                end;
            Country."Address Format"::"City+County+Post Code":
                begin
                    if (County <> '') and (PostCode <> '') then
                        PostCodeCityText :=
                          DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - StrLen(County) - 3) +
                          ', ' + County + ' ' + PostCode
                    else
                        if PostCode = '' then begin
                            PostCodeCityText := City;
                            CountyText := County;
                        end else
                            if (County = '') and (PostCode <> '') then
                                PostCodeCityText := DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ', ' + PostCode;
                end;
            Country."Address Format"::"City+Post Code":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ', ' + PostCode
                    else
                        PostCodeCityText := City;
                    CountyText := County;
                end;
            Country."Address Format"::"Blank Line+Post Code+City":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := DelStr(PostCode + ' ' + City, OverMaxStrLen)
                    else
                        PostCodeCityText := City;
                    CountyText := County;
                end;
        end;

        OnAfterGeneratePostCodeCity(Country, PostCode, PostCodeCityText, City, CountyText, County);
    end;

    local procedure GenerateCustomPostCodeCity(var PostCodeCityText: Text[100]; City: Text[50]; PostCode: Code[20]; County: Text[50]; Country: Record "Country/Region")
    var
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
        PostCodeCityLine: Text;
        CustomAddressFormatLineQty: Integer;
        Counter: Integer;
    begin
        PostCodeCityLine := '';

        CustomAddressFormat.Reset();
        CustomAddressFormat.SetRange("Country/Region Code", Country.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        if not CustomAddressFormat.FindFirst() then
            exit;

        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        CustomAddressFormatLine.SetRange("Country/Region Code", CustomAddressFormat."Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        CustomAddressFormatLineQty := CustomAddressFormatLine.Count();
        if CustomAddressFormatLine.FindSet() then
            repeat
                Counter += 1;
                case CustomAddressFormatLine."Field ID" of
                    CompanyInfo.FieldNo(City):
                        PostCodeCityLine += City;
                    CompanyInfo.FieldNo("Post Code"):
                        PostCodeCityLine += PostCode;
                    CompanyInfo.FieldNo(County):
                        PostCodeCityLine += County;
                end;
                if Counter < CustomAddressFormatLineQty then
                    if CustomAddressFormatLine.Separator <> '' then
                        PostCodeCityLine += CustomAddressFormatLine.Separator
                    else
                        PostCodeCityLine += ' ';
            until CustomAddressFormatLine.Next() = 0;

        PostCodeCityText := DelStr(PostCodeCityLine, MaxStrLen(PostCodeCityText));
    end;

    procedure GetCompanyAddr(RespCenterCode: Code[10]; var ResponsibilityCenter: Record "Responsibility Center"; var CompanyInfo: Record "Company Information"; var CompanyAddr: array[8] of Text[100])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCompanyAddr(RespCenterCode, ResponsibilityCenter, CompanyInfo, CompanyAddr, IsHandled);
        if IsHandled then
            exit;

        if ResponsibilityCenter.Get(RespCenterCode) then begin
            RespCenter(CompanyAddr, ResponsibilityCenter);
            CompanyInfo."Phone No." := ResponsibilityCenter."Phone No.";
            CompanyInfo."Fax No." := ResponsibilityCenter."Fax No.";
            OnGetCompanyAddrOnAfterFillCompanyInfoFromRespCenter(ResponsibilityCenter, CompanyInfo);
        end else
            Company(CompanyAddr, CompanyInfo);
    end;

    procedure Company(var AddrArray: array[8] of Text[100]; var CompanyInfo: Record "Company Information")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCompany(AddrArray, CompanyInfo, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, CompanyInfo.Name, CompanyInfo."Name 2", '', CompanyInfo.Address, CompanyInfo."Address 2",
            CompanyInfo.City, CompanyInfo."Post Code", CompanyInfo.County, '');
    end;

    procedure Customer(var AddrArray: array[8] of Text[100]; var Cust: Record Customer)
    var
        Handled: Boolean;
    begin
        OnBeforeCustomer(AddrArray, Cust, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, Cust.Name, Cust."Name 2", Cust.Contact, Cust.Address, Cust."Address 2",
            Cust.City, Cust."Post Code", Cust.County, Cust."Country/Region Code");
    end;

    procedure Vendor(var AddrArray: array[8] of Text[100]; var Vend: Record Vendor)
    var
        Handled: Boolean;
    begin
        OnBeforeVendor(AddrArray, Vend, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, Vend.Name, Vend."Name 2", Vend.Contact, Vend.Address, Vend."Address 2",
            Vend.City, Vend."Post Code", Vend.County, Vend."Country/Region Code");
    end;

    procedure BankAcc(var AddrArray: array[8] of Text[100]; var BankAcc: Record "Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBankAcc(AddrArray, BankAcc, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
              AddrArray, BankAcc.Name, BankAcc."Name 2", BankAcc.Contact, BankAcc.Address, BankAcc."Address 2",
              BankAcc.City, BankAcc."Post Code", BankAcc.County, BankAcc."Country/Region Code");
    end;


    procedure Location(var AddrArray: array[8] of Text[100]; var Location: Record Location)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLocation(AddrArray, Location, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, Location.Name, Location."Name 2", Location.Contact, Location.Address, Location."Address 2",
            Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
    end;

    procedure SalesHeaderSellTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderSellTo(AddrArray, SalesHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, SalesHeader."Sell-to Customer Name", SalesHeader."Sell-to Customer Name 2", SalesHeader."Sell-to Contact", SalesHeader."Sell-to Address", SalesHeader."Sell-to Address 2",
            SalesHeader."Sell-to City", SalesHeader."Sell-to Post Code", SalesHeader."Sell-to County", SalesHeader."Sell-to Country/Region Code");
    end;

    procedure SalesHeaderBillTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderBillTo(AddrArray, SalesHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, SalesHeader."Bill-to Name", SalesHeader."Bill-to Name 2", SalesHeader."Bill-to Contact", SalesHeader."Bill-to Address", SalesHeader."Bill-to Address 2",
            SalesHeader."Bill-to City", SalesHeader."Bill-to Post Code", SalesHeader."Bill-to County", SalesHeader."Bill-to Country/Region Code");
    end;

    procedure SalesHeaderShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesHeader: Record "Sales Header") Result: Boolean
    var
        CountryRegion: Record "Country/Region";
        SellToCountry: Code[50];
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderShipTo(AddrArray, CustAddr, SalesHeader, Handled, Result);
        if Handled then
            exit(Result);

        FormatAddr(
            AddrArray, SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2", SalesHeader."Ship-to Contact", SalesHeader."Ship-to Address", SalesHeader."Ship-to Address 2",
            SalesHeader."Ship-to City", SalesHeader."Ship-to Post Code", SalesHeader."Ship-to County", SalesHeader."Ship-to Country/Region Code");
        if CountryRegion.Get(SalesHeader."Sell-to Country/Region Code") then
            SellToCountry := CountryRegion.GetTranslatedName(LanguageCode);
        if SalesHeader."Sell-to Customer No." <> SalesHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                exit(true);
        exit(false);
    end;

    procedure PurchHeaderBuyFrom(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderBuyFrom(AddrArray, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchHeader."Buy-from Vendor Name", PurchHeader."Buy-from Vendor Name 2", PurchHeader."Buy-from Contact", PurchHeader."Buy-from Address", PurchHeader."Buy-from Address 2",
            PurchHeader."Buy-from City", PurchHeader."Buy-from Post Code", PurchHeader."Buy-from County", PurchHeader."Buy-from Country/Region Code");
    end;

    procedure PurchHeaderPayTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderPayTo(AddrArray, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchHeader."Pay-to Name", PurchHeader."Pay-to Name 2", PurchHeader."Pay-to Contact", PurchHeader."Pay-to Address", PurchHeader."Pay-to Address 2",
            PurchHeader."Pay-to City", PurchHeader."Pay-to Post Code", PurchHeader."Pay-to County", PurchHeader."Pay-to Country/Region Code");
    end;

    procedure PurchHeaderShipTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderShipTo(AddrArray, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchHeader."Ship-to Name", PurchHeader."Ship-to Name 2", PurchHeader."Ship-to Contact", PurchHeader."Ship-to Address", PurchHeader."Ship-to Address 2",
            PurchHeader."Ship-to City", PurchHeader."Ship-to Post Code", PurchHeader."Ship-to County", PurchHeader."Ship-to Country/Region Code");
    end;

#if not CLEAN22
    [Obsolete('Replaced by PurchHeaderRemitTo with dictionaries.', '22.0')]
    procedure PurchHeaderRemitTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header"): Boolean
    var
        RemitAddress: Record "Remit Address";
    begin
        if PurchHeader."Remit-to Code" <> '' then begin
            RemitAddress.Reset();
            RemitAddress.SetRange("Vendor No.", PurchHeader."Pay-to Vendor No.");
            RemitAddress.SetRange(Code, PurchHeader."Remit-to Code");
            if RemitAddress.IsEmpty() then
                exit(false);

            RemitAddress.FindFirst();
            VendorRemitToAddress(RemitAddress, AddrArray);
        end;
        exit(true);
    end;
#endif

    procedure PurchHeaderRemitTo(var RemitAddressBuffer: Record "Remit Address Buffer"; var PurchHeader: Record "Purchase Header"): Boolean
    var
        RemitAddress: Record "Remit Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderRemitToAddress(RemitAddressBuffer, PurchHeader, IsHandled);
        if IsHandled then
            exit(false);

        if PurchHeader."Remit-to Code" <> '' then begin
            RemitAddress.Reset();
            RemitAddress.SetRange("Vendor No.", PurchHeader."Pay-to Vendor No.");
            RemitAddress.SetRange(Code, PurchHeader."Remit-to Code");
            if RemitAddress.IsEmpty() then
                exit(false);

            RemitAddress.FindFirst();
            VendorRemitToAddress(RemitAddress, RemitAddressBuffer);
        end;
        exit(true);
    end;

    procedure SalesShptSellTo(var AddrArray: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesShptSellTo(AddrArray, SalesShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, SalesShptHeader."Sell-to Customer Name", SalesShptHeader."Sell-to Customer Name 2", SalesShptHeader."Sell-to Contact", SalesShptHeader."Sell-to Address", SalesShptHeader."Sell-to Address 2",
            SalesShptHeader."Sell-to City", SalesShptHeader."Sell-to Post Code", SalesShptHeader."Sell-to County", SalesShptHeader."Sell-to Country/Region Code");
    end;

    procedure SalesShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesShptBillTo(AddrArray, ShipToAddr, SalesShptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, SalesShptHeader."Bill-to Name", SalesShptHeader."Bill-to Name 2", SalesShptHeader."Bill-to Contact", SalesShptHeader."Bill-to Address", SalesShptHeader."Bill-to Address 2",
            SalesShptHeader."Bill-to City", SalesShptHeader."Bill-to Post Code", SalesShptHeader."Bill-to County", SalesShptHeader."Bill-to Country/Region Code");
        if SalesShptHeader."Bill-to Customer No." <> SalesShptHeader."Sell-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if ShipToAddr[i] <> AddrArray[i] then
                exit(true);
        exit(false);
    end;

    procedure SalesShptShipTo(var AddrArray: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesShptShipTo(AddrArray, SalesShptHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, SalesShptHeader."Ship-to Name", SalesShptHeader."Ship-to Name 2", SalesShptHeader."Ship-to Contact", SalesShptHeader."Ship-to Address", SalesShptHeader."Ship-to Address 2",
            SalesShptHeader."Ship-to City", SalesShptHeader."Ship-to Post Code", SalesShptHeader."Ship-to County", SalesShptHeader."Ship-to Country/Region Code");
    end;

    procedure SalesInvSellTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesInvSellTo(AddrArray, SalesInvHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, SalesInvHeader."Sell-to Customer Name", SalesInvHeader."Sell-to Customer Name 2", SalesInvHeader."Sell-to Contact", SalesInvHeader."Sell-to Address", SalesInvHeader."Sell-to Address 2",
            SalesInvHeader."Sell-to City", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to County", SalesInvHeader."Sell-to Country/Region Code");
    end;

    procedure SalesInvBillTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesInvBillTo(AddrArray, SalesInvHeader, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, SalesInvHeader."Bill-to Name", SalesInvHeader."Bill-to Name 2", SalesInvHeader."Bill-to Contact", SalesInvHeader."Bill-to Address", SalesInvHeader."Bill-to Address 2",
            SalesInvHeader."Bill-to City", SalesInvHeader."Bill-to Post Code", SalesInvHeader."Bill-to County", SalesInvHeader."Bill-to Country/Region Code");
    end;

    procedure SalesInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeSalesInvShipTo(AddrArray, SalesInvHeader, IsHandled, Result, CustAddr);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, SalesInvHeader."Ship-to Name", SalesInvHeader."Ship-to Name 2", SalesInvHeader."Ship-to Contact", SalesInvHeader."Ship-to Address", SalesInvHeader."Ship-to Address 2",
            SalesInvHeader."Ship-to City", SalesInvHeader."Ship-to Post Code", SalesInvHeader."Ship-to County", SalesInvHeader."Ship-to Country/Region Code");
        if SalesInvHeader."Sell-to Customer No." <> SalesInvHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure SalesCrMemoSellTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCrMemoSellTo(AddrArray, SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, SalesCrMemoHeader."Sell-to Customer Name", SalesCrMemoHeader."Sell-to Customer Name 2", SalesCrMemoHeader."Sell-to Contact", SalesCrMemoHeader."Sell-to Address", SalesCrMemoHeader."Sell-to Address 2",
            SalesCrMemoHeader."Sell-to City", SalesCrMemoHeader."Sell-to Post Code", SalesCrMemoHeader."Sell-to County", SalesCrMemoHeader."Sell-to Country/Region Code");
    end;

    procedure SalesCrMemoBillTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCrMemoBillTo(AddrArray, SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, SalesCrMemoHeader."Bill-to Name", SalesCrMemoHeader."Bill-to Name 2", SalesCrMemoHeader."Bill-to Contact", SalesCrMemoHeader."Bill-to Address", SalesCrMemoHeader."Bill-to Address 2",
            SalesCrMemoHeader."Bill-to City", SalesCrMemoHeader."Bill-to Post Code", SalesCrMemoHeader."Bill-to County", SalesCrMemoHeader."Bill-to Country/Region Code");
    end;

    procedure SalesCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCrMemoShipTo(AddrArray, CustAddr, SalesCrMemoHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, SalesCrMemoHeader."Ship-to Name", SalesCrMemoHeader."Ship-to Name 2", SalesCrMemoHeader."Ship-to Contact", SalesCrMemoHeader."Ship-to Address", SalesCrMemoHeader."Ship-to Address 2",
            SalesCrMemoHeader."Ship-to City", SalesCrMemoHeader."Ship-to Post Code", SalesCrMemoHeader."Ship-to County", SalesCrMemoHeader."Ship-to Country/Region Code");
        if SalesCrMemoHeader."Sell-to Customer No." <> SalesCrMemoHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure SalesRcptSellTo(var AddrArray: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesRcptSellTo(AddrArray, ReturnRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ReturnRcptHeader."Sell-to Customer Name", ReturnRcptHeader."Sell-to Customer Name 2", ReturnRcptHeader."Sell-to Contact", ReturnRcptHeader."Sell-to Address", ReturnRcptHeader."Sell-to Address 2",
            ReturnRcptHeader."Sell-to City", ReturnRcptHeader."Sell-to Post Code", ReturnRcptHeader."Sell-to County", ReturnRcptHeader."Sell-to Country/Region Code");
    end;

    procedure SalesRcptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesRcptBillTo(AddrArray, ShipToAddr, ReturnRcptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, ReturnRcptHeader."Bill-to Name", ReturnRcptHeader."Bill-to Name 2", ReturnRcptHeader."Bill-to Contact", ReturnRcptHeader."Bill-to Address", ReturnRcptHeader."Bill-to Address 2",
            ReturnRcptHeader."Bill-to City", ReturnRcptHeader."Bill-to Post Code", ReturnRcptHeader."Bill-to County", ReturnRcptHeader."Bill-to Country/Region Code");
        if ReturnRcptHeader."Bill-to Customer No." <> ReturnRcptHeader."Sell-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> ShipToAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure SalesRcptShipTo(var AddrArray: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesRcptShipTo(AddrArray, ReturnRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ReturnRcptHeader."Ship-to Name", ReturnRcptHeader."Ship-to Name 2", ReturnRcptHeader."Ship-to Contact", ReturnRcptHeader."Ship-to Address", ReturnRcptHeader."Ship-to Address 2",
            ReturnRcptHeader."Ship-to City", ReturnRcptHeader."Ship-to Post Code", ReturnRcptHeader."Ship-to County", ReturnRcptHeader."Ship-to Country/Region Code");
    end;

    procedure PurchRcptBuyFrom(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptBuyFrom(AddrArray, PurchRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchRcptHeader."Buy-from Vendor Name", PurchRcptHeader."Buy-from Vendor Name 2", PurchRcptHeader."Buy-from Contact", PurchRcptHeader."Buy-from Address", PurchRcptHeader."Buy-from Address 2",
            PurchRcptHeader."Buy-from City", PurchRcptHeader."Buy-from Post Code", PurchRcptHeader."Buy-from County", PurchRcptHeader."Buy-from Country/Region Code");
    end;

    procedure PurchRcptPayTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptPayTo(AddrArray, PurchRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchRcptHeader."Pay-to Name", PurchRcptHeader."Pay-to Name 2", PurchRcptHeader."Pay-to Contact", PurchRcptHeader."Pay-to Address", PurchRcptHeader."Pay-to Address 2",
            PurchRcptHeader."Pay-to City", PurchRcptHeader."Pay-to Post Code", PurchRcptHeader."Pay-to County", PurchRcptHeader."Pay-to Country/Region Code");
    end;

    procedure PurchRcptShipTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptShipTo(AddrArray, PurchRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchRcptHeader."Ship-to Name", PurchRcptHeader."Ship-to Name 2", PurchRcptHeader."Ship-to Contact", PurchRcptHeader."Ship-to Address", PurchRcptHeader."Ship-to Address 2",
            PurchRcptHeader."Ship-to City", PurchRcptHeader."Ship-to Post Code", PurchRcptHeader."Ship-to County", PurchRcptHeader."Ship-to Country/Region Code");
    end;

    procedure PurchInvBuyFrom(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvBuyFrom(AddrArray, PurchInvHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchInvHeader."Buy-from Vendor Name", PurchInvHeader."Buy-from Vendor Name 2", PurchInvHeader."Buy-from Contact", PurchInvHeader."Buy-from Address", PurchInvHeader."Buy-from Address 2",
            PurchInvHeader."Buy-from City", PurchInvHeader."Buy-from Post Code", PurchInvHeader."Buy-from County", PurchInvHeader."Buy-from Country/Region Code");
    end;

    procedure PurchInvPayTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvPayTo(AddrArray, PurchInvHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchInvHeader."Pay-to Name", PurchInvHeader."Pay-to Name 2", PurchInvHeader."Pay-to Contact", PurchInvHeader."Pay-to Address", PurchInvHeader."Pay-to Address 2",
            PurchInvHeader."Pay-to City", PurchInvHeader."Pay-to Post Code", PurchInvHeader."Pay-to County", PurchInvHeader."Pay-to Country/Region Code");
    end;

    procedure PurchInvShipTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvShipTo(AddrArray, PurchInvHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchInvHeader."Ship-to Name", PurchInvHeader."Ship-to Name 2", PurchInvHeader."Ship-to Contact", PurchInvHeader."Ship-to Address", PurchInvHeader."Ship-to Address 2",
            PurchInvHeader."Ship-to City", PurchInvHeader."Ship-to Post Code", PurchInvHeader."Ship-to County", PurchInvHeader."Ship-to Country/Region Code");
    end;

#if not CLEAN22
    [Obsolete('Replaced by PurchInvRemitTo with dictionaries.', '22.0')]
    procedure PurchInvRemitTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        RemitAddress: Record "Remit Address";
    begin
        if PurchInvHeader."Remit-to Code" <> '' then begin
            RemitAddress.Reset();
            RemitAddress.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
            RemitAddress.SetRange(Code, PurchInvHeader."Remit-to Code");
            if RemitAddress.IsEmpty() then
                exit(false);

            RemitAddress.FindFirst();
            VendorRemitToAddress(RemitAddress, AddrArray);
        end;
        exit(true);
    end;
#endif

    procedure PurchInvRemitTo(var RemitAddressBuffer: Record "Remit Address Buffer"; var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        RemitAddress: Record "Remit Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvRemitToAddress(RemitAddressBuffer, PurchInvHeader, IsHandled);
        if IsHandled then
            exit(false);

        if PurchInvHeader."Remit-to Code" <> '' then begin
            RemitAddress.Reset();
            RemitAddress.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
            RemitAddress.SetRange(Code, PurchInvHeader."Remit-to Code");
            if RemitAddress.IsEmpty() then
                exit(false);

            RemitAddress.FindFirst();
            VendorRemitToAddress(RemitAddress, RemitAddressBuffer);
        end;
        exit(true);
    end;

    procedure PurchCrMemoBuyFrom(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCrMemoBuyFrom(AddrArray, PurchCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchCrMemoHeader."Buy-from Vendor Name", PurchCrMemoHeader."Buy-from Vendor Name 2", PurchCrMemoHeader."Buy-from Contact", PurchCrMemoHeader."Buy-from Address", PurchCrMemoHeader."Buy-from Address 2",
            PurchCrMemoHeader."Buy-from City", PurchCrMemoHeader."Buy-from Post Code", PurchCrMemoHeader."Buy-from County", PurchCrMemoHeader."Buy-from Country/Region Code");
    end;

    procedure PurchCrMemoPayTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCrMemoPayTo(AddrArray, PurchCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchCrMemoHeader."Pay-to Name", PurchCrMemoHeader."Pay-to Name 2", PurchCrMemoHeader."Pay-to Contact", PurchCrMemoHeader."Pay-to Address", PurchCrMemoHeader."Pay-to Address 2",
            PurchCrMemoHeader."Pay-to City", PurchCrMemoHeader."Pay-to Post Code", PurchCrMemoHeader."Pay-to County", PurchCrMemoHeader."Pay-to Country/Region Code");
    end;

    procedure PurchCrMemoShipTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCrMemoShipTo(AddrArray, PurchCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchCrMemoHeader."Ship-to Name", PurchCrMemoHeader."Ship-to Name 2", PurchCrMemoHeader."Ship-to Contact", PurchCrMemoHeader."Ship-to Address", PurchCrMemoHeader."Ship-to Address 2",
            PurchCrMemoHeader."Ship-to City", PurchCrMemoHeader."Ship-to Post Code", PurchCrMemoHeader."Ship-to County", PurchCrMemoHeader."Ship-to Country/Region Code");
    end;

    procedure PurchShptBuyFrom(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchShptBuyFrom(AddrArray, ReturnShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ReturnShptHeader."Buy-from Vendor Name", ReturnShptHeader."Buy-from Vendor Name 2", ReturnShptHeader."Buy-from Contact", ReturnShptHeader."Buy-from Address", ReturnShptHeader."Buy-from Address 2",
            ReturnShptHeader."Buy-from City", ReturnShptHeader."Buy-from Post Code", ReturnShptHeader."Buy-from County", ReturnShptHeader."Buy-from Country/Region Code");
    end;

    procedure PurchShptPayTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchShptPayTo(AddrArray, ReturnShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ReturnShptHeader."Pay-to Name", ReturnShptHeader."Pay-to Name 2", ReturnShptHeader."Pay-to Contact", ReturnShptHeader."Pay-to Address", ReturnShptHeader."Pay-to Address 2",
            ReturnShptHeader."Pay-to City", ReturnShptHeader."Pay-to Post Code", ReturnShptHeader."Pay-to County", ReturnShptHeader."Pay-to Country/Region Code");
    end;

    procedure PurchShptShipTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchShptShipTo(AddrArray, ReturnShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ReturnShptHeader."Ship-to Name", ReturnShptHeader."Ship-to Name 2", ReturnShptHeader."Ship-to Contact", ReturnShptHeader."Ship-to Address", ReturnShptHeader."Ship-to Address 2",
            ReturnShptHeader."Ship-to City", ReturnShptHeader."Ship-to Post Code", ReturnShptHeader."Ship-to County", ReturnShptHeader."Ship-to Country/Region Code");
    end;

    procedure AltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee; var AlternativeAddr: Record "Alternative Address")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAltAddr(AddrArray, Employee, AlternativeAddr, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, CopyStr(Employee.FullName(), 1, 50), '', '', AlternativeAddr.Address,
            AlternativeAddr."Address 2", AlternativeAddr.City, AlternativeAddr."Post Code", AlternativeAddr.County, AlternativeAddr."Country/Region Code");
    end;

    procedure Employee(var AddrArray: array[8] of Text[100]; var Employee: Record Employee)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEmployee(AddrArray, Employee, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, CopyStr(Employee.FullName(), 1, 50), '', '', Employee.Address, Employee."Address 2",
            Employee.City, Employee."Post Code", Employee.County, Employee."Country/Region Code");
    end;

    procedure EmployeeAltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee)
    var
        AlternativeAddr: Record "Alternative Address";
    begin
        AlternativeAddr.Get(Employee."No.", Employee."Alt. Address Code");
        FormatAddr(
            AddrArray, CopyStr(Employee.FullName(), 1, 50), '', '', AlternativeAddr.Address,
            AlternativeAddr."Address 2", AlternativeAddr.City, AlternativeAddr."Post Code", AlternativeAddr.County, AlternativeAddr."Country/Region Code");
    end;

    procedure VendBankAcc(var AddrArray: array[8] of Text[100]; var VendBankAcc: Record "Vendor Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendBankAcc(AddrArray, VendBankAcc, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, VendBankAcc.Name, VendBankAcc."Name 2", VendBankAcc.Contact, VendBankAcc.Address, VendBankAcc."Address 2",
            VendBankAcc.City, VendBankAcc."Post Code", VendBankAcc.County, VendBankAcc."Country/Region Code");
    end;

    procedure CustBankAcc(var AddrArray: array[8] of Text[100]; var CustBankAcc: Record "Customer Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustBankAcc(AddrArray, CustBankAcc, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, CustBankAcc.Name, CustBankAcc."Name 2", CustBankAcc.Contact, CustBankAcc.Address, CustBankAcc."Address 2",
            CustBankAcc.City, CustBankAcc."Post Code", CustBankAcc.County, CustBankAcc."Country/Region Code");
    end;

    procedure RespCenter(var AddrArray: array[8] of Text[100]; var RespCenter: Record "Responsibility Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRespCenter(AddrArray, RespCenter, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, RespCenter.Name, RespCenter."Name 2", RespCenter.Contact, RespCenter.Address, RespCenter."Address 2",
            RespCenter.City, RespCenter."Post Code", RespCenter.County, RespCenter."Country/Region Code");
    end;

    procedure TransferShptTransferFrom(var AddrArray: array[8] of Text[100]; var TransShptHeader: Record "Transfer Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferShptTransferFrom(AddrArray, TransShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray,
            TransShptHeader."Transfer-from Name", TransShptHeader."Transfer-from Name 2", TransShptHeader."Transfer-from Contact", TransShptHeader."Transfer-from Address", TransShptHeader."Transfer-from Address 2",
            TransShptHeader."Transfer-from City", TransShptHeader."Transfer-from Post Code", TransShptHeader."Transfer-from County", TransShptHeader."Trsf.-from Country/Region Code");
    end;

    procedure TransferShptTransferTo(var AddrArray: array[8] of Text[100]; var TransShptHeader: Record "Transfer Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferShptTransferTo(AddrArray, TransShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, TransShptHeader."Transfer-to Name", TransShptHeader."Transfer-to Name 2", TransShptHeader."Transfer-to Contact", TransShptHeader."Transfer-to Address", TransShptHeader."Transfer-to Address 2",
            TransShptHeader."Transfer-to City", TransShptHeader."Transfer-to Post Code", TransShptHeader."Transfer-to County", TransShptHeader."Trsf.-to Country/Region Code");
    end;

    procedure TransferRcptTransferFrom(var AddrArray: array[8] of Text[100]; var TransRcptHeader: Record "Transfer Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferRcptTransferFrom(AddrArray, TransRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray,
            TransRcptHeader."Transfer-from Name", TransRcptHeader."Transfer-from Name 2", TransRcptHeader."Transfer-from Contact", TransRcptHeader."Transfer-from Address", TransRcptHeader."Transfer-from Address 2",
            TransRcptHeader."Transfer-from City", TransRcptHeader."Transfer-from Post Code", TransRcptHeader."Transfer-from County", TransRcptHeader."Trsf.-from Country/Region Code");
    end;

    procedure TransferRcptTransferTo(var AddrArray: array[8] of Text[100]; var TransRcptHeader: Record "Transfer Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferRcptTransferTo(AddrArray, TransRcptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, TransRcptHeader."Transfer-to Name", TransRcptHeader."Transfer-to Name 2", TransRcptHeader."Transfer-to Contact", TransRcptHeader."Transfer-to Address", TransRcptHeader."Transfer-to Address 2",
            TransRcptHeader."Transfer-to City", TransRcptHeader."Transfer-to Post Code", TransRcptHeader."Transfer-to County", TransRcptHeader."Trsf.-to Country/Region Code");
    end;

    procedure TransferHeaderTransferFrom(var AddrArray: array[8] of Text[100]; var TransHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferHeaderTransferFrom(AddrArray, TransHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray,
            TransHeader."Transfer-from Name", TransHeader."Transfer-from Name 2", TransHeader."Transfer-from Contact", TransHeader."Transfer-from Address", TransHeader."Transfer-from Address 2",
            TransHeader."Transfer-from City", TransHeader."Transfer-from Post Code", TransHeader."Transfer-from County", TransHeader."Trsf.-from Country/Region Code");
    end;

    procedure TransferHeaderTransferTo(var AddrArray: array[8] of Text[100]; var TransHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferHeaderTransferTo(AddrArray, TransHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, TransHeader."Transfer-to Name", TransHeader."Transfer-to Name 2", TransHeader."Transfer-to Contact", TransHeader."Transfer-to Address", TransHeader."Transfer-to Address 2",
            TransHeader."Transfer-to City", TransHeader."Transfer-to Post Code", TransHeader."Transfer-to County", TransHeader."Trsf.-to Country/Region Code");
    end;

    procedure ContactAddr(var AddrArray: array[8] of Text[100]; var Cont: Record Contact)
    begin
        ContactAddrAlt(AddrArray, Cont, Cont.ActiveAltAddress(WorkDate()), WorkDate())
    end;

    procedure ContactAddrAlt(var AddrArray: array[8] of Text[100]; var Cont: Record Contact; AltAddressCode: Code[10]; ActiveDate: Date)
    var
        RMSetup: Record "Marketing Setup";
        ContCompany: Record Contact;
        ContAltAddr: Record "Contact Alt. Address";
        CompanyAltAddressCode: Code[10];
        ContIdenticalAddress: Boolean;
        Handled: Boolean;
    begin
        OnBeforeContactAddrAlt(AddrArray, Cont, AltAddressCode, ActiveDate, Handled);
        if Handled then
            exit;

        RMSetup.Get();

        if (Cont.Type = Cont.Type::Person) and (Cont."Company No." <> '') then begin
            ContCompany.Get(Cont."Company No.");
            CompanyAltAddressCode := ContCompany.ActiveAltAddress(ActiveDate);
            ContIdenticalAddress := Cont.IdenticalAddress(ContCompany);
        end;

        case true of
            AltAddressCode <> '':
                begin
                    ContAltAddr.Get(Cont."No.", AltAddressCode);
                    FormatAddr(
                      AddrArray, ContAltAddr."Company Name", ContAltAddr."Company Name 2", Cont.Name, ContAltAddr.Address, ContAltAddr."Address 2",
                      ContAltAddr.City, ContAltAddr."Post Code", ContAltAddr.County, ContAltAddr."Country/Region Code");
                end;
            (Cont.Type = Cont.Type::Person) and
          (Cont."Company No." <> '') and
          (CompanyAltAddressCode <> '') and
          RMSetup."Inherit Address Details" and
          ContIdenticalAddress:
                begin
                    ContAltAddr.Get(Cont."Company No.", CompanyAltAddressCode);
                    FormatAddr(
                      AddrArray, ContAltAddr."Company Name", ContAltAddr."Company Name 2", Cont.Name, ContAltAddr.Address, ContAltAddr."Address 2",
                      ContAltAddr.City, ContAltAddr."Post Code", ContAltAddr.County, ContAltAddr."Country/Region Code");
                end;
            (Cont.Type = Cont.Type::Person) and
          (Cont."Company No." <> ''):
                FormatCompanyContactAddr(AddrArray, Cont, ContCompany)
            else
                FormatPersonContactAddr(AddrArray, Cont);
        end;
    end;

    local procedure FormatCompanyContactAddr(var AddrArray: array[8] of Text[100]; Cont: Record Contact; ContCompany: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatCompanyContactAddr(AddrArray, Cont, ContCompany, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ContCompany.Name, ContCompany."Name 2", Cont.Name, Cont.Address, Cont."Address 2",
            Cont.City, Cont."Post Code", Cont.County, Cont."Country/Region Code");
    end;

    local procedure FormatPersonContactAddr(var AddrArray: array[8] of Text[100]; Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatPersonContactAddr(AddrArray, Cont, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, Cont.Name, Cont."Name 2", '', Cont.Address, Cont."Address 2",
            Cont.City, Cont."Post Code", Cont.County, Cont."Country/Region Code");
    end;

    procedure ServiceOrderSellto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceOrderSellto(AddrArray, ServHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServHeader.Name, ServHeader."Name 2", ServHeader."Contact Name", ServHeader.Address, ServHeader."Address 2",
            ServHeader.City, ServHeader."Post Code", ServHeader.County, ServHeader."Country/Region Code");
    end;

    procedure ServiceOrderShipto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceOrderShipto(AddrArray, ServHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServHeader."Ship-to Name", ServHeader."Ship-to Name 2", ServHeader."Ship-to Contact", ServHeader."Ship-to Address", ServHeader."Ship-to Address 2",
            ServHeader."Ship-to City", ServHeader."Ship-to Post Code", ServHeader."Ship-to County", ServHeader."Ship-to Country/Region Code");
    end;

    procedure ServContractSellto(var AddrArray: array[8] of Text[100]; ServContract: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServContractSellto(AddrArray, ServContract, IsHandled);
        if IsHandled then
            exit;

        ServContract.CalcFields(Name, "Name 2", Address, "Address 2", "Post Code", City, County, "Country/Region Code");
        FormatAddr(
          AddrArray, ServContract.Name, ServContract."Name 2", ServContract."Contact Name", ServContract.Address, ServContract."Address 2",
          ServContract.City, ServContract."Post Code", ServContract.County, ServContract."Country/Region Code");
    end;

    procedure ServContractShipto(var AddrArray: array[8] of Text[100]; ServiceContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        ServiceContractHeader.CalcFields(
            "Ship-to Name", "Ship-to Name 2", "Ship-to Address", "Ship-to Address 2",
            "Ship-to Post Code", "Ship-to City", "Ship-to County", "Ship-to Country/Region Code");

        IsHandled := false;
        OnBeforeServContractShipTo(AddrArray, ServiceContractHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
          AddrArray, ServiceContractHeader."Ship-to Name", ServiceContractHeader."Ship-to Name 2", ServiceContractHeader."Contact Name", ServiceContractHeader."Ship-to Address", ServiceContractHeader."Ship-to Address 2",
          ServiceContractHeader."Ship-to City", ServiceContractHeader."Ship-to Post Code", ServiceContractHeader."Ship-to County", ServiceContractHeader."Ship-to Country/Region Code");
    end;

    procedure ServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceInvBillTo(AddrArray, ServiceInvHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceInvHeader."Bill-to Name", ServiceInvHeader."Bill-to Name 2", ServiceInvHeader."Bill-to Contact", ServiceInvHeader."Bill-to Address", ServiceInvHeader."Bill-to Address 2",
            ServiceInvHeader."Bill-to City", ServiceInvHeader."Bill-to Post Code", ServiceInvHeader."Bill-to County", ServiceInvHeader."Bill-to Country/Region Code");
    end;

    procedure ServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceInvShipTo(AddrArray, CustAddr, ServiceInvHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, ServiceInvHeader."Ship-to Name", ServiceInvHeader."Ship-to Name 2", ServiceInvHeader."Ship-to Contact", ServiceInvHeader."Ship-to Address", ServiceInvHeader."Ship-to Address 2",
            ServiceInvHeader."Ship-to City", ServiceInvHeader."Ship-to Post Code", ServiceInvHeader."Ship-to County", ServiceInvHeader."Ship-to Country/Region Code");
        if ServiceInvHeader."Customer No." <> ServiceInvHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure ServiceShptShipTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptShipTo(AddrArray, ServiceShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceShptHeader."Ship-to Name", ServiceShptHeader."Ship-to Name 2", ServiceShptHeader."Ship-to Contact", ServiceShptHeader."Ship-to Address", ServiceShptHeader."Ship-to Address 2",
            ServiceShptHeader."Ship-to City", ServiceShptHeader."Ship-to Post Code", ServiceShptHeader."Ship-to County", ServiceShptHeader."Ship-to Country/Region Code");
    end;

    procedure ServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptSellTo(AddrArray, ServiceShptHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceShptHeader.Name, ServiceShptHeader."Name 2", ServiceShptHeader."Contact Name", ServiceShptHeader.Address, ServiceShptHeader."Address 2",
            ServiceShptHeader.City, ServiceShptHeader."Post Code", ServiceShptHeader.County, ServiceShptHeader."Country/Region Code");
    end;

    procedure ServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptBillTo(AddrArray, ShipToAddr, ServiceShptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, ServiceShptHeader."Bill-to Name", ServiceShptHeader."Bill-to Name 2", ServiceShptHeader."Bill-to Contact", ServiceShptHeader."Bill-to Address", ServiceShptHeader."Bill-to Address 2",
            ServiceShptHeader."Bill-to City", ServiceShptHeader."Bill-to Post Code", ServiceShptHeader."Bill-to County", ServiceShptHeader."Bill-to Country/Region Code");
        if ServiceShptHeader."Bill-to Customer No." <> ServiceShptHeader."Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if ShipToAddr[i] <> AddrArray[i] then
                exit(true);
        exit(false);
    end;

    procedure ServiceCrMemoBillTo(var AddrArray: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceCrMemoBillTo(AddrArray, ServiceCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceCrMemoHeader."Bill-to Name", ServiceCrMemoHeader."Bill-to Name 2", ServiceCrMemoHeader."Bill-to Contact", ServiceCrMemoHeader."Bill-to Address", ServiceCrMemoHeader."Bill-to Address 2",
            ServiceCrMemoHeader."Bill-to City", ServiceCrMemoHeader."Bill-to Post Code", ServiceCrMemoHeader."Bill-to County", ServiceCrMemoHeader."Bill-to Country/Region Code");
    end;

    procedure ServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceCrMemoShipTo(AddrArray, CustAddr, ServiceCrMemoHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, ServiceCrMemoHeader."Ship-to Name", ServiceCrMemoHeader."Ship-to Name 2", ServiceCrMemoHeader."Ship-to Contact", ServiceCrMemoHeader."Ship-to Address", ServiceCrMemoHeader."Ship-to Address 2",
            ServiceCrMemoHeader."Ship-to City", ServiceCrMemoHeader."Ship-to Post Code", ServiceCrMemoHeader."Ship-to County", ServiceCrMemoHeader."Ship-to Country/Region Code");
        if ServiceCrMemoHeader."Customer No." <> ServiceCrMemoHeader."Bill-to Customer No." then
            exit(true);
        for i := 1 to ArrayLen(AddrArray) do
            if AddrArray[i] <> CustAddr[i] then
                exit(true);
        exit(false);
    end;

    procedure ServiceHeaderSellTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderSellTo(AddrArray, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceHeader.Name, ServiceHeader."Name 2", ServiceHeader."Contact Name", ServiceHeader.Address, ServiceHeader."Address 2",
            ServiceHeader.City, ServiceHeader."Post Code", ServiceHeader.County, ServiceHeader."Country/Region Code");
    end;

    procedure ServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderBillTo(AddrArray, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceHeader."Bill-to Name", ServiceHeader."Bill-to Name 2", ServiceHeader."Bill-to Contact", ServiceHeader."Bill-to Address", ServiceHeader."Bill-to Address 2",
            ServiceHeader."Bill-to City", ServiceHeader."Bill-to Post Code", ServiceHeader."Bill-to County", ServiceHeader."Bill-to Country/Region Code");
    end;

    procedure ServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderShipTo(AddrArray, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ServiceHeader."Ship-to Name", ServiceHeader."Ship-to Name 2", ServiceHeader."Ship-to Contact", ServiceHeader."Ship-to Address", ServiceHeader."Ship-to Address 2",
            ServiceHeader."Ship-to City", ServiceHeader."Ship-to Post Code", ServiceHeader."Ship-to County", ServiceHeader."Ship-to Country/Region Code");
    end;

    procedure PostalBarCode(AddressType: Option): Text[100]
    begin
        if AddressType = AddressType then
            exit('');
        exit('');
    end;

    procedure SalesHeaderArchBillTo(var AddrArray: array[8] of Text[100]; var SalesHeaderArch: Record "Sales Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderArchBillTo(AddrArray, SalesHeaderArch, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, SalesHeaderArch."Bill-to Name", SalesHeaderArch."Bill-to Name 2", SalesHeaderArch."Bill-to Contact", SalesHeaderArch."Bill-to Address", SalesHeaderArch."Bill-to Address 2",
            SalesHeaderArch."Bill-to City", SalesHeaderArch."Bill-to Post Code", SalesHeaderArch."Bill-to County", SalesHeaderArch."Bill-to Country/Region Code");
    end;

    procedure SalesHeaderArchShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesHeaderArch: Record "Sales Header Archive") Result: Boolean
    var
        CountryRegion: Record "Country/Region";
        SellToCountry: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderArchShipTo(AddrArray, CustAddr, SalesHeaderArch, IsHandled, Result);
        if IsHandled then
            exit(Result);

        FormatAddr(
            AddrArray, SalesHeaderArch."Ship-to Name", SalesHeaderArch."Ship-to Name 2", SalesHeaderArch."Ship-to Contact", SalesHeaderArch."Ship-to Address", SalesHeaderArch."Ship-to Address 2",
            SalesHeaderArch."Ship-to City", SalesHeaderArch."Ship-to Post Code", SalesHeaderArch."Ship-to County", SalesHeaderArch."Ship-to Country/Region Code");
        if SalesHeaderArch."Sell-to Customer No." <> SalesHeaderArch."Bill-to Customer No." then
            exit(true);
        if CountryRegion.Get(SalesHeaderArch."Sell-to Country/Region Code") then
            SellToCountry := CountryRegion.GetTranslatedName(LanguageCode);
        for i := 1 to ArrayLen(AddrArray) do
            if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                exit(true);
        exit(false);
    end;

    procedure PurchHeaderBuyFromArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderBuyFromArch(AddrArray, PurchHeaderArch, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchHeaderArch."Buy-from Vendor Name", PurchHeaderArch."Buy-from Vendor Name 2", PurchHeaderArch."Buy-from Contact", PurchHeaderArch."Buy-from Address", PurchHeaderArch."Buy-from Address 2",
            PurchHeaderArch."Buy-from City", PurchHeaderArch."Buy-from Post Code", PurchHeaderArch."Buy-from County", PurchHeaderArch."Buy-from Country/Region Code");
    end;

    procedure PurchHeaderPayToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderPayToArch(AddrArray, PurchHeaderArch, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchHeaderArch."Pay-to Name", PurchHeaderArch."Pay-to Name 2", PurchHeaderArch."Pay-to Contact", PurchHeaderArch."Pay-to Address", PurchHeaderArch."Pay-to Address 2",
            PurchHeaderArch."Pay-to City", PurchHeaderArch."Pay-to Post Code", PurchHeaderArch."Pay-to County", PurchHeaderArch."Pay-to Country/Region Code");
    end;

    procedure PurchHeaderShipToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderShipToArch(AddrArray, PurchHeaderArch, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, PurchHeaderArch."Ship-to Name", PurchHeaderArch."Ship-to Name 2", PurchHeaderArch."Ship-to Contact", PurchHeaderArch."Ship-to Address", PurchHeaderArch."Ship-to Address 2",
            PurchHeaderArch."Ship-to City", PurchHeaderArch."Ship-to Post Code", PurchHeaderArch."Ship-to County", PurchHeaderArch."Ship-to Country/Region Code");
    end;

    procedure Reminder(var AddrArray: array[8] of Text[100]; var ReminderHeader: Record "Reminder Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReminder(AddrArray, ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, ReminderHeader.Name, ReminderHeader."Name 2", ReminderHeader.Contact, ReminderHeader.Address, ReminderHeader."Address 2", ReminderHeader.City, ReminderHeader."Post Code", ReminderHeader.County, ReminderHeader."Country/Region Code");
    end;

    procedure IssuedReminder(var AddrArray: array[8] of Text[100]; var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedReminder(AddrArray, IssuedReminderHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, IssuedReminderHeader.Name, IssuedReminderHeader."Name 2", IssuedReminderHeader.Contact, IssuedReminderHeader.Address, IssuedReminderHeader."Address 2", IssuedReminderHeader.City, IssuedReminderHeader."Post Code", IssuedReminderHeader.County, IssuedReminderHeader."Country/Region Code");
    end;

    procedure FinanceChargeMemo(var AddrArray: array[8] of Text[100]; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinanceChargeMemo(AddrArray, FinanceChargeMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, FinanceChargeMemoHeader.Name, FinanceChargeMemoHeader."Name 2", FinanceChargeMemoHeader.Contact, FinanceChargeMemoHeader.Address, FinanceChargeMemoHeader."Address 2", FinanceChargeMemoHeader.City, FinanceChargeMemoHeader."Post Code", FinanceChargeMemoHeader.County, FinanceChargeMemoHeader."Country/Region Code");
    end;

    procedure IssuedFinanceChargeMemo(var AddrArray: array[8] of Text[100]; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedFinanceChargeMemo(AddrArray, IssuedFinChargeMemoHeader, IsHandled);
        if IsHandled then
            exit;

        FormatAddr(
            AddrArray, IssuedFinChargeMemoHeader.Name, IssuedFinChargeMemoHeader."Name 2", IssuedFinChargeMemoHeader.Contact, IssuedFinChargeMemoHeader.Address, IssuedFinChargeMemoHeader."Address 2", IssuedFinChargeMemoHeader.City, IssuedFinChargeMemoHeader."Post Code", IssuedFinChargeMemoHeader.County, IssuedFinChargeMemoHeader."Country/Region Code");
    end;

    procedure JobBillTo(var AddrArray: array[8] of Text[100]; var Job: Record Job)
    var
        Handled: Boolean;
    begin
        OnBeforeJobBillTo(AddrArray, Job, Handled);
        if Handled then
            exit;

        FormatAddr(
            AddrArray, Job."Bill-to Name", Job."Bill-to Name 2", Job."Bill-to Contact", Job."Bill-to Address", Job."Bill-to Address 2",
            Job."Bill-to City", Job."Bill-to Post Code", Job."Bill-to County", Job."Bill-to Country/Region Code");
    end;

#if not CLEAN22
    [Obsolete('Replaced by VendorRemitToAddress.', '22.0')]
    procedure VendorRemitToAddress(var AddrArray: array[8] of Text[100]; var RemitAddress: Record "Remit Address")
    begin
        VendorRemitToAddress(RemitAddress, AddrArray);
    end;
#endif

    procedure VendorRemitToAddress(var RemitAddress: Record "Remit Address"; var ArrayAddress: array[8] of Text[100])
    var
        RemitAddressBuffer: Record "Remit Address Buffer";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendorRemitToAddress(ArrayAddress, RemitAddress, IsHandled);
        if IsHandled then
            exit;

        VendorRemitToAddress(RemitAddress, RemitAddressBuffer);

        FormatAddr(
            ArrayAddress,
            RemitAddressBuffer.Name,
            RemitAddress."Name 2",
            RemitAddress.Contact,
            RemitAddress.Address,
            RemitAddress."Address 2",
            RemitAddress.City,
            RemitAddress."Post Code",
            RemitAddress.County,
            RemitAddressBuffer."Country/Region Code");
    end;

    procedure VendorRemitToAddress(var RemitAddress: Record "Remit Address"; var RemitAddressBuffer: Record "Remit Address Buffer")
    begin
        RemitAddressBuffer.Name := RemitAddress.Name;
        RemitAddressBuffer.Address := RemitAddress.Address;
        RemitAddressBuffer."Address 2" := RemitAddress."Address 2";
        RemitAddressBuffer.City := RemitAddress.City;
        RemitAddressBuffer.County := RemitAddress.County;
        RemitAddressBuffer."Post Code" := RemitAddress."Post Code";
        RemitAddressBuffer."Country/Region Code" := RemitAddress."Country/Region Code";
        RemitAddressBuffer.Contact := RemitAddress.Contact;
    end;

    procedure UseCounty(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        OnBeforeUseCounty(CountryCode, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        if CountryCode = '' then begin
            GetGLSetup();
            case true of
                GLSetup."Local Address Format" = GLSetup."Local Address Format"::"City+County+Post Code":
                    exit(true);
                CustomAddressFormat.UseCounty(''):
                    exit(true);
            end;
        end;

        if CountryRegion.Get(CountryCode) then
            case true of
                CountryRegion."Address Format" = CountryRegion."Address Format"::"City+County+Post Code":
                    exit(true);
                CustomAddressFormat.UseCounty(CountryCode):
                    exit(true);
            end;

        exit(false);
    end;

    local procedure SetLineNos(Country: Record "Country/Region"; var NameLineNo: Integer; var Name2LineNo: Integer; var AddrLineNo: Integer; var Addr2LineNo: Integer; var ContLineNo: Integer; var PostCodeCityLineNo: Integer; var CountyLineNo: Integer; var CountryLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLineNos(Country, NameLineNo, Name2LineNo, AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo, IsHandled);
        if IsHandled then
            exit;

        case Country."Contact Address Format" of
            Country."Contact Address Format"::First:
                begin
                    NameLineNo := 2;
                    Name2LineNo := 3;
                    ContLineNo := 1;
                    AddrLineNo := 4;
                    Addr2LineNo := 5;
                    PostCodeCityLineNo := 6;
                    CountyLineNo := 7;
                    CountryLineNo := 8;
                end;
            Country."Contact Address Format"::"After Company Name":
                begin
                    NameLineNo := 1;
                    Name2LineNo := 2;
                    ContLineNo := 3;
                    AddrLineNo := 4;
                    Addr2LineNo := 5;
                    PostCodeCityLineNo := 6;
                    CountyLineNo := 7;
                    CountryLineNo := 8;
                end;
            Country."Contact Address Format"::Last:
                begin
                    NameLineNo := 1;
                    Name2LineNo := 2;
                    ContLineNo := 8;
                    AddrLineNo := 3;
                    Addr2LineNo := 4;
                    PostCodeCityLineNo := 5;
                    CountyLineNo := 6;
                    CountryLineNo := 7;
                end;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;
        GLSetupRead := true;
        GLSetup.Get();
    end;


    procedure SetLanguageCode(NewLanguageCode: Code[10])
    begin
        LanguageCode := NewLanguageCode;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupModify()
    begin
        GLSetupRead := false;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompany(var AddrArray: array[8] of Text[100]; var CompanyInfo: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCompanyAddr(RespCenterCode: Code[10]; var ResponsibilityCenter: Record "Responsibility Center"; var CompanyInfo: Record "Company Information"; var CompanyAddr: array[8] of Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatAddress(var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; LanguageCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGeneratePostCodeCity(var Country: Record "Country/Region"; var PostCode: Code[20]; var PostCodeCityText: Text[100]; var City: Text[50]; var CountyText: Text[50]; var County: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAcc(var AddrArray: array[8] of Text[100]; var BankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLocation(var AddrArray: array[8] of Text[100]; var Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee; var AlternativeAddress: Record "Alternative Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmployee(var AddrArray: array[8] of Text[100]; var Employee: Record Employee; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactAddrAlt(var AddrArray: array[8] of Text[100]; var Cont: Record Contact; AltAddressCode: Code[10]; ActiveDate: Date; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomer(var AddrArray: array[8] of Text[100]; var Cust: Record Customer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustBankAcc(var AddrArray: array[8] of Text[100]; var CustomerBankAccount: Record "Customer Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatAddress(Country: Record "Country/Region"; var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; NameLineNo: Integer; Name2LineNo: Integer; AddrLineNo: Integer; Addr2LineNo: Integer; ContLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; CountryLineNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatAddr(var Country: Record "Country/Region"; var CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatPostCodeCity(var Country: Record "Country/Region"; var CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatCompanyContactAddr(var AddrArray: array[8] of Text[100]; Cont: Record Contact; ContCompany: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatPersonContactAddr(var AddrArray: array[8] of Text[100]; Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinanceChargeMemo(var AddrArray: array[8] of Text[100]; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedFinanceChargeMemo(var AddrArray: array[8] of Text[100]; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedReminder(var AddrArray: array[8] of Text[100]; var IssuedReminderHeader: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderBuyFromArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderPayToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderShipToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderBuyFrom(var AddrArray: array[8] of Text[100]; var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderPayTo(var AddrArray: array[8] of Text[100]; var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptBuyFrom(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptPayTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchRcptShipTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvBuyFrom(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvPayTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvShipTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN22
    [Obsolete('Replaced by OnBeforePurchInvRemitToAddress.', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvRemitTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvRemitToAddress(var RemitAddressBuffer: Record "Remit Address Buffer"; var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoBuyFrom(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoPayTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoShipTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchShptBuyFrom(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchShptPayTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReminder(var AddrArray: array[8] of Text[100]; var ReminderHeader: Record "Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRespCenter(var AddrArray: array[8] of Text[100]; var RespCenter: Record "Responsibility Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchShptShipTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderArchBillTo(var AddrArray: array[8] of Text[100]; var SalesHeaderArch: Record "Sales Header Archive"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderArchShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesHeaderArch: Record "Sales Header Archive"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderBillTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderSellTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderShipTo(var AddrArray: array[8] of Text[100]; var CustAddr: array[8] of Text[100]; var SalesHeader: Record "Sales Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvBillTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvShipTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header"; var Handled: Boolean; var Result: Boolean; var CustAddr: array[8] of Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoBillTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoSellTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoShipTo(var AddrArray: array[8] of Text[100]; var CustAddr: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptShipTo(var AddrArray: array[8] of Text[100]; var SalesShipmentHeader: Record "Sales Shipment Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptBillTo(var AddrArray: array[8] of Text[100]; var ShipToAddr: array[8] of Text[100]; var SalesShipmentHeader: Record "Sales Shipment Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptSellTo(var AddrArray: array[8] of Text[100]; var SalesShipmentHeader: Record "Sales Shipment Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesRcptSellTo(var AddrArray: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesRcptShipTo(var AddrArray: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesRcptBillTo(var AddrArray: array[8] of Text[100]; var ShipToAddr: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvSellTo(var AddrArray: array[8] of Text[100]; var SalesInvoiceHeader: Record "Sales Invoice Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderShipTo(var AddrArray: array[8] of Text[100]; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN22
    [Obsolete('Replaced by OnBeforePurchHeaderRemitToAddress.', '22.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderRemitTo(var AddrArray: array[8] of Text[100]; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderRemitToAddress(var RemitAddressBuffer: Record "Remit Address Buffer"; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractShipTo(var AddrArray: array[8] of Text[100]; var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractSellto(var AddrArray: array[8] of Text[100]; var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoBillTo(var AddrArray: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderSellTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceOrderSellto(var AddrArray: array[8] of Text[100]; var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceOrderShipto(var AddrArray: array[8] of Text[100]; var ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptShipTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineNos(Country: Record "Country/Region"; var NameLineNo: Integer; var Name2LineNo: Integer; var AddrLineNo: Integer; var Addr2LineNo: Integer; var ContLineNo: Integer; var PostCodeCityLineNo: Integer; var CountyLineNo: Integer; var CountryLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferHeaderTransferFrom(var AddrArray: array[8] of Text[100]; var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferHeaderTransferTo(var AddrArray: array[8] of Text[100]; var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRcptTransferFrom(var AddrArray: array[8] of Text[100]; var TransferReceiptHeader: Record "Transfer Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRcptTransferTo(var AddrArray: array[8] of Text[100]; var TransferReceiptHeader: Record "Transfer Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferShptTransferFrom(var AddrArray: array[8] of Text[100]; var TransferShipmentHeader: Record "Transfer Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferShptTransferTo(var AddrArray: array[8] of Text[100]; var TransferShipmentHeader: Record "Transfer Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAddrArrayForPostCodeCity(var AddrArray: array[8] of Text[100]; Contact: Text[100]; ContLineNo: Integer; Country: Record "Country/Region"; CountryLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; City: Text[50]; PostCode: Code[20]; County: Text[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendor(var AddrArray: array[8] of Text[100]; var Vendor: Record Vendor; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendBankAcc(var AddrArray: array[8] of Text[100]; var VendorBankAccount: Record "Vendor Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendorRemitToAddress(var AddrArray: array[8] of Text[100]; RemitAddress: Record "Remit Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatAddrOnAfterGetCountry(var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; LanguageCode: Code[10]; var IsHandled: Boolean; var Country: Record "Country/Region")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCompanyAddrOnAfterFillCompanyInfoFromRespCenter(ResponsibilityCenter: Record "Responsibility Center"; var CompanyInformation: Record "Company Information")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobBillTo(var AddrArray: array[8] of Text[100]; var Job: Record Job; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUseCounty(var CountryCode: Code[10]; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;
}

