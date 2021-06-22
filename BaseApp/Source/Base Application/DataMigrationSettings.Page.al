page 1807 "Data Migration Settings"
{
    AccessByPermission = TableData "Data Migration Setup" = R;
    AdditionalSearchTerms = 'implementation settings,data setup settings,quickbooks settings';
    ApplicationArea = Basic, Suite;
    Caption = 'Data Migration Settings';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Data Migration Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Select default templates for data migration';
                field("Default Customer Template"; "Default Customer Template")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Config Templates";
                    ToolTip = 'Specifies the template to use by default when migrating data for customers. The template defines the data structure and ensures customers are created accurately.';
                }
                field("Default Vendor Template"; "Default Vendor Template")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Config Templates";
                    ToolTip = 'Specifies the template to use by default when migrating data for vendors. The template defines the data structure and ensures vendors are created accurately.';
                }
                field("Default Item Template"; "Default Item Template")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Config Templates";
                    ToolTip = 'Specifies the template to use by default when migrating data for items. The template defines the data structure and ensures items are created accurately.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}

