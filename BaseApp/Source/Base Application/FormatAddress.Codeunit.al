codeunit 365 "Format Address"
{
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
            Country."Address Format" := GLSetup."Local Address Format";
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            if not Country.Get(CountryCode) then begin
                Country.Init();
                Country.Name := CountryCode;
            end;
        IsHandled := false;
        OnFormatAddrOnAfterGetCountry(
            AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, LanguageCode, IsHandled, Country);
        if IsHandled then
            exit;

        if Country."Address Format" = Country."Address Format"::Custom then begin
            CustomAddressFormat.Reset();
            CustomAddressFormat.SetCurrentKey("Country/Region Code", "Line Position");
            CustomAddressFormat.SetRange("Country/Region Code", CountryCode);
            if CustomAddressFormat.FindSet then
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
            Country."Address Format" := GLSetup."Local Address Format";
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            Country.Get(CountryCode);

        if Country."Address Format" = Country."Address Format"::Custom then
            GenerateCustomPostCodeCity(PostCodeCityText, City, PostCode, County, Country)
        else
            GeneratePostCodeCity(PostCodeCityText, CountyText, City, PostCode, County, Country);
    end;

    local procedure GeneratePostCodeCity(var PostCodeCityText: Text[100]; var CountyText: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; Country: Record "Country/Region")
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
        if not CustomAddressFormat.FindFirst then
            exit;

        CustomAddressFormatLine.Reset();
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        CustomAddressFormatLine.SetRange("Country/Region Code", CustomAddressFormat."Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        CustomAddressFormatLineQty := CustomAddressFormatLine.Count();
        if CustomAddressFormatLine.FindSet then
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
    begin
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

        with CompanyInfo do
            FormatAddr(
              AddrArray, Name, "Name 2", '', Address, "Address 2",
              City, "Post Code", County, '');
    end;

    procedure Customer(var AddrArray: array[8] of Text[100]; var Cust: Record Customer)
    var
        Handled: Boolean;
    begin
        OnBeforeCustomer(AddrArray, Cust, Handled);
        if Handled then
            exit;

        with Cust do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure Vendor(var AddrArray: array[8] of Text[100]; var Vend: Record Vendor)
    var
        Handled: Boolean;
    begin
        OnBeforeVendor(AddrArray, Vend, Handled);
        if Handled then
            exit;

        with Vend do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure BankAcc(var AddrArray: array[8] of Text[100]; var BankAcc: Record "Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBankAcc(AddrArray, BankAcc, IsHandled);
        if IsHandled then
            exit;

        with BankAcc do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure SalesHeaderSellTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderSellTo(AddrArray, SalesHeader, Handled);
        if Handled then
            exit;

        with SalesHeader do
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
    end;

    procedure SalesHeaderBillTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderBillTo(AddrArray, SalesHeader, Handled);
        if Handled then
            exit;

        with SalesHeader do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
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

        with SalesHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            if CountryRegion.Get("Sell-to Country/Region Code") then
                SellToCountry := CountryRegion.Name;
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                    exit(true);
        end;
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

        with PurchHeader do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchHeaderPayTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderPayTo(AddrArray, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchHeaderShipTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderShipTo(AddrArray, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure SalesShptSellTo(var AddrArray: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesShptSellTo(AddrArray, SalesShptHeader, IsHandled);
        if IsHandled then
            exit;

        with SalesShptHeader do
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
    end;

    procedure SalesShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesShptBillTo(AddrArray, ShipToAddr, SalesShptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with SalesShptHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            if "Bill-to Customer No." <> "Sell-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if ShipToAddr[i] <> AddrArray[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure SalesShptShipTo(var AddrArray: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesShptShipTo(AddrArray, SalesShptHeader, Handled);
        if Handled then
            exit;

        with SalesShptHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure SalesInvSellTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesInvSellTo(AddrArray, SalesInvHeader, IsHandled);
        if IsHandled then
            exit;

        with SalesInvHeader do
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
    end;

    procedure SalesInvBillTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesInvBillTo(AddrArray, SalesInvHeader, Handled);
        if Handled then
            exit;

        with SalesInvHeader do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
    end;

    procedure SalesInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeSalesInvShipTo(AddrArray, SalesInvHeader, IsHandled, Result, CustAddr);
        if IsHandled then
            exit(Result);

        with SalesInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
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

        with SalesCrMemoHeader do
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
    end;

    procedure SalesCrMemoBillTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCrMemoBillTo(AddrArray, SalesCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with SalesCrMemoHeader do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
    end;

    procedure SalesCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesCrMemoShipTo(AddrArray, CustAddr, SalesCrMemoHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with SalesCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
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

        with ReturnRcptHeader do
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
    end;

    procedure SalesRcptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesRcptBillTo(AddrArray, ShipToAddr, ReturnRcptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with ReturnRcptHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            if "Bill-to Customer No." <> "Sell-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> ShipToAddr[i] then
                    exit(true);
        end;
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

        with ReturnRcptHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure PurchRcptBuyFrom(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptBuyFrom(AddrArray, PurchRcptHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchRcptHeader do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchRcptPayTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptPayTo(AddrArray, PurchRcptHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchRcptHeader do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchRcptShipTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchRcptShipTo(AddrArray, PurchRcptHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchRcptHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure PurchInvBuyFrom(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvBuyFrom(AddrArray, PurchInvHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchInvHeader do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchInvPayTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvPayTo(AddrArray, PurchInvHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchInvHeader do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchInvShipTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchInvShipTo(AddrArray, PurchInvHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchInvHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure PurchCrMemoBuyFrom(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCrMemoBuyFrom(AddrArray, PurchCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchCrMemoHeader do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchCrMemoPayTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCrMemoPayTo(AddrArray, PurchCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchCrMemoHeader do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchCrMemoShipTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchCrMemoShipTo(AddrArray, PurchCrMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchCrMemoHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure PurchShptBuyFrom(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchShptBuyFrom(AddrArray, ReturnShptHeader, IsHandled);
        if IsHandled then
            exit;

        with ReturnShptHeader do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchShptPayTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchShptPayTo(AddrArray, ReturnShptHeader, IsHandled);
        if IsHandled then
            exit;

        with ReturnShptHeader do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchShptShipTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchShptShipTo(AddrArray, ReturnShptHeader, IsHandled);
        if IsHandled then
            exit;

        with ReturnShptHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure AltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee; var AlternativeAddr: Record "Alternative Address")
    begin
        with AlternativeAddr do
            FormatAddr(
              AddrArray, CopyStr(Employee.FullName, 1, 50), '', '', Address,
              "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure Employee(var AddrArray: array[8] of Text[100]; var Employee: Record Employee)
    begin
        with Employee do
            FormatAddr(
              AddrArray, CopyStr(FullName, 1, 50), '', '', Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure EmployeeAltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee)
    var
        AlternativeAddr: Record "Alternative Address";
    begin
        AlternativeAddr.Get(Employee."No.", Employee."Alt. Address Code");
        with AlternativeAddr do
            FormatAddr(
              AddrArray, CopyStr(Employee.FullName, 1, 50), '', '', Address,
              "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure VendBankAcc(var AddrArray: array[8] of Text[100]; var VendBankAcc: Record "Vendor Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendBankAcc(AddrArray, VendBankAcc, IsHandled);
        if IsHandled then
            exit;

        with VendBankAcc do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure CustBankAcc(var AddrArray: array[8] of Text[100]; var CustBankAcc: Record "Customer Bank Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustBankAcc(AddrArray, CustBankAcc, IsHandled);
        if IsHandled then
            exit;

        with CustBankAcc do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure RespCenter(var AddrArray: array[8] of Text[100]; var RespCenter: Record "Responsibility Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRespCenter(AddrArray, RespCenter, IsHandled);
        if IsHandled then
            exit;

        with RespCenter do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure TransferShptTransferFrom(var AddrArray: array[8] of Text[100]; var TransShptHeader: Record "Transfer Shipment Header")
    begin
        with TransShptHeader do
            FormatAddr(
              AddrArray,
              "Transfer-from Name", "Transfer-from Name 2", "Transfer-from Contact", "Transfer-from Address", "Transfer-from Address 2",
              "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
    end;

    procedure TransferShptTransferTo(var AddrArray: array[8] of Text[100]; var TransShptHeader: Record "Transfer Shipment Header")
    begin
        with TransShptHeader do
            FormatAddr(
              AddrArray, "Transfer-to Name", "Transfer-to Name 2", "Transfer-to Contact", "Transfer-to Address", "Transfer-to Address 2",
              "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
    end;

    procedure TransferRcptTransferFrom(var AddrArray: array[8] of Text[100]; var TransRcptHeader: Record "Transfer Receipt Header")
    begin
        with TransRcptHeader do
            FormatAddr(
              AddrArray,
              "Transfer-from Name", "Transfer-from Name 2", "Transfer-from Contact", "Transfer-from Address", "Transfer-from Address 2",
              "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
    end;

    procedure TransferRcptTransferTo(var AddrArray: array[8] of Text[100]; var TransRcptHeader: Record "Transfer Receipt Header")
    begin
        with TransRcptHeader do
            FormatAddr(
              AddrArray, "Transfer-to Name", "Transfer-to Name 2", "Transfer-to Contact", "Transfer-to Address", "Transfer-to Address 2",
              "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
    end;

    procedure TransferHeaderTransferFrom(var AddrArray: array[8] of Text[100]; var TransHeader: Record "Transfer Header")
    begin
        with TransHeader do
            FormatAddr(
              AddrArray,
              "Transfer-from Name", "Transfer-from Name 2", "Transfer-from Contact", "Transfer-from Address", "Transfer-from Address 2",
              "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
    end;

    procedure TransferHeaderTransferTo(var AddrArray: array[8] of Text[100]; var TransHeader: Record "Transfer Header")
    begin
        with TransHeader do
            FormatAddr(
              AddrArray, "Transfer-to Name", "Transfer-to Name 2", "Transfer-to Contact", "Transfer-to Address", "Transfer-to Address 2",
              "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
    end;

    procedure ContactAddr(var AddrArray: array[8] of Text[100]; var Cont: Record Contact)
    begin
        ContactAddrAlt(AddrArray, Cont, Cont.ActiveAltAddress(WorkDate), WorkDate)
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
                with ContAltAddr do begin
                    Get(Cont."No.", AltAddressCode);
                    FormatAddr(
                      AddrArray, "Company Name", "Company Name 2", Cont.Name, Address, "Address 2",
                      City, "Post Code", County, "Country/Region Code");
                end;
            (Cont.Type = Cont.Type::Person) and
          (Cont."Company No." <> '') and
          (CompanyAltAddressCode <> '') and
          RMSetup."Inherit Address Details" and
          ContIdenticalAddress:
                with ContAltAddr do begin
                    Get(Cont."Company No.", CompanyAltAddressCode);
                    FormatAddr(
                      AddrArray, "Company Name", "Company Name 2", Cont.Name, Address, "Address 2",
                      City, "Post Code", County, "Country/Region Code");
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

        with ServHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure ServiceOrderShipto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceOrderShipto(AddrArray, ServHeader, IsHandled);
        if IsHandled then
            exit;

        with ServHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure ServContractSellto(var AddrArray: array[8] of Text[100]; ServContract: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServContractSellto(AddrArray, ServContract, IsHandled);
        if IsHandled then
            exit;

        with ServContract do begin
            CalcFields(Name, "Name 2", Address, "Address 2", "Post Code", City, County, "Country/Region Code");
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
        end;
    end;

    procedure ServContractShipto(var AddrArray: array[8] of Text[100]; ServiceContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        with ServiceContractHeader do begin
            CalcFields(
              "Ship-to Name", "Ship-to Name 2", "Ship-to Address", "Ship-to Address 2",
              "Ship-to Post Code", "Ship-to City", "Ship-to County", "Ship-to Country/Region Code");

            IsHandled := false;
            OnBeforeServContractShipTo(AddrArray, ServiceContractHeader, IsHandled);
            if IsHandled then
                exit;

            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Contact Name", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
        end;
    end;

    procedure ServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceInvBillTo(AddrArray, ServiceInvHeader, IsHandled);
        if IsHandled then
            exit;

        with ServiceInvHeader do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
    end;

    procedure ServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceInvShipTo(AddrArray, CustAddr, ServiceInvHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with ServiceInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            if "Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
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

        with ServiceShptHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure ServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptSellTo(AddrArray, ServiceShptHeader, IsHandled);
        if IsHandled then
            exit;

        with ServiceShptHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure ServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceShptBillTo(AddrArray, ShipToAddr, ServiceShptHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with ServiceShptHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            if "Bill-to Customer No." <> "Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if ShipToAddr[i] <> AddrArray[i] then
                    exit(true);
        end;
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

        with ServiceCrMemoHeader do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
    end;

    procedure ServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceCrMemoShipTo(AddrArray, CustAddr, ServiceCrMemoHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        with ServiceCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            if "Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
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

        with ServiceHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
    end;

    procedure ServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderBillTo(AddrArray, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        with ServiceHeader do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
    end;

    procedure ServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceHeaderShipTo(AddrArray, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        with ServiceHeader do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
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

        with SalesHeaderArch do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
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

        with SalesHeaderArch do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            if CountryRegion.Get("Sell-to Country/Region Code") then
                SellToCountry := CountryRegion.Name;
            for i := 1 to ArrayLen(AddrArray) do
                if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                    exit(true);
        end;
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

        with PurchHeaderArch do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchHeaderPayToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderPayToArch(AddrArray, PurchHeaderArch, IsHandled);
        if IsHandled then
            exit;

        with PurchHeaderArch do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchHeaderShipToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderShipToArch(AddrArray, PurchHeaderArch, IsHandled);
        if IsHandled then
            exit;

        with PurchHeaderArch do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure Reminder(var AddrArray: array[8] of Text[100]; var ReminderHeader: Record "Reminder Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReminder(AddrArray, ReminderHeader, IsHandled);
        if IsHandled then
            exit;

        with ReminderHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure IssuedReminder(var AddrArray: array[8] of Text[100]; var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedReminder(AddrArray, IssuedReminderHeader, IsHandled);
        if IsHandled then
            exit;

        with IssuedReminderHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure FinanceChargeMemo(var AddrArray: array[8] of Text[100]; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinanceChargeMemo(AddrArray, FinanceChargeMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with FinanceChargeMemoHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure IssuedFinanceChargeMemo(var AddrArray: array[8] of Text[100]; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIssuedFinanceChargeMemo(AddrArray, IssuedFinChargeMemoHeader, IsHandled);
        if IsHandled then
            exit;

        with IssuedFinChargeMemoHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure UseCounty(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
    begin
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
    begin
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
    local procedure OnBeforeFormatAddr(var Country: Record "Country/Region"; CountryCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatPostCodeCity(var Country: Record "Country/Region"; CountryCode: Code[10])
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
    local procedure OnFormatAddrOnAfterGetCountry(var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; LanguageCode: Code[10]; var IsHandled: Boolean; var Country: Record "Country/Region")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCompanyAddrOnAfterFillCompanyInfoFromRespCenter(ResponsibilityCenter: Record "Responsibility Center"; var CompanyInformation: Record "Company Information")
    begin
    end;
}

