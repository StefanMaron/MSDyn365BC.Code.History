report 14950 "Job Ticket"
{
    Caption = 'Job Ticket';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
        }
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
        }
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control1210004)
                {
                    ShowCaption = false;
                    field(ItemDescription; ItemDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Description';
                    }
                    field(VehicleDescription; VehicleDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vehicle Description';
                    }
                    field(VehicleRegistrationNo; VehicleDescriptionRegNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vehicle Registration No.';
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

    trigger OnPostReport()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentTemplate: Record "Excel Template";
        [RunOnClient]
        wrdApp: DotNet ApplicationClass;
        [RunOnClient]
        wrdDoc: DotNet DocumentClass;
        [RunOnClient]
        WordHelper: DotNet WordHelper;
        FileName: Text[1024];
        ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment;
    begin
        if not DefineReportSource(ReportSource, SalesHeader) then
            exit;

        if ReportSource = ReportSource::UnpostedSales then
            SalesHeader.TestField(Status, SalesHeader.Status::Released);

        SalesReceivablesSetup.Get;
        FileName := DocumentTemplate.OpenTemplate(SalesReceivablesSetup."Job Ticket Template Code");

        wrdApp := wrdApp.ApplicationClass;
        wrdDoc := WordHelper.CallOpen(wrdApp, FileName, false, false);

        FillBookmarks(wrdDoc, SalesHeader, ReportSource);
        wrdApp.Visible(true);
    end;

    var
        ItemDescription: Text[1024];
        VehicleDescription: Text[1024];
        VehicleDescriptionRegNo: Text[1024];

    [Scope('OnPrem')]
    procedure FillBookmarks(var wrdDoc: DotNet DocumentClass; SalesHeader: Record "Sales Header"; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment)
    var
        LocalReportManagement: Codeunit "Local Report Management";
        Quantity: Decimal;
        Weight: Decimal;
        Volume: Decimal;
    begin
        FillBookmark(wrdDoc, 'OrderDate', Format(SalesHeader."Order Date"));
        FillBookmark(wrdDoc, 'OrderNo', SalesHeader."No.");
        FillBookmark(wrdDoc, 'Vendor', GetVendorInfo(SalesHeader));
        FillBookmark(wrdDoc, 'ResponsiblePerson', GetResponsiblePersonInfo(SalesHeader, ReportSource));
        FillBookmark(wrdDoc, 'ShippingAgent', GetShippingAgentName(SalesHeader));

        FillBookmark(wrdDoc, 'ItemDescription', ItemDescription);
        GetLinesInfo(SalesHeader, Quantity, Weight, Volume, ReportSource);
        FillBookmark(wrdDoc, 'Quantity', Format(Quantity));
        FillBookmark(
          wrdDoc, 'NetWeight',
          LocalReportManagement.FormatReportValue(Weight, 2) + ',  ,' +
          LocalReportManagement.FormatReportValue(Volume, 2));

        FillBookmark(wrdDoc, 'VehicleDescription', VehicleDescription);
        FillBookmark(wrdDoc, 'VehicleDescriptionRegNo', VehicleDescriptionRegNo);
    end;

    [Scope('OnPrem')]
    procedure FillBookmark(var wrdDoc: DotNet DocumentClass; BookmarkName: Text[250]; TextValue: Text[1024])
    var
        [RunOnClient]
        wrdBookmark: DotNet Bookmark;
        [RunOnClient]
        Enumerator: DotNet IEnumerator;
    begin
        Enumerator := wrdDoc.Bookmarks.GetEnumerator();
        while Enumerator.MoveNext do begin
            wrdBookmark := Enumerator.Current;
            if wrdBookmark.Name = BookmarkName then begin
                wrdBookmark.Range.Text(TextValue);
                exit;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVendorInfo(SalesHeader: Record "Sales Header"): Text[250]
    var
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        if SalesHeader."Consignor No." = '' then
            exit(LocalReportManagement.GetCompanyName + '. ' + LocalReportManagement.GetLegalAddress);
        exit(LocalReportManagement.GetConsignerInfo(SalesHeader."Consignor No.", SalesHeader."Responsibility Center"));
    end;

    [Scope('OnPrem')]
    procedure GetShippingAgentName(SalesHeader: Record "Sales Header"): Text[250]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShippingAgent.Get(SalesHeader."Shipping Agent Code") then
            exit(ShippingAgent.Name);
    end;

    [Scope('OnPrem')]
    procedure GetResponsiblePersonInfo(SalesHeader: Record "Sales Header"; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment): Text[250]
    var
        Employee: Record Employee;
        DocumentSignature: Record "Document Signature";
        PostedDocumentSignature: Record "Posted Document Signature";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        case ReportSource of
            ReportSource::UnpostedSales:
                begin
                    if not DocumentSignature.Get(
                         DATABASE::"Sales Header",
                         SalesHeader."Document Type",
                         SalesHeader."No.",
                         DocumentSignature."Employee Type"::Responsible)
                    then
                        exit('');
                    if not Employee.Get(DocumentSignature."Employee No.") then
                        exit('');
                end;
            ReportSource::SalesInvoice:
                begin
                    if not PostedDocumentSignature.Get(
                         DATABASE::"Sales Invoice Header",
                         0,
                         SalesHeader."No.",
                         DocumentSignature."Employee Type"::Responsible)
                    then
                        exit('');
                    if not Employee.Get(PostedDocumentSignature."Employee No.") then
                        exit('');
                end;
            ReportSource::SalesShipment:
                begin
                    if not PostedDocumentSignature.Get(
                         DATABASE::"Sales Shipment Header",
                         0,
                         SalesHeader."No.",
                         DocumentSignature."Employee Type"::Responsible)
                    then
                        exit('');
                    if not Employee.Get(PostedDocumentSignature."Employee No.") then
                        exit('');
                end;
        end;

        exit(
          LocalReportManagement.GetEmpName(Employee."No.") + ' ' +
          Employee."Phone No." + ' ' +
          Employee."Mobile Phone No.");
    end;

    [Scope('OnPrem')]
    procedure GetLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal; ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment)
    begin
        case ReportSource of
            ReportSource::UnpostedSales:
                GetSalesLinesInfo(SalesHeader, Quantity, Weight, Volume);
            ReportSource::SalesInvoice:
                GetInvoiceLinesInfo(SalesHeader, Quantity, Weight, Volume);
            ReportSource::SalesShipment:
                GetShipmentLinesInfo(SalesHeader, Quantity, Weight, Volume);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSalesLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        if SalesLine.FindSet then
            repeat
                Quantity += SalesLine."Qty. to Ship";
                Weight += SalesLine."Qty. to Ship" * SalesLine."Net Weight";
                Volume += SalesLine."Qty. to Ship" * SalesLine."Unit Volume";
            until SalesLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetInvoiceLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesHeader."No.");

        if SalesInvoiceLine.FindSet then
            repeat
                Quantity += SalesInvoiceLine.Quantity;
                Weight += SalesInvoiceLine.Quantity * SalesInvoiceLine."Net Weight";
                Volume += SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Volume";
            until SalesInvoiceLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure GetShipmentLinesInfo(SalesHeader: Record "Sales Header"; var Quantity: Decimal; var Weight: Decimal; var Volume: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", SalesHeader."No.");

        if SalesShipmentLine.FindSet then
            repeat
                Quantity += SalesShipmentLine.Quantity;
                Weight += SalesShipmentLine.Quantity * SalesShipmentLine."Net Weight";
                Volume += SalesShipmentLine.Quantity * SalesShipmentLine."Unit Volume";
            until SalesShipmentLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure DefineReportSource(var ReportSource: Option UnpostedSales,SalesInvoice,SalesShipment; var SalesHeader: Record "Sales Header"): Boolean
    begin
        if "Sales Header".GetFilters <> '' then begin
            ReportSource := ReportSource::UnpostedSales;
            SalesHeader := "Sales Header";
        end else
            if "Sales Invoice Header".GetFilters <> '' then begin
                ReportSource := ReportSource::SalesInvoice;
                SalesHeader.TransferFields("Sales Invoice Header");
            end else
                if "Sales Shipment Header".GetFilters <> '' then begin
                    ReportSource := ReportSource::SalesShipment;
                    SalesHeader.TransferFields("Sales Shipment Header");
                end else
                    exit(false);
        exit(true);
    end;
}

