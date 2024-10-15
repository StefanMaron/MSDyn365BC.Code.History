table 31082 "Acc. Schedule Result Line"
{
    Caption = 'Acc. Schedule Result Line';

    fields
    {
        field(1; "Result Code"; Code[20])
        {
            Caption = 'Result Code';
            TableRelation = "Acc. Schedule Result Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Row No."; Code[20])
        {
            Caption = 'Row No.';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = IF ("Totaling Type" = CONST("Posting Accounts")) "G/L Account"
            ELSE
            IF ("Totaling Type" = CONST("Total Accounts")) "G/L Account"
            ELSE
            IF ("Totaling Type" = CONST(Custom)) "Acc. Schedule Extension";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(6; "Totaling Type"; Option)
        {
            Caption = 'Totaling Type';
            OptionCaption = 'Posting Accounts,Total Accounts,Formula,Constant,,Set Base For Percent,,,Custom';
            OptionMembers = "Posting Accounts","Total Accounts",Formula,Constant,,"Set Base For Percent",,,Custom;
        }
        field(7; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(16; Show; Option)
        {
            Caption = 'Show';
            OptionCaption = 'Yes,No,If Any Column Not Zero,When Positive Balance,When Negative Balance';
            OptionMembers = Yes,No,"If Any Column Not Zero","When Positive Balance","When Negative Balance";
        }
        field(23; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(24; Italic; Boolean)
        {
            Caption = 'Italic';
        }
        field(25; Underline; Boolean)
        {
            Caption = 'Underline';
        }
        field(26; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
        }
        field(27; "Row Type"; Option)
        {
            Caption = 'Row Type';
            OptionCaption = 'Net Change,Balance at Date,Beginning Balance';
            OptionMembers = "Net Change","Balance at Date","Beginning Balance";
        }
        field(28; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            OptionCaption = 'Net Amount,Debit Amount,Credit Amount';
            OptionMembers = "Net Amount","Debit Amount","Credit Amount";
        }
    }

    keys
    {
        key(Key1; "Result Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

