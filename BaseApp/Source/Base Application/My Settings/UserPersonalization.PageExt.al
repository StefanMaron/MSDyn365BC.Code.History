pageextension 9206 "User Personalization" extends "User Personalization"
{    
    actions
    {   
        addFirst(navigation)
        {
            action(PersonalizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Personalized Pages';
                Image = Link;
                ToolTip = 'View the list of pages that the user has personalized.';
                trigger OnAction()
                var
                    UserPagePersonalizationList: page "User Page Personalization List";
                begin
                    UserPagePersonalizationList.SetUserID(Rec."User SID");
                    UserPagePersonalizationList.RunModal();
                end;
            }
            action(CustomizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customized Pages';
                Image = Link;
                ToolTip = 'View the list of pages that have been customized for the user role.';
                trigger OnAction()
                var
                    TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
                begin
                    TenantProfilePageMetadata.SetFilter("Profile ID", Rec."Profile ID");
                    Page.RunModal(Page::"Profile Customization List", TenantProfilePageMetadata);
                end;
            }
        }

        addFirst(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("C&lear Personalized Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lear Personalized Pages';
                    Image = Cancel;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    ToolTip = 'Delete all personalizations made by the specified user across display targets.';

                    trigger OnAction()
                    var
                        UserPersonalization: Record "User Personalization";
                    begin
                        UserPersonalization.Get(Rec."User SID");
                        ConfPersonalizationMgt.ClearUserPersonalization(UserPersonalization);
                    end;
                }
            }
        }
    }

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
}