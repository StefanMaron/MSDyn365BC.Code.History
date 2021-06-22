table 309 "No. Series Line"
{
    Caption = 'No. Series Line';
    DrillDownPageID = "No. Series Lines";
    LookupPageID = "No. Series Lines";

    fields
    {
        field(1; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
            NotBlank = true;
            TableRelation = "No. Series";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; "Starting No."; Code[20])
        {
            Caption = 'Starting No.';

            trigger OnValidate()
            begin
                UpdateLine("Starting No.", FieldCaption("Starting No."));
                UpdateStartingSequenceNo;
            end;
        }
        field(5; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';

            trigger OnValidate()
            begin
                if "Ending No." = '' then
                    "Warning No." := '';
                UpdateLine("Ending No.", FieldCaption("Ending No."));
                Validate(Open);
            end;
        }
        field(6; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';

            trigger OnValidate()
            begin
                TestField("Ending No.");
                UpdateLine("Warning No.", FieldCaption("Warning No."));
            end;
        }
        field(7; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
            InitValue = 1;
            MinValue = 1;
            trigger OnValidate()
            begin
                TestField("Allow Gaps in Nos.", false);
            end;
        }
        field(8; "Last No. Used"; Code[20])
        {
            Caption = 'Last No. Used';

            trigger OnValidate()
            begin
                UpdateLine("Last No. Used", FieldCaption("Last No. Used"));
                Validate(Open);
            end;
        }
        field(9; Open; Boolean)
        {
            Caption = 'Open';
            Editable = false;
            InitValue = true;

            trigger OnValidate()
            begin
                Open := ("Ending No." = '') or ("Ending No." <> "Last No. Used");
            end;
        }
        field(10; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
        field(11; "Allow Gaps in Nos."; Boolean)
        {
            Caption = 'Allow Gaps in Nos.';

            trigger OnValidate()
            var
                NoSeries: Record "No. Series";
            begin
                if "Allow Gaps in Nos." = xRec."Allow Gaps in Nos." then
                    exit;
                if "Allow Gaps in Nos." then begin
                    NoSeries.Get("Series Code");
                    if NoSeries."Date Order" then
                        Error(NoSeriesDateOrderErr, "Series Code");
                    UpdateStartingSequenceNo;
                    "Sequence Name" := '';
                    CreateNewSequence;
                    "Last Date Used" := 0D;
                    "Last No. Used" := '';
                end else begin
                    "Last No. Used" := xRec.GetLastNoUsed;
                    DeleteSequence;
                    "Starting Sequence No." := 0;
                    "Sequence Name" := '';
                end;
                if "Line No." <> 0 then
                    Modify;
            end;
        }
        field(12; "Sequence Name"; Code[40])
        {
            Caption = 'Sequence Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(13; "Starting Sequence No."; BigInteger)
        {
            Caption = 'Starting Sequence No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Series Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Series Code", "Starting Date", "Starting No.")
        {
        }
        key(Key3; "Starting No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        // A delete trigger (subscriber) is placed in codeunit 396 to clean up NumberSequence
    end;

    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoOverFlowErr: Label 'Number series can only use up to 18 digit numbers. %1 has %2 digits.', Comment = '%1 is a string that also contains digits. %2 is a number.';
        NoSeriesDateOrderErr: Label 'The Allow Gaps in Nos. setting is not possible for number series %1 because the Date Order check box is selected.', Comment = '%1=name/code10.';

    local procedure UpdateLine(NewNo: Code[20]; NewFieldName: Text[100])
    begin
        NoSeriesMgt.UpdateNoSeriesLine(Rec, NewNo, NewFieldName);
    end;

    procedure GetLastDateUsed(): Date
    begin
        if not "Allow Gaps in Nos." or ("Sequence Name" = '') then
            exit("Last Date Used");
        if not NumberSequence.Exists("Sequence Name") then
            exit("Last Date Used");
        exit(0D);
    end;

    procedure GetLastNoUsed(): Code[20]
    var
        LastSeqNoUsed: BigInteger;
    begin
        if not "Allow Gaps in Nos." or ("Sequence Name" = '') then
            exit("Last No. Used");
        if not NumberSequence.Exists("Sequence Name") then
            exit("Last No. Used");
        LastSeqNoUsed := NumberSequence.Current("Sequence Name");
        if LastSeqNoUsed > "Starting Sequence No." then
            exit(GetFormattedNo(LastSeqNoUsed));
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetNextSequenceNo(ModifySeries: Boolean): Code[20]
    var
        NewNo: BigInteger;
    begin
        TestField("Allow Gaps in Nos.");
        TestField("Sequence Name");
        if ModifySeries then
            NewNo := NumberSequence.Next("Sequence Name")
        else
            NewNo := NumberSequence.Current("Sequence Name") + "Increment-by No."; // Peek
        exit(GetFormattedNo(NewNo));
    end;

    local procedure UpdateStartingSequenceNo()
    begin
        if not "Allow Gaps in Nos." then
            exit;
        if "Last No. Used" = '' then
            "Starting Sequence No." := ExtractNoFromCode("Starting No.")
        else
            "Starting Sequence No." := ExtractNoFromCode("Last No. Used") - "Increment-by No.";
    end;

    local procedure CreateNewSequence()
    var
        DummySeq: BigInteger;
    begin
        if "Sequence Name" = '' then begin
            "Sequence Name" := Format(CreateGuid);
            "Sequence Name" := CopyStr("Sequence Name", 2, StrLen("Sequence Name") - 2);
        end;
        NumberSequence.Insert("Sequence Name", "Starting Sequence No.", "Increment-by No.");
        if "Last No. Used" <> '' then begin
            // Simulate that a number was used
            DummySeq := NumberSequence.next("Sequence Name");
            DummySeq := NumberSequence.next("Sequence Name");
        end;
    end;

    local procedure DeleteSequence()
    begin
        if "Sequence Name" = '' then
            exit;
        if NumberSequence.Exists("Sequence Name") then
            NumberSequence.Delete("Sequence Name");
    end;

    local procedure ExtractNoFromCode(NumberCode: Code[20]): BigInteger
    var
        i: Integer;
        j: Integer;
        Number: BigInteger;
        NoCodeSnip: Code[20];
    begin
        if NumberCode = '' then
            exit(0);
        i := StrLen(NumberCode);
        while (i > 1) and not (NumberCode[i] in ['0' .. '9']) do
            i -= 1;
        if i = 1 then begin
            if Evaluate(Number, Format(NumberCode[1])) then
                exit(Number);
            exit(0);
        end;
        j := i;
        while (i > 1) and (NumberCode[i] in ['0' .. '9']) do
            i -= 1;
        if (i = 1) and (NumberCode[i] in ['0' .. '9']) then
            i -= 1;
        NoCodeSnip := CopyStr(NumberCode, i + 1, j - i);
        if StrLen(NoCodeSnip) > 18 then
            Error(NoOverFlowErr, NumberCode, StrLen(NoCodeSnip));
        Evaluate(Number, NoCodeSnip);
        exit(Number);
    end;

    local procedure GetFormattedNo(Number: BigInteger): Code[20]
    var
        NumberCode: Code[20];
        i: Integer;
        j: Integer;
    begin
        if Number < "Starting Sequence No." then
            exit('');
        NumberCode := Format(Number);
        if "Starting No." = '' then
            exit(NumberCode);
        i := StrLen("Starting No.");
        while (i > 1) and not ("Starting No."[i] in ['0' .. '9']) do
            i -= 1;
        j := i - StrLen(NumberCode);
        if (j > 0) and (i < MaxStrLen("Starting No.")) then
            exit(CopyStr("Starting No.", 1, j) + NumberCode + CopyStr("Starting No.", i + 1));
        if (j > 0) then
            exit(CopyStr("Starting No.", 1, j) + NumberCode);
        while (i > 1) and ("Starting No."[i] in ['0' .. '9']) do
            i -= 1;
        if (i > 0) and (i + StrLen(NumberCode) <= MaxStrLen(NumberCode)) then
            if (i = 1) and ("Starting No."[i] in ['0' .. '9']) then
                exit(NumberCode)
            else
                exit(CopyStr("Starting No.", 1, i) + NumberCode);
        exit(NumberCode); // should ideally not be possible, as bigints can produce max 18 digits
    end;
}

