namespace Microsoft.Inventory.Item.Catalog;

table 5719 "Nonstock Item Setup"
{
    Caption = 'Nonstock Item Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "No. Format"; Enum "Nonstock Item No. Format")
        {
            Caption = 'No. Format';
            trigger OnValidate()
            begin
                if "No. Format" = "No. Format"::"Item No. Series" then
                    "No. Format Separator" := '';
            end;
        }
        field(3; "No. Format Separator"; Code[1])
        {
            Caption = 'No. Format Separator';
            trigger OnValidate()
            begin
                if "No. Format" = "No. Format"::"Item No. Series" then
                    if "No. Format Separator" <> '' then
                        FieldError("No. Format");
            end;
        }
        field(31070; "No. From No. Series"; Boolean)
        {
            Caption = 'No. From No. Series';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

