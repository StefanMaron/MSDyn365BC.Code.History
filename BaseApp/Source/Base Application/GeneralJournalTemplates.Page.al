page 101 "General Journal Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Journal Templates';
    PageType = List;
    SourceTable = "Gen. Journal Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the journal template you are creating.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal type. The type determines what the window will look like.';
                }
                field(Recurring; Recurring)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the journal template will be a recurring journal.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign document numbers to ledger entries that are posted from journals using this template.';
                }
                field("Source Code"; "Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Force Doc. Balance"; "Force Doc. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether transactions that are posted in the general journal must balance by document number and document type, in addition to balancing by date.';
                }
                field("Copy VAT Setup to Jnl. Lines"; "Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the program to calculate VAT for accounts and balancing accounts on the journal line of the selected journal template.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if "Copy VAT Setup to Jnl. Lines" <> xRec."Copy VAT Setup to Jnl. Lines" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text001, FieldCaption("Copy VAT Setup to Jnl. Lines")), true)
                            then
                                Error(Text002);
                    end;
                }
                field("Increment Batch Name"; "Increment Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
                }
                field("Allow VAT Difference"; "Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow the manual adjustment of VAT amounts in journals.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if "Allow VAT Difference" <> xRec."Allow VAT Difference" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text001, FieldCaption("Allow VAT Difference")), true)
                            then
                                Error(Text002);
                    end;
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; "Page Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Test Report ID"; "Test Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the test report that is printed when you click Test Report.';
                    Visible = false;
                }
                field("Test Report Caption"; "Test Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that is printed when you print a journal under this journal template.';
                    Visible = false;
                }
                field("Posting Report ID"; "Posting Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the posting report that is printed when you choose Post and Print.';
                    Visible = false;
                }
                field("Posting Report Caption"; "Posting Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the report that is printed when you print the journal.';
                    Visible = false;
                }
                field("Force Posting Report"; "Force Posting Report")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether a report is printed automatically when you post.';
                    Visible = false;
                }
                field("Cust. Receipt Report ID"; "Cust. Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies how to print customer receipts when you post.';
                    Visible = false;
                }
                field("Cust. Receipt Report Caption"; "Cust. Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how to print customer receipts when you post.';
                    Visible = false;
                }
                field("Vendor Receipt Report ID"; "Vendor Receipt Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies how to print vendor receipts when you post.';
                    Visible = false;
                }
                field("Vendor Receipt Report Caption"; "Vendor Receipt Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies how to print vendor receipts when you post.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "General Journal Batches";
                    RunPageLink = "Journal Template Name" = FIELD(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                }
            }
        }
    }

    var
        Text001: Label 'Do you want to update the %1 field on all general journal batches?';
        Text002: Label 'Canceled.';
}

