report 5915 "Service Document - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ServiceDocumentTest.rdlc';
    Caption = 'Service Document - Test';

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = WHERE("Document Type" = FILTER(<> Quote));
            RequestFilterFields = "Document Type", "No.";
            RequestFilterHeading = 'Service Document';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Service_Document___TestCaption; Service_Document___TestCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(STRSUBSTNO_Text014_ServiceHeaderFilter_; StrSubstNo(Text014, ServiceHeaderFilter))
                {
                }
                column(ShowServiceHeaderFilter; ServiceHeaderFilter)
                {
                }
                column(ShipInvText; ShipInvText)
                {
                }
                column(ReceiveInvText; ReceiveInvText)
                {
                }
                column(Service_Header___Customer_No__; "Service Header"."Customer No.")
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
                column(Service_Header___Ship_to_Code_; "Service Header"."Ship-to Code")
                {
                }
                column(FORMAT__Service_Header___Document_Type____________Service_Header___No__; Format("Service Header"."Document Type") + ' ' + "Service Header"."No.")
                {
                }
                column(FORMAT__Service_Header___Prices_Including_VAT__; Format("Service Header"."Prices Including VAT"))
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
                column(Service_Header___Bill_to_Customer_No__; "Service Header"."Bill-to Customer No.")
                {
                }
                column(ShowBillAddrInfo; "Service Header"."Bill-to Customer No." <> "Service Header"."Customer No.")
                {
                }
                column(Service_Header___Salesperson_Code_; "Service Header"."Salesperson Code")
                {
                }
                column(Service_Header___Your_Reference_; "Service Header"."Your Reference")
                {
                }
                column(Service_Header___Customer_Posting_Group_; "Service Header"."Customer Posting Group")
                {
                }
                column(Service_Header___Posting_Date_; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date_; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT_; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowQuote; "Service Header"."Document Type" = "Service Header"."Document Type"::Quote)
                {
                }
                column(Service_Header___Payment_Terms_Code_; "Service Header"."Payment Terms Code")
                {
                }
                column(Service_Header___Payment_Discount___; "Service Header"."Payment Discount %")
                {
                }
                column(Service_Header___Due_Date_; Format("Service Header"."Due Date"))
                {
                }
                column(Service_Header___Customer_Disc__Group_; "Service Header"."Customer Disc. Group")
                {
                }
                column(Service_Header___Pmt__Discount_Date_; Format("Service Header"."Pmt. Discount Date"))
                {
                }
                column(Service_Header___Invoice_Disc__Code_; "Service Header"."Invoice Disc. Code")
                {
                }
                column(Service_Header___Payment_Method_Code_; "Service Header"."Payment Method Code")
                {
                }
                column(Service_Header___Posting_Date__Control105; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date__Control106; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Order_Date_; Format("Service Header"."Order Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT__Control194; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowOrder; "Service Header"."Document Type" = "Service Header"."Document Type"::Order)
                {
                }
                column(Service_Header___Payment_Terms_Code__Control18; "Service Header"."Payment Terms Code")
                {
                }
                column(Service_Header___Due_Date__Control19; Format("Service Header"."Due Date"))
                {
                }
                column(Service_Header___Pmt__Discount_Date__Control22; Format("Service Header"."Pmt. Discount Date"))
                {
                }
                column(Service_Header___Payment_Discount____Control23; "Service Header"."Payment Discount %")
                {
                }
                column(Service_Header___Payment_Method_Code__Control26; "Service Header"."Payment Method Code")
                {
                }
                column(Service_Header___Customer_Disc__Group__Control100; "Service Header"."Customer Disc. Group")
                {
                }
                column(Service_Header___Invoice_Disc__Code__Control102; "Service Header"."Invoice Disc. Code")
                {
                }
                column(Service_Header___Customer_Posting_Group__Control130; "Service Header"."Customer Posting Group")
                {
                }
                column(Service_Header___Posting_Date__Control131; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date__Control132; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT__Control196; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowInvoice; "Service Header"."Document Type" = "Service Header"."Document Type"::Invoice)
                {
                }
                column(Service_Header___Applies_to_Doc__Type_; "Service Header"."Applies-to Doc. Type")
                {
                }
                column(Service_Header___Applies_to_Doc__No__; "Service Header"."Applies-to Doc. No.")
                {
                }
                column(Service_Header___Customer_Posting_Group__Control136; "Service Header"."Customer Posting Group")
                {
                }
                column(Service_Header___Posting_Date__Control137; Format("Service Header"."Posting Date"))
                {
                }
                column(Service_Header___Document_Date__Control138; Format("Service Header"."Document Date"))
                {
                }
                column(Service_Header___Prices_Including_VAT__Control198; "Service Header"."Prices Including VAT")
                {
                }
                column(ShowCreditMemo; "Service Header"."Document Type" = "Service Header"."Document Type"::"Credit Memo")
                {
                }
                column(Service_Header___Customer_No__Caption; "Service Header".FieldCaption("Customer No."))
                {
                }
                column(Ship_toCaption; Ship_toCaptionLbl)
                {
                }
                column(CustomerCaption; CustomerCaptionLbl)
                {
                }
                column(Service_Header___Ship_to_Code_Caption; "Service Header".FieldCaption("Ship-to Code"))
                {
                }
                column(Bill_toCaption; Bill_toCaptionLbl)
                {
                }
                column(Service_Header___Bill_to_Customer_No__Caption; "Service Header".FieldCaption("Bill-to Customer No."))
                {
                }
                column(Service_Header___Salesperson_Code_Caption; "Service Header".FieldCaption("Salesperson Code"))
                {
                }
                column(Service_Header___Your_Reference_Caption; "Service Header".FieldCaption("Your Reference"))
                {
                }
                column(Service_Header___Customer_Posting_Group_Caption; "Service Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Service_Header___Posting_Date_Caption; Service_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Service_Header___Document_Date_Caption; Service_Header___Document_Date_CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT_Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Service_Header___Payment_Terms_Code_Caption; "Service Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Service_Header___Payment_Discount___Caption; "Service Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Service_Header___Due_Date_Caption; Service_Header___Due_Date_CaptionLbl)
                {
                }
                column(Service_Header___Customer_Disc__Group_Caption; "Service Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Service_Header___Pmt__Discount_Date_Caption; Service_Header___Pmt__Discount_Date_CaptionLbl)
                {
                }
                column(Service_Header___Invoice_Disc__Code_Caption; "Service Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Service_Header___Payment_Method_Code_Caption; "Service Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Service_Header___Posting_Date__Control105Caption; Service_Header___Posting_Date__Control105CaptionLbl)
                {
                }
                column(Service_Header___Document_Date__Control106Caption; Service_Header___Document_Date__Control106CaptionLbl)
                {
                }
                column(Service_Header___Order_Date_Caption; Service_Header___Order_Date_CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT__Control194Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Service_Header___Payment_Terms_Code__Control18Caption; "Service Header".FieldCaption("Payment Terms Code"))
                {
                }
                column(Service_Header___Payment_Discount____Control23Caption; "Service Header".FieldCaption("Payment Discount %"))
                {
                }
                column(Service_Header___Due_Date__Control19Caption; Service_Header___Due_Date__Control19CaptionLbl)
                {
                }
                column(Service_Header___Pmt__Discount_Date__Control22Caption; Service_Header___Pmt__Discount_Date__Control22CaptionLbl)
                {
                }
                column(Service_Header___Payment_Method_Code__Control26Caption; "Service Header".FieldCaption("Payment Method Code"))
                {
                }
                column(Service_Header___Customer_Disc__Group__Control100Caption; "Service Header".FieldCaption("Customer Disc. Group"))
                {
                }
                column(Service_Header___Invoice_Disc__Code__Control102Caption; "Service Header".FieldCaption("Invoice Disc. Code"))
                {
                }
                column(Service_Header___Customer_Posting_Group__Control130Caption; "Service Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Service_Header___Posting_Date__Control131Caption; Service_Header___Posting_Date__Control131CaptionLbl)
                {
                }
                column(Service_Header___Document_Date__Control132Caption; Service_Header___Document_Date__Control132CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT__Control196Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(Service_Header___Applies_to_Doc__Type_Caption; "Service Header".FieldCaption("Applies-to Doc. Type"))
                {
                }
                column(Service_Header___Applies_to_Doc__No__Caption; "Service Header".FieldCaption("Applies-to Doc. No."))
                {
                }
                column(Service_Header___Customer_Posting_Group__Control136Caption; "Service Header".FieldCaption("Customer Posting Group"))
                {
                }
                column(Service_Header___Posting_Date__Control137Caption; Service_Header___Posting_Date__Control137CaptionLbl)
                {
                }
                column(Service_Header___Document_Date__Control138Caption; Service_Header___Document_Date__Control138CaptionLbl)
                {
                }
                column(Service_Header___Prices_Including_VAT__Control198Caption; "Service Header".FieldCaption("Prices Including VAT"))
                {
                }
                column(SellToAddr_1_; SellToAddr[1])
                {
                }
                column(SellToAddr_2_; SellToAddr[2])
                {
                }
                column(SellToAddr_3_; SellToAddr[3])
                {
                }
                column(SellToAddr_4_; SellToAddr[4])
                {
                }
                column(SellToAddr_5_; SellToAddr[5])
                {
                }
                column(SellToAddr_6_; SellToAddr[6])
                {
                }
                column(SellToAddr_7_; SellToAddr[7])
                {
                }
                column(SellToAddr_8_; SellToAddr[8])
                {
                }
                dataitem(DimensionLoop1; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(DimText; DimText)
                    {
                    }
                    column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DimText := DimTxtArr[Number];
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        FindDimTxt("Service Header"."Dimension Set ID");
                        SetRange(Number, 1, DimTxtArrLength);
                    end;
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrorText_Number_; ErrorText[Number])
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
                    dataitem("Service Line"; "Service Line")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");

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
                        column(Service_Line__Type; "Service Line".Type)
                        {
                        }
                        column(Service_Line___No__; "Service Line"."No.")
                        {
                        }
                        column(Service_Line__Description; "Service Line".Description)
                        {
                        }
                        column(Service_Line__Quantity; "Service Line".Quantity)
                        {
                        }
                        column(QtyToHandle; QtyToHandle)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Service_Line___Qty__to_Invoice_; "Service Line"."Qty. to Invoice")
                        {
                        }
                        column(Service_Line___Unit_Price_; "Service Line"."Unit Price")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Service_Line___Line_Discount___; "Service Line"."Line Discount %")
                        {
                        }
                        column(Service_Line___Line_Amount_; "Service Line"."Line Amount")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Service_Line___Allow_Invoice_Disc__; "Service Line"."Allow Invoice Disc.")
                        {
                        }
                        column(Service_Line___VAT_Identifier_; "Service Line"."VAT Identifier")
                        {
                        }
                        column(FORMAT__Service_Line___Allow_Invoice_Disc___; Format("Service Line"."Allow Invoice Disc."))
                        {
                        }
                        column(ServiceLineLineNo; ServiceLine."Line No.")
                        {
                        }
                        column(SumLineAmount; SumLineAmount)
                        {
                        }
                        column(SumInvDiscountAmount; SumInvDiscountAmount)
                        {
                        }
                        column(TempServiceLine__Inv__Discount_Amount_; -TempServiceLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempServiceLine__Line_Amount_; TempServiceLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TempServiceLine__Line_Amount_____Service_Line___Inv__Discount_Amount_; TempServiceLine."Line Amount" - TempServiceLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ShowRoundLoop5; VATAmount = 0)
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATAmountLine_VATAmountText; VATAmountLine.VATAmountText)
                        {
                        }
                        column(TempServiceLine__Line_Amount____TempServiceLine__Inv__Discount_Amount_; TempServiceLine."Line Amount" - TempServiceLine."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TempServiceLine__Line_Amount____TempServiceLine__Inv__Discount_Amount____VATAmount; TempServiceLine."Line Amount" - TempServiceLine."Inv. Discount Amount" + VATAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(ShowRoundLoop6; not "Service Header"."Prices Including VAT" and (VATAmount <> 0))
                        {
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ShowRoundLoop7; "Service Header"."Prices Including VAT" and (VATAmount <> 0) and ("Service Header"."VAT Base Discount %" <> 0))
                        {
                        }
                        column(VATBaseAmount___VATAmount; VATBaseAmount + VATAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(ShowRoundLoop8; "Service Header"."Prices Including VAT" and (VATAmount <> 0))
                        {
                        }
                        column(Service_Line___No__Caption; "Service Line".FieldCaption("No."))
                        {
                        }
                        column(Service_Line__DescriptionCaption; "Service Line".FieldCaption(Description))
                        {
                        }
                        column(Service_Line___Qty__to_Invoice_Caption; "Service Line".FieldCaption("Qty. to Invoice"))
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Service_Line___Line_Discount___Caption; Service_Line___Line_Discount___CaptionLbl)
                        {
                        }
                        column(Service_Line___Allow_Invoice_Disc__Caption; "Service Line".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(Service_Line___VAT_Identifier_Caption; "Service Line".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Service_Line__TypeCaption; "Service Line".FieldCaption(Type))
                        {
                        }
                        column(Service_Line__QuantityCaption; Service_Line__QuantityCaptionLbl)
                        {
                        }
                        column(QtyToHandleCaption; QtyToHandleCaptionLbl)
                        {
                        }
                        column(TempServiceLine__Inv__Discount_Amount_Caption; TempServiceLine__Inv__Discount_Amount_CaptionLbl)
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
                            DataItemTableView = SORTING(Number);
                            column(DimText_Control159; DimText)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := DimTxtArr[Number];
                            end;

                            trigger OnPostDataItem()
                            begin
                                SumLineAmount := SumLineAmount + TempServiceLine."Line Amount";
                                SumInvDiscountAmount := SumInvDiscountAmount + TempServiceLine."Inv. Discount Amount";
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowDim then
                                    CurrReport.Break();
                                FindDimTxt("Service Line"."Dimension Set ID");
                                SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }
                        dataitem(LineErrorCounter; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            column(ErrorText_Number__Control97; ErrorText[Number])
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
                            ServCost: Record "Service Cost";
                            TableID: array[10] of Integer;
                            No: array[10] of Code[20];
                        begin
                            if Number = 1 then
                                TempServiceLine.Find('-')
                            else
                                TempServiceLine.Next;
                            "Service Line" := TempServiceLine;

                            with "Service Line" do begin
                                if not "Service Header"."Prices Including VAT" and
                                   ("VAT Calculation Type" = "VAT Calculation Type"::"Full VAT")
                                then
                                    TempServiceLine."Line Amount" := 0;

                                TempDimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                                if "Document Type" = "Document Type"::"Credit Memo" then begin
                                    if "Document Type" = "Document Type"::"Credit Memo" then
                                        if "Qty. to Invoice" <> Quantity then
                                            AddError(StrSubstNo(Text015, FieldCaption("Qty. to Invoice"), Quantity));
                                    if "Qty. to Ship" <> 0 then
                                        AddError(StrSubstNo(Text043, FieldCaption("Qty. to Ship")));
                                end else
                                    if "Document Type" = "Document Type"::Invoice then begin
                                        if ("Qty. to Ship" <> Quantity) and ("Shipment No." = '') then
                                            AddError(StrSubstNo(Text015, FieldCaption("Qty. to Ship"), Quantity));
                                        if "Qty. to Invoice" <> Quantity then
                                            AddError(StrSubstNo(Text015, FieldCaption("Qty. to Invoice"), Quantity));
                                    end;

                                if not Ship then
                                    "Qty. to Ship" := 0;

                                if ("Document Type" = "Document Type"::Invoice) and ("Shipment No." <> '') then begin
                                    "Quantity Shipped" := Quantity;
                                    "Qty. to Ship" := 0;
                                end;

                                if Invoice then begin
                                    if "Document Type" = "Document Type"::"Credit Memo" then
                                        MaxQtyToBeInvoiced := Quantity
                                    else
                                        MaxQtyToBeInvoiced := "Qty. to Ship" + "Quantity Shipped" - "Quantity Invoiced";
                                    if Abs("Qty. to Invoice") > Abs(MaxQtyToBeInvoiced) then
                                        "Qty. to Invoice" := MaxQtyToBeInvoiced;
                                end else
                                    "Qty. to Invoice" := 0;

                                if "Gen. Prod. Posting Group" <> '' then begin
                                    if ("Service Header"."Document Type" = "Service Header"."Document Type"::"Credit Memo") and
                                       ("Service Header"."Applies-to Doc. Type" = "Service Header"."Applies-to Doc. Type"::Invoice) and
                                       ("Service Header"."Applies-to Doc. No." <> '')
                                    then begin
                                        CustLedgEntry.SetCurrentKey("Document No.");
                                        CustLedgEntry.SetRange("Customer No.", "Service Header"."Bill-to Customer No.");
                                        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                                        CustLedgEntry.SetRange("Document No.", "Service Header"."Applies-to Doc. No.");
                                        if not CustLedgEntry.FindLast and not ApplNoError then begin
                                            ApplNoError := true;
                                            AddError(
                                              StrSubstNo(
                                                Text016,
                                                "Service Header".FieldCaption("Applies-to Doc. No."), "Service Header"."Applies-to Doc. No."));
                                        end;
                                    end;

                                    if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                                        AddError(
                                          StrSubstNo(
                                            Text017,
                                            VATPostingSetup.TableCaption, "VAT Bus. Posting Group", "VAT Prod. Posting Group"));
                                    if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                        if ("Service Header"."VAT Registration No." = '') and not VATNoError then begin
                                            VATNoError := true;
                                            AddError(
                                              StrSubstNo(
                                                Text035, "Service Header".FieldCaption("VAT Registration No.")));
                                        end;
                                end;

                                CheckQuantity("Service Line");

                                ServiceLine := "Service Line";
                                if not ("Document Type" = "Document Type"::"Credit Memo") then begin
                                    ServiceLine."Qty. to Ship" := -ServiceLine."Qty. to Ship";
                                    ServiceLine."Qty. to Invoice" := -ServiceLine."Qty. to Invoice";
                                end;

                                RemQtyToBeInvoiced := ServiceLine."Qty. to Invoice";

                                case "Document Type" of
                                    "Document Type"::Order, "Document Type"::Invoice:
                                        CheckShptLines("Service Line");
                                end;

                                if (Type.AsInteger() >= Type::"G/L Account".AsInteger()) and ("Qty. to Invoice" <> 0) then begin
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

                                CheckType("Service Line");

                                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                    AddError(DimMgt.GetDimCombErr);

                                if Type = Type::Cost then begin
                                    TableID[1] := DATABASE::"G/L Account";
                                    if ServCost.Get("No.") then
                                        No[1] := ServCost."Account No.";
                                end else begin
                                    TableID[1] := DimMgt.TypeToTableID5(Type.AsInteger());
                                    No[1] := "No.";
                                end;
                                TableID[2] := DATABASE::Job;
                                No[2] := "Job No.";
                                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                                    AddError(DimMgt.GetDimValuePostingErr);
                                if "Line No." > OrigMaxLineNo then begin
                                    "No." := '';
                                    Type := Type::" ";
                                end;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATNoError := false;
                            ApplNoError := false;

                            MoreLines := TempServiceLine.Find('+');
                            while MoreLines and (TempServiceLine.Description = '') and (TempServiceLine."Description 2" = '') and
                                  (TempServiceLine."No." = '') and (TempServiceLine.Quantity = 0) and
                                  (TempServiceLine.Amount = 0)
                            do
                                MoreLines := TempServiceLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempServiceLine.SetRange("Line No.", 0, TempServiceLine."Line No.");
                            SetRange(Number, 1, TempServiceLine.Count);

                            SumLineAmount := 0;
                            SumInvDiscountAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(VATAmountLine__VAT_Amount_; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base_; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control150; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control151; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
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
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control171; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control169; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control181; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control182; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Line"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control183; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control184; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Header"."Currency Code";
                            AutoFormatType = 1;
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
                        column(TotalCaption; TotalCaptionLbl)
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

                    trigger OnAfterGetRecord()
                    begin
                        Clear(TempServiceLine);
                        Clear(ServAmountsMgt);
                        VATAmountLine.DeleteAll();
                        TempServiceLine.DeleteAll();

                        ServAmountsMgt.GetServiceLines("Service Header", TempServiceLine, 1);

                        // Ship prm added
                        TempServiceLine.CalcVATAmountLines(0, "Service Header", TempServiceLine, VATAmountLine, Ship);
                        TempServiceLine.UpdateVATOnLines(0, "Service Header", TempServiceLine, VATAmountLine);
                        VATAmount := VATAmountLine.GetTotalVATAmount;
                        VATBaseAmount := VATAmountLine.GetTotalVATBase;
                        VATDiscountAmount :=
                          VATAmountLine.GetTotalVATDiscount("Service Header"."Currency Code", "Service Header"."Prices Including VAT");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                TableID: array[10] of Integer;
                No: array[10] of Code[20];
            begin
                FormatAddr.ServiceHeaderSellTo(SellToAddr, "Service Header");
                FormatAddr.ServiceHeaderBillTo(BillToAddr, "Service Header");
                FormatAddr.ServiceHeaderShipTo(ShipToAddr, "Service Header");
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

                VerifyCustomerNo("Service Header");
                VerifyBilltoCustomerNo("Service Header");

                ServiceSetup.Get();

                VerifyPostingDate("Service Header");

                if "Document Date" <> 0D then
                    if "Document Date" <> NormalDate("Document Date") then
                        AddError(StrSubstNo(Text009, FieldCaption("Document Date")));

                case "Document Type" of
                    "Document Type"::Invoice:
                        begin
                            Ship := true;
                            Invoice := true;
                        end;
                    "Document Type"::"Credit Memo":
                        begin
                            Ship := false;
                            Invoice := true;
                        end;
                end;

                if not (Ship or Invoice) then
                    AddError(
                      StrSubstNo(
                        Text034,
                        Text001, Text002));

                if Invoice then begin
                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", "Document Type");
                    ServiceLine.SetRange("Document No.", "No.");
                    ServiceLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        ServiceLine.SetFilter("Qty. to Invoice", '<>0');
                    Invoice := ServiceLine.Find('-');
                    if Invoice and not Ship and ("Document Type" = "Document Type"::Order) then begin
                        Invoice := false;
                        repeat
                            Invoice := (ServiceLine."Quantity Shipped" - ServiceLine."Quantity Invoiced") <> 0;
                        until Invoice or (ServiceLine.Next = 0);
                    end;
                end;

                if Ship then begin
                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", "Document Type");
                    ServiceLine.SetRange("Document No.", "No.");
                    ServiceLine.SetFilter(Quantity, '<>0');
                    if "Document Type" = "Document Type"::Order then
                        ServiceLine.SetFilter("Qty. to Ship", '<>0');
                    ServiceLine.SetRange("Shipment No.", '');
                    Ship := ServiceLine.Find('-');
                end;

                if not (Ship or Invoice) then
                    AddError(Text012);

                if Invoice then
                    if not ("Document Type" = "Document Type"::"Credit Memo") then
                        if "Due Date" = 0D then
                            AddError(StrSubstNo(Text006, FieldCaption("Due Date")));

                if Ship and ("Shipping No." = '') then // Order,Invoice
                    if ("Document Type" = "Document Type"::Order) or
                       (("Document Type" = "Document Type"::Invoice) and ServiceSetup."Shipment on Invoice")
                    then
                        if "Shipping No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Shipping No. Series")));

                if Invoice and ("Posting No." = '') then
                    if "Document Type" = "Document Type"::Order then
                        if "Posting No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                Text006,
                                FieldCaption("Posting No. Series")));

                ServiceLine.Reset();
                ServiceLine.SetRange("Document Type", "Document Type");
                ServiceLine.SetRange("Document No.", "No.");
                if ServiceLine.FindFirst then;

                if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                    AddError(DimMgt.GetDimCombErr);

                TableID[1] := DATABASE::Customer;
                No[1] := "Bill-to Customer No.";
                TableID[3] := DATABASE::"Salesperson/Purchaser";
                No[3] := "Salesperson Code";
                TableID[4] := DATABASE::"Responsibility Center";
                No[4] := "Responsibility Center";

                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr);
            end;

            trigger OnPreDataItem()
            begin
                ServiceHeader.Copy("Service Header");
                ServiceHeader.FilterGroup := 2;
                ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
                if ServiceHeader.FindFirst then begin
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
                    group("Order Posting")
                    {
                        Caption = 'Order Posting';
                        field(ShipReceiveOnNextPostReq; ShipReceiveOnNextPostReq)
                        {
                            ApplicationArea = Service;
                            Caption = 'Ship';
                            ToolTip = 'Specifies if you want to post the documents that are being tested as shipped, or as shipped and invoiced.';

                            trigger OnValidate()
                            begin
                                if not ShipReceiveOnNextPostReq then
                                    InvOnNextPostReq := true;
                            end;
                        }
                        field(InvOnNextPostReq; InvOnNextPostReq)
                        {
                            ApplicationArea = Service;
                            Caption = 'Invoice';
                            ToolTip = 'Specifies whether you want to post the documents that are being tested as invoiced, or as shipped and invoiced.';

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
        ServiceHeaderFilter := "Service Header".GetFilters;
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
        Text012: Label 'There is nothing to post.';
        Text014: Label 'Service Document: %1';
        Text015: Label '%1 must be %2.';
        Text016: Label '%1 %2 does not exist on customer entries.';
        Text017: Label '%1 %2 %3 does not exist.';
        Text019: Label '%1 %2 must be specified.';
        Text020: Label '%1 must be 0 when %2 is 0.';
        Text024: Label 'The %1 on the shipment is not the same as the %1 on the Service Header.';
        Text026: Label 'Line %1 of the shipment %2, which you are attempting to invoice, has already been invoiced.';
        Text027: Label '%1 must have the same sign as the shipments.';
        Text033: Label 'Total %1 Excl. VAT';
        Text034: Label 'Enter "Yes" in %1 and/or %2.';
        Text035: Label 'You must enter the customer''s %1.';
        Text036: Label 'The quantity you are attempting to invoice is greater than the quantity in shipment %1.';
        ServiceSetup: Record "Service Mgt. Setup";
        GLSetup: Record "General Ledger Setup";
        Cust: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        ServiceShptLine: Record "Service Shipment Line";
        GenPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        FormatAddr: Codeunit "Format Address";
        DimMgt: Codeunit DimensionManagement;
        ServAmountsMgt: Codeunit "Serv-Amounts Mgt.";
        ServiceHeaderFilter: Text;
        SellToAddr: array[8] of Text[100];
        BillToAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        ShipInvText: Text[50];
        ReceiveInvText: Text[50];
        DimText: Text;
        ErrorText: array[99] of Text[250];
        MaxQtyToBeInvoiced: Decimal;
        RemQtyToBeInvoiced: Decimal;
        QtyToBeInvoiced: Decimal;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        QtyToHandle: Decimal;
        SumLineAmount: Decimal;
        SumInvDiscountAmount: Decimal;
        ErrorCounter: Integer;
        OrigMaxLineNo: Integer;
        InvOnNextPostReq: Boolean;
        ShipReceiveOnNextPostReq: Boolean;
        VATNoError: Boolean;
        ApplNoError: Boolean;
        ShowDim: Boolean;
        Text043: Label '%1 must be zero.';
        Text045: Label '%1 must not be %2 for %3 %4.';
        MoreLines: Boolean;
        Ship: Boolean;
        Invoice: Boolean;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text;
        Service_Document___TestCaptionLbl: Label 'Service Document - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Ship_toCaptionLbl: Label 'Ship-to';
        CustomerCaptionLbl: Label 'Customer';
        Bill_toCaptionLbl: Label 'Bill-to';
        Service_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date_CaptionLbl: Label 'Document Date';
        Service_Header___Due_Date_CaptionLbl: Label 'Due Date';
        Service_Header___Pmt__Discount_Date_CaptionLbl: Label 'Pmt. Discount Date';
        Service_Header___Posting_Date__Control105CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date__Control106CaptionLbl: Label 'Document Date';
        Service_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Service_Header___Due_Date__Control19CaptionLbl: Label 'Due Date';
        Service_Header___Pmt__Discount_Date__Control22CaptionLbl: Label 'Pmt. Discount Date';
        Service_Header___Posting_Date__Control131CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date__Control132CaptionLbl: Label 'Document Date';
        Service_Header___Posting_Date__Control137CaptionLbl: Label 'Posting Date';
        Service_Header___Document_Date__Control138CaptionLbl: Label 'Document Date';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Service_Line___Line_Discount___CaptionLbl: Label 'Line Disc. %';
        AmountCaptionLbl: Label 'Amount';
        Service_Line__QuantityCaptionLbl: Label 'Quantity';
        QtyToHandleCaptionLbl: Label 'Qty. to Handle';
        TempServiceLine__Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
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
        TotalCaptionLbl: Label 'Total';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CheckShptLines(ServiceLine2: Record "Service Line")
    var
        TempPostedDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        with ServiceLine2 do begin
            if Abs(RemQtyToBeInvoiced) > Abs("Qty. to Ship") then begin
                ServiceShptLine.Reset();
                case "Document Type" of
                    "Document Type"::Order:
                        begin
                            ServiceShptLine.SetCurrentKey("Order No.", "Order Line No.");
                            ServiceShptLine.SetRange("Order No.", "Document No.");
                            ServiceShptLine.SetRange("Order Line No.", "Line No.");
                        end;
                    "Document Type"::Invoice:
                        begin
                            ServiceShptLine.SetRange("Document No.", "Shipment No.");
                            ServiceShptLine.SetRange("Line No.", "Shipment Line No.");
                        end;
                end;

                ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');

                if ServiceShptLine.Find('-') then
                    repeat
                        DimMgt.GetDimensionSet(TempPostedDimSetEntry, ServiceShptLine."Dimension Set ID");
                        if not DimMgt.CheckDimIDConsistency(
                             TempDimSetEntry, TempPostedDimSetEntry, DATABASE::"Service Line", DATABASE::"Service Shipment Line")
                        then
                            AddError(DimMgt.GetDocDimConsistencyErr);

                        if ServiceShptLine."Customer No." <> "Customer No." then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Customer No.")));
                        if ServiceShptLine.Type <> Type then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption(Type)));
                        if ServiceShptLine."No." <> "No." then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("No.")));
                        if ServiceShptLine."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Gen. Bus. Posting Group")));
                        if ServiceShptLine."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Gen. Prod. Posting Group")));
                        if ServiceShptLine."Location Code" <> "Location Code" then
                            AddError(
                              StrSubstNo(
                                Text024,
                                FieldCaption("Location Code")));

                        if -ServiceLine."Qty. to Invoice" * ServiceShptLine.Quantity < 0 then
                            AddError(
                              StrSubstNo(
                                Text027, FieldCaption("Qty. to Invoice")));

                        QtyToBeInvoiced := RemQtyToBeInvoiced - ServiceLine."Qty. to Ship";
                        if Abs(QtyToBeInvoiced) > Abs(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced") then
                            QtyToBeInvoiced := -(ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced");
                        RemQtyToBeInvoiced := RemQtyToBeInvoiced - QtyToBeInvoiced;
                        ServiceShptLine."Quantity Invoiced" := ServiceShptLine."Quantity Invoiced" - QtyToBeInvoiced;
                        ServiceShptLine."Qty. Shipped Not Invoiced" :=
                          ServiceShptLine.Quantity - ServiceShptLine."Quantity Invoiced"
                    until (ServiceShptLine.Next = 0) or (Abs(RemQtyToBeInvoiced) <= Abs("Qty. to Ship"))
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

    procedure FindDimTxt(DimSetID: Integer)
    var
        i: Integer;
        TxtToAdd: Text[120];
        Separation: Text[5];
        StartNewLine: Boolean;
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimTxtArrLength := 0;
        for i := 1 to ArrayLen(DimTxtArr) do
            DimTxtArr[i] := '';
        if not DimSetEntry.FindSet then
            exit;
        Separation := '; ';
        repeat
            TxtToAdd := DimSetEntry."Dimension Code" + ' - ' + DimSetEntry."Dimension Value Code";
            if DimTxtArrLength = 0 then
                StartNewLine := true
            else
                StartNewLine := StrLen(DimTxtArr[DimTxtArrLength]) + StrLen(Separation) + StrLen(TxtToAdd) > MaxStrLen(DimTxtArr[1]);
            if StartNewLine then begin
                DimTxtArrLength += 1;
                DimTxtArr[DimTxtArrLength] := TxtToAdd
            end else
                DimTxtArr[DimTxtArrLength] := DimTxtArr[DimTxtArrLength] + Separation + TxtToAdd;
        until DimSetEntry.Next = 0;
    end;

    procedure CheckQuantity(var ServiceLine: Record "Service Line")
    begin
        with ServiceLine do begin
            if Quantity <> 0 then begin
                if "No." = '' then
                    AddError(StrSubstNo(Text019, Type, FieldCaption("No.")));
                if Type = Type::" " then
                    AddError(StrSubstNo(Text006, FieldCaption(Type)));
            end else
                if Amount <> 0 then
                    AddError(
                      StrSubstNo(Text020, FieldCaption(Amount), FieldCaption(Quantity)));
        end;
    end;

    procedure InitializeRequest(ShipReceiveOnNextPostReqFrom: Boolean; InvOnNextPostReqFrom: Boolean; ShowDimFrom: Boolean)
    begin
        ShipReceiveOnNextPostReq := ShipReceiveOnNextPostReqFrom;
        if not ShipReceiveOnNextPostReq then
            InvOnNextPostReq := true;
        InvOnNextPostReq := InvOnNextPostReqFrom;
        if not InvOnNextPostReq then
            ShipReceiveOnNextPostReq := true;
        ShowDim := ShowDimFrom;
    end;

    local procedure CheckType(ServiceLine2: Record "Service Line")
    begin
        with ServiceLine2 do
            case Type of
                Type::"G/L Account":
                    begin
                        if ("No." = '') and (Amount = 0) then
                            exit;

                        if "No." <> '' then
                            if GLAcc.Get("No.") then begin
                                if GLAcc.Blocked then
                                    AddError(StrSubstNo(Text007, GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption, "No."));
                                if not GLAcc."Direct Posting" and ("Line No." <= OrigMaxLineNo) then
                                    AddError(StrSubstNo(Text007, GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption, "No."));
                            end else
                                AddError(StrSubstNo(Text008, GLAcc.TableCaption, "No."));
                    end;
                Type::Item:
                    begin
                        if ("No." = '') and (Quantity = 0) then
                            exit;

                        if "No." <> '' then
                            if Item.Get("No.") then begin
                                if Item.Blocked then
                                    AddError(StrSubstNo(Text007, Item.FieldCaption(Blocked), false, Item.TableCaption, "No."));
                                if Item.Reserve = Item.Reserve::Always then begin
                                    CalcFields("Reserved Quantity");
                                    if "Document Type" = "Document Type"::"Credit Memo" then begin
                                        if (SignedXX(Quantity) < 0) and (Abs("Reserved Quantity") < Abs(Quantity)) then
                                            AddError(StrSubstNo(Text015, FieldCaption("Reserved Quantity"), SignedXX(Quantity)));
                                    end else
                                        if (SignedXX(Quantity) < 0) and (Abs("Reserved Quantity") < Abs("Qty. to Ship")) then
                                            AddError(StrSubstNo(Text015, FieldCaption("Reserved Quantity"), SignedXX("Qty. to Ship")));
                                end
                            end else
                                AddError(StrSubstNo(Text008, Item.TableCaption, "No."));
                    end;
                Type::Resource:
                    begin
                        if ("No." = '') and (Quantity = 0) then
                            exit;

                        if "No." <> '' then
                            if Res.Get("No.") then begin
                                if Res."Privacy Blocked" then
                                    AddError(StrSubstNo(Text007, Res.FieldCaption("Privacy Blocked"), false, Res.TableCaption, "No."));
                                if Res.Blocked then
                                    AddError(StrSubstNo(Text007, Res.FieldCaption(Blocked), false, Res.TableCaption, "No."));
                            end else
                                AddError(StrSubstNo(Text008, Res.TableCaption, "No."));
                    end;
            end;
    end;

    local procedure VerifyCustomerNo(ServiceHeader: Record "Service Header")
    var
        ShipQtyExist: Boolean;
    begin
        with ServiceHeader do
            if "Customer No." = '' then
                AddError(StrSubstNo(Text006, FieldCaption("Customer No.")))
            else begin
                if Cust.Get("Customer No.") then begin
                    if (Cust.Blocked = Cust.Blocked::Ship) and Ship then begin
                        ServiceLine2.SetRange("Document Type", "Document Type");
                        ServiceLine2.SetRange("Document No.", "No.");
                        ServiceLine2.SetFilter("Qty. to Ship", '>0');
                        if ServiceLine2.FindFirst then
                            ShipQtyExist := true;
                    end;
                    if Cust."Privacy Blocked" then
                        AddError(
                          StrSubstNo(
                            Text045,
                            Cust.FieldCaption("Privacy Blocked"), Cust."Privacy Blocked", Cust.TableCaption, "Customer No."));
                    if (Cust.Blocked = Cust.Blocked::All) or
                       ((Cust.Blocked = Cust.Blocked::Invoice) and
                        (not ("Document Type" = "Document Type"::"Credit Memo"))) or
                       ShipQtyExist
                    then
                        AddError(
                          StrSubstNo(
                            Text045,
                            Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption, "Customer No."));
                end else
                    AddError(
                      StrSubstNo(
                        Text008,
                        Cust.TableCaption, "Customer No."));
            end;
    end;

    local procedure VerifyBilltoCustomerNo(ServiceHeader: Record "Service Header")
    begin
        with ServiceHeader do
            if "Bill-to Customer No." = '' then
                AddError(StrSubstNo(Text006, FieldCaption("Bill-to Customer No.")))
            else
                if "Bill-to Customer No." <> "Customer No." then
                    if Cust.Get("Bill-to Customer No.") then begin
                        if Cust."Privacy Blocked" then
                            AddError(
                              StrSubstNo(
                                Text045,
                                Cust.FieldCaption("Privacy Blocked"), Cust."Privacy Blocked", Cust.TableCaption, "Bill-to Customer No."));
                        if (Cust.Blocked = Cust.Blocked::All) or
                           ((Cust.Blocked = Cust.Blocked::Invoice) and
                            ("Document Type" = "Document Type"::"Credit Memo"))
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

    local procedure VerifyPostingDate(ServiceHeader: Record "Service Header")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        TempErrorText: Text[250];
    begin
        with ServiceHeader do
            if "Posting Date" = 0D then
                AddError(StrSubstNo(Text006, FieldCaption("Posting Date")))
            else
                if "Posting Date" <> NormalDate("Posting Date") then
                    AddError(StrSubstNo(Text009, FieldCaption("Posting Date")))
                else
                    if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                        AddError(TempErrorText);
    end;
}
