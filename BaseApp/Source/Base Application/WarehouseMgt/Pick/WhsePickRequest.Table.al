table 7325 "Whse. Pick Request"
{
    Caption = 'Whse. Pick Request';

    fields
    {
        field(1; "Document Type"; Enum "Warehouse Pick Request Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document Subtype"; Option)
        {
            Caption = 'Document Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            NotBlank = true;
            TableRelation = IF ("Document Type" = CONST(Shipment)) "Warehouse Shipment Header"."No."
            ELSE
            IF ("Document Type" = CONST("Internal Pick")) "Whse. Internal Pick Header"."No."
            ELSE
#pragma warning disable AL0603
            IF ("Document Type" = CONST(Production)) "Production Order"."No." WHERE(Status = FIELD("Document Subtype"))
            ELSE
            IF ("Document Type" = CONST(Assembly)) "Assembly Header"."No." WHERE("Document Type" = FIELD("Document Subtype"))
#pragma warning restore AL0603
            ELSE
            IF ("Document Type" = const(Job)) Job."No." where(Status = const(Open));

            trigger OnLookup()
            begin
                LookupDocumentNo();
            end;
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(5; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));
        }
        field(6; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            ELSE
            IF ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(7; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(8; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
        }
        field(9; "Shipment Method Code"; Code[10])
        {
            CalcFormula = Lookup("Warehouse Shipment Header"."Shipment Method Code" WHERE("No." = FIELD("Document No.")));
            Caption = 'Shipment Method Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Shipment Method";
        }
        field(10; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            CalcFormula = Lookup("Warehouse Shipment Header"."Shipping Agent Code" WHERE("No." = FIELD("Document No.")));
            Caption = 'Shipping Agent Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Shipping Agent";
        }
        field(11; "Shipping Agent Service Code"; Code[10])
        {
            CalcFormula = Lookup("Warehouse Shipment Header"."Shipping Agent Service Code" WHERE("No." = FIELD("Document No.")));
            Caption = 'Shipping Agent Service Code';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document Subtype", "Document No.", "Location Code")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Document Type", Status) { }
    }

    fieldgroups
    {
    }

    local procedure LookupDocumentNo()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        ProdOrderHeader: Record "Production Order";
        AssemblyHeader: Record "Assembly Header";
        JobHeader: Record Job;
        WhseShptList: Page "Warehouse Shipment List";
        WhseInternalPickList: Page "Whse. Internal Pick List";
        ProdOrderList: Page "Production Order List";
        AssemblyOrders: Page "Assembly Orders";
        JobList: Page "Job List";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupDocumentNo(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::Shipment:
                begin
                    if WhseShptHeader.Get("Document No.") then
                        WhseShptList.SetRecord(WhseShptHeader);
                    WhseShptList.RunModal();
                    Clear(WhseShptList);
                end;
            "Document Type"::"Internal Pick":
                begin
                    if WhseInternalPickHeader.Get("Document No.") then
                        WhseInternalPickList.SetRecord(WhseInternalPickHeader);
                    WhseInternalPickList.RunModal();
                    Clear(WhseInternalPickList);
                end;
            "Document Type"::Production:
                begin
                    if ProdOrderHeader.Get("Document Subtype", "Document No.") then
                        ProdOrderList.SetRecord(ProdOrderHeader);
                    ProdOrderList.RunModal();
                    Clear(ProdOrderList);
                end;
            "Document Type"::Assembly:
                begin
                    if AssemblyHeader.Get("Document Subtype", "Document No.") then
                        AssemblyOrders.SetRecord(AssemblyHeader);
                    AssemblyOrders.RunModal();
                    Clear(AssemblyOrders);
                end;
            "Document Type"::Job:
                begin
                    if JobHeader.Get("Document No.") then
                        JobList.SetRecord(JobHeader);
                    JobList.RunModal();
                    Clear(JobList);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocumentNo(var WhsePickRequest: Record "Whse. Pick Request"; var IsHandled: Boolean)
    begin
    end;
}

