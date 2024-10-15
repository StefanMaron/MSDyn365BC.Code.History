report 10477 "Elec. Sales Invoice MX"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ElecSalesInvoiceMX.rdlc';
    Caption = 'Electronic Sales Invoice Mexico';
    Permissions = TableData "Sales Invoice Line" = rimd;

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Ship-to Code", "No. Printed";
            RequestFilterHeading = 'Sales Invoice';
            column(Sales_Invoice_Header_No_; "No.")
            {
            }
            column(DocumentFooter; DocumentFooterLbl)
            {
            }
            dataitem("Sales Invoice Line"; "Sales Invoice Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.");
                dataitem(SalesLineComments; "Sales Comment Line")
                {
                    DataItemLink = "No." = FIELD("Document No."), "Document Line No." = FIELD("Line No.");
                    DataItemTableView = SORTING("Document Type", "No.", "Document Line No.", "Line No.") WHERE("Document Type" = CONST("Posted Invoice"), "Print On Invoice" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        with TempSalesInvoiceLine do begin
                            Init;
                            "Document No." := "Sales Invoice Header"."No.";
                            "Line No." := HighestLineNo + 10;
                            HighestLineNo := "Line No.";
                        end;
                        if StrLen(Comment) <= MaxStrLen(TempSalesInvoiceLine.Description) then begin
                            TempSalesInvoiceLine.Description := Comment;
                            TempSalesInvoiceLine."Description 2" := '';
                        end else begin
                            SpacePointer := MaxStrLen(TempSalesInvoiceLine.Description) + 1;
                            while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                                SpacePointer := SpacePointer - 1;
                            if SpacePointer = 1 then
                                SpacePointer := MaxStrLen(TempSalesInvoiceLine.Description) + 1;
                            TempSalesInvoiceLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
                            TempSalesInvoiceLine."Description 2" :=
                              CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempSalesInvoiceLine."Description 2"));
                        end;
                        TempSalesInvoiceLine.Insert();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempSalesInvoiceLine := "Sales Invoice Line";
                    TempSalesInvoiceLine.Insert();
                    HighestLineNo := "Line No.";
                    TempSalesInvoiceLineAsm := "Sales Invoice Line";
                    TempSalesInvoiceLineAsm.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesInvoiceLine.Reset();
                    TempSalesInvoiceLine.DeleteAll();
                    TempSalesInvoiceLineAsm.Reset();
                    TempSalesInvoiceLineAsm.DeleteAll();
                end;
            }
            dataitem("Sales Comment Line"; "Sales Comment Line")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("Document Type", "No.", "Document Line No.", "Line No.") WHERE("Document Type" = CONST("Posted Invoice"), "Print On Invoice" = CONST(true), "Document Line No." = CONST(0));

                trigger OnAfterGetRecord()
                begin
                    with TempSalesInvoiceLine do begin
                        Init;
                        "Document No." := "Sales Invoice Header"."No.";
                        "Line No." := HighestLineNo + 1000;
                        HighestLineNo := "Line No.";
                    end;
                    if StrLen(Comment) <= MaxStrLen(TempSalesInvoiceLine.Description) then begin
                        TempSalesInvoiceLine.Description := Comment;
                        TempSalesInvoiceLine."Description 2" := '';
                    end else begin
                        SpacePointer := MaxStrLen(TempSalesInvoiceLine.Description) + 1;
                        while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                            SpacePointer := SpacePointer - 1;
                        if SpacePointer = 1 then
                            SpacePointer := MaxStrLen(TempSalesInvoiceLine.Description) + 1;
                        TempSalesInvoiceLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
                        TempSalesInvoiceLine."Description 2" :=
                          CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempSalesInvoiceLine."Description 2"));
                    end;
                    TempSalesInvoiceLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    with TempSalesInvoiceLine do begin
                        Init;
                        "Document No." := "Sales Invoice Header"."No.";
                        "Line No." := HighestLineNo + 1000;
                        HighestLineNo := "Line No.";
                    end;
                    TempSalesInvoiceLine.Insert();
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInformation_Picture; CompanyInformation.Picture)
                    {
                    }
                    column(CompanyAddress_1_; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress_2_; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress_3_; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress_4_; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress_5_; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddress_6_; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BillToAddress_1_; BillToAddress[1])
                    {
                    }
                    column(BillToAddress_2_; BillToAddress[2])
                    {
                    }
                    column(BillToAddress_3_; BillToAddress[3])
                    {
                    }
                    column(BillToAddress_4_; BillToAddress[4])
                    {
                    }
                    column(BillToAddress_5_; BillToAddress[5])
                    {
                    }
                    column(BillToAddress_6_; BillToAddress[6])
                    {
                    }
                    column(BillToAddress_7_; BillToAddress[7])
                    {
                    }
                    column(ShipmentMethod_Description; ShipmentMethod.Description)
                    {
                    }
                    column(Sales_Invoice_Header___Shipment_Date_; "Sales Invoice Header"."Shipment Date")
                    {
                    }
                    column(Sales_Invoice_Header___Due_Date_; "Sales Invoice Header"."Due Date")
                    {
                    }
                    column(PaymentTerms_Description; PaymentTerms.Description)
                    {
                    }
                    column(ShipToAddress_1_; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddress_2_; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddress_3_; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddress_4_; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddress_5_; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddress_6_; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddress_7_; ShipToAddress[7])
                    {
                    }
                    column(Sales_Invoice_Header___Bill_to_Customer_No__; "Sales Invoice Header"."Bill-to Customer No.")
                    {
                    }
                    column(Sales_Invoice_Header___Your_Reference_; "Sales Invoice Header"."Your Reference")
                    {
                    }
                    column(Sales_Invoice_Header___Order_Date_; "Sales Invoice Header"."Order Date")
                    {
                    }
                    column(Sales_Invoice_Header___Order_No__; "Sales Invoice Header"."Order No.")
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(CompanyAddress_7_; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress_8_; CompanyAddress[8])
                    {
                    }
                    column(BillToAddress_8_; BillToAddress[8])
                    {
                    }
                    column(ShipToAddress_8_; ShipToAddress[8])
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(DocumentText; DocumentText)
                    {
                    }
                    column(CompanyInformation__RFC_No__; CompanyInformation."RFC No.")
                    {
                    }
                    column(FolioText; "Sales Invoice Header"."Fiscal Invoice Number PAC")
                    {
                    }
                    column(Sales_Invoice_Header___Certificate_Serial_No__; "Sales Invoice Header"."Certificate Serial No.")
                    {
                    }
                    column(NoSeriesLine__Authorization_Code_; "Sales Invoice Header"."Date/Time Stamped")
                    {
                    }
                    column(NoSeriesLine__Authorization_Year_; StrSubstNo(Text013, "Sales Invoice Header"."Bill-to City", "Sales Invoice Header"."Document Date"))
                    {
                    }
                    column(Customer__RFC_No__; Customer."RFC No.")
                    {
                    }
                    column(Sales_Invoice_Header___No__; "Sales Invoice Header"."No.")
                    {
                    }
                    column(Customer__Phone_No__; Customer."Phone No.")
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(BillCaption; BillCaptionLbl)
                    {
                    }
                    column(Ship_ViaCaption; Ship_ViaCaptionLbl)
                    {
                    }
                    column(Ship_DateCaption; Ship_DateCaptionLbl)
                    {
                    }
                    column(Due_DateCaption; Due_DateCaptionLbl)
                    {
                    }
                    column(TermsCaption; TermsCaptionLbl)
                    {
                    }
                    column(Customer_IDCaption; Customer_IDCaptionLbl)
                    {
                    }
                    column(P_O__NumberCaption; P_O__NumberCaptionLbl)
                    {
                    }
                    column(P_O__DateCaption; P_O__DateCaptionLbl)
                    {
                    }
                    column(Our_Order_No_Caption; Our_Order_No_CaptionLbl)
                    {
                    }
                    column(SalesPersonCaption; SalesPersonCaptionLbl)
                    {
                    }
                    column(ShipCaption; ShipCaptionLbl)
                    {
                    }
                    column(Page_Caption; Page_CaptionLbl)
                    {
                    }
                    column(CompanyInformation__RFC_No__Caption; CompanyInformation__RFC_No__CaptionLbl)
                    {
                    }
                    column(FolioTextCaption; FolioTextCaptionLbl)
                    {
                    }
                    column(Sales_Invoice_Header___Certificate_Serial_No__Caption; Sales_Invoice_Header___Certificate_Serial_No__CaptionLbl)
                    {
                    }
                    column(NoSeriesLine__Authorization_Code_Caption; NoSeriesLine__Authorization_Code_CaptionLbl)
                    {
                    }
                    column(NoSeriesLine__Authorization_Year_Caption; NoSeriesLine__Authorization_Year_CaptionLbl)
                    {
                    }
                    column(Customer__RFC_No__Caption; Customer__RFC_No__CaptionLbl)
                    {
                    }
                    column(Customer__Phone_No__Caption; Customer__Phone_No__CaptionLbl)
                    {
                    }
                    column(SATPaymentMethod; SATPaymentMethod)
                    {
                    }
                    column(SATPaymentTerm; SATPaymentTerm)
                    {
                    }
                    column(SATTaxRegimeClassification; SATTaxRegimeClassification)
                    {
                    }
                    column(SATTipoRelacion; SATTipoRelacion)
                    {
                    }
                    column(SATFolioFiscal; SATFolioFiscal)
                    {
                    }
                    column(TaxRegimeCaption; TaxRegimeLbl)
                    {
                    }
                    dataitem(SalesInvLine; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(AmountExclInvDisc; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesInvoiceLine__No__; TempSalesInvoiceLine."No.")
                        {
                        }
                        column(TempSalesInvoiceLine__Unit_of_Measure_; TempSalesInvoiceLine."Unit of Measure")
                        {
                        }
                        column(OrderedQuantity; OrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempSalesInvoiceLine_Quantity; TempSalesInvoiceLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(UnitPriceToPrint; UnitPriceToPrint)
                        {
                            DecimalPlaces = 2 : 5;
                        }
                        column(AmountExclInvDisc_Control53; AmountExclInvDisc)
                        {
                        }
                        column(LowDescription; LowDescriptionToPrint)
                        {
                        }
                        column(HighDescription; HighDescriptionToPrint)
                        {
                        }
                        column(SalesInvLine_Number; Number)
                        {
                        }
                        column(AmountExclInvDisc_Control40; AmountExclInvDisc)
                        {
                        }
                        column(AmountExclInvDisc_Control79; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesInvoiceLine_Amount___AmountExclInvDisc; TempSalesInvoiceLine.Amount - AmountExclInvDisc)
                        {
                        }
                        column(TempSalesInvoiceLine__Amount_Including_VAT____TempSalesInvoiceLine_Amount; TempSalesInvoiceLine."Amount Including VAT" - TempSalesInvoiceLine.Amount)
                        {
                        }
                        column(TempSalesInvoiceLine__Amount_Including_VAT_; TempSalesInvoiceLine."Amount Including VAT")
                        {
                        }
                        column(AmountInWords_1_; AmountInWords[1])
                        {
                        }
                        column(AmountInWords_2_; AmountInWords[2])
                        {
                        }
                        column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
                        {
                        }
                        column(UnitCaption; UnitCaptionLbl)
                        {
                        }
                        column(Order_QtyCaption; Order_QtyCaptionLbl)
                        {
                        }
                        column(QuantityCaption; QuantityCaptionLbl)
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Total_PriceCaption; Total_PriceCaptionLbl)
                        {
                        }
                        column(Subtotal_Caption; Subtotal_CaptionLbl)
                        {
                        }
                        column(Invoice_Discount_Caption; Invoice_Discount_CaptionLbl)
                        {
                        }
                        column(Total_Caption; Total_CaptionLbl)
                        {
                        }
                        column(Amount_in_words_Caption; Amount_in_words_CaptionLbl)
                        {
                        }
                        column(TempSalesInvoiceLine__Amount_Including_VAT____TempSalesInvoiceLine_AmountCaption; TempSalesInvoiceLine__Amount_Including_VAT____TempSalesInvoiceLine_AmountCaptionLbl)
                        {
                        }
                        dataitem(AsmLoop; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            column(TempPostedAsmLineUnitofMeasureCode; GetUOMText(TempPostedAsmLine."Unit of Measure Code"))
                            {
                            }
                            column(TempPostedAsmLineQuantity; TempPostedAsmLine.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(TempPostedAsmLineVariantCode; BlanksForIndent + TempPostedAsmLine."Variant Code")
                            {
                            }
                            column(TempPostedAsmLineDescription; BlanksForIndent + TempPostedAsmLine.Description)
                            {
                            }
                            column(TempPostedAsmLineNo; BlanksForIndent + TempPostedAsmLine."No.")
                            {
                            }
                            column(AsmLoop_Number; Number)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    TempPostedAsmLine.FindSet
                                else
                                    TempPostedAsmLine.Next;
                            end;

                            trigger OnPreDataItem()
                            begin
                                Clear(TempPostedAsmLine);
                                SetRange(Number, 1, TempPostedAsmLine.Count);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            with TempSalesInvoiceLine do begin
                                if OnLineNumber = 1 then
                                    Find('-')
                                else
                                    Next;

                                OrderedQuantity := 0;
                                if "Sales Invoice Header"."Order No." = '' then
                                    OrderedQuantity := Quantity
                                else
                                    if OrderLine.Get(1, "Sales Invoice Header"."Order No.", "Line No.") then
                                        OrderedQuantity := OrderLine.Quantity
                                    else begin
                                        ShipmentLine.SetRange("Order No.", "Sales Invoice Header"."Order No.");
                                        ShipmentLine.SetRange("Order Line No.", "Line No.");
                                        if ShipmentLine.Find('-') then
                                            repeat
                                                OrderedQuantity := OrderedQuantity + ShipmentLine.Quantity;
                                            until 0 = ShipmentLine.Next;
                                    end;

                                DescriptionToPrint := Description + ' ' + "Description 2";
                                if Type = Type::" " then begin
                                    if OnLineNumber < NumberOfLines then begin
                                        Next;
                                        if Type = Type::" " then begin
                                            DescriptionToPrint :=
                                              CopyStr(DescriptionToPrint + ' ' + Description + ' ' + "Description 2", 1, MaxStrLen(DescriptionToPrint));
                                            OnLineNumber := OnLineNumber + 1;
                                            SalesInvLine.Next;
                                        end else
                                            Next(-1);
                                    end;
                                    "No." := '';
                                    "Unit of Measure" := '';
                                    Amount := 0;
                                    "Amount Including VAT" := 0;
                                    "Inv. Discount Amount" := 0;
                                    Quantity := 0;
                                end else
                                    if Type = Type::"G/L Account" then
                                        "No." := '';

                                if "No." = '' then begin
                                    HighDescriptionToPrint := DescriptionToPrint;
                                    LowDescriptionToPrint := '';
                                end else begin
                                    HighDescriptionToPrint := '';
                                    LowDescriptionToPrint := DescriptionToPrint;
                                end;

                                AmountExclInvDisc := Amount + "Inv. Discount Amount";

                                if Quantity = 0 then
                                    UnitPriceToPrint := 0 // so it won't print
                                else
                                    UnitPriceToPrint := Round(AmountExclInvDisc / Quantity, 0.00001);
                                TotalAmountIncludingVAT += "Amount Including VAT";
                            end;

                            CollectAsmInformation(TempSalesInvoiceLine);
                            if OnLineNumber = NumberOfLines then
                                ConvertAmounttoWords(TotalAmountIncludingVAT);
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(AmountExclInvDisc);
                            NumberOfLines := TempSalesInvoiceLine.Count();
                            SetRange(Number, 1, NumberOfLines);
                            OnLineNumber := 0;
                            TotalAmountIncludingVAT := 0;
                        end;
                    }
                    dataitem(OriginalStringLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(OriginalStringText; OriginalStringText)
                        {
                        }
                        column(OriginalStringLoop_Number; Number)
                        {
                        }
                        column(Original_StringCaption; Original_StringCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(OriginalStringText);
                            OriginalStringText := CopyStr(OriginalStringTextUnbounded, Position, MaxStrLen(OriginalStringText));
                            Position := Position + StrLen(OriginalStringText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(OriginalStringTextUnbounded) / MaxStrLen(OriginalStringText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(DigitalSignaturePACLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(DigitalSignaturePACText; DigitalSignaturePACText)
                        {
                        }
                        column(DigitalSignaturePACLoop_Number; Number)
                        {
                        }
                        column(Digital_StampCaption; Digital_StampCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(DigitalSignaturePACText);
                            DigitalSignaturePACText := CopyStr(DigitalSignaturePACTextUnbounded, Position, MaxStrLen(DigitalSignaturePACText));
                            Position := Position + StrLen(DigitalSignaturePACText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(DigitalSignaturePACTextUnbounded) / MaxStrLen(DigitalSignaturePACText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(DigitalSignatureLoop; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(DigitalSignatureText; DigitalSignatureText)
                        {
                        }
                        column(DigitalSignatureLoop_Number; Number)
                        {
                        }
                        column(Digital_stampCaption_Control1020008; Digital_stampCaption_Control1020008Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(DigitalSignatureText);
                            DigitalSignatureText := CopyStr(DigitalSignatureTextUnbounded, Position, MaxStrLen(DigitalSignatureText));
                            Position := Position + StrLen(DigitalSignatureText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(DigitalSignatureTextUnbounded) / MaxStrLen(DigitalSignatureText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(QRCode; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        column(Sales_Invoice_Header___QR_Code_; "Sales Invoice Header"."QR Code")
                        {
                        }
                        column(QRCode_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            "Sales Invoice Header".CalcFields("QR Code");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            SalesInvPrinted.Run("Sales Invoice Header");
                        CurrReport.Break();
                    end;
                    CopyNo := CopyNo + 1;
                    if CopyNo = 1 then // Original
                        Clear(CopyTxt)
                    else
                        CopyTxt := Text000;
                end;

                trigger OnPreDataItem()
                begin
                    NoLoops := 1 + Abs(NoCopies) + Customer."Invoice Copies";
                    if NoLoops <= 0 then
                        NoLoops := 1;
                    CopyNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            var
                SATUtilities: Codeunit "SAT Utilities";
                EInvoiceMgt: Codeunit "E-Invoice Mgt.";
                InStream: InStream;
                DummySalesInvoiceNumber: Code[20];
            begin
                if "Source Code" = SourceCodeSetup."Deleted Document" then
                    Error(Text012);

                if PrintCompany then
                    if RespCenter.Get("Responsibility Center") then begin
                        FormatAddress.RespCenter(CompanyAddress, RespCenter);
                        CompanyInformation."Phone No." := RespCenter."Phone No.";
                        CompanyInformation."Fax No." := RespCenter."Fax No.";
                    end;
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                if "Salesperson Code" = '' then
                    Clear(SalesPurchPerson)
                else
                    SalesPurchPerson.Get("Salesperson Code");

                if not Customer.Get("Bill-to Customer No.") then begin
                    Clear(Customer);
                    "Bill-to Name" := Text009;
                    "Ship-to Name" := Text009;
                end;
                DocumentText := Text010;
                if "Prepayment Invoice" then
                    DocumentText := Text011;

                FormatAddress.SalesInvBillTo(BillToAddress, "Sales Invoice Header");
                FormatAddress.SalesInvShipTo(ShipToAddress, ShipToAddress, "Sales Invoice Header");

                if "Payment Terms Code" = '' then
                    Clear(PaymentTerms)
                else
                    PaymentTerms.Get("Payment Terms Code");

                if "Shipment Method Code" = '' then
                    Clear(ShipmentMethod)
                else
                    ShipmentMethod.Get("Shipment Method Code");

                if LogInteraction then
                    if not CurrReport.Preview then begin
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');
                    end;

                "Sales Invoice Header".CalcFields("Original String", "Digital Stamp SAT", "Digital Stamp PAC");

                Clear(OriginalStringTextUnbounded);
                "Original String".CreateInStream(InStream);
                InStream.Read(OriginalStringTextUnbounded);

                Clear(DigitalSignatureTextUnbounded);
                "Digital Stamp SAT".CreateInStream(InStream);
                InStream.Read(DigitalSignatureTextUnbounded);

                Clear(DigitalSignaturePACTextUnbounded);
                "Digital Stamp PAC".CreateInStream(InStream);
                InStream.Read(DigitalSignaturePACTextUnbounded);

                SATPaymentMethod := SATUtilities.GetSATPaymentTermDescription("Payment Terms Code"); // MetodoPago
                SATPaymentTerm := SATUtilities.GetSATPaymentMethodDescription("Payment Method Code"); // FormaPago

                SATFolioFiscal := EInvoiceMgt.GetUUIDFromOriginalPrepayment("Sales Invoice Header", DummySalesInvoiceNumber);// Folio Fiscal
                if SATFolioFiscal <> '' then
                    SATTipoRelacion := TipoRelacionTxt;
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
                    field(NoCopies; NoCopies)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies to print of the document.';
                    }
                    field(PrintCompany; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if the printed document includes your company address.';
                        Visible = false;
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies that interactions with contact persons in connection with the report are logged.';
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
            InitLogInteraction;
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        ShipmentLine.SetCurrentKey("Order No.", "Order Line No.");
        if not CurrReport.UseRequestPage then
            InitLogInteraction;

        CompanyInformation.Get();
        SalesSetup.Get();
        SourceCodeSetup.Get();
        PrintCompany := true;

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                CompanyInformation.CalcFields(Picture);
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

        if PrintCompany then
            FormatAddress.Company(CompanyAddress, CompanyInformation)
        else
            Clear(CompanyAddress);

        SATTaxRegimeClassification := SATUtilities.GetSATTaxSchemeDescription(CompanyInformation."SAT Tax Regime Classification");
    end;

    var
        OrderedQuantity: Decimal;
        UnitPriceToPrint: Decimal;
        AmountExclInvDisc: Decimal;
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        OrderLine: Record "Sales Line";
        ShipmentLine: Record "Sales Shipment Line";
        TempSalesInvoiceLine: Record "Sales Invoice Line" temporary;
        TempSalesInvoiceLineAsm: Record "Sales Invoice Line" temporary;
        RespCenter: Record "Responsibility Center";
        TempPostedAsmLine: Record "Posted Assembly Line" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        TranslationManagement: Report "Check Translation Management";
        Language: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        DescriptionToPrint: Text[210];
        HighDescriptionToPrint: Text[210];
        LowDescriptionToPrint: Text[210];
        PrintCompany: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        HighestLineNo: Integer;
        SpacePointer: Integer;
        SalesInvPrinted: Codeunit "Sales Inv.-Printed";
        FormatAddress: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        Position: Integer;
        LogInteraction: Boolean;
        Text000: Label 'COPY';
        Text001: Label 'Transferred from page %1';
        Text002: Label 'Transferred to page %1';
        TotalAmountIncludingVAT: Decimal;
        OriginalStringText: Text[80];
        DigitalSignatureText: Text[80];
        DigitalSignaturePACText: Text[80];
        AmountInWords: array[2] of Text[80];
        Text009: Label 'VOID INVOICE';
        DocumentText: Text[100];
        OriginalStringTextUnbounded: Text;
        DigitalSignatureTextUnbounded: Text;
        Text010: Label 'ELECTRONIC INVOICE';
        Text011: Label 'ELECTRONIC PREPAYMENT REQUEST';
        Text012: Label 'You can not sign or send or print a deleted document.';
        Text013: Label '%1, %2';
        DigitalSignaturePACTextUnbounded: Text;
        [InDataSet]
        LogInteractionEnable: Boolean;
        DisplayAssemblyInformation: Boolean;
        BillCaptionLbl: Label 'Bill-To:';
        Ship_ViaCaptionLbl: Label 'Ship Via';
        Ship_DateCaptionLbl: Label 'Ship Date';
        Due_DateCaptionLbl: Label 'Due Date';
        TermsCaptionLbl: Label 'Terms';
        Customer_IDCaptionLbl: Label 'Customer ID';
        P_O__NumberCaptionLbl: Label 'P.O. Number';
        P_O__DateCaptionLbl: Label 'P.O. Date';
        Our_Order_No_CaptionLbl: Label 'Our Order No.';
        SalesPersonCaptionLbl: Label 'SalesPerson';
        ShipCaptionLbl: Label 'Ship-To:';
        Page_CaptionLbl: Label 'Page:';
        CompanyInformation__RFC_No__CaptionLbl: Label 'Company RFC';
        FolioTextCaptionLbl: Label 'Folio:';
        Sales_Invoice_Header___Certificate_Serial_No__CaptionLbl: Label 'Certificate Serial No.';
        NoSeriesLine__Authorization_Code_CaptionLbl: Label 'Date and time of certification:';
        NoSeriesLine__Authorization_Year_CaptionLbl: Label 'Location and Issue date:';
        Customer__RFC_No__CaptionLbl: Label 'Customer RFC';
        Customer__Phone_No__CaptionLbl: Label 'Phone number ';
        Item_DescriptionCaptionLbl: Label 'Item/Description';
        UnitCaptionLbl: Label 'Unit';
        Order_QtyCaptionLbl: Label 'Order Qty';
        QuantityCaptionLbl: Label 'Quantity';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Total_PriceCaptionLbl: Label 'Total Price';
        Subtotal_CaptionLbl: Label 'Subtotal:';
        Invoice_Discount_CaptionLbl: Label 'Invoice Discount:';
        Total_CaptionLbl: Label 'Total:';
        Amount_in_words_CaptionLbl: Label 'Amount in words:';
        TempSalesInvoiceLine__Amount_Including_VAT____TempSalesInvoiceLine_AmountCaptionLbl: Label 'VAT Amount';
        Original_StringCaptionLbl: Label 'Original string of digital certificate complement from SAT';
        Digital_StampCaptionLbl: Label 'Digital stamp from SAT';
        Digital_stampCaption_Control1020008Lbl: Label 'Digital stamp';
        DocumentFooterLbl: Label 'This document is a printed version of a CFDI.';
        SATPaymentMethod: Text[50];
        SATPaymentTerm: Text[50];
        SATTaxRegimeClassification: Text[100];
        TaxRegimeLbl: Label 'Regimen Fiscal:';
        SATTipoRelacion: Text[100];
        SATFolioFiscal: Text[100];
        TipoRelacionTxt: Label '07 CFDI por aplicacion de anticipo';

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractTmplCode(4) <> '';
    end;

    procedure ConvertAmounttoWords(AmountLoc: Decimal)
    var
        LanguageId: Integer;
    begin
        if CurrReport.Language in [1033, 3084, 2058, 4105] then
            LanguageId := CurrReport.Language
        else
            LanguageId := GlobalLanguage;
        TranslationManagement.FormatNoText(AmountInWords, AmountLoc,
          LanguageId, "Sales Invoice Header"."Currency Code");
    end;

    procedure CollectAsmInformation(TempSalesInvoiceLine: Record "Sales Invoice Line" temporary)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedAsmHeader: Record "Posted Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        TempPostedAsmLine.DeleteAll();
        if not DisplayAssemblyInformation then
            exit;
        if not TempSalesInvoiceLineAsm.Get(TempSalesInvoiceLine."Document No.", TempSalesInvoiceLine."Line No.") then
            exit;
        SalesInvoiceLine.Get(TempSalesInvoiceLineAsm."Document No.", TempSalesInvoiceLineAsm."Line No.");
        if SalesInvoiceLine.Type <> SalesInvoiceLine.Type::Item then
            exit;
        with ValueEntry do begin
            SetCurrentKey("Document No.");
            SetRange("Document No.", SalesInvoiceLine."Document No.");
            SetRange("Document Type", "Document Type"::"Sales Invoice");
            SetRange("Document Line No.", SalesInvoiceLine."Line No.");
            if not FindSet then
                exit;
        end;
        repeat
            if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Sales Shipment" then begin
                    SalesShipmentLine.Get(ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.");
                    if SalesShipmentLine.AsmToShipmentExists(PostedAsmHeader) then begin
                        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
                        if PostedAsmLine.FindSet then
                            repeat
                                TreatAsmLineBuffer(PostedAsmLine);
                            until PostedAsmLine.Next = 0;
                    end;
                end;
        until ValueEntry.Next = 0;
    end;

    procedure TreatAsmLineBuffer(PostedAsmLine: Record "Posted Assembly Line")
    begin
        Clear(TempPostedAsmLine);
        TempPostedAsmLine.SetRange(Type, PostedAsmLine.Type);
        TempPostedAsmLine.SetRange("No.", PostedAsmLine."No.");
        TempPostedAsmLine.SetRange("Variant Code", PostedAsmLine."Variant Code");
        TempPostedAsmLine.SetRange(Description, PostedAsmLine.Description);
        TempPostedAsmLine.SetRange("Unit of Measure Code", PostedAsmLine."Unit of Measure Code");
        if TempPostedAsmLine.FindFirst then begin
            TempPostedAsmLine.Quantity += PostedAsmLine.Quantity;
            TempPostedAsmLine.Modify();
        end else begin
            Clear(TempPostedAsmLine);
            TempPostedAsmLine := PostedAsmLine;
            TempPostedAsmLine.Insert();
        end;
    end;

    procedure GetUOMText(UOMCode: Code[10]): Text[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UOMCode) then
            exit(UOMCode);
        exit(UnitOfMeasure.Description);
    end;

    procedure BlanksForIndent(): Text[10]
    begin
        exit(PadStr('', 2, ' '));
    end;
}

