report 210 "Blanket Sales Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BlanketSalesOrder.rdlc';
    Caption = 'Blanket Sales Order';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST("Blanket Order"));
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Blanket Sales Order';
            column(No_SalesHeader; "No.")
            {
            }
            column(SellToContactPhoneNoLbl; SellToContactPhoneNoLbl)
            {
            }
            column(SellToContactMobilePhoneNoLbl; SellToContactMobilePhoneNoLbl)
            {
            }
            column(SellToContactEmailLbl; SellToContactEmailLbl)
            {
            }
            column(BillToContactPhoneNoLbl; BillToContactPhoneNoLbl)
            {
            }
            column(BillToContactMobilePhoneNoLbl; BillToContactMobilePhoneNoLbl)
            {
            }
            column(BillToContactEmailLbl; BillToContactEmailLbl)
            {
            }
            column(SellToContactPhoneNo; SellToContact."Phone No.")
            {
            }
            column(SellToContactMobilePhoneNo; SellToContact."Mobile Phone No.")
            {
            }
            column(SellToContactEmail; SellToContact."E-Mail")
            {
            }
            column(BillToContactPhoneNo; BillToContact."Phone No.")
            {
            }
            column(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
            {
            }
            column(BillToContactEmail; BillToContact."E-Mail")
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
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(BlanketSalesOrderCopyText; StrSubstNo(Text11500, CopyText))
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
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
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
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(SalesHeaderBilltoCustNo; "Sales Header"."Bill-to Customer No.")
                    {
                    }
                    column(DocDateCaption; DocDateCaptionLbl)
                    {
                    }
                    column(SalesHeaderDocDate; Format("Sales Header"."Document Date", 0, '<Day,2>.<Month,2>.<Year4>'))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(SalesHeaderVATRegNo; "Sales Header"."VAT Registration No.")
                    {
                    }
                    column(SalesHeaderShipmentDate; Format("Sales Header"."Shipment Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(SalesHeaderNo1; "Sales Header"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(SalesHeaderYourRef; "Sales Header"."Your Reference")
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
                    column(SalesHeaderPricesIncludingVAT; "Sales Header"."Prices Including VAT")
                    {
                    }
                    column(PageCaption; StrSubstNo(Text005, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(SalesHeaderPricesIncludingVATFormatted; Format("Sales Header"."Prices Including VAT"))
                    {
                    }
                    column(PhNoCaption; PhNoCaptionLbl)
                    {
                    }
                    column(FaxNoCaption; FaxNoCaptionLbl)
                    {
                    }
                    column(VATRegNoCaption; VATRegNoCaptionLbl)
                    {
                    }
                    column(GiroNoCaption; GiroNoCaptionLbl)
                    {
                    }
                    column(BankCaption; BankCaptionLbl)
                    {
                    }
                    column(AccNoCaption; AccNoCaptionLbl)
                    {
                    }
                    column(CustNoCaption; CustNoCaptionLbl)
                    {
                    }
                    column(SalesHeaderBilltoCustNoCaption; "Sales Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(ShipmentDateCaption; ShipmentDateCaptionLbl)
                    {
                    }
                    column(BlanketSalesOrderNoCaption; BlanketSalesOrderNoCaptionLbl)
                    {
                    }
                    column(SalesHeaderPricesIncludingVATCaption; "Sales Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(HeaderLabel1; HeaderLabel[1])
                    {
                    }
                    column(HeaderLabel2; HeaderLabel[2])
                    {
                    }
                    column(HeaderLabel3; HeaderLabel[3])
                    {
                    }
                    column(HeaderLabel4; HeaderLabel[4])
                    {
                    }
                    column(HeaderLabel5; HeaderLabel[5])
                    {
                    }
                    column(HeaderLabel6; HeaderLabel[6])
                    {
                    }
                    column(HeaderLabel7; HeaderLabel[7])
                    {
                    }
                    column(HeaderLabel8; HeaderLabel[8])
                    {
                    }
                    column(HeaderTxt1; HeaderTxt[1])
                    {
                    }
                    column(HeaderTxt2; HeaderTxt[2])
                    {
                    }
                    column(HeaderTxt3; HeaderTxt[3])
                    {
                    }
                    column(HeaderTxt4; HeaderTxt[4])
                    {
                    }
                    column(HeaderTxt5; HeaderTxt[5])
                    {
                    }
                    column(HeaderTxt6; HeaderTxt[6])
                    {
                    }
                    column(HeaderTxt7; HeaderTxt[7])
                    {
                    }
                    column(HeaderTxt8; HeaderTxt[8])
                    {
                    }
                    column(FooterLabel1; FooterLabel[1])
                    {
                    }
                    column(FooterLabel2; FooterLabel[2])
                    {
                    }
                    column(FooterLabel3; FooterLabel[3])
                    {
                    }
                    column(FooterLabel4; FooterLabel[4])
                    {
                    }
                    column(FooterLabel5; FooterLabel[5])
                    {
                    }
                    column(FooterLabel6; FooterLabel[6])
                    {
                    }
                    column(FooterLabel7; FooterLabel[7])
                    {
                    }
                    column(FooterLabel8; FooterLabel[8])
                    {
                    }
                    column(FooterTxt1; FooterTxt[1])
                    {
                    }
                    column(FooterTxt2; FooterTxt[2])
                    {
                    }
                    column(FooterTxt3; FooterTxt[3])
                    {
                    }
                    column(FooterTxt4; FooterTxt[4])
                    {
                    }
                    column(FooterTxt5; FooterTxt[5])
                    {
                    }
                    column(FooterTxt6; FooterTxt[6])
                    {
                    }
                    column(FooterTxt7; FooterTxt[7])
                    {
                    }
                    column(FooterTxt8; FooterTxt[8])
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimensionLoop1Number; DimensionLoop1.Number)
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
                    dataitem("Sales Line"; "Sales Line")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(SalesLineTypeInt; SalesLineTypeInt)
                        {
                        }
                        column(SalesHeaderVATBaseDisc; "Sales Header"."VAT Base Discount %")
                        {
                        }
                        column(TotalSalesInvDiscAmount; TotalSalesInvDiscAmount)
                        {
                        }
                        column(TotalSalesLineAmount; TotalSalesLineAmount)
                        {
                        }
                        column(SalesLineLineNo; "Sales Line"."Line No.")
                        {
                        }
                        column(SalesLineLineAmount; SalesLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesLineDescription; SalesLine.Description)
                        {
                        }
                        column(SalesLineNo; "Sales Line"."No.")
                        {
                        }
                        column(SalesLineDescription1; "Sales Line".Description)
                        {
                        }
                        column(SalesLineQuantity; "Sales Line".Quantity)
                        {
                        }
                        column(SalesLineUnitofMeasure; "Sales Line"."Unit of Measure")
                        {
                        }
                        column(SalesLineLineAmount1; "Sales Line"."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesLineVAT; "Sales Line"."VAT %")
                        {
                        }
                        column(SalesLineUnitPrice; "Sales Line"."Unit Price")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(SalesLineShipmentDateFormatted; Format("Sales Line"."Shipment Date"))
                        {
                            AutoFormatType = 1;
                        }
                        column(SalesLineVATIdentifier; "Sales Line"."VAT Identifier")
                        {
                        }
                        column(NegOfSalesLineInvDiscAmt; -SalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(SalesLineLineAmtExclSalesLineInvDiscAmt; SalesLine."Line Amount" - SalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATAmtText; VATAmountLine.VATAmountText)
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesLineLineAmtExclSalesLineInvDiscAmtInclVATAmt; SalesLine."Line Amount" - SalesLine."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATDiscountAmt; VATDiscountAmount)
                        {
                        }
                        column(NegOfVATDiscAmt; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmtInclVAT; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseAmt; VATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesLineDescCaption; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(SalesLineNoCaption; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(SalesLineQuantityCaption; "Sales Line".FieldCaption(Quantity))
                        {
                        }
                        column(SalesLineUnitofMeasureCaption; "Sales Line".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmtCaptionLbl)
                        {
                        }
                        column(ShipmentDateCaption_SalesLine; ShipmentDateCaptionLbl)
                        {
                        }
                        column(SalesLineVATIdentifierCaption; "Sales Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(VATCaption; VATCaptionLbl)
                        {
                        }
                        column(VATDiscAmtCaption; VATDiscAmtCaptionLbl)
                        {
                        }
                        column(NewPageGroupNo; NewPageGroupNo)
                        {
                        }
                        column(NewPageLine; NewPageLine)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.Find('-') then
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Sales Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                SalesLine.Find('-')
                            else
                                SalesLine.Next;
                            "Sales Line" := SalesLine;

                            if not "Sales Header"."Prices Including VAT" and
                               (SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT")
                            then
                                SalesLine."Line Amount" := 0;

                            if (SalesLine.Type = SalesLine.Type::"G/L Account") and (not ShowInternalInfo) then
                                "Sales Line"."No." := '';

                            SalesLineTypeInt := SalesLine.Type.AsInteger();
                            TotalSalesLineAmount += SalesLine."Line Amount";
                            TotalSalesInvDiscAmount += SalesLine."Inv. Discount Amount";

                            NewPageLine := "Sales Line".Type = "Sales Line".Type::"New Page";
                            if NewPageLine then
                                NewPageGroupNo += 1;
                        end;

                        trigger OnPostDataItem()
                        begin
                            SalesLine.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := SalesLine.Find('+');
                            while MoreLines and (SalesLine.Description = '') and (SalesLine."Description 2" = '') and
                                  (SalesLine."No." = '') and (SalesLine.Quantity = 0) and
                                  (SalesLine.Amount = 0)
                            do
                                MoreLines := SalesLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SalesLine.SetRange("Line No.", 0, SalesLine."Line No.");
                            SetRange(Number, 1, SalesLine.Count);

                            TotalSalesLineAmount := 0;
                            TotalSalesInvDiscAmount := 0;

                            NewPageLine := false;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmountLineVATBase; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATAmount; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineLineAmount; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineInvDiscBaseAmount; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineInvoiceDiscountAmount; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLineVATIdentifier; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATCaption_VATCounter; VATCaptionLbl)
                        {
                        }
                        column(VATBaseCaption; VATBaseCaptionLbl)
                        {
                        }
                        column(VATAmtCaption; VATAmtCaptionLbl)
                        {
                        }
                        column(VATAmtSpecificationCaption; VATAmtSpecificationCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption; VATIdentifierCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmountCaption; InvDiscBaseAmountCaptionLbl)
                        {
                        }
                        column(LineAmountCaption; LineAmountCaptionLbl)
                        {
                        }
                        column(InvoiceDiscountAmountCaption; InvoiceDiscountAmountCaptionLbl)
                        {
                        }
                        column(VATAmountLineVATBaseCaption; VATAmtLineVATBaseCaptionLbl)
                        {
                        }
                        column(TotCaption; TotCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmount = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
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
                        column(VALVATAmountLCY; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT_VATCounterLCY; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLineVATIdentifier_VATCounterLCY; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountCaption; VATAmountCaptionLbl)
                        {
                        }
                        column(VATBaseCaption_VATCounterLCY; VATBaseCaptionLbl)
                        {
                        }
                        column(VATCaption_VATCounterLCY; VATCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption__VATCounterLCY; VATIdentifierCaptionLbl)
                        {
                        }
                        column(VALVATBaseLCYCaption; VALVATBaseLCYCaptionLbl)
                        {
                        }
                        column(VATBaseLCYCaption; VATBaseLCYCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              VATAmountLine.GetBaseLCY(
                                "Sales Header"."Posting Date", "Sales Header"."Currency Code", "Sales Header"."Currency Factor");
                            VALVATAmountLCY :=
                              VATAmountLine.GetAmountLCY(
                                "Sales Header"."Posting Date", "Sales Header"."Currency Code", "Sales Header"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Header"."Currency Code" = '') or
                               (VATAmountLine.GetTotalVATAmount = 0)
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, VATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text007 + Text008
                            else
                                VALSpecLCYHeader := Text007 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency(WorkDate, "Sales Header"."Currency Code", 1);
                            VALExchRate := StrSubstNo(Text009, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(PaymentTermsDescription; PaymentTerms.Description)
                        {
                        }
                        column(ShipmentMethodDescription; ShipmentMethod.Description)
                        {
                        }
                        column(PaymentTermsCaption; PaymentTermsCaptionLbl)
                        {
                        }
                        column(ShipmentMethodCaption; ShipmentMethodCaptionLbl)
                        {
                        }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    SalesPost: Codeunit "Sales-Post";
                begin
                    Clear(SalesLine);
                    Clear(SalesPost);
                    SalesLine.DeleteAll();
                    VATAmountLine.DeleteAll();
                    SalesPost.GetSalesLines("Sales Header", SalesLine, 0);
                    SalesLine.CalcVATAmountLines(0, "Sales Header", SalesLine, VATAmountLine);
                    SalesLine.UpdateVATOnLines(0, "Sales Header", SalesLine, VATAmountLine);
                    VATAmount := VATAmountLine.GetTotalVATAmount;
                    VATBaseAmount := VATAmountLine.GetTotalVATBase;
                    VATDiscountAmount :=
                      VATAmountLine.GetTotalVATDiscount("Sales Header"."Currency Code", "Sales Header"."Prices Including VAT");
                    TotalAmountInclVAT := VATAmountLine.GetTotalAmountInclVAT;

                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Sales-Printed", "Sales Header");
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

                FormatAddressFields("Sales Header");
                FormatDocumentFields("Sales Header");
                if SellToContact.Get("Sell-to Contact No.") then;
                if BillToContact.Get("Bill-to Contact No.") then;

                if not CompanyBankAccount.Get("Sales Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                PrepareHeader;
                PrepareFooter;

                if not IsReportInPreviewMode then
                    if ArchiveDocument then
                        ArchiveManagement.StoreSalesDocument("Sales Header", LogInteraction);
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
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies whether to archive the order.';

                        trigger OnValidate()
                        begin
                            if not ArchiveDocument then
                                LogInteraction := false;
                        end;
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to log this interaction.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
            ArchiveDocument := SalesSetup."Archive Blanket Orders";
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction;
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        SalesSetup.Get();
        FormatDocument.SetLogoPosition(SalesSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);

        NewPageGroupNo := 0;
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode then
            if "Sales Header".FindSet() then
                repeat
                    "Sales Header".CalcFields("No. of Archived Versions");
                    if "Sales Header"."Bill-to Contact No." <> '' then
                        SegManagement.LogDocument(
                          2, "Sales Header"."No.", "Sales Header"."Doc. No. Occurrence",
                          "Sales Header"."No. of Archived Versions", DATABASE::Contact, "Sales Header"."Bill-to Contact No.",
                          "Sales Header"."Salesperson Code", "Sales Header"."Campaign No.", "Sales Header"."Posting Description",
                          "Sales Header"."Opportunity No.")
                    else
                        SegManagement.LogDocument(
                          2, "Sales Header"."No.", "Sales Header"."Doc. No. Occurrence",
                          "Sales Header"."No. of Archived Versions", DATABASE::Customer, "Sales Header"."Bill-to Customer No.",
                          "Sales Header"."Salesperson Code", "Sales Header"."Campaign No.", "Sales Header"."Posting Description",
                          "Sales Header"."Opportunity No.");

                until "Sales Header".Next() = 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        Text004: Label 'Blanket Sales Order %1', Comment = '%1 = Document No.';
        Text005: Label 'Page %1';
        GLSetup: Record "General Ledger Setup";
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo3: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        CompanyBankAccount: Record "Bank Account";
        CompanyInfo: Record "Company Information";
        VATAmountLine: Record "VAT Amount Line" temporary;
        SalesLine: Record "Sales Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        ArchiveManagement: Codeunit ArchiveManagement;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[30];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        SalesLineTypeInt: Integer;
        OutputNo: Integer;
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
        LogInteraction: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        TotalSalesLineAmount: Decimal;
        TotalSalesInvDiscAmount: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        Text007: Label 'VAT Amount Specification in ';
        Text008: Label 'Local Currency';
        Text009: Label 'Exchange rate: %1/%2';
        ArchiveDocument: Boolean;
        [InDataSet]
        LogInteractionEnable: Boolean;
        PhNoCaptionLbl: Label 'Phone No.';
        FaxNoCaptionLbl: Label 'Fax No.';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankCaptionLbl: Label 'Bank';
        AccNoCaptionLbl: Label 'Account No.';
        CustNoCaptionLbl: Label 'Customer No.';
        DocDateCaptionLbl: Label 'Date';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
        BlanketSalesOrderNoCaptionLbl: Label 'Blanket Sales Order No.';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        AmtCaptionLbl: Label 'Amount';
        ContinuedCaptionLbl: Label 'Continued';
        InvDiscAmtCaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        VATDiscAmtCaptionLbl: Label 'Payment Discount on VAT';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        InvDiscBaseAmountCaptionLbl: Label 'Inv. Disc. Base Amount';
        LineAmountCaptionLbl: Label 'Line Amount';
        InvoiceDiscountAmountCaptionLbl: Label 'Invoice Discount Amount';
        VATAmtLineVATBaseCaptionLbl: Label 'Continued';
        TotCaptionLbl: Label 'Total';
        VATAmountCaptionLbl: Label 'VAT Amount';
        VALVATBaseLCYCaptionLbl: Label 'Continued';
        VATBaseLCYCaptionLbl: Label 'Total';
        PaymentTermsCaptionLbl: Label 'Payment Terms';
        ShipmentMethodCaptionLbl: Label 'Shipment Method';
        ShiptoAddrCaptionLbl: Label 'Ship-to Address';
        SellToContactPhoneNoLbl: Label 'Sell-to Contact Phone No.';
        SellToContactMobilePhoneNoLbl: Label 'Sell-to Contact Mobile Phone No.';
        SellToContactEmailLbl: Label 'Sell-to Contact E-Mail';
        BillToContactPhoneNoLbl: Label 'Bill-to Contact Phone No.';
        BillToContactMobilePhoneNoLbl: Label 'Bill-to Contact Mobile Phone No.';
        BillToContactEmailLbl: Label 'Bill-to Contact E-Mail';
        Text11500: Label 'Blanket Order %1';
        FooterLabel: array[20] of Text[30];
        FooterTxt: array[20] of Text;
        HeaderLabel: array[20] of Text[30];
        HeaderTxt: array[20] of Text;
        CurrGroupPageNO: Integer;
        CurrPageFooterHiddenFlg: Integer;
        CurrPageHeaderHiddenFlg: Integer;
        InnerGroupPageNO: Integer;
        NewPageGroupNo: Integer;
        NewPageLine: Boolean;

    procedure InitializeRequest(NewNoOfCopies: Integer; NewShowInternalInfo: Boolean; NewArchiveDocument: Boolean; NewLogInteraction: Boolean)
    begin
        NoOfCopies := NewNoOfCopies;
        ShowInternalInfo := NewShowInternalInfo;
        ArchiveDocument := NewArchiveDocument;
        LogInteraction := NewLogInteraction;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;

    local procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractTmplCode(2) <> '';
    end;

    local procedure FormatAddressFields(var SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            FormatAddr.GetCompanyAddr("Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
            FormatAddr.SalesHeaderBillTo(CustAddr, SalesHeader);
            ShowShippingAddr := FormatAddr.SalesHeaderShipTo(ShipToAddr, CustAddr, SalesHeader);
        end;
    end;

    local procedure FormatDocumentFields(SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do begin
            FormatDocument.SetTotalLabels("Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
            FormatDocument.SetSalesPerson(SalesPurchPerson, "Salesperson Code", SalesPersonText);
            FormatDocument.SetPaymentTerms(PaymentTerms, "Payment Terms Code", "Language Code");
            FormatDocument.SetShipmentMethod(ShipmentMethod, "Shipment Method Code", "Language Code");

            ReferenceText := FormatDocument.SetText("Your Reference" <> '', FieldCaption("Your Reference"));
            VATNoText := FormatDocument.SetText("VAT Registration No." <> '', FieldCaption("VAT Registration No."));
        end;
    end;

    [Scope('OnPrem')]
    procedure PrepareHeader()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        FormatAddr.SalesHeaderSellTo(CustAddr, "Sales Header");
        RecRef.GetTable("Sales Header");
        CHReportManagement.PrepareHeader(RecRef, REPORT::"Blanket Sales Order", HeaderLabel, HeaderTxt);
    end;

    [Scope('OnPrem')]
    procedure PrepareFooter()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable("Sales Header");
        CHReportManagement.PrepareFooter(RecRef, REPORT::"Blanket Sales Order", FooterLabel, FooterTxt);

        CurrGroupPageNO += 1;
        CurrPageFooterHiddenFlg := 0;
        CurrPageHeaderHiddenFlg := 0;
        InnerGroupPageNO := 1;
    end;
}

