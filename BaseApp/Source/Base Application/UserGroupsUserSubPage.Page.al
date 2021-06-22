page 9833 "User Groups User SubPage"
{
    Caption = 'User Groups';
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "User Group Member";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(UserGroupCode; "User Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                    ToolTip = 'Specifies a user group.';
                }
                field("User Group Name"; "User Group Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the user.';
                }
                field("Company Name"; "Company Name")
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
        "Company Name" := CompanyName;
    end;
}

