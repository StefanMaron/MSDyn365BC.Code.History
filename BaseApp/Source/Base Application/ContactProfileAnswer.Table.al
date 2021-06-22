table 5089 "Contact Profile Answer"
{
    Caption = 'Contact Profile Answer';
    DrillDownPageID = "Profile Contacts";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact;

            trigger OnValidate()
            var
                Cont: Record Contact;
            begin
                if Cont.Get("Contact No.") then
                    "Contact Company No." := Cont."Company No."
                else
                    "Contact Company No." := '';
            end;
        }
        field(2; "Contact Company No."; Code[20])
        {
            Caption = 'Contact Company No.';
            NotBlank = true;
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(3; "Profile Questionnaire Code"; Code[20])
        {
            Caption = 'Profile Questionnaire Code';
            NotBlank = true;
            TableRelation = "Profile Questionnaire Header";

            trigger OnValidate()
            var
                ProfileQuestnHeader: Record "Profile Questionnaire Header";
            begin
                ProfileQuestnHeader.Get("Profile Questionnaire Code");
                "Profile Questionnaire Priority" := ProfileQuestnHeader.Priority;
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Profile Questionnaire Line"."Line No." WHERE("Profile Questionnaire Code" = FIELD("Profile Questionnaire Code"),
                                                                           Type = CONST(Answer));

            trigger OnValidate()
            var
                ProfileQuestnLine: Record "Profile Questionnaire Line";
            begin
                ProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");
                "Answer Priority" := ProfileQuestnLine.Priority;
            end;
        }
        field(5; Answer; Text[250])
        {
            CalcFormula = Lookup ("Profile Questionnaire Line".Description WHERE("Profile Questionnaire Code" = FIELD("Profile Questionnaire Code"),
                                                                                 "Line No." = FIELD("Line No.")));
            Caption = 'Answer';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Contact Company Name"; Text[100])
        {
            CalcFormula = Lookup (Contact."Company Name" WHERE("No." = FIELD("Contact No.")));
            Caption = 'Contact Company Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Contact Name"; Text[100])
        {
            CalcFormula = Lookup (Contact.Name WHERE("No." = FIELD("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Profile Questionnaire Priority"; Option)
        {
            Caption = 'Profile Questionnaire Priority';
            Editable = false;
            OptionCaption = 'Very Low,Low,Normal,High,Very High';
            OptionMembers = "Very Low",Low,Normal,High,"Very High";
        }
        field(9; "Answer Priority"; Option)
        {
            Caption = 'Answer Priority';
            OptionCaption = 'Very Low (Hidden),Low,Normal,High,Very High';
            OptionMembers = "Very Low (Hidden)",Low,Normal,High,"Very High";
        }
        field(10; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(11; "Questions Answered (%)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Questions Answered (%)';
            DecimalPlaces = 0 : 0;
        }
        field(5088; "Profile Questionnaire Value"; Text[250])
        {
            Caption = 'Profile Questionnaire Value';
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Profile Questionnaire Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Contact No.", "Answer Priority", "Profile Questionnaire Priority")
        {
        }
        key(Key3; "Profile Questionnaire Code", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Contact: Record Contact;
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine.Get("Profile Questionnaire Code", QuestionLineNo);
        ProfileQuestnLine.TestField("Auto Contact Classification", false);

        if PartOfRating then begin
            Delete;
            UpdateContactClassification.UpdateRating("Contact No.");
            Insert;
        end;

        Contact.TouchContact("Contact No.");
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
        ProfileQuestnLine3: Record "Profile Questionnaire Line";
    begin
        ProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");
        ProfileQuestnLine.TestField(Type, ProfileQuestnLine.Type::Answer);

        ProfileQuestnLine2.Get("Profile Questionnaire Code", QuestionLineNo);
        ProfileQuestnLine2.TestField("Auto Contact Classification", false);

        if not ProfileQuestnLine2."Multiple Answers" then begin
            ContProfileAnswer.Reset();
            ProfileQuestnLine3.Reset();
            ProfileQuestnLine3.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
            ProfileQuestnLine3.SetRange(Type, ProfileQuestnLine3.Type::Question);
            ProfileQuestnLine3.SetFilter("Line No.", '>%1', ProfileQuestnLine2."Line No.");
            if ProfileQuestnLine3.FindFirst then
                ContProfileAnswer.SetRange(
                  "Line No.", ProfileQuestnLine2."Line No.", ProfileQuestnLine3."Line No.")
            else
                ContProfileAnswer.SetFilter("Line No.", '>%1', ProfileQuestnLine2."Line No.");
            ContProfileAnswer.SetRange("Contact No.", "Contact No.");
            ContProfileAnswer.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
            if not ContProfileAnswer.IsEmpty then
                Error(Text000, ProfileQuestnLine2.FieldCaption("Multiple Answers"));
        end;

        if PartOfRating then begin
            Insert;
            UpdateContactClassification.UpdateRating("Contact No.");
            Delete;
        end;

        Contact.TouchContact("Contact No.");
    end;

    trigger OnModify()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnRename()
    var
        Contact: Record Contact;
    begin
        if xRec."Contact No." = "Contact No." then
            Contact.TouchContact("Contact No.")
        else begin
            Contact.TouchContact("Contact No.");
            Contact.TouchContact(xRec."Contact No.");
        end;
    end;

    var
        Text000: Label 'This Question does not allow %1.';
        UpdateContactClassification: Report "Update Contact Classification";

    procedure Question(): Text[250]
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        if ProfileQuestnLine.Get("Profile Questionnaire Code", QuestionLineNo) then
            exit(ProfileQuestnLine.Description)
    end;

    local procedure QuestionLineNo(): Integer
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        with ProfileQuestnLine do begin
            Reset;
            SetRange("Profile Questionnaire Code", Rec."Profile Questionnaire Code");
            SetFilter("Line No.", '<%1', Rec."Line No.");
            SetRange(Type, Type::Question);
            if FindLast then
                exit("Line No.")
        end;
    end;

    local procedure PartOfRating(): Boolean
    var
        Rating: Record Rating;
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
    begin
        Rating.SetCurrentKey("Rating Profile Quest. Code", "Rating Profile Quest. Line No.");
        Rating.SetRange("Rating Profile Quest. Code", "Profile Questionnaire Code");

        ProfileQuestnLine.Get("Profile Questionnaire Code", "Line No.");
        ProfileQuestnLine.Get("Profile Questionnaire Code", ProfileQuestnLine.FindQuestionLine);

        ProfileQuestnLine2 := ProfileQuestnLine;
        ProfileQuestnLine2.SetRange(Type, ProfileQuestnLine2.Type::Question);
        ProfileQuestnLine2.SetRange("Profile Questionnaire Code", ProfileQuestnLine2."Profile Questionnaire Code");
        if ProfileQuestnLine2.Next <> 0 then
            Rating.SetRange("Rating Profile Quest. Line No.", ProfileQuestnLine."Line No.", ProfileQuestnLine2."Line No.")
        else
            Rating.SetFilter("Rating Profile Quest. Line No.", '%1..', ProfileQuestnLine."Line No.");

        exit(Rating.FindFirst);
    end;
}

