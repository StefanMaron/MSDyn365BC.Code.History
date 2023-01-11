table 5765 "Warehouse Request"
{
    Caption = 'Warehouse Request';
    LookupPageID = "Source Documents";

    fields
    {
        field(1; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(2; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(3; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            TableRelation = IF ("Source Document" = CONST("Sales Order")) "Sales Header"."No." WHERE("Document Type" = CONST(Order),
                                                                                                    "No." = FIELD("Source No."))
            ELSE
            IF ("Source Document" = CONST("Sales Return Order")) "Sales Header"."No." WHERE("Document Type" = CONST("Return Order"),
                                                                                                                                                                                        "No." = FIELD("Source No."))
            ELSE
            IF ("Source Document" = CONST("Purchase Order")) "Purchase Header"."No." WHERE("Document Type" = CONST(Order),
                                                                                                                                                                                                                                                                           "No." = FIELD("Source No."))
            ELSE
            IF ("Source Document" = CONST("Purchase Return Order")) "Purchase Header"."No." WHERE("Document Type" = CONST("Return Order"),
                                                                                                                                                                                                                                                                                                                                                                     "No." = FIELD("Source No."))
            ELSE
            IF ("Source Type" = CONST(5741)) "Transfer Header"."No." WHERE("No." = FIELD("Source No."))
            ELSE
            IF ("Source Type" = FILTER(5406 | 5407)) "Production Order"."No." WHERE(Status = CONST(Released),
                                                                                                                                                                                                                                                                                                                                                                                                                                               "No." = FIELD("Source No."))
            ELSE
            IF ("Source Type" = FILTER(901)) "Assembly Header"."No." WHERE("Document Type" = CONST(Order),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  "No." = FIELD("Source No."));
        }
        field(4; "Source Document"; Enum "Warehouse Request Source Document")
        {
            Caption = 'Source Document';
            Editable = false;
        }
        field(5; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(7; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            Editable = false;
            TableRelation = "Shipment Method";
        }
        field(8; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            Editable = false;
            TableRelation = "Shipping Agent";
        }
        field(9; "Shipping Agent Service Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Service Code';
            Editable = false;
            TableRelation = "Shipping Agent Services";
        }
        field(10; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            Editable = false;
        }
        field(11; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
        }
        field(12; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            TableRelation = IF ("Destination Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Destination Type" = CONST(Customer)) Customer
            ELSE
            IF ("Destination Type" = CONST(Location)) Location
            ELSE
            IF ("Destination Type" = CONST(Item)) Item
            ELSE
            IF ("Destination Type" = CONST(Family)) Family
            ELSE
            IF ("Destination Type" = CONST("Sales Order")) "Sales Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(13; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(14; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(15; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(19; Type; Enum "Warehouse Request Type")
        {
            Caption = 'Type';
            Editable = false;
        }
        field(20; "Put-away / Pick No."; Code[20])
        {
            CalcFormula = Lookup("Warehouse Activity Line"."No." WHERE("Source Type" = FIELD("Source Type"),
                                                                        "Source Subtype" = FIELD("Source Subtype"),
                                                                        "Source No." = FIELD("Source No."),
                                                                        "Location Code" = FIELD("Location Code")));
            Caption = 'Put-away / Pick No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Completely Handled"; Boolean)
        {
            Caption = 'Completely Handled';
        }
    }

    keys
    {
        key(Key1; Type, "Location Code", "Source Type", "Source Subtype", "Source No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Subtype", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "Source Type", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Source Document", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; Type, "Location Code", "Completely Handled", "Document Status", "Expected Receipt Date", "Shipment Date", "Source Document", "Source No.")
        {
        }
        key(Key6; "Source No.", "Source Subtype", "Source Type", Type, "Document Status")
        {
        }
    }

    fieldgroups
    {
    }

    procedure DeleteRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20])
    begin
        SetSourceFilter(SourceType, SourceSubtype, SourceNo);
        if not IsEmpty() then
            DeleteAll();

        OnAfterDeleteRequest(SourceType, SourceSubtype, SourceNo);
    end;

    procedure SetDestinationType(ProdOrder: Record "Production Order")
    begin
        case ProdOrder."Source Type" of
            ProdOrder."Source Type"::Item:
                "Destination Type" := "Destination Type"::Item;
            ProdOrder."Source Type"::Family:
                "Destination Type" := "Destination Type"::Family;
            ProdOrder."Source Type"::"Sales Header":
                "Destination Type" := "Destination Type"::"Sales Order";
        end;

        OnAfterSetDestinationType(Rec, ProdOrder);
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20])
    begin
        SetRange("Source Type", SourceType);
        SetRange("Source Subtype", SourceSubtype);
        SetRange("Source No.", SourceNo);
    end;

    procedure ShowSourceDocumentCard()
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransHeader: Record "Transfer Header";
        ProdOrder: Record "Production Order";
        ServiceHeader: Record "Service Header";
    begin
        case "Source Document" of
            "Source Document"::"Purchase Order":
                begin
                    PurchHeader.Get("Source Subtype", "Source No.");
                    PAGE.Run(PAGE::"Purchase Order", PurchHeader);
                end;
            "Source Document"::"Purchase Return Order":
                begin
                    PurchHeader.Get("Source Subtype", "Source No.");
                    PAGE.Run(PAGE::"Purchase Return Order", PurchHeader);
                end;
            "Source Document"::"Sales Order":
                begin
                    SalesHeader.Get("Source Subtype", "Source No.");
                    PAGE.Run(PAGE::"Sales Order", SalesHeader);
                end;
            "Source Document"::"Sales Return Order":
                begin
                    SalesHeader.Get("Source Subtype", "Source No.");
                    PAGE.Run(PAGE::"Sales Return Order", SalesHeader);
                end;
            "Source Document"::"Inbound Transfer", "Source Document"::"Outbound Transfer":
                begin
                    TransHeader.Get("Source No.");
                    PAGE.Run(PAGE::"Transfer Order", TransHeader);
                end;
            "Source Document"::"Prod. Consumption", "Source Document"::"Prod. Output":
                begin
                    ProdOrder.Get("Source Subtype", "Source No.");
                    PAGE.Run(PAGE::"Released Production Order", ProdOrder);
                end;
            "Source Document"::"Service Order":
                begin
                    ServiceHeader.Get("Source Subtype", "Source No.");
                    PAGE.Run(PAGE::"Service Order", ServiceHeader);
                end;
            else
                OnShowSourceDocumentCardCaseElse(Rec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDestinationType(var WhseRequest: Record "Warehouse Request"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocumentCardCaseElse(var WhseRequest: Record "Warehouse Request")
    begin
    end;
}

