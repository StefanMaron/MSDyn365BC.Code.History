table 5771 "Warehouse Source Filter"
{
    Caption = 'Warehouse Source Filter';

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
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(4; "Variant Code Filter"; Code[100])
        {
            Caption = 'Variant Code Filter';
            TableRelation = "Item Variant".Code;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(5; "Unit of Measure Filter"; Code[100])
        {
            Caption = 'Unit of Measure Filter';
            TableRelation = "Unit of Measure";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(6; "Sell-to Customer No. Filter"; Code[100])
        {
            Caption = 'Sell-to Customer No. Filter';
            TableRelation = Customer;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(7; "Buy-from Vendor No. Filter"; Code[100])
        {
            Caption = 'Buy-from Vendor No. Filter';
            TableRelation = Vendor;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(8; "Customer No. Filter"; Code[100])
        {
            Caption = 'Customer No. Filter';
            TableRelation = Customer;
            //This property is currently not supported
            //TestTableRelation = false;
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
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(12; "Shipping Agent Code Filter"; Code[100])
        {
            Caption = 'Shipping Agent Code Filter';
            TableRelation = "Shipping Agent";
            //This property is currently not supported
            //TestTableRelation = false;
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
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "In-Transit Code Filter"; Code[100])
        {
            Caption = 'In-Transit Code Filter';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(true));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(19; "Transfer-from Code Filter"; Code[100])
        {
            Caption = 'Transfer-from Code Filter';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(20; "Transfer-to Code Filter"; Code[100])
        {
            Caption = 'Transfer-to Code Filter';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
            //This property is currently not supported
            //TestTableRelation = false;
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
            Caption = 'Shipment Date Filter';
            FieldClass = FlowFilter;
        }
        field(25; "Receipt Date Filter"; Date)
        {
            Caption = 'Receipt Date Filter';
            FieldClass = FlowFilter;
        }
        field(28; "Sales Shipment Date Filter"; Date)
        {
            Caption = 'Sales Shipment Date Filter';
            FieldClass = FlowFilter;
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
                if Type = Type::Inbound then begin
                    "Sales Orders" := false;
                    "Purchase Return Orders" := false;
                    "Outbound Transfers" := false;
                    "Service Orders" := false;
                end else begin
                    "Purchase Orders" := false;
                    "Sales Return Orders" := false;
                    "Inbound Transfers" := false;
                end;
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
                    CheckOutboundSourceDocumentChosen;
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
                    CheckInboundSourceDocumentChosen;
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
                    CheckInboundSourceDocumentChosen;
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
                    CheckOutboundSourceDocumentChosen;
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
                    CheckInboundSourceDocumentChosen;
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
                    CheckOutboundSourceDocumentChosen;
            end;
        }
        field(108; Partial; Boolean)
        {
            Caption = 'Partial';
            InitValue = true;

            trigger OnValidate()
            begin
                if not Partial and not Complete then
                    Error(Text000, FieldCaption("Shipping Advice Filter"));
            end;
        }
        field(109; Complete; Boolean)
        {
            Caption = 'Complete';
            InitValue = true;

            trigger OnValidate()
            begin
                if not Partial and not Complete then
                    Error(Text000, FieldCaption("Shipping Advice Filter"));
            end;
        }
        field(110; "Service Orders"; Boolean)
        {
            Caption = 'Service Orders';
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Outbound then
                    CheckOutboundSourceDocumentChosen;
            end;
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

    var
        Text000: Label '%1 must be chosen.';

    procedure SetFilters(var GetSourceBatch: Report "Get Source Documents"; LocationCode: Code[10])
    var
        WhseRequest: Record "Warehouse Request";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        "Source Document" := '';

        if "Sales Orders" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Sales Order";
            AddFilter("Source Document", Format(WhseRequest."Source Document"));
        end;

        if "Service Orders" then begin
            WhseRequest."Source Document" := WhseRequest."Source Document"::"Service Order";
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

        if "Source Document" = '' then
            Error(Text000, FieldCaption("Source Document"));

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

        SalesLine.SetFilter("No.", "Item No. Filter");
        SalesLine.SetFilter("Variant Code", "Variant Code Filter");
        SalesLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");

        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("No.", "Item No. Filter");
        ServiceLine.SetFilter("Variant Code", "Variant Code Filter");
        ServiceLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");

        PurchLine.SetFilter("No.", "Item No. Filter");
        PurchLine.SetFilter("Variant Code", "Variant Code Filter");
        PurchLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");

        TransLine.SetFilter("Item No.", "Item No. Filter");
        TransLine.SetFilter("Variant Code", "Variant Code Filter");
        TransLine.SetFilter("Unit of Measure Code", "Unit of Measure Filter");

        SalesHeader.SetFilter("Sell-to Customer No.", "Sell-to Customer No. Filter");
        SalesLine.SetFilter("Planned Delivery Date", "Planned Delivery Date");
        SalesLine.SetFilter("Planned Shipment Date", "Planned Shipment Date");
        SalesLine.SetFilter("Shipment Date", "Sales Shipment Date");

        ServiceHeader.SetFilter("Customer No.", "Customer No. Filter");

        ServiceLine.SetFilter("Planned Delivery Date", "Planned Delivery Date");

        PurchLine.SetFilter("Buy-from Vendor No.", "Buy-from Vendor No. Filter");
        PurchLine.SetFilter("Expected Receipt Date", "Expected Receipt Date");
        PurchLine.SetFilter("Planned Receipt Date", "Planned Receipt Date");

        TransLine.SetFilter("In-Transit Code", "In-Transit Code Filter");
        TransLine.SetFilter("Transfer-from Code", "Transfer-from Code Filter");
        TransLine.SetFilter("Transfer-to Code", "Transfer-to Code Filter");
        TransLine.SetFilter("Shipment Date", "Shipment Date");
        TransLine.SetFilter("Receipt Date", "Receipt Date");

        SalesLine.SetFilter("Shipping Agent Code", "Shipping Agent Code Filter");
        SalesLine.SetFilter("Shipping Agent Service Code", "Shipping Agent Service Filter");

        ServiceLine.SetFilter("Shipping Agent Code", "Shipping Agent Code Filter");
        ServiceLine.SetFilter("Shipping Agent Service Code", "Shipping Agent Service Filter");

        TransLine.SetFilter("Shipping Agent Code", "Shipping Agent Code Filter");
        TransLine.SetFilter("Shipping Agent Service Code", "Shipping Agent Service Filter");

        OnBeforeSetTableView(WhseRequest, SalesHeader, SalesLine, PurchLine, TransLine, ServiceHeader, ServiceLine, Rec, PurchHeader);

        GetSourceBatch.SetTableView(WhseRequest);
        GetSourceBatch.SetTableView(SalesHeader);
        GetSourceBatch.SetTableView(SalesLine);
        GetSourceBatch.SetTableView(PurchHeader);
        GetSourceBatch.SetTableView(PurchLine);
        GetSourceBatch.SetTableView(TransLine);
        GetSourceBatch.SetTableView(ServiceHeader);
        GetSourceBatch.SetTableView(ServiceLine);
        GetSourceBatch.SetDoNotFillQtytoHandle("Do Not Fill Qty. to Handle");
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
            Error(Text000, FieldCaption("Source Document"));
    end;

    local procedure CheckOutboundSourceDocumentChosen()
    begin
        if not ("Sales Orders" or "Purchase Return Orders" or "Outbound Transfers" or "Service Orders") then
            Error(Text000, FieldCaption("Source Document"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTableView(var WarehouseRequest: Record "Warehouse Request"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var PurchaseLine: Record "Purchase Line"; var TransferLine: Record "Transfer Line"; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

