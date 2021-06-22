page 2355 "O365 To D365 Trial"
{
    Caption = 'Try Dynamics 365 Business Central';
    Editable = false;
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control4)
            {
                InstructionalText = 'Dynamics 365 Business Central is a business management solution for small and mid-sized organizations. As an all-in-one solution, Business Central has more functionality than Microsoft Invoicing, including inventory, purchasing, and projects.';
                ShowCaption = false;
            }
            cuegroup("Get to Know")
            {
                Caption = 'Get to Know';
                Editable = false;

                actions
                {
                    action(GetToKnowBC)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Get to know Business Central';
                        Image = TileVideo;
                        RunPageMode = View;
                        ToolTip = 'Launches a video that introduces you to Business Central.';

                        trigger OnAction()
                        var
                            Video: Codeunit Video;
                        begin
                            SendTraceTag('000081W', InvToBusinessCentralCategoryLbl,
                              VERBOSITY::Normal, IntroTelemetryTxt, DATACLASSIFICATION::SystemMetadata);
                            Video.Play('https://go.microsoft.com/fwlink/?linkid=867632');
                        end;
                    }
                }
            }
            field(EnablePopups; EnablePopupsLbl)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Editable = false;
                ShowCaption = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(TryBusinessCentral)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Try Dynamics 365 Business Central for free today!';
                InFooterBar = true;
                //The property 'PromotedOnly' can only be set if the property 'Promoted' is set to 'true'
                //PromotedOnly = true;

                trigger OnAction()
                begin
                    CurrPage.Close;
                    O365SetupMgmt.GotoBusinessCentralWithEvaluationCompany;
                end;
            }
        }
    }

    var
        O365SetupMgmt: Codeunit "O365 Setup Mgmt";
        EnablePopupsLbl: Label 'To see the Business Central window, make sure your browser allows pop-ups.';
        IntroTelemetryTxt: Label 'Business Central introduction video was played from Invoicing.', Locked = true;
        InvToBusinessCentralCategoryLbl: Label 'AL Invoicing To Business Central', Locked = true;
}

