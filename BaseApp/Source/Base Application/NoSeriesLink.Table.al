table 11799 "No. Series Link"
{
    Caption = 'No. Series Link';
    ObsoleteState = Removed;
    ObsoleteReason = 'The functionality of No. Series Enhancements will be removed and this table should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '18.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Initial No. Series"; Code[20])
        {
            Caption = 'Initial No. Series';
            NotBlank = true;
            TableRelation = "No. Series";
        }
        field(2; "Initial No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Initial No. Series")));
            Caption = 'Initial No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Linked No. Series"; Code[20])
        {
            Caption = 'Linked No. Series';
            TableRelation = "No. Series";
        }
        field(4; "Linked No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Linked No. Series")));
            Caption = 'Linked No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(6; "Posting No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Posting No. Series")));
            Caption = 'Posting No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";
        }
        field(8; "Shipping No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Shipping No. Series")));
            Caption = 'Shipping No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Receiving No. Series"; Code[20])
        {
            Caption = 'Receiving No. Series';
            TableRelation = "No. Series";
        }
        field(10; "Receiving No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Receiving No. Series")));
            Caption = 'Receiving No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Shipping Wh. No. Series"; Code[20])
        {
            Caption = 'Shipping Wh. No. Series';
            TableRelation = "No. Series";
        }
        field(12; "Shipping Wh. No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Shipping Wh. No. Series")));
            Caption = 'Shipping Wh. No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Receiving Wh. No. Series"; Code[20])
        {
            Caption = 'Receiving Wh. No. Series';
            TableRelation = "No. Series";
        }
        field(14; "Receiving Wh. No. Series Desc."; Text[50])
        {
            CalcFormula = lookup("No. Series".Description where(Code = field("Receiving Wh. No. Series")));
            Caption = 'Receiving Wh. No. Series Desc.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Initial No. Series")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        NoSerieCheck();
    end;

    trigger OnModify()
    begin
        NoSerieCheck();
    end;

    trigger OnRename()
    begin
        NoSerieCheck();
    end;

    var
        MustEnterErr: Label 'You must enter either %1 or %2.';
        MustNotEnterErr: Label 'You must not enter either %1 or %2.';

    local procedure NoSerieCheck()
    begin
        TestField("Initial No. Series");

        if ("Receiving Wh. No. Series" <> '') and ("Shipping Wh. No. Series" <> '') and
           (("Linked No. Series" <> '') or ("Posting No. Series" <> ''))
        then
            Error(MustNotEnterErr, FieldCaption("Linked No. Series"), FieldCaption("Posting No. Series"));

        if ("Linked No. Series" <> '') and ("Posting No. Series" <> '') then
            Error(MustEnterErr, FieldCaption("Linked No. Series"), FieldCaption("Posting No. Series"));

        if ("Linked No. Series" <> '') and ("Shipping No. Series" <> '') then
            Error(MustEnterErr, FieldCaption("Linked No. Series"), FieldCaption("Shipping No. Series"));

        if ("Linked No. Series" <> '') and ("Receiving No. Series" <> '') then
            Error(MustEnterErr, FieldCaption("Linked No. Series"), FieldCaption("Receiving No. Series"));

        if ("Posting No. Series" <> '') and ("Shipping No. Series" <> '') and ("Receiving No. Series" <> '') then
            Error(MustNotEnterErr, FieldCaption("Shipping No. Series"), FieldCaption("Receiving No. Series"));

        if ("Posting No. Series" <> '') and (("Receiving Wh. No. Series" <> '') or ("Shipping Wh. No. Series" <> '')) then
            Error(MustNotEnterErr, FieldCaption("Receiving Wh. No. Series"), FieldCaption("Shipping Wh. No. Series"));
    end;
}

