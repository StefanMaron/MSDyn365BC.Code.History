table 9054 "Finance Cue"
{
    Caption = 'Finance Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Overdue Sales Documents"; Integer)
        {
            CalcFormula = Count ("Cust. Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                            "Due Date" = FIELD("Overdue Date Filter"),
                                                            Open = CONST(true)));
            Caption = 'Overdue Sales Documents';
            FieldClass = FlowField;
        }
        field(3; "Purchase Documents Due Today"; Integer)
        {
            CalcFormula = Count ("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                             "Due Date" = FIELD("Due Date Filter"),
                                                             Open = CONST(true)));
            Caption = 'Purchase Documents Due Today';
            FieldClass = FlowField;
        }
        field(4; "POs Pending Approval"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Count ("Purchase Header" WHERE("Document Type" = CONST(Order),
                                                         Status = FILTER("Pending Approval")));
            Caption = 'POs Pending Approval';
            FieldClass = FlowField;
        }
        field(5; "SOs Pending Approval"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      Status = FILTER("Pending Approval")));
            Caption = 'SOs Pending Approval';
            FieldClass = FlowField;
        }
        field(6; "Approved Sales Orders"; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = CONST(Order),
                                                      Status = FILTER(Released | "Pending Prepayment")));
            Caption = 'Approved Sales Orders';
            FieldClass = FlowField;
        }
        field(7; "Approved Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Count ("Purchase Header" WHERE("Document Type" = CONST(Order),
                                                         Status = FILTER(Released | "Pending Prepayment")));
            Caption = 'Approved Purchase Orders';
            FieldClass = FlowField;
        }
        field(8; "Vendors - Payment on Hold"; Integer)
        {
            CalcFormula = Count (Vendor WHERE(Blocked = FILTER(Payment)));
            Caption = 'Vendors - Payment on Hold';
            FieldClass = FlowField;
        }
        field(9; "Purchase Return Orders"; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = Count ("Purchase Header" WHERE("Document Type" = CONST("Return Order")));
            Caption = 'Purchase Return Orders';
            FieldClass = FlowField;
        }
        field(10; "Sales Return Orders - All"; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            CalcFormula = Count ("Sales Header" WHERE("Document Type" = CONST("Return Order")));
            Caption = 'Sales Return Orders - All';
            FieldClass = FlowField;
        }
        field(11; "Customers - Blocked"; Integer)
        {
            CalcFormula = Count (Customer WHERE(Blocked = FILTER(<> " ")));
            Caption = 'Customers - Blocked';
            FieldClass = FlowField;
        }
        field(16; "Overdue Purchase Documents"; Integer)
        {
            CalcFormula = Count ("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                             "Due Date" = FIELD("Overdue Date Filter"),
                                                             Open = CONST(true)));
            Caption = 'Overdue Purchase Documents';
            FieldClass = FlowField;
        }
        field(17; "Purchase Discounts Next Week"; Integer)
        {
            CalcFormula = Count ("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                             "Pmt. Discount Date" = FIELD("Due Next Week Filter"),
                                                             Open = CONST(true)));
            Caption = 'Purchase Discounts Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Purch. Invoices Due Next Week"; Integer)
        {
            CalcFormula = Count ("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice | "Credit Memo"),
                                                             "Due Date" = FIELD("Due Next Week Filter"),
                                                             Open = CONST(true)));
            Caption = 'Purch. Invoices Due Next Week';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Due Next Week Filter"; Date)
        {
            Caption = 'Due Next Week Filter';
            FieldClass = FlowFilter;
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
        field(22; "New Incoming Documents"; Integer)
        {
            CalcFormula = Count ("Incoming Document" WHERE(Status = CONST(New)));
            Caption = 'New Incoming Documents';
            FieldClass = FlowField;
        }
        field(23; "Approved Incoming Documents"; Integer)
        {
            CalcFormula = Count ("Incoming Document" WHERE(Status = CONST(Released)));
            Caption = 'Approved Incoming Documents';
            FieldClass = FlowField;
        }
        field(24; "OCR Pending"; Integer)
        {
            CalcFormula = Count ("Incoming Document" WHERE("OCR Status" = FILTER(Ready | Sent | "Awaiting Verification")));
            Caption = 'OCR Pending';
            FieldClass = FlowField;
        }
        field(25; "OCR Completed"; Integer)
        {
            CalcFormula = Count ("Incoming Document" WHERE("OCR Status" = CONST(Success)));
            Caption = 'OCR Completed';
            FieldClass = FlowField;
        }
        field(26; "Requests to Approve"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Approver ID" = FIELD("User ID Filter"),
                                                        Status = FILTER(Open)));
            Caption = 'Requests to Approve';
            FieldClass = FlowField;
        }
        field(27; "Requests Sent for Approval"; Integer)
        {
            CalcFormula = Count ("Approval Entry" WHERE("Sender ID" = FIELD("User ID Filter"),
                                                        Status = FILTER(Open)));
            Caption = 'Requests Sent for Approval';
            FieldClass = FlowField;
        }
        field(28; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Non-Applied Payments"; Integer)
        {
            CalcFormula = Count ("Bank Acc. Reconciliation" WHERE("Statement Type" = CONST("Payment Application")));
            Caption = 'Non-Applied Payments';
            FieldClass = FlowField;
        }
        field(30; "Cash Accounts Balance"; Decimal)
        {
            AutoFormatExpression = GetAmountFormat;
            AutoFormatType = 11;
            Caption = 'Cash Accounts Balance';
            FieldClass = Normal;
        }
        field(31; "Last Depreciated Posted Date"; Date)
        {
            CalcFormula = Max ("FA Ledger Entry"."FA Posting Date" WHERE("FA Posting Type" = CONST(Depreciation)));
            Caption = 'Last Depreciated Posted Date';
            FieldClass = FlowField;
        }
        field(33; "Outstanding Vendor Invoices"; Integer)
        {
            CalcFormula = Count ("Vendor Ledger Entry" WHERE("Document Type" = FILTER(Invoice),
                                                             "Remaining Amount" = FILTER(< 0),
                                                             "Applies-to ID" = FILTER('')));
            Caption = 'Outstanding Vendor Invoices';
            Editable = false;
            FieldClass = FlowField;
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

    local procedure GetAmountFormat(): Text
    var
        ActivitiesCue: Record "Activities Cue";
    begin
        exit(ActivitiesCue.GetAmountFormat);
    end;
}

