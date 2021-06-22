table 9050 "Warehouse Basic Cue"
{
    Caption = 'Warehouse Basic Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Rlsd. Sales Orders Until Today"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Released),
                                                      "Shipment Date" = FIELD("Date Filter"),
                                                      "Location Code" = FIELD("Location Filter")));
            Caption = 'Rlsd. Sales Orders Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Posted Sales Shipments - Today"; Integer)
        {
            CalcFormula = Count ("Sales Shipment Header" WHERE("Posting Date" = FIELD("Date Filter2"),
                                                               "Location Code" = FIELD("Location Filter")));
            Caption = 'Posted Sales Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Exp. Purch. Orders Until Today"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Count ("Purchase Header" WHERE("Document Type" = FILTER(Order),
                                                         Status = FILTER(Released),
                                                         "Expected Receipt Date" = FIELD("Date Filter"),
                                                         "Location Code" = FIELD("Location Filter")));
            Caption = 'Exp. Purch. Orders Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Posted Purch. Receipts - Today"; Integer)
        {
            CalcFormula = Count ("Purch. Rcpt. Header" WHERE("Posting Date" = FIELD("Date Filter2"),
                                                             "Location Code" = FIELD("Location Filter")));
            Caption = 'Posted Purch. Receipts - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Invt. Picks Until Today"; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = FILTER("Invt. Pick"),
                                                                   "Shipment Date" = FIELD("Date Filter"),
                                                                   "Location Code" = FIELD("Location Filter")));
            Caption = 'Invt. Picks Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Invt. Put-aways Until Today"; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = FILTER("Invt. Put-away"),
                                                                   "Shipment Date" = FIELD("Date Filter"),
                                                                   "Location Code" = FIELD("Location Filter")));
            Caption = 'Invt. Put-aways Until Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Open Phys. Invt. Orders"; Integer)
        {
            CalcFormula = Count ("Phys. Invt. Order Header" WHERE(Status = CONST(Open)));
            Caption = 'Open Phys. Invt. Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
        }
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

