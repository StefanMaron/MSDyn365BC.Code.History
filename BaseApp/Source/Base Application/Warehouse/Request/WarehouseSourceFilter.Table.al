namespace Microsoft.Warehouse.Request;

using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

table 5771 "Warehouse Source Filter"
{
    Caption = 'Warehouse Source Filter';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Item No. Filter"; Code[100])
        {
            Caption = 'Item No. Filter';
            TableRelation = Item;
            ValidateTableRelation = false;
        }
        field(4; "Variant Code Filter"; Code[100])
        {
            Caption = 'Variant Code Filter';
            TableRelation = "Item Variant".Code;
            ValidateTableRelation = false;
        }
        field(5; "Unit of Measure Filter"; Code[100])
        {
            Caption = 'Unit of Measure Filter';
            TableRelation = "Unit of Measure";
            ValidateTableRelation = false;
        }
        field(6; "Sell-to Customer No. Filter"; Code[100])
        {
            Caption = 'Sell-to Customer No. Filter';
            TableRelation = Customer;
            ValidateTableRelation = false;
        }
        field(7; "Buy-from Vendor No. Filter"; Code[100])
        {
            Caption = 'Buy-from Vendor No. Filter';
            TableRelation = Vendor;
            ValidateTableRelation = false;
        }
        field(8; "Customer No. Filter"; Code[100])
        {
            Caption = 'Customer No. Filter';
            TableRelation = Customer;
            ValidateTableRelation = false;
        }
        field(10; "Planned Delivery Date Filter"; Date)
        {
            Caption = 'Planned Delivery Date Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Shipment Method Code Filter"; Code[100])
        {
            Caption = 'Shipment Method Code Filter';
            TableRelation = "Shipment Method";
            ValidateTableRelation = false;
        }
        field(12; "Shipping Agent Code Filter"; Code[100])
        {
            Caption = 'Shipping Agent Code Filter';
            TableRelation = "Shipping Agent";
            ValidateTableRelation = false;
        }
        field(13; "Shipping Advice Filter"; Code[100])
        {
            Caption = 'Shipping Advice Filter';
        }
        field(15; "Do Not Fill Qty. to Handle"; Boolean)
        {
            Caption = 'Do Not Fill Qty. to Handle';
        }
        field(16; "Show Filter Request"; Boolean)
        {
            Caption = 'Show Filter Request';
        }
        field(17; "Shipping Agent Service Filter"; Code[100])
        {
            Caption = 'Shipping Agent Service Filter';
            TableRelation = "Shipping Agent Services".Code;
            ValidateTableRelation = false;
        }
        field(18; "In-Transit Code Filter"; Code[100])
        {
            Caption = 'In-Transit Code Filter';
            TableRelation = Location where("Use As In-Transit" = const(true));
            ValidateTableRelation = false;
        }
        field(19; "Transfer-from Code Filter"; Code[100])
        {
            Caption = 'Transfer-from Code Filter';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ValidateTableRelation = false;
        }
        field(20; "Transfer-to Code Filter"; Code[100])
        {
            Caption = 'Transfer-to Code Filter';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ValidateTableRelation = false;
        }
        field(21; "Planned Shipment Date Filter"; Date)
        {
            Caption = 'Planned Shipment Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Planned Receipt Date Filter"; Date)
        {
            Caption = 'Planned Receipt Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Expected Receipt Date Filter"; Date)
        {
            Caption = 'Expected Receipt Date Filter';
            FieldClass = FlowFilter;
        }
        field(24; "Shipment Date Filter"; Date)
        {
            Caption = 'Outbound Date Filter';
            FieldClass = FlowFilter;
        }
        field(25; "Receipt Date Filter"; Date)
        {
            Caption = 'Inbound Date Filter';
            FieldClass = FlowFilter;
        }
        field(28; "Sales Shipment Date Filter"; Date)
        {
            Caption = 'Sales Shipment Date Filter';
            FieldClass = FlowFilter;
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(96; "Reserved From Stock"; Enum "Reservation From Stock")
        {
            Caption = 'Reserved from Stock';
            ValuesAllowed = " ", "Full and Partial", Full;
        }
        field(98; "Source No. Filter"; Code[100])
        {
            Caption = 'Source No. Filter';
        }
        field(99; "Source Document"; Code[250])
        {
            Caption = 'Source Document';
        }
        field(100; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Inbound,Outbound';
            OptionMembers = Inbound,Outbound;

            trigger OnValidate()
            begin
                CheckType();
            end;
        }
        field(101; "Sales Orders"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Sales Orders';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Outbound then
                    CheckOutboundSourceDocumentChosen();
            end;
        }
        field(102; "Sales Return Orders"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Sales Return Orders';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Inbound then
                    CheckInboundSourceDocumentChosen();
            end;
        }
        field(103; "Purchase Orders"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Purchase Orders';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Inbound then
                    CheckInboundSourceDocumentChosen();
            end;
        }
        field(104; "Purchase Return Orders"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Purchase Return Orders';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Outbound then
                    CheckOutboundSourceDocumentChosen();
            end;
        }
        field(105; "Inbound Transfers"; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Inbound Transfers';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Inbound then
                    CheckInboundSourceDocumentChosen();
            end;
        }
        field(106; "Outbound Transfers"; Boolean)
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Outbound Transfers';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Outbound then
                    CheckOutboundSourceDocumentChosen();
            end;
        }
        field(108; Partial; Boolean)
        {
            Caption = 'Partial';
            InitValue = true;

            trigger OnValidate()
            begin
                if not Partial and not Complete then
                    Error(MustBeChosenErr, FieldCaption("Shipping Advice Filter"));
            end;
        }
        field(109; Complete; Boolean)
        {
            Caption = 'Complete';
            InitValue = true;

            trigger OnValidate()
            begin
                if not Partial and not Complete then
                    Error(MustBeChosenErr, FieldCaption("Shipping Advice Filter"));
            end;
        }
        field(1001; "Job Task No. Filter"; Code[100])
        {
            Caption = 'Project Task No. Filter';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ValidateTableRelation = false;
        }
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(7300; "Planned Delivery Date"; Text[250])
        {
            Caption = 'Planned Delivery Date';
        }
        field(7301; "Planned Shipment Date"; Text[250])
        {
            Caption = 'Planned Shipment Date';
        }
        field(7302; "Planned Receipt Date"; Text[250])
        {
            Caption = 'Planned Receipt Date';
        }
        field(7303; "Expected Receipt Date"; Text[250])
        {
            Caption = 'Expected Receipt Date';
        }
        field(7304; "Shipment Date"; Text[250])
        {
            Caption = 'Shipment Date';
        }
        field(7305; "Receipt Date"; Text[250])
        {
            Caption = 'Receipt Date';
        }
        field(7306; "Sales Shipment Date"; Text[250])
        {
            Caption = 'Sales Shipment Date';
        }
        field(99000754; "Prod. Order Line No. Filter"; Text[100])
        {
            Caption = 'Prod. Order Line No. Filter';
            TableRelation = "Prod. Order Line"."Line No." where(Status = filter(Released),
                                                                 "Prod. Order No." = field("Prod. Order No."));
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; Type, "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    protected var
        MustBeChosenErr: Label '%1 must be chosen.', Comment = '%1 - source type';

    procedure SetFilters(var GetSourceDocuments: Report "Get Source Documents"; LocationCode: Code[10])
    var
        WhseRequest: Record "Warehouse Request";
#if not CLEAN23
        SalesLine: Record Microsoft.Sales.Document."Sales Line";
        PurchLine: Record Microsoft.Purchases.Document."Purchase Line";
        TransLine: Record "Transfer Line";
        SalesHeader: Record Microsoft.Sales.Document."Sales Header";
        PurchHeader: Record Microsoft.Purchases.Document."Purchase Header";
        ServiceHeader: Record Microsoft.Service.Document."Service Header";
        ServiceLine: Record Microsoft.Service.Document."Service Line";
#endif
    begin
        "Source Document" := '';

        if "Sales Orders" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Sales Order";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        if "Sales Return Orders" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Sales Return Order";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        if "Outbound Transfers" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Outbound Transfer";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        if "Purchase Orders" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Purchase Order";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        if "Purchase Return Orders" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Purchase Return Order";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        if "Inbound Transfers" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Inbound Transfer";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        OnSetFiltersOnAfterSetSourceFilters(Rec, WhseRequest);

        if "Source Document" = '' then
            Error(MustBeChosenErr, FieldCaption("Source Document"));

        WhseRequest.SetFilter("Source Document", "Source Document");
        WhseRequest.SetFilter("Source No.", "Source No. Filter");
        WhseRequest.SetFilter("Shipment Method Code", "Shipment Method Code Filter");

        "Shipping Advice Filter" := '';

        if Partial then begin
            WhseRequest."Shipping Advice" := WhseRequest."Shipping Advice"::Partial;
            AddFilter("Shipping Advice Filter", Format(WhseRequest."Shipping Advice"));
        end;

        if Complete then begin
            WhseRequest."Shipping Advice" := WhseRequest."Shipping Advice"::Complete;
            AddFilter("Shipping Advice Filter", Format(WhseRequest."Shipping Advice"));
        end;

        WhseRequest.SetFilter("Shipping Advice", "Shipping Advice Filter");
        WhseRequest.SetRange("Location Code", LocationCode);

        OnSetFiltersOnSourceTables(Rec, GetSourceDocuments, WhseRequest);

#if not CLEAN23
        SalesHeader.SetFilter("Sell-to Customer No.", "Sell-to Customer No. Filter");
        SalesLine.SetFilter("No.", "Item No. Filter");
        SalesLine.SetFilter("Variant Code", "Variant Code Filter");
        SalesLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");
        SalesLine.SetFilter("Planned Delivery Date", "Planned Delivery Date");
        SalesLine.SetFilter("Planned Shipment Date", "Planned Shipment Date");
        SalesLine.SetFilter("Shipment Date", "Sales Shipment Date");
        SalesLine.SetFilter("Shipping Agent Code", "Shipping Agent Code Filter");
        SalesLine.SetFilter("Shipping Agent Service Code", "Shipping Agent Service Filter");

        ServiceHeader.SetFilter("Customer No.", "Customer No. Filter");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("No.", "Item No. Filter");
        ServiceLine.SetFilter("Variant Code", "Variant Code Filter");
        ServiceLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");
        ServiceLine.SetFilter("Planned Delivery Date", "Planned Delivery Date");
        ServiceLine.SetFilter("Shipping Agent Code", "Shipping Agent Code Filter");
        ServiceLine.SetFilter("Shipping Agent Service Code", "Shipping Agent Service Filter");

        PurchHeader.SetFilter("Buy-from Vendor No.", "Buy-from Vendor No. Filter");
        PurchLine.SetFilter("No.", "Item No. Filter");
        PurchLine.SetFilter("Variant Code", "Variant Code Filter");
        PurchLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");
        PurchLine.SetFilter("Buy-from Vendor No.", "Buy-from Vendor No. Filter");
        PurchLine.SetFilter("Expected Receipt Date", "Expected Receipt Date");
        PurchLine.SetFilter("Planned Receipt Date", "Planned Receipt Date");

        TransLine.SetFilter("Item No.", "Item No. Filter");
        TransLine.SetFilter("Variant Code", "Variant Code Filter");
        TransLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");
        TransLine.SetFilter("In-Transit Code", "In-Transit Code Filter");
        TransLine.SetFilter("Transfer-from Code", "Transfer-from Code Filter");
        TransLine.SetFilter("Transfer-to Code", "Transfer-to Code Filter");
        TransLine.SetFilter("Shipment Date", "Shipment Date");
        TransLine.SetFilter("Receipt Date", "Receipt Date");
        TransLine.SetFilter("Shipping Agent Code", "Shipping Agent Code Filter");
        TransLine.SetFilter("Shipping Agent Service Code", "Shipping Agent Service Filter");

        OnBeforeSetTableView(WhseRequest, SalesHeader, SalesLine, PurchLine, TransLine, ServiceHeader, ServiceLine, Rec, PurchHeader);

        GetSourceDocuments.SetTableView(WhseRequest);
        GetSourceDocuments.SetTableView(SalesHeader);
        GetSourceDocuments.SetTableView(SalesLine);
        GetSourceDocuments.SetTableView(PurchHeader);
        GetSourceDocuments.SetTableView(PurchLine);
        GetSourceDocuments.SetTableView(TransLine);
        GetSourceDocuments.SetTableView(ServiceHeader);
        GetSourceDocuments.SetTableView(ServiceLine);
#else
        GetSourceDocuments.SetTableView(WhseRequest);
#endif
        GetSourceDocuments.SetDoNotFillQtytoHandle("Do Not Fill Qty. to Handle");
        GetSourceDocuments.SetReservedFromStock("Reserved From Stock");

        OnAfterSetFilters(GetSourceDocuments, Rec);
    end;

    local procedure AddFilter(var CodeField: Code[250]; NewFilter: Text[100])
    begin
        if CodeField = '' then
            CodeField := NewFilter
        else
            CodeField := CodeField + '|' + NewFilter;
    end;

    local procedure CheckInboundSourceDocumentChosen()
    begin
        if not ("Sales Return Orders" or "Purchase Orders" or "Inbound Transfers") then
            Error(MustBeChosenErr, FieldCaption("Source Document"));
    end;

    local procedure CheckOutboundSourceDocumentChosen()
    begin
        if not ("Sales Orders" or "Purchase Return Orders" or "Outbound Transfers") then
            Error(MustBeChosenErr, FieldCaption("Source Document"));
    end;

    local procedure CheckType()
    begin
        if Type = Type::Inbound then begin
            "Sales Orders" := false;
            "Purchase Return Orders" := false;
            "Outbound Transfers" := false;
        end else begin
            "Purchase Orders" := false;
            "Sales Return Orders" := false;
            "Inbound Transfers" := false;
        end;

        OnAfterCheckType(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var GetSourceBatch: Report "Get Source Documents"; var WarehouseSourceFilter: Record "Warehouse Source Filter")
    begin
    end;

#if not CLEAN23
    [Obsolete('Related code moved to codeunits [Source Table] Warehouse Mgt. This event is replaced with similar events in [Source Table] Warehouse Mgt. codeunits.', '23.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTableView(
        var WarehouseRequest: Record "Warehouse Request";
        var SalesHeader: Record Microsoft.Sales.Document."Sales Header"; var SalesLine: Record Microsoft.Sales.Document."Sales Line";
        var PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line"; var TransferLine: Record "Transfer Line";
        var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ServiceLine: Record Microsoft.Service.Document."Service Line";
        var WarehouseSourceFilter: Record "Warehouse Source Filter"; var PurchaseHeader: Record Microsoft.Purchases.Document."Purchase Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckType(var WarehouseSourceFilter: Record "Warehouse Source Filter")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnAfterSetSourceFilters(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;
}

