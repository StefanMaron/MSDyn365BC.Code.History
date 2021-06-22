table 5969 "Contract Gain/Loss Entry"
{
    Caption = 'Contract Gain/Loss Entry';
    DrillDownPageID = "Contract Gain/Loss Entries";
    LookupPageID = "Contract Gain/Loss Entries";
    Permissions = TableData "Contract Gain/Loss Entry" = rimd;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract));
        }
        field(3; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            TableRelation = "Contract Group";
        }
        field(4; "Change Date"; Date)
        {
            Caption = 'Change Date';
        }
        field(5; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(6; "Type of Change"; Option)
        {
            Caption = 'Type of Change';
            OptionCaption = 'Line Added,Line Deleted,Contract Signed,Contract Canceled,Manual Update,Price Update';
            OptionMembers = "Line Added","Line Deleted","Contract Signed","Contract Canceled","Manual Update","Price Update";
        }
        field(8; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(10; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Customer No."));
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(12; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract No.", "Change Date", "Reason Code")
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Contract Group Code", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Customer No.", "Ship-to Code", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key5; "Reason Code", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Responsibility Center", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key7; "Responsibility Center", "Type of Change", "Reason Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";

    procedure AddEntry(ChangeStatus: Integer; ContractType: Integer; ContractNo: Code[20]; ChangeAmount: Decimal; ReasonCode: Code[10])
    var
        ServContract: Record "Service Contract Header";
        NextLine: Integer;
    begin
        ContractGainLossEntry.Reset();
        ContractGainLossEntry.LockTable();
        if ContractGainLossEntry.FindLast then
            NextLine := ContractGainLossEntry."Entry No." + 1
        else
            NextLine := 1;

        if ContractNo <> '' then
            ServContract.Get(ContractType, ContractNo)
        else
            Clear(ServContract);

        ContractGainLossEntry.Init();
        ContractGainLossEntry."Entry No." := NextLine;
        ContractGainLossEntry."Contract No." := ContractNo;
        ContractGainLossEntry."Contract Group Code" := ServContract."Contract Group Code";
        ContractGainLossEntry."Change Date" := Today;
        ContractGainLossEntry."Type of Change" := ChangeStatus;
        ContractGainLossEntry."Responsibility Center" := ServContract."Responsibility Center";
        ContractGainLossEntry."Customer No." := ServContract."Customer No.";
        ContractGainLossEntry."Ship-to Code" := ServContract."Ship-to Code";
        ContractGainLossEntry."User ID" := UserId;
        ContractGainLossEntry.Amount := ChangeAmount;
        ContractGainLossEntry."Reason Code" := ReasonCode;
        ContractGainLossEntry.Insert();
    end;
}

