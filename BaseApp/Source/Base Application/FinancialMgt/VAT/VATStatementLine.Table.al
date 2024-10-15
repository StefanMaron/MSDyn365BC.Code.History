table 256 "VAT Statement Line"
{
    Caption = 'VAT Statement Line';

    fields
    {
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
            TableRelation = "VAT Statement Template";
        }
        field(2; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
            TableRelation = "VAT Statement Name".Name WHERE("Statement Template Name" = FIELD("Statement Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Type; Enum "VAT Statement Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then begin
                    TempType := Type;
                    Init();
                    "Statement Template Name" := xRec."Statement Template Name";
                    "Statement Name" := xRec."Statement Name";
                    "Line No." := xRec."Line No.";
                    "Row No." := xRec."Row No.";
                    Description := xRec.Description;
                    Type := TempType;
                end;
            end;
        }
        field(7; "Account Totaling"; Text[30])
        {
            Caption = 'Account Totaling';
            TableRelation = "G/L Account";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Account Totaling" <> '' then begin
                    GLAcc.SetFilter("No.", "Account Totaling");
                    GLAcc.SetFilter("Account Type", '<> 0');
                    if GLAcc.FindFirst() then
                        GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                end;
            end;
        }
        field(8; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(9; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(10; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(11; "Row Totaling"; Text[50])
        {
            Caption = 'Row Totaling';
        }
        field(12; "Amount Type"; Enum "VAT Statement Line Amount Type")
        {
            Caption = 'Amount Type';
        }
        field(13; "Calculate with"; Option)
        {
            Caption = 'Calculate with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";

            trigger OnValidate()
            begin
                if ("Calculate with" = "Calculate with"::"Opposite Sign") and (Type = Type::"Row Totaling") then
                    FieldError(Type, StrSubstNo(Text000, Type));
            end;
        }
        field(14; Print; Boolean)
        {
            Caption = 'Print';
            InitValue = true;
        }
        field(15; "Print with"; Option)
        {
            Caption = 'Print with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";
        }
        field(16; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(18; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            TableRelation = "Tax Jurisdiction";
        }
        field(19; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
        }
        field(20; "Box No."; Text[30])
        {
            Caption = 'Box No.';
        }
        field(11763; "Attribute Code"; Code[20])
        {
            Caption = 'Attribute Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11770; "G/L Amount Type"; Option)
        {
            Caption = 'G/L Amount Type';
            OptionCaption = 'Net Change,Debit,Credit';
            OptionMembers = "Net Change",Debit,Credit;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11771; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11772; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(11773; "Use Row Date Filter"; Boolean)
        {
            Caption = 'Use Row Date Filter';
            ObsoleteState = Removed;
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '20.0';
        }
        field(11774; "Date Row Filter"; Date)
        {
            Caption = 'Date Row Filter';
            FieldClass = FlowFilter;
            ObsoleteState = Removed;
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '20.0';
        }
        field(11775; Show; Option)
        {
            Caption = 'Show';
            OptionCaption = ' ,Zero If Negative,Zero If Positive';
            OptionMembers = " ","Zero If Negative","Zero If Positive";
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(31000; "Prepayment Type"; Option)
        {
            Caption = 'Prepayment Type';
            OptionCaption = ' ,Not Prepayment,Prepayment,Advance';
            OptionMembers = " ","Not Prepayment",Prepayment,Advance;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '22.0';
        }
        field(31060; "EU-3 Party Trade"; Option)
        {
            Caption = 'EU-3 Party Trade';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(31061; "EU 3-Party Intermediate Role"; Option)
        {
            Caption = 'EU 3-Party Intermediate Role';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(31100; "VAT Control Rep. Section Code"; Code[20])
        {
            Caption = 'VAT Control Rep. Section Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
        field(31101; "Ignore Simpl. Tax Doc. Limit"; Boolean)
        {
            Caption = 'Ignore Simpl. Tax Doc. Limit';
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '20.0';
        }
    }

    keys
    {
        key(Key1; "Statement Template Name", "Statement Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLAcc: Record "G/L Account";
        TempType: Enum "VAT Statement Line Type";

        Text000: Label 'must not be %1';

}

