namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Security.AccessControl;

table 9153 "My Account"
{
    Caption = 'My Account';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            NotBlank = true;
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                SetAccountFields();
            end;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(4; Balance; Decimal)
        {
            CalcFormula = sum("G/L Entry".Amount where("G/L Account No." = field("Account No.")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteReason = 'This flowfield is showing incomplete data.';
            ObsoleteState = Removed;
            ObsoleteTag = '18.0';
        }
        field(5; "Account Balance"; Decimal)
        {
            Caption = 'Account Balance';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "User ID", "Account No.")
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
    }

    local procedure SetAccountFields()
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get("Account No.") then
            Name := GLAccount.Name;
    end;
}

