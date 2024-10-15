table 11773 "VAT Statement Attachment"
{
    Caption = 'VAT Statement Attachment';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "VAT Statement Template Name"; Code[10])
        {
            Caption = 'VAT Statement Template Name';
            NotBlank = true;
            TableRelation = "VAT Statement Template";
        }
        field(2; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            NotBlank = true;
            TableRelation = "VAT Statement Name".Name;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; Attachment; BLOB)
        {
            Caption = 'Attachment';
        }
        field(7; "File Name"; Text[250])
        {
            Caption = 'File Name';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "VAT Statement Template Name", "VAT Statement Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}