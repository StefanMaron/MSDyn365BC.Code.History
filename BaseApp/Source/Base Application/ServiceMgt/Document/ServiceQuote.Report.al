report 5902 "Service Quote"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ServiceMgt/Document/ServiceQuote.rdlc';
    Caption = 'Service Quote';

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") WHERE("Document Type" = CONST(Quote));
            RequestFilterFields = "No.", "Customer No.";
            column(Service_Header_Document_Type; "Document Type")
            {
            }
            column(Service_Header_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CompanyInfo_Picture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(Service_Header___Order_Time_; "Service Header"."Order Time")
                    {
                    }
                    column(Service_Header___Order_Date_; Format("Service Header"."Order Date"))
                    {
                    }
                    column(Service_Header__Status; "Service Header".Status)
                    {
                    }
                    column(Service_Header___No__; "Service Header"."No.")
                    {
                    }
                    column(CustAddr_6_; CustAddr[6])
                    {
                    }
                    column(CustAddr_5_; CustAddr[5])
                    {
                    }
                    column(CustAddr_4_; CustAddr[4])
                    {
                    }
                    column(CustAddr_3_; CustAddr[3])
                    {
                    }
                    column(CustAddr_2_; CustAddr[2])
                    {
                    }
                    column(CustAddr_1_; CustAddr[1])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(Service_Header___Bill_to_Name_; "Service Header"."Bill-to Name")
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(STRSUBSTNO_Text001_CopyText_; StrSubstNo(Text001, CopyText))
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(Service_Header___E_Mail_; "Service Header"."E-Mail")
                    {
                    }
                    column(Service_Header___Phone_No__; "Service Header"."Phone No.")
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(Service_Header___Order_Date_Caption; Service_Header___Order_Date_CaptionLbl)
                    {
                    }
                    column(Service_Header___Order_Time_Caption; "Service Header".FieldCaption("Order Time"))
                    {
                    }
                    column(Service_Header__StatusCaption; "Service Header".FieldCaption(Status))
                    {
                    }
                    column(Service_Header___No__Caption; "Service Header".FieldCaption("No."))
                    {
                    }
                    column(Invoice_toCaption; Invoice_toCaptionLbl)
                    {
                    }
                    column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                    {
                    }
                    column(Service_Header___Phone_No__Caption; Service_Header___Phone_No__CaptionLbl)
                    {
                    }
                    column(Service_Header___E_Mail_Caption; Service_Header___E_Mail_CaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimensionLoopNumber; Number)
                        {
                        }
                        column(DimText_Control9; DimText)
                        {
                        }
                        column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
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
                    dataitem("Service Order Comment"; "Service Comment Line")
                    {
                        DataItemLink = "Table Subtype" = FIELD("Document Type"), "No." = FIELD("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = SORTING("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") WHERE("Table Name" = CONST("Service Header"), Type = CONST(General));
                        column(Service_Order_Comment__Line_No__; "Line No.")
                        {
                        }
                        column(Service_Order_Comment_Table_Name; "Table Name")
                        {
                        }
                        column(Service_Order_Comment_Table_Subtype; "Table Subtype")
                        {
                        }
                        column(Service_Order_Comment_No_; "No.")
                        {
                        }
                        column(Service_Order_Comment_Type; Type)
                        {
                        }
                        column(Service_Order_Comment_Table_Line_No_; "Table Line No.")
                        {
                        }
                    }
                    dataitem("Service Item Line"; "Service Item Line")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");
                        column(NoOfCopies; NoOfCopies)
                        {
                        }
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(Service_Item_Line__Serial_No__; "Serial No.")
                        {
                        }
                        column(Description_ServLineType; Description)
                        {
                        }
                        column(ServItemNo_ServLineType; "Service Item No.")
                        {
                        }
                        column(Service_Item_Line__Service_Item_Group_Code_; "Service Item Group Code")
                        {
                        }
                        column(Service_Item_Line_Warranty; Warranty)
                        {
                        }
                        column(ItemNo_ServLineType; "Item No.")
                        {
                        }
                        column(Service_Item_Line__Loaner_No__; "Loaner No.")
                        {
                        }
                        column(Service_Item_Line__Service_Shelf_No__; "Service Shelf No.")
                        {
                        }
                        column(Warranty; Format(Warranty))
                        {
                        }
                        column(Service_Item_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Service_Item_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Service_Item_Line_Line_No_; "Line No.")
                        {
                        }
                        column(Service_Item_Line__Serial_No__Caption; FieldCaption("Serial No."))
                        {
                        }
                        column(Service_Item_Line_DescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(Service_Item_Line__Service_Item_No__Caption; FieldCaption("Service Item No."))
                        {
                        }
                        column(Service_Item_Line__Service_Item_Group_Code_Caption; FieldCaption("Service Item Group Code"))
                        {
                        }
                        column(Service_Item_Line__Item_No__Caption; FieldCaption("Item No."))
                        {
                        }
                        column(Service_Item_Line_WarrantyCaption; FieldCaption(Warranty))
                        {
                        }
                        column(Service_Item_LinesCaption; Service_Item_LinesCaptionLbl)
                        {
                        }
                        column(Service_Item_Line__Loaner_No__Caption; FieldCaption("Loaner No."))
                        {
                        }
                        column(Service_Item_Line__Service_Shelf_No__Caption; FieldCaption("Service Shelf No."))
                        {
                        }
                        dataitem("Fault Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = FIELD("Document Type"), "No." = FIELD("Document No."), "Table Line No." = FIELD("Line No.");
                            DataItemTableView = SORTING("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") WHERE("Table Name" = CONST("Service Header"), Type = CONST(Fault));
                            column(Fault_Comment_Comment; Comment)
                            {
                            }
                            column(FaultCommentNumber; Number1)
                            {
                            }
                            column(Fault_Comment_Table_Name; "Table Name")
                            {
                            }
                            column(Fault_Comment_Table_Subtype; "Table Subtype")
                            {
                            }
                            column(Fault_Comment_No_; "No.")
                            {
                            }
                            column(Fault_Comment_Type; Type)
                            {
                            }
                            column(Fault_Comment_Table_Line_No_; "Table Line No.")
                            {
                            }
                            column(Fault_Comment_Line_No_; "Line No.")
                            {
                            }
                            column(Fault_CommentsCaption; Fault_CommentsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Number2 := 0;
                                Number1 := Number1 + 1;
                            end;
                        }
                        dataitem("Resolution Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = FIELD("Document Type"), "No." = FIELD("Document No."), "Table Line No." = FIELD("Line No.");
                            DataItemTableView = SORTING("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") WHERE("Table Name" = CONST("Service Header"), Type = CONST(Resolution));
                            column(Resolution_Comment_Comment; Comment)
                            {
                            }
                            column(ResolutionCommentNumber; Number2)
                            {
                            }
                            column(Resolution_Comment_Table_Name; "Table Name")
                            {
                            }
                            column(Resolution_Comment_Table_Subtype; "Table Subtype")
                            {
                            }
                            column(Resolution_Comment_No_; "No.")
                            {
                            }
                            column(Resolution_Comment_Type; Type)
                            {
                            }
                            column(Resolution_Comment_Table_Line_No_; "Table Line No.")
                            {
                            }
                            column(Resolution_Comment_Line_No_; "Line No.")
                            {
                            }
                            column(Resolution_CommentsCaption; Resolution_CommentsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Number1 := 0;
                                Number2 := Number2 + 1;
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Number1 := 0;
                            Number2 := 0;
                        end;
                    }
                    dataitem("Service Line"; "Service Line")
                    {
                        DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");
                        column(Service_Line__Service_Item_Serial_No__; "Service Item Serial No.")
                        {
                        }
                        column(Type_ServLine; Type)
                        {
                        }
                        column(Service_Line__No__; "No.")
                        {
                        }
                        column(Service_Line_Description; Description)
                        {
                        }
                        column(Service_Line__Unit_Price_; "Unit Price")
                        {
                        }
                        column(LineDiscount_ServLine; "Line Discount %")
                        {
                        }
                        column(Amt; Amt)
                        {
                        }
                        column(Service_Line__Variant_Code_; "Variant Code")
                        {
                        }
                        column(GrossAmt; GrossAmt)
                        {
                        }
                        column(Quantity_ServLine; Quantity)
                        {
                        }
                        column(TotAmt; TotAmt)
                        {
                        }
                        column(TotGrossAmt; TotGrossAmt)
                        {
                        }
                        column(Service_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Service_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Service_Line_Line_No_; "Line No.")
                        {
                        }
                        column(Service_Line__Service_Item_Serial_No__Caption; FieldCaption("Service Item Serial No."))
                        {
                        }
                        column(Service_Line__No__Caption; FieldCaption("No."))
                        {
                        }
                        column(Service_Line_TypeCaption; FieldCaption(Type))
                        {
                        }
                        column(Service_Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                        {
                        }
                        column(Service_Line_DescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(Service_LineCaption; Service_LineCaptionLbl)
                        {
                        }
                        column(Service_Line__Unit_Price_Caption; FieldCaption("Unit Price"))
                        {
                        }
                        column(Service_Line__Line_Discount___Caption; FieldCaption("Line Discount %"))
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(Gross_AmountCaption; Gross_AmountCaptionLbl)
                        {
                        }
                        column(Service_Line_QuantityCaption; FieldCaption(Quantity))
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }
                        dataitem(DimesionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            column(DimText_Control12; DimText)
                            {
                            }
                            column(DimesionLoop2_Number; Number)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Service Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        var
                            ExchangeFactor: Decimal;
                            SalesTaxCalculate: Codeunit "Sales Tax Calculate";
                            TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
                        begin
                            Amt := "Line Amount";
                            if "Service Header"."Currency Factor" = 0 then
                                ExchangeFactor := 1
                            else
                                ExchangeFactor := "Service Header"."Currency Factor";
                            SalesTaxCalculate.StartSalesTaxCalculation();
                            SalesTaxCalculate.AddServiceLine("Service Line");
                            SalesTaxCalculate.EndSalesTaxCalculation("Posting Date");
                            SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmountLine);
                            OnAfterCalculateSalesTax("Service Header", "Service Line", TempSalesTaxAmountLine);
                            GrossAmt := Amt + TempSalesTaxAmountLine.GetTotalTaxAmountFCY();

                            TotAmt := TotAmt + Amt;
                            TotGrossAmt := TotGrossAmt + GrossAmt;
                        end;
                    }
                    dataitem(Shipto; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
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
                        column(Shipto_Number; Number)
                        {
                        }
                        column(Ship_to_AddressCaption; Ship_to_AddressCaptionLbl)
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
                begin
                    TotAmt := 0;
                    TotGrossAmt := 0;

                    if Number > 1 then
                        CopyText := FormatDocument.GetCOPYText();
                    OutputNo += 1;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Service-Printed", "Service Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("Service Header");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");
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
                        ApplicationArea = Service;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Service;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the service quotes that you want to print as interactions and add them to the Interaction Log Entry table.';
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
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Service Quote") <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        ServiceSetup.Get();

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                CompanyInfo.CalcFields(Picture);
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

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Service Header".FindSet() then
                repeat
                    if "Service Header"."Contact No." <> '' then
                        SegManagement.LogDocument(25, "Service Header"."No.", 0, 0, DATABASE::Contact, "Service Header"."Contact No.",
                          "Service Header"."Salesperson Code", '', '', '')
                    else
                        SegManagement.LogDocument(25, "Service Header"."No.", 0, 0, DATABASE::Customer, "Service Header"."Customer No.",
                          "Service Header"."Salesperson Code", '', '', '');
                until "Service Header".Next() = 0;
    end;

    var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        ServiceSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        Number1: Integer;
        Number2: Integer;
        ShowInternalInfo: Boolean;
        ShowShippingAddr: Boolean;
        Continue: Boolean;
        CopyText: Text[30];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DimText: Text[120];
        OldDimText: Text[120];
        Amt: Decimal;
        TotAmt: Decimal;
        LogInteraction: Boolean;
        GrossAmt: Decimal;
        TotGrossAmt: Decimal;
        OutputNo: Integer;
        [InDataSet]
        LogInteractionEnable: Boolean;

        Text001: Label 'Service Quote %1';
        Text002: Label 'Page %1';
        Service_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Invoice_toCaptionLbl: Label 'Invoice to';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        Service_Header___Phone_No__CaptionLbl: Label 'Phone No.';
        Service_Header___E_Mail_CaptionLbl: Label 'Email';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Service_Item_LinesCaptionLbl: Label 'Service Item Lines';
        Fault_CommentsCaptionLbl: Label 'Fault Comments';
        Resolution_CommentsCaptionLbl: Label 'Resolution Comments';
        Service_LineCaptionLbl: Label 'Service Line';
        AmtCaptionLbl: Label 'Amount';
        Gross_AmountCaptionLbl: Label 'Gross Amount';
        TotalCaptionLbl: Label 'Total';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ServiceHeader: Record "Service Header")
    begin
        FormatAddr.GetCompanyAddr(ServiceHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.ServiceOrderSellto(CustAddr, ServiceHeader);
        ShowShippingAddr := ServiceHeader."Ship-to Code" <> '';
        if ShowShippingAddr then
            FormatAddr.ServiceOrderShipto(ShipToAddr, ServiceHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTax(var ServiceHeaderParm: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
    end;
}

