report 216 "Archived Sales Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ArchivedSalesOrder.rdlc';
    Caption = 'Archived Sales Order';

    dataset
    {
        dataitem("Sales Header Archive"; "Sales Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.", "Doc. No. Occurrence", "Version No.") WHERE("Document Type" = CONST(Order));
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed", "Version No.";
            RequestFilterHeading = 'Archived Sales Order';
            column(DocType_SalesHeaderArchive; "Document Type")
            {
            }
            column(No_SalesHeaderArchive; "No.")
            {
            }
            column(VersionNo_SalesHeaderArchive; "Version No.")
            {
            }
            column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
            {
            }
            column(VATPecentCaption; VATPecentCaptionLbl)
            {
            }
            column(VATBaseCaption; VATBaseCaptionLbl)
            {
            }
            column(VATAmountCaption; VATAmountCaptionLbl)
            {
            }
            column(VATIdentifierCaption; VATIdentifierCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(EmailCaption; EmailCaptionLbl)
            {
            }
            column(DocumentDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(AllowInvoiceDiscCaption; AllowInvoiceDiscCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(SalesHeaderCopytext; StrSubstNo(Text004, CopyText))
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(PaymentTermsDescription; PaymentTerms.Description)
                    {
                    }
                    column(ShipmentMethodDescription; ShipmentMethod.Description)
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoEmail; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccountNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(BilltoCustNo_SalesHeaderArchive; "Sales Header Archive"."Bill-to Customer No.")
                    {
                    }
                    column(DocDate_SalesHeaderArchive; Format("Sales Header Archive"."Document Date", 0, 4))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_SalesHeaderArchive; "Sales Header Archive"."VAT Registration No.")
                    {
                    }
                    column(ShipmentDate_SalesHeaderArchive; Format("Sales Header Archive"."Shipment Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No1_SalesHeaderArchive; "Sales Header Archive"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_SalesHeaderArchive; "Sales Header Archive"."Your Reference")
                    {
                    }
                    column(CustAddr7; CustAddr[7])
                    {
                    }
                    column(CustAddr8; CustAddr[8])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(PricesInclVAT_SalesHeaderArchive; "Sales Header Archive"."Prices Including VAT")
                    {
                    }
                    column(SalesHeaderArchiveVersionNo1; StrSubstNo(Text011, "Sales Header Archive"."Version No.", "Sales Header Archive"."No. of Archived Versions"))
                    {
                    }
                    column(VATBaseDiscPercent; "Sales Header Archive"."VAT Base Discount %")
                    {
                    }
                    column(PricesInclVATYesNo; Format("Sales Header Archive"."Prices Including VAT"))
                    {
                    }
                    column(PageCaption; StrSubstNo(Text005, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(VATRegNoCaption; VATRegNoCaptionLbl)
                    {
                    }
                    column(GiroNoCaption; GiroNoCaptionLbl)
                    {
                    }
                    column(BankNameCaption; BankNameCaptionLbl)
                    {
                    }
                    column(BankAccountNoCaption; BankAccountNoCaptionLbl)
                    {
                    }
                    column(ShipmentDateCaption; ShipmentDateCaptionLbl)
                    {
                    }
                    column(OrderNoCaption; OrderNoCaptionLbl)
                    {
                    }
                    column(PaymentTermsCaption; PaymentTermsCaptionLbl)
                    {
                    }
                    column(ShipmentMethodCaption; ShipmentMethodCaptionLbl)
                    {
                    }
                    column(BilltoCustNo_SalesHeaderArchiveCaption; "Sales Header Archive".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PricesInclVAT_SalesHeaderArchiveCaption; "Sales Header Archive".FieldCaption("Prices Including VAT"))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Header Archive";
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1, %2 %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Sales Line Archive"; "Sales Line Archive")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = "Sales Header Archive";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(LineAmt_SalesLineArch; TempSalesLineArchive."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Desc_SalesLineArch; "Sales Line Archive".Description)
                        {
                        }
                        column(Body3Visibility_RoundLoop; TempSalesLineArchive.Type = "Sales Line Type"::" ")
                        {
                        }
                        column(No_SalesLineArchive; "Sales Line Archive"."No.")
                        {
                        }
                        column(Quantity_SalesLineArchive; "Sales Line Archive".Quantity)
                        {
                        }
                        column(UOM_SalesLineArchive; "Sales Line Archive"."Unit of Measure")
                        {
                        }
                        column(UnitPrice_SalesLineArchive; "Sales Line Archive"."Unit Price")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(LineDisc_SalesLineArchive; "Sales Line Archive"."Line Discount %")
                        {
                        }
                        column(LineAmt_SalesLineArchive; "Sales Line Archive"."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AllowInvDisc_SalesLineArchive; "Sales Line Archive"."Allow Invoice Disc.")
                        {
                            IncludeCaption = false;
                        }
                        column(VATIdentifier_SalesLineArchive; "Sales Line Archive"."VAT Identifier")
                        {
                        }
                        column(SalesLineType; Format("Sales Line Archive".Type))
                        {
                        }
                        column(AllowInvoiceDisYesNo; Format("Sales Line Archive"."Allow Invoice Disc."))
                        {
                        }
                        column(SalesLineNo; Format("Sales Line Archive"."Line No."))
                        {
                        }
                        column(Body4Visibility_RoundLoop; TempSalesLineArchive.Type <> "Sales Line Type"::" ")
                        {
                        }
                        column(SalesLineArchInvDiscAmt; TempSalesLineArchive."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(SalesLineArchLineAmtInvDisc; TempSalesLineArchive."Line Amount" - TempSalesLineArchive."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATAmtLineText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesLineArchLineAmtInvDiscAmtVATAmt; TempSalesLineArchive."Line Amount" - TempSalesLineArchive."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(DiscountPercentCaption; DiscountPercentCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(PmtDiscVATCaption; PmtDiscVATCaptionLbl)
                        {
                        }
                        column(Desc_SalesLineArchCaption; "Sales Line Archive".FieldCaption(Description))
                        {
                        }
                        column(No_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("No."))
                        {
                        }
                        column(Quantity_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption(Quantity))
                        {
                        }
                        column(UOM_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(VATIdentifier_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("VAT Identifier"))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1, %2 %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                DimSetEntry2.SetRange("Dimension Set ID", "Sales Line Archive"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TempSalesLineArchive.Find('-')
                            else
                                TempSalesLineArchive.Next();
                            "Sales Line Archive" := TempSalesLineArchive;

                            if not "Sales Header Archive"."Prices Including VAT" and
                               (TempSalesLineArchive."VAT Calculation Type" = TempSalesLineArchive."VAT Calculation Type"::"Full VAT")
                            then
                                TempSalesLineArchive."Line Amount" := 0;

                            if (TempSalesLineArchive.Type = TempSalesLineArchive.Type::"G/L Account") and (not ShowInternalInfo) then
                                "Sales Line Archive"."No." := '';
                        end;

                        trigger OnPostDataItem()
                        begin
                            TempSalesLineArchive.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := TempSalesLineArchive.Find('+');
                            while MoreLines and (TempSalesLineArchive.Description = '') and (TempSalesLineArchive."Description 2" = '') and
                                  (TempSalesLineArchive."No." = '') and (TempSalesLineArchive.Quantity = 0) and
                                  (TempSalesLineArchive.Amount = 0)
                            do
                                MoreLines := TempSalesLineArchive.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempSalesLineArchive.SetRange("Line No.", 0, TempSalesLineArchive."Line No.");
                            SetRange(Number, 1, TempSalesLineArchive.Count);
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvoiceDiscountAmt; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
                        {
                        }
                        column(LineAmountCaption; LineAmountCaptionLbl)
                        {
                        }
                        column(VATAmountLine__EC_Amount; TempVATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Pct; TempVATAmountLine."EC %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VAT_EC_BaseCaption; VAT_EC_Base_CaptionLbl)
                        {
                        }
                        column(EC_Amount_Caption; EC_Amount_CaptionLbl)
                        {
                        }
                        column(EC_Pct_Caption; EC_Pct_CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmount = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(VATCounterLCY; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VALExchRate; VALExchRate)
                        {
                        }
                        column(VALSpecLCYHeader; VALSpecLCYHeader)
                        {
                        }
                        column(VALVATBaseLCY; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT1; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier1; TempVATAmountLine."VAT Identifier")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "Sales Header Archive"."Posting Date", "Sales Header Archive"."Currency Code",
                                "Sales Header Archive"."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "Sales Header Archive"."Posting Date", "Sales Header Archive"."Currency Code",
                                "Sales Header Archive"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Header Archive"."Currency Code" = '') or
                               (TempVATAmountLine.GetTotalVATAmount() = 0)
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text007 + Text008
                            else
                                VALSpecLCYHeader := Text007 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Sales Header Archive"."Posting Date", "Sales Header Archive"."Currency Code", 1);
                            VALExchRate := StrSubstNo(Text009, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(SelltoCustNo_SalesHeaderArchive; "Sales Header Archive"."Sell-to Customer No.")
                        {
                        }
                        column(ShipToAddr8; ShipToAddr[8])
                        {
                        }
                        column(ShipToAddr7; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddressCaption; ShipToAddressCaptionLbl)
                        {
                        }
                        column(SelltoCustNo_SalesHeaderArchiveCaption; "Sales Header Archive".FieldCaption("Sell-to Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    TempSalesHeader: Record "Sales Header" temporary;
                    TempSalesLine: Record "Sales Line" temporary;
                begin
                    InitTempLines(TempSalesHeader, TempSalesLine);

                    VATAmount := TempVATAmountLine.GetTotalVATAmount();
                    VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    VATDiscountAmount :=
                      TempVATAmountLine.GetTotalVATDiscount(TempSalesHeader."Currency Code", TempSalesHeader."Prices Including VAT");
                    TotalAmountInclVAT := TempVATAmountLine.GetTotalAmountInclVAT();

                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"SalesCount-PrintedArch", "Sales Header Archive");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Sales Header Archive");
                FormatDocumentFields("Sales Header Archive");

                if not CompanyBankAccount.Get("Sales Header Archive"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                CalcFields("No. of Archived Versions");
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the report to show information that is only for internal use.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        PrepmtPaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempSalesLineArchive: Record "Sales Line Archive" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        OutputNo: Integer;

        Text001: Label 'Total %1';
        Text004: Label 'Sales Order Archived %1', Comment = '%1 = Document No.';
        Text005: Label 'Page %1';
        Text007: Label 'VAT Amount Specification in ';
        Text008: Label 'Local Currency';
        Text009: Label 'Exchange rate: %1/%2';
        Text011: Label 'Version %1 of %2';
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccountNoCaptionLbl: Label 'Account No.';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
        OrderNoCaptionLbl: Label 'Order No.';
        PaymentTermsCaptionLbl: Label 'Payment Terms';
        ShipmentMethodCaptionLbl: Label 'Shipment Method';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        DiscountPercentCaptionLbl: Label 'Discount %';
        AmountCaptionLbl: Label 'Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        PmtDiscVATCaptionLbl: Label 'Payment Discount on VAT';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        LineAmountCaptionLbl: Label 'Line Amount';
        ShipToAddressCaptionLbl: Label 'Ship-to Address';
        InvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        VATPecentCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmountCaptionLbl: Label 'VAT Amount';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        TotalCaptionLbl: Label 'Total';
        HomePageCaptionLbl: Label 'Home Page';
        EmailCaptionLbl: Label 'E-Mail';
        DocumentDateCaptionLbl: Label 'Document Date';
        AllowInvoiceDiscCaptionLbl: Label 'Allow Invoice Discount';
        TotalInclVAT_EC_Lbl: Label 'Total %1 Incl. VAT+EC', Comment = '%1 - Currency Code';
        TotalExclVAT_EC_Lbl: Label 'Total %1 Excl. VAT+EC', Comment = '%1 - Currency Code';
        VAT_EC_Base_CaptionLbl: Label 'VAT + EC Base';
        EC_Pct_CaptionLbl: Label 'EC %';
        EC_Amount_CaptionLbl: Label 'EC Amount';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var SalesHeaderArchive: Record "Sales Header Archive")
    begin
        FormatAddr.GetCompanyAddr(SalesHeaderArchive."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.SalesHeaderArchBillTo(CustAddr, SalesHeaderArchive);
        ShowShippingAddr := FormatAddr.SalesHeaderArchShipTo(ShipToAddr, CustAddr, SalesHeaderArchive);
    end;

    local procedure FormatDocumentFields(SalesHeaderArchive: Record "Sales Header Archive")
    begin
        with SalesHeaderArchive do begin
            if "Currency Code" = '' then begin
                GLSetup.TestField("LCY Code");
                TotalText := StrSubstNo(Text001, GLSetup."LCY Code");
                TotalInclVATText := StrSubstNo(TotalInclVAT_EC_Lbl, GLSetup."LCY Code");
                TotalExclVATText := StrSubstNo(TotalExclVAT_EC_Lbl, GLSetup."LCY Code");
            end else begin
                TotalText := StrSubstNo(Text001, "Currency Code");
                TotalInclVATText := StrSubstNo(TotalInclVAT_EC_Lbl, "Currency Code");
                TotalExclVATText := StrSubstNo(TotalExclVAT_EC_Lbl, "Currency Code");
            end;
            FormatDocument.SetSalesPerson(SalesPurchPerson, "Salesperson Code", SalesPersonText);
            FormatDocument.SetPaymentTerms(PaymentTerms, "Payment Terms Code", "Language Code");
            FormatDocument.SetPaymentTerms(PrepmtPaymentTerms, "Prepmt. Payment Terms Code", "Language Code");
            FormatDocument.SetShipmentMethod(ShipmentMethod, "Shipment Method Code", "Language Code");

            ReferenceText := FormatDocument.SetText("Your Reference" <> '', FieldCaption("Your Reference"));
            VATNoText := FormatDocument.SetText("VAT Registration No." <> '', FieldCaption("VAT Registration No."));
        end;
    end;

    local procedure InitTempLines(var TempSalesHeader: Record "Sales Header" temporary; var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLineArchive.CopyTempLines("Sales Header Archive", TempSalesLine);

        TempVATAmountLine.DeleteAll();
        TempSalesHeader.TransferFields("Sales Header Archive");
        TempSalesLine."Prepayment Line" := true;  // used as flag in CalcVATAmountLines -> not invoice rounding
        TempSalesLine.CalcVATAmountLines(0, TempSalesHeader, TempSalesLine, TempVATAmountLine);
    end;
}

