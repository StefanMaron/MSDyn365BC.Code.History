table 11749 "Cash Desk Cue"
{
    Caption = 'Cash Desk Cue';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Open Documents"; Integer)
        {
            CalcFormula = Count("Cash Document Header" WHERE("Cash Desk No." = FIELD("Cash Desk Filter"),
                                                              Status = CONST(Open)));
            Caption = 'Open Documents';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Released Documents"; Integer)
        {
            CalcFormula = Count("Cash Document Header" WHERE("Cash Desk No." = FIELD("Cash Desk Filter"),
                                                              Status = CONST(Released)));
            Caption = 'Released Documents';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Posted Documents"; Integer)
        {
            CalcFormula = Count("Posted Cash Document Header" WHERE("Cash Desk No." = FIELD("Cash Desk Filter"),
                                                                     "Posting Date" = FIELD("Date Filter")));
            Caption = 'Posted Documents';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Cash Desk Filter"; Code[20])
        {
            Caption = 'Cash Desk Filter';
            FieldClass = FlowFilter;
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));
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
