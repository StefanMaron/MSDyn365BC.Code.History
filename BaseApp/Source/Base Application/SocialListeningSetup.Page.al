page 870 "Social Listening Setup"
{
    ApplicationArea = Suite;
    Caption = 'Social Engagement Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Social Listening Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Control10)
                {
                    InstructionalText = 'If you do not already have a subscription, sign up at Microsoft Social Engagement. After signing up, you will receive a Social Engagement Server URL.';
                    ShowCaption = false;
                    field(SignupLbl; SignupLbl)
                    {
                        ApplicationArea = Suite;
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies a link to the sign-up page for Microsoft Social Engagement.';

                        trigger OnDrillDown()
                        begin
                            HyperLink("Signup URL");
                        end;
                    }
                    field("Social Listening URL"; "Social Listening URL")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Social Engagement URL';
                        ToolTip = 'Specifies the URL for the Microsoft Social Engagement subscription.';
                    }
                    field("Solution ID"; "Solution ID")
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ToolTip = 'Specifies the Solution ID assigned for Microsoft Social Engagement. This field cannot be edited.';
                    }
                }
                group(Control9)
                {
                    InstructionalText = 'I agree to the terms of the applicable Microsoft Social Engagement License or Subscription Agreement.';
                    ShowCaption = false;
                    field(TermsOfUseLbl; TermsOfUseLbl)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies a link to the Terms of Use for Microsoft Social Engagement.';

                        trigger OnDrillDown()
                        begin
                            HyperLink("Terms of Use URL");
                        end;
                    }
                    field("Accept License Agreement"; "Accept License Agreement")
                    {
                        ApplicationArea = Suite;
                        ToolTip = 'Specifies acceptance of the license agreement for using Microsoft Social Engagement. This field is mandatory for activating Microsoft Social Engagement.';
                    }
                }
            }
            group("Show Social Media Insights for")
            {
                Caption = 'Show Social Media Insights for';
                field("Show on Items"; "Show on Items")
                {
                    ApplicationArea = Suite;
                    Caption = 'Items';
                    ToolTip = 'Specifies the list of items that you trade in.';
                }
                field("Show on Customers"; "Show on Customers")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customers';
                    ToolTip = 'Specifies whether to enable Microsoft Social Engagement for customers. Selecting Show on Customers will enable a fact box on the Customers list page and on the Customer card.';
                }
                field("Show on Vendors"; "Show on Vendors")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendors';
                    ToolTip = 'Specifies whether to enable Microsoft Social Engagement for vendors. Selecting Show on Vendors will enable a fact box on the Vendors list page and on the Vendor card.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Users)
            {
                ApplicationArea = Suite;
                Caption = 'Users';
                Enabled = "Social Listening URL" <> '';
                Image = Users;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Open the list of users that are registered in the system.';

                trigger OnAction()
                var
                    SocialListeningMgt: Codeunit "Social Listening Management";
                begin
                    HyperLink(SocialListeningMgt.MSLUsersURL);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.CheckAppAreaOnlyBasic;

        Reset;
        if not Get then begin
            Init;
            Insert(true);
        end;
    end;

    var
        TermsOfUseLbl: Label 'Microsoft Social Engagement Terms of Use';
        SignupLbl: Label 'Sign up for Microsoft Social Engagement';
}

