table 5087 "Profile Questionnaire Header"
{
    Caption = 'Profile Questionnaire Header';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Profile Questionnaire List";
    LookupPageID = "Profile Questionnaires";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; "Contact Type"; Option)
        {
            Caption = 'Contact Type';
            OptionCaption = ' ,Companies,People';
            OptionMembers = " ",Companies,People;
        }
        field(4; "Business Relation Code"; Code[10])
        {
            Caption = 'Business Relation Code';
            TableRelation = "Business Relation";
        }
        field(5; Priority; Option)
        {
            Caption = 'Priority';
            InitValue = Normal;
            OptionCaption = 'Very Low,Low,Normal,High,Very High';
            OptionMembers = "Very Low",Low,Normal,High,"Very High";

            trigger OnValidate()
            var
                ContProfileAnswer: Record "Contact Profile Answer";
            begin
                ContProfileAnswer.SetCurrentKey("Profile Questionnaire Code");
                ContProfileAnswer.SetRange("Profile Questionnaire Code", Code);
                ContProfileAnswer.ModifyAll("Profile Questionnaire Priority", Priority);
                Modify;
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ProfileQuestnLine.Reset();
        ProfileQuestnLine.SetRange("Profile Questionnaire Code", Code);
        ProfileQuestnLine.DeleteAll(true);
    end;

    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
}

