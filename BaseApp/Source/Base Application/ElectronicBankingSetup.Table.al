table 11306 "Electronic Banking Setup"
{
    Caption = 'Electronic Banking Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Summarize Gen. Jnl. Lines"; Boolean)
        {
            Caption = 'Summarize Gen. Jnl. Lines';
            InitValue = true;
        }
        field(3; "Cut off Payment Message Texts"; Boolean)
        {
            Caption = 'Cut off Payment Message Texts';
            InitValue = false;
        }
        field(21; "IBS Version"; Option)
        {
            Caption = 'IBS Version';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            OptionCaption = ' ,1,2,3,4,5,6';
            OptionMembers = " ","1","2","3","4","5","6";
            ObsoleteTag = '15.0';
        }
        field(22; "Notification E-mail address"; Text[30])
        {
            Caption = 'Notification E-mail address';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(23; Language; Option)
        {
            Caption = 'Language';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            OptionCaption = 'EN,FR,NL,DE';
            OptionMembers = EN,FR,NL,DE;
            ObsoleteTag = '15.0';
        }
        field(24; "Upload Integration Mode"; Option)
        {
            Caption = 'Upload Integration Mode';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            OptionCaption = 'Manual,Attended';
            OptionMembers = Manual,Attended;
            ObsoleteTag = '15.0';

            trigger OnValidate()
            begin
                if (xRec."Upload Integration Mode" <> "Upload Integration Mode") and
                   ("Upload Integration Mode" = "Upload Integration Mode"::Attended)
                then
                    TestField("IBS Version", "IBS Version"::"6");
            end;
        }
        field(25; "Upload Path"; Text[250])
        {
            Caption = 'Upload Path';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(26; "Download Integration Mode"; Option)
        {
            Caption = 'Download Integration Mode';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            OptionCaption = 'Manual,Attended';
            OptionMembers = Manual,Attended;
            ObsoleteTag = '15.0';

            trigger OnValidate()
            begin
                if (xRec."Download Integration Mode" <> "Download Integration Mode") and
                   ("Download Integration Mode" = "Download Integration Mode"::Attended)
                then
                    TestField("IBS Version", "IBS Version"::"6");
            end;
        }
        field(27; "Download Path"; Text[250])
        {
            Caption = 'Download Path';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(28; "IBS Log Upload Nos."; Code[20])
        {
            Caption = 'IBS Log Upload Nos.';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            TableRelation = "No. Series";
            ObsoleteTag = '15.0';
        }
        field(29; "IBS Log Download Nos."; Code[20])
        {
            Caption = 'IBS Log Download Nos.';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            TableRelation = "No. Series";
            ObsoleteTag = '15.0';
        }
        field(30; "IBS Request ID"; Code[20])
        {
            Caption = 'IBS Request ID';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            TableRelation = "No. Series";
            ObsoleteTag = '15.0';
        }
        field(31; "IBS Service Version"; Code[10])
        {
            Caption = 'IBS Service Version';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
        }
        field(40; "Test Environment"; Boolean)
        {
            Caption = 'Test Environment';
            ObsoleteReason = 'Legacy ISABEL';
            ObsoleteState = Pending;
            ObsoleteTag = '15.0';
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

