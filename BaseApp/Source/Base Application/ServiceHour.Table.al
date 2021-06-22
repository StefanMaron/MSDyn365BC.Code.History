table 5910 "Service Hour"
{
    Caption = 'Service Hour';
    LookupPageID = "Service Hours";

    fields
    {
        field(1; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            TableRelation = IF ("Service Contract Type" = CONST(Contract)) "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract))
            ELSE
            IF ("Service Contract Type" = CONST(Quote)) "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Quote));
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; Day; Option)
        {
            Caption = 'Day';
            OptionCaption = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
        }
        field(4; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                if "Ending Time" <> 0T then
                    if "Starting Time" >= "Ending Time" then
                        Error(Text001, FieldCaption("Starting Time"), FieldCaption("Ending Time"));
            end;
        }
        field(5; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                if "Ending Time" <> 0T then
                    if "Ending Time" <= "Starting Time" then
                        Error(Text000, FieldCaption("Ending Time"), FieldCaption("Starting Time"));
            end;
        }
        field(6; "Valid on Holidays"; Boolean)
        {
            Caption = 'Valid on Holidays';
        }
        field(7; "Service Contract Type"; Option)
        {
            Caption = 'Service Contract Type';
            OptionCaption = ' ,Quote,Contract';
            OptionMembers = " ",Quote,Contract;
        }
    }

    keys
    {
        key(Key1; "Service Contract Type", "Service Contract No.", Day, "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckTime;
    end;

    trigger OnModify()
    begin
        CheckTime;
    end;

    var
        Text000: Label '%1 must be later than %2.';
        Text001: Label '%1 must be earlier than %2.';
        Text002: Label 'You must specify %1.';
        Text003: Label 'Do you want to copy the default service calendar?';

    local procedure CheckTime()
    begin
        if "Starting Time" = 0T then
            Error(Text002, FieldCaption("Starting Time"));
        if "Ending Time" = 0T then
            Error(Text002, FieldCaption("Ending Time"));
    end;

    procedure CopyDefaultServiceHours()
    var
        ServHour: Record "Service Hour";
        ServHour2: Record "Service Hour";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
            exit;

        ServHour.Reset();
        ServHour.SetRange("Service Contract No.", '');
        if ServHour.FindSet then
            repeat
                ServHour2.TransferFields(ServHour);
                Evaluate(ServHour2."Service Contract Type", GetFilter("Service Contract Type"));
                ServHour2.Validate("Service Contract No.", GetFilter("Service Contract No."));
                if not ServHour2.Insert() then
                    ServHour2.Modify();
            until ServHour.Next = 0;
    end;
}

