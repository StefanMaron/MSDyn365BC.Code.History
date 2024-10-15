#if not CLEAN19
page 1200 "Bank Export/Import Setup"
{
    AdditionalSearchTerms = 'data exchange definition setup,bank file import setup,bank file export setup,bank transfer setup,amc yodlee feed stream setup';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Export/Import Setup';
    PageType = List;
    SourceTable = "Bank Export/Import Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code for the Bank Export/Import setup.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank export/import setup.';
                }
                field(Direction; Direction)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies if this setup will be used to import a bank file or to export a bank file.';
                }
                field("Processing Codeunit ID"; "Processing Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that will import the bank statement data.';
                }
                field("Processing Codeunit Name"; "Processing Codeunit Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the codeunit that will import the bank statement data.';
                }
                field("Processing XMLport ID"; "Processing XMLport ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the XMLport through which the bank statement data is imported.';
                }
                field("Processing XMLport Name"; "Processing XMLport Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the XMLport through which the bank statement data is imported.';
                }
                field("Processing Report ID"; "Processing Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that has been set up to process data before you apply it to a Microsoft Dynamics NAV database.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Processing Report Name"; "Processing Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of codeunit that has been set up to process data before you apply it to a Microsoft Dynamics NAV database.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Default File Type"; "Default File Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a type of default file';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Data Exch. Def. Code"; "Data Exch. Def. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that represents the xml file with a data exchange definition that you have created in the Data Exchange Framework.';
                }
                field("Preserve Non-Latin Characters"; "Preserve Non-Latin Characters")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that non-latin characters in the bank statement files are preserved during import.';
                }
                field("Check Export Codeunit"; "Check Export Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit that validates payment lines when you use the Export Payments to File action in the Payment Journal window.';
                }
                field("Check Export Codeunit Name"; "Check Export Codeunit Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the codeunit that validates payment lines when you use the Export Payments to File action in the Payment Journal window.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control12; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control13; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
    }
}

#endif