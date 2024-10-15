table 1313 "Activities Cue"
{
    Caption = 'Activities Cue';
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(3; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(4; "Ongoing Sales Invoices"; Integer)
        {
            CalcFormula = Count("Sales Header" WHERE("Document Type" = FILTER(Invoice)));
            Caption = 'Ongoing Sales Invoices';
            FieldClass = FlowField;
        }
        field(5; "Ongoing Purchase Invoices"; Integer)
        {
            CalcFormula = Count("Purchase Header" WHERE("Document Type" = FILTER(Invoice)));
            Caption = 'Ongoing Purchase Invoices';
            FieldClass = FlowField;
        }
        field(6; "Sales This Month"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Sales This Month';
            DecimalPlaces = 0 : 0;
        }
        field(7; "Top 10 Customer Sales YTD"; Decimal)
        {
            AutoFormatExpression = '<Precision,1:1><Standard Format,9>%';
            AutoFormatType = 11;
            Caption = 'Top 10 Customer Sales YTD';
        }
        field(8; "Overdue Purch. Invoice Amount"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Overdue Purch. Invoice Amount';
            DecimalPlaces = 0 : 0;
        }
        field(9; "Overdue Sales Invoice Amount"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat();
            AutoFormatType = 11;
            Caption = 'Overdue Sales Invoice Amount';
            DecimalPlaces = 0 : 0;
        }
        field(10; "Average Collection Days"; Decimal)
        {
            Caption = 'Average Collection Days';
            DecimalPlaces = 1 : 1;
        }
        field(11; "Ongoing Sales Quotes"; Integer)
        {
            CalcFormula = Count("Sales Header" WHERE("Document Type" = FILTER(Quote)));
            Caption = 'Ongoing Sales Quotes';
            FieldClass = FlowField;
        }
        field(13; "Sales Inv. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = Count("Sales Invoice Header" WHERE("Document Exchange Status" = FILTER("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Invoices - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Sales CrM. - Pending Doc.Exch."; Integer)
        {
            CalcFormula = Count("Sales Cr.Memo Header" WHERE("Document Exchange Status" = FILTER("Sent to Document Exchange Service" | "Delivery Failed")));
            Caption = 'Sales Credit Memos - Pending Document Exchange';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Due Next Week Filter"; Date)
        {
            Caption = 'Due Next Week Filter';
            FieldClass = FlowFilter;
        }
        field(20; "My Incoming Documents"; Integer)
        {
            CalcFormula = Count("Incoming Document" WHERE(Processed = CONST(false)));
            Caption = 'My Incoming Documents';
            FieldClass = FlowField;
        }
        field(21; "Non-Applied Payments"; Integer)
        {
            CalcFormula = Count("Bank Acc. Reconciliation" WHERE("Statement Type" = CONST("Payment Application")));
            Caption = 'Non-Applied Payments';
            FieldClass = FlowField;
        }
        field(22; "Purch. Invoices Due Next Week"; Integer)
        {
            CalcFormula = Count("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                             "Due Date" = FIELD("Due Next Week Filter"),
                                                             Open = CONST(true)));
            Caption = 'Purch. Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Sales Invoices Due Next Week"; Integer)
        {
            CalcFormula = Count("Cust. Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                            "Due Date" = FIELD("Due Next Week Filter"),
                                                            Open = CONST(true)));
            Caption = 'Sales Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Ongoing Sales Orders"; Integer)
        {
            CalcFormula = Count("Sales Header" WHERE("Document Type" = FILTER(Order)));
            Caption = 'Ongoing Sales Orders';
            FieldClass = FlowField;
        }
        field(25; "Inc. Doc. Awaiting Verfication"; Integer)
        {
            CalcFormula = Count("Incoming Document" WHERE("OCR Status" = CONST("Awaiting Verification")));
            Caption = 'Inc. Doc. Awaiting Verfication';
            FieldClass = FlowField;
        }
        field(26; "Purchase Orders"; Integer)
        {
            CalcFormula = Count("Purchase Header" WHERE("Document Type" = FILTER(Order)));
            Caption = 'Purchase Orders';
            FieldClass = FlowField;
        }
        field(27; "Uninvoiced Bookings"; Integer)
        {
            Caption = 'Uninvoiced Bookings';
            Editable = false;
        }
        field(28; "IC Inbox Transactions"; Integer)
        {
            CalcFormula = Count("IC Inbox Transaction");
            Caption = 'IC Inbox Transactions';
            FieldClass = FlowField;
        }
        field(29; "IC Outbox Transactions"; Integer)
        {
            CalcFormula = Count("IC Outbox Transaction");
            Caption = 'IC Outbox Transactions';
            FieldClass = FlowField;
        }
        field(31; "Outstanding Vendor Invoices"; Integer)
        {
            CalcFormula = Count("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice),
                                                             Open = CONST(true)));
            Caption = 'Outstanding Vendor Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = Count("CRM Integration Record" WHERE(Skipped = CONST(true)));
            Caption = 'Coupled Data Synch Errors';
            FieldClass = FlowField;
        }
        field(33; "CDS Integration Errors"; Integer)
        {
            CalcFormula = Count("Integration Synch. Job Errors");
            Caption = 'Dataverse Integration Errors';
            FieldClass = FlowField;
        }
        field(110; "Last Date/Time Modified"; DateTime)
        {
            Caption = 'Last Date/Time Modified';
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

    procedure GetAmountFormat(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.GetAmountFormatLCYWithUserLocale());
    end;
}

