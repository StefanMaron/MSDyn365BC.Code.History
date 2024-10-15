table 18003 "GST Component"
{
    Caption = 'GST Component';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                VALIDATE("Calculation Order");
            end;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "GST Jurisdiction Type"; Enum "GST Jurisdiction Type")
        {
            Caption = 'GST Jurisdiction Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Include Base"; Boolean)
        {
            Caption = 'Include Base';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; Formula; Code[250])
        {
            Caption = 'Formula';
            TableRelation = "GST Component";
            DataClassification = EndUserIdentifiableInformation;
            ValidateTableRelation = false;
        }
        field(6; "Calculation Order"; Integer)
        {
            Caption = 'Calculation Order';
            DataClassification = EndUserIdentifiableInformation;
            MinValue = 1;
            NotBlank = true;

            trigger OnValidate()
            var
                GSTComponent: Record "GST Component";
            begin
                IF (xRec."Calculation Order" <> "Calculation Order") AND IsSameCalculationOrder() THEN
                    ERROR(CalculationOrderErr, GSTComponent.Code);
            end;
        }
        field(7; "Report View"; Enum "Report View")
        {
            Caption = 'Report View';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                IF ("Report View" <> "Report View"::CESS) AND "Exclude from Reports" = TRUE THEN
                    ERROR(ExcludeRepErr);
            end;
        }
        field(8; "Non-Availment"; Boolean)
        {
            Caption = 'Non-Availment';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Exclude from Reports"; Boolean)
        {
            Caption = 'Exclude from Reports';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                IF "Report View" <> "Report View"::CESS THEN
                    ERROR(ExcludeReportErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Calculation Order")
        {
        }
        key(Key3; "Report View")
        {
        }
    }

    trigger OnDelete()
    var
        GSTClaimSetoff: Record "GST Claim Setoff";
    begin
        GSTClaimSetoff.SETRANGE("GST Component Code", Code);
        GSTClaimSetoff.DELETEALL(TRUE);
    end;

    trigger OnInsert()
    begin
        "Calculation Order" := GetLastCalculationOrder();
        IF IsZeroCalculationOrder() THEN
            ERROR(ZeroCalculationOrderErr);
    end;

    local procedure IsZeroCalculationOrder(): Boolean
    var
        GSTComponent: Record "GST Component";
    begin
        GSTComponent.SETRANGE("Calculation Order", 0);
        EXIT(NOT GSTComponent.ISEMPTY());
    end;

    local procedure GetLastCalculationOrder(): Integer
    var
        GSTComponent: Record "GST Component";
    begin
        GSTComponent.SETCURRENTKEY("Calculation Order");
        IF GSTComponent.FINDLAST() THEN
            EXIT(GSTComponent."Calculation Order" + 1);
        EXIT(1);
    end;

    local procedure IsSameCalculationOrder(): Boolean
    var
        GSTComponent: Record "GST Component";
    begin
        GSTComponent.SETRANGE("Calculation Order", "Calculation Order");
        EXIT(NOT GSTComponent.ISEMPTY());
    end;

    var
        CalculationOrderErr: Label 'The same calculation order is already exist for component code %1.', Comment = 'The same calculation order is already exist for component code %1.';
        ZeroCalculationOrderErr: Label 'Calculation Order cannot be Zero.';
        ExcludeReportErr: Label 'Exclude from Report is applicable only for Cess Component.';
        ExcludeRepErr: Label 'Exclude from Reports is applicable only for Cess Component, Currently this field is TRUE.';
}

