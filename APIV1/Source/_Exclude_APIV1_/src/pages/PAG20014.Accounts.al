page 20014 "APIV1 - Accounts"
{
    APIVersion = 'v1.0';
    Caption = 'accounts', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'account';
    EntitySetName = 'accounts';
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "G/L Account";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(category; "Account Category")
                {
                    ApplicationArea = All;
                    Caption = 'category', Locked = true;
                }
                field(subCategory; "Account Subcategory Descript.")
                {
                    ApplicationArea = All;
                    Caption = 'subCategory', Locked = true;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'blocked', Locked = true;
                    ToolTip = 'Specifies the status of the account.';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    trigger OnOpenPage()
    begin
        SETRANGE("Account Type", "Account Type"::Posting);
        SETRANGE("Direct Posting", TRUE);
    end;

    local procedure SetCalculatedFields()
    begin
    end;
}

