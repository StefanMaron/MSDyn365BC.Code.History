page 8610 "Config. Questionnaire"
{
    AdditionalSearchTerms = 'rapid start implementation migrate setup questionnaire';
    ApplicationArea = Suite;
    Caption = 'Configuration Questionnaire';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Excel';
    SourceTable = "Config. Questionnaire";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the configuration questionnaire that you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the configuration questionnaire.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Questionnaire")
            {
                Caption = '&Questionnaire';
                Image = Questionaire;
                action(ExportToExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Export data in the questionnaire to Excel.';

                    trigger OnAction()
                    begin
                        TestField(Code);
                        if QuestionnaireMgt.ExportQuestionnaireToExcel('', Rec) then
                            Message(Text000);
                    end;
                }
                separator(Action9)
                {
                }
                action(ExportToXML)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export to XML';
                    Ellipsis = true;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Export information in the questionnaire to Excel.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.ExportQuestionnaireAsXML('', Rec) then
                            Message(Text000)
                        else
                            Message(Text003);
                    end;
                }
                action(ImportFromXML)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import from XML';
                    Ellipsis = true;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Import information from XML into the questionnaire. Save the filled Excel file as "XML Data" to produce the XML file to import.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.ImportQuestionnaireAsXMLFromClient then
                            Message(Text001);
                    end;
                }
                separator(Action6)
                {
                }
                action("&Update Questionnaire")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Update Questionnaire';
                    Image = Refresh;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'Fill the question list based on the fields in the table on which the question area is based.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.UpdateQuestionnaire(Rec) then
                            Message(Text004);
                    end;
                }
                action("&Apply Answers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Apply Answers';
                    Image = Apply;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Implement answers in the questionnaire in the related setup fields.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.ApplyAnswers(Rec) then
                            Message(Text005);
                    end;
                }
            }
        }
        area(navigation)
        {
            group(Areas)
            {
                Caption = 'Areas';
                action("&Question Areas")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Question Areas';
                    Image = View;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Config. Question Areas";
                    RunPageLink = "Questionnaire Code" = FIELD(Code);
                    ToolTip = 'View the areas that questions are grouped by.';
                }
            }
        }
    }

    var
        Text000: Label 'The questionnaire has been successfully exported.';
        Text001: Label 'The questionnaire has been successfully imported.';
        Text003: Label 'The export of the questionnaire has been canceled.';
        QuestionnaireMgt: Codeunit "Questionnaire Management";
        Text004: Label 'The questionnaire has been updated.';
        Text005: Label 'Answers have been applied.';
}

