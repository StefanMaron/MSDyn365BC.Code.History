﻿namespace Microsoft.Purchases.History;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;
using Microsoft.Foundation.Reporting;

report 407 "Purchase - Credit Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/History/PurchaseCreditMemo.rdlc';
    Caption = 'Purchase - Credit Memo';
    PreviewMode = PrintLayout;
    WordMergeDataItem = "Purch. Cr. Memo Hdr.";

    dataset
    {
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Posted Purchase Cr. Memo';
            column(No_PurchCrMemoHdr; "No.")
            {
            }
            column(InvDiscountAmountCaption; InvDiscountAmountCaptionLbl)
            {
            }
            column(VATCaption; VATCaptionLbl)
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
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(EMailCaption; EMailCaptionLbl)
            {
            }
            column(DocumentDateCaption; DateCaptionLbl)
            {
            }
            column(BuyFromContactPhoneNoLbl; BuyFromContactPhoneNoLbl)
            {
            }
            column(BuyFromContactMobilePhoneNoLbl; BuyFromContactMobilePhoneNoLbl)
            {
            }
            column(BuyFromContactEmailLbl; BuyFromContactEmailLbl)
            {
            }
            column(PayToContactPhoneNoLbl; PayToContactPhoneNoLbl)
            {
            }
            column(PayToContactMobilePhoneNoLbl; PayToContactMobilePhoneNoLbl)
            {
            }
            column(PayToContactEmailLbl; PayToContactEmailLbl)
            {
            }
            column(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
            {
            }
            column(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
            {
            }
            column(BuyFromContactEmail; BuyFromContact."E-Mail")
            {
            }
            column(PayToContactPhoneNo; PayToContact."Phone No.")
            {
            }
            column(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
            {
            }
            column(PayToContactEmail; PayToContact."E-Mail")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(VendorNoCaption; VendorNoCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(DocumentCaption; DocumentCaption())
                    {
                    }
                    column(CopyText; CopyText)
                    {
                    }
                    column(VendAddr1; VendAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(VendAddr2; VendAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(VendAddr3; VendAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(VendAddr4; VendAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(VendAddr5; VendAddr[5])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(VendAddr6; VendAddr[6])
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoEMail; CompanyInfo."E-Mail")
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
                    column(PaytoVendNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Pay-to Vendor No.")
                    {
                    }
                    column(DocDate_PurchCrMemoHdr; Format("Purch. Cr. Memo Hdr."."Document Date", 0, '<Day,2>.<Month,2>.<Year4>'))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."VAT Registration No.")
                    {
                    }
                    column(PurchaserText; PurchaserText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(AppliedToText; AppliedToText)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourReference_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Your Reference")
                    {
                    }
                    column(VendAddr7; VendAddr[7])
                    {
                    }
                    column(VendAddr8; VendAddr[8])
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
                    column(PostingDate_PurchCrMemoHdr; Format("Purch. Cr. Memo Hdr."."Posting Date"))
                    {
                    }
                    column(PricesInclVAT_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Prices Including VAT")
                    {
                    }
                    column(ReturnOrderNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Return Order No.")
                    {
                    }
                    column(ReturnOrderNoText; ReturnOrderNoText)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(FormattedPricesInclVAT_PurchCrMemoHdr; Format("Purch. Cr. Memo Hdr."."Prices Including VAT"))
                    {
                    }
                    column(RegNoText; RegNoText)
                    {
                    }
                    column(RegNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Registration No.")
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
                    column(PurchCrMemoNoCaption; PurchCrMemoNoCaptionLbl)
                    {
                    }
                    column(PostingDateCaption; PostingDateCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(PaytoVendNo_PurchCrMemoHdrCaption; "Purch. Cr. Memo Hdr.".FieldCaption("Pay-to Vendor No."))
                    {
                    }
                    column(PricesInclVAT_PurchCrMemoHdrCaption; "Purch. Cr. Memo Hdr.".FieldCaption("Prices Including VAT"))
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
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Purch. Cr. Memo Hdr.";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText_DimensionLoop1; DimText)
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
                    dataitem("Purch. Cr. Memo Line"; "Purch. Cr. Memo Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purch. Cr. Memo Hdr.";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(AllowInvDiscount; AllowInvDiscount)
                        {
                        }
                        column(PricesIncludingVAT; PricesIncludingVAT)
                        {
                        }
                        column(Type_PurchCrMemoLine; Format(Type, 0, 2))
                        {
                        }
                        column(PurCrMemHdrVATBasDiscount; "Purch. Cr. Memo Hdr."."VAT Base Discount %")
                        {
                        }
                        column(VATAmountText; VATAmountText)
                        {
                        }
                        column(DocumentNo; DocumentNo)
                        {
                        }
                        column(Amt_PurchCrMemoLineLine; "Line Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Description_PurchCrMemoLine; Description)
                        {
                        }
                        column(No_PurchCrMemoLine; "No.")
                        {
                        }
                        column(Quantity_PurchCrMemoLine; Quantity)
                        {
                        }
                        column(UOM_PurchCrMemoLine; "Unit of Measure")
                        {
                        }
                        column(DirectUnitCost_PurchCrMemoLine; "Direct Unit Cost")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDisc_PurchCrMemoLine; "Line Discount %")
                        {
                        }
                        column(AllowInvDisc_PurchCrMemoLine; "Allow Invoice Disc.")
                        {
                        }
                        column(VAT_PurchCrMemoLine; "VAT %")
                        {
                        }
                        column(InvDiscountAmount; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(Amount_PurchCrMemoLine; Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(Amount_PurchCrMemoLineIncludingVAT; "Amount Including VAT")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmountIncludingVATAmount; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(DocNo_PurchCrMemoLine; "Document No.")
                        {
                        }
                        column(LineNo_PurchCrMemoLine; "Line No.")
                        {
                        }
                        column(TotalSubTotal; TotalSubTotal)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInvoiceDiscountAmt; TotalInvoiceDiscountAmount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmount; TotalAmount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmountVAT; TotalAmountVAT)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalPaymentDiscountOnVAT; TotalPaymentDiscountOnVAT)
                        {
                            AutoFormatType = 1;
                        }
                        column(DirectUnitCostCaption; DirectUnitCostCaptionLbl)
                        {
                        }
                        column(DiscountCaption; DiscountCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(PaymentDiscAmtCaption; PaymentDiscAmtCaptionLbl)
                        {
                        }
                        column(Description_PurchCrMemoLineCaption; FieldCaption(Description))
                        {
                        }
                        column(No_PurchCrMemoLineCaption; FieldCaption("No."))
                        {
                        }
                        column(Quantity_PurchCrMemoLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UOM_PurchCrMemoLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(AllowInvDisc_PurchCrMemoLineCaption; FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(VAT_PurchCrMemoLineCaption; FieldCaption("VAT %"))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_DimensionLoop2; DimText)
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Purch. Cr. Memo Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if (Type = Type::"G/L Account") and (not ShowInternalInfo) then
                                "No." := '';

                            TempVATAmountLine.Init();
                            TempVATAmountLine."VAT Identifier" := "VAT Identifier";
                            TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                            TempVATAmountLine."Use Tax" := "Use Tax";
                            TempVATAmountLine."VAT %" := "VAT %";
                            TempVATAmountLine."VAT Base" := Amount;
                            TempVATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            TempVATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                TempVATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            TempVATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            TempVATAmountLine.InsertLine();

                            AllowInvDiscount := Format("Allow Invoice Disc.");

                            TotalSubTotal += "Line Amount";
                            TotalInvoiceDiscountAmount -= "Inv. Discount Amount";
                            TotalAmount += Amount;
                            TotalAmountVAT += "Amount Including VAT" - Amount;
                            TotalAmountInclVAT += "Amount Including VAT";
                            TotalPaymentDiscountOnVAT += -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT");
                        end;

                        trigger OnPreDataItem()
                        var
                            PurchCrMemoLine: Record "Purch. Cr. Memo Line";
                            VATIdentifier: Code[20];
                        begin
                            TempVATAmountLine.DeleteAll();
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");

                            PurchCrMemoLine.SetRange("Document No.", "Purch. Cr. Memo Hdr."."No.");
                            PurchCrMemoLine.SetFilter(Type, '<>%1', 0);
                            VATAmountText := '';
                            if PurchCrMemoLine.Find('-') then begin
                                VATAmountText := StrSubstNo(Text012, PurchCrMemoLine."VAT %");
                                VATIdentifier := PurchCrMemoLine."VAT Identifier";
                                repeat
                                    if (PurchCrMemoLine."VAT Identifier" <> VATIdentifier) and (PurchCrMemoLine.Quantity <> 0) then
                                        VATAmountText := Text013;
                                until PurchCrMemoLine.Next() = 0;
                            end;
                            AllowInvDiscount := Format("Allow Invoice Disc.");
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLineVATBase; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVATAmount; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineLineAmount; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountSpecificationCaption; VATAmountSpecificationCaptionLbl)
                        {
                        }
                        column(LineAmountCaption; LineAmountCaptionLbl)
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
                            SetRange(Number, 1, TempVATAmountLine.Count);
                        end;
                    }
                    dataitem(VATCounterLCY; "Integer")
                    {
                        DataItemTableView = sorting(Number);
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
                        column(VATAmtLineVATIdentifier_VATCounterLCY; TempVATAmountLine."VAT Identifier")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "Purch. Cr. Memo Hdr."."Posting Date", "Purch. Cr. Memo Hdr."."Currency Code",
                                "Purch. Cr. Memo Hdr."."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "Purch. Cr. Memo Hdr."."Posting Date", "Purch. Cr. Memo Hdr."."Currency Code",
                                "Purch. Cr. Memo Hdr."."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Purch. Cr. Memo Hdr."."Currency Code" = '')
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text008 + Text009
                            else
                                VALSpecLCYHeader := Text008 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Purch. Cr. Memo Hdr."."Posting Date", "Purch. Cr. Memo Hdr."."Currency Code", 1);
                            CalculatedExchRate := Round(1 / "Purch. Cr. Memo Hdr."."Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.000001);
                            VALExchRate := StrSubstNo(Text010, CalculatedExchRate, CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(BuyfromVendNo_PurchCrMemoHdr; "Purch. Cr. Memo Hdr."."Buy-from Vendor No.")
                        {
                        }
                        column(BuyfromVendNo_PurchCrMemoHdrCaption; "Purch. Cr. Memo Hdr.".FieldCaption("Buy-from Vendor No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Purch. Cr. Memo Hdr."."Buy-from Vendor No." = "Purch. Cr. Memo Hdr."."Pay-to Vendor No." then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
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
                        column(ShipToAddressCaption; ShipToAddressCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if ShipToAddr[1] = '' then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;

                    TotalSubTotal := 0;
                    TotalInvoiceDiscountAmount := 0;
                    TotalAmount := 0;
                    TotalAmountVAT := 0;
                    TotalAmountInclVAT := 0;
                    TotalPaymentDiscountOnVAT := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"PurchCrMemo-Printed", "Purch. Cr. Memo Hdr.");
                end;

                trigger OnPreDataItem()
                begin
                    OutputNo := 1;

                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Purch. Cr. Memo Hdr.");
                FormatDocumentFields("Purch. Cr. Memo Hdr.");
                if BuyFromContact.Get("Buy-from Contact No.") then;
                if PayToContact.Get("Pay-to Contact No.") then;

                PrepareHeader();
                PrepareFooter();

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");
                TableID := DATABASE::"Purch. Cr. Memo Hdr.";
                DocumentNo := "Purch. Cr. Memo Hdr."."No.";

                PricesIncludingVAT := Format("Prices Including VAT");
            end;

            trigger OnPreDataItem()
            begin
                OnAfterPostDataItem("Purch. Cr. Memo Hdr.");
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies that interactions with the contact are logged.';
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
        end;

        trigger OnOpenPage()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Purch. Cr. Memo") <> '';
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

        OnAfterInitReport();
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Purch. Cr. Memo Hdr.".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      16, "Purch. Cr. Memo Hdr."."No.", 0, 0, DATABASE::Vendor, "Purch. Cr. Memo Hdr."."Buy-from Vendor No.",
                      "Purch. Cr. Memo Hdr."."Purchaser Code", '', "Purch. Cr. Memo Hdr."."Posting Description", '');
                until "Purch. Cr. Memo Hdr.".Next() = 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction();
    end;

    var
        Text003: Label '(Applies to %1 %2)';
        GLSetup: Record "General Ledger Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        VendAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        ReturnOrderNoText: Text[80];
        PurchaserText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        AppliedToText: Text;
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
        AllowInvDiscount: Text[30];
        PricesIncludingVAT: Text[30];
        VATAmountText: Text[30];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        LogInteraction: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        Text008: Label 'VAT Amount Specification in ';
        Text009: Label 'Local Currency';
        Text010: Label 'Exchange rate: %1/%2';
        CalculatedExchRate: Decimal;
        Text012: Label '%1% VAT';
        Text013: Label 'VAT Amount';
        RegNoText: Text[20];
        LogInteractionEnable: Boolean;
        TotalSubTotal: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountVAT: Decimal;
        TotalInvoiceDiscountAmount: Decimal;
        TotalPaymentDiscountOnVAT: Decimal;
        TableID: Integer;
        DocumentNo: Code[20];
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccountNoCaptionLbl: Label 'Account No.';
        PurchCrMemoNoCaptionLbl: Label 'Credit Memo No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        TotalCaptionLbl: Label 'Total';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        DirectUnitCostCaptionLbl: Label 'Direct Unit Cost';
        DiscountCaptionLbl: Label 'Discount %';
        AmountCaptionLbl: Label 'Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        PaymentDiscAmtCaptionLbl: Label 'Payment Discount on VAT';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        LineAmountCaptionLbl: Label 'Line Amount';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        ShipToAddressCaptionLbl: Label 'Ship-to Address';
        InvDiscountAmountCaptionLbl: Label 'Invoice Discount Amount';
        VATCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmountCaptionLbl: Label 'VAT Amount';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        HomePageCaptionLbl: Label 'Home Page';
        EMailCaptionLbl: Label 'Email';
        DateCaptionLbl: Label 'Date';
        PageCaptionLbl: Label 'Page';
        BuyFromContactPhoneNoLbl: Label 'Buy-from Contact Phone No.';
        BuyFromContactMobilePhoneNoLbl: Label 'Buy-from Contact Mobile Phone No.';
        BuyFromContactEmailLbl: Label 'Buy-from Contact E-Mail';
        PayToContactPhoneNoLbl: Label 'Pay-to Contact Phone No.';
        PayToContactMobilePhoneNoLbl: Label 'Pay-to Contact Mobile Phone No.';
        PayToContactEmailLbl: Label 'Pay-to Contact E-Mail';
        HeaderLabel: array[20] of Text[30];
        HeaderTxt: array[20] of Text;
        FooterLabel: array[20] of Text[30];
        FooterTxt: array[20] of Text;
        Text11500: Label 'Credit Memo';
        Text11501: Label 'Prepmt. Credit Memo';
        VendorNoCaptionLbl: Label 'Vendor No.';

    protected var
        CompanyInfo: Record "Company Information";

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Purch. Cr. Memo") <> '';
    end;

    local procedure DocumentCaption(): Text[250]
    begin
        if "Purch. Cr. Memo Hdr."."Prepayment Credit Memo" then
            exit(Text11501);
        exit(Text11500);
    end;

    procedure InitializeRequest(NewNoOfCopies: Integer; NewShowInternalInfo: Boolean; NewLogInteraction: Boolean)
    begin
        NoOfCopies := NewNoOfCopies;
        ShowInternalInfo := NewShowInternalInfo;
        LogInteraction := NewLogInteraction;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        FormatAddr.GetCompanyAddr(PurchCrMemoHdr."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.PurchCrMemoPayTo(VendAddr, PurchCrMemoHdr);
        FormatAddr.PurchCrMemoShipTo(ShipToAddr, PurchCrMemoHdr);
    end;

    local procedure FormatDocumentFields(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        FormatDocument.SetTotalLabels(PurchCrMemoHdr."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetPurchaser(SalesPurchPerson, PurchCrMemoHdr."Purchaser Code", PurchaserText);

        ReturnOrderNoText := FormatDocument.SetText(PurchCrMemoHdr."Return Order No." <> '', PurchCrMemoHdr.FieldCaption("Return Order No."));
        ReferenceText := FormatDocument.SetText(PurchCrMemoHdr."Your Reference" <> '', PurchCrMemoHdr.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(PurchCrMemoHdr."VAT Registration No." <> '', PurchCrMemoHdr.FieldCaption("VAT Registration No."));
        RegNoText := FormatDocument.SetText(PurchCrMemoHdr."Registration No." <> '', PurchCrMemoHdr.FieldCaption("Registration No."));
        AppliedToText :=
          FormatDocument.SetText(
            PurchCrMemoHdr."Applies-to Doc. No." <> '', Format(StrSubstNo(Text003, Format(PurchCrMemoHdr."Applies-to Doc. Type"), PurchCrMemoHdr."Applies-to Doc. No.")));
    end;

    [Scope('OnPrem')]
    procedure PrepareHeader()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        FormatAddr.PurchCrMemoPayTo(VendAddr, "Purch. Cr. Memo Hdr.");
        RecRef.GetTable("Purch. Cr. Memo Hdr.");
        CHReportManagement.PrepareHeader(RecRef, REPORT::"Purchase - Credit Memo", HeaderLabel, HeaderTxt);
    end;

    [Scope('OnPrem')]
    procedure PrepareFooter()
    var
        CHReportManagement: Codeunit "CH Report Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable("Purch. Cr. Memo Hdr.");
        CHReportManagement.PrepareFooter(RecRef, REPORT::"Purchase - Credit Memo", FooterLabel, FooterTxt);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostDataItem(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}
