report 207 "Sales - Credit Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesCreditMemo.rdlc';
    Caption = 'Sales - Credit Memo';
    Permissions = TableData "Sales Shipment Buffer" = rimd;
    ObsoleteReason = 'Replaced with report 1307 Standard Sales - Credit Memo';
    ObsoleteState = Pending;
    ObsoleteTag = '15.2';

    dataset
    {
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Sales Credit Memo';
            column(No_SalesCrMemoHeader; "No.")
            {
            }
            column(DocumentDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionCap)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(DocCaptionCopyText; StrSubstNo(DocumentCaption, CopyText))
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(BilltoCustNo_SalesCrMemoHeader; "Sales Cr.Memo Header"."Bill-to Customer No.")
                    {
                    }
                    column(PostDate_SalesCrMemoHeader; Format("Sales Cr.Memo Header"."Posting Date", 0, 4))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_SalesCrMemoHeader; "Sales Cr.Memo Header"."VAT Registration No.")
                    {
                    }
                    column(No1_SalesCrMemoHeader; "Sales Cr.Memo Header"."No.")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
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
                    column(YourRef_SalesCrMemoHeader; "Sales Cr.Memo Header"."Your Reference")
                    {
                    }
                    column(CustAddr7; CustAddr[7])
                    {
                    }
                    column(CustAddr8; CustAddr[8])
                    {
                    }
                    column(DocDate_SalesCrMemoHeader; Format("Sales Cr.Memo Header"."Document Date", 0, 4))
                    {
                    }
                    column(PricIncVAT_SalesCrMemoHeader; "Sales Cr.Memo Header"."Prices Including VAT")
                    {
                    }
                    column(ReturnOrderNoText; ReturnOrderNoText)
                    {
                    }
                    column(RetOrderNo_SalesCrMemoHeader; "Sales Cr.Memo Header"."Return Order No.")
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricInclVAT1_SalesCrMemoHeader; Format("Sales Cr.Memo Header"."Prices Including VAT"))
                    {
                    }
                    column(VATBaseDiscPct_SalesCrMemoHeader; "Sales Cr.Memo Header"."VAT Base Discount %")
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
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoHomePageCaption; CompanyInfoHomePageCaptionLbl)
                    {
                    }
                    column(CompanyInfoEMail; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyInfoEMailCaption; CompanyInfoEMailCaptionLbl)
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoVATRegNoCaption; CompanyInfoVATRegNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankName; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(CompanyInfoBankAccNoCaption; CompanyInfoBankAccNoCaptionLbl)
                    {
                    }
                    column(CompanyAddress1; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddress2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddress3; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddress4; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddress5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddress6; CompanyAddr[6])
                    {
                    }
                    column(CrMemoNoCaption; CrMemoNoCaptionLbl)
                    {
                    }
                    column(PostingDateCaption; PostingDateCaptionLbl)
                    {
                    }
                    column(BilltoCustNo_SalesCrMemoHeaderCaption; "Sales Cr.Memo Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(PricIncVAT_SalesCrMemoHeaderCaption; "Sales Cr.Memo Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Cr.Memo Header";
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_IntegerLine; DimensionLoop1.Number)
                        {
                        }
                        column(HdrDimCaption; HdrDimCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet then
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
                            until DimSetEntry1.Next = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Sales Cr.Memo Line"; "Sales Cr.Memo Line")
                    {
                        DataItemLink = "Document No." = FIELD("No.");
                        DataItemLinkReference = "Sales Cr.Memo Header";
                        DataItemTableView = SORTING("Document No.", "Line No.");
                        column(LineAmt_SalesCrMemoLine; "Line Amount")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Desc_SalesCrMemoLine; Description)
                        {
                        }
                        column(No_SalesCrMemoLine; "No.")
                        {
                        }
                        column(Qty_SalesCrMemoLine; Quantity)
                        {
                        }
                        column(UOM_SalesCrMemoLine; "Unit of Measure")
                        {
                        }
                        column(UnitPrice_SalesCrMemoLine; "Unit Price")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(LineDisc_SalesCrMemoLine; "Line Discount %")
                        {
                        }
                        column(VATIdent_SalesCrMemoLine; "VAT Identifier")
                        {
                        }
                        column(PostedReceiptDate; Format("Shipment Date"))
                        {
                        }
                        column(Type_SalesCrMemoLine; Format(Type))
                        {
                        }
                        column(NNCTotalLineAmt; NNC_TotalLineAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(NNCTotalAmtInclVat; NNC_TotalAmountInclVat)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(NNCTotalInvDiscAmt; NNC_TotalInvDiscAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(NNCTotalAmt; NNC_TotalAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(Amt_SalesCrMemoLine; Amount)
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
                        column(AmtIncVAT_SalesCrMemoLine; "Amount Including VAT")
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtIncVATAmt_SalesCrMemoLine; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmtText; VATAmountLine.VATAmountText)
                        {
                        }
                        column(VATExemptionVATExemptNo; VATExemption.GetVATExemptNo())
                        {
                        }
                        column(VATExemptionVATExemptDate; Format(VATExemption."VAT Exempt. Date"))
                        {
                        }
                        column(VATExemptionCheck; VATExemptionCheck)
                        {
                        }
                        column(LineNo_SalesCrMemoLine; "Line No.")
                        {
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(DiscPercentCaption; DiscPercentCaptionLbl)
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(PostedReceiptDateCaption; PostedReceiptDateCaptionLbl)
                        {
                        }
                        column(InvDiscAmtCaption; InvDiscAmtCaptionLbl)
                        {
                        }
                        column(SubTotalCaption; SubTotalCaptionLbl)
                        {
                        }
                        column(PaymentDiscOnVATCaption; PaymentDiscOnVATCaptionLbl)
                        {
                        }
                        column(CustVATExemptionNoCaption; CustVATExemptionNoCaptionLbl)
                        {
                        }
                        column(CustVATExemptionDateCaption; CustVATExemptionDateCaptionLbl)
                        {
                        }
                        column(Desc_SalesCrMemoLineCaption; FieldCaption(Description))
                        {
                        }
                        column(No_SalesCrMemoLineCaption; FieldCaption("No."))
                        {
                        }
                        column(Qty_SalesCrMemoLineCaption; FieldCaption(Quantity))
                        {
                        }
                        column(UOM_SalesCrMemoLineCaption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(VATIdent_SalesCrMemoLineCaption; FieldCaption("VAT Identifier"))
                        {
                        }
                        column(SalesCrMemoLineHidden; Format(SalesCrMemoLineHidden, 0, 2))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimCaption; LineDimCaptionLbl)
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
                                until DimSetEntry2.Next = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                DimSetEntry2.SetRange("Dimension Set ID", "Sales Cr.Memo Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            NNC_TotalLineAmount += "Line Amount";
                            NNC_TotalAmountInclVat += "Amount Including VAT";
                            NNC_TotalInvDiscAmount += "Inv. Discount Amount";
                            NNC_TotalAmount += Amount;
                            if (Type = Type::"G/L Account") and (not ShowInternalInfo) then
                                "No." := '';

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
                            VATAmountLine."VAT Clause Code" := "VAT Clause Code";
                            VATAmountLine.InsertLine;

                            PrintCashVATFooter := PrintCashVATFooter or ("Sales Cr.Memo Line"."VAT Prod. Posting Group" = CashVATProdGrp);
                            SalesCrMemoLineHidden := (Type = Type::" ") or ((Quantity < 0) and ("Unit Price" > 0) and (Amount = 0));
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATAmountLine.DeleteAll();
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmtLineVATBase; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVATAmt; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineLineAmt; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscBaseAmt; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineInvDiscAmt; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier; VATAmountLine."VAT Identifier")
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
                        column(InvDiscAmt1Caption; InvDiscAmt1CaptionLbl)
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
                            SetRange(Number, 1, VATAmountLine.Count);
                            CleanAmountsInVATAmountLine;
                        end;
                    }
                    dataitem(VATClauseEntryCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATClauseVATIdentifier; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATClauseCode; VATAmountLine."VAT Clause Code")
                        {
                        }
                        column(VATClauseDescription; VATClause.Description)
                        {
                        }
                        column(VATClauseDescription2; VATClause."Description 2")
                        {
                        }
                        column(VATClauseAmount; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATClausesCaption; VATClausesCap)
                        {
                        }
                        column(VATClauseVATIdentifierCaption; VATIdentifierCaptionLbl)
                        {
                        }
                        column(VATClauseVATAmtCaption; VATAmtCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                            if not VATClause.Get(VATAmountLine."VAT Clause Code") then
                                CurrReport.Skip();
                            VATClause.GetDescription("Sales Cr.Memo Header");
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(VATClause);
                            SetRange(Number, 1, VATAmountLine.Count);
                        end;
                    }
                    dataitem(VATCounterLCY; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VALSpecLCYHeader; VALSpecLCYHeader)
                        {
                        }
                        column(VALExchRate; VALExchRate)
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
                        column(VATAmtLineVAT1; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier1; VATAmountLine."VAT Identifier")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              VATAmountLine.GetBaseLCY(
                                "Sales Cr.Memo Header"."Posting Date", "Sales Cr.Memo Header"."Currency Code",
                                "Sales Cr.Memo Header"."Currency Factor");
                            VALVATAmountLCY :=
                              VATAmountLine.GetAmountLCY(
                                "Sales Cr.Memo Header"."Posting Date", "Sales Cr.Memo Header"."Currency Code",
                                "Sales Cr.Memo Header"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Cr.Memo Header"."Currency Code" = '')
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, VATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text008 + Text009
                            else
                                VALSpecLCYHeader := Text008 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Sales Cr.Memo Header"."Posting Date", "Sales Cr.Memo Header"."Currency Code", 1);
                            CalculatedExchRate := Round(1 / "Sales Cr.Memo Header"."Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.000001);
                            VALExchRate := StrSubstNo(Text010, CalculatedExchRate, CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(SelltoCustNo_SalesCrMemoHeader; "Sales Cr.Memo Header"."Sell-to Customer No.")
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
                        column(ShiptoAddCaption; ShiptoAddCaptionLbl)
                        {
                        }
                        column(SelltoCustNo_SalesCrMemoHeaderCaption; "Sales Cr.Memo Header".FieldCaption("Sell-to Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(CashVATFooter; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(CashVATFooterText; CashVATFooterText)
                        {
                        }
                        column(PrintCashVATFooter; PrintCashVATFooter)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not PrintCashVATFooter then
                                CurrReport.Skip();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText;
                        OutputNo += 1;
                    end;

                    NNC_TotalLineAmount := 0;
                    NNC_TotalAmountInclVat := 0;
                    NNC_TotalInvDiscAmount := 0;
                    NNC_TotalAmount := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Sales Cr. Memo-Printed", "Sales Cr.Memo Header");
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
            var
                SalesHeader: Record "Sales Header";
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("Sales Cr.Memo Header");
                FormatDocumentFields("Sales Cr.Memo Header");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                PrintCashVATFooter := false;
                SalesHeader.TransferFields("Sales Cr.Memo Header");
                SalesHeader.FindVATExemption(VATExemption, VATExemptionCheck, true);

                OnAfterGetRecordSalesCrMemoHeader("Sales Cr.Memo Header");
            end;

            trigger OnPostDataItem()
            begin
                OnAfterPostDataItem("Sales Cr.Memo Header");
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
            LogInteraction := SegManagement.FindInteractTmplCode(6) <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        VATProdPostingGr: Record "VAT Product Posting Group";
    begin
        GLSetup.Get();
        SalesSetup.Get();
        CompanyInfo.Get();
        FormatDocument.SetLogoPosition(SalesSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);

        CashVATProdGrp := GLSetup."CashVAT Product Posting Group";
        if StrLen(CashVATProdGrp) > 0 then begin
            VATProdPostingGr.Get(CashVATProdGrp);
            CashVATFooterText := VATProdPostingGr.Description;
        end else
            CashVATFooterText := '';

        OnAfterInitReport;
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode then
            if "Sales Cr.Memo Header".FindSet then
                repeat
                    if "Sales Cr.Memo Header"."Bill-to Contact No." <> '' then
                        SegManagement.LogDocument(
                          6, "Sales Cr.Memo Header"."No.", 0, 0, DATABASE::Contact, "Sales Cr.Memo Header"."Bill-to Contact No.",
                          "Sales Cr.Memo Header"."Salesperson Code", "Sales Cr.Memo Header"."Campaign No.",
                          "Sales Cr.Memo Header"."Posting Description", '')
                    else
                        SegManagement.LogDocument(
                          6, "Sales Cr.Memo Header"."No.", 0, 0, DATABASE::Customer, "Sales Cr.Memo Header"."Sell-to Customer No.",
                          "Sales Cr.Memo Header"."Salesperson Code", "Sales Cr.Memo Header"."Campaign No.",
                          "Sales Cr.Memo Header"."Posting Description", '');
                until "Sales Cr.Memo Header".Next = 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        Text003: Label '(Applies to %1 %2)';
        Text005: Label 'Sales - Credit Memo %1', Comment = '%1 = Document No.';
        PageCaptionCap: Label 'Page %1 of %2';
        GLSetup: Record "General Ledger Setup";
        RespCenter: Record "Responsibility Center";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        VATAmountLine: Record "VAT Amount Line" temporary;
        VATClause: Record "VAT Clause";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        VATExemption: Record "VAT Exemption";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        ReturnOrderNoText: Text[80];
        SalesPersonText: Text[30];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        AppliedToText: Text;
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
        LogInteraction: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        Text008: Label 'VAT Amount Specification in ';
        Text009: Label 'Local Currency';
        Text010: Label 'Exchange rate: %1/%2';
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        CalculatedExchRate: Decimal;
        Text011: Label 'Sales - Prepmt. Credit Memo %1';
        OutputNo: Integer;
        NNC_TotalLineAmount: Decimal;
        NNC_TotalAmountInclVat: Decimal;
        NNC_TotalInvDiscAmount: Decimal;
        NNC_TotalAmount: Decimal;
        CashVATFooterText: Text[100];
        CashVATProdGrp: Code[20];
        PrintCashVATFooter: Boolean;
        [InDataSet]
        LogInteractionEnable: Boolean;
        VATExemptionCheck: Boolean;
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        CompanyInfoEMailCaptionLbl: Label 'Email';
        CompanyInfoVATRegNoCaptionLbl: Label 'VAT Registration No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        CrMemoNoCaptionLbl: Label 'Credit Memo No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        HdrDimCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        DiscPercentCaptionLbl: Label 'Discount %';
        AmtCaptionLbl: Label 'Amount';
        PostedReceiptDateCaptionLbl: Label 'Posted Return Receipt Date';
        InvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        SubTotalCaptionLbl: Label 'Subtotal';
        PaymentDiscOnVATCaptionLbl: Label 'Payment Discount on VAT';
        VATClausesCap: Label 'VAT Clause';
        CustVATExemptionNoCaptionLbl: Label 'Customer VAT Exemption No.';
        CustVATExemptionDateCaptionLbl: Label 'Customer VAT Exemption Date';
        LineDimCaptionLbl: Label 'Line Dimensions';
        VATPercentCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        LineAmtCaptionLbl: Label 'Line Amount';
        InvDiscAmt1CaptionLbl: Label 'Invoice Discount Amount';
        TotalCaptionLbl: Label 'Total';
        ShiptoAddCaptionLbl: Label 'Ship-to Address';
        DocumentDateCaptionLbl: Label 'Document Date';
        SalesCrMemoLineHidden: Boolean;

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractTmplCode(6) <> '';
    end;

    local procedure DocumentCaption(): Text[250]
    var
        DocCaption: Text[250];
    begin
        OnBeforeDocumentCaption("Sales Cr.Memo Header", DocCaption);
        if DocCaption <> '' then
            exit(DocCaption);
        if "Sales Cr.Memo Header"."Prepayment Credit Memo" then
            exit(Text011);
        exit(Text005);
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
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;

    local procedure FormatAddressFields(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        FormatAddr.GetCompanyAddr(SalesCrMemoHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.SalesCrMemoBillTo(CustAddr, SalesCrMemoHeader);
        ShowShippingAddr := FormatAddr.SalesCrMemoShipTo(ShipToAddr, CustAddr, SalesCrMemoHeader);
    end;

    local procedure FormatDocumentFields(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        with SalesCrMemoHeader do begin
            FormatDocument.SetTotalLabels("Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
            FormatDocument.SetSalesPerson(SalesPurchPerson, "Salesperson Code", SalesPersonText);

            ReturnOrderNoText := FormatDocument.SetText("Return Order No." <> '', FieldCaption("Return Order No."));
            ReferenceText := FormatDocument.SetText("Your Reference" <> '', FieldCaption("Your Reference"));
            VATNoText := FormatDocument.SetText("VAT Registration No." <> '', FieldCaption("VAT Registration No."));
            AppliedToText :=
              FormatDocument.SetText(
                "Applies-to Doc. No." <> '', Format(StrSubstNo(Text003, Format("Applies-to Doc. Type"), "Applies-to Doc. No.")));
        end;
    end;

    local procedure CleanAmountsInVATAmountLine()
    begin
        VATAmountLine.SetRange("VAT Calculation Type", VATAmountLine."VAT Calculation Type"::"Full VAT");
        VATAmountLine.ModifyAll("Line Amount", 0);
        VATAmountLine.ModifyAll("Inv. Disc. Base Amount", 0);
        VATAmountLine.SetRange("VAT Calculation Type");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterPostDataItem(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDocumentCaption(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var DocCaption: Text[250])
    begin
    end;
}

