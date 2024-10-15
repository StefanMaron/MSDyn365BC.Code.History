report 7054 "Res. Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ResPriceList.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Resource Price List';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Resource; Resource)
        {
            RequestFilterFields = Type, "No.";
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
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(StrsubsnoAsofFormatWorkDt; StrSubstNo(AsOfTok, Format(WorkDate(), 0, 4)))
            {
            }
            column(PhoneNo_CompanyInfo; CompanyInfo."Phone No.")
            {
            }
            column(VATResgNo_CompanyInfo; CompanyInfo."VAT Registration No.")
            {
            }
            column(GiroNo_CompanyInfo; CompanyInfo."Giro No.")
            {
            }
            column(BankName_CompanyInfo; CompanyInfo."Bank Name")
            {
            }
            column(BankAccNo_CompanyInfo; CompanyInfo."Bank Account No.")
            {
            }
            column(ResFldCaptUnitPriceCurrTxt; FieldCaption("Unit Price") + CurrencyText)
            {
            }
            column(No_Resource; "No.")
            {
            }
            column(Type_Resource; Type)
            {
                IncludeCaption = true;
            }
            column(UnitPrice_Resource; "Unit Price")
            {
            }
            column(HomePage_CompanyInfo; CompanyInfo."Home Page")
            {
            }
            column(Email_CompanyInfo; CompanyInfo."E-Mail")
            {
            }
            column(ResourceName; Name)
            {
            }
            column(ResourcePriceListCaption; ResourcePriceListCaptionLbl)
            {
            }
            column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
            {
            }
            column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
            {
            }
            column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
            {
            }
            column(CompanyInfoBankAccountNoCaption; CompanyInfoBankAccountNoCaptionLbl)
            {
            }
            column(ResourceNoCaption; ResourceNoCaptionLbl)
            {
            }
            column(WorkTypeCaption; WorkTypeCaptionLbl)
            {
            }
            column(ResourceNameCaption; ResourceNameCaptionLbl)
            {
            }
            column(WorkTypeDescriptionCaption; WorkTypeDescriptionCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(UnitPrice_ResPrice; UnitPrice)
                {
                    AutoFormatType = 2;
                }
                column(WorkTypeCode_ResPrice; WorkType.Code)
                {
                }
                column(Description_WorkType; WorkType.Description)
                {
                }

                trigger OnAfterGetRecord()
                var
                    TempPriceListLine: Record "Price List Line" temporary;
                begin
                    PriceInCurrency := false;

                    if Number = 1 then
                        Ok := TempWorkTypePriceListLine.FindSet()
                    else
                        Ok := TempWorkTypePriceListLine.Next() <> 0;
                    if not Ok then
                        CurrReport.Break();

                    FindPrice(TempWorkTypePriceListLine."Work Type Code", TempPriceListLine);
                    WorkType.Get(TempPriceListLine."Work Type Code");
                    PriceInCurrency := TempPriceListLine."Currency Code" <> '';

                    UnitPrice := TempPriceListLine."Unit Price";
                    if (Currency.Code <> '') and (not PriceInCurrency) then
                        UnitPrice :=
                          Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              WorkDate(), Currency.Code, UnitPrice,
                              CurrExchRate.ExchangeRate(
                                WorkDate(), Currency.Code)),
                            Currency."Unit-Amount Rounding Precision");
                end;

                trigger OnPostDataItem()
                begin
                    TempWorkTypePriceListLine.Reset();
                    TempWorkTypePriceListLine.SetFilter("Asset No.", '<>%1', '');
                    TempWorkTypePriceListLine.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    TempWorkTypePriceListLine.Reset();
                end;
            }

            trigger OnAfterGetRecord()
            var
                PriceListLine: Record "Price List Line";
                TempPriceListLine: Record "Price List Line" temporary;
            begin
                PriceInCurrency := false;
                FindPrice('', TempPriceListLine);
                "Unit Price" := TempPriceListLine."Unit Price";
                PriceInCurrency := TempPriceListLine."Currency Code" <> '';
                if (Currency.Code <> '') and (not PriceInCurrency) then
                    "Unit Price" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          WorkDate(), Currency.Code, "Unit Price",
                          CurrExchRate.ExchangeRate(
                            WorkDate(), Currency.Code)),
                        Currency."Unit-Amount Rounding Precision");

                PriceListLine.SetRange("Asset Type", "Price Asset Type"::Resource);
                PriceListLine.SetRange("Asset No.", "No.");
                FindWorkTypes(PriceListLine);
                PriceListLine.SetRange("Asset Type", "Price Asset Type"::"Resource Group");
                PriceListLine.SetRange("Asset No.", "Resource Group No.");
                FindWorkTypes(PriceListLine);
            end;

            trigger OnPreDataItem()
            var
                PriceListLine: Record "Price List Line";
                LineNo: Integer;
            begin
                PriceListLine.SetFilter("Currency Code", '%1|%2', Currency.Code, '');
                PriceListLine.SetRange("Asset Type", "Price Asset Type"::Resource);
                PriceListLine.SetRange("Asset No.", '');
                PriceListLine.SetFilter("Work Type Code", '<>%1', '');
                if PriceListLine.FindSet() then
                    repeat
                        TempWorkTypePriceListLine.Init();
                        TempWorkTypePriceListLine."Asset Type" := PriceListLine."Asset Type";
                        TempWorkTypePriceListLine."Work Type Code" := PriceListLine."Work Type Code";
                        LineNo += 1;
                        TempWorkTypePriceListLine."Line No." := LineNo;
                        TempWorkTypePriceListLine.Insert();
                    until PriceListLine.Next() = 0;
            end;
        }
    }

    requestpage
    {

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
                        ToolTip = 'Specifies the period for which the prices apply, such as 10/01/20...12/31/20.';
                    }
                    field(Method; PriceCalcMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Method';
                        ToolTip = 'Specifies the price calculation method.';

                        trigger OnValidate()
                        begin
                            ValidateMethod();
                        end;
                    }
                    field(Handler; format(PriceCalculationHandler))
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Handler';
                        ToolTip = 'Specifies the price calculation handler that is defined for the calculation of sales prices for the selected method.';

                        trigger OnAssistEdit()
                        begin
                            Page.RunModal(Page::"Price Calculation Methods");
                        end;
                    }
                    field(SourceTypeCtrl; SourceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Applies-to Type';
                        ToolTip = 'Specifies the price source type for which the price list should be valid.';

                        trigger OnValidate()
                        begin
                            SourceNoCtrlEnable := SourceType <> SourceType::"All Jobs";
                            PriceSource.Validate("Source Type", SourceType.AsInteger());
                            ParentSourceNo := PriceSource."Parent Source No.";
                            SourceNo := PriceSource."Source No.";
                        end;
                    }
                    field(ParentSourceNoCtrl; ParentSourceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Applies-to Parent No.';
                        Editable = false;
                        ToolTip = 'Specifies the job number which is the parent for the job task to be selected.';
                    }
                    field(SourceNoCtrl; SourceNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Applies-to No.';
                        Enabled = SourceNoCtrlEnable;
                        ToolTip = 'Specifies code for the price source type for which the price list should be valid.';

                        trigger OnLookup(var Text: Text) Result: Boolean
                        begin
                            Result := PriceSource.LookupNo();
                            if Result then begin
                                ParentSourceNo := PriceSource."Parent Source No.";
                                SourceNo := PriceSource."Source No.";
                                LookupIsComplete := true;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if LookupIsComplete then begin
                                SourceNo := PriceSource."Source No.";
                                ParentSourceNo := PriceSource."Parent Source No.";
                            end;
                            if (SourceNo = '') and (SourceType <> SourceType::"All Jobs") then
                                Error(MissSourceNoErr);

                            PriceSource.Validate("Source No.", SourceNo);
                            LookupIsComplete := false;

                            Currency.Code := PriceSource."Currency Code";
                            ParentSourceNo := PriceSource."Parent Source No.";
                            SourceNo := PriceSource."Source No.";
                        end;
                    }
                    field("Currency.Code"; Currency.Code)
                    {
                        ApplicationArea = Jobs;
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

        trigger OnOpenPage()
        begin
            if SourceType.AsInteger() = 0 then
                SourceType := SourceType::"All Jobs";
            if DateReq = 0D then
                DateReq := WorkDate();

            SourceNoCtrlEnable := SourceType <> SourceType::"All Jobs";
        end;

        trigger OnAfterGetCurrRecord()
        begin
            ValidateMethod();
        end;
    }

    labels
    {
        EMailIdCaption = 'EMail';
        HomePageCaption = 'Home Page';
    }

    trigger OnPreReport()
    begin
        if (SourceNo = '') and (SourceType <> SourceType::"All Jobs") then
            Error(MissSourceNoErr);
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);
        if Currency.Code <> '' then
            CurrencyText := ' (' + Currency.Code + ')';

        PriceSource.Validate("Source Type", SourceType.AsInteger());
        PriceSource.Validate("Parent Source No.", ParentSourceNo);
        PriceSource.Validate("Source No.", SourceNo);
        PriceSource."Currency Code" := Currency.Code;
    end;

    var
        CompanyInfo: Record "Company Information";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        PriceSource: Record "Price Source";
        TempWorkTypePriceListLine: Record "Price List Line" temporary;
        WorkType: Record "Work Type";
        FormatAddr: Codeunit "Format Address";
        PriceCalcMethod: Enum "Price Calculation Method";
        PriceCalculationHandler: Enum "Price Calculation Handler";
        SourceType: Enum "Job Price Source Type";
        CompanyAddr: array[8] of Text[100];
        DateReq: Date;
        LookupIsComplete: Boolean;
        PriceInCurrency: Boolean;
        Ok: Boolean;
        CurrencyText: Text[30];
        [InDataSet]
        SourceNoCtrlEnable: Boolean;
        ParentSourceNo: Code[20];
        SourceNo: Code[20];
        UnitPrice: Decimal;
        AsOfTok: Label 'As of %1', Comment = '%1 - a date';
        ResourcePriceListCaptionLbl: Label 'Resource - Price List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccountNoCaptionLbl: Label 'Account No.';
        ResourceNoCaptionLbl: Label 'Resource No.';
        WorkTypeCaptionLbl: Label 'Work Type';
        ResourceNameCaptionLbl: Label 'Resource Name';
        WorkTypeDescriptionCaptionLbl: Label 'Work Type Description';
        MissSourceNoErr: Label 'You must specify an Applies-to No., if the Applies-to Type is different from All Jobs.';

    local procedure FindPrice(WorkTypeCode: Code[10]; var TempPriceListLine: Record "Price List Line" temporary)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceSourceList: Codeunit "Price Source List";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
    begin
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::Resource;
        SalesLine."No." := Resource."No.";
        SalesLine."Work Type Code" := WorkTypeCode;
        SalesLine."Posting Date" := DateReq;
        if Currency.Code <> '' then begin
            SalesHeader."Posting Date" := DateReq;
            SalesHeader."Currency Code" := Currency.Code;
            SalesHeader.UpdateCurrencyFactor();
        end;
        SalesLine.GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);
        GetSourceList(PriceSourceList);
        LineWithPrice.SetSources(PriceSourceList);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.FindPrice(TempPriceListLine, false);
    end;

    local procedure GetSourceList(var PriceSourceList: Codeunit "Price Source List")
    begin
        PriceSourceList.Add("Price Source Type"::"All Jobs");
        if SourceType = SourceType::Job then begin
            PriceSourceList.IncLevel();
            PriceSourceList.Add("Price Source Type"::Job, SourceNo);
        end else
            if SourceType = SourceType::"Job Task" then begin
                PriceSourceList.IncLevel();
                PriceSourceList.Add("Price Source Type"::Job, ParentSourceNo);
                PriceSourceList.IncLevel();
                PriceSourceList.Add("Price Source Type"::"Job Task", ParentSourceNo, SourceNo);
            end;
    end;

    local procedure GetPriceHandler(Method: Enum "Price Calculation Method"): Enum "Price Calculation Handler";
    var
        PriceCalculationSetup: record "Price Calculation Setup";
    begin
        if PriceCalculationSetup.FindDefault(Method, PriceCalculationSetup.Type::Sale) then
            exit(PriceCalculationSetup.Implementation);
    end;

    local procedure ValidateMethod()
    begin
        if PriceCalcMethod = PriceCalcMethod::" " then
            PriceCalcMethod := PriceCalcMethod::"Lowest Price";
        PriceCalculationHandler := GetPriceHandler(PriceCalcMethod);
    end;

    local procedure FindWorkTypes(var PriceListLine: Record "Price List Line")
    var
        LineNo: Integer;
    begin
        TempWorkTypePriceListLine.Reset();
        if TempWorkTypePriceListLine.FindLast() then
            LineNo := TempWorkTypePriceListLine."Line No.";

        PriceListLine.SetFilter("Work Type Code", '<>%1', '');
        if PriceListLine.FindSet() then
            repeat
                TempWorkTypePriceListLine.SetRange("Work Type Code", PriceListLine."Work Type Code");
                if TempWorkTypePriceListLine.IsEmpty() then begin
                    TempWorkTypePriceListLine."Asset Type" := PriceListLine."Asset Type";
                    TempWorkTypePriceListLine."Asset No." := PriceListLine."Asset No.";
                    TempWorkTypePriceListLine."Work Type Code" := PriceListLine."Work Type Code";
                    LineNo += 1;
                    TempWorkTypePriceListLine."Line No." := LineNo;
                    TempWorkTypePriceListLine.Insert();
                end;
            until PriceListLine.Next() = 0;
    end;

    procedure InitializeRequest(NewDateReq: Date; NewSourceType: Enum "Job Price Source Type"; NewSourceNo: Code[20]; NewCurrencyCode: Code[10])
    begin
        DateReq := NewDateReq;
        SourceType := NewSourceType;
        SourceNo := NewSourceNo;
        Currency.Code := NewCurrencyCode;

        PriceSource.Validate("Source Type", SourceType.AsInteger());
        PriceSource.Validate("Source No.", SourceNo);
        PriceSource."Currency Code" := Currency.Code;
    end;
}

