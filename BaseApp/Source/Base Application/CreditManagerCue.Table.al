table 36623 "Credit Manager Cue"
{
    Caption = 'Credit Manager Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Overdue Sales Invoices"; Integer)
        {
            CalcFormula = Count ("Cust. Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                            "Due Date" = FIELD("Overdue Date Filter"),
                                                            Open = CONST(true)));
            Caption = 'Overdue Sales Invoices';
            FieldClass = FlowField;
        }
        field(5; "SOs Pending Approval"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      Status = FILTER("Pending Approval")));
            Caption = 'SOs Pending Approval';
            FieldClass = FlowField;
        }
        field(6; "Approved Sales Orders"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      Status = FILTER(Released | "Pending Prepayment")));
            Caption = 'Approved Sales Orders';
            FieldClass = FlowField;
        }
        field(7; "Sales Orders On Hold"; Integer)
        {
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      "On Hold" = FILTER(<> '')));
            Caption = 'Sales Orders On Hold';
            FieldClass = FlowField;
        }
        field(11; "Customers - Blocked"; Integer)
        {
            CalcFormula = Count (Customer WHERE(Blocked = FILTER(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(12; "Customers - Overdue"; Integer)
        {
            CalcFormula = Count (Customer WHERE("Date Filter" = FIELD("Overdue Date Filter"),
                                                "Balance Due (LCY)" = FILTER(> 0)));
            Caption = 'Customers - Overdue';
            FieldClass = FlowField;
        }
        field(15; "Approvals - Sales Orders"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Table ID" = CONST(36),
                                                        "Document Type" = CONST(Order),
                                                        "Approver ID" = FIELD("User Filter"),
                                                        Status = CONST(Open)));
            Caption = 'Approvals - Sales Orders';
            FieldClass = FlowField;
        }
        field(16; "Approvals - Sales Invoices"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Table ID" = CONST(36),
                                                        "Document Type" = CONST(Invoice),
                                                        "Approver ID" = FIELD("User Filter"),
                                                        Status = CONST(Open)));
            Caption = 'Approvals - Sales Invoices';
            FieldClass = FlowField;
        }
        field(20; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "User Filter"; Code[50])
        {
            Caption = 'User Filter';
            Editable = false;
            FieldClass = FlowFilter;
            TableRelation = "User Setup";
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

