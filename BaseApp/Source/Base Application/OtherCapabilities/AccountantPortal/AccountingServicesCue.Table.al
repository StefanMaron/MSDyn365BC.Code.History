namespace Microsoft.AccountantPortal;

using Microsoft.EServices.EDocument;
using Microsoft.Sales.Document;
using System.Automation;

table 9070 "Accounting Services Cue"
{
    Caption = 'Accounting Services Cue';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Requests to Approve"; Integer)
        {
            CalcFormula = Count("Approval Entry" where(Status = const(Open),
                                                        "Approver ID" = const('USERID')));
            Caption = 'Requests to Approve';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Ongoing Sales Invoices"; Integer)
        {
            CalcFormula = Count("Sales Header" where("Document Type" = filter(Invoice)));
            Caption = 'Ongoing Sales Invoices';
            FieldClass = FlowField;
        }
        field(5; "My Incoming Documents"; Integer)
        {
            CalcFormula = Count("Incoming Document");
            Caption = 'My Incoming Documents';
            FieldClass = FlowField;
        }
        field(20; "User ID Filter"; Code[50])
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

