namespace Microsoft.Bank.PositivePay;

using System.IO;

table 1240 "Positive Pay Header"
{
    Caption = 'Positive Pay Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(3; "Account Number"; Text[30])
        {
            Caption = 'Account Number';
        }
        field(4; "Date of File"; Date)
        {
            Caption = 'Date of File';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

