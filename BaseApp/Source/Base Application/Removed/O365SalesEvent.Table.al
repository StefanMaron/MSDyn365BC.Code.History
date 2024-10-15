table 2163 "O365 Sales Event"
{
    Caption = 'O365 Sales Event';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Invoice Sent,Invoice Paid,Draft Reminder,Invoice Overdue,Invoicing Inactivity,Estimate Sent,Estimate Accepted,Estimate Expiring,Invoice Email Failed,Estimate Email Failed,KPI Update';
            OptionMembers = "Invoice Sent","Invoice Paid","Draft Reminder","Invoice Overdue","Invoicing Inactivity","Estimate Sent","Estimate Accepted","Estimate Expiring","Invoice Email Failed","Estimate Email Failed","KPI Update";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
    }

    keys
    {
        key(Key1; "No.", Type, "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

