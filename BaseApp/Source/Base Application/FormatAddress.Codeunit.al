codeunit 365 "Format Address"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        i: Integer;
        BarCode: array[50] of Text[100];

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
        Handled: Boolean;
    begin
        Clear(AddrArray);

        if CountryCode = '' then begin
            GLSetup.Get;
            Clear(Country);
            Country."Address Format" := GLSetup."Local Address Format";
            Country."Contact Address Format" := GLSetup."Local Cont. Addr. Format";
        end else
            if not Country.Get(CountryCode) then begin
                Country.Init;
                Country.Name := CountryCode;
            end;

        if Country."Address Format" = Country."Address Format"::Custom then begin
            CustomAddressFormat.Reset;
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
                until CustomAddressFormat.Next = 0;

            CompressArray(AddrArray);
        end else begin
            SetLineNos(Country, NameLineNo, Name2LineNo, AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo);

            OnBeforeFormatAddress(
              Country, AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode, NameLineNo, Name2LineNo,
              AddrLineNo, Addr2LineNo, ContLineNo, PostCodeCityLineNo, CountyLineNo, CountryLineNo, Handled);
            if Handled then
                exit;

            AddrArray[NameLineNo] := Name;
            AddrArray[Name2LineNo] := Name2;
            AddrArray[AddrLineNo] := Addr;
            AddrArray[Addr2LineNo] := Addr2;

            case Country."Address Format" of
                Country."Address Format"::"Post Code+City",
                Country."Address Format"::"City+County+Post Code",
                Country."Address Format"::"City+Post Code",
                Country."Address Format"::"City+Post Code (no comma)",
                Country."Address Format"::"City+County+Post Code (no comma)":
                    begin
                        AddrArray[ContLineNo] := Contact;
                        GeneratePostCodeCity(AddrArray[PostCodeCityLineNo], AddrArray[CountyLineNo], City, PostCode, County, Country);
                        AddrArray[CountryLineNo] := Country.Name;
                        CompressArray(AddrArray);
                    end;
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
        OnAfterFormatAddress(AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryCode);
    end;

    procedure FormatPostCodeCity(var PostCodeCityText: Text[100]; var CountyText: Text[50]; City: Text[50]; PostCode: Code[20]; County: Text[50]; CountryCode: Code[10])
    var
        Country: Record "Country/Region";
    begin
        Clear(PostCodeCityText);
        Clear(CountyText);

        if CountryCode = '' then begin
            GLSetup.Get;
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
            Country."Address Format"::"City+Post Code (no comma)":
                begin
                    if PostCode <> '' then
                        PostCodeCityText := DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ' ' + PostCode
                    else
                        PostCodeCityText := City;
                end;
            Country."Address Format"::"City+County+Post Code (no comma)":
                begin
                    if (County <> '') and (PostCode <> '') then
                        PostCodeCityText :=
                          DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - StrLen(County) - 3) +
                          ' ' + County + ' ' + PostCode
                    else
                        if PostCode = '' then begin
                            PostCodeCityText := City;
                            CountyText := County;
                        end else
                            if (County = '') and (PostCode <> '') then
                                PostCodeCityText := DelStr(City, MaxStrLen(PostCodeCityText) - StrLen(PostCode) - 1) + ' ' + PostCode;
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

        CustomAddressFormat.Reset;
        CustomAddressFormat.SetRange("Country/Region Code", Country.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        if not CustomAddressFormat.FindFirst then
            exit;

        CustomAddressFormatLine.Reset;
        CustomAddressFormatLine.SetCurrentKey("Country/Region Code", "Line No.", "Field Position");
        CustomAddressFormatLine.SetRange("Country/Region Code", CustomAddressFormat."Country/Region Code");
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        CustomAddressFormatLineQty := CustomAddressFormatLine.Count;
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
            until CustomAddressFormatLine.Next = 0;

        PostCodeCityText := DelStr(PostCodeCityLine, MaxStrLen(PostCodeCityText));
    end;

    procedure GetCompanyAddr(RespCenterCode: Code[10]; var ResponsibilityCenter: Record "Responsibility Center"; var CompanyInfo: Record "Company Information"; var CompanyAddr: array[8] of Text[100])
    begin
        if ResponsibilityCenter.Get(RespCenterCode) then begin
            RespCenter(CompanyAddr, ResponsibilityCenter);
            CompanyInfo."Phone No." := ResponsibilityCenter."Phone No.";
            CompanyInfo."Fax No." := ResponsibilityCenter."Fax No.";
        end else
            Company(CompanyAddr, CompanyInfo);
    end;

    procedure Company(var AddrArray: array[8] of Text[100]; var CompanyInfo: Record "Company Information")
    begin
        with CompanyInfo do begin
            FormatAddr(
              AddrArray, Name, "Name 2", '', Address, "Address 2",
              City, "Post Code", County, '');
            CreateBarCode(
              DATABASE::"Company Information", GetPosition, 0, '', '', '');
        end;
    end;

    procedure Customer(var AddrArray: array[8] of Text[100]; var Cust: Record Customer)
    var
        Handled: Boolean;
    begin
        OnBeforeCustomer(AddrArray, Cust, Handled);
        if Handled then
            exit;

        with Cust do begin
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::Customer, GetPosition, 0,
              "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
        end;
    end;

    procedure Vendor(var AddrArray: array[8] of Text[100]; var Vend: Record Vendor)
    var
        Handled: Boolean;
    begin
        OnBeforeVendor(AddrArray, Vend, Handled);
        if Handled then
            exit;

        with Vend do begin
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::Vendor, GetPosition, 0,
              "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
        end;
    end;

    procedure BankAcc(var AddrArray: array[8] of Text[100]; var BankAcc: Record "Bank Account")
    begin
        with BankAcc do begin
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Bank Account", GetPosition, 0,
              "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
        end;
    end;

    procedure SalesHeaderSellTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderSellTo(AddrArray, SalesHeader, Handled);
        if Handled then
            exit;

        with SalesHeader do begin
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Header", GetPosition, 3,
              "Sell-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesHeaderBillTo(var AddrArray: array[8] of Text[100]; var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesHeaderBillTo(AddrArray, SalesHeader, Handled);
        if Handled then
            exit;

        with SalesHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
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
            CreateBarCode(
              DATABASE::"Sales Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if (AddrArray[i] <> CustAddr[i]) and (AddrArray[i] <> '') and (AddrArray[i] <> SellToCountry) then
                    exit(true);
        end;
        exit(false);
    end;

    procedure PurchHeaderBuyFrom(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Purchase Header", GetPosition, 5,
              "Buy-from Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchHeaderPayTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purchase Header", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchHeaderShipTo(var AddrArray: array[8] of Text[100]; var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purchase Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesShptSellTo(var AddrArray: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header")
    begin
        with SalesShptHeader do begin
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Shipment Header", GetPosition, 3,
              "Sell-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var SalesShptHeader: Record "Sales Shipment Header"): Boolean
    begin
        with SalesShptHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Shipment Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
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

        with SalesShptHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Shipment Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesInvSellTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header")
    begin
        with SalesInvHeader do begin
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Invoice Header", GetPosition, 3,
              "Sell-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesInvBillTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesInvBillTo(AddrArray, SalesInvHeader, Handled);
        if Handled then
            exit;

        with SalesInvHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Invoice Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header"): Boolean
    begin
        with SalesInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Invoice Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure SalesCrMemoSellTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        with SalesCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Cr.Memo Header", GetPosition, 3,
              "Sell-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesCrMemoBillTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Handled: Boolean;
    begin
        OnBeforeSalesCrMemoBillTo(AddrArray, SalesCrMemoHeader, Handled);
        if Handled then
            exit;

        with SalesCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Cr.Memo Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    begin
        with SalesCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Cr.Memo Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Sell-to Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure SalesRcptSellTo(var AddrArray: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header")
    begin
        with ReturnRcptHeader do begin
            FormatAddr(
              AddrArray, "Sell-to Customer Name", "Sell-to Customer Name 2", "Sell-to Contact", "Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Return Receipt Header", GetPosition, 3,
              "Sell-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure SalesRcptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header"): Boolean
    begin
        with ReturnRcptHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Return Receipt Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Bill-to Customer No." <> "Sell-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> ShipToAddr[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure SalesRcptShipTo(var AddrArray: array[8] of Text[100]; var ReturnRcptHeader: Record "Return Receipt Header")
    begin
        with ReturnRcptHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Return Receipt Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchRcptBuyFrom(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        with PurchRcptHeader do begin
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Rcpt. Header", GetPosition, 5,
              "Buy-from Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchRcptPayTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        with PurchRcptHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Rcpt. Header", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchRcptShipTo(var AddrArray: array[8] of Text[100]; var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        with PurchRcptHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Rcpt. Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchInvBuyFrom(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        with PurchInvHeader do begin
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Inv. Header", GetPosition, 5,
              "Buy-from Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchInvPayTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        with PurchInvHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Inv. Header", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchInvShipTo(var AddrArray: array[8] of Text[100]; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        with PurchInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Inv. Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchCrMemoBuyFrom(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
        with PurchCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Cr. Memo Hdr.", GetPosition, 5,
              "Buy-from Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchCrMemoPayTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
        with PurchCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Cr. Memo Hdr.", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchCrMemoShipTo(var AddrArray: array[8] of Text[100]; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
        with PurchCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Cr. Memo Hdr.", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchShptBuyFrom(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    begin
        with ReturnShptHeader do begin
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Return Shipment Header", GetPosition, 5,
              "Buy-from Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchShptPayTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    begin
        with ReturnShptHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Return Shipment Header", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure PurchShptShipTo(var AddrArray: array[8] of Text[100]; var ReturnShptHeader: Record "Return Shipment Header")
    begin
        with ReturnShptHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Return Shipment Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure AltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee; var AlternativeAddr: Record "Alternative Address")
    begin
        with AlternativeAddr do begin
            FormatAddr(
              AddrArray, CopyStr(Employee.FullName, 1, 50), '', '', Address,
              "Address 2", City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Alternative Address", GetPosition, 0, '', '', '');
        end;
    end;

    procedure Employee(var AddrArray: array[8] of Text[100]; var Employee: Record Employee)
    begin
        with Employee do begin
            FormatAddr(
              AddrArray, CopyStr(FullName, 1, 50), '', '', Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::Employee, GetPosition, 0,
              "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
        end;
    end;

    procedure EmployeeAltAddr(var AddrArray: array[8] of Text[100]; var Employee: Record Employee)
    var
        AlternativeAddr: Record "Alternative Address";
    begin
        AlternativeAddr.Get(Employee."No.", Employee."Alt. Address Code");
        with AlternativeAddr do begin
            FormatAddr(
              AddrArray, CopyStr(Employee.FullName, 1, 50), '', '', Address,
              "Address 2", City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Alternative Address", GetPosition, 0, '', '', '');
        end;
    end;

    procedure VendBankAcc(var AddrArray: array[8] of Text[100]; var VendBankAcc: Record "Vendor Bank Account")
    begin
        with VendBankAcc do begin
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Vendor Bank Account", GetPosition, 0, "Vendor No.", '', '');
        end;
    end;

    procedure CustBankAcc(var AddrArray: array[8] of Text[100]; var CustBankAcc: Record "Customer Bank Account")
    begin
        with CustBankAcc do begin
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Customer Bank Account", GetPosition, 0, "Customer No.", '', '');
        end;
    end;

    procedure RespCenter(var AddrArray: array[8] of Text[100]; var RespCenter: Record "Responsibility Center")
    begin
        with RespCenter do begin
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Responsibility Center", GetPosition, 0,
              Code, "Global Dimension 1 Code", "Global Dimension 2 Code");
        end;
    end;

    procedure TransferShptTransferFrom(var AddrArray: array[8] of Text[100]; var TransShptHeader: Record "Transfer Shipment Header")
    begin
        with TransShptHeader do begin
            FormatAddr(
              AddrArray, "Transfer-from Name", "Transfer-from Name 2", '', "Transfer-from Address", "Transfer-from Address 2",
              "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Transfer Shipment Header", GetPosition, 6,
              "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure TransferShptTransferTo(var AddrArray: array[8] of Text[100]; var TransShptHeader: Record "Transfer Shipment Header")
    begin
        with TransShptHeader do begin
            FormatAddr(
              AddrArray, "Transfer-to Name", "Transfer-to Name 2", '', "Transfer-to Address", "Transfer-to Address 2",
              "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Transfer Shipment Header", GetPosition, 7,
              "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure TransferRcptTransferFrom(var AddrArray: array[8] of Text[100]; var TransRcptHeader: Record "Transfer Receipt Header")
    begin
        with TransRcptHeader do begin
            FormatAddr(
              AddrArray, "Transfer-from Name", "Transfer-from Name 2", '', "Transfer-from Address", "Transfer-from Address 2",
              "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Transfer Receipt Header", GetPosition, 6,
              "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure TransferRcptTransferTo(var AddrArray: array[8] of Text[100]; var TransRcptHeader: Record "Transfer Receipt Header")
    begin
        with TransRcptHeader do begin
            FormatAddr(
              AddrArray, "Transfer-to Name", "Transfer-to Name 2", '', "Transfer-to Address", "Transfer-to Address 2",
              "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Transfer Receipt Header", GetPosition, 7,
              "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure TransferHeaderTransferFrom(var AddrArray: array[8] of Text[100]; var TransHeader: Record "Transfer Header")
    begin
        with TransHeader do begin
            FormatAddr(
              AddrArray, "Transfer-from Name", "Transfer-from Name 2", '', "Transfer-from Address", "Transfer-from Address 2",
              "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            CreateBarCode(
              DATABASE::"Transfer Header", GetPosition, 6,
              "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure TransferHeaderTransferTo(var AddrArray: array[8] of Text[100]; var TransHeader: Record "Transfer Header")
    begin
        with TransHeader do begin
            FormatAddr(
              AddrArray, "Transfer-to Name", "Transfer-to Name 2", '', "Transfer-to Address", "Transfer-to Address 2",
              "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Transfer Header", GetPosition, 7,
              "No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
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

        RMSetup.Get;

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
                    CreateBarCode(
                      DATABASE::"Contact Alt. Address", GetPosition, 0,
                      "Contact No.", '', '');
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
                    CreateBarCode(
                      DATABASE::"Contact Alt. Address", GetPosition, 0,
                      "Contact No.", '', '');
                end;
            (Cont.Type = Cont.Type::Person) and
          (Cont."Company No." <> ''):
                with Cont do begin
                    FormatAddr(
                      AddrArray, ContCompany.Name, ContCompany."Name 2", Name, Address, "Address 2",
                      City, "Post Code", County, "Country/Region Code");
                    CreateBarCode(DATABASE::Contact, GetPosition, 0, "No.", '', '');
                end;
            else
                with Cont do begin
                    FormatAddr(
                      AddrArray, Name, "Name 2", '', Address, "Address 2",
                      City, "Post Code", County, "Country/Region Code");
                    CreateBarCode(DATABASE::Contact, GetPosition, 0, "No.", '', '');
                end;
        end;
    end;

    procedure ServiceOrderSellto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    begin
        with ServHeader do begin
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Header", GetPosition, 3,
              "Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure ServiceOrderShipto(var AddrArray: array[8] of Text[100]; ServHeader: Record "Service Header")
    begin
        with ServHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure ServContractSellto(var AddrArray: array[8] of Text[100]; ServContract: Record "Service Contract Header")
    begin
        with ServContract do begin
            CalcFields(Name, "Name 2", Address, "Address 2", "Post Code", City, County, "Country/Region Code");
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Contract Header", GetPosition, 3,
              "Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure ServContractShipto(var AddrArray: array[8] of Text[100]; ServiceContractHeader: Record "Service Contract Header")
    begin
        with ServiceContractHeader do begin
            CalcFields(
              "Ship-to Name", "Ship-to Name 2", "Ship-to Address", "Ship-to Address 2",
              "Ship-to Post Code", "Ship-to City", "Ship-to County", "Ship-to Country/Region Code");

            OnBeforeServContractShipTo(AddrArray, ServiceContractHeader);
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Contact Name", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Contract Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    procedure ServiceInvBillTo(var AddrArray: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header")
    begin
        with ServiceInvHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Invoice Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure ServiceInvShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceInvHeader: Record "Service Invoice Header"): Boolean
    begin
        with ServiceInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Invoice Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure ServiceShptShipTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    begin
        with ServiceShptHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Shipment Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure ServiceShptSellTo(var AddrArray: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header")
    begin
        with ServiceShptHeader do begin
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact Name", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Shipment Header", GetPosition, 3,
              "Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure ServiceShptBillTo(var AddrArray: array[8] of Text[100]; ShipToAddr: array[8] of Text[100]; var ServiceShptHeader: Record "Service Shipment Header"): Boolean
    begin
        with ServiceShptHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Shipment Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Bill-to Customer No." <> "Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if ShipToAddr[i] <> AddrArray[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure ServiceCrMemoBillTo(var AddrArray: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        with ServiceCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Cr.Memo Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure ServiceCrMemoShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Boolean
    begin
        with ServiceCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Cr.Memo Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if "Customer No." <> "Bill-to Customer No." then
                exit(true);
            for i := 1 to ArrayLen(AddrArray) do
                if AddrArray[i] <> CustAddr[i] then
                    exit(true);
        end;
        exit(false);
    end;

    procedure ServiceHeaderSellTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    begin
        with ServiceHeader do begin
            FormatAddr(
              AddrArray, Name, "Name 2", "Contact No.", Address, "Address 2",
              City, "Post Code", County, "Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Header", GetPosition, 3,
              "Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure ServiceHeaderBillTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    begin
        with ServiceHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure ServiceHeaderShipTo(var AddrArray: array[8] of Text[100]; var ServiceHeader: Record "Service Header")
    begin
        with ServiceHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Service Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    local procedure CreateBarCode(TableNo: Integer; TableKey: Text[1024]; AddressType: Option; CustomInfo1: Code[20]; CustomInfo2: Code[20]; CustomInfo3: Code[20])
    var
        AddressID: Record "Address ID";
        BarCodeManagement: Codeunit "BarCode Management";
        CustomInfo: Code[20];
    begin
        BarCode[AddressType + 1] := '';
        if AddressID.Get(TableNo, TableKey, AddressType) then
            case AddressID."Bar Code System" of
                AddressID."Bar Code System"::"4-State Bar Code":
                    begin
                        case GLSetup."BarCode Custom Information" of
                            GLSetup."BarCode Custom Information"::" ":
                                CustomInfo := '';
                            GLSetup."BarCode Custom Information"::Code:
                                CustomInfo := CustomInfo1;
                            GLSetup."BarCode Custom Information"::"Global Dimension 1 Code":
                                CustomInfo := CustomInfo2;
                            GLSetup."BarCode Custom Information"::"Global Dimension 2 Code":
                                CustomInfo := CustomInfo3;
                        end;
                        if StrLen(CustomInfo) > 15 then
                            CustomInfo := '';
                        BarCodeManagement.BuildBarCode(AddressID."Address ID", CustomInfo, BarCode[AddressType + 1]);
                    end;
                else
                    BarCode[AddressType + 1] := AddressID."Bar Code";
            end;
    end;

    procedure PrintBarCode(AddressType: Option): Text[100]
    begin
        exit(BarCode[AddressType + 1]);
    end;

    [Scope('OnPrem')]
    procedure SalesTaxInvBillTo(var AddrArray: array[8] of Text[100]; var SalesTaxInvHeader: Record "Sales Tax Invoice Header")
    begin
        with SalesTaxInvHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Tax Invoice Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure SalesTaxInvShipTo(var AddrArray: array[8] of Text[100]; var SalesTaxInvHeader: Record "Sales Tax Invoice Header")
    begin
        with SalesTaxInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Tax Invoice Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure SalesTaxCrMemoBillTo(var AddrArray: array[8] of Text[100]; var SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header")
    begin
        with SalesTaxCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Tax Cr.Memo Header", GetPosition, 1,
              "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure SalesTaxCrMemoShipTo(var AddrArray: array[8] of Text[100]; var SalesTaxCrMemoHeader: Record "Sales Tax Cr.Memo Header")
    begin
        with SalesTaxCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Sales Tax Cr.Memo Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure PurchTaxInvPayTo(var AddrArray: array[8] of Text[100]; var PurchTaxInvHeader: Record "Purch. Tax Inv. Header")
    begin
        with PurchTaxInvHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Tax Inv. Header", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure PurchTaxInvShipTo(var AddrArray: array[8] of Text[100]; var PurchTaxInvHeader: Record "Purch. Tax Inv. Header")
    begin
        with PurchTaxInvHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Tax Inv. Header", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure PurchTaxCrMemoPayTo(var AddrArray: array[8] of Text[100]; var PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.")
    begin
        with PurchTaxCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Tax Cr. Memo Hdr.", GetPosition, 4,
              "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    [Scope('OnPrem')]
    procedure PurchTaxCrMemoShipTo(var AddrArray: array[8] of Text[100]; var PurchTaxCrMemoHeader: Record "Purch. Tax Cr. Memo Hdr.")
    begin
        with PurchTaxCrMemoHeader do begin
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            CreateBarCode(
              DATABASE::"Purch. Tax Cr. Memo Hdr.", GetPosition, 2,
              "Ship-to Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end
    end;

    procedure PostalBarCode(AddressType: Option): Text[100]
    begin
        exit(PrintBarCode(AddressType));
    end;

    procedure SalesHeaderArchBillTo(var AddrArray: array[8] of Text[100]; var SalesHeaderArch: Record "Sales Header Archive")
    begin
        with SalesHeaderArch do
            FormatAddr(
              AddrArray, "Bill-to Name", "Bill-to Name 2", "Bill-to Contact", "Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
    end;

    procedure SalesHeaderArchShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesHeaderArch: Record "Sales Header Archive"): Boolean
    var
        CountryRegion: Record "Country/Region";
        SellToCountry: Code[50];
    begin
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
    begin
        with PurchHeaderArch do
            FormatAddr(
              AddrArray, "Buy-from Vendor Name", "Buy-from Vendor Name 2", "Buy-from Contact", "Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code");
    end;

    procedure PurchHeaderPayToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    begin
        with PurchHeaderArch do
            FormatAddr(
              AddrArray, "Pay-to Name", "Pay-to Name 2", "Pay-to Contact", "Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
    end;

    procedure PurchHeaderShipToArch(var AddrArray: array[8] of Text[100]; var PurchHeaderArch: Record "Purchase Header Archive")
    begin
        with PurchHeaderArch do
            FormatAddr(
              AddrArray, "Ship-to Name", "Ship-to Name 2", "Ship-to Contact", "Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
    end;

    procedure Reminder(var AddrArray: array[8] of Text[100]; var ReminderHeader: Record "Reminder Header")
    begin
        with ReminderHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure IssuedReminder(var AddrArray: array[8] of Text[100]; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        with IssuedReminderHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure FinanceChargeMemo(var AddrArray: array[8] of Text[100]; var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    begin
        with FinanceChargeMemoHeader do
            FormatAddr(
              AddrArray, Name, "Name 2", Contact, Address, "Address 2", City, "Post Code", County, "Country/Region Code");
    end;

    procedure IssuedFinanceChargeMemo(var AddrArray: array[8] of Text[100]; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
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
            GLSetup.Get;
            case true of
                GLSetup."Local Address Format" = GLSetup."Local Address Format"::"City+County+Post Code":
                    exit(true);
                GLSetup."Local Address Format" = GLSetup."Local Address Format"::"City+County+Post Code (no comma)":
                    exit(true);
                CustomAddressFormat.UseCounty(''):
                    exit(true);
            end;
        end;

        if CountryRegion.Get(CountryCode) then
            case true of
                CountryRegion."Address Format" = CountryRegion."Address Format"::"City+County+Post Code":
                    exit(true);
                CountryRegion."Address Format" = CountryRegion."Address Format"::"City+County+Post Code (no comma)":
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatAddress(var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10])
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
    local procedure OnBeforeFormatAddress(Country: Record "Country/Region"; var AddrArray: array[8] of Text[100]; var Name: Text[100]; var Name2: Text[100]; var Contact: Text[100]; var Addr: Text[100]; var Addr2: Text[50]; var City: Text[50]; var PostCode: Code[20]; var County: Text[50]; var CountryCode: Code[10]; NameLineNo: Integer; Name2LineNo: Integer; AddrLineNo: Integer; Addr2LineNo: Integer; ContLineNo: Integer; PostCodeCityLineNo: Integer; CountyLineNo: Integer; CountryLineNo: Integer; var Handled: Boolean)
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
    local procedure OnBeforeSalesHeaderShipTo(var AddrArray: array[8] of Text[100]; CustAddr: array[8] of Text[100]; var SalesHeader: Record "Sales Header"; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvBillTo(var AddrArray: array[8] of Text[100]; var SalesInvHeader: Record "Sales Invoice Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoBillTo(var AddrArray: array[8] of Text[100]; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesShptShipTo(var AddrArray: array[8] of Text[100]; var SalesShipmentHeader: Record "Sales Shipment Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractShipTo(var AddrArray: array[8] of Text[100]; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendor(var AddrArray: array[8] of Text[100]; var Vendor: Record Vendor; var Handled: Boolean)
    begin
    end;
}

