namespace Microsoft.Finance.FinancialReports;

table 342 "Acc. Sched. Cell Value"
{
    Caption = 'Acc. Sched. Cell Value';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(3; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(4; "Has Error"; Boolean)
        {
            Caption = 'Has Error';
        }
        field(5; "Period Error"; Boolean)
        {
            Caption = 'Period Error';
        }
        field(31080; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "Acc. Schedule Name";
            ObsoleteState = Removed;
            ObsoleteTag = '24.0';
            ObsoleteReason = 'The field is not used anymore.';
        }
    }

    keys
    {
        key(Key1; "Row No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

