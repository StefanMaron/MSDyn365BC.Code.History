#if not CLEAN22
namespace System.Security.AccessControl;

page 9833 "User Groups User SubPage"
{
    Caption = 'User Groups';
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "User Group Member";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the User Security Groups Part page in the security groups system; by Permission Sets FactBox page in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(UserGroupCode; Rec."User Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                    ToolTip = 'Specifies a user group.';
                }
                field("User Group Name"; Rec."User Group Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the user.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Company Name" := CompanyName;
    end;
}

#endif