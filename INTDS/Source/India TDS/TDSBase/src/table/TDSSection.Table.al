table 18692 "TDS Section"
{
    Caption = 'Section';
    DataClassification = EndUserIdentifiableInformation;
    DrillDownPageId = "TDS Sections";
    LookupPageId = "TDS Sections";
    DataCaptionFields = "Code", "Description";
    Access = Public;
    Extensible = true;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = EndUserIdentifiableInformation;

        }
        field(3; ecode; Code[10])
        {
            Caption = 'ecode';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; Detail; Blob)
        {
            Caption = 'Detail';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Presentation Order"; Integer)
        {
            Caption = 'Presentation Order';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Indentation Level"; Integer)
        {
            Caption = 'Indentation Level';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Parent Code"; Code[20])
        {
            Caption = 'Parent Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Section Order"; Integer)
        {
            Caption = 'Section Order';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
        key(Key2; "Presentation Order") { }
    }

    trigger OnInsert()
    var
        Sections: Record "TDS Section";
        SubSection: Record "TDS Section";
    begin
        if "Presentation Order" = 0 then begin
            Sections.SetCurrentKey("Presentation Order");
            if Sections.FindLast() then begin
                SubSection.Reset();
                SubSection.SetCurrentKey("Presentation Order");
                SubSection.SetRange("Parent Code", Code);
                if SubSection.FindLast() then
                    "Presentation Order" := SubSection."Presentation Order" + 1
                else
                    "Presentation Order" := Sections."Presentation Order" + 20
            end else
                "Presentation Order" := 1;
        end;

        if "Section Order" = 0 then begin
            Sections.Reset();
            Sections.SetCurrentKey("Presentation Order");
            Sections.SetRange("Parent Code", "Parent Code");
            if Sections.FindLast() then
                "Section Order" := Sections."Section Order" + 1
            else
                "Section Order" := 1;
        end;
    end;
}