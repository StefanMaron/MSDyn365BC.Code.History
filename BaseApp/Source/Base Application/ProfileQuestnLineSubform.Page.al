page 5169 "Profile Questn. Line Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Set; Set)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Select';
                    ToolTip = 'Specifies that the profile question will be included.';

                    trigger OnValidate()
                    begin
                        TestField(Type, Type::Answer);

                        if Set then begin
                            TempProfileQuestionnaireLine.Init();
                            TempProfileQuestionnaireLine.Validate("Profile Questionnaire Code", "Profile Questionnaire Code");
                            TempProfileQuestionnaireLine.Validate("Line No.", "Line No.");
                            TempProfileQuestionnaireLine.Insert();
                        end else begin
                            TempProfileQuestionnaireLine.Get("Profile Questionnaire Code", "Line No.");
                            TempProfileQuestionnaireLine.Delete();
                        end;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the profile question or answer.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Set := TempProfileQuestionnaireLine.Get("Profile Questionnaire Code", "Line No.");
        StyleIsStrong := Type = Type::Question;
    end;

    var
        TempProfileQuestionnaireLine: Record "Profile Questionnaire Line" temporary;
        Set: Boolean;
        [InDataSet]
        StyleIsStrong: Boolean;

    procedure SetProfileQnLine(var FromProfileQuestionnaireLine: Record "Profile Questionnaire Line")
    begin
        with FromProfileQuestionnaireLine do begin
            ClearSettings;
            if Find('-') then
                repeat
                    TempProfileQuestionnaireLine := FromProfileQuestionnaireLine;
                    TempProfileQuestionnaireLine.Insert();
                until Next = 0;
        end;
    end;

    local procedure ClearSettings()
    begin
        if TempProfileQuestionnaireLine.FindFirst then
            TempProfileQuestionnaireLine.DeleteAll();
    end;
}

