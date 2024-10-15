page 18750 "TDS Journal Templates"
{
    Caption = 'TDS Journal Templates';
    PageType = List;
    SourceTable = "TDS Journal Template";
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the tax journal template.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the tax journal template.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the tax journal template.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account where the balancing entry will be posted.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number where the balancing entry will be posted.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of number series that will be used to assign number to ledger entries that are posted from Journal using this template.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that defines where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Form ID"; "Form ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    Visible = false;
                    ToolTip = 'Specifies the Form ID';
                }

                field("Form Name"; "Form Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                    ToolTiP = 'Specifies the Form Name';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                ToolTip = 'View or edit multiple journals for a specific template.';
                action(Batches)
                {
                    Caption = 'Batches';
                    ToolTip = 'View or edit multiple journals for a specific template.';
                    ApplicationArea = Basic, Suite;
                    Image = Description;
                    RunObject = Page "TDS Journal Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);

                }
            }
        }
    }
}

