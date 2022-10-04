#if not CLEAN21
page 2355 "O365 To D365 Trial"
{
    Caption = 'Try Dynamics 365 Business Central';
    Editable = false;
    PageType = NavigatePage;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

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
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Get to know Business Central';
                        Image = TileVideo;
                        RunPageMode = View;
                        ToolTip = 'Launches a video that introduces you to Business Central.';

                        trigger OnAction()
                        var
                            Video: Codeunit Video;
                        begin
                            Session.LogMessage('000081W', IntroTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
                            Video.Play('https://go.microsoft.com/fwlink/?linkid=867632');
                        end;
                    }
                }
            }
            field(EnablePopups; EnablePopupsLbl)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Try Dynamics 365 Business Central for free today!';
                InFooterBar = true;
                //The property 'PromotedOnly' can only be set if the property 'Promoted' is set to 'true'
                //PromotedOnly = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                    O365SetupMgmt.GotoBusinessCentralWithEvaluationCompany();
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
#endif
