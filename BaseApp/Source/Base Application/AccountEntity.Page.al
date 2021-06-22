page 5480 "Account Entity"
{
    Caption = 'accounts', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'account';
    EntitySetName = 'accounts';
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "G/L Account";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                }
                field(category; "Account Category")
                {
                    ApplicationArea = All;
                    Caption = 'Category', Locked = true;
                }
                field(subCategory; "Account Subcategory Descript.")
                {
                    ApplicationArea = All;
                    Caption = 'SubCategory', Locked = true;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;
                    ToolTip = 'Specifies the status of the account.';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnOpenPage()
    begin
        SetRange("Account Type", "Account Type"::Posting);
        SetRange("Direct Posting", true);
    end;

    local procedure SetCalculatedFields()
    begin
    end;
}

