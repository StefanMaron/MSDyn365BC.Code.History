codeunit 5462 "Graph Int. - Questionnaire"
{

    trigger OnRun()
    begin
    end;

    var
        ProfileQuestionnaireDescriptionTxt: Label 'Microsoft Graph Syncing for Contacts';
        NameProfileQuestionTxt: Label 'Name';
        AnniversariesProfileQuestionTxt: Label 'Anniversaries';
        PhoneticNameProfileQuestionTxt: Label 'PhoneticName';
        WorkProfileQuestionTxt: Label 'Work';

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterTransferRecordFields', '', false, false)]
    procedure OnAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Contact-Graph Contact':
                begin
                    SetProfileQuestionnaireOnGraph(SourceRecordRef, DestinationRecordRef);
                    AdditionalFieldsWereModified := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterInsertRecord', '', false, false)]
    procedure OnAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                CreateProfileQuestionnaireFromGraph(SourceRecordRef, DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterModifyRecord', '', false, false)]
    procedure OnAfterModifyRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                SetProfileQuestionnaireFromGraph(SourceRecordRef, DestinationRecordRef);
        end;
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number <> 0) and (DestinationRecordRef.Number <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name, DestinationRecordRef.Name));
        exit('');
    end;

    procedure GetGraphSyncQuestionnaireCode(): Code[10]
    begin
        exit(UpperCase('GraphSync'));
    end;

    local procedure GetProfileQuestionnaireLine(var ProfileQuestionnaireLine: Record "Profile Questionnaire Line"; InputType: Option; InputDescription: Text[250]): Boolean
    begin
        with ProfileQuestionnaireLine do begin
            SetRange("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
            SetRange(Type, InputType);
            SetRange(Description, InputDescription);
            exit(FindFirst);
        end;
    end;

    local procedure GetContactProfileAnswer(var ContactProfileAnswer: Record "Contact Profile Answer"; ContactNo: Code[20]; Description: Text[250]): Boolean
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        if GetProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, Description) then
            exit(ContactProfileAnswer.Get(ContactNo, GetGraphSyncQuestionnaireCode, ProfileQuestionnaireLine."Line No."));
    end;

    procedure CreateGraphSyncQuestionnaire()
    var
        GraphContact: Record "Graph Contact";
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
    begin
        with ProfileQuestionnaireHeader do
            if not Get(GetGraphSyncQuestionnaireCode) then begin
                Init;
                Validate(Code, GetGraphSyncQuestionnaireCode);
                Validate(Description, ProfileQuestionnaireDescriptionTxt);
                Validate("Contact Type", "Contact Type"::People);
                Insert(true);
            end;

        CreateProfileQuestion(NameProfileQuestionTxt);
        CreateProfileAnswer(GraphContact.FieldName(Title));
        CreateProfileAnswer(GraphContact.FieldName(NickName));
        CreateProfileAnswer(GraphContact.FieldName(Generation));

        CreateProfileQuestion(AnniversariesProfileQuestionTxt);
        CreateProfileAnswer(GraphContact.FieldName(Birthday));
        CreateProfileAnswer(GraphContact.FieldName(WeddingAnniversary));
        CreateProfileAnswer(GraphContact.FieldName(SpouseName));

        CreateProfileQuestion(PhoneticNameProfileQuestionTxt);
        CreateProfileAnswer(GraphContact.FieldName(YomiGivenName));
        CreateProfileAnswer(GraphContact.FieldName(YomiSurname));

        CreateProfileQuestion(WorkProfileQuestionTxt);
        CreateProfileAnswer(GraphContact.FieldName(Profession));
        CreateProfileAnswer(GraphContact.FieldName(Department));
        CreateProfileAnswer(GraphContact.FieldName(OfficeLocation));
        CreateProfileAnswer(GraphContact.FieldName(AssistantName));
        CreateProfileAnswer(GraphContact.FieldName(Manager));
    end;

    local procedure CreateProfileQuestion(InputDescription: Text[250])
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        CreateProfileQestionnaireLine(InputDescription, ProfileQuestionnaireLine.Type::Question, true);
    end;

    local procedure CreateProfileAnswer(InputDescription: Text[250])
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        CreateProfileQestionnaireLine(InputDescription, ProfileQuestionnaireLine.Type::Answer, false);
    end;

    local procedure CreateProfileQestionnaireLine(InputDescription: Text[250]; InputType: Option; EnableMultipleAnswers: Boolean)
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        if not GetProfileQuestionnaireLine(ProfileQuestionnaireLine, InputType, InputDescription) then
            with ProfileQuestionnaireLine do begin
                Init;
                Validate("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
                Validate("Line No.", GetNewLineNo);
                Validate(Type, InputType);
                Validate(Description, InputDescription);
                Validate("Multiple Answers", EnableMultipleAnswers);
                Insert(true);
            end;
    end;

    local procedure CreateContactProfileAnswer(ContactNo: Code[20]; InputDescription: Text[250]; NewProfileQuestionnaireValue: Text)
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        if not GetProfileQuestionnaireLine(ProfileQuestionnaireLine, ProfileQuestionnaireLine.Type::Answer, InputDescription) then
            exit;

        with ContactProfileAnswer do
            if Get(ContactNo, GetGraphSyncQuestionnaireCode, ProfileQuestionnaireLine."Line No.") then begin
                Validate("Profile Questionnaire Value", CopyStr(NewProfileQuestionnaireValue, 1, MaxStrLen("Profile Questionnaire Value")));
                Modify(true);
            end else begin
                Init;
                Validate("Contact No.", ContactNo);
                Validate("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
                Validate("Line No.", ProfileQuestionnaireLine."Line No.");
                Validate("Profile Questionnaire Value", CopyStr(NewProfileQuestionnaireValue, 1, MaxStrLen("Profile Questionnaire Value")));
                Insert(true);
            end;
    end;

    local procedure GetNewLineNo(): Integer
    var
        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
    begin
        with ProfileQuestionnaireLine do begin
            SetRange("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
            if FindLast then;
            exit("Line No." + 10000);
        end;
    end;

    local procedure SetProfileQuestionnaireOnGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
    begin
        SourceRecordRef.SetTable(Contact);
        DestinationRecordRef.SetTable(GraphContact);

        SetProfileQuestionnaireForNameOnGraph(Contact, GraphContact);
        SetProfileQuestionnaireForAnniversariesOnGraph(Contact, GraphContact);
        SetProfileQuestionnaireForPhoneticNameOnGraph(Contact, GraphContact);
        SetProfileQuestionnaireForWorkOnGraph(Contact, GraphContact);

        DestinationRecordRef.GetTable(GraphContact);
    end;

    local procedure CreateProfileQuestionnaireFromGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        SetProfileQuestionnaireFromGraph(SourceRecordRef, DestinationRecordRef);
    end;

    local procedure SetProfileQuestionnaireFromGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
        GraphContact: Record "Graph Contact";
    begin
        SourceRecordRef.SetTable(GraphContact);
        DestinationRecordRef.SetTable(Contact);

        SetProfileQuestionnaireForNameFromGraph(Contact, GraphContact);
        SetProfileQuestionnaireForAnniversariesFromGraph(Contact, GraphContact);
        SetProfileQuestionnaireForPhoneticNameFromGraph(Contact, GraphContact);
        SetProfileQuestionnaireForWorkFromGraph(Contact, GraphContact);

        DestinationRecordRef.GetTable(Contact);
    end;

    local procedure SetProfileQuestionnaireForNameOnGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
    begin
        ContactProfileAnswer.SetRange("Contact No.", Contact."No.");
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
        if ContactProfileAnswer.IsEmpty then
            exit;

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(Title));
        GraphContact.Title := CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.Title));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(NickName));
        GraphContact.NickName := CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.NickName));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(Generation));
        GraphContact.Generation := CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.Generation));
    end;

    local procedure SetProfileQuestionnaireForAnniversariesOnGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
        BirthdayDate: Date;
        WeddingAnniversaryDate: Date;
    begin
        ContactProfileAnswer.SetRange("Contact No.", Contact."No.");
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
        if ContactProfileAnswer.IsEmpty then
            exit;

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(Birthday));
        Evaluate(BirthdayDate, ContactProfileAnswer."Profile Questionnaire Value");
        GraphContact.Birthday := CreateDateTime(BirthdayDate, 0T);

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(WeddingAnniversary));
        Evaluate(WeddingAnniversaryDate, ContactProfileAnswer."Profile Questionnaire Value");
        GraphContact.WeddingAnniversary := CreateDateTime(WeddingAnniversaryDate, 0T);

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(SpouseName));
        GraphContact.SpouseName := CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.SpouseName));
    end;

    local procedure SetProfileQuestionnaireForPhoneticNameOnGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
    begin
        ContactProfileAnswer.SetRange("Contact No.", Contact."No.");
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
        if ContactProfileAnswer.IsEmpty then
            exit;

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(YomiGivenName));
        GraphContact.YomiGivenName :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.YomiGivenName));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(YomiSurname));
        GraphContact.YomiSurname :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.YomiSurname));
    end;

    local procedure SetProfileQuestionnaireForWorkOnGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    var
        ContactProfileAnswer: Record "Contact Profile Answer";
    begin
        ContactProfileAnswer.SetRange("Contact No.", Contact."No.");
        ContactProfileAnswer.SetRange("Profile Questionnaire Code", GetGraphSyncQuestionnaireCode);
        if ContactProfileAnswer.IsEmpty then
            exit;

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(Profession));
        GraphContact.Profession :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.Profession));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(Department));
        GraphContact.Department :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.Department));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(OfficeLocation));
        GraphContact.OfficeLocation :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.OfficeLocation));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(AssistantName));
        GraphContact.AssistantName :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.AssistantName));

        GetContactProfileAnswer(ContactProfileAnswer, Contact."No.", GraphContact.FieldName(Manager));
        GraphContact.Manager :=
          CopyStr(ContactProfileAnswer."Profile Questionnaire Value", 1, MaxStrLen(GraphContact.Manager));
    end;

    local procedure SetProfileQuestionnaireForNameFromGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    begin
        if not GraphContact.HasNameDetailsForQuestionnaire then
            exit;

        CreateGraphSyncQuestionnaire;

        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(Title), GraphContact.Title);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(NickName), GraphContact.NickName);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(Generation), GraphContact.Generation);
    end;

    local procedure SetProfileQuestionnaireForAnniversariesFromGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    begin
        if not GraphContact.HasAnniversariesForQuestionnaire then
            exit;

        CreateGraphSyncQuestionnaire;

        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(Birthday), Format(GraphContact.Birthday));
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(WeddingAnniversary), Format(GraphContact.WeddingAnniversary));
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(SpouseName), GraphContact.SpouseName);
    end;

    local procedure SetProfileQuestionnaireForPhoneticNameFromGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    begin
        if not GraphContact.HasPhoneticNameDetailsForQuestionnaire then
            exit;

        CreateGraphSyncQuestionnaire;

        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(YomiGivenName), GraphContact.YomiGivenName);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(YomiSurname), GraphContact.YomiSurname);
    end;

    local procedure SetProfileQuestionnaireForWorkFromGraph(var Contact: Record Contact; var GraphContact: Record "Graph Contact")
    begin
        if not GraphContact.HasWorkDetailsForQuestionnaire then
            exit;

        CreateGraphSyncQuestionnaire;

        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(Profession), GraphContact.Profession);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(Department), GraphContact.Department);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(OfficeLocation), GraphContact.OfficeLocation);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(AssistantName), GraphContact.AssistantName);
        CreateContactProfileAnswer(Contact."No.", GraphContact.FieldName(Manager), GraphContact.Manager);
    end;
}

