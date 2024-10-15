table 15000001 "Remittance Payment Order"
{
    Caption = 'Remittance Payment Order';
    DrillDownPageID = "Remittance Payment Order";
    LookupPageID = "Remittance Payment Order";

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            Editable = false;
        }
        field(2; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Export,Return';
            OptionMembers = Export,Return;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(11; Time; Time)
        {
            Caption = 'Time';
            Editable = false;
        }
        field(20; Canceled; Boolean)
        {
            Caption = 'Canceled';
            Editable = false;
        }
        field(30; "Number Sent"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Waiting Journal" WHERE("Payment Order ID - Sent" = FIELD(ID)));
            Caption = 'Number Sent';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Number Approved"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Waiting Journal" WHERE("Payment Order ID - Approved" = FIELD(ID)));
            Caption = 'Number Approved';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Number Settled"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Waiting Journal" WHERE("Payment Order ID - Settled" = FIELD(ID)));
            Caption = 'Number Settled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Number Rejected"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Waiting Journal" WHERE("Payment Order ID - Rejected" = FIELD(ID)));
            Caption = 'Number Rejected';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; Date)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PaymentOrderData: Record "Payment Order Data";
        WaitingJournal: Record "Waiting Journal";
    begin
        PaymentOrderData.SetRange("Payment Order No.", ID);
        PaymentOrderData.DeleteAll();
        WaitingJournal.SetRange(Reference, ID);
        WaitingJournal.DeleteAll();
    end;
}

