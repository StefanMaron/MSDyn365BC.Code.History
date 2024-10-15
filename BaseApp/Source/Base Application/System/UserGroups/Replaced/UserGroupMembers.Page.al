#if not CLEAN22
namespace System.Security.AccessControl;

using System.Environment;
using System.Security.User;

page 9831 "User Group Members"
{
    Caption = 'User Group Members';
    DataCaptionFields = "User Group Code", "User Group Name";
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "User Group Member";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] Replaced by the Security Group Members page in the security groups system; by Perm. Set Assignments Part page in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SelectedCompany; SelectedCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    TableRelation = Company;
                    ToolTip = 'Specifies the company that you want to see users for.';

                    trigger OnValidate()
                    begin
                        UpdateCompany();
                    end;
                }
            }
            repeater(Group)
            {
                field(UserName; UserName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    Lookup = true;
                    LookupPageID = Users;
                    ShowMandatory = true;
                    TableRelation = User;
                    ToolTip = 'Specifies the name of the user.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        UserSelection: Codeunit "User Selection";
                    begin
                        if UserSelection.Open(User) then begin
                            if User."User Security ID" = Rec."User Security ID" then
                                exit;
                            if Rec.Get(Rec."User Group Code", Rec."User Security ID", SelectedCompany) then
                                Rec.Delete(true);
                            Rec.Init();
                            Rec.Validate("User Security ID", User."User Security ID");
                            Rec.Validate("Company Name", SelectedCompany);
                            Rec.CalcFields("User Name");
                            Rec.Insert(true);
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        if UserName = '' then
                            exit;
                        User.SetRange("User Name", UserName);
                        User.FindFirst();
                        Rec.Init();
                        Rec.Validate("User Security ID", User."User Security ID");
                        Rec.Validate("Company Name", SelectedCompany);
                        Rec.CalcFields("User Name");
                        Rec.Insert(true);
                        CurrPage.Update(false);
                    end;
                }
                field("User Full Name"; Rec."User Full Name")
                {
                    ApplicationArea = All;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the user.';
                }
                field("User Group Code"; Rec."User Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    TableRelation = "User Group".Code;
                    ToolTip = 'Specifies a user group.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company.';
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(AddUsers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Add Users';
                Image = Users;
                ToolTip = 'See a list of existing users and add users to the user group.';

                trigger OnAction()
                begin
                    Rec.AddUsers(Company.Name);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AddUsers_Promoted; AddUsers)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("User Name");
        UserName := Rec."User Name";
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(not IsNullGuid(Rec."User Security ID"));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField("User Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UserName := '';
    end;

    trigger OnOpenPage()
    begin
        SelectedCompany := CompanyName;
        UpdateCompany();
    end;

    var
        Company: Record Company;
        SelectedCompany: Text[30];
        UserName: Code[50];

    local procedure UpdateCompany()
    begin
        Company.Name := SelectedCompany;
        if SelectedCompany <> '' then begin
            Company.Find('=<>');
            SelectedCompany := Company.Name;
        end;
        Rec.SetRange("Company Name", Company.Name);
        CurrPage.Update(false);
    end;
}

#endif