table 5328 "CRM Synch Status"
{
    Caption = 'Microsoft Dynamics 365 Invoice Synch Status';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Last Update Invoice Entry No."; Integer)
        {
            Caption = 'Last Update Invoice Entry No.';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(3; "Last Cust Contact Link Update"; DateTime)
        {
            Caption = 'Last Customer Contact Link Update';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(4; "Cust. Statistics Synch. Time"; DateTime)
        {
            Caption = 'Customer Statistics Synchronization Time';
        }
        field(5; "Item Availability Synch. Time"; DateTime)
        {
            Caption = 'Item Availability Synchronization Time';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure UpdateLastUpdateInvoiceEntryNo(): Boolean
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        Get();
        DtldCustLedgEntry.Reset();
        if DtldCustLedgEntry.FindLast() then
            if "Last Update Invoice Entry No." <> DtldCustLedgEntry."Entry No." then begin
                "Last Update Invoice Entry No." := DtldCustLedgEntry."Entry No.";
                exit(Modify());
            end;
    end;
}