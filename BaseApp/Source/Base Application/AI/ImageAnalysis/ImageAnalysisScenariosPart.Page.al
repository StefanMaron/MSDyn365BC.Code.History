page 2023 "Image Analysis Scenarios Part"
{
    PageType = ListPart;
    Caption = 'Image Analysis Scenarios';
    ApplicationArea = All;
    SourceTable = "Image Analysis Scenario";
    Permissions = tabledata "Image Analysis Scenario" = Rimd;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ScenarioName; Rec."Scenario Name")
                {
                    Caption = 'Scenario Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier for a scenario where Image Analysis can be used inside Business Central.';
                }
                field(CompanyName; Rec."Company Name")
                {
                    Caption = 'Company Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company where this setting applies (empty means all companies).';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Enabled';
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether Image Analysis can be used or not for this scenario.';

                    trigger OnValidate()
                    begin
                        if not Rec.Status then
                            exit;

                        if not Confirm(ConfirmAcceptQuestionTxt) then
                            Error('');
                    end;
                }
            }
        }
    }

    var
        ConfirmAcceptQuestionTxt: Label 'This feature utilizes Microsoft Cognitive Services. By continuing you are affirming that you understand that the data handling and compliance standards of Microsoft Cognitive Services may not be the same as those provided by Microsoft Dynamics 365 Business Central. Please consult the documentation for Microsoft Cognitive Services to learn more.';

}