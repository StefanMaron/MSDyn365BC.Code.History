table 2711 "Bank Acc. Rec. Match Buffer"
{
    Caption = 'Bank Account Reconciliation Many-to-One Matchings';

    fields
    {
        field(1; "Ledger Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Bank Account Ledger Entry No.';
            Editable = false;
        }
        field(2; "Statement No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Statement No.';
            Editable = false;
        }
        field(3; "Statement Line No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Statement Line No.';
            Editable = false;
        }
        field(4; "Bank Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Bank Account No.';
            Editable = false;
        }
        field(5; "Match ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Match ID';
            Editable = false;
        }
        field(6; "Is Processed"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Is Processed';
            Editable = false;
        }
    }

    keys
    {
        key(key1; "Statement No.", "Statement Line No.", "Bank Account No.", "Match ID")
        {
            Clustered = true;
        }
        key(Key2; "Ledger Entry No.")
        {

        }
        key(Key3; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
        }
    }

    trigger OnDelete()
    begin

    end;
}