report 18009 "Order Confirmation GST"
{
    DefaultLayout = RDLC;
    RDLCLayout = './rdlc/OrderConfirmation.rdl';
    Caption = 'Order Confirmation';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.")
                                where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Sales Order';

            column(DocumentType_SalesHeader; "Document Type")
            {
            }
            column(No_SalesHeader; "No.")
            {
            }
            column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
            {
            }
            column(VATPercentCaption; VATPercentCaptionLbl)
            {
            }
            column(VATBaseCaption; VATBaseCaptionLbl)
            {
            }
            column(VATAmtCaption; VATAmtCaptionLbl)
            {
            }
            column(LineAmtCaption; LineAmtCaptionLbl)
            {
            }
            column(VATIdentCaption; VATIdentCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem(CopyLoop; Integer)
            {
                DataItemTableView = sorting(Number);

                dataitem(PageLoop; Integer)
                {
                    DataItemTableView = sorting(Number)
                                        where(Number = const(1));

                    column(CompanyInfo_GST_RegistrationNo; CompanyInfo."GST Registration No.")
                    {
                    }
                    column(Customer_GST_RegistrationNo; Customer."GST Registration No.")
                    {
                    }
                    column(CompanyRegistrationLbl; CompanyRegistrationLbl)
                    {
                    }
                    column(CustomerRegistrationLbl; CustomerRegistrationLbl)
                    {
                    }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(DocumentCaptionCopyText; StrSubstNo(OrderConfLbl, CopyText))
                    {
                    }
                    column(GSTComponentCode1; GSTComponentCodeName[2] + ' Amount')
                    {
                    }
                    column(GSTComponentCode2; GSTComponentCodeName[3] + ' Amount')
                    {
                    }
                    column(GSTComponentCode3; GSTComponentCodeName[5] + ' Amount')
                    {
                    }
                    column(GSTComponentCode4; GSTComponentCodeName[6] + ' Amount')
                    {
                    }
                    column(GSTCompAmount1; Abs(GSTCompAmount[2]))
                    {
                    }
                    column(GSTCompAmount2; Abs(GSTCompAmount[3]))
                    {
                    }
                    column(GSTCompAmount3; Abs(GSTCompAmount[5]))
                    {
                    }
                    column(GSTCompAmount4; Abs(GSTCompAmount[6]))
                    {
                    }
                    column(TCSGSTCompAmount1; Abs(TCSGSTCompAmount))
                    {
                    }
                    column(IsGSTApplicable; IsGSTApplicable)
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
                    column(PaymentTermsDescription; PaymentTerms.Description)
                    {
                    }
                    column(ShipmentMethodDescription; ShipmentMethod.Description)
                    {
                    }
                    column(PrepmtPaymentTermsDescription; PrepmtPaymentTerms.Description)
                    {
                    }
                    column(CompanyInfoEMail; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
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
                    column(CompanyInfoBankAccountNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(BillToCustNo_SalesHeader; "Sales Header"."Bill-to Customer No.")
                    {
                        IncludeCaption = false;
                    }
                    column(DocumentDate_SalesHeader; Format("Sales Header"."Document Date", 0, 4))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_SalesHeader; "Sales Header"."VAT Registration No.")
                    {
                    }
                    column(ShipmentDate_SalesHeader; Format("Sales Header"."Shipment Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourReference_SalesHeader; "Sales Header"."Your Reference")
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
                    column(PricesInclVAT_SalesHeader; "Sales Header"."Prices Including VAT")
                    {
                        IncludeCaption = false;
                    }
                    column(PageCaption; PageCaptionCapLbl)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricesInclVATYesNo; Format("Sales Header"."Prices Including VAT"))
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(BillToCustNo_SalesHeaderCaption; "Sales Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PricesInclVAT_SalesHeaderCaption; "Sales Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(HomePageCaption; HomePageCaptionCapLbl)
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
                    column(BankAccNoCaption; BankAccNoCaptionLbl)
                    {
                    }
                    column(ShpDateCaption; ShpDateCaptionLbl)
                    {
                    }
                    column(OrderNoCaption; OrderNoCaptionLbl)
                    {
                    }
                    column(EMailCaption; EMailCaptionLbl)
                    {
                    }
                    column(PmtTermsDescCaption; PmtTermsDescCaptionLbl)
                    {
                    }
                    column(ShipMethodDescCaption; ShipMethodDescCaptionLbl)
                    {
                    }
                    column(PrepmtTermsDescCaption; PrepmtTermsDescCaptionLbl)
                    {
                    }
                    column(DocDateCaption; DocDateCaptionLbl)
                    {
                    }
                    column(AmtCaption; AmtCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; Integer)
                    {
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = sorting(Number)
                                            where(Number = filter(1 ..));

                        column(DimText; DimText)
                        {
                        }
                        column(Number_Integer; Number)
                        {
                        }
                        column(HdrDimsCaption; HdrDimsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimText := GetDimensionText(DimSetEntry1, Number, Continue);
                            if not Continue then
                                CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInterInf then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Sales Line"; "Sales Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"),
                                       "Document No." = field("No.");
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");


                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; Integer)
                    {
                        DataItemTableView = sorting(Number);

                        column(SalesLineAmt; TempSalesLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Desc_SalesLine; "Sales Line".Description)
                        {
                        }
                        column(NNCSalesLineLineAmt; NNC_SalesLineLineAmt)
                        {
                        }
                        column(NNCSalesLineInvDiscAmt; NNC_SalesLineInvDiscAmt)
                        {
                        }
                        column(NNCTotalLCY; NNC_TotalLCY)
                        {
                        }
                        column(NNCVATAmt; NNC_VATAmt)
                        {
                        }
                        column(NNCPmtDiscOnVAT; NNC_PmtDiscOnVAT)
                        {
                        }
                        column(NNCTotalInclVAT2; NNC_TotalInclVAT2)
                        {
                        }
                        column(NNCVatAmt2; NNC_VatAmt2)
                        {
                        }
                        column(NNCTotalExclVAT2; NNC_TotalExclVAT2)
                        {
                        }
                        column(VATBaseDisc_SalesHeader; "Sales Header"."VAT Base Discount %")
                        {
                        }
                        column(ShowInternalInfo; ShowInterInf)
                        {
                        }
                        column(No2_SalesLine; "Sales Line"."No.")
                        {
                        }
                        column(Qty_SalesLine; "Sales Line".Quantity)
                        {
                        }
                        column(UnitofMeasure_SalesLine; "Sales Line"."Unit of Measure")
                        {
                            IncludeCaption = false;
                        }
                        column(UnitPrice_SalesLine; "Sales Line"."Unit Price")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(LineDiscount_SalesLine; "Sales Line"."Line Discount %")
                        {
                        }
                        column(LineAmt_SalesLine; "Sales Line"."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(AllowInvDisc_SalesLine; "Sales Line"."Allow Invoice Disc.")
                        {
                            IncludeCaption = false;
                        }
                        column(LineDiscount_SalesLineAmount; "Sales Line"."Line Discount Amount")
                        {
                        }
                        column(VATIdentifier_SalesLine; "Sales Line"."VAT Identifier")
                        {
                        }
                        column(Type_SalesLine; Format("Sales Line".Type))
                        {
                        }
                        column(No_SalesLine; "Sales Line"."Line No.")
                        {
                        }
                        column(AllowInvoiceDisYesNo; Format("Sales Line"."Allow Invoice Disc."))
                        {
                        }
                        column(SalesLineInvDiscAmount; TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(SalesLineLineAmtInvDiscAmt; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SalesLineTaxAmount; 0)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ChargesAmount; ChargesAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(OtherTaxesAmount; OtherTaxesAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(TotalAmount; TotalAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(NNCSalesLineExciseAmt; NNC_SalesLineExciseAmt)
                        {
                        }
                        column(NNCSalesLineTaxAmt; NNC_SalesLineTaxAmt)
                        {
                        }
                        column(NNCSalesLineSvcTaxAmt; NNC_SalesLineSvcTaxAmt)
                        {
                        }
                        column(NNCSalesLineSvcTaxeCessAmt; NNC_SalesLineSvcTaxeCessAmt)
                        {
                        }
                        column(NNCSalesLineSvcSHECessAmt; NNC_SalesLineSvcSHECessAmt)
                        {
                        }
                        column(NNCSalesLineTDSTCSSHECESS; NNC_SalesLineTDSTCSSHECESS)
                        {
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(VATAmount1; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(No_SalesLineCaption; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(Description_SalesLineCaption; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(Quantity_SalesLineCaption; "Sales Line".FieldCaption(Quantity))
                        {
                        }
                        column(UnitofMeasure_SalesLineCaption; "Sales Line".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(AllowInvDisc_SalesLineCaption; "Sales Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(DiscPercentCaption; DiscPercentCaptionLbl)
                        {
                        }
                        column(LineDiscCaption; LineDiscCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(ExciseAmtCaption; ExciseAmtCaptionLbl)
                        {
                        }
                        column(TaxAmtCaption; TaxAmtCaptionLbl)
                        {
                        }
                        column(ServTaxAmtCaption; ServTaxAmtCaptionLbl)
                        {
                        }
                        column(ChargesAmtCaption; ChargesAmtCaptionLbl)
                        {
                        }
                        column(OtherTaxesAmtCaption; OtherTaxesAmtCaptionLbl)
                        {
                        }
                        column(ServTaxeCessAmtCaption; ServTaxeCessAmtCaptionLbl)
                        {
                        }
                        column(TCSAmtCaption; TCSAmtCaptionLbl)
                        {
                        }
                        column(ServTaxSHECessAmtCaption; ServTaxSHECessAmtCaptionLbl)
                        {
                        }
                        column(VATDisctAmtCaption; VATDisctAmtCaptionLbl)
                        {
                        }
                        column(NNCSalesLineSvcTaxSBCAmt; NNC_SalesLineSvcTaxSBCAmt)
                        {
                        }
                        column(ServTaxSBCAmtCaption; ServTaxSBCAmtCaptionLbl)
                        {
                        }
                        column(NNCSalesLineKKCessAmt; NNC_SalesLineKKCessAmt)
                        {
                        }
                        column(KKCessAmtCaption; KKCessAmtCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; Integer)
                        {
                            DataItemTableView = sorting(Number)
                                                where(Number = filter(1 ..));

                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimsCaption; LineDimsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := GetDimensionText(DimSetEntry2, Number, Continue);
                                if not Continue then
                                    CurrReport.Break();

                                if ShowInterInf then begin
                                    j := 1;
                                    TaxTrnasactionValue.Reset();
                                    TaxTrnasactionValue.SetRange("Tax Record ID", TempSalesLine.RecordId);
                                    TaxTrnasactionValue.SetRange("Tax Type", 'GST');
                                    TaxTrnasactionValue.SetRange("Value Type", TaxTrnasactionValue."Value Type"::COMPONENT);
                                    TaxTrnasactionValue.SetFilter(Percent, '<>%1', 0);
                                    if TaxTrnasactionValue.FindSet() then
                                        repeat
                                            j := TaxTrnasactionValue."Value ID";
                                            GSTComponentCode[j] := TaxTrnasactionValue."Value ID";
                                            TaxTrnasactionValue1.Reset();
                                            TaxTrnasactionValue1.SetRange("Tax Record ID", TempSalesLine.RecordId);
                                            TaxTrnasactionValue1.SetRange("Tax Type", 'GST');
                                            TaxTrnasactionValue1.SetRange("Value Type", TaxTrnasactionValue1."Value Type"::COMPONENT);
                                            TaxTrnasactionValue1.SetRange("Value ID", GSTComponentCode[j]);
                                            if TaxTrnasactionValue1.FindSet() then
                                                repeat
                                                    GSTCompAmount[j] += TaxTrnasactionValue1.Amount;
                                                    NNC_SalesLineTaxAmt += TaxTrnasactionValue1.Amount;
                                                    NNC_TotalGST += TaxTrnasactionValue1.Amount;
                                                until TaxTrnasactionValue1.Next() = 0;
                                            j += 1;
                                        until TaxTrnasactionValue.Next() = 0;


                                    TotalAmount := NNC_SalesLineLineAmt - NNC_SalesLineInvDiscAmt + NNC_SalesLineExciseAmt + NNC_SalesLineTaxAmt +
                                    NNC_SalesLineSvcTaxAmt + NNC_SalesLineSvcTaxeCessAmt + ChargesAmount +
                                    OtherTaxesAmount +
                                    NNC_SalesLineTDSTCSSHECESS + NNC_SalesLineSvcSHECessAmt +
                                    NNC_SalesLineSvcTaxSBCAmt + NNC_SalesLineKKCessAmt + NNC_TotalGST;
                                end;
                            end;

                            trigger OnPostDataItem()
                            begin
                                if not ShowInterInf then begin
                                    j := 1;
                                    TaxTrnasactionValue.Reset();
                                    TaxTrnasactionValue.SetRange("Tax Record ID", TempSalesLine.RecordId);
                                    TaxTrnasactionValue.SetRange("Tax Type", 'GST');
                                    TaxTrnasactionValue.SetRange("Value Type", TaxTrnasactionValue."Value Type"::COMPONENT);
                                    TaxTrnasactionValue.SetFilter(Percent, '<>%1', 0);
                                    if TaxTrnasactionValue.FindSet() then
                                        repeat
                                            j := TaxTrnasactionValue."Value ID";
                                            GSTComponentCode[j] := TaxTrnasactionValue."Value ID";
                                            TaxTrnasactionValue1.Reset();
                                            TaxTrnasactionValue1.SetRange("Tax Record ID", TempSalesLine.RecordId);
                                            TaxTrnasactionValue1.SetRange("Tax Type", 'GST');
                                            TaxTrnasactionValue1.SetRange("Value Type", TaxTrnasactionValue1."Value Type"::COMPONENT);
                                            TaxTrnasactionValue1.SetRange("Value ID", GSTComponentCode[j]);
                                            if TaxTrnasactionValue1.FindSet() then
                                                repeat
                                                    GSTCompAmount[j] += TaxTrnasactionValue1.Amount;
                                                    NNC_SalesLineTaxAmt += TaxTrnasactionValue1.Amount;
                                                    NNC_TotalGST += TaxTrnasactionValue1.Amount;
                                                until TaxTrnasactionValue1.Next() = 0;
                                            j += 1;
                                        until TaxTrnasactionValue.Next() = 0;

                                    TaxTrnasactionValue.Reset();
                                    TaxTrnasactionValue.SetRange("Tax Record ID", TempSalesLine.RecordId);
                                    TaxTrnasactionValue.SetRange("Tax Type", 'TCS');
                                    TaxTrnasactionValue.SetRange("Value Type", TaxTrnasactionValue."Value Type"::COMPONENT);
                                    TaxTrnasactionValue.SetFilter(Percent, '<>%1', 0);
                                    if TaxTrnasactionValue.FindSet() then
                                        repeat
                                            j := TaxTrnasactionValue."Value ID";
                                            TCSComponentCode[j] := TaxTrnasactionValue."Value ID";
                                            TaxTrnasactionValue2.Reset();
                                            TaxTrnasactionValue2.SetRange("Tax Record ID", TempSalesLine.RecordId);
                                            TaxTrnasactionValue2.SetRange("Tax Type", 'TCS');
                                            TaxTrnasactionValue2.SetRange("Value Type", TaxTrnasactionValue2."Value Type"::COMPONENT);
                                            TaxTrnasactionValue2.SetRange("Value ID", TCSComponentCode[j]);
                                            if TaxTrnasactionValue2.FindSet() then
                                                repeat
                                                    TCSGSTCompAmount += TaxTrnasactionValue2.Amount;
                                                until TaxTrnasactionValue2.Next() = 0;

                                            TCSGSTCompAmount := Round(TCSGSTCompAmount, 1);
                                            j += 1;
                                        until TaxTrnasactionValue.Next() = 0;

                                    TotalAmount := NNC_SalesLineLineAmt -
                                        NNC_SalesLineInvDiscAmt +
                                        NNC_SalesLineExciseAmt +
                                        NNC_SalesLineTaxAmt +
                                        NNC_SalesLineSvcTaxAmt +
                                        NNC_SalesLineSvcTaxeCessAmt +
                                        ChargesAmount +
                                        OtherTaxesAmount +
                                        NNC_SalesLineTDSTCSSHECESS +
                                        NNC_SalesLineSvcSHECessAmt +
                                        NNC_SalesLineSvcTaxSBCAmt +
                                        NNC_SalesLineKKCessAmt +
                                        TCSGSTCompAmount;
                                end;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInterInf then
                                    CurrReport.Break();

                                DimSetEntry2.SetRange("Dimension Set ID", "Sales Line"."Dimension Set ID");
                            end;
                        }
                        dataitem(AsmLoop; Integer)
                        {
                            DataItemTableView = sorting(Number);

                            column(AsmLineUnitOfMeasureText; GetUnitOfMeasureDescr(AsmLine."Unit of Measure Code"))
                            {
                            }
                            column(AsmLineQuantity; AsmLine.Quantity)
                            {
                            }
                            column(AsmLineDescription; BlanksForIndent() + AsmLine.Description)
                            {
                            }
                            column(AsmLineNo; BlanksForIndent() + AsmLine."No.")
                            {
                            }
                            column(AsmLineType; AsmLine.Type)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    AsmLine.FindSet()
                                else
                                    AsmLine.Next();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not DisplayAssemblyInformation then
                                    CurrReport.Break();

                                if not AsmInfoExistsForLine then
                                    CurrReport.Break();

                                AsmLine.SetRange("Document Type", AsmHeader."Document Type");
                                AsmLine.SetRange("Document No.", AsmHeader."No.");
                                SetRange(Number, 1, AsmLine.Count);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TempSalesLine.FindFirst()
                            else
                                TempSalesLine.Next();

                            "Sales Line" := TempSalesLine;
                            if DisplayAssemblyInformation then
                                AsmInfoExistsForLine := TempSalesLine.AsmToOrderExists(AsmHeader);

                            if not "Sales Header"."Prices Including VAT" and
                               (TempSalesLine."VAT Calculation Type" = TempSalesLine."VAT Calculation Type"::"Full VAT")
                            then
                                TempSalesLine."Line Amount" := 0;

                            NNC_SalesLineLineAmt += TempSalesLine."Line Amount";
                            NNC_SalesLineInvDiscAmt += TempSalesLine."Inv. Discount Amount";
                            NNC_TotalLCY := NNC_SalesLineLineAmt - NNC_SalesLineInvDiscAmt;
                            NNC_VATAmt := VATAmount;
                            NNC_PmtDiscOnVAT := -VATDiscountAmount;
                            NNC_TotalInclVAT2 := TotalAmountInclVAT;
                            NNC_VatAmt2 := VATAmount;
                            NNC_TotalExclVAT2 := VATBaseAmount;

                            TaxTrnasactionValue.Reset();
                            TaxTrnasactionValue.SetRange("Tax Record ID", TempSalesLine.RecordId);
                            TaxTrnasactionValue.SetRange("Tax Type", 'GST');
                            TaxTrnasactionValue.SetRange("Value Type", TaxTrnasactionValue."Value Type"::COMPONENT);
                            TaxTrnasactionValue.SetFilter(Percent, '<>%1', 0);
                            if TaxTrnasactionValue.FindSet() then
                                repeat
                                    j := TaxTrnasactionValue."Value ID";
                                    case TaxTrnasactionValue."Value ID" of
                                        6:
                                            GSTComponentCodeName[j] := 'SGST';
                                        2:
                                            GSTComponentCodeName[j] := 'CGST';
                                        3:
                                            GSTComponentCodeName[j] := 'IGST';
                                        5:
                                            GSTComponentCodeName[j] := 'UTGST';
                                    end;
                                    j += 1;
                                until TaxTrnasactionValue.Next() = 0;
                        end;

                        trigger OnPostDataItem()
                        begin
                            TempSalesLine.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := TempSalesLine.FindLast();
                            while MoreLines and (TempSalesLine.Description = '') and (TempSalesLine."Description 2" = '') and
                                  (TempSalesLine."No." = '') and (TempSalesLine.Quantity = 0) and
                                  (TempSalesLine.Amount = 0)
                            do
                                MoreLines := TempSalesLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();

                            TempSalesLine.SetRange("Line No.", 0, TempSalesLine."Line No.");
                            SetRange(Number, 1, TempSalesLine.Count);

                            NNC_SalesLineExciseAmt := 0;
                            NNC_SalesLineTaxAmt := 0;
                            NNC_SalesLineSvcTaxAmt := 0;
                            NNC_SalesLineSvcTaxeCessAmt := 0;
                            NNC_SalesLineSvcSHECessAmt := 0;
                            NNC_SalesLineTDSTCSSHECESS := 0;
                            NNC_SalesLineSvcTaxSBCAmt := 0;
                            NNC_SalesLineKKCessAmt := 0;
                        end;
                    }
                    dataitem(VATCounter; Integer)
                    {
                        DataItemTableView = sorting(Number);

                        column(VATAmountLineVATBase; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATAmount; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineLineAmount; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmtSpecCaption; VATAmtSpecCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
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
                    dataitem(VATCounterLCY; Integer)
                    {
                        DataItemTableView = sorting(Number);

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
                        column(VATAmountLineVAT1; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier1; TempVATAmountLine."VAT Identifier")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY := TempVATAmountLine.GetBaseLCY(
                                "Sales Header"."Posting Date",
                                "Sales Header"."Currency Code",
                                "Sales Header"."Currency Factor");
                            VALVATAmountLCY := TempVATAmountLine.GetAmountLCY(
                                "Sales Header"."Posting Date",
                                "Sales Header"."Currency Code",
                                "Sales Header"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Header"."Currency Code" = '') or
                               (TempVATAmountLine.GetTotalVATAmount() = 0) then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := VAtAmtSpecLbl + LocalCurrLbl
                            else
                                VALSpecLCYHeader := VAtAmtSpecLbl + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Sales Header"."Posting Date", "Sales Header"."Currency Code", 1);
                            VALExchRate := StrSubstNo(
                                ExchangeRateLbl,
                                CurrExchRate."Relational Exch. Rate Amount",
                                CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total2; Integer)
                    {
                        DataItemTableView = sorting(Number)
                                            where(Number = const(1));

                        column(SellToCustNo_SalesHeader; "Sales Header"."Sell-to Customer No.")
                        {
                            IncludeCaption = false;
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
                        column(ShipToAddrCaption; ShipToAddrCaptionLbl)
                        {
                        }
                        column(SellToCustNo_SalesHeaderCaption; "Sales Header".FieldCaption("Sell-to Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(PrepmtLoop; Integer)
                    {
                        DataItemTableView = sorting(Number)
                                            where(Number = filter(1 ..));

                        column(PrepmtLineAmount; PrepmtLineAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtInvBufDescription; TempPrepmtInvBuf.Description)
                        {
                        }
                        column(PrepmtInvBufGLAccountNo; TempPrepmtInvBuf."G/L Account No.")
                        {
                        }
                        column(TotalExclVATText1; TotalExclVATText)
                        {
                        }
                        column(PrepmtVATAmtLineVATAmtText; TempPrepmtVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalInclVATText1; TotalInclVATText)
                        {
                        }
                        column(PrepmtInvBufAmount; TempPrepmtInvBuf.Amount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtVATAmount; PrepmtVATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtInvBufAmtPrepmtVATAmt; TempPrepmtInvBuf.Amount + PrepmtVATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText1; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(PrepmtTotalAmountInclVAT; PrepmtTotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtVATBaseAmount; PrepmtVATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PmtTermsCaption; PmtTermsCaptionLbl)
                        {
                        }
                        column(GLAccNoCaption; GLAccNoCaptionLbl)
                        {
                        }
                        column(PrepmtSpecCaption; PrepmtSpecCaptionLbl)
                        {
                        }
                        dataitem(PrepmtDimLoop; Integer)
                        {
                            DataItemTableView = sorting(Number)
                                                where(Number = filter(1 ..));

                            column(DimText2; DimText)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := GetDimensionText(TempPrepmtDimSetEntry, Number, Continue);
                                if not Continue then
                                    CurrReport.Break();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not TempPrepmtInvBuf.FindFirst() then
                                    CurrReport.Break();
                            end else
                                if TempPrepmtInvBuf.Next() = 0 then
                                    CurrReport.Break();

                            if ShowInterInf then
                                DimMgt.GetDimensionSet(TempPrepmtDimSetEntry, TempPrepmtInvBuf."Dimension Set ID");

                            if "Sales Header"."Prices Including VAT" then
                                PrepmtLineAmount := TempPrepmtInvBuf."Amount Incl. VAT"
                            else
                                PrepmtLineAmount := TempPrepmtInvBuf.Amount;
                        end;
                    }
                    dataitem(PrepmtVATCounter; Integer)
                    {
                        DataItemTableView = sorting(Number);

                        column(PrepmtVATAmtLineVATAmt; TempPrepmtVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtVATAmtLineVATBase; TempPrepmtVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtVATAmtLineLineAmt; TempPrepmtVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PrepmtVATAmountLineVAT; TempPrepmtVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(PrepmtVATAmtLineVATIdentifier; TempPrepmtVATAmountLine."VAT Identifier")
                        {
                        }
                        column(PrepmtVATAmtSpecCaption; PrepmtVATAmtSpecCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempPrepmtVATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, TempPrepmtVATAmountLine.Count);
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    TempPrepmtSalesLine: Record "Sales Line" temporary;
                    SalesPost: Codeunit "Sales-Post";
                begin
                    Clear(TempSalesLine);
                    Clear(SalesPost);

                    TempVATAmountLine.DeleteAll();
                    TempSalesLine.DeleteAll();

                    SalesPost.GetSalesLines("Sales Header", TempSalesLine, 0);
                    TempSalesLine.CalcVATAmountLines(0, "Sales Header", TempSalesLine, TempVATAmountLine);
                    TempSalesLine.UpdateVATOnLines(0, "Sales Header", TempSalesLine, TempVATAmountLine);

                    VATAmount := TempVATAmountLine.GetTotalVATAmount();
                    VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    VATDiscountAmount := TempVATAmountLine.GetTotalVATDiscount(
                        "Sales Header"."Currency Code",
                        "Sales Header"."Prices Including VAT");
                    TotalAmountInclVAT := TempVATAmountLine.GetTotalAmountInclVAT();

                    TempPrepmtInvBuf.DeleteAll();
                    SalesPostPrepmt.GetSalesLines("Sales Header", 0, TempPrepmtSalesLine);

                    if not TempPrepmtSalesLine.IsEmpty then begin
                        SalesPostPrepmt.GetSalesLinesToDeduct("Sales Header", TempSalesLine);
                        if not TempSalesLine.IsEmpty then
                            SalesPostPrepmt.CalcVATAmountLines("Sales Header", TempSalesLine, TempPrepmtVATAmountLineDeduct, 1);
                    end;

                    SalesPostPrepmt.CalcVATAmountLines("Sales Header", TempPrepmtSalesLine, TempPrepmtVATAmountLine, 0);
                    TempPrepmtVATAmountLine.DeductVATAmountLine(TempPrepmtVATAmountLineDeduct);
                    SalesPostPrepmt.UpdateVATOnLines("Sales Header", TempPrepmtSalesLine, TempPrepmtVATAmountLine, 0);
                    PrepmtVATAmount := TempPrepmtVATAmountLine.GetTotalVATAmount();
                    PrepmtVATBaseAmount := TempPrepmtVATAmountLine.GetTotalVATBase();
                    PrepmtTotalAmountInclVAT := TempPrepmtVATAmountLine.GetTotalAmountInclVAT();

                    if Number > 1 then begin
                        CopyText := CopyLbl;
                        OutputNo += 1;
                    end;

                    NNC_TotalLCY := 0;
                    NNC_TotalInclVAT2 := 0;
                    NNC_VatAmt2 := 0;
                    NNC_TotalExclVAT2 := 0;
                    NNC_SalesLineLineAmt := 0;
                    NNC_SalesLineInvDiscAmt := 0;
                    TCSGSTCompAmount := 0;
                    ChargesAmount := 0;
                    TotalAmount := 0;
                    OtherTaxesAmount := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if Print then
                        SalesCountPrinted.Run("Sales Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopy) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageID("Language Code");
                IsGSTApplicable := CheckGSTDoc("Sales Line");
                Customer.Get("Bill-to Customer No.");
                if RespCenter.Get("Responsibility Center") then begin
                    FormatAddr.RespCenter(CompanyAddr, RespCenter);
                    CompanyInfo."Phone No." := RespCenter."Phone No.";
                    CompanyInfo."Fax No." := RespCenter."Fax No.";
                end else
                    FormatAddr.Company(CompanyAddr, CompanyInfo);

                DimSetEntry1.SetRange("Dimension Set ID", "Sales Header"."Dimension Set ID");

                if "Salesperson Code" = '' then begin
                    Clear(SalesPurchPerson);
                    SalesPersonText := '';
                end else begin
                    SalesPurchPerson.Get("Salesperson Code");
                    SalesPersonText := SalesPerLbl;
                end;

                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := CopyStr(FieldCaption("Your Reference"), 1, 80);

                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := CopyStr(FieldCaption("VAT Registration No."), 1, 80);

                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(TotalLbl, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(TotalIncTaxLbl, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(TotalExclTaxLbl, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(TotalLbl, "Currency Code");
                    TotalInclVATText := StrSubstNo(TotalIncTaxLbl, "Currency Code");
                    TotalExclVATText := StrSubstNo(TotalExclTaxLbl, "Currency Code");
                end;

                FormatAddr.SalesHeaderBillTo(CustAddr, "Sales Header");

                if "Payment Terms Code" = '' then
                    PaymentTerms.Init()
                else begin
                    PaymentTerms.Get("Payment Terms Code");
                    PaymentTerms.TranslateDescription(PaymentTerms, "Sales Header"."Language Code");
                end;

                if "Prepmt. Payment Terms Code" = '' then
                    PrepmtPaymentTerms.Init()
                else begin
                    PrepmtPaymentTerms.Get("Prepmt. Payment Terms Code");
                    PrepmtPaymentTerms.TranslateDescription(PrepmtPaymentTerms, "Sales Header"."Language Code");
                end;

                if "Prepmt. Payment Terms Code" = '' then
                    PrepmtPaymentTerms.Init()
                else begin
                    PrepmtPaymentTerms.Get("Prepmt. Payment Terms Code");
                    PrepmtPaymentTerms.TranslateDescription(PrepmtPaymentTerms, "Sales Header"."Language Code");
                end;

                if "Shipment Method Code" = '' then
                    PrepmtPaymentTerms.Init()
                else begin
                    ShipmentMethod.Get("Shipment Method Code");
                    ShipmentMethod.TranslateDescription(ShipmentMethod, "Sales Header"."Language Code");
                end;

                ShowShippingAddr := "Sell-to Customer No." <> "Bill-to Customer No.";
                for i := 1 TO ArrayLen(ShipToAddr) do
                    if ShipToAddr[i] <> CustAddr[i] then
                        ShowShippingAddr := true;

                if Print then begin
                    if ShowRequestPage and ArchiveDoc or
                       not ShowRequestPage and SalesSetup."Archive Orders"
                    then
                        ArchiveManagement.StoreSalesDocument("Sales Header", LogInterac);

                    if LogInterac then begin
                        CalcFields("No. of Archived Versions");
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              SegManagement.SalesOrderConfirmInterDocType(), "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", Database::Contact, "Bill-to Contact No."
                              , "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.")
                        else
                            SegManagement.LogDocument(
                              SegManagement.SalesOrderConfirmInterDocType(), "No.", "Doc. No. Occurrence",
                              "No. of Archived Versions", Database::Customer, "Bill-to Customer No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", "Opportunity No.");
                    end;
                end;

                Clear(GSTCompAmount);
                Clear(GSTComponentCodeName);
                Clear(GSTComponentCode);
            end;

            trigger OnPreDataItem()
            begin
                Print := Print or not CurrReport.Preview;
                AsmInfoExistsForLine := false;
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
                    field(NoOfCopies; NoOfCopy)
                    {
                        Caption = 'No. of Copies';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the number of copies that need to be printed.';
                    }
                    field(ShowInternalInfo; ShowInterInf)
                    {
                        Caption = 'Show Internal Information';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the line internal information';
                    }
                    field(ArchiveDocument; ArchiveDoc)
                    {
                        Caption = 'Archive Document';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies whether the document is archived or not.';

                        trigger OnValidate()
                        begin
                            if not ArchiveDoc then
                                LogInterac := false;
                        end;
                    }
                    field(LogInteraction; LogInterac)
                    {
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the log Interaction for archived document to be done or not.';

                        trigger OnValidate()
                        begin
                            if LogInterac then
                                ArchiveDoc := ArchiveDocumentEnable;
                        end;
                    }
                    field(ShowAssemblyComponents; DisplayAssemblyInformation)
                    {
                        Caption = 'Show Assembly Components';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies whether assembly components need to be printed or not.';

                    }
                }
            }
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
            ArchiveDocumentEnable := false;
        end;

        trigger OnOpenPage()
        begin
            ArchiveDoc := SalesSetup."Archive Orders";
            LogInterac := SegManagement.FindInteractTmplCode(3) <> '';
            LogInteractionEnable := LogInterac;
            ShowRequestPage := true;
        end;
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
        Customer: Record Customer;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempPrepmtVATAmountLine: Record "VAT Amount Line" temporary;
        TempPrepmtVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        TempPrepmtDimSetEntry: Record "Dimension Set Entry" temporary;
        TempPrepmtInvBuf: Record "Prepayment Inv. Line Buffer" temporary;
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        TaxTrnasactionValue: Record "Tax Transaction Value";
        TaxTrnasactionValue1: Record "Tax Transaction Value";
        TaxTrnasactionValue2: Record "Tax Transaction Value";
        Language: Codeunit Language;
        SalesCountPrinted: Codeunit "Sales-Printed";
        FormatAddr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesPostPrepmt: Codeunit "Sales-Post Prepayments";
        DimMgt: Codeunit DimensionManagement;
        GSTCompAmount: array[20] of Decimal;
        TCSGSTCompAmount: Decimal;
        TCSComponentCode: array[20] of Integer;
        GSTComponentCode: array[20] of Integer;
        CustAddr: array[8] of Text[50];
        ShipToAddr: array[8] of Text[50];
        CompanyAddr: array[8] of Text[50];
        SalesPersonText: Text[30];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopy: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        i: Integer;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInterInf: Boolean;
        Continue: Boolean;
        ArchiveDoc: Boolean;
        LogInterac: Boolean;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        PrepmtVATAmount: Decimal;
        PrepmtVATBaseAmount: Decimal;
        PrepmtTotalAmountInclVAT: Decimal;
        PrepmtLineAmount: Decimal;
        OutputNo: Integer;
        NNC_TotalLCY: Decimal;
        NNC_TotalExclVAT: Decimal;
        NNC_VATAmt: Decimal;
        NNC_TotalInclVAT: Decimal;
        NNC_PmtDiscOnVAT: Decimal;
        NNC_TotalInclVAT2: Decimal;
        NNC_VatAmt2: Decimal;
        NNC_TotalExclVAT2: Decimal;
        NNC_SalesLineLineAmt: Decimal;
        NNC_SalesLineInvDiscAmt: Decimal;
        Print: Boolean;
        ChargesAmount: Decimal;
        OtherTaxesAmount: Decimal;
        TotalAmount: Decimal;
        NNC_SalesLineSvcTaxeCessAmt: Decimal;
        NNC_SalesLineExciseAmt: Decimal;
        NNC_SalesLineTaxAmt: Decimal;
        NNC_SalesLineSvcTaxAmt: Decimal;
        NNC_SalesLineSvcSHECessAmt: Decimal;
        NNC_SalesLineTDSTCSSHECESS: Decimal;
        NNC_SalesLineAmtToCustomer: Decimal;
        NNC_TotalGST: Decimal;
        [InDataSet]
        ArchiveDocumentEnable: Boolean;
        [InDataSet]
        LogInteractionEnable: Boolean;
        DisplayAssemblyInformation: Boolean;
        AsmInfoExistsForLine: Boolean;
        GSTComponentCodeName: array[10] of Code[20];
        ShowRequestPage: Boolean;
        NNC_SalesLineSvcTaxSBCAmt: Decimal;
        NNC_SalesLineKKCessAmt: Decimal;
        IsGSTApplicable: Boolean;
        j: Integer;
        VAtAmtSpecLbl: Label 'VAT Amount Specification in ';
        LocalCurrLbl: Label 'Local Currency';
        ExchangeRateLbl: Label 'Exchange rate: %1/%2', Comment = '%1 = CurrExchRate."Relational Exch. Rate Amount" %2 = CurrExchRate."Exchange Rate Amount"';
        TotalIncTaxLbl: Label 'Total %1 Incl. Taxes', Comment = '%1 = LCY Code/Currency Code';
        TotalExclTaxLbl: Label 'Total %1 Excl. Taxes', Comment = '%1 = LCY Code/Currency Code';
        SalesPerLbl: Label 'Salesperson';
        TotalLbl: Label 'Total %1', Comment = '%1 = LCY Code/Currency Code';
        CopyLbl: Label ' COPY';
        OrderConfLbl: Label 'Order Confirmation%1', Comment = '%1 = CopyText';
        PageCaptionCapLbl: Label 'Page %1 of %2', Comment = '%1 = PageNo ,%2  = Total Page No';
        PhoneNoCaptionLbl: Label 'Phone No.';
        HomePageCaptionCapLbl: Label 'Home Page';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccNoCaptionLbl: Label 'Account No.';
        ShpDateCaptionLbl: Label 'Shipment Date';
        OrderNoCaptionLbl: Label 'Order No.';
        EMailCaptionLbl: Label 'E-Mail';
        PmtTermsDescCaptionLbl: Label 'Payment Terms';
        ShipMethodDescCaptionLbl: Label 'Shipment Method';
        PrepmtTermsDescCaptionLbl: Label 'Prepayment Payment Terms';
        DocDateCaptionLbl: Label 'Document Date';
        AmtCaptionLbl: Label 'Amount';
        HdrDimsCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        DiscPercentCaptionLbl: Label 'Discount %';
        LineDiscCaptionLbl: Label 'Line Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        ExciseAmtCaptionLbl: Label 'Excise Amount';
        TaxAmtCaptionLbl: Label 'Tax Amount';
        ServTaxAmtCaptionLbl: Label 'Service Tax Amount';
        ChargesAmtCaptionLbl: Label 'Charges Amount';
        OtherTaxesAmtCaptionLbl: Label 'Other Taxes Amount';
        ServTaxeCessAmtCaptionLbl: Label 'Service Tax eCess Amount';
        TCSAmtCaptionLbl: Label 'TCS Amount';
        ServTaxSHECessAmtCaptionLbl: Label 'Service Tax SHECess Amount';
        VATDisctAmtCaptionLbl: Label 'Payment Discount on VAT';
        LineDimsCaptionLbl: Label 'Line Dimensions';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        ShipToAddrCaptionLbl: Label 'Ship-to Address';
        PmtTermsCaptionLbl: Label 'Description';
        GLAccNoCaptionLbl: Label 'G/L Account No.';
        PrepmtSpecCaptionLbl: Label 'Prepayment Specification';
        PrepmtVATAmtSpecCaptionLbl: Label 'Prepayment VAT Amount Specification';
        InvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        VATPercentCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        LineAmtCaptionLbl: Label 'Line Amount';
        VATIdentCaptionLbl: Label 'VAT Identifier';
        TotalCaptionLbl: Label 'Total';
        ServTaxSBCAmtCaptionLbl: Label 'SBC Amount';
        KKCessAmtCaptionLbl: Label 'KK Cess Amount';
        CompanyRegistrationLbl: Label 'Company Registration No.';
        CustomerRegistrationLbl: Label 'Customer GST Reg No.';

    procedure InitializeRequest(
        NoOfCopiesFrom: Integer;
        ShowInternalInfoFrom: Boolean;
        ArchiveDocumentFrom: Boolean;
        LogInteractionFrom: Boolean;
        PrintFrom: Boolean;
        DisplAsmInfo: Boolean)
    begin
        NoOfCopy := NoOfCopiesFrom;
        ShowInterInf := ShowInternalInfoFrom;
        ArchiveDoc := ArchiveDocumentFrom;
        LogInterac := LogInteractionFrom;
        Print := PrintFrom;
        DisplayAssemblyInformation := DisplAsmInfo;
    end;

    procedure GetUnitOfMeasureDescr(UOMCode: Code[10]): Text[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UOMCode) then
            exit(UOMCode);

        exit(CopyStr(UnitOfMeasure.Description, 1, 10));
    end;

    procedure BlanksForIndent(): Text[10]
    begin
        exit(PadStr('', 2, ' '));
    end;

    local procedure CheckGSTDoc(SalesLine: Record "Sales Line"): Boolean
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Tax Record ID", SalesLine.RecordId);
        TaxTransactionValue.SetRange("Tax Type", 'GST');
        if not TaxTransactionValue.IsEmpty then
            exit(true);
    end;

    local procedure GetDimensionText(
        var DimSetEntry: Record "Dimension Set Entry";
        Number: Integer;
        var Continue: Boolean): Text[120]
    var
        DimensionText: Text[120];
        PrevDimText: Text[75];
        DimensionTextLbl: Label '%1; %2 - %3', Comment = ' %1 = DimText, %2 = Dimension Code, %3 = Dimension Value Code';
        DimensionLbl: Label '%1 - %2', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
    begin
        Continue := false;
        if Number = 1 then
            if not DimSetEntry.FindSet() then
                exit;

        repeat
            PrevDimText := CopyStr((DimensionText), 1, 75);
            if DimensionText = '' then
                DimensionText := StrSubstNo(DimensionLbl, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
            else
                DimensionText := CopyStr(
                    StrSubstNo(
                        DimensionTextLbl,
                        DimensionText,
                        DimSetEntry."Dimension Code",
                        DimSetEntry."Dimension Value Code"),
                    1,
                    120);

            if StrLen(DimensionText) > MaxStrLen(PrevDimText) then begin
                Continue := true;
                exit(PrevDimText);
            end;
        until DimSetEntry.Next() = 0;

        exit(DimensionText)
    end;
}