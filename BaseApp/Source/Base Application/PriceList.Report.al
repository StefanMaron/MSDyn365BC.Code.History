report 715 "Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PriceList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Price List';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group";
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
            {
            }
            column(CompanyInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfoBankAccNo; CompanyInfo."Bank Account No.")
            {
            }
            column(ReqDateFormatted; StrSubstNo(Text003, Format(DateReq, 0, 4)))
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(SalesType; SalesType)
            {
                OptionCaption = 'Customer,Customer Price Group,All Customers,Campaign';
            }
            column(SalesCode; SalesCode)
            {
            }
            column(PageCaption; StrSubstNo(Text002, ''))
            {
            }
            column(SalesDesc; SalesDesc)
            {
            }
            column(UnitPriceFieldCaption; SalesPrice.FieldCaption("Unit Price") + CurrencyText)
            {
            }
            column(LineDiscountFieldCaption; SalesLineDisc.FieldCaption("Line Discount %") + CurrencyText)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(PriceListCaption; PriceListCaptionLbl)
            {
            }
            column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
            {
            }
            column(CompanyInfoVATRegNoCaption; CompanyInfoVATRegNoCaptionLbl)
            {
            }
            column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
            {
            }
            column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
            {
            }
            column(CompanyInfoBankAccNoCaption; CompanyInfoBankAccNoCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(ItemDescCaption; ItemDescCaptionLbl)
            {
            }
            column(UnitOfMeasureCaption; UnitOfMeasureCaptionLbl)
            {
            }
            column(MinimumQuantityCaption; MinimumQuantityCaptionLbl)
            {
            }
            column(VATTextCaption; VATTextCaptionLbl)
            {
            }
            dataitem(SalesPrices; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(VATText_SalesPrices; VATText)
                {
                }
                column(SalesPriceUnitPrice; SalesPrice."Unit Price")
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 2;
                }
                column(UOM_SalesPrices; UnitOfMeasure)
                {
                }
                column(ItemNo_SalesPrices; ItemNo)
                {
                }
                column(ItemDesc_SalesPrices; ItemDesc)
                {
                }
                column(MinimumQty_SalesPrices; SalesPrice."Minimum Quantity")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PrintSalesPrice(false);
                end;

                trigger OnPreDataItem()
                begin
                    PreparePrintSalesPrice(false);
                end;
            }
            dataitem(SalesLineDiscs; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(LineDisc_SalesLineDisc; SalesLineDisc."Line Discount %")
                {
                    AutoFormatExpression = Currency.Code;
                    AutoFormatType = 2;
                }
                column(MinimumQty_SalesLineDiscs; SalesLineDisc."Minimum Quantity")
                {
                }
                column(UOM_SalesLineDiscs; UnitOfMeasure)
                {
                }
                column(ItemDesc_SalesLineDiscs; ItemDesc)
                {
                }
                column(ItemNo_SalesLineDiscs; ItemNo)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PrintSalesDisc();
                end;

                trigger OnPreDataItem()
                begin
                    PreparePrintSalesDisc(false);
                end;
            }
            dataitem("Item Variant"; "Item Variant")
            {
                DataItemLink = "Item No." = FIELD("No.");
                dataitem(VariantSalesPrices; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(ItemNo_Variant_SalesPrices; ItemNo)
                    {
                    }
                    column(ItemDesc_Variant_SalesPrices; ItemDesc)
                    {
                    }
                    column(UOM_Variant_SalesPrices; UnitOfMeasure)
                    {
                    }
                    column(MinimumQty_Variant_SalesPrices; SalesPrice."Minimum Quantity")
                    {
                    }
                    column(UnitPrince_Variant_SalesPrices; SalesPrice."Unit Price")
                    {
                    }
                    column(VATText_Variant_SalesPrices; VATText)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PrintSalesPrice(true);
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreparePrintSalesPrice(true);
                    end;
                }
                dataitem(VariantSalesLineDiscs; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(ItemNo_Variant_SalesLineDescs; ItemNo)
                    {
                    }
                    column(ItemDesc_Variant_SalesLineDescs; ItemDesc)
                    {
                    }
                    column(UOM_Variant_SalesLineDescs; UnitOfMeasure)
                    {
                    }
                    column(MinimumQty_Variant_SalesLineDescs; SalesLineDisc."Minimum Quantity")
                    {
                    }
                    column(LineDisc_Variant_SalesLineDescs; SalesLineDisc."Line Discount %")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PrintSalesDisc();
                    end;

                    trigger OnPreDataItem()
                    begin
                        PreparePrintSalesDisc(true);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    SalesHeader: Record "Sales Header";
                    SalesLine: Record "Sales Line";
                    TempPriceListLine: Record "Price List Line" temporary;
                    CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
                    LineWithPrice: Interface "Line With Price";
                    PriceCalculation: Interface "Price Calculation";
                    PriceType: Enum "Price Type";
                begin
                    ItemNo := Code;
                    ItemDesc := Description;

                    SalesLine.Init();
                    SalesLine.Type := SalesLine.Type::Item;
                    SalesLine."No." := Item."No.";
                    SalesLine."Variant Code" := Code;
                    SalesLine."Posting Date" := DateReq;
                    SetCurrencyFactorInHeader(SalesHeader);
                    SalesLine.GetLineWithPrice(LineWithPrice);
                    LineWithPrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
                    LineWithPrice.SetSources(PriceSourceList);
                    PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
                    PriceCalculation.FindPrice(TempPriceListLine, false);
                    CopyFromToPriceListLine.CopyTo(SalesPrice, TempPriceListLine);
                    PriceCalculation.FindDiscount(TempPriceListLine, false);
                    CopyFromToPriceListLine.CopyTo(SalesLineDisc, TempPriceListLine);
                end;
            }

            trigger OnAfterGetRecord()
            var
                SalesHeader: Record "Sales Header";
                SalesLine: Record "Sales Line";
                TempPriceListLine: Record "Price List Line" temporary;
                CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
                LineWithPrice: Interface "Line With Price";
                PriceCalculation: Interface "Price Calculation";
                PriceType: Enum "Price Type";
            begin
                ItemNo := "No.";
                ItemDesc := Description;

                SalesLine.Init();
                SalesLine.Type := SalesLine.Type::Item;
                SalesLine."No." := Item."No.";
                SalesLine."Posting Date" := DateReq;
                SetCurrencyFactorInHeader(SalesHeader);
                SalesLine.GetLineWithPrice(LineWithPrice);
                LineWithPrice.SetLine(PriceType::Sale, SalesHeader, SalesLine);
                LineWithPrice.SetSources(PriceSourceList);
                PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
                PriceCalculation.FindPrice(TempPriceListLine, false);
                CopyFromToPriceListLine.CopyTo(SalesPrice, TempPriceListLine);
                PriceCalculation.FindDiscount(TempPriceListLine, false);
                CopyFromToPriceListLine.CopyTo(SalesLineDisc, TempPriceListLine);
            end;

            trigger OnPreDataItem()
            begin
                PriceSourceList.Init();
                CustNo := '';
                ContNo := '';
                CustPriceGrCode := '';
                CustDiscGrCode := '';
                SalesDesc := '';

                case SalesType of
                    SalesType::Customer:
                        begin
                            Cust.Get(SalesCode);
                            CustNo := Cust."No.";
                            CustPriceGrCode := Cust."Customer Price Group";
                            CustDiscGrCode := Cust."Customer Disc. Group";
                            PriceSourceList.Add(PriceSourceType::"Customer Disc. Group", CustDiscGrCode);
                            SalesDesc := Cust.Name;
                            PriceSourceList.Add(PriceSourceType::Customer, CustNo);
                            if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustNo) then begin
                                ContNo := ContBusRel."Contact No.";
                                PriceSourceList.Add(PriceSourceType::Contact, ContNo);
                            end;
                            PriceSourceList.Add("Price Source Type"::"All Customers");
                        end;
                    SalesType::"Customer Price Group":
                        begin
                            CustPriceGr.Get(SalesCode);
                            CustPriceGrCode := CopyStr(SalesCode, 1, MaxStrLen(CustPriceGrCode));
                            PriceSourceList.Add(PriceSourceType::"Customer Price Group", CustPriceGrCode);
                        end;
                    SalesType::Campaign:
                        begin
                            Campaign.Get(SalesCode);
                            CampaignNo := SalesCode;
                            SalesDesc := Campaign.Description;
                            PriceSourceList.Add(PriceSourceType::Campaign, CampaignNo);
                        end;
                    SalesType::"All Customers":
                        PriceSourceList.Add(PriceSourceType::"All Customers");
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Date; DateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date';
                        ToolTip = 'Specifies the period for which the prices apply, such as 10/01/96...12/31/96.';
                    }
                    field(Method; PriceCalcMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation method';
                        ToolTip = 'Specifies the price calculation method.';
                    }
                    field(SalesType; SalesType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Type';
                        OptionCaption = 'Customer,Customer Price Group,All Customers,Campaign';
                        ToolTip = 'Specifies the sales type for which the price list should be valid.';

                        trigger OnValidate()
                        begin
                            SalesCodeCtrlEnable := SalesType <> SalesType::"All Customers";
                            SalesCode := '';
                        end;
                    }
                    field(SalesCodeCtrl; SalesCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Code';
                        Enabled = SalesCodeCtrlEnable;
                        ToolTip = 'Specifies code for the sales type for which the price list should be valid.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            CustList: Page "Customer List";
                            CustPriceGrList: Page "Customer Price Groups";
                            CampaignList: Page "Campaign List";
                        begin
                            case SalesType of
                                SalesType::Customer:
                                    begin
                                        CustList.LookupMode := true;
                                        CustList.SetRecord(Cust);
                                        if CustList.RunModal = ACTION::LookupOK then begin
                                            CustList.GetRecord(Cust);
                                            SalesCode := Cust."No.";
                                        end;
                                    end;
                                SalesType::"Customer Price Group":
                                    begin
                                        CustPriceGrList.LookupMode := true;
                                        CustPriceGrList.SetRecord(CustPriceGr);
                                        if CustPriceGrList.RunModal = ACTION::LookupOK then begin
                                            CustPriceGrList.GetRecord(CustPriceGr);
                                            SalesCode := CustPriceGr.Code;
                                        end;
                                    end;
                                SalesType::Campaign:
                                    begin
                                        CampaignList.LookupMode := true;
                                        CampaignList.SetRecord(Campaign);
                                        if CampaignList.RunModal = ACTION::LookupOK then begin
                                            CampaignList.GetRecord(Campaign);
                                            SalesCode := Campaign."No.";
                                        end;
                                    end;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateSalesCode;
                        end;
                    }
                    field("Currency.Code"; Currency.Code)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Currency Code';
                        TableRelation = Currency;
                        ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            SalesCodeCtrlEnable := true;
        end;

        trigger OnOpenPage()
        begin
            VerifyPriceSetup();
            if DateReq = 0D then
                DateReq := WorkDate;

            SalesCodeCtrlEnable := true;
            if SalesType = SalesType::"All Customers" then
                SalesCodeCtrlEnable := false;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ValidateSalesCode();

        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        if CustPriceGr.Code <> '' then
            CustPriceGr.Find;

        SetCurrency;
    end;

    var
        Text000: Label 'Incl.';
        Text001: Label 'Excl.';
        Text002: Label 'Page %1';
        Text003: Label 'As of %1';
        CompanyInfo: Record "Company Information";
        CustPriceGr: Record "Customer Price Group";
        Cust: Record Customer;
        Campaign: Record Campaign;
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesPrice: Record "Sales Price" temporary;
        SalesLineDisc: Record "Sales Line Discount" temporary;
        ContBusRel: Record "Contact Business Relation";
        GLSetup: Record "General Ledger Setup";
        PriceSourceList: Codeunit "Price Source List";
        FormatAddr: Codeunit "Format Address";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceSourceType: Enum "Price Source Type";
        VATText: Text[20];
        DateReq: Date;
        PriceCalcMethod: Enum "Price Calculation Method";
        CompanyAddr: array[8] of Text[100];
        CurrencyText: Text[30];
        UnitOfMeasure: Code[10];
        SalesType: Option Customer,"Customer Price Group","All Customers",Campaign;
        SalesCode: Code[20];
        CustNo: Code[20];
        ContNo: Code[20];
        CampaignNo: Code[20];
        ItemNo: Code[20];
        ItemDesc: Text[100];
        SalesDesc: Text[100];
        CustPriceGrCode: Code[10];
        CustDiscGrCode: Code[20];
        IsFirstSalesPrice: Boolean;
        IsFirstSalesLineDisc: Boolean;
        PricesInCurrency: Boolean;
        CurrencyFactor: Decimal;
        [InDataSet]
        SalesCodeCtrlEnable: Boolean;
        Text004: Label 'You must specify a sales code, if the sales type is different from All Customers.';
        PriceListCaptionLbl: Label 'Price List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        ItemNoCaptionLbl: Label 'Item No.';
        ItemDescCaptionLbl: Label 'Description';
        UnitOfMeasureCaptionLbl: Label 'Unit of Measure';
        MinimumQuantityCaptionLbl: Label 'Minimum Quantity';
        VATTextCaptionLbl: Label 'VAT';
        NativeCalculationErr: Label 'The Business Central (Version 15.0) must be selected on the Price Calculation Method page.';

    local procedure VerifyPriceSetup()
    var
        PriceCalculationSetup: record "Price Calculation Setup";
    begin
        with PriceCalculationSetup do
            if FindDefault(Method::"Lowest Price", Type::Sale) then
                if Implementation <> Implementation::"Business Central (Version 15.0)" then
                    Error(NativeCalculationErr);
    end;

    local procedure SetCurrency()
    begin
        PricesInCurrency := Currency.Code <> '';
        if PricesInCurrency then begin
            Currency.Find;
            CurrencyText := ' (' + Currency.Code + ')';
            CurrencyFactor := 0;
        end else
            GLSetup.Get();
    end;

    local procedure ConvertPricetoUoM(var UOMCode: Code[10]; var UnitPrice: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if UOMCode = '' then begin
            UnitPrice :=
              UnitPrice * UOMMgt.GetQtyPerUnitOfMeasure(Item, Item."Sales Unit of Measure");
            if UOMCode = '' then
                UOMCode := Item."Sales Unit of Measure"
            else
                UOMCode := Item."Base Unit of Measure";
        end;
    end;

    local procedure ConvertPriceLCYToFCY(CurrencyCode: Code[10]; var UnitPrice: Decimal)
    begin
        if PricesInCurrency then begin
            if CurrencyCode = '' then begin
                if CurrencyFactor = 0 then begin
                    Currency.TestField("Unit-Amount Rounding Precision");
                    CurrencyFactor := CurrExchRate.ExchangeRate(DateReq, Currency.Code);
                end;
                UnitPrice := CurrExchRate.ExchangeAmtLCYToFCY(DateReq, Currency.Code, UnitPrice, CurrencyFactor);
            end;
            UnitPrice := Round(UnitPrice, Currency."Unit-Amount Rounding Precision");
        end else
            UnitPrice := Round(UnitPrice, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure PreparePrintSalesPrice(IsVariant: Boolean)
    begin
        with SalesPrice do begin
            if PricesInCurrency then begin
                SetRange("Currency Code", Currency.Code);
                if Find('-') then begin
                    SetRange("Currency Code", '');
                    DeleteAll();
                end;
                SetRange("Currency Code");
            end;

            if IsVariant then begin
                SetRange("Variant Code", '');
                DeleteAll();
                SetRange("Variant Code");
            end;
        end;

        IsFirstSalesPrice := true;
    end;

    local procedure PrintSalesPrice(IsVariant: Boolean)
    begin
        with SalesPrice do begin
            if IsFirstSalesPrice then begin
                IsFirstSalesPrice := false;
                if not Find('-') then
                    if not IsVariant then begin
                        if SalesType = SalesType::Campaign then
                            CurrReport.Skip();

                        "Currency Code" := '';
                        "Price Includes VAT" := Item."Price Includes VAT";
                        "Unit Price" := Item."Unit Price";
                        "Unit of Measure Code" := Item."Base Unit of Measure";
                        "Minimum Quantity" := 0;
                    end else
                        CurrReport.Skip();
            end else
                if Next = 0 then
                    CurrReport.Break();

            if (SalesType = SalesType::Campaign) and ("Sales Type" <> "Sales Type"::Campaign) then
                CurrReport.Skip();

            if "Price Includes VAT" then
                VATText := Text000
            else
                VATText := Text001;
            UnitOfMeasure := "Unit of Measure Code";
            ConvertPricetoUoM(UnitOfMeasure, "Unit Price");
            ConvertPriceLCYToFCY("Currency Code", "Unit Price");
        end;
    end;

    local procedure PreparePrintSalesDisc(IsVariant: Boolean)
    begin
        with SalesLineDisc do begin
            if PricesInCurrency then begin
                SetRange("Currency Code", Currency.Code);
                if Find('-') then begin
                    SetRange("Currency Code", '');
                    DeleteAll();
                end;
                SetRange("Currency Code");
            end;

            if IsVariant then begin
                SetRange("Variant Code", '');
                DeleteAll();
                SetRange("Variant Code");
            end;
        end;

        IsFirstSalesLineDisc := true;
    end;

    local procedure PrintSalesDisc()
    begin
        with SalesLineDisc do begin
            if IsFirstSalesLineDisc then begin
                IsFirstSalesLineDisc := false;
                if not Find('-') then
                    CurrReport.Break();
            end else
                if Next = 0 then
                    CurrReport.Break();

            if (SalesType = SalesType::Campaign) and ("Sales Type" <> "Sales Type"::Campaign) then
                CurrReport.Skip();

            if "Unit of Measure Code" = '' then
                UnitOfMeasure := Item."Base Unit of Measure"
            else
                UnitOfMeasure := "Unit of Measure Code";
        end;
    end;

    local procedure SetCurrencyFactorInHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Posting Date" := DateReq;
        SalesHeader."Currency Code" := Currency.Code;
        SalesHeader.UpdateCurrencyFactor();
    end;

    procedure InitializeRequest(NewDateReq: Date; NewSalesType: Option; NewSalesCode: Code[20]; NewCurrencyCode: Code[10])
    begin
        DateReq := NewDateReq;
        SalesType := NewSalesType;
        SalesCode := NewSalesCode;
        Currency.Code := NewCurrencyCode;
    end;

    local procedure ValidateSalesCode()
    begin
        if (SalesType <> SalesType::"All Customers") and (SalesCode = '') then
            Error(Text004);

        case SalesType of
            SalesType::Customer:
                Cust.Get(SalesCode);
            SalesType::"Customer Price Group":
                CustPriceGr.Get(SalesCode);
            SalesType::Campaign:
                Campaign.Get(SalesCode);
        end;
    end;
}

