table 9051 "Warehouse WMS Cue"
{
    Caption = 'Warehouse WMS Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Released Sales Orders - Today"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = FILTER(Order),
                                                      Status = FILTER(Released),
                                                      "Shipment Date" = FIELD("Date Filter"),
                                                      "Location Code" = FIELD("Location Filter")));
            Caption = 'Released Sales Orders - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Shipments - Today"; Integer)
        {
            CalcFormula = Count ("Warehouse Shipment Header" WHERE("Shipment Date" = FIELD("Date Filter"),
                                                                   "Location Code" = FIELD("Location Filter")));
            Caption = 'Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Posted Shipments - Today"; Integer)
        {
            CalcFormula = Count ("Posted Whse. Shipment Header" WHERE("Posting Date" = FIELD("Date Filter2"),
                                                                      "Location Code" = FIELD("Location Filter")));
            Caption = 'Posted Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Expected Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Count ("Purchase Header" WHERE("Document Type" = FILTER(Order),
                                                         Status = FILTER(Released),
                                                         "Expected Receipt Date" = FIELD("Date Filter"),
                                                         "Location Code" = FIELD("Location Filter")));
            Caption = 'Expected Purchase Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Arrivals; Integer)
        {
            CalcFormula = Count ("Warehouse Receipt Header" WHERE("Location Code" = FIELD("Location Filter")));
            Caption = 'Arrivals';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Posted Receipts - Today"; Integer)
        {
            CalcFormula = Count ("Posted Whse. Receipt Header" WHERE("Posting Date" = FIELD("Date Filter2"),
                                                                     "Location Code" = FIELD("Location Filter")));
            Caption = 'Posted Receipts - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Picked Shipments - Today"; Integer)
        {
            CalcFormula = Count ("Warehouse Shipment Header" WHERE("Shipment Date" = FIELD("Date Filter"),
                                                                   "Location Code" = FIELD("Location Filter"),
                                                                   "Document Status" = FILTER("Partially Picked" | "Completely Picked")));
            Caption = 'Picked Shipments - Today';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Picks - All"; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = FILTER(Pick),
                                                                   "Location Code" = FIELD("Location Filter")));
            Caption = 'Picks - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Put-aways - All"; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = FILTER("Put-away"),
                                                                   "Location Code" = FIELD("Location Filter")));
            Caption = 'Put-aways - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Movements - All"; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = FILTER(Movement),
                                                                   "Location Code" = FIELD("Location Filter")));
            Caption = 'Movements - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Registered Picks - Today"; Integer)
        {
            CalcFormula = Count ("Registered Whse. Activity Hdr." WHERE(Type = FILTER(Pick),
                                                                        "Registering Date" = FIELD("Date Filter2"),
                                                                        "Location Code" = FIELD("Location Filter")));
            Caption = 'Registered Picks - Today';
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

    procedure GetEmployeeLocation(UserID: Code[50]): Text[1024]
    var
        WhseEmployee: Record "Warehouse Employee";
        LocationString: Text[1024];
    begin
        LocationString := '';
        if UserID <> '' then begin
            WhseEmployee.SetRange("User ID", UserID);
            if WhseEmployee.FindSet then
                repeat
                    LocationString += WhseEmployee."Location Code" + '|';
                until WhseEmployee.Next = 0;

            LocationString := DelChr(LocationString, '>', '|');
        end;
        if LocationString = '' then
            LocationString := '''''';
        exit(LocationString);
    end;
}

