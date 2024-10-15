report 18018 "Service - Invoice GST"
{
    DefaultLayout = RDLC;
    RDLCLayout = './rdlc/ServiceInvoice.rdl';
    Caption = 'Service - Invoice';
    Permissions = TableData "Sales Shipment Buffer" = rimd;

    dataset
    {
        dataitem("Service Invoice Header"; "Service Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Invoice';

            column(No_ServiceInvHeader; "No.")
            {
            }
            column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
            {
            }
            column(DisplayAdditionalFeeNote; DisplayAddFeeNote)
            {
            }
            dataitem(CopyLoop; Integer)
            {
                DataItemTableView = sorting(Number);

                dataitem(PageLoop; Integer)
                {
                    DataItemTableView = sorting(Number)
                                        where(Number = const(1));

                    column(CompanyRegistrationLbl; CompanyRegistrationLbl)
                    {
                    }
                    column(CompanyInfo_GST_RegistrationNo; CompanyInfo."GST Registration No.")
                    {
                    }
                    column(CustomerRegistrationLbl; CustomerRegistrationLbl)
                    {
                    }
                    column(Customer_GST_RegistrationNo; Customer."GST Registration No.")
                    {
                    }
                    column(CompanyInfoPicture2; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfoPicture1; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfoPicture3; CompanyInfo3.Picture)
                    {
                    }
                    column(ReportTitleCopyText; StrSubstNo(ServiceInvLbl, CopyText))
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
                    column(CompanyInfoBankName; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(BillToCustNo_ServiceInvoiceHeader; "Service Invoice Header"."Bill-to Customer No.")
                    {
                        IncludeCaption = false;
                    }
                    column(BillToCustNo_ServiceInvoiceHeaderCaption; "Service Invoice Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PostingDate_ServiceInvoiceHeader; FORMAT("Service Invoice Header"."Posting Date"))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_ServiceInvoiceHeader; "Service Invoice Header"."VAT Registration No.")
                    {
                    }
                    column(DueDate_ServiceInvoiceHeader; FORMAT("Service Invoice Header"."Due Date"))
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
                    column(YourReference_ServiceInvoiceHeader; "Service Invoice Header"."Your Reference")
                    {
                    }
                    column(OrderNoText; OrderNoText)
                    {
                    }
                    column(OrderNo_ServiceInvoiceHeader; "Service Invoice Header"."Order No.")
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
                    column(DocDate_ServiceInvoiceHeader; FORMAT("Service Invoice Header"."Document Date", 0, 4))
                    {
                    }
                    column(PricesInclVAT_ServiceInvoiceHeader; "Service Invoice Header"."Prices Including VAT")
                    {
                        IncludeCaption = false;
                    }
                    column(PricesInclVAT_ServiceInvoiceHeaderCaption; "Service Invoice Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(PageCaption; StrSubstNo(PageLbl, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricesInclVAT_FormattedServiceInvoiceHeader; FORMAT("Service Invoice Header"."Prices Including VAT"))
                    {
                    }
                    column(PageLoopNo; Number)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
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
                    column(CompanyInfoBankAccNoCaption; CompanyInfoBankAccNoCaptionLbl)
                    {
                    }
                    column(DueDateCaption; DueDateCaptionLbl)
                    {
                    }
                    column(InvoiceNoCaption; InvoiceNoCaptionLbl)
                    {
                    }
                    column(PostingDateCaption; PostingDateCaptionLbl)
                    {
                    }
                    column(ServiceTaxRegistrationNoCaption; ServiceTaxRegistrationNoLbl)
                    {
                    }
                    column(ServiceTaxRegistrationNo; ServiceTaxRegistrationNo)
                    {
                    }
                    dataitem(DimensionLoop1; Integer)
                    {
                        DataItemLinkReference = "Service Invoice Header";
                        DataItemTableView = sorting(Number);

                        column(DimText_DimensionLoop1; DimText)
                        {
                        }
                        column(No_DimensionLoop1; Number)
                        {
                        }
                        column(HdrDimCaption; HdrDimCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimText := DimText_DimensionLoop1Arr[Number];
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowIntnalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Service Invoice Line"; "Service Invoice Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Service Invoice Header";
                        DataItemTableView = sorting("Document No.", "Line No.");

                        column(GSTComponentCode1; GSTComponentCodeName[1] + ' Amount')
                        {
                        }
                        column(GSTComponentCode2; GSTComponentCodeName[2] + ' Amount')
                        {
                        }
                        column(GSTComponentCode3; GSTComponentCodeName[3] + ' Amount')
                        {
                        }
                        column(GSTComponentCode4; GSTComponentCodeName[4] + ' Amount')
                        {
                        }
                        column(GSTCompAmount1; Abs(GSTCompAmount[1]))
                        {
                        }
                        column(GSTCompAmount2; Abs(GSTCompAmount[2]))
                        {
                        }
                        column(GSTCompAmount3; Abs(GSTCompAmount[3]))
                        {
                        }
                        column(GSTCompAmount4; Abs(GSTCompAmount[4]))
                        {
                        }
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(ServInvHeaderVATBaseDisc; "Service Invoice Header"."VAT Base Discount %")
                        {
                        }
                        column(TotalLineAmt; TotalLineAmount)
                        {
                        }
                        column(TotalAmt; TotalAmount)
                        {
                        }
                        column(TotalAmtInclVAT; TotalAmountInclVAT)
                        {
                        }
                        column(TotalInvDiscAmt; TotalInvDiscAmount)
                        {
                        }
                        column(LineNo_ServiceInvoiceLine; "Service Invoice Line"."Line No.")
                        {
                        }
                        column(LineAmt_ServiceInvoiceLine; "Line Amount")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Comment_ServiceInvoiceLine; Description)
                        {
                            IncludeCaption = false;
                        }
                        column(Comment_ServiceInvoiceLineCaption; "Service Invoice Line".FieldCaption(Description))
                        {
                        }
                        column(No_ServiceInvoiceLine; "No.")
                        {
                            IncludeCaption = false;
                        }
                        column(No_ServiceInvoiceLineCaption; "Service Invoice Line".FieldCaption("No."))
                        {
                        }
                        column(Qty_ServiceInvoiceLine; Quantity)
                        {
                            IncludeCaption = false;
                        }
                        column(Qty_ServiceInvoiceLineCaption; "Service Invoice Line".FieldCaption(Quantity))
                        {
                        }
                        column(UOM_ServiceInvoiceLine; "Unit of Measure")
                        {
                            IncludeCaption = false;
                        }
                        column(UOM_ServiceInvoiceLineCaption; "Service Invoice Line".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(UnitPrice_ServiceInvoiceLine; "Unit Price")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDisc_ServiceInvoiceLine; "Line Discount %")
                        {
                        }
                        column(LineDiscAmt_ServiceInvoiceLine; "Line Discount Amount")
                        {
                        }
                        column(PostedShipmentDate; FORMAT(PostedShipmentDate))
                        {
                        }
                        column(NegInvDiscountAmt; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(LineAmt_ServInvLine; Amount)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtInclVAT_ServInvLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(TaxAmt_ServiceInvoiceLine; 0)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ServTaxAmt; ServiceTaxAmt)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ChargesAmt; ChargesAmount)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(OtherTaxesAmt; OtherTaxesAmount)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ServiceTaxECessAmt; ServiceTaxECessAmt)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AppliedServTaxAmt; AppliedServiceTaxAmt)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AppliedServTaxECessAmt; AppliedServiceTaxECessAmt)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ServiceTaxSHECessAmt; ServiceTaxSHECessAmt)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AppliedServTaxSHECessAmt; AppliedServiceTaxSHECessAmt)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalTaxAmt; TotalTaxAmt)
                        {
                        }
                        column(TotalExciseAmt; TotalExciseAmt)
                        {
                        }
                        column(NegLineAmtInvDiscAmtAmtInclVAT; -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText; VATAmountLine.VATAmountText())
                        {
                        }
                        column(AmtInclVATAmount; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(LineDiscCaption; LineDiscCaptionLbl)
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(LineDiscAmtCaption; LineDiscAmtCaptionLbl)
                        {
                        }
                        column(PostedShipmentDateCaption; PostedShipmentDateCaptionLbl)
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
                        column(SvcTaxAmtAppliedCaption; SvcTaxAmtAppliedCaptionLbl)
                        {
                        }
                        column(SvcTaxeCessAmtAppliedCaption; SvcTaxeCessAmtAppliedCaptionLbl)
                        {
                        }
                        column(ServTaxSHECessAmtCaption; ServTaxSHECessAmtCaptionLbl)
                        {
                        }
                        column(SvcTaxSHECessAmtAppliedCaption; SvcTaxSHECessAmtAppliedCaptionLbl)
                        {
                        }
                        column(PymtDiscOnVATCaption; PymtDiscOnVATCaptionLbl)
                        {
                        }
                        column(ServiceTaxSBCAmt; ServiceTaxSBCAmt)
                        {
                        }
                        column(AppliedServiceTaxSBCAmt; AppliedServiceTaxSBCAmt)
                        {
                        }
                        column(ServTaxSBCAmtCaption; ServTaxSBCAmtCaptionLbl)
                        {
                        }
                        column(SvcTaxSBCAmtAppliedCaption; SvcTaxSBCAmtAppliedCaptionLbl)
                        {
                        }
                        column(KKCessAmt; KKCessAmt)
                        {
                        }
                        column(AppliedKKCessAmt; AppliedKKCessAmt)
                        {
                        }
                        column(KKCessAmtCaption; KKCessAmtCaptionLbl)
                        {
                        }
                        column(KKCessAmtAppliedCaption; KKCessAmtAppliedCaptionLbl)
                        {
                        }
                        dataitem("Service Shipment Buffer"; Integer)
                        {
                            DataItemTableView = sorting(Number);

                            column(ServShipmentBufferPostingDate; FORMAT(ServiceShipmentBuffer."Posting Date"))
                            {
                            }
                            column(ServShipmentBufferQty; ServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(ShipmentCaption; ShipmentCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    ServiceShipmentBuffer.Find('-')
                                else
                                    ServiceShipmentBuffer.Next();
                            end;

                            trigger OnPreDataItem()
                            begin
                                ServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
                                ServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");

                                SetRange(Number, 1, ServiceShipmentBuffer.Count);
                            end;
                        }
                        dataitem(DimensionLoop2; Integer)
                        {
                            DataItemTableView = sorting(Number);

                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number <= DimText_DimensionLoop1ArrLength then
                                    DimText := DimText_DimensionLoop1Arr[Number]
                                else
                                    DimText := Format("Service Invoice Line".Type) + ' ' + AccNo;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowIntnalInfo then
                                    CurrReport.Break();

                                if IsServiceContractLine then
                                    SetRange(Number, 1, DimText_DimensionLoop1ArrLength + 1)
                                else
                                    SetRange(Number, 1, DimText_DimensionLoop1ArrLength);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        var
                            TaxTrnasactionValue: Record "Tax Transaction Value";
                            CurrExchRate: Record "Currency Exchange Rate";
                        begin
                            PostedShipmentDate := 0D;

                            IsServiceContractLine := (Type = Type::"G/L Account") and ("Service Item No." <> '') and ("Contract No." <> '');
                            if IsServiceContractLine then begin
                                AccNo := "No.";
                                "No." := "Service Item No.";
                            end;

                            VATAmountLine.Init();
                            VATAmountLine."VAT Identifier" := "VAT Identifier";
                            VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            VATAmountLine."Tax Group Code" := "Tax Group Code";
                            VATAmountLine."VAT %" := "VAT %";
                            VATAmountLine."VAT Base" := Amount;
                            VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            VATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            VATAmountLine.InsertLine();
                            if IsGSTApplicable and (Type <> Type::" ") then begin
                                J := 1;

                                TaxTrnasactionValue.Reset();
                                TaxTrnasactionValue.SetRange("Tax Record ID", "Service Invoice Line".RecordId);
                                TaxTrnasactionValue.SetRange("Tax Type", 'GST');
                                TaxTrnasactionValue.SetRange("Value Type", TaxTrnasactionValue."Value Type"::COMPONENT);
                                TaxTrnasactionValue.SetFilter(Percent, '<>%1', 0);
                                if TaxTrnasactionValue.FindSet() then
                                    repeat
                                        GSTComponentCode[J] := TaxTrnasactionValue."Value ID";
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
                                        DetailedGSTLedgerEntry.Reset();
                                        DetailedGSTLedgerEntry.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Document Line No.");
                                        DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Sales);
                                        DetailedGSTLedgerEntry.SetRange("Document No.", "Document No.");
                                        DetailedGSTLedgerEntry.SetRange("Document Line No.", "Line No.");
                                        DetailedGSTLedgerEntry.SetRange("GST Component Code", GSTComponentCodeName[J]);
                                        if DetailedGSTLedgerEntry.FindSet() then begin
                                            repeat
                                                GSTCompAmount[J] +=
                                                  CurrExchRate.ExchangeAmtLCYToFCY(
                                                    DetailedGSTLedgerEntry."Posting Date", DetailedGSTLedgerEntry."Currency Code",
                                                    DetailedGSTLedgerEntry."GST Amount", DetailedGSTLedgerEntry."Currency Factor");
                                            until DetailedGSTLedgerEntry.Next() = 0;
                                            J += 1;
                                        end;
                                    until TaxTrnasactionValue.Next() = 0;

                                TaxTrnasactionValue.Reset();
                                TaxTrnasactionValue.SetRange("Tax Record ID", "Service Invoice Line".RecordId);
                                TaxTrnasactionValue.SetRange("Tax Type", 'TDS');
                                TaxTrnasactionValue.SetRange("Value Type", TaxTrnasactionValue."Value Type"::COMPONENT);
                                TaxTrnasactionValue.SetFilter(Percent, '<>%1', 0);
                                if TaxTrnasactionValue.FindSet() then
                                    repeat
                                        TotalTDSAmount += TaxTrnasactionValue.Amount;
                                    until TaxTrnasactionValue.Next() = 0;
                            end;
                            TotalLineAmount += "Line Amount";
                            TotalAmount += TaxTrnasactionValue.Amount;
                            TotalInvDiscAmount += "Inv. Discount Amount";
                            TypeInt := Type;
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATAmountLine.DeleteAll();
                            ServiceShipmentBuffer.Reset();
                            ServiceShipmentBuffer.DeleteAll();
                            FirstValueEntryNo := 0;
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                            //CurrReport.CREATETOTALS("Line Amount", Amount, "Amount Including VAT", "Inv. Discount Amount");
                            TotalLineAmount := 0;
                            TotalAmount := 0;
                            TotalAmountInclVAT := 0;
                            TotalInvDiscAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; Integer)
                    {
                        DataItemTableView = sorting(Number);

                        column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Invoice Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Invoice Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATPercentageCaption; VATPercentageCaptionLbl)
                        {
                        }
                        column(VATBaseCaption; VATBaseCaptionLbl)
                        {
                        }
                        column(VATAmtCaption; VATAmtCaptionLbl)
                        {
                        }
                        column(VATAmtSpecCaption; VATAmtSpecCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption; VATIdentifierCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
                        {
                        }
                        column(LineAmtCaption; LineAmtCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmountLine.GetTotalVATAmount() = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
                            // CurrReport.CREATETOTALS(
                            //   VATAmountLine."Line Amount", VATAmountLine."Inv. Disc. Base Amount",
                            //   VATAmountLine."Invoice Discount Amount", VATAmountLine."VAT Base", VATAmountLine."VAT Amount");
                        end;
                    }
                    dataitem(Total; Integer)
                    {
                        DataItemTableView = sorting(Number)
                                            where(Number = const(1));

                        column(PaymentTermsComment; PaymentTerms.Description)
                        {
                        }
                        column(PymtTermsDescCaption; PymtTermsDescCaptionLbl)
                        {
                        }
                    }
                    dataitem(Total2; Integer)
                    {
                        DataItemTableView = sorting(Number)
                                            where(Number = const(1));

                        column(CustNo_ServiceInvoiceHeader; "Service Invoice Header"."Customer No.")
                        {
                            IncludeCaption = false;
                        }
                        column(CustNo_ServiceInvoiceHeaderCaption; "Service Invoice Header".FieldCaption("Customer No."))
                        {
                        }
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr7; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr8; ShipToAddr[8])
                        {
                        }
                        column(ShiptoAddrCaption; ShiptoAddrCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(LineFee; Integer)
                    {
                        DataItemTableView = sorting(Number)
                                            order(ascending)
                                            where(Number = filter(1 ..));

                        column(LineFeeCaptionLbl; TempLineFeeNoteOnReportHist.ReportText)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not DisplayAddFeeNote then
                                CurrReport.Break();
                            if Number = 1 then begin
                                if not TempLineFeeNoteOnReportHist.FindSet() then
                                    CurrReport.Break()
                            end else
                                if TempLineFeeNoteOnReportHist.Next() = 0 then
                                    CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := CopyLbl;
                        OutputNo += 1;
                    end;
                    CurrReport.PageNo := 1;

                    TotalExciseAmt := 0;
                    TotalTaxAmt := 0;
                    ServiceTaxAmount := 0;
                    ServiceTaxeCessAmount := 0;
                    ServiceTaxSHECessAmount := 0;
                    ServiceTaxSBCAmount := 0;
                    KKCessAmount := 0;

                    OtherTaxesAmount := 0;
                    ChargesAmount := 0;
                    AppliedServiceTaxSHECessAmt := 0;
                    AppliedServiceTaxECessAmt := 0;
                    AppliedServiceTaxAmt := 0;
                    AppliedServiceTaxSBCAmt := 0;
                    AppliedKKCessAmt := 0;
                    ServiceTaxSHECessAmt := 0;
                    ServiceTaxECessAmt := 0;
                    ServiceTaxAmt := 0;
                    ServiceTaxSBCAmt := 0;
                    KKCessAmt := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not CurrReport.Preview then
                        ServiceInvCountPrinted.Run("Service Invoice Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + Cust."Invoice Copies" + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                ServiceInvoiceLine: Record "Service Invoice Line";
                Location: Record Location;
            begin
                CurrReport.LANGUAGE := Language.GetLanguageID("Language Code");
                IsGSTApplicable := CheckGSTDoc(ServiceInvoiceLine);
                Customer.Get("Bill-to Customer No.");
                if RespCenter.Get("Responsibility Center") then begin
                    FormatAddr.RespCenter(CompanyAddr, RespCenter);
                    CompanyInfo."Phone No." := RespCenter."Phone No.";
                    CompanyInfo."Fax No." := RespCenter."Fax No.";
                end else
                    FormatAddr.Company(CompanyAddr, CompanyInfo);

                if "Order No." = '' then
                    OrderNoText := ''
                else
                    OrderNoText := CopyStr(FieldCaption("Order No."), 1, 80);
                if "Salesperson Code" = '' then begin
                    SalesPurchPerson.Init();
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
                    TotalExclVATText := StrSubstNo(TotalExcTaxLbl, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(TotalLbl, "Currency Code");
                    TotalInclVATText := StrSubstNo(TotalIncTaxLbl, "Currency Code");
                    TotalExclVATText := StrSubstNo(TotalExcTaxLbl, "Currency Code");
                end;
                FormatAddr.ServiceInvBillTo(CustAddr, "Service Invoice Header");
                Cust.Get("Bill-to Customer No.");

                GetLineFeeNoteOnReportHist("No.");

                if "Payment Terms Code" = '' then
                    PaymentTerms.Init()
                else
                    PaymentTerms.Get("Payment Terms Code");

                FormatAddr.ServiceInvShipTo(ShipToAddr, CustAddr, "Service Invoice Header");
                ShowShippingAddr := "Customer No." <> "Bill-to Customer No.";
                for i := 1 TO ArrayLen(ShipToAddr) do
                    if ShipToAddr[i] <> CustAddr[i] then
                        ShowShippingAddr := true;
                SupplementaryText := '';
                ServiceInvoiceLine.SetRange("Document No.", "No.");
                if ServiceInvoiceLine.FindFirst() then
                    SupplementaryText := SupplInvoiceLbl;

                if Location.Get("Location Code") then
                    ServiceTaxRegistrationNo := Location."GST Registration No."
                else
                    ServiceTaxRegistrationNo := CompanyInfo."Registration No.";
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
                        Caption = 'No. of Copies';
                        ApplicationArea = Basic, Suite;
                    }
                    field(ShowInternalInfo; ShowIntnalInfo)
                    {
                        Caption = 'Show Internal Information';
                        ApplicationArea = Basic, Suite;
                    }
                    field(DisplayAdditionalFeeNote; DisplayAddFeeNote)
                    {
                        Caption = 'Show Additional Fee Note';
                        ApplicationArea = Basic, Suite;
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
        ServiceSetup.Get();

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo3: Record "Company Information";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        ServiceSetup: Record "Service Mgt. Setup";
        Cust: Record "Customer";
        DimSetEntry: Record "Dimension Set Entry";
        VATAmountLine: Record "VAT Amount Line" temporary;
        RespCenter: Record "Responsibility Center";
        ServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        TempLineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist." temporary;
        GSTComponent: Record "GST Component";
        Customer: Record "Customer";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        SegManagement: Codeunit SegManagement;
        Language: Codeunit "Language";
        ServiceInvCountPrinted: Codeunit "Service Inv.-Printed";
        FormatAddr: Codeunit "Format Address";
        PostedShipmentDate: Date;
        CustAddr: array[8] of Text[50];
        ShipToAddr: array[8] of Text[50];
        CompanyAddr: array[8] of Text[50];
        OrderNoText: Text[80];
        SalesPersonText: Text[30];
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
        i: Integer;
        NextEntryNo: Integer;
        FirstValueEntryNo: Integer;
        OutputNo: Integer;
        TypeInt: Integer;
        DimText: Text[120];
        ShowIntnalInfo: Boolean;
        TotalLineAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalInvDiscAmount: Decimal;
        DimText_DimensionLoop1ArrLength: Integer;
        DimText_DimensionLoop1Arr: array[500] of Text[50];
        IsServiceContractLine: Boolean;
        AccNo: Code[20];
        ChargesAmount: Decimal;
        OtherTaxesAmount: Decimal;
        SupplementaryText: Text[30];
        ServiceTaxAmt: Decimal;
        ServiceTaxECessAmt: Decimal;
        AppliedServiceTaxAmt: Decimal;
        AppliedServiceTaxECessAmt: Decimal;
        ServiceTaxSHECessAmt: Decimal;
        AppliedServiceTaxSHECessAmt: Decimal;
        TotalTaxAmt: Decimal;
        TotalExciseAmt: Decimal;
        ServiceTaxAmount: Decimal;
        ServiceTaxeCessAmount: Decimal;
        ServiceTaxSHECessAmount: Decimal;
        ServiceTaxRegistrationNo: Code[20];
        ServiceTaxSBCAmount: Decimal;
        ServiceTaxSBCAmt: Decimal;
        AppliedServiceTaxSBCAmt: Decimal;
        DisplayAddFeeNote: Boolean;
        KKCessAmount: Decimal;
        KKCessAmt: Decimal;
        AppliedKKCessAmt: Decimal;
        GSTCompAmount: array[20] of Decimal;
        GSTComponentCode: array[20] of Integer;
        TotalTDSAmount: Decimal;
        GSTComponentCodeName: array[20] of Code[10];
        IsGSTApplicable: Boolean;
        J: Integer;
        TotalIncTaxLbl: Label 'Total %1 Incl. Taxes', Comment = '%1 Amt';
        TotalExcTaxLbl: Label 'Total %1 Excl. Taxes', Comment = '%1 Amt';
        SalesPerLbl: Label 'Salesperson';
        TotalLbl: Label 'Total %1', Comment = '%1 Amt';
        CopyLbl: Label 'COPY';
        ServiceInvLbl: Label 'Service - Invoice';
        PageLbl: Label 'Page %1', Comment = '%1 No.';
        SupplInvoiceLbl: Label 'Supplementary Invoice';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        DueDateCaptionLbl: Label 'Due Date';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        HdrDimCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        LineDiscCaptionLbl: Label 'Disc. %';
        AmtCaptionLbl: Label 'Amount';
        LineDiscAmtCaptionLbl: Label 'Line Discount Amount';
        PostedShipmentDateCaptionLbl: Label 'Posted Shipment Date';
        SubtotalCaptionLbl: Label 'Subtotal';
        ExciseAmtCaptionLbl: Label 'Excise Amount';
        TaxAmtCaptionLbl: Label 'Tax Amount';
        ServTaxAmtCaptionLbl: Label 'Service Tax Amount';
        ChargesAmtCaptionLbl: Label 'Charges Amount';
        OtherTaxesAmtCaptionLbl: Label 'Other Taxes Amount';
        ServTaxeCessAmtCaptionLbl: Label 'Service Tax eCess Amount';
        SvcTaxAmtAppliedCaptionLbl: Label 'Svc Tax Amt (Applied)';
        SvcTaxeCessAmtAppliedCaptionLbl: Label 'Svc Tax eCess Amt (Applied)';
        ServTaxSHECessAmtCaptionLbl: Label 'Service Tax SHE Cess Amount';
        SvcTaxSHECessAmtAppliedCaptionLbl: Label 'Svc Tax SHECess Amt(Applied)';
        PymtDiscOnVATCaptionLbl: Label 'Payment Discount on VAT';
        ShipmentCaptionLbl: Label 'Shipment';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATPercentageCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        LineAmtCaptionLbl: Label 'Line Amount';
        TotalCaptionLbl: Label 'Total';
        PymtTermsDescCaptionLbl: Label 'Payment Terms';
        ShiptoAddrCaptionLbl: Label 'Ship-to Address';
        InvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        ServiceTaxRegistrationNoLbl: Label 'Service Tax Registration No.';
        ServTaxSBCAmtCaptionLbl: Label 'SBC Amount';
        SvcTaxSBCAmtAppliedCaptionLbl: Label 'SBC Amt (Applied)';
        KKCessAmtCaptionLbl: Label 'KK Cess Amount';
        KKCessAmtAppliedCaptionLbl: Label 'KK Cess Amt (Applied)';
        CompanyRegistrationLbl: Label 'Company Registration No.';
        CustomerRegistrationLbl: Label 'Customer GST Reg No.';

    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;
        if "Service Invoice Line"."Shipment No." <> '' then
            if ServiceShipmentHeader.Get("Service Invoice Line"."Shipment No.") then
                exit(ServiceShipmentHeader."Posting Date");

        if "Service Invoice Header"."Order No." = '' then
            exit("Service Invoice Header"."Posting Date");

        case "Service Invoice Line".Type of
            "Service Invoice Line".Type::Item:
                GenerateBufferFromValueEntry("Service Invoice Line");

            "Service Invoice Line".Type::"G/L Account", "Service Invoice Line".Type::Resource,
          "Service Invoice Line".Type::Cost:
                GenerateBufferFromShipment("Service Invoice Line");

            "Service Invoice Line".Type::" ":
                exit(0D);
        end;

        ServiceShipmentBuffer.Reset();
        ServiceShipmentBuffer.SetRange("Document No.", "Service Invoice Line"."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", "Service Invoice Line"."Line No.");
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer2 := ServiceShipmentBuffer;
            if ServiceShipmentBuffer.Next() = 0 then begin
                ServiceShipmentBuffer.Get(
                  ServiceShipmentBuffer2."Document No.", ServiceShipmentBuffer2."Line No.", ServiceShipmentBuffer2."Entry No.");
                ServiceShipmentBuffer.Delete();
                exit(ServiceShipmentBuffer2."Posting Date");
            end;
            ServiceShipmentBuffer.CalcSums(Quantity);
            if ServiceShipmentBuffer.Quantity <> "Service Invoice Line".Quantity then begin
                ServiceShipmentBuffer.DeleteAll();
                exit("Service Invoice Header"."Posting Date");
            end;
        end else
            exit("Service Invoice Header"."Posting Date");
    end;

    procedure GenerateBufferFromValueEntry(ServiceInvoiceLine2: Record "Service Invoice Line")
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := ServiceInvoiceLine2."Quantity (Base)";
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", ServiceInvoiceLine2."Document No.");
        ValueEntry.SetRange("Posting Date", "Service Invoice Header"."Posting Date");
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Entry No.", '%1..', FirstValueEntryNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if ServiceInvoiceLine2."Qty. per Unit of Measure" <> 0 then
                        Quantity := ValueEntry."Invoiced Quantity" / ServiceInvoiceLine2."Qty. per Unit of Measure"
                    else
                        Quantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      ServiceInvoiceLine2,
                      -Quantity,
                      ItemLedgerEntry."Posting Date");
                    TotalQuantity := TotalQuantity + ValueEntry."Invoiced Quantity";
                end;
                FirstValueEntryNo := ValueEntry."Entry No." + 1;
            until (ValueEntry.Next() = 0) or (TotalQuantity = 0);
    end;

    procedure GenerateBufferFromShipment(ServiceInvoiceLine: Record "Service Invoice Line")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine2: Record "Service Invoice Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := 0;
        ServiceInvoiceHeader.SetCurrentKey("Order No.");
        ServiceInvoiceHeader.SetFilter("No.", '..%1', "Service Invoice Header"."No.");
        ServiceInvoiceHeader.SetRange("Order No.", "Service Invoice Header"."Order No.");
        if ServiceInvoiceHeader.Find('-') then
            repeat
                ServiceInvoiceLine2.SetRange("Document No.", ServiceInvoiceHeader."No.");
                ServiceInvoiceLine2.SetRange("Line No.", ServiceInvoiceLine."Line No.");
                ServiceInvoiceLine2.SetRange(Type, ServiceInvoiceLine.Type);
                ServiceInvoiceLine2.SetRange("No.", ServiceInvoiceLine."No.");
                ServiceInvoiceLine2.SetRange("Unit of Measure Code", ServiceInvoiceLine."Unit of Measure Code");
                if ServiceInvoiceLine2.Find('-') then
                    repeat
                        TotalQuantity := TotalQuantity + ServiceInvoiceLine2.Quantity;
                    until ServiceInvoiceLine2.Next() = 0;
            until ServiceInvoiceHeader.Next() = 0;

        ServiceShipmentLine.SetCurrentKey("Order No.", "Order Line No.");
        ServiceShipmentLine.SetRange("Order No.", "Service Invoice Header"."Order No.");
        ServiceShipmentLine.SetRange("Order Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentLine.SetRange("Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentLine.SetRange(Type, ServiceInvoiceLine.Type);
        ServiceShipmentLine.SetRange("No.", ServiceInvoiceLine."No.");
        ServiceShipmentLine.SetRange("Unit of Measure Code", ServiceInvoiceLine."Unit of Measure Code");
        ServiceShipmentLine.SetFilter(Quantity, '<>%1', 0);

        if ServiceShipmentLine.Find('-') then
            repeat
                if Abs(ServiceShipmentLine.Quantity) <= Abs(TotalQuantity - ServiceInvoiceLine.Quantity) then
                    TotalQuantity := TotalQuantity - ServiceShipmentLine.Quantity
                else begin
                    if Abs(ServiceShipmentLine.Quantity) > Abs(TotalQuantity) then
                        ServiceShipmentLine.Quantity := TotalQuantity;
                    Quantity :=
                      ServiceShipmentLine.Quantity - (TotalQuantity - ServiceInvoiceLine.Quantity);

                    TotalQuantity := TotalQuantity - ServiceShipmentLine.Quantity;
                    ServiceInvoiceLine.Quantity := ServiceInvoiceLine.Quantity - Quantity;

                    if ServiceShipmentHeader.Get(ServiceShipmentLine."Document No.") then
                        AddBufferEntry(
                          ServiceInvoiceLine,
                          Quantity,
                          ServiceShipmentHeader."Posting Date");
                end;
            until (ServiceShipmentLine.Next() = 0) or (TotalQuantity = 0);
    end;

    procedure AddBufferEntry(
        ServiceInvoiceLine: Record "Service Invoice Line";
        QtyOnShipment: Decimal;
        PostingDate: Date)
    begin
        ServiceShipmentBuffer.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", ServiceInvoiceLine."Line No.");
        ServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer.Quantity := ServiceShipmentBuffer.Quantity + QtyOnShipment;
            ServiceShipmentBuffer.Modify();
            exit;
        end;
        ServiceShipmentBuffer."Document No." := ServiceInvoiceLine."Document No.";
        ServiceShipmentBuffer."Line No." := ServiceInvoiceLine."Line No.";
        ServiceShipmentBuffer."Entry No." := NextEntryNo;
        ServiceShipmentBuffer.Type := ServiceInvoiceLine.Type;
        ServiceShipmentBuffer."No." := ServiceInvoiceLine."No.";
        ServiceShipmentBuffer.Quantity := QtyOnShipment;
        ServiceShipmentBuffer."Posting Date" := PostingDate;
        ServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
    end;

    procedure FindDimText_DimensionLoop1(DimSetID: Integer)
    var
        Separation: Text[5];
        i: Integer;
        TxtToAdd: Text[120];
        StartNewLine: Boolean;
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimText_DimensionLoop1ArrLength := 0;
        for i := 1 TO ArrayLen(DimText_DimensionLoop1Arr) do
            DimText_DimensionLoop1Arr[i] := '';
        if not DimSetEntry.FindSet() then
            exit;
        Separation := '; ';
        repeat
            TxtToAdd := DimSetEntry."Dimension Code" + ' - ' + DimSetEntry."Dimension Value Code";
            if DimText_DimensionLoop1ArrLength = 0 then
                StartNewLine := true
            else
                StartNewLine := StrLen(DimText_DimensionLoop1Arr[DimText_DimensionLoop1ArrLength]) + StrLen(Separation) + StrLen(TxtToAdd) > MaxStrLen(DimText_DimensionLoop1Arr[1]);
            if StartNewLine then begin
                DimText_DimensionLoop1ArrLength += 1;
                DimText_DimensionLoop1Arr[DimText_DimensionLoop1ArrLength] := CopyStr(TxtToAdd, 1, 50)
            end else
                DimText_DimensionLoop1Arr[DimText_DimensionLoop1ArrLength] := DimText_DimensionLoop1Arr[DimText_DimensionLoop1ArrLength] + Separation + TxtToAdd;
        until DimSetEntry.Next() = 0;
    end;

    local procedure GetLineFeeNoteOnReportHist(SalesInvoiceHeaderNo: Code[20])
    var
        LineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustRec: Record Customer;
    begin
        TempLineFeeNoteOnReportHist.DeleteAll();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        if not CustLedgerEntry.FindFirst() then
            exit;

        if not CustRec.Get("Service Invoice Header"."Bill-to Customer No.") then
            exit;

        LineFeeNoteOnReportHist.SetRange("Cust. Ledger Entry No", CustLedgerEntry."Entry No.");
        LineFeeNoteOnReportHist.SetRange("Language Code", CustRec."Language Code");
        if LineFeeNoteOnReportHist.FindSet() then
            repeat
                TempLineFeeNoteOnReportHist.Init();
                TempLineFeeNoteOnReportHist.Copy(LineFeeNoteOnReportHist);
                TempLineFeeNoteOnReportHist.Insert();
            until LineFeeNoteOnReportHist.Next() = 0;

    end;

    local procedure CheckGSTDoc(PurchInvLine: Record "Service Invoice Line"): Boolean
    var
        TaxTransactionValue: Record "Tax Transaction Value";
    begin
        TaxTransactionValue.Reset();
        TaxTransactionValue.SetRange("Tax Record ID", PurchInvLine.RecordId);
        TaxTransactionValue.SetRange("Tax Type", 'GST');
        if not TaxTransactionValue.IsEmpty then
            exit(true);
    end;
}