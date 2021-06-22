page 5051 "Contact Card Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Contact Profile Answer";
    SourceTableView = SORTING("Contact No.", "Answer Priority", "Profile Questionnaire Priority")
                      ORDER(Descending)
                      WHERE("Answer Priority" = FILTER(<> "Very Low (Hidden)"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Answer Priority"; "Answer Priority")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the profile answer. There are five options:';
                    Visible = false;
                }
                field("Profile Questionnaire Priority"; "Profile Questionnaire Priority")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the questionnaire that the profile answer is linked to. There are five options: Very Low, Low, Normal, High, and Very High.';
                    Visible = false;
                }
                field(Question; Question)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Question';
                    ToolTip = 'Specifies the question in the profile questionnaire.';
                }
                field(Answer; Answer)
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies your contact''s answer to the question.';

                    trigger OnAssistEdit()
                    var
                        ContactProfileAnswer: Record "Contact Profile Answer";
                        Rating: Record Rating;
                        RatingTemp: Record Rating temporary;
                        ProfileQuestionnaireLine: Record "Profile Questionnaire Line";
                        Contact: Record Contact;
                        ProfileManagement: Codeunit ProfileManagement;
                    begin
                        ProfileQuestionnaireLine.Get("Profile Questionnaire Code", "Line No.");
                        ProfileQuestionnaireLine.Get("Profile Questionnaire Code", ProfileQuestionnaireLine.FindQuestionLine);
                        if ProfileQuestionnaireLine."Auto Contact Classification" then begin
                            if ProfileQuestionnaireLine."Contact Class. Field" = ProfileQuestionnaireLine."Contact Class. Field"::Rating then begin
                                Rating.SetRange("Profile Questionnaire Code", "Profile Questionnaire Code");
                                Rating.SetRange("Profile Questionnaire Line No.", ProfileQuestionnaireLine."Line No.");
                                if Rating.Find('-') then
                                    repeat
                                        if ContactProfileAnswer.Get(
                                             "Contact No.", Rating."Rating Profile Quest. Code", Rating."Rating Profile Quest. Line No.")
                                        then begin
                                            RatingTemp := Rating;
                                            RatingTemp.Insert();
                                        end;
                                    until Rating.Next = 0;

                                if not RatingTemp.IsEmpty then
                                    PAGE.RunModal(PAGE::"Answer Points List", RatingTemp)
                                else
                                    Message(Text001);
                            end else
                                Message(Text002, "Last Date Updated");
                        end else begin
                            Contact.Get("Contact No.");
                            ProfileManagement.ShowContactQuestionnaireCard(Contact, "Profile Questionnaire Code", "Line No.");
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("Questions Answered (%)"; "Questions Answered (%)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of questions in percentage of total questions that have scored points based on the question you used for your rating.';
                }
                field("Last Date Updated"; "Last Date Updated")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the contact profile answer was last updated. This field shows the first date when the questions used to rate this contact has been given points.';
                }
            }
        }
    }

    actions
    {
    }

    var
        Text001: Label 'There are no answer values for this rating answer.';
        Text002: Label 'This answer reflects the state of the contact on %1 when the Update Contact Class. batch job was run.\To make the answer reflect the current state of the contact, run the batch job again.';
}

