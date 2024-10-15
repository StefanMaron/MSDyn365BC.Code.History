table 31100 "VAT Control Report Header"
{
    Caption = 'VAT Control Report Header';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Report Period"; Option)
        {
            Caption = 'Report Period';
            OptionCaption = 'Month,Quarter';
            OptionMembers = Month,Quarter;
        }
        field(4; "Period No."; Integer)
        {
            Caption = 'Period No.';
            MaxValue = 12;
            MinValue = 1;
        }
        field(5; Year; Integer)
        {
            Caption = 'Year';
            MinValue = 0;
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(8; "Created Date"; Date)
        {
            Caption = 'Created Date';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Release';
            OptionMembers = Open,Release;
        }
        field(15; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries has been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(20; "VAT Statement Template Name"; Code[10])
        {
            Caption = 'VAT Statement Template Name';
            TableRelation = "VAT Statement Template";
        }
        field(21; "VAT Statement Name"; Code[10])
        {
            Caption = 'VAT Statement Name';
            TableRelation = "VAT Statement Name".Name WHERE("Statement Template Name" = FIELD("VAT Statement Template Name"));
        }
        field(51; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(100; "Closed by Document No. Filter"; Code[20])
        {
            Caption = 'Closed by Document No. Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

}
