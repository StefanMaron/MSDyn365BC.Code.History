page 11000015 "Import Protocols"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Import Protocols';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Import Protocol";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an import protocol code that you want attached to the entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of what the import protocol stands for.';
                }
                field("Import Type"; "Import Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of the import file used to import electronic bank statements.';
                }
                field("Import ID"; "Import ID")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = Objects;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID for the report or XMLport used to import electronic bank statements.';
                }
                field("Import Name"; "Import Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the import object.';
                }
                field("Automatic Reconciliation"; "Automatic Reconciliation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether automatic reconciliation should be performed when importing electronic bank statements.';
                }
                field("Default File Name"; "Default File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default name of the file that contains bank statements which will be imported with the object.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that bank statements are imported for.';
                }
            }
        }
    }

    actions
    {
    }
}

