table 9056 "Manufacturing Cue"
{
    Caption = 'Manufacturing Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Planned Prod. Orders - All"; Integer)
        {
            CalcFormula = Count ("Production Order" WHERE(Status = CONST(Planned)));
            Caption = 'Planned Prod. Orders';
            FieldClass = FlowField;
        }
        field(3; "Firm Plan. Prod. Orders - All"; Integer)
        {
            CalcFormula = Count ("Production Order" WHERE(Status = CONST("Firm Planned")));
            Caption = 'Firm Plan. Prod. Orders';
            FieldClass = FlowField;
        }
        field(4; "Released Prod. Orders - All"; Integer)
        {
            CalcFormula = Count ("Production Order" WHERE(Status = CONST(Released)));
            Caption = 'Released Prod. Orders';
            FieldClass = FlowField;
        }
        field(5; "Prod. BOMs under Development"; Integer)
        {
            CalcFormula = Count ("Production BOM Header" WHERE(Status = CONST("Under Development")));
            Caption = 'Prod. BOMs under Development';
            FieldClass = FlowField;
        }
        field(6; "Routings under Development"; Integer)
        {
            CalcFormula = Count ("Routing Header" WHERE(Status = CONST("Under Development")));
            Caption = 'Routings under Development';
            FieldClass = FlowField;
        }
        field(7; "Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Count ("Purchase Header" WHERE("Document Type" = CONST(Order),
                                                         "Assigned User ID" = FIELD("User ID Filter")));
            Caption = 'Purchase Orders';
            FieldClass = FlowField;
        }
        field(8; "Prod. Orders Routings-in Queue"; Integer)
        {
            CalcFormula = Count ("Prod. Order Routing Line" WHERE("Starting Date" = FIELD("Date Filter"),
                                                                  "Routing Status" = FILTER(" " | Planned),
                                                                  Status = FILTER(<> Finished)));
            Caption = 'Prod. Orders Routings-in Queue';
            FieldClass = FlowField;
        }
        field(9; "Prod. Orders Routings-in Prog."; Integer)
        {
            CalcFormula = Count ("Prod. Order Routing Line" WHERE("Ending Date" = FIELD("Date Filter"),
                                                                  "Routing Status" = FILTER("In Progress"),
                                                                  Status = CONST(Released)));
            Caption = 'Prod. Orders Routings-in Prog.';
            FieldClass = FlowField;
        }
        field(10; "Invt. Picks to Production"; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = CONST(Pick),
                                                                   "Source Document" = CONST("Prod. Consumption")));
            Caption = 'Invt. Picks to Production';
            FieldClass = FlowField;
        }
        field(11; "Invt. Put-aways from Prod."; Integer)
        {
            CalcFormula = Count ("Warehouse Activity Header" WHERE(Type = CONST(Pick),
                                                                   "Source Document" = CONST("Prod. Output")));
            Caption = 'Invt. Put-aways from Prod.';
            FieldClass = FlowField;
        }
        field(12; "Rlsd. Prod. Orders Until Today"; Integer)
        {
            CalcFormula = Count ("Production Order" WHERE(Status = CONST(Released),
                                                          "Starting Date" = FIELD("Date Filter")));
            Caption = 'Rlsd. Prod. Orders Until Today';
            FieldClass = FlowField;
        }
        field(13; "Simulated Prod. Orders"; Integer)
        {
            CalcFormula = Count ("Production Order" WHERE(Status = CONST(Simulated)));
            Caption = 'Simulated Prod. Orders';
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "User ID Filter"; Code[50])
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

