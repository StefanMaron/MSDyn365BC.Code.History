table 292 "Reminder Terms"
{
    Caption = 'Reminder Terms';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Reminder Terms";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
        }
        field(4; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
        }
        field(5; "Max. No. of Reminders"; Integer)
        {
            Caption = 'Max. No. of Reminders';
            MinValue = 0;
        }
        field(6; "Minimum Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Minimum Amount (LCY)';
            MinValue = 0;
        }
        field(7; "Post Add. Fee per Line"; Boolean)
        {
            Caption = 'Post Add. Fee per Line';
        }
        field(8; "Note About Line Fee on Report"; Text[150])
        {
            Caption = 'Note About Line Fee on Report';
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
        ReminderLevel.SetRange("Reminder Terms Code", Code);
        ReminderLevel.DeleteAll(true);

        ReminderTermsTranslation.SetRange("Reminder Terms Code", Code);
        ReminderTermsTranslation.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        ReminderTermsTranslation.SetRange("Reminder Terms Code", xRec.Code);
        while ReminderTermsTranslation.FindFirst do
            ReminderTermsTranslation.Rename(
              Code, ReminderTermsTranslation."Language Code");

        ReminderLevel.SetRange("Reminder Terms Code", xRec.Code);
        while ReminderLevel.FindFirst do
            ReminderLevel.Rename(Code, ReminderLevel."No.");
    end;

    var
        ReminderTermsTranslation: Record "Reminder Terms Translation";
        ReminderLevel: Record "Reminder Level";

    procedure SetAccountVisibility(var InterestVisible: Boolean; var AdditionalFeeVisible: Boolean; var AddFeePerLineVisible: Boolean)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.SetRange("Post Interest", true);
        InterestVisible := not ReminderTerms.IsEmpty;

        ReminderTerms.SetRange("Post Interest");
        ReminderTerms.SetRange("Post Additional Fee", true);
        AdditionalFeeVisible := not ReminderTerms.IsEmpty;

        ReminderTerms.SetRange("Post Additional Fee");
        ReminderTerms.SetRange("Post Add. Fee per Line", true);
        AddFeePerLineVisible := not ReminderTerms.IsEmpty;
    end;
}

