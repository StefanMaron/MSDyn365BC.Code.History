page 18873 "TCS Journal Templates"
{
    Caption = 'TCS Journal Templates';
    PageType = List;
    SourceTable = "TCS Journal Template";
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
                    Caption = 'Name';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you are creating.';
                }
                field(Description; Description)
                {
                    Caption = 'Description';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the journal template you are creating.';
                }
                field("Source Code"; "Source Code")
                {
                    Caption = 'Source Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Source Code of the journal template you are creating.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    Caption = 'Bal. Account Type';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as Bank or a Cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    Caption = 'Bal. Account No.';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a Cash account.';
                }
                field("No. Series"; "No. Series")
                {
                    Caption = 'No. Series';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    Caption = 'Posting No. Series';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign document numbers to ledger entries that are posted from this journal batch.';
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
                action(Batches)
                {
                    Caption = 'Batches';
                    ApplicationArea = Basic, Suite;
                    Image = Description;
                    RunObject = Page "TCS Journal Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                    ToolTip = 'View or edit multiple journals for a specific template.';
                }
            }
        }
    }
}