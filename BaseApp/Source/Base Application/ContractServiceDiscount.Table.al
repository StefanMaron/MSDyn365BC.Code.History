table 5972 "Contract/Service Discount"
{
    Caption = 'Contract/Service Discount';
    DataCaptionFields = "Contract Type", "Contract No.";
    LookupPageID = "Contract/Service Discounts";

    fields
    {
        field(1; "Contract Type"; Option)
        {
            Caption = 'Contract Type';
            OptionCaption = 'Quote,Contract,Template';
            OptionMembers = Quote,Contract,Template;
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = IF ("Contract Type" = CONST(Template)) "Service Contract Template"."No."
            ELSE
            IF ("Contract Type" = CONST(Contract)) "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract))
            ELSE
            IF ("Contract Type" = CONST(Quote)) "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Quote));
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Service Item Group,Resource Group,Cost';
            OptionMembers = "Service Item Group","Resource Group",Cost;
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST("Service Item Group")) "Service Item Group".Code
            ELSE
            IF (Type = CONST("Resource Group")) "Resource Group"."No."
            ELSE
            IF (Type = CONST(Cost)) "Service Cost".Code;
            //This property is currently not supported
            //TestTableRelation = true;
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(7; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Contract Type", "Contract No.", Type, "No.", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if "Contract Type" = "Contract Type"::Contract then begin
            VerifyContractOpen;
            ServMgtSetup.Get();
            if ServMgtSetup."Register Contract Changes" then
                ContractChangeLog.LogContractChange(
                  "Contract No.", 2, StrSubstNo('%1 %2 %3', Type, "No.", FieldCaption("No.")), 2,
                  Format("No."), '', '', 0);
        end;
    end;

    trigger OnInsert()
    begin
        TestField("Contract No.");
        if "Contract Type" = "Contract Type"::Contract then begin
            VerifyContractOpen;
            ServMgtSetup.Get();
            if ServMgtSetup."Register Contract Changes" then
                ContractChangeLog.LogContractChange(
                  "Contract No.", 2, StrSubstNo('%1 %2 %3', Type, "No.", FieldCaption("No.")), 1,
                  '', Format("No."), '', 0);
        end;
    end;

    trigger OnModify()
    begin
        if "Contract Type" = "Contract Type"::Contract then begin
            VerifyContractOpen;
            ServMgtSetup.Get();
            if "Discount %" <> xRec."Discount %" then
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 2, StrSubstNo('%1 %2 %3', Type, "No.", FieldCaption("Discount %")), 0,
                      Format(xRec."Discount %"), Format("Discount %"), '', 0);
        end;
    end;

    trigger OnRename()
    begin
        Error(Text000);
    end;

    var
        Text000: Label 'You cannot rename the record.';
        ContractChangeLog: Record "Contract Change Log";
        ServMgtSetup: Record "Service Mgt. Setup";

    local procedure VerifyContractOpen()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.Get("Contract Type", "Contract No.");
        ServiceContractHeader.TestField("Change Status", ServiceContractHeader."Change Status"::Open);
    end;
}

