table 9080 "Error Handling Parameters"
{
    DataClassification = SystemMetadata;
    #pragma warning disable AS0034
    TableType = Temporary;
    #pragma warning restore AS0034

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Journal Template Name"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Journal Batch Name"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Previous Document No."; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Previous Posting Date"; Date)
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Full Batch Check"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Line Modified"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure IsGenJnlDocumentChanged(): Boolean
    begin
        exit(("Document No." <> "Previous Document No.") or ("Posting Date" <> "Previous Posting Date"));
    end;

    procedure FromArgs(Args: Dictionary of [Text, Text])
    begin
        "Journal Template Name" := CopyStr(Args.Get(FieldName("Journal Template Name")), 1, MaxStrLen("Journal Template Name"));
        "Journal Batch Name" := CopyStr(Args.Get(FieldName("Journal Batch Name")), 1, MaxStrLen("Journal Batch Name"));
        "Line Modified" := GetBooleanParameterValue(Args, FieldName("Line Modified"));
        "Document No." := CopyStr(Args.Get(FieldName("Document No.")), 1, MaxStrLen("Document No."));
        "Posting Date" := GetDateParameterValue(Args, FieldName("Posting Date"));
        "Previous Document No." := CopyStr(Args.Get(FieldName("Previous Document No.")), 1, MaxStrLen("Previous Document No."));
        "Previous Posting Date" := GetDateParameterValue(Args, FieldName("Previous Posting Date"));
        "Full Batch Check" := GetBooleanParameterValue(Args, FieldName("Full Batch Check"));
    end;

    local procedure GetBooleanParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) ParameterValue: Boolean
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(ParameterValue, ParamValueAsText);
    end;

    local procedure GetDateParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) ParameterValue: Date
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(ParameterValue, ParamValueAsText);
    end;

    procedure ToArgs(var Args: Dictionary of [Text, Text])
    begin
        Args.Add(FieldName("Journal Template Name"), "Journal Template Name");
        Args.Add(FieldName("Journal Batch Name"), "Journal Batch Name");
        Args.Add(FieldName("Line Modified"), format("Line Modified"));
        Args.Add(FieldName("Document No."), "Document No.");
        Args.Add(FieldName("Posting Date"), Format("Posting Date"));
        Args.Add(FieldName("Previous Document No."), "Previous Document No.");
        Args.Add(FieldName("Previous Posting Date"), Format("Previous Posting Date"));
        Args.Add(FieldName("Full Batch Check"), Format("Full Batch Check"));
    end;
}