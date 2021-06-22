report 202 "Sales Document - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesDocumentTest.rdlc';
    Caption = 'Sales Document - Test';

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = WHERE("Document Type" = FILTER(<> Quote));
            RequestFilterFields = "Document Type", "No.";
            RequestFilterHeading = 'Sales Document';
            column(Sales_Header_Document_Type; "Document Type")
            {
            }
            column(Sales_Header_No_; "No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(USERID; UserId)
                {
                }
                column(STRSUBSTNO_Text014_SalesHeaderFilter_; StrSubstNo(Text014, SalesHeaderFilter))
                {
                }
                column(SalesHeaderFilter; SalesHeaderFilter)
                {
                }
                column(ShipInvText; ShipInvText)
                {
                }
                column(ReceiveInvText; ReceiveInvText)
                {
                }
                column(Sales_Header___Sell_to_Customer_No__; "Sales Header"."Sell-to Customer No.")
                {
                }
                column(ShipToAddr_8_; ShipToAddr[8])
                {
                }
                column(ShipToAddr_7_; ShipToAddr[7])
                {
                }
                column(ShipToAddr_6_; ShipToAddr[6])
                {
                }
                column(ShipToAddr_5_; ShipToAddr[5])
                {
                }
                column(ShipToAddr_4_; ShipToAddr[4])
                {
                }
                column(ShipToAddr_3_; ShipToAddr[3])
                {
                }
                column(ShipToAddr_2_; ShipToAddr[2])
                {
                }
                column(ShipToAddr_1_; ShipToAddr[1])
                {
                }
                column(SellToAddr_8_; SellToAddr[8])
                {
                }
                column(SellToAddr_7_; SellToAddr[7])
                {
                }
                column(SellToAddr_6_; SellToAddr[6])
                {
                }
                column(SellToAddr_5_; SellToAddr[5])
                {
                }
                column(SellToAddr_4_; SellToAddr[4])
                {
                }
                column(SellToAddr_3_; SellToAddr[3])
                {
                }
                column(SellToAddr_2_; SellToAddr[2])
                {
                }
                column(SellToAddr_1_; SellToAddr[1])
                {
                }
                column(Sales_Header___Ship_to_Code_; "Sales Header"."Ship-to Code")
                {
                }
                column(FORMAT__Sales_Header___Document_Type____________Sales_Header___No__; Format("Sales Header"."Document Type") + ' ' + "Sales Header"."No.")
                {
                }
                column(ShipReceiveOnNextPostReq; ShipReceiveOnNextPostReq)
                {
                }
                column(ShowCostAssignment; ShowCostAssignment)
                {
                }
                column(InvOnNextPostReq; InvOnNextPostReq)
                {
                }
                column(Sales_Header___VAT_Base_Discount___; "Sales Header"."VAT Base Discount %")
                {
                }
                column(SalesDocumentType; Format("Sales Header"."Document Type", 0, 2))
                {
                }
                column(BillToAddr_8_; BillToAddr[8])
                {
                }
                column(BillToAddr_7_; BillToAddr[7])
                {
                }
                column(BillToAddr_6_; BillToAddr[6])
                {
                }
                column(BillToAddr_5_; BillToAddr[5])
                {
                }
                column(BillToAddr_4_; BillToAddr[4])
                {
                }
                column(BillToAddr_3_; BillToAddr[3])
                {
                }
                column(BillToAddr_2_; BillToAddr[2])
                {
                }
                column(BillToAddr_1_; BillToAddr[1])
                {
                }
                column(Sales_Header___Bill_to_Customer_No__; "Sales Header"."Bill-to Customer No.")
                {
                }
                column(Sales_Header___Salesperson_Code_; "Sales Header"."Salesperson Code")
                {
                }
                column(Sales_Header___Your_Reference_; "Sales Header"."Your Reference")
                {
                }
                column(Sales_Header___Customer_Posting_Group_; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date_; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date_; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT_; "Sales Header"."Prices Including VAT")
                {
                }
                column(SalesHdrPricesIncludingVATFmt; Format("Sales Header"."Prices Including VAT"))
                {
                }
                column(Sales_Header___Payment_Terms_Code_; "Sales Header"."Payment Terms Code")
                {
                }
                column(Sales_Header___Payment_Discount___; "Sales Header"."Payment Discount %")
                {
                }
                column(Sales_Header___Due_Date_; Format("Sales Header"."Due Date"))
                {
                }
                column(Sales_Header___Customer_Disc__Group_; "Sales Header"."Customer Disc. Group")
                {
                }
                column(Sales_Header___Pmt__Discount_Date_; Format("Sales Header"."Pmt. Discount Date"))
                {
                }
                column(Sales_Header___Invoice_Disc__Code_; "Sales Header"."Invoice Disc. Code")
                {
                }
                column(Sales_Header___Shipment_Method_Code_; "Sales Header"."Shipment Method Code")
                {
                }
                column(Sales_Header___Payment_Method_Code_; "Sales Header"."Payment Method Code")
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control104; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date__Control105; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date__Control106; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Order_Date_; Format("Sales Header"."Order Date"))
                {
                }
                column(Sales_Header___Shipment_Date_; Format("Sales Header"."Shipment Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control194; "Sales Header"."Prices Including VAT")
                {
                }
                column(Sales_Header___Payment_Terms_Code__Control18; "Sales Header"."Payment Terms Code")
                {
                }
                column(Sales_Header___Due_Date__Control19; Format("Sales Header"."Due Date"))
                {
                }
                column(Sales_Header___Pmt__Discount_Date__Control22; Format("Sales Header"."Pmt. Discount Date"))
                {
                }
                column(Sales_Header___Payment_Discount____Control23; "Sales Header"."Payment Discount %")
                {
                }
                column(Sales_Header___Payment_Method_Code__Control26; "Sales Header"."Payment Method Code")
                {
                }
                column(Sales_Header___Shipment_Method_Code__Control37; "Sales Header"."Shipment Method Code")
                {
                }
                column(Sales_Header___Customer_Disc__Group__Control100; "Sales Header"."Customer Disc. Group")
                {
                }
                column(Sales_Header___Invoice_Disc__Code__Control102; "Sales Header"."Invoice Disc. Code")
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control130; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date__Control131; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date__Control132; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control196; "Sales Header"."Prices Including VAT")
                {
                }
                column(Sales_Header___Applies_to_Doc__Type_; "Sales Header"."Applies-to Doc. Type")
                {
                }
                column(Sales_Header___Applies_to_Doc__No__; "Sales Header"."Applies-to Doc. No.")
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control136; "Sales Header"."Customer Posting Group")
                {
                }
                column(Sales_Header___Posting_Date__Control137; Format("Sales Header"."Posting Date"))
                {
                }
                column(Sales_Header___Document_Date__Control138; Format("Sales Header"."Document Date"))
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control198; "Sales Header"."Prices Including VAT")
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(Sales_Document___TestCaption; Sales_Document___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Sales_Header___Sell_to_Customer_No__Caption; "Sales Header".FieldCaption("Sell-to Customer No."))
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(Sell_toCaption; Sell_toCaptionLbl)
                {
                }
                column(Sales_Header___Ship_to_Code_Caption; "Sales Header".FieldCaption("Ship-to Code"))
                {
                }
                column(Bill_toCaption; Bill_toCaptionLbl)
                {
                }
                column(Sales_Header___Bill_to_Customer_No__Caption; "Sales Header".FieldCaption("Bill-to Customer No."))
                {
                }
                column(Sales_Header___Salesperson_Code_Caption; "Sales Header".FieldCaption("Salesperson Code"))
                {
                }
                column(Sales_Header___Your_Reference_Caption; "Sales Header".FieldCaption("Your Reference"))
                {
                }
                column(Sales_Header___Customer_Posting_Group_Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date_Caption; Sales_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date_Caption; Sales_Header___Document_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT_Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Sales_Header___Payment_Terms_Code_Caption; "Sales Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Sales_Header___Payment_Discount___Caption; "Sales Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Sales_Header___Due_Date_Caption; Sales_Header___Due_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Customer_Disc__Group_Caption; "Sales Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Sales_Header___Pmt__Discount_Date_Caption; Sales_Header___Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Invoice_Disc__Code_Caption; "Sales Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Sales_Header___Shipment_Method_Code_Caption; "Sales Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Sales_Header___Payment_Method_Code_Caption; "Sales Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control104Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date__Control105Caption; Sales_Header___Posting_Date__Control105CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date__Control106Caption; Sales_Header___Document_Date__Control106CaptionLbl)
                {
                }
                column(Sales_Header___Order_Date_Caption; Sales_Header___Order_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Shipment_Date_Caption; Sales_Header___Shipment_Date_CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control194Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Sales_Header___Payment_Terms_Code__Control18Caption; "Sales Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Sales_Header___Payment_Discount____Control23Caption; "Sales Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Sales_Header___Due_Date__Control19Caption; Sales_Header___Due_Date__Control19CaptionLbl)
                {
                }
                column(Sales_Header___Pmt__Discount_Date__Control22Caption; Sales_Header___Pmt__Discount_Date__Control22CaptionLbl)
                {
                }
                column(Sales_Header___Shipment_Method_Code__Control37Caption; "Sales Header".FieldCaption("Shipment Method Code"))
                {
                }
                column(Sales_Header___Payment_Method_Code__Control26Caption; "Sales Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Sales_Header___Customer_Disc__Group__Control100Caption; "Sales Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Sales_Header___Invoice_Disc__Code__Control102Caption; "Sales Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control130Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date__Control131Caption; Sales_Header___Posting_Date__Control131CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date__Control132Caption; Sales_Header___Document_Date__Control132CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control196Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Sales_Header___Applies_to_Doc__Type_Caption; "Sales Header".FieldCaption("Applies-to Doc. Type"))
                {
                }
                column(Sales_Header___Applies_to_Doc__No__Caption; "Sales Header".FieldCaption("Applies-to Doc. No."))
                {
                }
                column(Sales_Header___Customer_Posting_Group__Control136Caption; "Sales Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Sales_Header___Posting_Date__Control137Caption; Sales_Header___Posting_Date__Control137CaptionLbl)
                {
                }
                column(Sales_Header___Document_Date__Control138Caption; Sales_Header___Document_Date__Control138CaptionLbl)
                {
                }
                column(Sales_Header___Prices_Including_VAT__Control198Caption; "Sales Header".FieldCaption("Prices Including VAT"))
                {
                }
                dataitem(DimensionLoop1; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimensionLoop1_Number; Number)
                    {
                    }
                    column(DimText_Control162; DimText)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
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

                        DimText := '';
                        Continue := false;
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText, DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                Continue := true;
                                exit;
                            end;
                        until DimSetEntry1.Next = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(HeaderErrorCounter_Number; Number)
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem(CopyLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    MaxIteration = 1;
                    dataitem("Sales Line"; "Sales Line")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");
                        column(Sales_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Sales_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Sales_Line_Line_No_; "Line No.")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if Find('+') then
                                OrigMaxLineNo := "Line No.";
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(QtyToHandleCaption; QtyToHandleCaption)
                        {
                        }
                        column(Sales_Line__Type; Format("Sales Line".Type))
                        {
                        }
                        column(Sales_Line___No__; "Sales Line"."No.")
                        {
                        }
                        column(Sales_Line__Description; "Sales Line".Description)
                        {
                        }
                        column(Sales_Line__Quantity; "Sales Line".Quantity)
                        {
                        }
                        column(QtyToHandle; QtyToHandle)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Sales_Line___Qty__to_Invoice_; "Sales Line"."Qty. to Invoice")
                        {
                        }
                        column(Sales_Line___Unit_Price_; "Sales Line"."Unit Price")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Sales_Line___Line_Discount___; "Sales Line"."Line Discount %")
                        {
                        }
                        column(Sales_Line___Line_Amount_; "Sales Line"."Line Amount")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Sales_Line___Allow_Invoice_Disc__; "Sales Line"."Allow Invoice Disc.")
                        {
                        }
                        column(Sales_Line___VAT_Identifier_; "Sales Line"."VAT Identifier")
                        {
                        }
                        column(SalesLineAllowInvoiceDiscFmt; Format("Sales Line"."Allow Invoice Disc."))
                        {
                        }
                        column(RoundLoop_RoundLoop_Number; Number)
                        {
                        }
                        column(Sales_Line___Inv__Discount_Amount_; "Sales Line"."Inv. Discount Amount")
                        {
                        }
                        column(TempSalesLine__Inv__Discount_Amount_; -TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempSalesLine__Line_Amount_; TempSalesLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(SumLineAmount; SumLineAmount)
                        {
                        }
                        column(SumInvDiscountAmount; SumInvDiscountAmount)
                        {
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TempSalesLine__Line_Amount_____Sales_Line___Inv__Discount_Amount_; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText; VATAmountLine.VATAmountText)
                        {
                        }
                        column(TempSalesLine__Line_Amount____TempSalesLine__Inv__Discount_Amount_; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempSalesLine__Line_Amount____TempSalesLine__Inv__Discount_Amount____VATAmount; TempSalesLine."Line Amount" - TempSalesLine."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText_Control191; TotalInclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText_Control189; VATAmountLine.VATAmountText)
                        {
                        }
                        column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount_Control188; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText_Control186; TotalExclVATText)
                        {
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Sales_Line___No__Caption; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(Sales_Line__DescriptionCaption; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(Sales_Line___Qty__to_Invoice_Caption; "Sales Line".FieldCaption("Qty. to Invoice"))
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Sales_Line___Line_Discount___Caption; Sales_Line___Line_Discount___CaptionLbl)
                        {
                        }
                        column(Sales_Line___Allow_Invoice_Disc__Caption; "Sales Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(Sales_Line___VAT_Identifier_Caption; "Sales Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Sales_Line__TypeCaption; "Sales Line".FieldCaption(Type))
                        {
                        }
                        column(Sales_Line__QuantityCaption; "Sales Line".FieldCaption(Quantity))
                        {
                        }
                        column(TempSalesLine__Inv__Discount_Amount_Caption; TempSalesLine__Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(VATDiscountAmountCaption; VATDiscountAmountCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText_Control159; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
                            {
                            }
                            column(DimText_Control161; DimText)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                DimText := '';
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText, DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next = 0;
                            end;

                            trigger OnPostDataItem()
                            begin
                                SumLineAmount := SumLineAmount + TempSalesLine."Line Amount";
                                SumInvDiscountAmount := SumInvDiscountAmount + TempSalesLine."Inv. Discount Amount";
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowDim then
                                    CurrReport.Break();
                            end;
                        }
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            column(ErrorText_Number__Control97; ErrorText[Number])
                            {
                            }
                            column(LineErrorCounter_Number; Number)
                            {
                            }
                            column(ErrorText_Number__Control97Caption; ErrorText_Number__Control97CaptionLbl)
                            {
                            }

                            trigger OnPostDataItem()
                            begin
                                ErrorCounter := 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, ErrorCounter);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        var
                            TableID: array[10] of Integer;
                            No: array[10] of Code[20];
                            Fraction: Decimal;
                        begin
                            if Number = 1 then
                                TempSalesLine.Find('-')
                            else
                                TempSalesLine.Next;
                            "Sales Line" := TempSalesLine;

                            with "Sales Line" do begin
                                if not "Sales Header"."Prices Including VAT" and
                                   ("VAT Calculation Type" = "VAT Calculation Type"::"Full VAT")
                                then
                                    TempSalesLine."Line Amount" := 0;

                                DimSetEntry2.SetRange("Dimension Set ID", "Dimension Set ID");
                                DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");

                                if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]
                                then begin
                                    if "Document Type" = "Document Type"::"Credit Memo" then begin
                                        if ("Return Qty. to Receive" <> Quantity) and ("Return Receipt No." = '') then
                                            AddError(StrSubstNo(Text015, FieldCaption("Return Qty. to Receive"), Quantity));
                                        if "Qty. to Invoice" <> Quantity then
                                            AddError(StrSubstNo(Text015, FieldCaption("Qty. to Invoice"), Quantity));
                                    end;
                                    if "Qty. to Ship" <> 0 then
                                        AddError(StrSubstNo(Text043, FieldCaption("Qty. to Ship")));
                                end else begin
                                    if "Document Type" = "Document Type"::Invoice then begin
                                        if ("Qty. to Ship" <> Quantity) and ("Shipment No." = '') then
                                            AddError(StrSubstNo(Text015, FieldCaption("Qty. to Ship"), Quantity));
                                        if "Qty. to Invoice" <> Quantity then
                                            AddError(StrSubstNo(Text015, FieldCaption("Qty. to Invoice"), Quantity));
                                    end;
                                    if "Return Qty. to Receive" <> 0 then
                                        AddError(StrSubstNo(Text043, FieldCaption("Return Qty. to Receive")));
                                end;

                                if not "Sales Header".Ship then
                                    "Qty. to Ship" := 0;
                                if not "Sales Header".Receive then
                                    "Return Qty. to Receive" := 0;

                                if ("Document Type" = "Document Type"::Invoice) and ("Shipment No." <> '') then begin
                                    "Quantity Shipped" := Quantity;
                                    "Qty. to Ship" := 0;
                                end;

                                if ("Document Type" = "Document Type"::"Credit Memo") and ("Return Receipt No." <> '') then begin
                                    "Return Qty. Received" := Quantity;
                                    "Return Qty. to Receive" := 0;
                                end;

                                if "Sales Header".Invoice then begin
                                    if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then
                                        MaxQtyToBeInvoiced := "Return Qty. to Receive" + "Return Qty. Received" - "Quantity Invoiced"
                                    else
                                        MaxQtyToBeInvoiced := "Qty. to Ship" + "Quantity Shipped" - "Quantity Invoiced";
                                    if Abs("Qty. to Invoice") > Abs(MaxQtyToBeInvoiced) then
                                        "Qty. to Invoice" := MaxQtyToBeInvoiced;
                                end else
                                    "Qty. to Invoice" := 0;

                                if "Gen. Prod. Posting Group" <> '' then begin
                                    if ("Sales Header"."Document Type" in
                                        ["Sales Header"."Document Type"::"Return Order",
                                         "Sales Header"."Document Type"::"Credit Memo"]) and
                                       ("Sales Header"."Applies-to Doc. Type" = "Sales Header"."Applies-to Doc. Type"::Invoice) and
                                       ("Sales Header"."Applies-to Doc. No." <> '')
                                    then begin
                                        CustLedgEntry.SetCurrentKey("Document No.");
                                        CustLedgEntry.SetRange("Customer No.", "Sales Header"."Bill-to Customer No.");
                                        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                        CustLedgEntry.SetRange("Document No.", "Sales Header"."Applies-to Doc. No.");
                                        if (not CustLedgEntry.FindLast) and (not ApplNoError) then begin
                                            ApplNoError := true;
                                            AddError(
                                              StrSubstNo(
                                                Text016,
                                                "Sales Header".FieldCaption("Applies-to Doc. No."), "Sales Header"."Applies-to Doc. No."));
                                        end;
                                    end;

                                    if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                                        AddError(
                                          StrSubstNo(
                                            Text017,
                                            VATPostingSetup.TableCaption, "VAT Bus. Posting Group", "VAT Prod. Posting Group"));
                                    if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                        if ("Sales Header"."VAT Registration No." = '') and (not VATNoError) then begin
                                            VATNoError := true;
                                            AddError(
                                              StrSubstNo(
                                                Text035, "Sales Header".FieldCaption("VAT Registration No.")));
                                        end;
                                end;

                                if Quantity <> 0 then begin
                                    if "No." = '' then
                                        AddError(StrSubstNo(Text019, Type, FieldCaption("No.")));
                                    if Type = 0 then
                                        AddError(StrSubstNo(Text006, FieldCaption(Type)));
                                end else
                                    if Amount <> 0 then
                                        AddError(
                                          StrSubstNo(Text020, FieldCaption(Amount), FieldCaption(Quantity)));

                                if "Drop Shipment" then begin
                                    if Type <> Type::Item then
                                        AddError(Text021);
                                    if ("Qty. to Ship" <> 0) and ("Purch. Order Line No." = 0) then begin
                                        AddError(StrSubstNo(Text022, "Line No."));
                                        AddError(Text023);
                                    end;
                                end;

                                SalesLine := "Sales Line";
                                if not ("Document Type" in
                                        ["Document Type"::"Return Order", "Document Type"::"Credit Memo"])
                                then begin
                                    SalesLine."Qty. to Ship" := -SalesLine."Qty. to Ship";
                                    SalesLine."Qty. to Invoice" := -SalesLine."Qty. to Invoice";
                                end;

                                RemQtyToBeInvoiced := SalesLine."Qty. to Invoice";

                                case "Document Type" of
                                    "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                                        CheckRcptLines("Sales Line");
                                    "Document Type"::Order, "Document Type"::Invoice:
                                        CheckShptLines("Sales Line");
                                end;

                                if (Type >= Type::"G/L Account") and ("Qty. to Invoice" <> 0) then begin
                                    if not ApplicationAreaMgmt.IsSalesTaxEnabled then
                                        if not GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                                            AddError(
                                              StrSubstNo(
                                                Text017,
                                                GenPostingSetup.TableCaption, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"));
                                    if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                                        AddError(
                                          StrSubstNo(
                                            Text017,
                                            VATPostingSetup.TableCaption, "VAT Bus. Posting Group", "VAT Prod. Posting Group"));
                                end;

                                if "Prepayment %" > 0 then
                                    if not "Prepayment Line" and (Quantity > 0) then begin
                                        Fraction := ("Qty. to Invoice" + "Quantity Invoiced") / Quantity;
                                        if Fraction > 1 then
                                            Fraction := 1;

                                        case true of
                                            (Fraction * "Line Amount" < "Prepmt Amt to Deduct") and
                                          ("Prepmt Amt to Deduct" <> 0):
                                                AddError(
                                                  StrSubstNo(
                                                    Text053,
                                                    FieldCaption("Prepmt Amt to Deduct"),
                                                    Round(Fraction * "Line Amount", GLSetup."Amount Rounding Precision")));
                                            (1 - Fraction) * "Line Amount" <
                                          "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" - "Prepmt Amt to Deduct":
                                                AddError(
                                                  StrSubstNo(
                                                    Text054,
                                                    FieldCaption("Prepmt Amt to Deduct"),
                                                    Round(
                                                      "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" - (1 - Fraction) * "Line Amount",
                                                      GLSetup."Amount Rounding Precision")));
                                        end;
                                    end;
                                if not "Prepayment Line" and ("Prepmt. Line Amount" > 0) then
                                    if "Prepmt. Line Amount" > "Prepmt. Amt. Inv." then
                                        AddError(StrSubstNo(Text046, FieldCaption("Prepmt. Line Amount")));

                                CheckSalesLine("Sales Line");

                                if "Line No." > OrigMaxLineNo then begin
                                    AddDimToTempLine("Sales Line");
                                    if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                        AddError(DimMgt.GetDimCombErr);
                                    if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                                        AddError(DimMgt.GetDimValuePostingErr);
                                end else begin
                                    if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                        AddError(DimMgt.GetDimCombErr);

                                    TableID[1] := DimMgt.TypeToTableID3(Type);
                                    No[1] := "No.";
                                    TableID[2] := DATABASE::Job;
                                    No[2] := "Job No.";
                                    OnBeforeCheckDimValuePostingLine("Sales Line", TableID, No);
                                    if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                                        AddError(DimMgt.GetDimValuePostingErr);
                                end;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATNoError := false;
                            ApplNoError := false;

                            MoreLines := TempSalesLine.Find('+');
                            while MoreLines and (TempSalesLine.Description = '') and (TempSalesLine."Description 2" = '') and
                                  (TempSalesLine."No." = '') and (TempSalesLine.Quantity = 0) and
                                  (TempSalesLine.Amount = 0)
                            do
                                MoreLines := TempSalesLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempSalesLine.SetRange("Line No.", 0, TempSalesLine."Line No.");
                            SetRange(Number, 1, TempSalesLine.Count);

                            SumLineAmount := 0;
                            SumInvDiscountAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmountLine__VAT_Amount_; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base_; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control150; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control151; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier_; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control173; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control171; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control169; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control175; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control176; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control177; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control178; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control179; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control181; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control182; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control183; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control184; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control185; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
                        }
                        column(VATAmountLine__VAT_Amount__Control150Caption; VATAmountLine__VAT_Amount__Control150CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control151Caption; VATAmountLine__VAT_Base__Control151CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control173Caption; VATAmountLine__Invoice_Discount_Amount__Control173CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control171Caption; VATAmountLine__Inv__Disc__Base_Amount__Control171CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Line_Amount__Control169Caption; VATAmountLine__Line_Amount__Control169CaptionLbl)
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control155; ContinuedCaption_Control155Lbl)
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
                        column(VALVATAmountLCY_Control88; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control165; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT____Control167; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier__Control241; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VALVATAmountLCY_Control242; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control243; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY_Control245; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATBaseLCY_Control246; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATCounterLCY_Number; Number)
                        {
                        }
                        column(VALVATAmountLCY_Control88Caption; VALVATAmountLCY_Control88CaptionLbl)
                        {
                        }
                        column(VALVATBaseLCY_Control165Caption; VALVATBaseLCY_Control165CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT____Control167Caption; VATAmountLine__VAT____Control167CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier__Control241Caption; VATAmountLine__VAT_Identifier__Control241CaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control87; ContinuedCaption_Control87Lbl)
                        {
                        }
                        column(ContinuedCaption_Control244; ContinuedCaption_Control244Lbl)
                        {
                        }
                        column(TotalCaption_Control247; TotalCaption_Control247Lbl)
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
                        var
                            CurrExchRate: Record "Currency Exchange Rate";
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Header"."Currency Code" = '')
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, VATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text050 + Text051
                            else
                                VALSpecLCYHeader := Text050 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Sales Header"."Posting Date", "Sales Header"."Currency Code", 1);
                            CurrExchRate."Relational Exch. Rate Amount" := CurrExchRate."Exchange Rate Amount" / "Sales Header"."Currency Factor";
                            VALExchRate := StrSubstNo(Text052, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem("Item Charge Assignment (Sales)"; "Item Charge Assignment (Sales)")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("Document No.");
                        DataItemLinkReference = "Sales Line";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Document Line No.", "Line No.");
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign_; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign_; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Item_Charge_No__; "Item Charge No.")
                        {
                        }
                        column(SalesLine2_Description; SalesLine2.Description)
                        {
                        }
                        column(SalesLine2_Quantity; SalesLine2.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Item_Charge_Assignment__Sales___Item_No__; "Item No.")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control209; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Unit_Cost_; "Unit Cost")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control216; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control221; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control222; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control224; "Qty. to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control225; "Amount to Assign")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Document_Type; "Document Type")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Document_No_; "Document No.")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Document_Line_No_; "Document Line No.")
                        {
                        }
                        column(Item_Charge_Assignment__Sales__Line_No_; "Line No.")
                        {
                        }
                        column(Item_Charge_SpecificationCaption; Item_Charge_SpecificationCaptionLbl)
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Item_Charge_No__Caption; FieldCaption("Item Charge No."))
                        {
                        }
                        column(SalesLine2_DescriptionCaption; SalesLine2_DescriptionCaptionLbl)
                        {
                        }
                        column(SalesLine2_QuantityCaption; SalesLine2_QuantityCaptionLbl)
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Item_No__Caption; FieldCaption("Item No."))
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Qty__to_Assign__Control209Caption; FieldCaption("Qty. to Assign"))
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Unit_Cost_Caption; FieldCaption("Unit Cost"))
                        {
                        }
                        column(Item_Charge_Assignment__Sales___Amount_to_Assign__Control216Caption; FieldCaption("Amount to Assign"))
                        {
                        }
                        column(ContinuedCaption_Control210; ContinuedCaption_Control210Lbl)
                        {
                        }
                        column(TotalCaption_Control220; TotalCaption_Control220Lbl)
                        {
                        }
                        column(ContinuedCaption_Control223; ContinuedCaption_Control223Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if SalesLine2.Get("Document Type", "Document No.", "Document Line No.") then;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowCostAssignment then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(TempSalesLine);
                        Clear(SalesPost);
                        VATAmountLine.DeleteAll();
                        TempSalesLine.DeleteAll();
                        SalesPost.GetSalesLines("Sales Header", TempSalesLine, 1);
                        OnAfterSalesPostGetSalesLines("Sales Header", TempSalesLine);
                        TempSalesLine.CalcVATAmountLines(0, "Sales Header", TempSalesLine, VATAmountLine);
                        TempSalesLine.UpdateVATOnLines(0, "Sales Header", TempSalesLine, VATAmountLine);
                        VATAmount := VATAmountLine.GetTotalVATAmount;
                        VATBaseAmount := VATAmountLine.GetTotalVATBase;
                        VATDiscountAmount :=
                          VATAmountLine.GetTotalVATDiscount("Sales Header"."Currency Code", "Sales Header"."Prices Including VAT");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.SalesHeaderSellTo(SellToAddr, "Sales Header");
                FormatAddr.SalesHeaderBillTo(BillToAddr, "Sales Header");
                FormatAddr.SalesHeaderShipTo(ShipToAddr, ShipToAddr, "Sales Header");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text004, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text033, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text005, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text004, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text033, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text005, "Currency Code");
                end;

                Invoice := InvOnNextPostReq;
                Ship := ShipReceiveOnNextPostReq;
                Receive := ShipReceiveOnNextPostReq;

                VerifySellToCust("Sales Header");
                VerifyBillToCust("Sales Header");

                SalesSetup.Get();

                VerifyPostingDate("Sales Header");

                if "Document Date" <> 0D then
                    if "Document Date" <> NormalDate("Document Date") then
                        AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                case "Document Type" of
                    "Document Type"::Order:
                        Receive := false;
                    "Document Type"::Invoice:
                        begin
                            Ship := true;
                            Invoice := true;
                            Receive := false;
                        end;
                    "Document Type"::"Return Order":
                        Ship := false;
                    "Document Type"::"Credit Memo":
                        begin
                            Ship := false;
                            Invoice := true;
                            Receive := true;
                        end;
                end;

                if not (Ship or Invoice or Receive) then
                    AddError(
                      StrSubstNo(
                        Text034,
                        FieldCaption(Ship), FieldCaption(Invoice), FieldCaption(Receive)));

                if Invoice then begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter(Quantity, '<>0');
                    if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                        SalesLine.SetFilter("Qty. to Invoice", '<>0');
                    Invoice := SalesLine.Find('-');
                    if Invoice and (not Ship) and ("Document Type" = "Document Type"::Order) then begin
                        Invoice := false;
                        repeat
                            Invoice := (SalesLine."Quantity Shipped" - SalesLine."Quantity Invoiced") <> 0;
                        until Invoice or (SalesLine.Next = 0);
                    end else
                        if Invoice and (not Receive) and ("Document Type" = "Document Type"::"Return Order") then begin
                            Invoice := false;
                            repeat
                                Invoice := (SalesLine."Return Qty. Received" - SalesLine."Quantity Invoiced") <> 0;
                            until Invoice or (SalesLine.Next = 0);
                        end;
                end;

                if Ship then begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        SalesLine.SetFilter("Qty. to Ship", '<>0');
                    SalesLine.SetRange("Shipment No.", '');
                    Ship := SalesLine.Find('-');
                end;
                if Receive then begin
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::"Return Order" then
                        SalesLine.SetFilter("Return Qty. to Receive", '<>0');
                    SalesLine.SetRange("Return Receipt No.", '');
                    Receive := SalesLine.Find('-');
                end;

                if not (Ship or Invoice or Receive) then
                    AddError(Text012);

                if Invoice then
                    if not ("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]) then
                        if "Due Date" = 0D then
                            AddError(StrSubstNo(Text006, FieldCaption("Due Date")));

                if Ship and ("Shipping No." = '') then // Order,Invoice
                    if ("Document Type" = "Document Type"::Order) or
                       (("Document Type" = "Document Type"::Invoice) and SalesSetup."Shipment on Invoice")
                    then
                        if "Shipping No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Shipping No. Series")));

                if Receive and ("Return Receipt No." = '') then // Return Order,Credit Memo
                    if ("Document Type" = "Document Type"::"Return Order") or
                       (("Document Type" = "Document Type"::"Credit Memo") and SalesSetup."Return Receipt on Credit Memo")
                    then
                        if "Return Receipt No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Return Receipt No. Series")));

                if Invoice and ("Posting No." = '') then
                    if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                        if "Posting No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Posting No. Series")));

                SalesLine.Reset();
                SalesLine.SetRange("Document Type", "Document Type");
                SalesLine.SetRange("Document No.", "No.");
                SalesLine.SetFilter("Purch. Order Line No.", '<>0');
                if Ship then
                    if SalesLine.Find('-') then
                        repeat
                            if PurchOrderHeader."No." <> SalesLine."Purchase Order No." then begin
                                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, SalesLine."Purchase Order No.");
                                if PurchOrderHeader."Pay-to Vendor No." = '' then
                                    AddError(
                                      StrSubstNo(
                                        Text013,
                                        PurchOrderHeader.FieldCaption("Pay-to Vendor No.")));
                                if PurchOrderHeader."Receiving No." = '' then
                                    if PurchOrderHeader."Receiving No. Series" = '' then
                                        AddError(
                                          StrSubstNo(
                                            Text013,
                                            PurchOrderHeader.FieldCaption("Receiving No. Series")));
                            end;
                        until SalesLine.Next = 0;

                if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                    if SalesSetup."Ext. Doc. No. Mandatory" and ("External Document No." = '') then
                        AddError(StrSubstNo(Text006, FieldCaption("External Document No.")));

                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr);

                TableID[1] := DATABASE::Customer;
                No[1] := "Bill-to Customer No.";
                TableID[3] := DATABASE::"Salesperson/Purchaser";
                No[3] := "Salesperson Code";
                TableID[4] := DATABASE::Campaign;
                No[4] := "Campaign No.";
                TableID[5] := DATABASE::"Responsibility Center";
                No[5] := "Responsibility Center";
                OnBeforeCheckDimValuePostingHeader("Sales Header", TableID, No);
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr);

                OnAfterCheckSalesDoc("Sales Header", ErrorText, ErrorCounter);
            end;

            trigger OnPreDataItem()
            begin
                SalesHeader.Copy("Sales Header");
                SalesHeader.FilterGroup := 2;
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                if SalesHeader.FindFirst then begin
                    case true of
                        ShipReceiveOnNextPostReq and InvOnNextPostReq:
                            ShipInvText := Text000;
                        ShipReceiveOnNextPostReq:
                            ShipInvText := Text001;
                        InvOnNextPostReq:
                            ShipInvText := Text002;
                    end;
                    ShipInvText := StrSubstNo(Text003, ShipInvText);
                end;
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
                if SalesHeader.FindFirst then begin
                    case true of
                        ShipReceiveOnNextPostReq and InvOnNextPostReq:
                            ReceiveInvText := Text018;
                        ShipReceiveOnNextPostReq:
                            ReceiveInvText := Text031;
                        InvOnNextPostReq:
                            ReceiveInvText := Text002;
                    end;
                    ReceiveInvText := StrSubstNo(Text032, ReceiveInvText);
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
                    group("Order/Return Order Posting")
                    {
                        Caption = 'Order/Return Order Posting';
                        field(ShipReceiveOnNextPostReq; ShipReceiveOnNextPostReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ship/Receive';
                            ToolTip = 'Specifies whether you want to post the documents that are being tested as shipped/received, as invoiced or as shipped/received and invoiced. Select the check box next to each option that you want to select.';

                            trigger OnValidate()
                            begin
                                if not ShipReceiveOnNextPostReq then
                                    InvOnNextPostReq := true;
                            end;
                        }
                        field(InvOnNextPostReq; InvOnNextPostReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies invoices to test before you post them, to check whether there are any posting dates missing, etc.';

                            trigger OnValidate()
                            begin
                                if not InvOnNextPostReq then
                                    ShipReceiveOnNextPostReq := true;
                            end;
                        }
                    }
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines that you want to include in the report.';
                    }
                    field(ShowItemChargeAssignment; ShowCostAssignment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Item Charge Assgnt.';
                        ToolTip = 'Specifies if you want the test report to show the item charges that have been assigned to the sales document.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if not ShipReceiveOnNextPostReq and not InvOnNextPostReq then begin
                ShipReceiveOnNextPostReq := true;
                InvOnNextPostReq := true;
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPreReport()
    begin
        SalesHeaderFilter := "Sales Header".GetFilters;
    end;

    var
        Text000: Label 'Ship and Invoice';
        Text001: Label 'Ship';
        Text002: Label 'Invoice';
        Text003: Label 'Order Posting: %1';
        Text004: Label 'Total %1';
        Text005: Label 'Total %1 Incl. VAT';
        Text006: Label '%1 must be specified.';
        Text007: Label '%1 must be %2 for %3 %4.';
        Text008: Label '%1 %2 does not exist.';
        Text009: Label '%1 must not be a closing date.';
        Text010: Label '%1 is not within your allowed range of posting dates.';
        Text012: Label 'There is nothing to post.';
        Text013: Label '%1 must be entered on the purchase order header.';
        Text014: Label 'Sales Document: %1';
        Text015: Label '%1 must be %2.';
        Text016: Label '%1 %2 does not exist on customer entries.';
        Text017: Label '%1 %2 %3 does not exist.';
        Text018: Label 'Receive and Credit Memo';
        Text019: Label '%1 %2 must be specified.';
        Text020: Label '%1 must be 0 when %2 is 0.';
        Text021: Label 'Drop shipments are only possible for items.';
        Text022: Label 'You cannot ship sales order line %1 because the line is marked';
        Text023: Label 'as a drop shipment and is not yet associated with a purchase order.';
        Text024: Label 'The %1 on the shipment is not the same as the %1 on the sales header.';
        Text025: Label 'Line %1 of the return receipt %2, which you are attempting to invoice, has already been invoiced.';
        Text026: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text027: Label '%1 must have the same sign as the shipments.';
        Text031: Label 'Receive';
        Text032: Label 'Return Order Posting: %1';
        Text033: Label 'Total %1 Excl. VAT';
        Text034: Label 'Enter "Yes" in %1 and/or %2 and/or %3.';
        Text035: Label 'You must enter the customer''s %1.';
        Text036: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.';
        Text037: Label 'The quantity you are attempting to invoice is greater than the quantity in return receipt %1.';
        Text038: Label 'The %1 on the return receipt is not the same as the %1 on the sales header.';
        Text039: Label '%1 must have the same sign as the return receipt.';
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        SaleShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        PurchOrderHeader: Record "Purchase Header";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        InvtPeriod: Record "Inventory Period";
        FormatAddr: Codeunit "Format Address";
        DimMgt: Codeunit DimensionManagement;
        SalesPost: Codeunit "Sales-Post";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        SalesHeaderFilter: Text;
        SellToAddr: array[8] of Text[100];
        BillToAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        ShipInvText: Text[50];
        ReceiveInvText: Text[50];
        DimText: Text[120];
        OldDimText: Text[75];
        ErrorText: array[99] of Text[250];
        QtyToHandleCaption: Text[30];
        MaxQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoiced: Decimal;
        QtyToBeInvoiced: Decimal;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        QtyToHandle: Decimal;
        ErrorCounter: Integer;
        OrigMaxLineNo: Integer;
        InvOnNextPostReq: Boolean;
        ShipReceiveOnNextPostReq: Boolean;
        VATNoError: Boolean;
        ApplNoError: Boolean;
        ShowDim: Boolean;
        Continue: Boolean;
        ShowCostAssignment: Boolean;
        Text043: Label '%1 must be zero.';
        Text045: Label '%1 must not be %2 for %3 %4.';
        MoreLines: Boolean;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        Text046: Label '%1 must be completely preinvoiced before you can ship or invoice the line.';
        Text050: Label 'VAT Amount Specification in ';
        Text051: Label 'Local Currency';
        Text052: Label 'Exchange rate: %1/%2';
        Text053: Label '%1 can at most be %2.';
        Text054: Label '%1 must be at least %2.';
        SumLineAmount: Decimal;
        SumInvDiscountAmount: Decimal;
        Sales_Document___TestCaptionLbl: Label 'Sales Document - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Ship_toCaptionLbl: Label 'Ship-to';
        Sell_toCaptionLbl: Label 'Sell-to';
        Bill_toCaptionLbl: Label 'Bill-to';
        Sales_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Sales_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Sales_Header___Pmt__Discount_Date_CaptionLbl: Label 'Pmt. Discount Date';
        Sales_Header___Posting_Date__Control105CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date__Control106CaptionLbl: Label 'Document Date';
        Sales_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Sales_Header___Shipment_Date_CaptionLbl: Label 'Shipment Date';
        Sales_Header___Due_Date__Control19CaptionLbl: Label 'Due Date';
        Sales_Header___Pmt__Discount_Date__Control22CaptionLbl: Label 'Pmt. Discount Date';
        Sales_Header___Posting_Date__Control131CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date__Control132CaptionLbl: Label 'Document Date';
        Sales_Header___Posting_Date__Control137CaptionLbl: Label 'Posting Date';
        Sales_Header___Document_Date__Control138CaptionLbl: Label 'Document Date';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Sales_Line___Line_Discount___CaptionLbl: Label 'Line Disc. %';
        AmountCaptionLbl: Label 'Amount';
        TempSalesLine__Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        VATAmountLine__VAT_Amount__Control150CaptionLbl: Label 'VAT Amount';
        VATAmountLine__VAT_Base__Control151CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VATAmountLine__Invoice_Discount_Amount__Control173CaptionLbl: Label 'Invoice Discount Amount';
        VATAmountLine__Inv__Disc__Base_Amount__Control171CaptionLbl: Label 'Inv. Disc. Base Amount';
        VATAmountLine__Line_Amount__Control169CaptionLbl: Label 'Line Amount';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control155Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';
        VALVATAmountLCY_Control88CaptionLbl: Label 'VAT Amount';
        VALVATBaseLCY_Control165CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT____Control167CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Identifier__Control241CaptionLbl: Label 'VAT Identifier';
        ContinuedCaption_Control87Lbl: Label 'Continued';
        ContinuedCaption_Control244Lbl: Label 'Continued';
        TotalCaption_Control247Lbl: Label 'Total';
        Item_Charge_SpecificationCaptionLbl: Label 'Item Charge Specification';
        SalesLine2_DescriptionCaptionLbl: Label 'Description';
        SalesLine2_QuantityCaptionLbl: Label 'Assignable Qty';
        ContinuedCaption_Control210Lbl: Label 'Continued';
        TotalCaption_Control220Lbl: Label 'Total';
        ContinuedCaption_Control223Lbl: Label 'Continued';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CheckShptLines(SalesLine2: Record "Sales Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        with SalesLine2 do begin
            if Abs(RemQtyToBeInvoiced) > Abs("Qty. to Ship") then begin
                SaleShptLine.Reset();
                case "Document Type" of
                    "Document Type"::Order:
                        begin
                            SaleShptLine.SetCurrentKey("Order No.", "Order Line No.");
                            SaleShptLine.SetRange("Order No.", "Document No.");
                            SaleShptLine.SetRange("Order Line No.", "Line No.");
                        end;
                    "Document Type"::Invoice:
                        begin
                            SaleShptLine.SetRange("Document No.", "Shipment No.");
                            SaleShptLine.SetRange("Line No.", "Shipment Line No.");
                        end;
                end;

                SaleShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                if SaleShptLine.Find('-') then
                    repeat
                        DimMgt.GetDimensionSet(TempPostedDimSetEntry, SaleShptLine."Dimension Set ID");
                        if not DimMgt.CheckDimIDConsistency(
                             TempDimSetEntry, TempPostedDimSetEntry, DATABASE::"Sales Line", DATABASE::"Sales Shipment Line")
                        then
                            AddError(DimMgt.GetDocDimConsistencyErr);
                        if SaleShptLine."Sell-to Customer No." <> "Sell-to Customer No." then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Sell-to Customer No.")));
                        if SaleShptLine.Type <> Type then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption(Type)));
                        if SaleShptLine."No." <> "No." then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("No.")));
                        if SaleShptLine."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Gen. Bus. Posting Group")));
                        if SaleShptLine."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Gen. Prod. Posting Group")));
                        if SaleShptLine."Location Code" <> "Location Code" then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Location Code")));
                        if SaleShptLine."Job No." <> "Job No." then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Job No.")));

                        if -SalesLine."Qty. to Invoice" * SaleShptLine.Quantity < 0 then
                            AddError(
                              StrSubstNo(
                                Text027, FieldCaption("Qty. to Invoice")));

                        QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Qty. to Ship";
                        if Abs(QtyToBeInvoiced) > Abs(SaleShptLine.Quantity - SaleShptLine."Quantity Invoiced") then
                            QtyToBeInvoiced := -(SaleShptLine.Quantity - SaleShptLine."Quantity Invoiced");
                        RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                        SaleShptLine."Quantity Invoiced" := SaleShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                        SaleShptLine."Qty. Shipped Not Invoiced" :=
                          SaleShptLine.Quantity - SaleShptLine."Quantity Invoiced"
                    until (SaleShptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs("Qty. to Ship"))
                else
                    AddError(
                      StrSubstNo(
                        Text026,
                        "Shipment Line No.",
                        "Shipment No."));
            end;

            if Abs(RemQtyToBeInvoiced) > Abs("Qty. to Ship") then
                if "Document Type" = "Document Type"::Invoice then
                    AddError(
                      StrSubstNo(
                        Text036,
                        "Shipment No."));
        end;
    end;

    local procedure CheckRcptLines(SalesLine2: Record "Sales Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        with SalesLine2 do begin
            if Abs(RemQtyToBeInvoiced) > Abs("Return Qty. to Receive") then begin
                ReturnRcptLine.Reset();
                case "Document Type" of
                    "Document Type"::"Return Order":
                        begin
                            ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                            ReturnRcptLine.SetRange("Return Order No.", "Document No.");
                            ReturnRcptLine.SetRange("Return Order Line No.", "Line No.");
                        end;
                    "Document Type"::"Credit Memo":
                        begin
                            ReturnRcptLine.SetRange("Document No.", "Return Receipt No.");
                            ReturnRcptLine.SetRange("Line No.", "Return Receipt Line No.");
                        end;
                end;

                ReturnRcptLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');
                if ReturnRcptLine.Find('-') then
                    repeat
                        DimMgt.GetDimensionSet(TempPostedDimSetEntry, ReturnRcptLine."Dimension Set ID");
                        if not DimMgt.CheckDimIDConsistency(
                             TempDimSetEntry, TempPostedDimSetEntry, DATABASE::"Sales Line", DATABASE::"Return Receipt Line")
                        then
                            AddError(DimMgt.GetDocDimConsistencyErr);
                        if ReturnRcptLine."Sell-to Customer No." <> "Sell-to Customer No." then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption("Sell-to Customer No.")));
                        if ReturnRcptLine.Type <> Type then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption(Type)));
                        if ReturnRcptLine."No." <> "No." then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption("No.")));
                        if ReturnRcptLine."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption("Gen. Bus. Posting Group")));
                        if ReturnRcptLine."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption("Gen. Prod. Posting Group")));
                        if ReturnRcptLine."Location Code" <> "Location Code" then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption("Location Code")));
                        if ReturnRcptLine."Job No." <> "Job No." then
                            AddError(
                              StrSubstNo(
                                Text038,
                                FieldCaption("Job No.")));

                        if SalesLine."Qty. to Invoice" * ReturnRcptLine.Quantity < 0 then
                            AddError(
                              StrSubstNo(
                                Text039, FieldCaption("Qty. to Invoice")));
                        QtyToBeInvoiced := RemQtyToBeInvoiced - SalesLine."Return Qty. to Receive";
                        if Abs(QtyToBeInvoiced) > Abs(ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced") then
                            QtyToBeInvoiced := ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                        RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                        ReturnRcptLine."Quantity Invoiced" := ReturnRcptLine."Quantity Invoiced" + QtyToBeInvoiced;
                        ReturnRcptLine."Return Qty. Rcd. Not Invd." :=
                          ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced";
                    until (ReturnRcptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs("Return Qty. to Receive"))
                else
                    AddError(
                      StrSubstNo(
                        Text025,
                        "Return Receipt Line No.",
                        "Return Receipt No."));
            end;

            if Abs(RemQtyToBeInvoiced) > Abs("Return Qty. to Receive") then
                if "Document Type" = "Document Type"::"Credit Memo" then
                    AddError(
                      StrSubstNo(
                        Text037,
                        "Return Receipt No."));
        end;
    end;

    local procedure IsInvtPosting(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        with "Sales Header" do begin
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            SalesLine.SetFilter(Type, '%1|%2', SalesLine.Type::Item, SalesLine.Type::"Charge (Item)");
            if SalesLine.IsEmpty then
                exit(false);
            if Ship then begin
                SalesLine.SetFilter("Qty. to Ship", '<>%1', 0);
                if not SalesLine.IsEmpty then
                    exit(true);
            end;
            if Receive then begin
                SalesLine.SetFilter("Return Qty. to Receive", '<>%1', 0);
                if not SalesLine.IsEmpty then
                    exit(true);
            end;
            if Invoice then begin
                SalesLine.SetFilter("Qty. to Invoice", '<>%1', 0);
                if not SalesLine.IsEmpty then
                    exit(true);
            end;
        end;
    end;

    procedure AddDimToTempLine(SalesLine: Record "Sales Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();

        with SalesLine do begin
            TableID[1] := DimMgt.TypeToTableID3(Type);
            No[1] := "No.";
            TableID[2] := DATABASE::Job;
            No[2] := "Job No.";
            TableID[3] := DATABASE::"Responsibility Center";
            No[3] := "Responsibility Center";

            OnAfterCreateDimTableIDs(SalesLine, TableID, No);

            "Shortcut Dimension 1 Code" := '';
            "Shortcut Dimension 2 Code" := '';
            "Dimension Set ID" :=
              DimMgt.GetDefaultDimID(TableID, No, SourceCodeSetup.Sales, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
                "Dimension Set ID", DATABASE::Customer);
        end;
    end;

    procedure InitializeRequest(NewShipReceiveOnNextPostReq: Boolean; NewInvOnNextPostReq: Boolean; NewShowDim: Boolean; NewShowCostAssignment: Boolean)
    begin
        ShipReceiveOnNextPostReq := NewShipReceiveOnNextPostReq;
        InvOnNextPostReq := NewInvOnNextPostReq;
        ShowDim := NewShowDim;
        ShowCostAssignment := NewShowCostAssignment;
    end;

    local procedure CheckSalesLine(SalesLine2: Record "Sales Line")
    var
        ErrorText: Text[250];
    begin
        with SalesLine2 do
            case Type of
                Type::"G/L Account":
                    begin
                        if ("No." = '') and (Amount = 0) then
                            exit;

                        if "No." <> '' then
                            if GLAcc.Get("No.") then begin
                                if GLAcc.Blocked then
                                    AddError(
                                      StrSubstNo(
                                        Text007,
                                        GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption, "No."));
                                if not GLAcc."Direct Posting" and ("Line No." <= OrigMaxLineNo) then
                                    AddError(
                                      StrSubstNo(
                                        Text007,
                                        GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption, "No."));
                            end else
                                AddError(
                                  StrSubstNo(
                                    Text008,
                                    GLAcc.TableCaption, "No."));
                    end;
                Type::Item:
                    begin
                        if ("No." = '') and (Quantity = 0) then
                            exit;

                        if "No." <> '' then
                            if Item.Get("No.") then begin
                                if Item.Blocked then
                                    AddError(
                                      StrSubstNo(
                                        Text007,
                                        Item.FieldCaption(Blocked), false, Item.TableCaption, "No."));
                                if Item.Reserve = Item.Reserve::Always then begin
                                    CalcFields("Reserved Quantity");
                                    if "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"] then begin
                                        if (SignedXX(Quantity) < 0) and (Abs("Reserved Quantity") < Abs("Return Qty. to Receive")) then
                                            AddError(
                                              StrSubstNo(
                                                Text015,
                                                FieldCaption("Reserved Quantity"), SignedXX("Return Qty. to Receive")));
                                    end else
                                        if (SignedXX(Quantity) < 0) and (Abs("Reserved Quantity") < Abs("Qty. to Ship")) then
                                            AddError(
                                              StrSubstNo(
                                                Text015,
                                                FieldCaption("Reserved Quantity"), SignedXX("Qty. to Ship")));
                                end
                            end else
                                AddError(
                                  StrSubstNo(
                                    Text008,
                                    Item.TableCaption, "No."));
                    end;
                Type::Resource:
                    begin
                        if ("No." = '') and (Quantity = 0) then
                            exit;

                        if Res.Get("No.") then begin
                            if Res."Privacy Blocked" then
                                AddError(
                                  StrSubstNo(
                                    Text007,
                                    Res.FieldCaption("Privacy Blocked"), false, Res.TableCaption, "No."));
                            if Res.Blocked then
                                AddError(
                                  StrSubstNo(
                                    Text007,
                                    Res.FieldCaption(Blocked), false, Res.TableCaption, "No."));
                        end else
                            AddError(
                              StrSubstNo(
                                Text008,
                                Res.TableCaption, "No."));
                    end;
                Type::"Fixed Asset":
                    begin
                        if ("No." = '') and (Quantity = 0) then
                            exit;
                        if "No." <> '' then
                            if FA.Get("No.") then begin
                                if FA.Blocked then
                                    AddError(
                                      StrSubstNo(
                                        Text007,
                                        FA.FieldCaption(Blocked), false, FA.TableCaption, "No."));
                                if FA.Inactive then
                                    AddError(
                                      StrSubstNo(
                                        Text007,
                                        FA.FieldCaption(Inactive), false, FA.TableCaption, "No."));
                                if "Depreciation Book Code" = '' then
                                    AddError(StrSubstNo(Text006, FieldCaption("Depreciation Book Code")))
                                else
                                    if not FADeprBook.Get("No.", "Depreciation Book Code") then
                                        AddError(
                                          StrSubstNo(
                                            Text017,
                                            FADeprBook.TableCaption, "No.", "Depreciation Book Code"));
                            end else
                                AddError(
                                  StrSubstNo(
                                    Text008,
                                    FA.TableCaption, "No."));
                    end;
                else begin
                        OnCheckSalesLineCaseTypeElse(Type, "No.", ErrorText);
                        if ErrorText <> '' then
                            AddError(ErrorText);
                    end;
            end;
    end;

    local procedure VerifySellToCust(SalesHeader: Record "Sales Header")
    var
        ShipQtyExist: Boolean;
    begin
        with SalesHeader do begin
            if "Sell-to Customer No." = '' then
                AddError(StrSubstNo(Text006, FieldCaption("Sell-to Customer No.")))
            else
                if Cust.Get("Sell-to Customer No.") then begin
                    if (Cust.Blocked = Cust.Blocked::Ship) and Ship then begin
                        SalesLine2.SetRange("Document Type", "Document Type");
                        SalesLine2.SetRange("Document No.", "No.");
                        SalesLine2.SetFilter("Qty. to Ship", '>0');
                        if SalesLine2.FindFirst then
                            ShipQtyExist := true;
                    end;
                    if Cust."Privacy Blocked" then
                        AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                    if (Cust.Blocked = Cust.Blocked::All) or
                       ((Cust.Blocked = Cust.Blocked::Invoice) and
                        (not ("Document Type" in
                              ["Document Type"::"Credit Memo", "Document Type"::"Return Order"]))) or
                       ShipQtyExist
                    then
                        AddError(
                          StrSubstNo(
                            Text045,
                            Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption, "Sell-to Customer No."))
                end else
                    AddError(
                      StrSubstNo(
                        Text008,
                        Cust.TableCaption, "Sell-to Customer No."));
        end;
    end;

    local procedure VerifyBillToCust(SalesHeader: Record "Sales Header")
    begin
        with SalesHeader do
            if "Bill-to Customer No." = '' then
                AddError(StrSubstNo(Text006, FieldCaption("Bill-to Customer No.")))
            else begin
                if "Bill-to Customer No." <> "Sell-to Customer No." then
                    if Cust.Get("Bill-to Customer No.") then begin
                        if Cust."Privacy Blocked" then
                            AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                        if (Cust.Blocked = Cust.Blocked::All) or
                           ((Cust.Blocked = Cust.Blocked::Invoice) and
                            ("Document Type" in
                             ["Document Type"::"Credit Memo", "Document Type"::"Return Order"]))
                        then
                            AddError(
                              StrSubstNo(
                                Text045,
                                Cust.FieldCaption(Blocked), false, Cust.TableCaption, "Bill-to Customer No."));
                    end else
                        AddError(
                          StrSubstNo(
                            Text008,
                            Cust.TableCaption, "Bill-to Customer No."));
            end;
    end;

    local procedure VerifyPostingDate(SalesHeader: Record "Sales Header")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        InvtPeriodEndDate: Date;
        TempErrorText: Text[250];
    begin
        with SalesHeader do
            if "Posting Date" = 0D then
                AddError(StrSubstNo(Text006, FieldCaption("Posting Date")))
            else
                if "Posting Date" <> NormalDate("Posting Date") then
                    AddError(StrSubstNo(Text009, FieldCaption("Posting Date")))
                else begin
                    if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                        AddError(TempErrorText);
                    if IsInvtPosting then begin
                        InvtPeriodEndDate := "Posting Date";
                        if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                            AddError(
                              StrSubstNo(Text010, Format("Posting Date")))
                    end;
                end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesDoc(SalesHeader: Record "Sales Header"; var ErrorText: array[99] of Text[250]; var ErrorCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesPostGetSalesLines(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var SalesLine: Record "Sales Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePostingHeader(var SalesHeader: Record "Sales Header"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePostingLine(var SalesLine: Record "Sales Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesLineCaseTypeElse(LineType: Option; "No.": Code[20]; var ErrorText: Text[250])
    begin
    end;
}

