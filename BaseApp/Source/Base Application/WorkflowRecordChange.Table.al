table 1525 "Workflow - Record Change"
{
    Caption = 'Workflow - Record Change';
    ReplicateData = true;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
        }
        field(5; "New Value"; Text[250])
        {
            Caption = 'New Value';
        }
        field(6; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = SystemMetadata;
        }
        field(7; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(8; "Field Caption"; Text[250])
        {
            CalcFormula = Lookup (Field."Field Caption" WHERE(TableNo = FIELD("Table No."),
                                                              "No." = FIELD("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
        field(9; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Workflow Step Instance ID", "Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetFormattedNewValue(FormatOptionString: Boolean): Text
    begin
        exit(FormatValue("New Value", FormatOptionString));
    end;

    procedure GetFormattedOldValue(FormatOptionString: Boolean): Text
    begin
        exit(FormatValue("Old Value", FormatOptionString));
    end;

    procedure FormatValue(Value: Text; FormatOptionString: Boolean): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        Bool: Boolean;
        Date: Date;
        DateFormula: DateFormula;
        DateTime: DateTime;
        Decimal: Decimal;
        Duration: Duration;
        "Integer": Integer;
        Option: Option;
        Time: Time;
        BigInteger: BigInteger;
    begin
        RecRef.Get("Record ID");
        FieldRef := RecRef.Field("Field No.");
        case Format(FieldRef.Type) of
            'Date':
                begin
                    Evaluate(Date, Value, 9);
                    exit(Format(Date));
                end;
            'Boolean':
                begin
                    Evaluate(Bool, Value, 9);
                    exit(Format(Bool));
                end;
            'DateFormula':
                begin
                    Evaluate(DateFormula, Value, 9);
                    exit(Format(DateFormula));
                end;
            'DateTime':
                begin
                    Evaluate(DateTime, Value, 9);
                    exit(Format(DateTime));
                end;
            'BigInteger':
                begin
                    Evaluate(BigInteger, Value, 9);
                    exit(Format(BigInteger));
                end;
            'Time':
                begin
                    Evaluate(Time, Value, 9);
                    exit(Format(Time));
                end;
            'Option':
                begin
                    Evaluate(Option, Value, 9);
                    if FormatOptionString then begin
                        FieldRef.Value := Option;
                        exit(Format(FieldRef.Value));
                    end;
                    exit(Format(Option));
                end;
            'Integer':
                begin
                    Evaluate(Integer, Value, 9);
                    exit(Format(Integer));
                end;
            'Duration':
                begin
                    Evaluate(Duration, Value, 9);
                    exit(Format(Duration));
                end;
            'Decimal':
                begin
                    Evaluate(Decimal, Value, 9);
                    exit(Format(Decimal));
                end;
            'Code', 'Text':
                exit(Format(Value));
            else
                exit(Format(Value));
        end;
    end;
}

