report 12484 "Posted Cr. M. Factura-Invoice"
{
    Caption = 'Posted Cr. M. Factura-Invoice';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Header; "Sales Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            dataitem(CopyCycle; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(LineCycle; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    dataitem(AttachedLineCycle; "Integer")
                    {
                        DataItemTableView = SORTING(Number);

                        trigger OnAfterGetRecord()
                        var
                            LineValues: array[13] of Text;
                        begin
                            if Number = 1 then
                                AttachedSalesLine.FindSet
                            else
                                AttachedSalesLine.Next;

                            CopyArray(LastTotalAmount, TotalAmount, 1);
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, AttachedSalesLine.Description);
                            FillBody(LineValues);
                        end;

                        trigger OnPreDataItem()
                        begin
                            AttachedSalesLine.SetRange("Attached to Line No.", SalesLine1."Line No.");
                            SetRange(Number, 1, AttachedSalesLine.Count);
                        end;
                    }
                    dataitem(ItemTrackingLine; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));

                        trigger OnAfterGetRecord()
                        var
                            LineValues: array[13] of Text;
                        begin
                            if Header."Prepayment Credit Memo" then
                                CurrReport.Break();

                            if Number = 1 then
                                TrackingSpecBuffer2.FindSet
                            else
                                TrackingSpecBuffer2.Next;

                            if CDNoInfo.Get(
                                 CDNoInfo.Type::Item, TrackingSpecBuffer2."Item No.", TrackingSpecBuffer2."Variant Code", TrackingSpecBuffer2."CD No.")
                            then begin
                                CountryName := CDNoInfo.GetCountryName;
                                CountryCode := CDNoInfo.GetCountryLocalCode;
                            end;

                            CopyArray(LastTotalAmount, TotalAmount, 1);
                            FacturaInvoiceHelper.TransferItemTrLineValues(LineValues, TrackingSpecBuffer2, CountryCode, CountryName, Sign);
                            FillBody(LineValues);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not MultipleCD then
                                CurrReport.Break();

                            SetRange(Number, 1, TrackingSpecCount);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        LineValues: array[13] of Text;
                    begin
                        if Number = 1 then begin
                            if not SalesLine1.Find('-') then
                                CurrReport.Break();
                        end else
                            if SalesLine1.Next(1) = 0 then begin
                                FacturaInvoiceHelper.FormatTotalAmounts(
                                  TotalAmountText, TotalAmount, Sign, Header."Prepayment Credit Memo", VATExemptTotal);
                                CurrReport.Break();
                            end;

                        CopyArray(LastTotalAmount, TotalAmount, 1);

                        if SalesLine1.Type <> SalesLine1.Type::" " then begin
                            if SalesLine1.Quantity = 0 then
                                CurrReport.Skip();
                            if AmountInvoiceCurrent = AmountInvoiceCurrent::LCY then begin
                                SalesLine1.Amount := SalesLine1."Amount (LCY)";
                                SalesLine1."Amount Including VAT" := SalesLine1."Amount Including VAT (LCY)";
                            end;
                            SalesLine1."Unit Price" :=
                              Round(SalesLine1.Amount / SalesLine1.Quantity, Currency."Unit-Amount Rounding Precision");
                            IncrAmount(SalesLine1);
                        end else
                            SalesLine1."No." := '';

                        RetrieveCDSpecification;

                        if Header."Prepayment Credit Memo" then
                            LastTotalAmount[1] := 0;

                        if SalesLine1.Type = SalesLine1.Type::" " then
                            FacturaInvoiceHelper.TransferLineDescrValues(LineValues, SalesLine1.Description)
                        else
                            TransferReportValues(LineValues, SalesLine1, CountryName, CDNo, CountryCode);

                        FillBody(LineValues);
                    end;

                    trigger OnPostDataItem()
                    var
                        ResponsiblePerson: array[2] of Text;
                    begin
                        FillRespPerson(ResponsiblePerson);
                        FacturaInvoiceHelper.FinalizeReport(TotalAmountText, ResponsiblePerson, false);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AmountInvoiceCurrent = AmountInvoiceCurrent::"Invoice Currency") and (Header."Currency Code" <> '') then
                            Currency.Get(Header."Currency Code")
                        else
                            Currency.InitRoundingPrecision;

                        VATExemptTotal := true;

                        FillHeader;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(TotalAmount);
                end;

                trigger OnPostDataItem()
                begin
                    if not Preview then
                        CODEUNIT.Run(CODEUNIT::"Sales Cr. Memo-Printed", Header);
                end;

                trigger OnPreDataItem()
                begin
                    if not SalesLine1.Find('-') then
                        CurrReport.Break();

                    SetRange(Number, 1, CopiesNumber);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Customer.Get("Bill-to Customer No.");

                AmountInvoiceCurrent := AmountInvoiceDone;
                if "Currency Code" = '' then
                    AmountInvoiceCurrent := AmountInvoiceCurrent::LCY;

                Sign := -1;
                SalesLine1.Reset();
                SalesLine1.SetRange("Document No.", "No.");
                SalesLine1.SetFilter("Attached to Line No.", '<>%1', 0);
                if SalesLine1.FindSet then
                    repeat
                        AttachedSalesLine := SalesLine1;
                        AttachedSalesLine.Insert();
                    until SalesLine1.Next = 0;

                SalesLine1.SetRange("Attached to Line No.", 0);

                if "Currency Code" <> '' then begin
                    if not Currency.Get("Currency Code") then
                        Currency.Description := DollarUSATxt;
                end;

                CurrencyWrittenAmount := FacturaInvoiceHelper.GetCurrencyAmtCode("Currency Code", AmountInvoiceCurrent);
                FacturaInvoiceHelper.GetCurrencyInfo(CurrencyWrittenAmount, CurrencyDigitalCode, CurrencyDescription);

                if "Prepayment Credit Memo" or PrintShortAddr("No.") then
                    FacturaInvoiceHelper.InitAddressInfo(ConsignorName, ConsignorAddress, Receiver)
                else begin
                    Receiver[1] := StdRepMgt.GetCustInfo(Header, 0, 1);
                    Receiver[2] := StdRepMgt.GetCustInfo(Header, 1, 1);
                    FacturaInvoiceHelper.GetConsignorInfo("Consignor No.", ConsignorName, ConsignorAddress);
                end;

                if "KPP Code" <> '' then
                    KPPCode := "KPP Code"
                else
                    KPPCode := Customer."KPP Code";

                if "Prepayment Credit Memo" then
                    PrepmtDocsLine := StrSubstNo(PrepaymentTxt, "External Document Text", "Posting Date")
                else
                    CollectPrepayments(PrepmtDocsLine);

                ItemTrackingDocMgt.RetrieveDocumentItemTracking(
                  TrackingSpecBuffer, "No.", DATABASE::"Sales Cr.Memo Header", 0);

                if LogInteraction then
                    if not Preview then begin
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              6, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              6, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                              "Campaign No.", "Posting Description", '');
                    end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
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
                    field(CopiesNumber; CopiesNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';

                        trigger OnValidate()
                        begin
                            if CopiesNumber < 1 then
                                CopiesNumber := 1;
                        end;
                    }
                    field(AmountInvoiceDone; AmountInvoiceDone)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Currency';
                        OptionCaption = 'Invoice Currency,LCY';
                        ToolTip = 'Specifies if the currency code is shown in the report.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        ToolTip = 'Specifies that interactions with the related contact are logged.';
                    }
                    field(Preview; Preview)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if CopiesNumber < 1 then
                CopiesNumber := 1;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            FacturaInvoiceHelper.ExportDataFile(FileName)
        else
            FacturaInvoiceHelper.ExportData;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            CopiesNumber := 1;

        SalesSetup.Get();
        SalesSetup.TestField("Factura Template Code");
        FacturaInvoiceHelper.InitReportTemplate(SalesSetup."Factura Template Code");
    end;

    var
        DollarUSATxt: Label 'US Dollar';
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        SalesLine1: Record "Sales Cr.Memo Line";
        AttachedSalesLine: Record "Sales Cr.Memo Line" temporary;
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        CDNoInfo: Record "CD No. Information";
        TrackingSpecBuffer: Record "Tracking Specification" temporary;
        TrackingSpecBuffer2: Record "Tracking Specification" temporary;
        UoM: Record "Unit of Measure";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        SegManagement: Codeunit SegManagement;
        FacturaInvoiceHelper: Codeunit "Factura-Invoice Report Helper";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        CurrencyDescription: Text;
        TotalAmount: array[8] of Decimal;
        LastTotalAmount: array[8] of Decimal;
        CopiesNumber: Integer;
        AmountInvoiceDone: Option "Invoice Currency",LCY;
        AmountInvoiceCurrent: Option "Invoice Currency",LCY;
        MultipleCD: Boolean;
        CurrencyWrittenAmount: Code[20];
        ConsignorName: Text;
        ConsignorAddress: Text;
        Sign: Decimal;
        CountryCode: Code[10];
        CountryName: Text;
        LogInteraction: Boolean;
        CDNo: Text;
        KPPCode: Code[10];
        PrepmtDocsLine: Text;
        PrepaymentTxt: Label '%1 from %2', Comment = '%1 «Ô %2';
        Receiver: array[2] of Text;
        VATExemptTotal: Boolean;
        TotalAmountText: array[3] of Text;
        TrackingSpecCount: Integer;
        CurrencyDigitalCode: Code[3];
        Preview: Boolean;
        FileName: Text;

    [Scope('OnPrem')]
    procedure IncrAmount(SalesLine2: Record "Sales Cr.Memo Line")
    begin
        with SalesLine2 do begin
            TotalAmount[1] := TotalAmount[1] + Amount;
            TotalAmount[2] := TotalAmount[2] + "Amount Including VAT" - Amount;
            TotalAmount[3] := TotalAmount[3] + "Amount Including VAT";
        end;
    end;

    [Scope('OnPrem')]
    procedure CollectPrepayments(var PrepmtList: Text)
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        Delimiter: Text;
    begin
        PrepmtList := '';
        Delimiter := ' ';
        Customer.CollectPrepayments(Header."Sell-to Customer No.", Header."No.", TempCustLedgEntry);
        if TempCustLedgEntry.FindSet then
            repeat
                PrepmtList :=
                  PrepmtList + Delimiter +
                  StrSubstNo(PrepaymentTxt, TempCustLedgEntry."External Document No.", TempCustLedgEntry."Posting Date");
                Delimiter := ', ';
            until TempCustLedgEntry.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[13] of Text; SalesLine2: Record "Sales Cr.Memo Line"; CountryName2: Text; CDNo2: Text; CountryCode2: Code[10])
    begin
        ReportValues[1] := SalesLine2.Description;
        ReportValues[2] := '-';
        if Header."Prepayment Credit Memo" then begin
            ReportValues[3] := '-';
            ReportValues[4] := '-';
            ReportValues[5] := '-';
            ReportValues[6] := '-';
            ReportValues[7] := Format(SalesLine2."VAT %") + '/' + Format(100 + SalesLine2."VAT %");
            ReportValues[8] :=
              StdRepMgt.FormatReportValue(Sign * (SalesLine2."Amount Including VAT" - SalesLine2.Amount), 2);
            ReportValues[9] := StdRepMgt.FormatReportValue(Sign * SalesLine2."Amount Including VAT", 2);
            ReportValues[10] := '-';
            ReportValues[11] := '-';
            ReportValues[12] := '-';
        end else begin
            if UoM.Get(SalesLine2."Unit of Measure Code") then
                ReportValues[2] := StdRepMgt.FormatTextValue(UoM."OKEI Code");
            ReportValues[3] := StdRepMgt.FormatTextValue(SalesLine2."Unit of Measure Code");
            ReportValues[4] := Format(Sign * SalesLine2.Quantity);
            ReportValues[5] := StdRepMgt.FormatReportValue(SalesLine2."Unit Price", 2);
            ReportValues[6] := StdRepMgt.FormatReportValue(Sign * SalesLine2.Amount, 2);
            ReportValues[7] := Format(SalesLine1."VAT %");
            ReportValues[8] :=
              StdRepMgt.FormatReportValue(Sign * (SalesLine2."Amount Including VAT" - SalesLine2.Amount), 2);
            ReportValues[9] := StdRepMgt.FormatReportValue(Sign * SalesLine2."Amount Including VAT", 2);
            ReportValues[10] := StdRepMgt.FormatTextValue(CountryCode2);
            ReportValues[11] := StdRepMgt.FormatTextValue(CountryName2);
            ReportValues[12] := StdRepMgt.FormatTextValue(CDNo2);
        end;

        if StdRepMgt.VATExemptLine(SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group") then
            StdRepMgt.FormatVATExemptLine(ReportValues[7], ReportValues[8])
        else
            VATExemptTotal := false;

        ReportValues[13] := StdRepMgt.GetEAEUItemTariffNo_SalesCrMemoLine(SalesLine2);
    end;

    [Scope('OnPrem')]
    procedure TransferHeaderValues(var HeaderValue: array[12] of Text)
    begin
        HeaderValue[1] := StdRepMgt.GetCompanyName;
        HeaderValue[2] := StdRepMgt.GetLegalAddress;
        HeaderValue[3] := CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code";
        HeaderValue[4] := ConsignorName + '  ' + ConsignorAddress;
        HeaderValue[5] := Receiver[1] + ' ' + Receiver[2];
        HeaderValue[6] := Header."External Document Text";
        HeaderValue[7] := StdRepMgt.GetCustInfo(Header, 0, 2);
        HeaderValue[8] := StdRepMgt.GetCustInfo(Header, 1, 2);
        HeaderValue[9] := Customer."VAT Registration No." + '/' + KPPCode;
        HeaderValue[10] := CurrencyDigitalCode;
        HeaderValue[11] := CurrencyDescription;
    end;

    [Scope('OnPrem')]
    procedure PrintShortAddr(DocNo: Code[20]): Boolean
    var
        SalesInvLine: Record "Sales Cr.Memo Line";
    begin
        SalesInvLine.SetRange("Document No.", DocNo);
        SalesInvLine.SetFilter(Type, '%1|%2', SalesInvLine.Type::Item, SalesInvLine.Type::"Fixed Asset");
        SalesInvLine.SetFilter("No.", '<>''''');
        SalesInvLine.SetFilter(Quantity, '<>0');
        exit(SalesInvLine.IsEmpty);
    end;

    local procedure RetrieveCDSpecification()
    begin
        MultipleCD := false;
        CDNo := '';
        CountryName := '-';
        CountryCode := '';

        case SalesLine1.Type of
            SalesLine1.Type::Item:
                begin
                    TrackingSpecBuffer.Reset();
                    TrackingSpecBuffer.SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
                      "Source Prod. Order Line", "Source Ref. No.");
                    TrackingSpecBuffer.SetRange("Source Type", DATABASE::"Sales Cr.Memo Line");
                    TrackingSpecBuffer.SetRange("Source Subtype", 0);
                    TrackingSpecBuffer.SetRange("Source ID", SalesLine1."Document No.");
                    TrackingSpecBuffer.SetRange("Source Ref. No.", SalesLine1."Line No.");
                    TrackingSpecBuffer2.DeleteAll();
                    if TrackingSpecBuffer.FindSet then
                        repeat
                            TrackingSpecBuffer2.SetRange("CD No.", TrackingSpecBuffer."CD No.");
                            if TrackingSpecBuffer2.FindFirst then begin
                                TrackingSpecBuffer2."Quantity (Base)" += TrackingSpecBuffer."Quantity (Base)";
                                TrackingSpecBuffer2.Modify();
                            end else begin
                                TrackingSpecBuffer2.Init();
                                TrackingSpecBuffer2 := TrackingSpecBuffer;
                                TrackingSpecBuffer2.TestField("Quantity (Base)");
                                TrackingSpecBuffer2."Lot No." := '';
                                TrackingSpecBuffer2."Serial No." := '';
                                TrackingSpecBuffer2.Insert();
                            end;
                        until TrackingSpecBuffer.Next = 0;
                    TrackingSpecBuffer2.Reset();
                    TrackingSpecCount := TrackingSpecBuffer2.Count();
                    case TrackingSpecCount of
                        1:
                            begin
                                TrackingSpecBuffer2.FindFirst;
                                CDNo := TrackingSpecBuffer2."CD No.";
                                if CDNoInfo.Get(
                                     CDNoInfo.Type::Item, TrackingSpecBuffer2."Item No.",
                                     TrackingSpecBuffer2."Variant Code", TrackingSpecBuffer2."CD No.")
                                then begin
                                    CountryName := CDNoInfo.GetCountryName;
                                    CountryCode := CDNoInfo.GetCountryLocalCode;
                                end;
                            end;
                        else
                            MultipleCD := true;
                    end;
                end;
            SalesLine1.Type::"Fixed Asset":
                FacturaInvoiceHelper.GetFAInfo(SalesLine1."No.", CDNo, CountryName);
        end;
    end;

    local procedure FillDocHeader(var DocNo: Code[20]; var DocDate: Text; var RevNo: Code[20]; var RevDate: Text)
    var
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        with Header do
            if "Corrective Doc. Type" = "Corrective Doc. Type"::Revision then begin
                case "Original Doc. Type" of
                    "Original Doc. Type"::Invoice:
                        DocDate := LocMgt.Date2Text(CorrDocMgt.GetSalesInvHeaderPostingDate("Original Doc. No."));
                    "Original Doc. Type"::"Credit Memo":
                        DocDate := LocMgt.Date2Text(CorrDocMgt.GetSalesCrMHeaderPostingDate("Original Doc. No."));
                end;
                DocNo := "Original Doc. No.";
                RevNo := "Revision No.";
                RevDate := LocMgt.Date2Text("Document Date");
            end else begin
                DocNo := "No.";
                DocDate := LocMgt.Date2Text("Document Date");
                RevNo := '-';
                RevDate := '-';
            end;
    end;

    local procedure FillHeader()
    var
        DocNo: Code[20];
        RevNo: Code[20];
        DocDate: Text;
        RevDate: Text;
        HeaderValues: array[12] of Text;
    begin
        FillDocHeader(DocNo, DocDate, RevNo, RevDate);
        TransferHeaderValues(HeaderValues);

        FacturaInvoiceHelper.FillHeader(DocNo, DocDate, RevNo, RevDate, HeaderValues);
    end;

    local procedure FillBody(LineValue: array[13] of Text)
    begin
        FacturaInvoiceHelper.FillBody(LineValue, false);
    end;

    local procedure FillRespPerson(var ResponsiblePerson: array[2] of Text)
    begin
        ResponsiblePerson[1] := StdRepMgt.GetDirectorName(true, 112, 0, Header."No.");
        ResponsiblePerson[2] := StdRepMgt.GetAccountantName(true, 112, 0, Header."No.");
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

