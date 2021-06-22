table 5956 "Resource Skill"
{
    Caption = 'Resource Skill';
    LookupPageID = "Resource Skills";

    fields
    {
        field(1; Type; Enum "Resource Skill Type")
        {
            Caption = 'Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = IF (Type = CONST(Resource)) Resource."No."
            ELSE
            IF (Type = CONST("Service Item Group")) "Service Item Group".Code
            ELSE
            IF (Type = CONST(Item)) Item."No."
            ELSE
            IF (Type = CONST("Service Item")) "Service Item"."No.";
        }
        field(3; "Skill Code"; Code[10])
        {
            Caption = 'Skill Code';
            NotBlank = true;
            TableRelation = "Skill Code";

            trigger OnValidate()
            var
                ResSkill: Record "Resource Skill";
                ResSkillMgt: Codeunit "Resource Skill Mgt.";
            begin
                if ("Skill Code" <> xRec."Skill Code") and
                   (xRec."Skill Code" <> '') and
                   (not ResSkill.Get(Type, "No.", "Skill Code"))
                then begin
                    if not ResSkillMgt.ChangeResSkill(Rec, xRec."Skill Code") then
                        Error('');
                end
            end;
        }
        field(4; "Assigned From"; Enum "Resource Skill Assigned From")
        {
            Caption = 'Assigned From';
        }
        field(5; "Source Type"; Enum "Resource Skill Source Type")
        {
            Caption = 'Source Type';
        }
        field(6; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Skill Code")
        {
            Clustered = true;
        }
        key(Key2; "Skill Code", Type, "No.")
        {
        }
        key(Key3; "Assigned From")
        {
        }
        key(Key4; "Source Type", "Source Code")
        {
        }
        key(Key5; "Assigned From", "Source Type", "Source Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
    begin
        ResSkillMgt.AddResSkill(Rec);
    end;
}

