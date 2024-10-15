report 10082 "Return Receipt"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ReturnReceipt.rdlc';
    Caption = 'Return Receipt';

    dataset
    {
        dataitem("Return Receipt Header"; "Return Receipt Header")
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Ship-to Code", "No. Printed";
            RequestFilterHeading = 'Return Receipt';
            column(No_ReturnReceiptHeader; "No.")
            {
            }
            dataitem("Return Receipt Line"; "Return Receipt Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.");
                dataitem(SalesLineComments; "Sales Comment Line")
                {
                    DataItemLink = "No." = FIELD("Document No."), "Document Line No." = FIELD("Line No.");
                    DataItemTableView = SORTING("Document Type", "No.", "Document Line No.", "Line No.") WHERE("Document Type" = CONST("Posted Return Receipt"), "Print On Return Receipt" = CONST(true));

                    trigger OnAfterGetRecord()
                    begin
                        InsertTempLine(Comment, 10);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempReturnReceiptLine := "Return Receipt Line";
                    TempReturnReceiptLine.Insert();
                    HighestLineNo := "Line No.";
                end;

                trigger OnPreDataItem()
                begin
                    TempReturnReceiptLine.Reset();
                    TempReturnReceiptLine.DeleteAll();
                end;
            }
            dataitem("Sales Comment Line"; "Sales Comment Line")
            {
                DataItemLink = "No." = FIELD("No.");
                DataItemTableView = SORTING("Document Type", "No.", "Document Line No.", "Line No.") WHERE("Document Type" = CONST("Posted Return Receipt"), "Print On Return Receipt" = CONST(true), "Document Line No." = CONST(0));

                trigger OnAfterGetRecord()
                begin
                    InsertTempLine(Comment, 1000);
                end;

                trigger OnPreDataItem()
                begin
                    with TempReturnReceiptLine do begin
                        Init;
                        "Document No." := "Return Receipt Header"."No.";
                        "Line No." := HighestLineNo + 1000;
                        HighestLineNo := "Line No.";
                    end;
                    TempReturnReceiptLine.Insert();
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(CompanyAddress1; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress2; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress3; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress4; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress5; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddress6; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BillToAddress1; BillToAddress[1])
                    {
                    }
                    column(BillToAddress2; BillToAddress[2])
                    {
                    }
                    column(BillToAddress3; BillToAddress[3])
                    {
                    }
                    column(BillToAddress4; BillToAddress[4])
                    {
                    }
                    column(BillToAddress5; BillToAddress[5])
                    {
                    }
                    column(BillToAddress6; BillToAddress[6])
                    {
                    }
                    column(BillToAddress7; BillToAddress[7])
                    {
                    }
                    column(ShipToAddress1; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddress2; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddress3; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddress4; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddress5; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddress6; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddress7; ShipToAddress[7])
                    {
                    }
                    column(ReturnReceiptHeaderBillToCustNo; "Return Receipt Header"."Bill-to Customer No.")
                    {
                    }
                    column(ReturnReceiptHeaderYourRef; "Return Receipt Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(ReturnReceiptHeaderNo; "Return Receipt Header"."No.")
                    {
                    }
                    column(ReturnReceiptHeaderShipmentDate; "Return Receipt Header"."Shipment Date")
                    {
                    }
                    column(CompanyAddress7; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress8; CompanyAddress[8])
                    {
                    }
                    column(BillToAddress8; BillToAddress[8])
                    {
                    }
                    column(ShipToAddress8; ShipToAddress[8])
                    {
                    }
                    column(ShipmentMethodDescription; ShipmentMethod.Description)
                    {
                    }
                    column(ReturnReceiptHeaderOrderDate; "Return Receipt Header"."Order Date")
                    {
                    }
                    column(ReturnReceiptHeaderReturnOrderNo; "Return Receipt Header"."Return Order No.")
                    {
                    }
                    column(TaxRegLabel; TaxRegLabel)
                    {
                    }
                    column(TaxRegNo; TaxRegNo)
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(BillCaption; BillCaptionLbl)
                    {
                    }
                    column(ToCaption; ToCaptionLbl)
                    {
                    }
                    column(CustomerIDCaption; CustomerIDCaptionLbl)
                    {
                    }
                    column(PONumberCaption; PONumberCaptionLbl)
                    {
                    }
                    column(SalesPersonCaption; SalesPersonCaptionLbl)
                    {
                    }
                    column(ShipCaption; ShipCaptionLbl)
                    {
                    }
                    column(ReturnRecptCaption; ReturnReceiptCaptionLbl)
                    {
                    }
                    column(ReturnReceiptNumberCaption; ReturnReceiptNumberCaptionLbl)
                    {
                    }
                    column(ReturnReceiptDateCaption; ReturnReceiptDateCaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    column(ShipViaCaption; ShipViaCaptionLbl)
                    {
                    }
                    column(PODateCaption; PODateCaptionLbl)
                    {
                    }
                    column(RetAuthNoCaption; RetAuthNoCaptionLbl)
                    {
                    }
                    dataitem(RetRcptLine; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        column(TempReturnReceiptLineNo; TempReturnReceiptLine."No.")
                        {
                        }
                        column(TempReturnReceiptLineUOM; TempReturnReceiptLine."Unit of Measure")
                        {
                        }
                        column(TempReturnReceiptLineQuantity; TempReturnReceiptLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(OrderedQuantity; OrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(BackOrderedQuantity; BackOrderedQuantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempReturnReceiptLineDescription2; TempReturnReceiptLine.Description + ' ' + TempReturnReceiptLine."Description 2")
                        {
                        }
                        column(ItemNoCaption; ItemNoCaptionLbl)
                        {
                        }
                        column(UnitCaption; UnitCaptionLbl)
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        column(ReceivedCaption; ReceivedCaptionLbl)
                        {
                        }
                        column(AuthorizedCaption; AuthorizedCaptionLbl)
                        {
                        }
                        column(RemainingExpectedCaption; RemainingExpectedCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;

                            with TempReturnReceiptLine do begin
                                if OnLineNumber = 1 then
                                    Find('-')
                                else
                                    Next;

                                OrderedQuantity := 0;
                                BackOrderedQuantity := 0;
                                if "Return Order No." = '' then
                                    OrderedQuantity := Quantity
                                else
                                    if OrderLine.Get(5, "Return Order No.", "Return Order Line No.") then begin
                                        OrderedQuantity := OrderLine.Quantity;
                                        BackOrderedQuantity := OrderLine."Outstanding Quantity";
                                    end else begin
                                        ReceiptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                                        ReceiptLine.SetRange("Return Order No.", "Return Order No.");
                                        ReceiptLine.SetRange("Return Order Line No.", "Return Order Line No.");
                                        ReceiptLine.Find('-');
                                        repeat
                                            OrderedQuantity := OrderedQuantity + ReceiptLine.Quantity;
                                        until 0 = ReceiptLine.Next;
                                    end;

                                if Type = Type::" " then begin
                                    OrderedQuantity := 0;
                                    BackOrderedQuantity := 0;
                                    "No." := '';
                                    "Unit of Measure" := '';
                                    Quantity := 0;
                                end else
                                    if Type = Type::"G/L Account" then
                                        "No." := '';
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            NumberOfLines := TempReturnReceiptLine.Count();
                            SetRange(Number, 1, NumberOfLines);
                            OnLineNumber := 0;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            ReturnReceiptPrinted.Run("Return Receipt Header");
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
                    NoLoops := 1 + Abs(NoCopies);
                    if NoLoops <= 0 then
                        NoLoops := 1;
                    CopyNo := 0;

                    CurrentCopiesNo := CurrentCopiesNo + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                if PrintCompany then
                    if RespCenter.Get("Responsibility Center") then begin
                        FormatAddress.RespCenter(CompanyAddress, RespCenter);
                        CompanyInformation."Phone No." := RespCenter."Phone No.";
                        CompanyInformation."Fax No." := RespCenter."Fax No.";
                    end;

                FormatDocumentFields("Return Receipt Header");

                FormatAddress.SalesRcptBillTo(BillToAddress, BillToAddress, "Return Receipt Header");
                FormatAddress.SalesRcptShipTo(ShipToAddress, "Return Receipt Header");

                if LogInteraction then
                    if not CurrReport.Preview then
                        SegManagement.LogDocument(
                          20, "No.", 0, 0, DATABASE::Customer, "Sell-to Customer No.",
                          "Salesperson Code", "Campaign No.", "Posting Description", '');

                TaxRegNo := '';
                TaxRegLabel := '';
                if "Tax Area Code" <> '' then begin
                    TaxArea.Get("Tax Area Code");
                    case TaxArea."Country/Region" of
                        TaxArea."Country/Region"::US:
                            ;
                        TaxArea."Country/Region"::CA:
                            begin
                                TaxRegNo := CompanyInformation."VAT Registration No.";
                                TaxRegLabel := CompanyInformation.FieldCaption("VAT Registration No.");
                            end;
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInformation.Get();
                if PrintCompany then
                    FormatAddress.Company(CompanyAddress, CompanyInformation)
                else
                    Clear(CompanyAddress);
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(PrintCompany; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the related interactions with the involved contact person in the Interaction Log Entry table.';
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

    trigger OnInitReport()
    begin
        CurrentCopiesNo := 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        OrderedQuantity: Decimal;
        BackOrderedQuantity: Decimal;
        ShipmentMethod: Record "Shipment Method";
        ReceiptLine: Record "Return Receipt Line";
        OrderLine: Record "Sales Line";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        TempReturnReceiptLine: Record "Return Receipt Line" temporary;
        RespCenter: Record "Responsibility Center";
        TaxArea: Record "Tax Area";
        Language: Codeunit Language;
        ReturnReceiptPrinted: Codeunit "Return Receipt - Printed";
        FormatAddress: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        SalespersonText: Text[50];
        PrintCompany: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        HighestLineNo: Integer;
        SpacePointer: Integer;
        Text000: Label 'COPY';
        LogInteraction: Boolean;
        TaxRegNo: Text[30];
        TaxRegLabel: Text;
        CurrentCopiesNo: Integer;
        [InDataSet]
        LogInteractionEnable: Boolean;
        BillCaptionLbl: Label 'Bill';
        ToCaptionLbl: Label 'To:';
        CustomerIDCaptionLbl: Label 'Customer ID';
        PONumberCaptionLbl: Label 'P.O. Number';
        SalesPersonCaptionLbl: Label 'SalesPerson';
        ShipCaptionLbl: Label 'Ship';
        ReturnReceiptCaptionLbl: Label 'RETURN RECEIPT';
        ReturnReceiptNumberCaptionLbl: Label 'Return Receipt Number:';
        ReturnReceiptDateCaptionLbl: Label 'Return Receipt Date:';
        PageCaptionLbl: Label 'Page:';
        ShipViaCaptionLbl: Label 'Ship Via';
        PODateCaptionLbl: Label 'P.O. Date';
        RetAuthNoCaptionLbl: Label 'Ret. Auth. No.';
        ItemNoCaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        ReceivedCaptionLbl: Label 'Received';
        AuthorizedCaptionLbl: Label 'Authorized';
        RemainingExpectedCaptionLbl: Label 'Remaining Expected';

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractTmplCode(5) <> '';
    end;

    local procedure FormatDocumentFields(ReturnReceiptHeader: Record "Return Receipt Header")
    begin
        with ReturnReceiptHeader do begin
            FormatDocument.SetSalesPerson(SalesPurchPerson, "Salesperson Code", SalespersonText);
            if "Salesperson Code" = '' then
                Clear(SalesPurchPerson)
            else
                SalesPurchPerson.Get("Salesperson Code");

            if "Shipment Method Code" = '' then
                Clear(ShipmentMethod)
            else
                ShipmentMethod.Get("Shipment Method Code");
        end;
    end;

    local procedure InsertTempLine(Comment: Text[80]; IncrNo: Integer)
    begin
        with TempReturnReceiptLine do begin
            Init;
            "Document No." := "Return Receipt Header"."No.";
            "Line No." := HighestLineNo + IncrNo;
            HighestLineNo := "Line No.";
        end;
        if StrLen(Comment) <= MaxStrLen(TempReturnReceiptLine.Description) then begin
            TempReturnReceiptLine.Description := CopyStr(Comment, 1, MaxStrLen(TempReturnReceiptLine.Description));
            TempReturnReceiptLine."Description 2" := '';
        end else begin
            SpacePointer := MaxStrLen(TempReturnReceiptLine.Description) + 1;
            while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                SpacePointer := SpacePointer - 1;
            if SpacePointer = 1 then
                SpacePointer := MaxStrLen(TempReturnReceiptLine.Description) + 1;
            TempReturnReceiptLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
            TempReturnReceiptLine."Description 2" :=
              CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempReturnReceiptLine."Description 2"));
        end;
        TempReturnReceiptLine.Insert();
    end;
}

