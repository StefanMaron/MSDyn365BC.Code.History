table 9069 "O365 Sales Cue"
{
    Caption = 'O365 Sales Cue';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Overdue Sales Documents"; Integer)
        {
            CalcFormula = count("Cust. Ledger Entry" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                            "Due Date" = field("Overdue Date Filter"),
                                                            Open = const(true)));
            Caption = 'Overdue Sales Documents';
            FieldClass = FlowField;
        }
        field(3; "Customers - Blocked"; Integer)
        {
            CalcFormula = count(Customer where(Blocked = filter(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(4; "CM Date Filter"; Date)
        {
            Caption = 'CM Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "YTD Date Filter"; Date)
        {
            Caption = 'YTD Date Filter';
            FieldClass = FlowFilter;
        }
        field(6; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(7; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(8; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Non-Applied Payments"; Integer)
        {
            CalcFormula = count("Bank Acc. Reconciliation" where("Statement Type" = const("Payment Application")));
            Caption = 'Non-Applied Payments';
            FieldClass = FlowField;
        }
        field(10; "Invoiced YTD"; Decimal)
        {
            CalcFormula = sum("Sales Invoice Entity Aggregate"."Amount Including VAT" where("Document Date" = field("YTD Date Filter"),
                                                                                             Status = filter(Open | Paid)));
            Caption = 'Invoiced YTD';
            FieldClass = FlowField;
        }
        field(11; "Invoiced CM"; Decimal)
        {
            CalcFormula = sum("Sales Invoice Entity Aggregate"."Amount Including VAT" where("Document Date" = field("CM Date Filter"),
                                                                                             Status = filter(Open | Paid)));
            Caption = 'Invoiced CM';
            FieldClass = FlowField;
        }
        field(12; "Sales Invoices Outstanding"; Decimal)
        {
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)");
            Caption = 'Sales Invoices Outstanding';
            FieldClass = FlowField;
        }
        field(13; "Sales Invoices Overdue"; Decimal)
        {
            CalcFormula = sum("Detailed Cust. Ledg. Entry"."Amount (LCY)" where("Initial Entry Due Date" = field("Overdue Date Filter")));
            Caption = 'Sales Invoices Overdue';
            FieldClass = FlowField;
        }
        field(14; "No. of Quotes"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Quote)));
            Caption = 'No. of Quotes';
            FieldClass = FlowField;
        }
        field(15; "No. of Draft Invoices"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = const(Invoice)));
            Caption = 'No. of Draft Invoices';
            FieldClass = FlowField;
        }
        field(16; "No. of Invoices YTD"; Integer)
        {
            CalcFormula = count("Sales Invoice Header" where("Posting Date" = field("YTD Date Filter")));
            Caption = 'No. of Invoices YTD';
            FieldClass = FlowField;
        }
        field(17; "Requested DateTime"; DateTime)
        {
            Caption = 'Requested DateTime';
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

