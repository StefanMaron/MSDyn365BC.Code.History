table 9060 "SB Owner Cue"
{
    Caption = 'SB Owner Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Released Sales Quotes"; Integer)
        {
            CalcFormula = Count("Sales Header" WHERE("Document Type" = CONST(Quote),
                                                      Status = FILTER(Released)));
            Caption = 'Released Sales Quotes';
            FieldClass = FlowField;
        }
        field(3; "Open Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Count("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      Status = FILTER(Open)));
            Caption = 'Open Sales Orders';
            FieldClass = FlowField;
        }
        field(4; "Released Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Count("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      Status = FILTER(Released)));
            Caption = 'Released Sales Orders';
            FieldClass = FlowField;
        }
        field(5; "Released Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Count("Purchase Header" WHERE("Document Type" = CONST(Order),
                                                         Status = FILTER(Released)));
            Caption = 'Released Purchase Orders';
            FieldClass = FlowField;
        }
        field(6; "Overdue Sales Documents"; Integer)
        {
            CalcFormula = Count("Cust. Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                            "Due Date" = FIELD("Overdue Date Filter"),
                                                            Open = CONST(true)));
            Caption = 'Overdue Sales Documents';
            FieldClass = FlowField;
        }
        field(7; "SOs Shipped Not Invoiced"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      "Completely Shipped" = CONST(true),
                                                      "Shipped Not Invoiced" = CONST(true)));
            Caption = 'SOs Shipped Not Invoiced';
            FieldClass = FlowField;
            ObsoleteReason = 'Poor performance';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(8; "Customers - Blocked"; Integer)
        {
            CalcFormula = Count(Customer WHERE(Blocked = FILTER(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(9; "Purchase Documents Due Today"; Integer)
        {
            CalcFormula = Count("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                             "Due Date" = FIELD("Due Date Filter"),
                                                             Open = CONST(true)));
            Caption = 'Purchase Documents Due Today';
            FieldClass = FlowField;
        }
        field(10; "Vendors - Payment on Hold"; Integer)
        {
            CalcFormula = Count(Vendor WHERE(Blocked = FILTER(Payment)));
            Caption = 'Vendors - Payment on Hold';
            FieldClass = FlowField;
        }
        field(11; "Sales Invoices"; Integer)
        {
            CalcFormula = Count("Sales Header" WHERE("Document Type" = FILTER(Invoice)));
            Caption = 'Sales Invoices';
            FieldClass = FlowField;
        }
        field(12; "Unpaid Sales Invoices"; Integer)
        {
            CalcFormula = Count("Sales Invoice Header" WHERE(Closed = FILTER(false)));
            Caption = 'Unpaid Sales Invoices';
            FieldClass = FlowField;
        }
        field(13; "Overdue Sales Invoices"; Integer)
        {
            CalcFormula = Count("Sales Invoice Header" WHERE("Due Date" = FIELD("Overdue Date Filter"),
                                                              Closed = FILTER(false)));
            Caption = 'Overdue Sales Invoices';
            FieldClass = FlowField;
        }
        field(14; "Sales Quotes"; Integer)
        {
            CalcFormula = Count("Sales Header" WHERE("Document Type" = FILTER(Quote)));
            Caption = 'Sales Quotes';
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
        field(30; "Purchase Invoices"; Integer)
        {
            CalcFormula = Count("Purchase Header" WHERE("Document Type" = FILTER(Invoice)));
            Caption = 'Purchase Invoices';
            FieldClass = FlowField;
        }
        field(31; "Unpaid Purchase Invoices"; Integer)
        {
            CalcFormula = Count("Purch. Inv. Header" WHERE(Closed = FILTER(false)));
            Caption = 'Unpaid Purchase Invoices';
            FieldClass = FlowField;
        }
        field(32; "Overdue Purchase Invoices"; Integer)
        {
            CalcFormula = Count("Purch. Inv. Header" WHERE("Due Date" = FIELD("Overdue Date Filter"),
                                                            Closed = FILTER(false)));
            Caption = 'Overdue Purchase Invoices';
            FieldClass = FlowField;
        }
        field(33; "User ID Filter"; Code[50])
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

    procedure CountSalesOrdersShippedNotInvoiced(): Integer
    var
        CountSalesOrders: Query "Count Sales Orders";
    begin
        CountSalesOrders.SetRange(Completely_Shipped, true);
        CountSalesOrders.SetRange(Shipped_Not_Invoiced, true);
        CountSalesOrders.Open();
        CountSalesOrders.Read();
        exit(CountSalesOrders.Count_Orders);
    end;

    procedure ShowSalesOrdersShippedNotInvoiced()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Completely Shipped", true);
        SalesHeader.SetRange("Shipped Not Invoiced", true);
        PAGE.Run(PAGE::"Sales Order List", SalesHeader);
    end;
}

