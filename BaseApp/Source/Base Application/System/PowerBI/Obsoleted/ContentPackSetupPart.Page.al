#if not CLEAN23
namespace System.Integration.PowerBI;

using System.Security.AccessControl;
using System.Security.User;

page 6317 "Content Pack Setup Part"
{
    // // Wizard page to walk the user through connecting PBI content packs to their NAV data,
    // // automatically providing the relevant fields for copy-pasting, where possible.
    // // This page contains all the editable fields while page 6316 hosts this field in the wizard frame.

    Caption = 'Content Pack Setup Part';
    PageType = CardPart;
    ObsoleteState = Pending;
    ObsoleteReason = 'Instead, follow the Business Central documentation page "Building Power BI Reports to Display Dynamics 365 Business Central Data" available at https://learn.microsoft.com/en-gb/dynamics365/business-central/across-how-use-financials-data-source-powerbi';
    ObsoleteTag = '23.0';

    layout
    {
        area(content)
        {
            field(WebServiceURL; URL)
            {
                ApplicationArea = All;
                Caption = 'Web service URL';
                Editable = true;
                ToolTip = 'Specifies the Dynamics web service URL. Use this for the connector''s URL field.';
            }
            field(AuthType; AuthTypeLbl)
            {
                ApplicationArea = All;
                Caption = 'Authentication type';
                ToolTip = 'Specifies the value to select for the connector''s Authentication Type field.';
            }
            field(UserName; UserName)
            {
                ApplicationArea = All;
                Caption = 'User name';
                Editable = true;
                ToolTip = 'Specifies your Dynamics user name. Use this for the connector''s User Name field.';
            }
            field(WebServiceAccessKey; WebServiceAccessKey)
            {
                ApplicationArea = All;
                Caption = 'Web service access key';
                Editable = true;
                ToolTip = 'Specifies your Dynamics web service access key. You might use this for the connector''s Password field. If you don''t have a web service access key, you can create one on the User card page.';

                trigger OnAssistEdit()
                var
                    User: Record User;
                    UserCard: Page "User Card";
                begin
                    // Opens the User card page so they can make a Web Service Access Key when they don't already have one.
                    User.Get(UserSecurityId());
                    UserCard.SetRecord(User);

                    if UserCard.RunModal() = ACTION::OK then
                        GetFieldValues();
                end;
            }
            field(CompanyName; Company)
            {
                ApplicationArea = All;
                Caption = 'Company';
                ToolTip = 'Specifies your company''s name. Use this if the connector asks for it.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        GetFieldValues();
    end;

    var
        URL: Text;
        UserName: Text;
        WebServiceAccessKey: Text;
        Company: Text;
        AuthTypeLbl: Label 'Basic', Locked = true;

    local procedure GetFieldValues()
    var
        IdentityManagement: Codeunit "Identity Management";
    begin
        URL := GetUrl(CLIENTTYPE::ODataV4, CompanyName);

        UserName := UserId;

        WebServiceAccessKey := IdentityManagement.GetWebServicesKey(UserSecurityId());

        Company := CompanyName;
    end;
}

#endif